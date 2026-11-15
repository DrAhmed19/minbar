import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'carauto.dart';
import 'data.dart';
import 'lyrics.dart';
import 'state.dart';
import 'ui.dart';

/// وضع السيارة: مشهد قيادة حيّ بكامل الشاشة.
/// - السرعة من GPS مع تنقية (دقة السرعة، رفض القفزات، حساب احتياطي من المسافة/الزمن).
/// - الطريق يتحرك بالسرعة الحقيقية (بالمتر)، ينعطف مع اتجاه السيارة، الفرامل تضيء عند التباطؤ والتوقف، والإشارة عند الانعطاف.
/// - الشمس والقمر بموقعهما الحقيقي، والطقس الحقيقي (Open-Meteo).
/// - الأداء: الرسومات الثقيلة (نخيل، غيوم، أنسجة، هيكل السيارة) تُرسم مرة كصور وتُعاد بالـGPU، والجزيئات بـ drawAtlas.

double _cl(double x, [double a = 0, double b = 1]) => x < a ? a : (x > b ? b : x);
double _sm(double a, double b, double x) {
  final t = _cl((x - a) / (b - a));
  return t * t * (3 - 2 * t);
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, _cl(t))!;
double _hash(int i) {
  final x = math.sin(i * 127.1 + 311.7) * 43758.5453;
  return x - x.floorToDouble();
}

/// موقع جرم سماوي (ارتفاع، سمت) من طوله البروجي — خوارزمية فلكية مبسطة
(double, double) _skyPos(double lamRad, double n, double lat, double lon) {
  const rad = math.pi / 180;
  final eps = (23.439 - 0.0000004 * n) * rad;
  final ra = math.atan2(math.cos(eps) * math.sin(lamRad), math.cos(lamRad));
  final dec = math.asin(math.sin(eps) * math.sin(lamRad));
  final gmst = (18.697374558 + 24.06570982441908 * n) % 24;
  final ha = (gmst * 15 + lon) * rad - ra, la = lat * rad;
  final el = math.asin(math.sin(la) * math.sin(dec) + math.cos(la) * math.cos(dec) * math.cos(ha));
  final az = math.atan2(-math.sin(ha), math.tan(dec) * math.cos(la) - math.sin(la) * math.cos(ha));
  return (el / rad, (az / rad + 360) % 360);
}

/// الطقس الحالي (القيم 0..1)
class _Wx {
  double rain = 0, snow = 0, cloud = 0, fog = 0, dust = 0, storm = 0, wind = 0, temp = double.nan;
  int code = -1;
  _Wx();
  _Wx.preset(this.code, {this.rain = 0, this.snow = 0, this.cloud = 0, this.fog = 0, this.dust = 0, this.storm = 0, this.wind = 2});
  String get label {
    if (dust > 0.35) return 'غبار';
    if (storm > 0.3) return 'عاصفة رعدية';
    if (snow > 0.2) return 'ثلج';
    if (rain > 0.55) return 'مطر غزير';
    if (rain > 0.05) return 'مطر';
    if (fog > 0.4) return 'ضباب';
    if (cloud > 0.75) return 'غائم';
    if (cloud > 0.3) return 'غائم جزئياً';
    return 'صافٍ';
  }

  String icon(bool night) {
    if (dust > 0.35 || fog > 0.4) return '🌫';
    if (storm > 0.3) return '⛈';
    if (snow > 0.2) return '❄';
    if (rain > 0.05) return '🌧';
    if (cloud > 0.75) return '☁';
    if (cloud > 0.3) return night ? '☁' : '⛅';
    return night ? '🌙' : '☀';
  }
}

final _presets = <_Wx?>[
  null,
  _Wx.preset(0),
  _Wx.preset(3, cloud: 0.9),
  _Wx.preset(63, rain: 0.75, cloud: 0.95),
  _Wx.preset(95, rain: 0.9, cloud: 1, storm: 1, wind: 8),
  _Wx.preset(45, fog: 0.8, cloud: 0.6),
  _Wx.preset(0, dust: 0.85, cloud: 0.2, wind: 9),
  _Wx.preset(73, snow: 0.8, cloud: 0.95),
];
const _timeNames = ['الوقت الحقيقي', 'نهار', 'غروب', 'ليل'];
const _modelNames = {'sport': 'رياضية', 'sedan': 'سيدان', 'suv': 'دفع رباعي'};
const _colorNames = {'green': 'أخضر منبر', 'black': 'أسود', 'white': 'أبيض', 'silver': 'فضي', 'red': 'أحمر', 'blue': 'أزرق', 'gold': 'ذهبي'};

/// حالة المشهد الحيّة (تتحدث كل إطار بلا إعادة بناء الصفحة)
class _Scene {
  double t = 0, q = 0, v = 0, a = 0, brake = 0, tail = 0.3, curv = 0, lean = 0, blink = 0, pitch = 0, spin = 0, flash = 0, splash = 0;
  double sunEl = 45, sunAz = 180, moonEl = -20, moonAz = 0, moonPh = 0.5, heading = 180;
  double rain = 0, snow = 0, cloud = 0, fog = 0, dust = 0, storm = 0, wind = 0;
  double holyB = 0, holyD = 0; // اتجاه ومسافة حرم الإمام الحسين (ع)
  int bolt = 0;
  bool over = false; // تجاوز حد السرعة
  String model = 'sport', color = 'green';
}

/// أبعاد المسرح المحسوبة من التخطيط
class _Stage {
  final double hz, cx, carY, cw, dpr;
  const _Stage(this.hz, this.cx, this.carY, this.cw, this.dpr);
}

/// صور مرسومة مرة واحدة (نخيل، غيوم، أنسجة، جزيئات) تُعاد بالـGPU كل إطار
class _Art {
  static bool _ready = false;
  static late ui.Image dot, streak, flake, asphalt, sand;
  static late List<ui.Image> palms, clouds;

  static ui.Image _img(int w, int h, void Function(Canvas) draw) {
    final r = ui.PictureRecorder();
    draw(Canvas(r, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble())));
    final p = r.endRecording();
    final im = p.toImageSync(w, h);
    p.dispose();
    return im;
  }

  static void ensure() {
    if (_ready) return;
    _ready = true;
    dot = _img(64, 64, (c) => c.drawCircle(const Offset(32, 32), 32, Paint()..shader = ui.Gradient.radial(const Offset(32, 32), 32, [Colors.white, Colors.white.withOpacity(0.35), Colors.white.withOpacity(0)], [0, 0.3, 1])));
    streak = _img(8, 96, (c) {
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2.5, 0, 3, 96), const Radius.circular(1.5)), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 96), [Colors.white.withOpacity(0), Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.25)], [0, 0.82, 1]));
    });
    flake = _img(32, 32, (c) => c.drawCircle(const Offset(16, 16), 16, Paint()..shader = ui.Gradient.radial(const Offset(16, 16), 16, [Colors.white, Colors.white.withOpacity(0.85), Colors.white.withOpacity(0)], [0, 0.35, 1])));
    asphalt = _img(256, 256, _asphaltTex);
    sand = _img(256, 256, _sandTex);
    palms = [for (int v = 0; v < 3; v++) _img(256, 320, (c) => _palm(c, v))];
    clouds = [for (int v = 0; v < 3; v++) _img(512, 220, (c) => _cloud(c, v))];
  }

  /// حبيبات الأسفلت: حصى داكنة وفاتحة متناثرة (قابلة للتكرار بلا فواصل)
  static void _asphaltTex(Canvas c) {
    final r = math.Random(5);
    for (int pass = 0; pass < 4; pass++) {
      final pts = <Offset>[];
      for (int i = 0; i < 900; i++) {
        pts.add(Offset(r.nextDouble() * 256, r.nextDouble() * 256));
      }
      final col = [Colors.black.withOpacity(0.45), Colors.black.withOpacity(0.25), Colors.white.withOpacity(0.16), Colors.white.withOpacity(0.08)][pass];
      c.drawPoints(ui.PointMode.points, pts, Paint()
        ..color = col
        ..strokeWidth = [1.6, 2.6, 1.3, 2.2][pass]
        ..strokeCap = StrokeCap.round);
    }
    for (int i = 0; i < 26; i++) {
      final o = Offset(r.nextDouble() * 256, r.nextDouble() * 256);
      c.drawOval(Rect.fromCenter(center: o, width: 10 + r.nextDouble() * 30, height: 6 + r.nextDouble() * 16), Paint()..color = Colors.black.withOpacity(0.05 + r.nextDouble() * 0.05));
    }
  }

  /// رمل الصحراء: تموجات ريح + حبيبات
  static void _sandTex(Canvas c) {
    final r = math.Random(9);
    for (double y = 4; y < 256; y += 11) {
      final pa = Path()..moveTo(0, y);
      for (double x = 0; x <= 256; x += 8) {
        pa.lineTo(x, y + math.sin(x / 256 * math.pi * 4 + y * 0.3) * 3);
      }
      c.drawPath(pa, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF5A3C14).withOpacity(0.13));
      c.drawPath(pa.shift(const Offset(0, 2.2)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withOpacity(0.1));
    }
    for (int pass = 0; pass < 2; pass++) {
      final pts = [for (int i = 0; i < 700; i++) Offset(r.nextDouble() * 256, r.nextDouble() * 256)];
      c.drawPoints(ui.PointMode.points, pts, Paint()
        ..color = pass == 0 ? const Color(0xFF3D2A10).withOpacity(0.25) : Colors.white.withOpacity(0.15)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round);
    }
  }

  /// نخلة عراقية: جذع مخروطي بحلقات وكرانيف، سعف بوريقات بطبقتين، وعذوق تمر
  static void _palm(Canvas c, int v) {
    final r = math.Random(31 + v);
    const bx = 128.0, by = 318.0;
    final tx = 128.0 + (v - 1) * 10, ty = 70.0 + v * 6;
    final trunk = Path()
      ..moveTo(bx - 10, by)
      ..quadraticBezierTo(bx - 6, (by + ty) / 2, tx - 6, ty)
      ..lineTo(tx + 6, ty)
      ..quadraticBezierTo(bx + 7, (by + ty) / 2, bx + 10, by)
      ..close();
    c.drawPath(trunk, Paint()..shader = ui.Gradient.linear(const Offset(bx - 10, 0), const Offset(bx + 10, 0), [const Color(0xFF5B4329), const Color(0xFF8B6B44), const Color(0xFF4A351F)], [0, 0.45, 1]));
    for (double u = 0.03; u < 0.97; u += 0.045) {
      final x = (1 - u) * (1 - u) * bx + 2 * (1 - u) * u * (bx - 1) + u * u * tx, y = by + (ty - by) * u, hw = 10 - 4 * u;
      c.drawLine(Offset(x - hw, y), Offset(x + hw, y - 3), Paint()
        ..strokeWidth = 1.6
        ..color = const Color(0xFF2E2112).withOpacity(0.7));
    }
    void frond(double a, double len, Color col, double wd) {
      final ex = tx + math.sin(a) * len, ey = ty - math.cos(a) * len * 0.35 + (a.abs() * 0.55 + 0.25) * len * 0.55;
      final cxq = tx + math.sin(a) * len * 0.5, cyq = ty - len * 0.38 - math.cos(a) * 10;
      final pa = Path()
        ..moveTo(tx, ty)
        ..quadraticBezierTo(cxq, cyq, ex, ey);
      c.drawPath(pa, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = wd
        ..strokeCap = StrokeCap.round
        ..color = col);
      final lw = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = col;
      for (double u = 0.14; u < 0.98; u += 0.045) {
        final px = (1 - u) * (1 - u) * tx + 2 * (1 - u) * u * cxq + u * u * ex, py = (1 - u) * (1 - u) * ty + 2 * (1 - u) * u * cyq + u * u * ey;
        final dx = 2 * (1 - u) * (cxq - tx) + 2 * u * (ex - cxq), dy = 2 * (1 - u) * (cyq - ty) + 2 * u * (ey - cyq), dl = math.sqrt(dx * dx + dy * dy) + 1e-6;
        final nx = -dy / dl, ny = dx / dl, ll = (1 - u * 0.7) * 20 * (0.85 + r.nextDouble() * 0.3);
        c.drawLine(Offset(px, py), Offset(px + nx * ll + dx / dl * 5, py + ny * ll + 9), lw);
        c.drawLine(Offset(px, py), Offset(px - nx * ll + dx / dl * 5, py - ny * ll + 9), lw);
      }
    }

    for (int i = 0; i < 8; i++) {
      frond(-1.9 + i * 0.54 + r.nextDouble() * 0.2, 92 + r.nextDouble() * 22, const Color(0xFF2B4A1E), 3.2);
    }
    final dc = const Color(0xFFB0621C);
    for (final sd in const [-1.0, 1.0]) {
      for (int k = 0; k < 9; k++) {
        c.drawCircle(Offset(tx + sd * (10 + r.nextDouble() * 8), ty + 10 + r.nextDouble() * 18), 3, Paint()..color = _mix(dc, const Color(0xFF6B3410), r.nextDouble()));
      }
    }
    for (int i = 0; i < 9; i++) {
      frond(-1.75 + i * 0.44 + r.nextDouble() * 0.15, 98 + r.nextDouble() * 26, _mix(const Color(0xFF4F7F33), const Color(0xFF6E9441), r.nextDouble()), 3.4);
    }
    c.drawCircle(Offset(tx, ty), 7, Paint()..color = const Color(0xFF3B5A26));
  }

  /// غيمة ركامية: كتل متداخلة ناعمة، قاعدتها رمادية وقمتها بيضاء
  static void _cloud(Canvas c, int v) {
    final r = math.Random(70 + v);
    final blobs = <(Offset, double)>[];
    for (int i = 0; i < 9; i++) {
      final x = 90 + i * 42.0 + r.nextDouble() * 20, rad = 34 + r.nextDouble() * 42 * (1 - (i - 4).abs() / 6);
      blobs.add((Offset(x, 150 - rad * 0.55), rad));
    }
    final soft = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    c.saveLayer(const Rect.fromLTWH(0, 0, 512, 220), Paint());
    for (final b in blobs) {
      c.drawCircle(b.$1, b.$2, soft..color = Colors.white);
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 120, 380, 46), const Radius.circular(23)), soft..color = Colors.white);
    c.drawRect(const Rect.fromLTWH(0, 0, 512, 220), Paint()
      ..blendMode = BlendMode.srcATop
      ..shader = ui.Gradient.linear(const Offset(0, 40), const Offset(0, 170), [Colors.white, const Color(0xFFDCE2E8), const Color(0xFF9AA4AE)], [0, 0.55, 1]));
    c.restore();
  }
}
/// هندسة نماذج السيارات (مولّدة من النموذج الأولي): الوحدة = عرض السيارة، y سالب للأعلى
class _CarM {
  final List<double> tire, roof, mirror, plate, diff, third;
  final List<List<double>> exh;
  final List<double>? grille, spoiler;
  final List<List<double>> body, cab, glass, led, lamp;
  final List<List<double>>? bar;
  final double bumper, height;
  final double? trunk;
  final bool rails;
  const _CarM({required this.tire, required this.roof, required this.mirror, required this.plate, required this.diff, required this.third, required this.exh, this.grille, this.spoiler, required this.body, required this.cab, required this.glass, required this.led, required this.lamp, this.bar, required this.bumper, required this.height, this.trunk, required this.rails});
}

const _carModels = <String, _CarM>{
  'sport': _CarM(
    tire: [0.33, 0.478, 0.205], roof: [-0.18, -0.613, 0.18], mirror: [0.325, -0.495, 0.41, -0.455], plate: [-0.105, -0.29, 0.105, -0.235], diff: [-0.36, -0.165, 0.36, -0.07], third: [-0.06, -0.603, 0.06, -0.594],
    exh: [[0.07, -0.14, 0.15, -0.1]], grille: [-0.15, -0.392, 0.15, 4.0], spoiler: null,
    body: [[0.0, -0.43, -0.07], [1.0, -0.488, -0.115], [3.0, -0.512, -0.17, -0.512, -0.3, -0.49, -0.355], [3.0, -0.475, -0.405, -0.43, -0.43, -0.37, -0.432], [3.0, -0.2, -0.44, 0.2, -0.44, 0.37, -0.432], [3.0, 0.43, -0.43, 0.475, -0.405, 0.49, -0.355], [3.0, 0.512, -0.3, 0.512, -0.17, 0.488, -0.115], [1.0, 0.43, -0.07], [2.0, 0.0, -0.055, -0.43, -0.07]],
    cab: [[0.0, -0.325, -0.425], [3.0, -0.3, -0.5, -0.26, -0.585, -0.195, -0.612], [3.0, -0.1, -0.632, 0.1, -0.632, 0.195, -0.612], [3.0, 0.26, -0.585, 0.3, -0.5, 0.325, -0.425]],
    glass: [[0.0, -0.255, -0.44], [3.0, -0.235, -0.51, -0.205, -0.575, -0.16, -0.594], [3.0, -0.08, -0.606, 0.08, -0.606, 0.16, -0.594], [3.0, 0.205, -0.575, 0.235, -0.51, 0.255, -0.44], [2.0, 0.0, -0.432, -0.255, -0.44]],
    led: [[0.0, -0.46, -0.366], [3.0, -0.2, -0.384, 0.2, -0.384, 0.46, -0.366]],
    lamp: [[0.0, 0.392, -0.383], [1.0, 0.478, -0.372], [2.0, 0.492, -0.366, 0.49, -0.352], [1.0, 0.395, -0.352]],
    bar: [[0.0, -0.475, -0.373], [3.0, -0.2, -0.392, 0.2, -0.392, 0.475, -0.373], [1.0, 0.475, -0.357], [3.0, 0.2, -0.375, -0.2, -0.375, -0.475, -0.357]], bumper: -0.2, height: 0.632, trunk: null, rails: false,
  ),
  'sedan': _CarM(
    tire: [0.335, 0.47, 0.2], roof: [-0.25, -0.69, 0.25], mirror: [0.39, -0.53, 0.475, -0.49], plate: [-0.105, -0.33, 0.105, -0.275], diff: [-0.3, -0.15, 0.3, -0.08], third: [-0.07, -0.672, 0.07, -0.662],
    exh: [[0.3, -0.13, 0.38, -0.1]], grille: null, spoiler: null,
    body: [[0.0, -0.43, -0.075], [1.0, -0.48, -0.12], [3.0, -0.5, -0.17, -0.5, -0.33, -0.488, -0.4], [3.0, -0.482, -0.44, -0.46, -0.455, -0.42, -0.458], [3.0, -0.2, -0.466, 0.2, -0.466, 0.42, -0.458], [3.0, 0.46, -0.455, 0.482, -0.44, 0.488, -0.4], [3.0, 0.5, -0.33, 0.5, -0.17, 0.48, -0.12], [1.0, 0.43, -0.075], [2.0, 0.0, -0.06, -0.43, -0.075]],
    cab: [[0.0, -0.4, -0.45], [3.0, -0.37, -0.55, -0.33, -0.66, -0.27, -0.69], [3.0, -0.15, -0.71, 0.15, -0.71, 0.27, -0.69], [3.0, 0.33, -0.66, 0.37, -0.55, 0.4, -0.45]],
    glass: [[0.0, -0.345, -0.475], [3.0, -0.32, -0.56, -0.29, -0.64, -0.24, -0.665], [3.0, -0.12, -0.68, 0.12, -0.68, 0.24, -0.665], [3.0, 0.29, -0.64, 0.32, -0.56, 0.345, -0.475], [2.0, 0.0, -0.468, -0.345, -0.475]],
    led: [[0.0, -0.2, -0.405], [1.0, 0.2, -0.405]],
    lamp: [[0.0, 0.24, -0.425], [1.0, 0.47, -0.43], [2.0, 0.488, -0.425, 0.49, -0.4], [1.0, 0.488, -0.37], [1.0, 0.4, -0.375], [1.0, 0.36, -0.395], [1.0, 0.24, -0.395]],
    bar: null, bumper: -0.215, height: 0.71, trunk: -0.452, rails: false,
  ),
  'suv': _CarM(
    tire: [0.33, 0.47, 0.27], roof: [-0.36, -0.835, 0.36], mirror: [0.44, -0.66, 0.53, -0.61], plate: [-0.11, -0.44, 0.11, -0.38], diff: [-0.4, -0.22, 0.4, -0.13], third: [-0.12, -0.828, 0.12, -0.818],
    exh: [[0.28, -0.19, 0.36, -0.16]], grille: null, spoiler: [-0.36, -0.835, 0.36, -0.825],
    body: [[0.0, -0.44, -0.13], [1.0, -0.485, -0.16], [3.0, -0.5, -0.22, -0.5, -0.42, -0.49, -0.52], [3.0, -0.486, -0.56, -0.465, -0.575, -0.43, -0.578], [3.0, -0.2, -0.586, 0.2, -0.586, 0.43, -0.578], [3.0, 0.465, -0.575, 0.486, -0.56, 0.49, -0.52], [3.0, 0.5, -0.42, 0.5, -0.22, 0.485, -0.16], [1.0, 0.44, -0.13], [2.0, 0.0, -0.115, -0.44, -0.13]],
    cab: [[0.0, -0.445, -0.57], [3.0, -0.43, -0.66, -0.41, -0.79, -0.38, -0.835], [3.0, -0.2, -0.85, 0.2, -0.85, 0.38, -0.835], [3.0, 0.41, -0.79, 0.43, -0.66, 0.445, -0.57]],
    glass: [[0.0, -0.37, -0.6], [3.0, -0.36, -0.68, -0.35, -0.76, -0.33, -0.79], [3.0, -0.18, -0.8, 0.18, -0.8, 0.33, -0.79], [3.0, 0.35, -0.76, 0.36, -0.68, 0.37, -0.6], [2.0, 0.0, -0.592, -0.37, -0.6]],
    led: [[0.0, -0.28, -0.58], [1.0, 0.28, -0.58]],
    lamp: [[0.0, 0.4, -0.63], [1.0, 0.485, -0.625], [1.0, 0.492, -0.47], [1.0, 0.44, -0.47], [1.0, 0.4, -0.53]],
    bar: null, bumper: -0.27, height: 0.85, trunk: null, rails: true,
  ),
};
const _carColors = <String, List<int>>{
  'green': [0xFF57C6A9, 0xFF17705F, 0xFF0C4337, 0xFF05211B],
  'black': [0xFF5A6068, 0xFF1C1F23, 0xFF0E1013, 0xFF050607],
  'white': [0xFFFFFFFF, 0xFFE6E9EC, 0xFFB9BEC4, 0xFF7E848B],
  'silver': [0xFFE3E7EB, 0xFFA9B0B7, 0xFF6E757D, 0xFF3A3F45],
  'red': [0xFFFF6B6B, 0xFFC4161C, 0xFF7E0C10, 0xFF3A0507],
  'blue': [0xFF6FA8FF, 0xFF1E4FA8, 0xFF12306A, 0xFF081733],
  'gold': [0xFFF6DE9A, 0xFFC9A04A, 0xFF8A6A26, 0xFF45330F],
};

class CarPage extends StatefulWidget {
  const CarPage({super.key});
  static bool open = false;
  @override
  State<CarPage> createState() => _CarPageState();
}

class _CarPageState extends State<CarPage> with SingleTickerProviderStateMixin {
  List<Lyric> ly = const [];
  String? _id;
  final _sc = _Scene();
  final _frame = ValueNotifier<int>(0);
  final _kmh = ValueNotifier<int>(0);
  final _clock = ValueNotifier<DateTime>(DateTime.now());
  final _fx = ValueNotifier<String?>(null); // أيقونة تأكيد الإيماءة
  final _banner = ValueNotifier<String?>(null); // تنبيه الاستراحة/السرعة
  late final Ticker _tk;
  Duration _last = Duration.zero;
  Timer? _ct, _wt, _wt2, _fxT, _bnT;
  StreamSubscription<Position>? _gs;
  bool gps = false;
  DateTime? _backAt;
  // GPS
  Position? _lp;
  double _lt = 0, _rawV = 0, _turn = 0, _acc = 99, _fixAt = -99, _blinkHold = 0;
  double _lat = 32.616, _lon = 44.024; // كربلاء افتراضياً
  // الطقس والوقت
  _Wx _wx = _Wx();
  int _wMode = 0, _tMode = 0;
  final _rnd = math.Random();
  // الإعدادات
  int _limit = 0; // 0 = بلا تنبيه
  bool _restOn = true;
  // الرحلة
  final DateTime _start = DateTime.now();
  double _dist = 0, _moveSec = 0, _maxV = 0, _driveSec = 0, _stopSec = 0, _overSec = 0, _lastAlert = -999, _nextRest = 7200;
  bool _alertArmed = true;
  final Set<String> _heard = {};
  String? _curId;
  double _curSec = 0;
  // صوت التنبيه الهادئ
  AudioPlayer? _beep;

  double get _now => DateTime.now().millisecondsSinceEpoch / 1000.0;

  // قياس زمن الإطارات وتخفيف الرسم تلقائياً إذا الجهاز ما يلحق (منع التقطيع)
  final _ft = <double>[];
  double _goodFor = 0;
  void _timings(List<ui.FrameTiming> ts) {
    for (final t in ts) {
      _ft.add(math.max(t.buildDuration.inMicroseconds, t.rasterDuration.inMicroseconds) / 1000);
    }
    if (_ft.length < 45) return;
    _ft.sort();
    final p90 = _ft[(_ft.length * 0.9).floor()], med = _ft[_ft.length ~/ 2];
    debugPrint('MBCAR q=${_World.q} med=${med.toStringAsFixed(1)}ms p90=${p90.toStringAsFixed(1)}ms');
    if (p90 > 22 && _World.q > 0) {
      _World.q--;
      _goodFor = 0;
    } else if (p90 < 11) {
      _goodFor += _ft.length / 60;
      if (_goodFor > 12 && _World.q < 2 && app.player.perf == 0) {
        _World.q++;
        _goodFor = 0;
      }
    }
    _ft.clear();
  }

  @override
  void initState() {
    super.initState();
    CarPage.open = true;
    _World.q = app.player.perf == 0 ? 2 : 1;
    SchedulerBinding.instance.addTimingsCallback(_timings);
    WakelockPlus.enable();
    app.player.addListener(_r);
    _r();
    _tk = createTicker(_tick)..start();
    _env();
    _ct = Timer.periodic(const Duration(seconds: 1), (_) {
      _clock.value = DateTime.now();
      if (DateTime.now().second % 20 == 0) _env();
    });
    SharedPreferences.getInstance().then((p) async {
      _wMode = (p.getInt('car.wx') ?? 0) % _presets.length;
      _tMode = (p.getInt('car.tm') ?? 0) % 4;
      _sc.model = p.getString('car.model') ?? 'sport';
      _sc.color = p.getString('car.color') ?? 'green';
      if (!_carModels.containsKey(_sc.model)) _sc.model = 'sport';
      if (!_carColors.containsKey(_sc.color)) _sc.color = 'green';
      _limit = p.getInt('car.limit') ?? 0;
      _restOn = p.getBool('car.rest') ?? true;
      _env();
      if (mounted) setState(() {});
      if (p.getBool('car.gps') ?? false) {
        await _gpsOn(ask: false);
      } else {
        await _lastKnown();
      }
      _wxFetch();
    });
    _wt = Timer.periodic(const Duration(minutes: 15), (_) => _wxFetch());
  }

  // ---------------- السرعة والاتجاه ----------------
  void _onPos(Position p) {
    final now = p.timestamp.millisecondsSinceEpoch / 1000.0;
    _acc = p.accuracy;
    double? sp;
    // سرعة الجهاز (دوبلر) هي الأدق إن كانت دقتها مقبولة
    if (p.speed.isFinite && p.speed >= 0 && (p.speedAccuracy <= 0 || p.speedAccuracy < 2.5)) sp = p.speed;
    final lp = _lp;
    if (lp != null) {
      final dt = now - _lt;
      if (dt > 0.2 && dt < 15) {
        final d = Geolocator.distanceBetween(lp.latitude, lp.longitude, p.latitude, p.longitude);
        if (sp == null && p.accuracy < 20 && lp.accuracy < 20) sp = d / dt; // احتياطي: المسافة/الزمن
        if (sp != null) {
          final lim = _rawV + 8 * dt; // رفض القفزات غير الممكنة
          if (sp > lim) sp = lim;
          if (sp > 1.2 && d < sp * dt * 1.6 + 6) _dist += d;
        }
        if (sp != null && sp > 2.5 && p.heading >= 0 && lp.heading >= 0 && (p.headingAccuracy <= 0 || p.headingAccuracy < 25)) {
          final dh = ((p.heading - lp.heading + 540) % 360) - 180;
          _turn += (_cl((dh / dt) * math.pi / 180, -0.6, 0.6) - _turn) * 0.6;
          _sc.heading = p.heading;
        } else if ((sp ?? 0) < 1.5) {
          _turn *= 0.5;
        }
      }
    }
    _lp = p;
    _lt = now;
    _lat = p.latitude;
    _lon = p.longitude;
    if (sp == null) return;
    if (sp < 0.6) sp = 0; // ضجيج التوقف
    _rawV = sp;
    _fixAt = _now;
  }

  Future<void> _lastKnown() async {
    try {
      final pm = await Geolocator.checkPermission();
      if (pm == LocationPermission.always || pm == LocationPermission.whileInUse) {
        final p = await Geolocator.getLastKnownPosition();
        if (p != null) {
          _lat = p.latitude;
          _lon = p.longitude;
          _env();
        }
      }
    } catch (_) {}
  }

  Future<void> _gpsOn({bool ask = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (ask) _say('شغّل الموقع (GPS) بالهاتف حتى تظهر السرعة');
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied && ask) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        if (ask) _say('السرعة تحتاج صلاحية الموقع');
        return;
      }
      await _gs?.cancel();
      _gs = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0, intervalDuration: const Duration(milliseconds: 1000)),
      ).listen(_onPos, onError: (_) {});
      if (mounted) setState(() => gps = true);
      (await SharedPreferences.getInstance()).setBool('car.gps', true);
      final lp = await Geolocator.getLastKnownPosition();
      if (lp != null) {
        _lat = lp.latitude;
        _lon = lp.longitude;
        _env();
      }
    } catch (_) {
      if (ask) _say('تعذّر تشغيل عدّاد السرعة');
    }
  }

  Future<void> _gpsOff() async {
    await _gs?.cancel();
    _gs = null;
    _rawV = 0;
    _turn = 0;
    if (mounted) setState(() => gps = false);
    (await SharedPreferences.getInstance()).setBool('car.gps', false);
  }

  // ---------------- الشمس والقمر والطقس ----------------
  void _env() {
    final n = DateTime.now().toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5 - 2451545.0;
    const rad = math.pi / 180;
    final l = (280.460 + 0.9856474 * n) % 360, g = ((357.528 + 0.9856003 * n) % 360) * rad;
    final lam = (l + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) * rad;
    final (se, sa) = _skyPos(lam, n, _lat, _lon);
    final ph = (((n - 5.1) / 29.530588853) % 1 + 1) % 1; // عمر القمر من محاق مرجعي
    final (me, ma) = _skyPos(lam + ph * 2 * math.pi, n, _lat, _lon);
    _sc
      ..sunEl = se
      ..sunAz = sa
      ..moonEl = me
      ..moonAz = ma
      ..moonPh = ph;
    const kLat = 32.6164 * rad, kLon = 44.0324 * rad;
    final la1 = _lat * rad, dl = kLon - _lon * rad;
    _sc.holyB = (math.atan2(math.sin(dl) * math.cos(kLat), math.cos(la1) * math.sin(kLat) - math.sin(la1) * math.cos(kLat) * math.cos(dl)) / rad + 360) % 360;
    _sc.holyD = Geolocator.distanceBetween(_lat, _lon, 32.6164, 44.0324) / 1000;
    final h = _sc.heading;
    switch (_tMode) {
      case 1:
        _sc
          ..sunEl = 48
          ..sunAz = h - 35;
      case 2:
        _sc
          ..sunEl = 2.5
          ..sunAz = h + 18;
      case 3:
        _sc
          ..sunEl = -30
          ..moonEl = 28
          ..moonAz = h + 25
          ..moonPh = ph > 0.2 && ph < 0.8 ? ph : 0.42;
    }
  }

  Future<void> _wxFetch() async {
    final la = _lat.toStringAsFixed(3), lo = _lon.toStringAsFixed(3);
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    Future<Map<String, dynamic>> get(String u) async {
      final r = await (await c.getUrl(Uri.parse(u))).close().timeout(const Duration(seconds: 10));
      return jsonDecode(await r.transform(utf8.decoder).join()) as Map<String, dynamic>;
    }

    try {
      final m = await get('https://api.open-meteo.com/v1/forecast?latitude=$la&longitude=$lo&current=temperature_2m,weather_code,cloud_cover,precipitation,wind_speed_10m&hourly=visibility&forecast_hours=1');
      final cu = m['current'] as Map<String, dynamic>;
      double nv(String k) => (cu[k] as num?)?.toDouble() ?? 0.0;
      final code = (cu['weather_code'] as num?)?.toInt() ?? 0;
      final w = _Wx()
        ..code = code
        ..temp = nv('temperature_2m')
        ..cloud = _cl(nv('cloud_cover') / 100)
        ..wind = nv('wind_speed_10m') / 3.6;
      const rainBy = <int, double>{51: .25, 53: .4, 55: .55, 56: .4, 57: .55, 61: .45, 63: .7, 65: 1.0, 66: .6, 67: .8, 80: .55, 81: .8, 82: 1.0, 95: .8, 96: .9, 99: 1.0};
      const snowBy = <int, double>{71: .4, 73: .7, 75: 1.0, 77: .3, 85: .6, 86: 1.0};
      w.snow = snowBy[code] ?? 0.0;
      w.rain = math.max(rainBy[code] ?? 0.0, w.snow > 0 ? 0.0 : _cl(nv('precipitation') / 6));
      w.storm = code >= 95 ? 1.0 : 0.0;
      double vis = 0;
      try {
        vis = (((m['hourly'] as Map<String, dynamic>)['visibility'] as List).first as num).toDouble();
      } catch (_) {}
      w.fog = math.max(code == 45 || code == 48 ? 0.75 : 0.0, vis > 0 && vis < 8000 ? _cl(1 - vis / 8000) : 0.0);
      if (w.rain > 0 || w.snow > 0) w.cloud = math.max(w.cloud, 0.85);
      try {
        final aq = await get('https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$la&longitude=$lo&current=dust');
        final d = ((aq['current'] as Map<String, dynamic>)['dust'] as num?)?.toDouble() ?? 0.0;
        w.dust = _cl((d - 120) / 600);
      } catch (_) {}
      if (mounted) setState(() => _wx = w);
    } catch (e) {
      debugPrint('car wx fail $e');
      _wt2?.cancel();
      _wt2 = Timer(const Duration(seconds: 60), _wxFetch); // إعادة المحاولة
    } finally {
      c.close();
    }
  }

  _Wx get _wxNow => _presets[_wMode] ?? _wx;

  // ---------------- كل إطار ----------------
  void _tick(Duration e) {
    final dt = _cl((e - _last).inMicroseconds / 1e6, 0, 0.05);
    _last = e;
    if (dt <= 0) return;
    final s = _sc, playing = app.player.p.playing;
    s.t += dt;
    double target;
    if (gps) {
      final age = _now - _fixAt;
      target = age < 5 ? _rawV : _rawV * _cl(1 - (age - 5) / 5); // فقدان الإشارة: تباطؤ تدريجي
    } else {
      target = playing ? 13.9 : 0; // بدون GPS: سير عرضي 50 كم/س مع التشغيل
    }
    final prev = s.v;
    s.v += (target - s.v) * math.min(1.0, dt * 2.4);
    final acc = (s.v - prev) / dt;
    s.a += (acc - s.a) * math.min(1.0, dt * 4);
    final braking = gps ? ((s.a < -0.7 && s.v > 0.5) || s.v < 0.35) : !playing;
    s.brake += ((braking ? 1.0 : 0.0) - s.brake) * math.min(1.0, dt * 14);
    s.q += s.v * dt / 2.5; // وحدة العمق = 2.5 م
    if (playing) s.spin += dt * 0.8;
    final k = gps && s.v > 2.5 ? _cl(_turn / s.v, -0.03, 0.03) : 0.0;
    s.curv += (k - s.curv) * math.min(1.0, dt * 1.2);
    s.lean += ((gps ? _cl(s.v * _turn / 9.8, -0.5, 0.5) : 0.0) - s.lean) * math.min(1.0, dt * 3);
    if (gps && _turn.abs() > 0.13 && s.v < 17) _blinkHold = 1.6 * _turn.sign;
    if (_blinkHold != 0) {
      final sg = _blinkHold.sign;
      _blinkHold -= sg * dt;
      if (_blinkHold.sign != sg) _blinkHold = 0;
    }
    s.blink = _blinkHold.sign;
    s.pitch += (_cl(-s.a * 0.5, -2.5, 2.5) - s.pitch) * math.min(1.0, dt * 5);
    final w = _wxNow, m = math.min(1.0, dt * 0.6);
    s
      ..rain += (w.rain - s.rain) * m
      ..snow += (w.snow - s.snow) * m
      ..cloud += (w.cloud - s.cloud) * m
      ..fog += (w.fog - s.fog) * m
      ..dust += (w.dust - s.dust) * m
      ..storm += (w.storm - s.storm) * m
      ..wind += (w.wind - s.wind) * m;
    if (s.storm > 0.3 && _rnd.nextDouble() < dt * 0.12) {
      s.flash = 1;
      s.bolt++;
    }
    s.flash = math.max(0.0, s.flash - dt * 3.5);
    final lightsOn = 1 - _sm(-3, 5, s.sunEl);
    final murk = math.max(math.max(s.fog, s.dust), s.rain * 0.8);
    s.tail += ((0.3 + 0.55 * math.max(lightsOn, murk)) - s.tail) * math.min(1.0, dt * 2);
    s.splash = s.rain * _cl(s.v / 15);
    _stats(dt, playing);
    final kmh = gps ? (s.v * 3.6).round() : 0;
    if (kmh != _kmh.value) _kmh.value = kmh;
    _frame.value++;
  }

  /// إحصاءات الرحلة، تنبيه السرعة الهادئ، وتذكير الاستراحة
  void _stats(double dt, bool playing) {
    final v = _sc.v;
    if (gps && v > 1.5) _moveSec += dt;
    if (gps && v > _maxV) _maxV = v;
    // القصائد المسموعة (30 ثانية فأكثر)
    final id = app.player.cur?.id;
    if (id != _curId) {
      _curId = id;
      _curSec = 0;
    }
    if (playing && id != null) {
      _curSec += dt;
      if (_curSec > 30) _heard.add(id);
    }
    if (!gps) return;
    // تذكير الاستراحة: كل ساعتين قيادة متواصلة، والتوقف 15 دقيقة يصفّر العداد
    if (v > 2.8) {
      _driveSec += dt;
      _stopSec = 0;
    } else {
      _stopSec += dt;
      if (_stopSec > 900) {
        _driveSec = 0;
        _nextRest = 7200;
      }
    }
    if (_restOn && _driveSec > _nextRest) {
      _nextRest = _driveSec + 7200;
      _chime();
      final hr = (_driveSec / 3600).floor();
      _show('صار لك ${hr == 2 ? 'ساعتين' : '$hr ساعات'} تسوق — استراحة قصيرة تفيدك ☕', 12);
    }
    // تنبيه السرعة: مرة وحدة عند التجاوز (3 ثوانٍ متواصلة)، ولا يتكرر إلا بعد النزول تحت الحد بـ5 وبفاصل دقيقتين
    if (_limit > 0) {
      final kmh = v * 3.6;
      if (kmh > _limit + 2) {
        _overSec += dt;
      } else {
        _overSec = 0;
        if (kmh < _limit - 5) _alertArmed = true;
      }
      _sc.over = kmh > _limit + 2;
      if (_overSec > 3 && _alertArmed && _sc.t - _lastAlert > 120) {
        _alertArmed = false;
        _lastAlert = _sc.t;
        _chime();
        _show('تجاوزت $_limit كم/س', 4);
      }
    } else {
      _sc.over = false;
    }
  }

  void _show(String msg, int sec) {
    _banner.value = msg;
    _bnT?.cancel();
    _bnT = Timer(Duration(seconds: sec), () => _banner.value = null);
  }

  /// نغمة جرس ناعمة قصيرة (تُولَّد مرة وتُحفظ مؤقتاً) بصوت منخفض لا يقطع القصيدة
  Future<void> _chime() async {
    try {
      final f = File('${Directory.systemTemp.path}/minbar_chime.wav');
      if (!await f.exists()) {
        const sr = 22050;
        final n = (sr * 1.1).round(), d = ByteData(44 + n * 2);
        void str(int o, String s) {
          for (int i = 0; i < s.length; i++) {
            d.setUint8(o + i, s.codeUnitAt(i));
          }
        }

        str(0, 'RIFF');
        d.setUint32(4, 36 + n * 2, Endian.little);
        str(8, 'WAVE');
        str(12, 'fmt ');
        d.setUint32(16, 16, Endian.little);
        d.setUint16(20, 1, Endian.little);
        d.setUint16(22, 1, Endian.little);
        d.setUint32(24, sr, Endian.little);
        d.setUint32(28, sr * 2, Endian.little);
        d.setUint16(32, 2, Endian.little);
        d.setUint16(34, 16, Endian.little);
        str(36, 'data');
        d.setUint32(40, n * 2, Endian.little);
        for (int i = 0; i < n; i++) {
          final t = i / sr;
          double v = 0;
          // نغمتان متتاليتان (دينغ-دونغ) بتلاشٍ أسي وتوافقيات خفيفة
          if (t < 0.55) v += (math.sin(2 * math.pi * 784 * t) + 0.25 * math.sin(2 * math.pi * 1568 * t)) * math.exp(-t * 6) * math.min(1, t * 200);
          if (t > 0.28) {
            final u = t - 0.28;
            v += (math.sin(2 * math.pi * 587.3 * u) + 0.25 * math.sin(2 * math.pi * 1174.6 * u)) * math.exp(-u * 4.5) * math.min(1, u * 200);
          }
          d.setInt16(44 + i * 2, (v * 0.38 * 32767).round().clamp(-32767, 32767).toInt(), Endian.little);
        }
        await f.writeAsBytes(d.buffer.asUint8List());
      }
      _beep ??= AudioPlayer(handleAudioSessionActivation: false);
      await _beep!.setFilePath(f.path);
      await _beep!.setVolume(0.5);
      await _beep!.play();
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: tx(14, c: Colors.white)), duration: const Duration(seconds: 2)));
  }

  void _r() {
    final t = app.player.cur;
    if (t != null && t.id != _id) {
      _id = t.id;
      ly = const [];
      app.repo.lyricsFor(t).then((l) {
        if (mounted && _id == t.id) setState(() => ly = l);
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CarPage.open = false;
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    WakelockPlus.disable();
    app.player.removeListener(_r);
    _tk.dispose();
    for (final t in [_ct, _wt, _wt2, _fxT, _bnT]) {
      t?.cancel();
    }
    _gs?.cancel();
    _beep?.dispose();
    _frame.dispose();
    _kmh.dispose();
    _clock.dispose();
    _fx.dispose();
    _banner.dispose();
    super.dispose();
  }

  // ---------------- الخروج وملخص الرحلة ----------------
  String _dur(double sec) {
    final m = (sec / 60).round();
    return m < 60 ? '$m د' : '${m ~/ 60} س ${m % 60} د';
  }

  Future<void> _exit() async {
    final total = DateTime.now().difference(_start).inSeconds.toDouble();
    if (_dist > 300 || total > 180) {
      final avg = _moveSec > 30 ? _dist / _moveSec * 3.6 : 0.0;
      final sum = {'d': _dist, 't': total, 'm': _moveSec, 'avg': avg, 'max': _maxV * 3.6, 'n': _heard.length, 'at': DateTime.now().millisecondsSinceEpoch};
      SharedPreferences.getInstance().then((p) => p.setString('car.lastTrip', jsonEncode(sum)));
      final go = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: const Color(0xFF0B1F19),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (c) => _tripSheet(c, total, avg),
      );
      if (go != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _stat(String v, String l) => Expanded(
        child: Column(children: [
          Text(v, style: tx(20, c: Colors.white, h: 1.2)),
          Text(l, style: tx(12, c: Colors.white60)),
        ]),
      );

  Widget _tripSheet(BuildContext c, double total, double avg) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('ملخص الرحلة', style: tx(18, c: kGold)),
            const SizedBox(height: 16),
            Row(children: [_stat(gps ? '${(_dist / 1000).toStringAsFixed(1)} كم' : '—', 'المسافة'), _stat(_dur(total), 'المدة'), _stat('${_heard.length}', 'قصائد سمعتها')]),
            const SizedBox(height: 14),
            Row(children: [_stat(gps ? '${avg.round()}' : '—', 'معدل السرعة'), _stat(gps ? '${(_maxV * 3.6).round()}' : '—', 'أعلى سرعة'), _stat(gps ? _dur(_moveSec) : '—', 'وقت الحركة')]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(c, false), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)), child: Text('رجوع للقيادة', style: tx(14, c: Colors.white)))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: kGold), child: Text('خروج', style: tx(14, c: const Color(0xFF2A2106))))),
            ]),
          ]),
        ),
      );

  // ---------------- إعدادات وضع السيارة ----------------
  void _settings() async {
    final cars = await CarAuto.cars();
    var auto = await CarAuto.enabled();
    if (!mounted) return;
    Future<void> save(String k, Object v) async {
      final p = await SharedPreferences.getInstance();
      if (v is String) p.setString(k, v);
      if (v is int) p.setInt(k, v);
      if (v is bool) p.setBool(k, v);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1F19),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => StatefulBuilder(builder: (c, set) {
        Widget chip(String label, bool on, VoidCallback f) => GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                f();
                set(() {});
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: on ? const Color(0x33E8C468) : const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: on ? kGold : const Color(0x26FFFFFF))),
                child: Text(label, style: tx(13, c: on ? kGold : Colors.white)),
              ),
            );
        Widget head(String t) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Align(alignment: Alignment.centerRight, child: Text(t, style: tx(14, c: Colors.white70))));
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('إعدادات وضع السيارة', style: tx(17, c: kGold)),
                head('شكل السيارة'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in _modelNames.entries)
                    chip(e.value, _sc.model == e.key, () {
                      _sc.model = e.key;
                      save('car.model', e.key);
                    }),
                ]),
                head('اللون'),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final e in _carColors.entries)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _sc.color = e.key;
                        save('car.color', e.key);
                        set(() {});
                      },
                      child: Tooltip(
                        message: _colorNames[e.key] ?? '',
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(e.value[0]), Color(e.value[1]), Color(e.value[2])]),
                            border: Border.all(color: _sc.color == e.key ? kGold : const Color(0x33FFFFFF), width: _sc.color == e.key ? 3 : 1),
                          ),
                        ),
                      ),
                    ),
                ]),
                head('تنبيه السرعة (نغمة هادئة مرة وحدة)'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final v in const [0, 80, 100, 110, 120, 140])
                    chip(v == 0 ? 'إيقاف' : '$v', _limit == v, () {
                      _limit = v;
                      _alertArmed = true;
                      save('car.limit', v);
                      if (v > 0 && !gps) _gpsOn();
                    }),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _restOn,
                  activeColor: kGold,
                  onChanged: (v) {
                    _restOn = v;
                    save('car.rest', v);
                    set(() {});
                  },
                  title: Text('تذكير بالاستراحة كل ساعتين قيادة', style: tx(14, c: Colors.white)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: auto,
                  activeColor: kGold,
                  onChanged: (v) {
                    auto = v;
                    CarAuto.setEnabled(v);
                    set(() {});
                  },
                  title: Text('فتح وضع السيارة تلقائياً مع بلوتوث السيارة', style: tx(14, c: Colors.white)),
                  subtitle: Text(cars.isEmpty ? 'أول ما تتصل ببلوتوث سيارتك نسألك عنه' : cars.join('، '), style: tx(12, c: Colors.white54)),
                ),
                if (cars.isNotEmpty)
                  Wrap(spacing: 8, children: [
                    for (final n in [...cars])
                      chip('✕ $n', false, () {
                        CarAuto.forget(n);
                        cars.remove(n);
                      }),
                  ]),
                const SizedBox(height: 10),
                Text('Android Auto: افتح منبر من شاشة السيارة لتصفح المفضلة والإصدارات والتحكم بالتشغيل.', style: tx(12, c: Colors.white54, h: 1.6)),
              ]),
            ),
          ),
        );
      }),
    );
    if (mounted) setState(() {});
  }

  // ---------------- الواجهة ----------------
  Widget _btn(String ic, VoidCallback f, {double s = 84, bool main = false, bool on = false}) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          f();
        },
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: main ? const LinearGradient(colors: [kGold2, kGold], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
            color: main ? null : (on ? const Color(0x40E8C468) : const Color(0x33000000)),
            border: Border.all(color: main ? kGold2 : (on ? kGold : const Color(0x55FFFFFF)), width: 1.5),
            boxShadow: main ? const [BoxShadow(color: Color(0x66E8C468), blurRadius: 24)] : null,
          ),
          child: Center(child: PIcon(ic, color: main ? const Color(0xFF2A2106) : (on ? kGold : Colors.white), size: s * 0.44)),
        ),
      );

  Widget _chip(Widget child, VoidCallback onTap) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(color: const Color(0x59000000), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x33FFFFFF))),
          child: child,
        ),
      );

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _topBar() {
    final w = _wxNow, night = _sc.sunEl < -4;
    final t = w.temp.isNaN ? '' : ' ${w.temp.round()}°';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => _say('اضغط مطولاً على ✕ للخروج'),
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _exit();
          },
          child: const Padding(padding: EdgeInsets.all(10), child: PIcon(Ic.x, color: Colors.white, size: 26)),
        ),
        Flexible(
          flex: 5,
          child: _chip(Text('${w.icon(night)}$t  ${w.label}${_wMode == 0 ? '' : ' (تجربة)'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, c: Colors.white)), () {
            setState(() => _wMode = (_wMode + 1) % _presets.length);
            SharedPreferences.getInstance().then((p) => p.setInt('car.wx', _wMode));
            _say(_wMode == 0 ? 'الطقس الحقيقي' : 'تجربة: ${_presets[_wMode]!.label}');
          }),
        ),
        const SizedBox(width: 6),
        _chip(Row(mainAxisSize: MainAxisSize.min, children: [
          PIcon(Ic.moon, color: _tMode == 0 ? Colors.white : kGold, size: 16),
          const SizedBox(width: 4),
          Text(const ['تلقائي', 'نهار', 'غروب', 'ليل'][_tMode], style: tx(12, c: _tMode == 0 ? Colors.white : kGold)),
        ]), () {
          setState(() => _tMode = (_tMode + 1) % 4);
          SharedPreferences.getInstance().then((p) => p.setInt('car.tm', _tMode));
          _env();
          _say(_timeNames[_tMode]);
        }),
        const SizedBox(width: 6),
        Semantics(label: 'إعدادات السيارة', button: true, child: _chip(const PIcon(Ic.more, color: Colors.white, size: 18), _settings)),
        const Spacer(),
        ValueListenableBuilder<DateTime>(
          valueListenable: _clock,
          builder: (_, d, __) => Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${_two(d.hour)}:${_two(d.minute)}', style: tx(22, c: Colors.white).copyWith(fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Color(0x99000000), blurRadius: 8)])),
          ),
        ),
      ]),
    );
  }

  /// عدّاد السرعة: يُعاد بناؤه فقط عند تغيّر الرقم. اضغطه لتشغيل/إيقاف GPS
  Widget _speedo(double g) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          gps ? _gpsOff() : _gpsOn();
        },
        child: SizedBox(
          width: g,
          height: g * 0.7,
          child: ValueListenableBuilder<int>(
            valueListenable: _kmh,
            builder: (_, k, __) {
              final weak = gps && (_acc > 30 || _now - _fixAt > 5), hot = _sc.over || k > 140;
              final col = !gps ? Colors.white54 : (hot ? const Color(0xFFFF5A64) : Colors.white);
              return CustomPaint(
                painter: _GaugePainter(k.toDouble(), gps, _limit, hot),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: g * 0.15),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('$k', style: tx(g * 0.27, c: col, h: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 10)])),
                      ),
                      Text('كم/س', style: tx(g * 0.075, c: Colors.white70, h: 1.3)),
                      if (!gps) Text('اضغط لتفعيل السرعة', style: tx(g * 0.062, c: kGold, h: 1.4)),
                      if (weak) Text('إشارة GPS ضعيفة', style: tx(g * 0.06, c: const Color(0xFFFFB36B), h: 1.4)),
                      if (gps && !weak && _dist > 100) Text('${(_dist / 1000).toStringAsFixed(1)} كم', style: tx(g * 0.066, c: kGold, h: 1.4)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _disc(Track? t, double s) => SizedBox(
        width: s,
        height: s,
        child: AnimatedBuilder(
          animation: _frame,
          builder: (_, child) => Transform.rotate(angle: _sc.spin, child: child),
          child: RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kGold, width: 1.5)),
              child: Stack(alignment: Alignment.center, children: [
                ClipOval(child: Cover(t?.coverUrl ?? '', size: s - 3, radius: 0)),
                Container(width: s * 0.18, height: s * 0.18, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF04140F), border: Border.all(color: kGold, width: 1))),
              ]),
            ),
          ),
        ),
      );

  Widget _titleRow(Track? t) => Row(children: [
        _disc(t, 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(t?.title ?? 'اختر قصيدة', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(20, c: Colors.white, h: 1.35)),
            Text(t?.reciter ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14, c: kGold, h: 1.3)),
          ]),
        ),
      ]);

  String _fmt(Duration d) => '${d.inMinutes}:${_two(d.inSeconds % 60)}';

  Widget _progress() => StreamBuilder<Duration>(
        stream: app.player.p.positionStream,
        builder: (_, s) {
          final pos = s.data ?? Duration.zero, dur = app.player.p.duration ?? Duration.zero;
          final f = dur.inMilliseconds > 0 ? _cl(pos.inMilliseconds / dur.inMilliseconds) : 0.0;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              Text(_fmt(pos), style: tx(12, c: Colors.white70)),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      if (dur.inMilliseconds > 0) app.player.seek(dur.inMilliseconds / 1000 * _cl(d.localPosition.dx / c.maxWidth));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: f, minHeight: 5, backgroundColor: const Color(0x33FFFFFF), valueColor: const AlwaysStoppedAnimation(kGold))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_fmt(dur), style: tx(12, c: Colors.white70)),
            ]),
          );
        },
      );

  Widget _controls(Track? t, double u) {
    final pc = app.player;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _btn(Ic.prev, pc.prev, s: u),
          StreamBuilder<PlayerState>(stream: pc.p.playerStateStream, builder: (_, s) => _btn((s.data?.playing ?? false) ? Ic.pause : Ic.play, pc.toggle, s: u * 1.3, main: true)),
          _btn(Ic.next, pc.next, s: u),
        ]),
        SizedBox(height: u * 0.16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _btn(Ic.rw, () => pc.seek((pc.p.position.inSeconds - 15).clamp(0, 1 << 30).toDouble()), s: u * 0.64),
          _btn(t != null && app.repo.isFav(t.id) ? Ic.heartF : Ic.heart, () {
            if (t != null) app.repo.toggleFav(t.id);
            setState(() {});
          }, s: u * 0.64, on: t != null && app.repo.isFav(t.id)),
          _btn(Ic.shuf, pc.toggleShuffle, s: u * 0.64, on: pc.shuffle),
          _btn(Ic.fw, () => pc.seek(pc.p.position.inSeconds + 15.0), s: u * 0.64),
        ]),
      ]),
    );
  }

  /// إيماءات المشهد: ضغطة = تشغيل/إيقاف، سحب لليسار = التالية، لليمين = السابقة
  void _gesture(String ic) {
    HapticFeedback.mediumImpact();
    _fx.value = ic;
    _fxT?.cancel();
    _fxT = Timer(const Duration(milliseconds: 650), () => _fx.value = null);
  }

  Widget _scene(_Stage st) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final pl = app.player.p.playing;
          app.player.toggle();
          _gesture(pl ? Ic.pause : Ic.play);
        },
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 250) return;
          if (v < 0) {
            app.player.next();
            _gesture(Ic.next);
          } else {
            app.player.prev();
            _gesture(Ic.prev);
          }
        },
        child: RepaintBoundary(child: CustomPaint(painter: _World(_sc, st, _frame), size: Size.infinite)),
      );

  Widget _overlays(double cy) => IgnorePointer(
        child: Stack(children: [
          Positioned(
            left: 0,
            right: 0,
            top: cy - 50,
            child: Center(
              child: ValueListenableBuilder<String?>(
                valueListenable: _fx,
                builder: (_, ic, __) => AnimatedOpacity(
                  opacity: ic == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x80000000)),
                    child: Center(child: PIcon(ic ?? Ic.play, color: Colors.white, size: 46)),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _bannerW() => ValueListenableBuilder<String?>(
        valueListenable: _banner,
        builder: (_, m, __) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: m == null
              ? const SizedBox.shrink()
              : GestureDetector(
                  onTap: () => _banner.value = null,
                  child: Container(
                    key: ValueKey(m),
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xE60B1F19), borderRadius: BorderRadius.circular(16), border: Border.all(color: kGold)),
                    child: Text(m, textAlign: TextAlign.center, style: tx(15, c: Colors.white, h: 1.5)),
                  ),
                ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = app.player.cur, mq = MediaQuery.of(context), pad = mq.padding, dpr = mq.devicePixelRatio;
    // الخروج بإجراء مقصود فقط: ضغطتا رجوع متتاليتان، أو ضغط مطوّل على ✕
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_backAt != null && now.difference(_backAt!) < const Duration(seconds: 2)) {
          _backAt = null;
          _exit();
        } else {
          _backAt = now;
          _say('اضغط رجوع مرة ثانية للخروج');
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(builder: (_, c) {
            final w = c.maxWidth, h = c.maxHeight, land = w > h * 1.15;
            final top = pad.top + 4;
            if (land) {
              final pw = w * 0.42, sw = w - pw, u = _cl(h * 0.17, 50, 84);
              final g = _cl(math.min(sw * 0.36, h * 0.3), 90, 170);
              final hz = math.max(h * 0.36, top + 44 + g * 0.7 + 4), carY = h - pad.bottom - h * 0.05, cw = math.min(sw * 0.36, (carY - hz) * 0.85);
              return Stack(children: [
                Positioned.fill(child: _scene(_Stage(hz, sw * 0.5, carY, cw, dpr))),
                Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: pw + 40,
                    child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0x00000000), Color(0xB3000000), Color(0xD9000000)], stops: [0, 0.25, 1]))))),
                Positioned(left: 0, width: sw, top: 0, bottom: 0, child: _overlays(carY - cw * 0.4)),
                Positioned(top: top + 44, left: sw * 0.5 - g / 2, child: _speedo(g)),
                Positioned(top: top - 4, left: 0, right: 0, child: _topBar()),
                Positioned(left: 0, width: sw, top: hz + 8, child: _bannerW()),
                Positioned(
                  right: 12 + pad.right,
                  width: pw - 12,
                  top: top + 50,
                  bottom: pad.bottom + 8,
                  child: Column(children: [
                    _titleRow(t),
                    Expanded(child: ly.isEmpty ? const SizedBox() : LyricStrip(lines: ly, base: 20)),
                    _progress(),
                    _controls(t, u),
                  ]),
                ),
              ]);
            }
            final u = _cl(w * 0.19, 58, 88), lyH = ly.isEmpty ? 0.0 : _cl(h * 0.1, 54, 96);
            final panel = 58 + lyH + 30 + u * 1.3 + u * 0.16 + u * 0.64 + 14 + pad.bottom;
            final g = _cl(math.min(w * 0.44, h * 0.2), 100, 200);
            final hz = math.max(h * 0.3, top + 46 + g * 0.7 + 6), carY = h - panel - 4;
            final cw = math.min(w * 0.4, (carY - hz) * 0.85);
            return Stack(children: [
              Positioned.fill(child: _scene(_Stage(hz, w / 2, carY, cw, dpr))),
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: panel + 50,
                  child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC000000), Color(0xF2000000)], stops: [0, 0.2, 1]))))),
              Positioned.fill(child: _overlays(carY - cw * 0.4)),
              Positioned(top: top + 44, left: (w - g) / 2, child: _speedo(g)),
              Positioned(top: top - 4, left: 0, right: 0, child: _topBar()),
              Positioned(left: 0, right: 0, top: hz + 6, child: _bannerW()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panel,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 4, 18, 14 + pad.bottom),
                  child: Column(children: [
                    _titleRow(t),
                    SizedBox(height: lyH, child: ly.isEmpty ? null : LyricStrip(lines: ly, base: 22)),
                    _progress(),
                    _controls(t, u),
                  ]),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

/// عدّاد علوي: قوس بشرطات تضيء مع السرعة، وعلامة ذهبية عند حد التنبيه
class _GaugePainter extends CustomPainter {
  final double kmh;
  final bool on, hot;
  final int limit;
  _GaugePainter(this.kmh, this.on, this.limit, this.hot);
  @override
  void paint(Canvas c, Size s) {
    const neon = Color(0xFF35E3C1);
    final ctr = Offset(s.width / 2, s.width * 0.52), r = s.width * 0.46;
    const a0 = math.pi * 1.06, sw = math.pi * 0.88;
    c.drawCircle(ctr, r * 0.8, Paint()..shader = const RadialGradient(colors: [Color(0x73000000), Color(0x00000000)]).createShader(Rect.fromCircle(center: ctr, radius: r * 0.8)));
    final f = on ? _cl(kmh / 160) : 0.0;
    const n = 32;
    for (int i = 0; i <= n; i++) {
      final a = a0 + sw * i / n, d = Offset(math.cos(a), math.sin(a)), lg = i % 4 == 0, act = on && i / n <= f + 0.001;
      final col = act ? (hot ? const Color(0xFFFF5A64) : Color.lerp(neon, const Color(0xFFFF5A64), _cl((i / n - 0.6) * 2.5))!) : Colors.white.withOpacity(0.4);
      final p0 = ctr + d * (r * (lg ? 0.8 : 0.86)), p1 = ctr + d * (r * 0.94);
      if (act) {
        c.drawLine(p0, p1, Paint()
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = col.withOpacity(0.3));
      }
      c.drawLine(p0, p1, Paint()
        ..strokeWidth = lg ? 2.4 : 1.6
        ..strokeCap = StrokeCap.round
        ..color = col);
    }
    if (limit > 0 && on) {
      final a = a0 + sw * _cl(limit / 160), d = Offset(math.cos(a), math.sin(a));
      c.drawCircle(ctr + d * (r * 1.0), 3.2, Paint()..color = kGold);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.kmh != kmh || o.on != on || o.limit != limit || o.hot != hot;
}

Path _cpath(List<List<double>> cmds, double cw, {double sx = 1, bool close = true}) {
  final pa = Path();
  for (final m in cmds) {
    final op = m[0].round();
    double x(int i) => m[i] * cw * sx;
    double y(int i) => m[i] * cw;
    switch (op) {
      case 0:
        pa.moveTo(x(1), y(2));
      case 1:
        pa.lineTo(x(1), y(2));
      case 2:
        pa.quadraticBezierTo(x(1), y(2), x(3), y(4));
      case 3:
        pa.cubicTo(x(1), y(2), x(3), y(4), x(5), y(6));
    }
  }
  if (close) pa.close();
  return pa;
}

/// العالم: سماء حقيقية، أرض بنسيج رمل، طريق بنسيج أسفلت بمنظور هندسي بالأمتار، نخيل وأعمدة إنارة، طقس، وسيارة
class _World extends CustomPainter {
  /// مستوى الجودة يتكيّف مع قدرة الجهاز: 2 كامل، 1 بلا أنسجة وجزيئات أقل، 0 أخف ما يمكن
  static int q = 2;
  final _Scene s;
  final _Stage g;
  _World(this.s, this.g, Listenable r) : super(repaint: r);
  static TextPainter? _plate, _holyTp;
  static double _plateW = 0;
  static int _holyKm = -1;
  static ui.Image? _carImg;
  static String _carKey = '';
  static const _r64 = Rect.fromLTWH(0, 0, 64, 64);

  // دفعة توهّجات تُرسم بنداء واحد (إضافي) بدل تمويه كل ضوء على حدة
  final _gT = <RSTransform>[], _gC = <Color>[];
  void _glow(Offset o, double r, Color col) {
    if (r < 0.5 || col.alpha < 3) return;
    _gT.add(RSTransform.fromComponents(rotation: 0, scale: r / 32, anchorX: 32, anchorY: 32, translateX: o.dx, translateY: o.dy));
    _gC.add(col);
  }

  void _flush(Canvas c) {
    if (_gT.isEmpty) return;
    c.drawAtlas(_Art.dot, _gT, List.filled(_gT.length, _r64), _gC, BlendMode.modulate, null, Paint()..blendMode = BlendMode.plus);
    _gT.clear();
    _gC.clear();
  }

  @override
  void paint(Canvas c, Size z) {
    _Art.ensure();
    final w = z.width, h = z.height, hz = g.hz, cx = g.cx, hh = h - hz;
    // الإسقاط: عرض السيارة 1.85 م، وحدة العمق 2.5 م
    final fc = _cl((g.carY - hz) / hh, 0.05, 0.95), s0 = g.cw / (1.85 * fc), qc = 1 / fc - 1;
    final el = s.sunEl, day = _sm(-7, 7, el), golden = el > -6 ? _cl(1 - (el - 2).abs() / 10) : 0.0;
    final over = _cl(s.cloud * 0.75 + s.rain * 0.25);
    final light0 = _cl((0.06 + 0.94 * day) * (1 - 0.35 * over));
    final light = _cl(light0 + s.flash * 0.6);
    final lightsOn = 1 - _sm(-3, 5, el);
    final murk = math.max(s.fog, s.dust);
    double f(double q) => 1 / (1 + q);
    double off(double q) {
      final d = q - qc;
      return s.curv * 3.125 * d * d / (1 + d.abs() / 30);
    }

    double X(double xm, double q) => cx + (xm + off(q)) * s0 * f(q);
    double Y(double q, [double ym = 0]) => hz + (hh - ym * s0) * f(q);
    double sxOf(double az) => cx + (((az - s.heading + 540) % 360) - 180) / 55 * (w / 2);

    // ---------- السماء: ثلاث درجات + طقس ----------
    var top = _mix(const Color(0xFF01040B), const Color(0xFF2A64B8), day), hor = _mix(const Color(0xFF0D1B2F), const Color(0xFFB7D8F0), day);
    top = _mix(top, const Color(0xFF2E3A66), golden * 0.55);
    hor = _mix(hor, const Color(0xFFF28A50), golden * 0.85);
    top = _mix(top, _mix(const Color(0xFF0D1115), const Color(0xFF6F7B87), day), over);
    hor = _mix(hor, _mix(const Color(0xFF171C21), const Color(0xFFA7AFB7), day), over);
    final dustC = _mix(const Color(0xFF2A2014), const Color(0xFFC99A5A), day);
    top = _mix(top, dustC, s.dust * 0.85);
    hor = _mix(hor, _mix(dustC, const Color(0xFFE0B676), day), s.dust);
    final mid = _mix(_mix(top, hor, 0.55), const Color(0xFFE8A070), golden * 0.25);
    final sky = Rect.fromLTRB(0, 0, w, hz + 2);
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(top, Colors.white, s.flash * 0.5), _mix(mid, Colors.white, s.flash * 0.45), _mix(hor, Colors.white, s.flash * 0.4)], stops: const [0, 0.6, 1]).createShader(sky));
    // النجوم تتلألأ (ثلاث دفعات نقاط)
    final st = (1 - day) * (1 - over) * (1 - s.dust);
    if (st > 0.02) {
      final b = [<Offset>[], <Offset>[], <Offset>[]];
      for (int i = 0; i < 120; i++) {
        final y = _hash(i + 500) * hz * 0.92;
        b[((_hash(i) * 7 + s.t * (0.2 + _hash(i + 9) * 0.5)) % 3).floor()].add(Offset(_hash(i) * w, y));
      }
      for (int k = 0; k < 3; k++) {
        c.drawPoints(ui.PointMode.points, b[k], Paint()
          ..strokeWidth = 1.2 + k * 0.7
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(_cl(st * (0.35 + k * 0.3))));
      }
    }
    double skyY(double e) => hz - _cl(e / 42, -0.1, 1.1) * hz * 0.95;
    // الشمس بتوهّج حقيقي
    if (el > -3) {
      final x = sxOf(s.sunAz), y = skyY(el), rs = w * 0.035, vis = _cl(1 - over * 0.85 - s.dust * 0.55);
      if (x > -w * 0.4 && x < w * 1.4) {
        final sc = _mix(const Color(0xFFFF8A40), const Color(0xFFFFF6DE), _sm(0, 22, el));
        _glow(Offset(x, y), rs * 9, sc.withOpacity(0.35 * vis + 0.08));
        _glow(Offset(x, y), rs * 3, sc.withOpacity(0.6 * vis + 0.1));
        _flush(c);
        c.drawCircle(Offset(x, y), rs, Paint()..color = _mix(sc, Colors.white, 0.3).withOpacity(_cl(vis + 0.2)));
      }
    }
    // القمر بطوره الحقيقي
    if (s.moonEl > -2 && day < 0.85) {
      final x = sxOf(s.moonAz), y = skyY(s.moonEl), rm = w * 0.026, vis = _cl((1 - day) * (1 - over * 0.8));
      if (x > -rm && x < w + rm && vis > 0.03) {
        _glow(Offset(x, y), rm * 6, const Color(0xFFF3EEDB).withOpacity(0.22 * vis));
        _flush(c);
        final disk = Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: rm));
        final ph = s.moonPh, k = ph < 0.5 ? -ph * 4 * rm : (1 - ph) * 4 * rm;
        final shd = Path()..addOval(Rect.fromCircle(center: Offset(x + k, y), radius: rm * 1.02));
        c.drawPath(disk, Paint()..color = const Color(0xFF2A2F38).withOpacity(0.55 * vis));
        c.drawPath(Path.combine(PathOperation.difference, disk, shd), Paint()..color = const Color(0xFFF3EEDB).withOpacity(vis));
        c.drawCircle(Offset(x - rm * 0.3, y - rm * 0.2), rm * 0.22, Paint()..color = const Color(0xFFCFC8B0).withOpacity(0.35 * vis));
      }
    }
    // الغيوم: صور ركامية ملوّنة حسب الضوء، تنساب مع الريح
    final cTint = _mix(_mix(_mix(Colors.white, const Color(0xFFFFC090), golden * 0.7), const Color(0xFF9AA3AD), over * 0.8), const Color(0xFF1B2128), 1 - light0);
    final cp = Paint()
      ..filterQuality = FilterQuality.low
      ..colorFilter = ColorFilter.mode(_mix(cTint, Colors.white, s.flash), BlendMode.modulate);
    final nCl = (2 + s.cloud * 10).round();
    for (int i = 0; i < nCl; i++) {
      final cw0 = w * (0.35 + _hash(i + 40) * 0.45) * (1 - _hash(i + 30) * 0.4);
      final x = ((_hash(i + 20) * (w + cw0) + s.t * (2 + s.wind * 1.5) * (0.4 + _hash(i))) % (w + cw0 * 2)) - cw0, y = _hash(i + 30) * hz * 0.6 - cw0 * 0.12;
      cp.color = Colors.white.withOpacity(0.55 + 0.4 * s.cloud);
      c.drawImageRect(_Art.clouds[i % 3], const Rect.fromLTWH(0, 0, 512, 220), Rect.fromLTWH(x, y, cw0, cw0 * 0.43), cp);
    }
    if (over > 0.55) {
      c.drawRect(Rect.fromLTRB(0, 0, w, hz * 0.7), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top.withOpacity(0.8 * (over - 0.55) / 0.45), top.withOpacity(0)]).createShader(Rect.fromLTRB(0, 0, w, hz * 0.7)));
    }

    // ---------- الأرض البعيدة: طبقتا جبال بمنظور جوي + أضواء مدن + الحرم ----------
    var land = _mix(const Color(0xFF0E0C09), const Color(0xFFC9A46C), light);
    land = _mix(land, _mix(const Color(0xFF16130E), const Color(0xFFA9845A), light), s.rain * 0.6);
    land = _mix(land, _mix(const Color(0xFF2A2D33), const Color(0xFFE9EDF0), light), s.snow);
    final hp = s.heading * math.pi / 180 * 3;
    for (int layer = 0; layer < 2; layer++) {
      final hills = Path()..moveTo(0, hz);
      final amp = layer == 0 ? 0.07 : 0.035, fr = layer == 0 ? 3.0 : 7.0;
      for (int i = 0; i <= 64; i++) {
        final x = w * i / 64;
        hills.lineTo(x, hz - hh * (amp * (0.55 + 0.45 * math.sin(x / w * fr + 1 + hp * (layer + 1)) + 0.12 * math.sin(x / w * 23 + hp * 2))));
      }
      hills
        ..lineTo(w, hz)
        ..close();
      final hc0 = _mix(land, hor, layer == 0 ? 0.72 : 0.5);
      c.drawPath(hills, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(hc0, Colors.white, 0.06 * light), _mix(hc0, Colors.black, 0.08)]).createShader(Rect.fromLTRB(0, hz - hh * 0.1, w, hz)));
    }
    if (lightsOn > 0.1) {
      for (int i = 0; i < 80; i++) {
        final x = (_hash(i + 900) * w * 4 - s.heading / 360 * w * 4) % (w * 4);
        if (x > w) continue;
        final y = hz - hh * (0.003 + _hash(i + 901) * 0.012);
        _glow(Offset(x, y), 1.5 + _hash(i + 902) * 2.5, _mix(const Color(0xFFFFC27A), Colors.white, _hash(i + 903)).withOpacity(lightsOn * (0.4 + 0.5 * _hash(i + 904)) * (1 - murk)));
      }
      _flush(c);
    }
    if (s.holyD > 2) _shrine(c, sxOf(s.holyB), hz, hh, w, light, lightsOn, hor, murk);

    // ---------- الأرض: رمل بنسيج ----------
    final gr = Rect.fromLTRB(0, hz, w, h);
    c.drawRect(gr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(land, hor, 0.5), land, _mix(land, Colors.black, 0.25)], stops: const [0, 0.35, 1]).createShader(gr));
    const half = 5.4, shoulder = 1.6, qMin = -0.9, qMax = 70.0;
    void strip(double x0, double x1, double q0, double q1, Paint p, [int n = 36]) {
      final pa = Path(), f0 = f(q0), f1 = f(q1);
      final qs = List<double>.generate(n + 1, (i) => 1 / (f0 * math.pow(f1 / f0, i / n)) - 1);
      for (int i = 0; i <= n; i++) {
        i == 0 ? pa.moveTo(X(x0, qs[i]), Y(qs[i])) : pa.lineTo(X(x0, qs[i]), Y(qs[i]));
      }
      for (int i = n; i >= 0; i--) {
        pa.lineTo(X(x1, qs[i]), Y(qs[i]));
      }
      pa.close();
      c.drawPath(pa, p);
    }

    // نسيج بمنظور: شرائح عرضية، كل شريحة بمصفوفة تقريبية لعمقها (يتحرك مع المسافة الحقيقية)
    void tex(ui.Image img, double kTex, double alpha, {double? xl, double? xr}) {
      final nb = q >= 2 ? 16 : 10;
      final travel = (s.q * 2.5) % (256 / kTex), f0 = f(qMin), f1 = f(36.0);
      final p = Paint()..color = Colors.white.withOpacity(_cl(alpha));
      for (int i = 0; i < nb; i++) {
        final qa = 1 / (f0 * math.pow(f1 / f0, i / nb)) - 1, qb = 1 / (f0 * math.pow(f1 / f0, (i + 1) / nb)) - 1;
        final qm = (qa + qb) / 2, fm = f(qm), dz = -hh * fm * fm / 2.5;
        final a = s0 * fm / kTex, e = dz / kTex, tx = cx + off(qm) * s0 * fm, ty = Y(qm) + (-travel - qm * 2.5) * dz;
        p.shader = ImageShader(img, TileMode.repeated, TileMode.repeated, Float64List.fromList([a, 0, 0, 0, 0, e, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1]), filterQuality: FilterQuality.low);
        if (xl == null) {
          c.drawRect(Rect.fromLTRB(0, Y(qb), w, Y(qa) + 0.6), p);
        } else {
          strip(xl, xr!, qa, qb, p, 3);
        }
      }
    }

    if (q >= 2) tex(_Art.sand, 40, 0.3 + 0.45 * light * (1 - s.snow));

    // ---------- الطريق: 3 مسارات × 3.6 م، كتف 1.6 م ----------
    final wet = _cl(s.rain * 1.4 + s.snow * 0.5);
    var asph = _mix(const Color(0xFF0D0F11), const Color(0xFF4C4F53), light);
    asph = _mix(asph, _mix(const Color(0xFF06080A), const Color(0xFF2A2D31), light), wet);
    strip(-half - shoulder, half + shoulder, qMin, qMax, Paint()..color = _mix(asph, land, 0.3), 48);
    strip(-half, half, qMin, qMax, Paint()..color = asph, 48);
    if (q >= 1) tex(_Art.asphalt, 70, (0.75 - 0.35 * wet) * (0.4 + 0.6 * light), xl: -half - shoulder, xr: half + shoulder);
    // آثار العجلات: داكنة جافة، لامعة مبللة
    for (final lcn in const [-3.6, 0.0, 3.6]) {
      for (final o in const [-0.8, 0.8]) {
        strip(lcn + o - 0.3, lcn + o + 0.3, qMin, 40, Paint()..color = wet > 0.3 ? hor.withOpacity(0.08 * wet) : Colors.black.withOpacity(0.05 + 0.07 * light), 40);
      }
    }
    // رقع وشقوق
    for (int k = -1; k < 12; k++) {
      final idx = (s.q / 4).floor() + k, q = idx * 4 - s.q + _hash(idx + 11) * 2;
      if (q + 1 < qMin || q > 36) continue;
      final hsh = _hash(idx * 3 + 1);
      if (hsh < 0.3) {
        final x0 = -half + 0.3 + _hash(idx) * (2 * half - 3), q0 = math.max(q, qMin);
        strip(x0, x0 + 0.8 + _hash(idx + 4) * 1.6, q0, q0 + 0.3 + _hash(idx + 9) * 0.6, Paint()..color = Colors.black.withOpacity(0.07 + 0.06 * light), 6);
      } else if (hsh > 0.82 && q > qMin) {
        strip(-half, half, q, q + 0.025, Paint()..color = Colors.black.withOpacity(0.25), 2);
      }
    }
    if (wet > 0.05) strip(-half, half, 2, qMax, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [hor.withOpacity(0.3 * wet), hor.withOpacity(0.04 * wet)]).createShader(Rect.fromLTRB(0, hz, w, g.carY)), 30);
    if (s.snow > 0.3) {
      for (final sd in const [-1.0, 1.0]) {
        strip(sd * half, sd * (half + shoulder), qMin, qMax, Paint()..color = Colors.white.withOpacity(0.75 * s.snow * (0.4 + 0.6 * light)), 40);
      }
    }
    final lineC = _mix(const Color(0xFF3A3C3E), const Color(0xFFF0F0EC), _cl(light + 0.25));
    for (final xm in const [-half + 0.2, half - 0.2]) {
      strip(xm - 0.08, xm + 0.08, qMin, qMax, Paint()..color = lineC.withOpacity(0.92), 48);
    }
    // الخطوط المتقطعة: 3 م خط / 9 م فراغ
    const per = 4.8, dash = 1.2;
    final base = s.q % per;
    for (final xm in const [-1.8, 1.8]) {
      for (int k = 0; k < 40; k++) {
        final q0 = k * per - base - 0.6;
        if (q0 + dash < qMin) continue;
        if (q0 > qMax || f(math.max(q0, qMin)) * s0 * 0.16 < 0.5) break;
        strip(xm - 0.075, xm + 0.075, math.max(q0, qMin), q0 + dash, Paint()..color = lineC.withOpacity(0.88), 6);
      }
    }
    // برك ماء تعكس السماء وحلقات قطرات المطر
    if (s.rain > 0.12) {
      for (int k = -1; k < 10; k++) {
        final idx = (s.q / 6).floor() + k, q = idx * 6 - s.q + _hash(idx + 21) * 3;
        if (q < qMin + 0.2 || q > 34 || _hash(idx + 22) > 0.25 + s.rain * 0.5) continue;
        final xm = -half + 0.6 + _hash(idx + 23) * (2 * half - 1.2), wm = 0.9 + _hash(idx + 24) * 1.8, dm = 0.25 + _hash(idx + 25) * 0.5;
        final rc = Rect.fromLTRB(X(xm - wm / 2, q), Y(q + dm), X(xm + wm / 2, q), Y(math.max(q - dm, qMin)));
        c.drawOval(rc, Paint()..shader = RadialGradient(colors: [_mix(hor, top, 0.4).withOpacity(0.6 * s.rain), hor.withOpacity(0.35 * s.rain), hor.withOpacity(0)], stops: const [0, 0.7, 1]).createShader(rc));
        for (int j = 0; j < 3; j++) {
          final life = (s.t * 1.6 + _hash(idx * 5 + j)) % 1, cxr = rc.left + rc.width * (0.2 + 0.6 * _hash(idx * 7 + j)), cyr = rc.top + rc.height * (0.3 + 0.4 * _hash(idx * 9 + j));
          c.drawOval(Rect.fromCenter(center: Offset(cxr, cyr), width: rc.width * 0.25 * life, height: rc.height * 0.25 * life), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withOpacity(0.35 * (1 - life) * s.rain));
        }
      }
      final rp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (int i = 0; i < (70 * s.rain).round(); i++) {
        final ph0 = s.t * 2.5 + _hash(i + 300), life = ph0 % 1, gen = ph0.floor();
        final xm = -half + _hash(i * 13 + gen) * 2 * half, q = qc - 0.6 + _hash(i * 17 + gen) * 7;
        final sc = s0 * f(q) * 0.22 * life;
        rp.color = _mix(const Color(0xFF9AA4AE), Colors.white, light).withOpacity(0.5 * (1 - life) * s.rain);
        c.drawOval(Rect.fromCenter(center: Offset(X(xm, q), Y(q)), width: sc, height: sc * 0.32), rp);
      }
    }
    // عاكسات أرضية تلمع بالليل
    if (lightsOn > 0.3) {
      for (int k = 0; k < 16; k++) {
        final q = k * per * 0.5 - (s.q % (per * 0.5));
        if (q < qc + 0.3) continue;
        for (final xm in const [-half + 0.2, half - 0.2]) {
          _glow(Offset(X(xm, q), Y(q)), math.max(1.5, 0.25 * s0 * f(q)), const Color(0xFFFFC46B).withOpacity(lightsOn * _cl(f(q) * 6)));
        }
      }
      _flush(c);
    }

    // ---------- النخيل وأعمدة الإنارة (من البعيد للقريب) ----------
    final objs = <(double, int, int)>[];
    const pp = 6.0, lp = 14.0;
    final ip = (s.q / pp).floor(), il = (s.q / lp).floor();
    for (int k = -1; k < 14; k++) {
      final q = (ip + k) * pp - s.q;
      if (q > qMin && q < qMax) objs.add((q, 0, ip + k));
    }
    for (int k = -1; k < 6; k++) {
      final q = (il + k) * lp - s.q + 3;
      if (q > qMin && q < qMax) objs.add((q, 1, il + k));
    }
    objs.sort((a, b) => b.$1.compareTo(a.$1));
    final wetRefl = <Offset>[];
    const lampC = Color(0xFFFFB45A);
    final palmTint = _mix(_mix(const Color(0xFF151A1F), Colors.white, light), const Color(0xFFE6C690), s.dust * 0.6);
    final palmP = Paint()
      ..filterQuality = FilterQuality.low
      ..colorFilter = ColorFilter.mode(palmTint, BlendMode.modulate);
    final air = _cl(math.max(murk, s.rain * 0.7) * 1.3);
    for (final o in objs) {
      final q = o.$1, sc = s0 * f(q);
      if (o.$2 == 0) {
        final side = o.$3.isEven ? 1.0 : -1.0, xm = side * (half + shoulder + 4 + _hash(o.$3) * 7), ht = 8 + _hash(o.$3 + 3) * 4;
        final k = ht * sc / 250, bx = X(xm, q), by = Y(q);
        if (k * 256 < 2 || (_World.q == 0 && q > 25)) continue;
        final sway = math.sin(s.t * 1.2 + o.$3) * (0.02 + s.wind * 0.006);
        c.save();
        c.translate(bx, by);
        if (_hash(o.$3 + 8) > 0.5) c.scale(-1, 1);
        c.skew(sway, 0);
        c.drawImageRect(_Art.palms[o.$3.abs() % 3], const Rect.fromLTWH(0, 0, 256, 320), Rect.fromLTWH(-128 * k, -318 * k, 256 * k, 320 * k), palmP);
        c.restore();
      } else {
        for (final side in const [-1.0, 1.0]) {
          final xm = side * (half + shoulder + 0.9), bx = X(xm, q), by = Y(q), ty0 = Y(q, 10), ax = X(xm - side * 2.4, q), ay = Y(q, 9.7);
          final poleC = _mix(const Color(0xFF16181A), const Color(0xFF9097A0), light);
          c.drawLine(Offset(bx, by), Offset(bx, ty0), Paint()
            ..strokeWidth = math.max(1.0, 0.22 * sc)
            ..color = poleC);
          final arm = Path()
            ..moveTo(bx, ty0)
            ..quadraticBezierTo(bx, Y(q, 10.6), ax, ay);
          c.drawPath(arm, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, 0.14 * sc)
            ..color = poleC);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(ax, ay + 0.1 * sc), width: 0.9 * sc, height: 0.25 * sc), Radius.circular(0.1 * sc)), Paint()..color = _mix(poleC, Colors.black, 0.3));
          if (lightsOn > 0.05) {
            _glow(Offset(ax, ay + 0.25 * sc), math.max(3.0, 2.2 * sc), lampC.withOpacity(0.55 * lightsOn));
            _glow(Offset(ax, ay + 0.25 * sc), math.max(1.5, 0.5 * sc), const Color(0xFFFFEBC4).withOpacity(lightsOn));
            final px = X(xm - side * 2.4, q), y0 = Y(math.max(q - 1.6, -0.85)), y1 = Y(q + 1.6);
            final pr = Rect.fromCenter(center: Offset(px, by), width: 9 * sc, height: (y0 - y1).abs() + 2);
            c.drawOval(pr, Paint()..shader = RadialGradient(colors: [lampC.withOpacity(0.28 * lightsOn), lampC.withOpacity(0)]).createShader(pr));
            if (wet > 0.1 && q > qc) wetRefl.add(Offset(px, by));
            if (air > 0.08) {
              final cone = Path()
                ..moveTo(ax - 0.3 * sc, ay)
                ..lineTo(ax + 0.3 * sc, ay)
                ..lineTo(ax + 3 * sc, by)
                ..lineTo(ax - 3 * sc, by)
                ..close();
              c.drawPath(cone, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lampC.withOpacity(0.24 * air * lightsOn), lampC.withOpacity(0.03 * air * lightsOn)]).createShader(Rect.fromLTRB(0, ay, w, by)));
            }
          }
        }
      }
    }
    _flush(c);

    // ---------- الحواجز ----------
    void ribbon(double xm, double y0, double y1, double q0, double q1, Paint p, [int n = 40]) {
      final pa = Path(), f0 = f(q0), f1 = f(q1), qs = List<double>.generate(n + 1, (i) => 1 / (f0 * math.pow(f1 / f0, i / n)) - 1);
      for (int i = 0; i <= n; i++) {
        i == 0 ? pa.moveTo(X(xm, qs[i]), Y(qs[i], y1)) : pa.lineTo(X(xm, qs[i]), Y(qs[i], y1));
      }
      for (int i = n; i >= 0; i--) {
        pa.lineTo(X(xm, qs[i]), Y(qs[i], y0));
      }
      pa.close();
      c.drawPath(pa, p);
    }

    const gx = half + shoulder + 0.3, bxm = -(half + shoulder + 0.25);
    final steel = _mix(const Color(0xFF16181A), const Color(0xFFB3B9BF), light), conc = _mix(const Color(0xFF1C1C1A), const Color(0xFFB7B2A6), light);
    final postP = Paint()..color = _mix(steel, Colors.black, 0.35);
    for (int k = 0; k < 60; k++) {
      final q = k * 0.8 - (s.q % 0.8);
      if (q < qMin) continue;
      if (q > qMax || (Y(q) - Y(q + 0.8)) < 2.5) break;
      postP.strokeWidth = math.max(1.0, 0.1 * s0 * f(q));
      c.drawLine(Offset(X(gx, q), Y(q)), Offset(X(gx, q), Y(q, 0.75)), postP);
    }
    ribbon(gx, 0.5, 0.78, qMin, qMax, Paint()..color = steel);
    ribbon(gx, 0.62, 0.66, qMin, qMax, Paint()..color = _mix(steel, Colors.black, 0.25));
    ribbon(gx, 0.74, 0.78, qMin, qMax, Paint()..color = _mix(steel, Colors.white, 0.35 * light));
    ribbon(bxm, 0, 0.82, qMin, qMax, Paint()..color = conc);
    ribbon(bxm, 0, 0.18, qMin, qMax, Paint()..color = _mix(conc, Colors.black, 0.2));
    ribbon(bxm, 0.78, 0.82, qMin, qMax, Paint()..color = _mix(conc, Colors.white, 0.25 * light));
    if (s.snow > 0.3) {
      ribbon(bxm, 0.8, 0.9, qMin, qMax, Paint()..color = Colors.white.withOpacity(0.85 * s.snow));
      ribbon(gx, 0.78, 0.84, qMin, qMax, Paint()..color = Colors.white.withOpacity(0.8 * s.snow));
    }
    for (int k = 0; k < 24; k++) {
      final q = k * 1.6 - (s.q % 1.6);
      if (q < qc + 0.2) continue;
      if (q > qMax || f(q) * s0 * 0.12 < 0.6) break;
      final gl = _cl(0.25 + lightsOn * 0.9) * _cl(f(q) * 8), r0 = math.max(1.0, 0.12 * s0 * f(q));
      _glow(Offset(X(gx, q), Y(q, 0.64)), r0, Colors.white.withOpacity(gl));
      _glow(Offset(X(bxm, q), Y(q, 0.6)), r0, const Color(0xFFFFC21A).withOpacity(gl));
    }
    _flush(c);

    // ---------- ضباب الأفق (يُخفي تلاقي الخطوط البعيدة) ----------
    final hc = _mix(hor, land, 0.25);
    final hb = Rect.fromLTRB(0, hz - hh * 0.07, w, hz + hh * 0.12);
    c.drawRect(hb, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [hc.withOpacity(0), hc.withOpacity(0.95), hc.withOpacity(0)], stops: const [0, 0.38, 1]).createShader(hb));
    if (murk > 0.02) {
      final mc = s.dust > s.fog ? _mix(const Color(0xFF261C10), const Color(0xFFD7A764), light) : _mix(const Color(0xFF15181B), const Color(0xFFC9CDD1), light);
      c.drawRect(Offset.zero & z, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mc.withOpacity(0.35 * murk), mc.withOpacity(0.92 * murk), mc.withOpacity(0.25 * murk)], stops: [0, hz / h, 1]).createShader(Offset.zero & z));
    }
    if (s.rain > 0.2) {
      // ستائر مطر بعيدة تمشي مع الريح
      for (int i = 0; i < 3; i++) {
        final x = ((_hash(i + 600) * w + s.t * (10 + s.wind * 4)) % (w * 1.6)) - w * 0.3, ww = w * (0.3 + _hash(i + 601) * 0.3);
        final rr = Rect.fromLTWH(x, hz - hh * 0.25, ww, hh * 0.5);
        c.drawRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [hor.withOpacity(0), _mix(hor, Colors.grey, 0.4).withOpacity(0.25 * s.rain), hor.withOpacity(0)]).createShader(rr));
      }
    }
    for (final o in wetRefl) {
      final rr = Rect.fromLTRB(o.dx - 4, o.dy, o.dx + 4, math.min(h, o.dy + (h - o.dy) * 0.4));
      c.drawRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lampC.withOpacity(0.38 * wet * lightsOn), lampC.withOpacity(0)]).createShader(rr));
    }

    // ---------- ضوء السيارة الأمامي ----------
    final beamOn = math.max(lightsOn, murk * 0.8);
    if (beamOn > 0.05) {
      final qa = qc + 0.2, qb = qc + 30, ya = Y(qa), yb = Y(qb);
      const bc = Color(0xFFFFF1D6);
      for (final wv in const [(7.5, 0.12), (4.5, 0.2)]) {
        final bm = Path()
          ..moveTo(X(-0.9, qa), ya)
          ..lineTo(X(0.9, qa), ya)
          ..lineTo(X(wv.$1, qb), yb)
          ..lineTo(X(-wv.$1, qb), yb)
          ..close();
        c.drawPath(bm, Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [bc.withOpacity(wv.$2 * beamOn), bc.withOpacity(wv.$2 * 0.8 * beamOn), bc.withOpacity(0)], stops: const [0, 0.3, 1]).createShader(Rect.fromLTRB(0, yb, w, ya)));
      }
    }

    // ---------- السيارة ----------
    final m = _carModels[s.model] ?? _carModels['sport']!;
    final cw = g.cw;
    final bob = (math.sin(s.t * 11) * 0.5 + math.sin(s.t * 23 + 1) * 0.3) * _cl(s.v / 20) * cw * 0.004;
    final ox = cx + off(qc) * s0 * fc + s.lean * cw * 0.06, oy = g.carY + bob + s.pitch * cw * 0.004;
    final img = _carImage(cw, light0);
    final W = cw * 1.3, Hc = cw * 1.0;
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), dst = Rect.fromLTWH(-W / 2, -cw * 0.9, W, Hc);
    final lit = _cl(s.tail * 0.6 + s.brake * 0.9), red = Color.lerp(const Color(0xFF3A060C), const Color(0xFFFF2236), lit)!;
    // ظل الشمس باتجاهها الحقيقي (تدرّج بدل تمويه)
    final rel = ((s.sunAz - s.heading + 540) % 360 - 180) * math.pi / 180;
    final shL = _cl(1 / math.tan(math.max(el, 4) * math.pi / 180), 0, 3) * 0.22, shA = day * (1 - over) * (1 - s.dust * 0.7);
    if (shA > 0.05) {
      final sr = Rect.fromCenter(center: Offset(ox - math.sin(rel) * shL * 0.8 * cw, oy + (0.01 + math.cos(rel) * shL * 0.3) * cw), width: cw * (1.05 + (math.sin(rel) * shL).abs() * 0.9), height: cw * (0.08 + (math.cos(rel) * shL * 0.3).abs() * 0.5));
      c.drawOval(sr, Paint()..shader = RadialGradient(colors: [Colors.black.withOpacity(0.5 * shA), Colors.black.withOpacity(0.35 * shA), Colors.black.withOpacity(0)], stops: const [0, 0.6, 1]).createShader(sr));
    }
    // انعكاس السيارة وأضوائها على الأسفلت المبلل
    if (wet > 0.2) {
      c.save();
      c.translate(ox, oy);
      c.scale(1, -0.7);
      c.drawImageRect(img, src, dst, Paint()
        ..color = Colors.white.withOpacity(0.22 * wet)
        ..filterQuality = FilterQuality.low);
      c.restore();
    }
    final rl = 0.25 + 0.5 * wet;
    for (final sd in const [-1.0, 1.0]) {
      final rc = Rect.fromLTRB(ox + sd * cw * 0.36 - cw * 0.06, oy, ox + sd * cw * 0.36 + cw * 0.06, oy + cw * (0.2 + wet * 0.9));
      c.drawRect(rc, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [red.withOpacity(rl * lit), red.withOpacity(0)]).createShader(rc));
    }
    c.save();
    c.translate(ox, oy);
    c.rotate(s.lean * 0.035);
    c.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
    final lq = ((s.q - 3) / lp).round() * lp - s.q + 3 - qc;
    _carLive(c, m, cw, light, lightsOn, wet, lq, red, lit);
    c.restore();

    // ---------- رذاذ الإطارات بالمطر ----------
    if (s.splash > 0.05) {
      final sc0 = _mix(const Color(0xFF2A2E33), const Color(0xFFDDE3E8), light);
      final tr = <RSTransform>[], cl = <Color>[];
      for (int i = 0; i < 30; i++) {
        final side = i.isEven ? 1.0 : -1.0, life = (s.t * 2.2 + _hash(i)) % 1;
        final x = ox + side * cw * (0.4 + life * 0.3 * _hash(i + 5)), y = oy - cw * 0.03 + life * cw * 0.35, rr = cw * (0.05 + life * 0.1);
        tr.add(RSTransform.fromComponents(rotation: 0, scale: rr / 32, anchorX: 32, anchorY: 32, translateX: x, translateY: y));
        cl.add(sc0.withOpacity(0.28 * s.splash * (1 - life)));
      }
      c.drawAtlas(_Art.dot, tr, List.filled(tr.length, _r64), cl, BlendMode.modulate, null, Paint());
    }

    // ---------- المطر: ثلاث طبقات عمق بخيوط ناعمة (نداء رسم واحد) ----------
    if (s.rain > 0.02) {
      final n = ((80 + 380 * s.rain) * (_World.q == 2 ? 1 : 0.5)).round(), rc0 = _mix(const Color(0xFF8C96A0), const Color(0xFFE6ECF2), light);
      final tr = <RSTransform>[], cl = <Color>[];
      final slant = s.wind * 0.035;
      for (int i = 0; i < n; i++) {
        final d = _hash(i + 3), len = (16 + 70 * d * d) * (1 + s.v / 28);
        final x0 = _hash(i) * (w + 80) - 40, sp = (0.7 + 0.9 * d) * h * 1.5;
        final y = ((_hash(i + 1) * h + s.t * sp) % (h + len)) - len * 0.5;
        final ang = -(slant + (x0 - cx) / w * s.v * 0.035) * (0.6 + 0.4 * d);
        tr.add(RSTransform.fromComponents(rotation: ang, scale: len / 96, anchorX: 4, anchorY: 48, translateX: x0, translateY: y));
        cl.add(rc0.withOpacity(_cl((0.18 + 0.32 * d) * (0.6 + 0.4 * s.rain))));
      }
      c.drawAtlas(_Art.streak, tr, List.filled(tr.length, const Rect.fromLTWH(0, 0, 8, 96)), cl, BlendMode.modulate, null, Paint()..filterQuality = FilterQuality.low);
      c.drawRect(Offset.zero & z, Paint()..color = _mix(const Color(0xFF0A0E12), const Color(0xFF8E99A4), light).withOpacity(0.08 * s.rain));
    }
    // ---------- الثلج: رقائق بعمق، تتمايل وتسقط ببطء ----------
    if (s.snow > 0.02) {
      final n = ((60 + 260 * s.snow) * (_World.q == 2 ? 1 : 0.5)).round();
      final tr = <RSTransform>[], cl = <Color>[];
      for (int i = 0; i < n; i++) {
        final d = _hash(i + 2), sz = 2 + 9 * d * d;
        final y = (_hash(i + 1) * h + s.t * (25 + 70 * d) * (1 + s.v / 20)) % (h + 20) - 10;
        final x = (_hash(i) * w + math.sin(s.t * (0.6 + d) + i) * (6 + 14 * d) + (_hash(i) * w - cx) * (y / h) * s.v * 0.012) % w;
        tr.add(RSTransform.fromComponents(rotation: 0, scale: sz / 16, anchorX: 16, anchorY: 16, translateX: x, translateY: y));
        cl.add(Colors.white.withOpacity(0.55 + 0.4 * d));
      }
      c.drawAtlas(_Art.flake, tr, List.filled(tr.length, const Rect.fromLTWH(0, 0, 32, 32)), cl, BlendMode.modulate, null, Paint());
    }
    // رمال تتطاير مع الريح بالغبار
    if (s.dust > 0.2) {
      final dc = _mix(const Color(0xFF3A2A16), const Color(0xFFE2BC80), light);
      for (int i = 0; i < 40; i++) {
        final y = hz + (h - hz) * (0.2 + _hash(i + 700) * 0.8), len = 30 + 90 * _hash(i + 701);
        final x = (_hash(i + 702) * (w + 300) + s.t * (80 + s.wind * 25) * (0.6 + _hash(i + 703))) % (w + 300) - 150;
        c.drawLine(Offset(x, y), Offset(x + len, y - len * 0.04), Paint()
          ..strokeWidth = 1 + _hash(i + 704) * 2
          ..strokeCap = StrokeCap.round
          ..color = dc.withOpacity(0.16 * s.dust));
      }
    }
    // البرق: خط متعرج متفرع
    if (s.flash > 0.45) {
      final bp = Path();
      var x = w * (0.15 + 0.7 * _hash(s.bolt * 7)), y = 0.0;
      bp.moveTo(x, y);
      final pts = <Offset>[];
      for (int k = 0; k < 12; k++) {
        x += (_hash(s.bolt * 31 + k) - 0.5) * w * 0.09;
        y += hz * 0.085;
        bp.lineTo(x, y);
        pts.add(Offset(x, y));
      }
      bp.moveTo(pts[4].dx, pts[4].dy);
      bp.lineTo(pts[4].dx + w * 0.06, pts[4].dy + hz * 0.12);
      bp.lineTo(pts[4].dx + w * 0.1, pts[4].dy + hz * 0.2);
      final a = _cl((s.flash - 0.45) / 0.55);
      c.drawPath(bp, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0xFFBFD4FF).withOpacity(0.3 * a));
      c.drawPath(bp, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withOpacity(a));
    }
    if (s.flash > 0.01) c.drawRect(Offset.zero & z, Paint()..color = Colors.white.withOpacity(0.3 * s.flash));
  }

  /// حرم الإمام الحسين (ع) بالأفق باتجاهه الحقيقي من موقعك
  void _shrine(Canvas c, double hx, double hz, double hh, double w, double light, double lightsOn, Color hor, double murk) {
    final sz = w * _cl(0.035 + 2.5 / (s.holyD + 15), 0.035, 0.13);
    if (hx < -sz || hx > w + sz) return;
    final haze = _cl(s.holyD / 140 + murk * 0.7, 0, 0.75), by0 = hz - hh * 0.02;
    final gold = _mix(_mix(const Color(0xFF6B4E12), const Color(0xFFE9B949), _cl(light + lightsOn * 0.7)), hor, haze);
    final wall = _mix(_mix(const Color(0xFF15120C), const Color(0xFFB8A27A), light), hor, haze);
    c.drawPath(
        Path()
          ..addRect(Rect.fromLTRB(hx - sz * 0.9, by0 - sz * 0.32, hx + sz * 0.9, by0 + 1))
          ..addRect(Rect.fromLTRB(hx - sz * 0.3, by0 - sz * 0.55, hx + sz * 0.3, by0)),
        Paint()..color = wall);
    final dome = Path()
      ..moveTo(hx - sz * 0.34, by0 - sz * 0.55)
      ..cubicTo(hx - sz * 0.42, by0 - sz * 0.95, hx - sz * 0.1, by0 - sz * 1.05, hx, by0 - sz * 1.22)
      ..cubicTo(hx + sz * 0.1, by0 - sz * 1.05, hx + sz * 0.42, by0 - sz * 0.95, hx + sz * 0.34, by0 - sz * 0.55)
      ..close();
    if (lightsOn > 0.1) {
      _glow(Offset(hx, by0 - sz * 0.7), sz * 1.8, const Color(0xFFFFC94D).withOpacity(0.3 * lightsOn * (1 - haze)));
      _flush(c);
    }
    c.drawPath(dome, Paint()..color = gold);
    for (final sd in const [-1.0, 1.0]) {
      final mx = hx + sd * sz * 0.72;
      c.drawRect(Rect.fromLTRB(mx - sz * 0.05, by0 - sz * 1.45, mx + sz * 0.05, by0 - sz * 0.3), Paint()..color = wall);
      c.drawRect(Rect.fromLTRB(mx - sz * 0.085, by0 - sz * 1.15, mx + sz * 0.085, by0 - sz * 1.08), Paint()..color = gold);
      c.drawPath(
          Path()
            ..moveTo(mx - sz * 0.05, by0 - sz * 1.45)
            ..lineTo(mx, by0 - sz * 1.62)
            ..lineTo(mx + sz * 0.05, by0 - sz * 1.45)
            ..close(),
          Paint()..color = gold);
    }
    if (_holyKm != s.holyD.round()) {
      _holyKm = s.holyD.round();
      _holyTp = TextPainter(text: TextSpan(text: 'كربلاء $_holyKm كم', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white, shadows: [Shadow(color: Color(0xCC000000), blurRadius: 4)])), textDirection: TextDirection.rtl)..layout();
    }
    final tp = _holyTp!;
    tp.paint(c, Offset(hx - tp.width / 2, by0 - sz * 1.62 - tp.height - 2));
  }

  /// صورة هيكل السيارة الثابت (تُرسم مرة لكل شكل/لون/حجم/مستوى ضوء)
  ui.Image _carImage(double cw, double light) {
    final lq = (light * 24).round(), key = '${s.model}|${s.color}|${cw.round()}|$lq|${g.dpr}';
    if (key == _carKey && _carImg != null) return _carImg!;
    final rec = ui.PictureRecorder(), c = Canvas(rec);
    c.scale(g.dpr);
    c.translate(cw * 0.65, cw * 0.9);
    _carBody(c, _carModels[s.model] ?? _carModels['sport']!, _carColors[s.color] ?? _carColors['green']!, cw, lq / 24);
    final pic = rec.endRecording();
    final img = pic.toImageSync((cw * 1.3 * g.dpr).ceil(), (cw * g.dpr).ceil());
    pic.dispose();
    _carImg?.dispose();
    _carImg = img;
    _carKey = key;
    return img;
  }

  /// الأجزاء الثابتة: ظلال التلامس، الإطارات، الهيكل بتظليل أسطواني، الزجاج، المرايا، اللوحة، الناشر والعادم، وأغطية الأضواء
  void _carBody(Canvas c, _CarM m, List<int> col, double cw, double light) {
    Offset p(double x, double y) => Offset(x * cw, y * cw);
    Rect r(double x0, double y0, double x1, double y1) => Rect.fromPoints(p(x0, y0), p(x1, y1));
    Color shade(int v) => Color.lerp(Color.lerp(Color(v), Colors.black, 0.78), Color(v), light)!;
    final ti0 = m.tire[0], ti1 = m.tire[1], th = m.tire[2];
    // ظل التلامس: ظل عريض ناعم + ظلام كامل تحت الهيكل + ظل حاد تحت كل إطار (السيارة جالسة على الأرض)
    c.drawOval(r(-0.62, -0.045, 0.62, 0.075), Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.04));
    c.drawRect(r(-ti1, -m.tire[2] * 0.6, ti1, 0.0), Paint()
      ..color = Colors.black.withOpacity(0.92)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.012));
    for (final sd in const [-1.0, 1.0]) {
      c.drawOval(r(sd * (ti0 - 0.025), -0.022, sd * (ti1 + 0.02), 0.026), Paint()
        ..color = Colors.black
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.007));
    }
    // الإطارات: مطاط بتظليل وخطوط مداس
    for (final sd in const [-1.0, 1.0]) {
      final tr = r(sd * ti0, -th, sd * ti1, 0.004);
      c.drawRRect(RRect.fromRectAndRadius(tr, Radius.circular(cw * 0.035)), Paint()..color = const Color(0xFF0A0B0B));
      c.drawRRect(RRect.fromRectAndRadius(tr, Radius.circular(cw * 0.035)), Paint()..shader = LinearGradient(colors: [Colors.black.withOpacity(0.6), const Color(0xFF2A2D2E).withOpacity(0.35), Colors.black.withOpacity(0.6)]).createShader(tr));
      for (int k = 1; k < 5; k++) {
        final y = -th + th * k / 5.2;
        c.drawLine(p(sd * (ti0 + 0.012), y), p(sd * (ti1 - 0.012), y), Paint()
          ..strokeWidth = math.max(1.0, cw * 0.003)
          ..color = Colors.black.withOpacity(0.55));
      }
    }
    final body = _cpath(m.body, cw), cab = _cpath(m.cab, cw);
    final bottom = m.body[0][2];
    final paintSh = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade(col[0]), shade(col[1]), shade(col[2]), shade(col[3])], stops: const [0, 0.3, 0.62, 1]).createShader(r(-0.5, -m.height, 0.5, bottom));
    c.drawPath(cab, Paint()..shader = paintSh);
    c.drawPath(body, Paint()..shader = paintSh);
    c.save();
    c.clipPath(body);
    c.drawRect(r(-0.52, -m.height, 0.52, 0), Paint()..shader = const LinearGradient(colors: [Color(0x8C000000), Color(0x00000000), Color(0x00000000), Color(0x8C000000)], stops: [0, 0.16, 0.84, 1]).createShader(r(-0.5, 0, 0.5, 0.01)));
    // انعكاس الأفق على الطلاء: شريط فاتح ناعم
    final band = r(-0.5, m.bumper - 0.09, 0.5, m.bumper - 0.03);
    c.drawRect(band, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.06 + 0.09 * light), Colors.white.withOpacity(0)]).createShader(band));
    c.restore();
    // خط لمعان الكتفين وحافة السطح العلوي
    final b = m.body;
    for (final sd in const [-1.0, 1.0]) {
      final hl = Path()
        ..moveTo(sd * b[2][5] * cw, b[2][6] * cw)
        ..cubicTo(sd * b[3][1] * cw, b[3][2] * cw, sd * b[3][3] * cw, b[3][4] * cw, sd * b[3][5] * cw, b[3][6] * cw);
      c.drawPath(hl, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cw * 0.009
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.12 + 0.35 * light)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.004));
    }
    // الزجاج الخلفي بانعكاس مائل
    final gl = _cpath(m.glass, cw);
    c.drawPath(gl, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(const Color(0xFF101C1B), const Color(0xFF3F625E), light)!, const Color(0xFF040C0B)]).createShader(r(0, -m.height, 0.01, m.glass[0][2])));
    c.save();
    c.clipPath(gl);
    c.drawPath(_cpath([[0, -0.12, -m.height], [1, -0.04, -m.height], [1, -0.16, -0.4], [1, -0.24, -0.4]], cw), Paint()..color = Colors.white.withOpacity(0.04 + 0.08 * light));
    c.restore();
    final rf = m.roof;
    c.drawPath(_cpath([[0, rf[0], rf[1]], [3, rf[0] * 0.55, rf[1] - 0.02, rf[2] * 0.55, rf[1] - 0.02, rf[2], rf[1]], [3, rf[2] * 0.55, rf[1] - 0.01, rf[0] * 0.55, rf[1] - 0.01, rf[0], rf[1]]], cw), Paint()..color = Colors.white.withOpacity(0.05 + 0.12 * light));
    if (m.rails) {
      for (final sd in const [-1.0, 1.0]) {
        c.drawRRect(RRect.fromRectAndRadius(r(sd * 0.3, rf[1] - 0.03, sd * 0.34, rf[1] + 0.005), Radius.circular(cw * 0.006)), Paint()..color = const Color(0xFF1A1C1E));
      }
    }
    if (m.spoiler != null) {
      final sp = m.spoiler!;
      c.drawRRect(RRect.fromRectAndRadius(r(sp[0], sp[1] - 0.012, sp[2], sp[3]), Radius.circular(cw * 0.008)), Paint()..color = shade(col[2]));
    }
    if (m.trunk != null) {
      c.drawLine(p(-0.42, m.trunk!), p(0.42, m.trunk!), Paint()
        ..strokeWidth = math.max(1.0, cw * 0.004)
        ..color = Colors.black.withOpacity(0.35));
    }
    // المرايا متصلة بالمقصورة
    final mr = m.mirror;
    for (final sd in const [-1.0, 1.0]) {
      c.drawLine(p(sd * (mr[0] - 0.035), (mr[1] + mr[3]) / 2 + 0.008), p(sd * mr[0], (mr[1] + mr[3]) / 2), Paint()
        ..strokeWidth = cw * 0.012
        ..color = shade(col[2]));
      c.drawRRect(RRect.fromRectAndRadius(r(sd * mr[0], mr[1], sd * mr[2], mr[3]), Radius.circular(cw * 0.018)), Paint()..color = shade(col[1]));
    }
    if (m.grille != null) {
      final gr = m.grille!;
      for (int k = 0; k < gr[3].round(); k++) {
        c.drawLine(p(gr[0], gr[1] - k * 0.011), p(gr[2], gr[1] - k * 0.011), Paint()
          ..strokeWidth = math.max(1.0, cw * 0.004)
          ..color = Colors.black.withOpacity(0.5));
      }
    }
    // أغطية الأضواء (مطفأة) — الإضاءة نفسها تُرسم حيّة فوقها
    if (m.bar != null) c.drawPath(_cpath(m.bar!, cw), Paint()..color = const Color(0xFF1A0306));
    for (final sd in const [-1.0, 1.0]) {
      c.drawPath(_cpath(m.lamp, cw, sx: sd), Paint()..color = const Color(0xFF240407));
    }
    final t3 = m.third;
    c.drawRRect(RRect.fromRectAndRadius(r(t3[0], t3[1], t3[2], t3[3]), Radius.circular(cw * 0.004)), Paint()..color = const Color(0xFF2A0508));
    c.drawLine(p(-0.47, m.bumper), p(0.47, m.bumper), Paint()
      ..strokeWidth = math.max(1.0, cw * 0.004)
      ..color = Colors.black.withOpacity(0.45));
    // اللوحة
    final pl = r(m.plate[0], m.plate[1], m.plate[2], m.plate[3]);
    c.drawRRect(RRect.fromRectAndRadius(pl.inflate(cw * 0.006), Radius.circular(cw * 0.01)), Paint()..color = Colors.black.withOpacity(0.35));
    c.drawRRect(RRect.fromRectAndRadius(pl, Radius.circular(cw * 0.008)), Paint()..color = Color.lerp(const Color(0xFF3A3A36), const Color(0xFFEEEBE2), light)!);
    if (_plate == null || (_plateW - cw).abs() > 1) {
      _plateW = cw;
      _plate = TextPainter(text: TextSpan(text: 'منبر', style: TextStyle(fontFamily: 'Cairo', fontSize: cw * 0.036, fontWeight: FontWeight.w700, color: kGreen, height: 1)), textDirection: TextDirection.rtl)..layout();
    }
    _plate!.paint(c, pl.center - Offset(_plate!.width / 2, _plate!.height / 2));
    // الناشر والعادم
    final df = m.diff;
    c.drawRRect(RRect.fromRectAndRadius(r(df[0], df[1], df[2], df[3]), Radius.circular(cw * 0.02)), Paint()..color = const Color(0xFF050C0B));
    for (double x = df[0] + 0.1; x < df[2] - 0.05; x += 0.1) {
      c.drawLine(p(x, df[1] + 0.01), p(x, df[3] - 0.01), Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.07));
    }
    for (final e in m.exh) {
      for (final sd in const [-1.0, 1.0]) {
        final ex = r(sd * e[0], e[1], sd * e[2], e[3]);
        c.drawRRect(RRect.fromRectAndRadius(ex, Radius.circular(cw * 0.02)), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(const Color(0xFF4A5452), const Color(0xFFDDE5E2), light)!, const Color(0xFF2C3433)]).createShader(ex));
        c.drawRRect(RRect.fromRectAndRadius(ex.deflate(cw * 0.008), Radius.circular(cw * 0.014)), Paint()..color = const Color(0xFF060808));
      }
    }
    c.drawPath(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.05 + 0.06 * light));
  }

  /// الأجزاء الحيّة: الأضواء (خلفية/فرامل/إشارة/لوحة)، لمعة الإنارة المارة، قطرات المطر، الثلج
  void _carLive(Canvas c, _CarM m, double cw, double light, double lightsOn, double wet, double pass, Color red, double lit) {
    Offset p(double x, double y) => Offset(x * cw, y * cw);
    Rect r(double x0, double y0, double x1, double y1) => Rect.fromPoints(p(x0, y0), p(x1, y1));
    final brake = s.brake, blinkOn = s.blink != 0 && (s.t * 1.6) % 1 < 0.55;
    if (pass.abs() < 3 && lightsOn > 0.2 || wet > 0.3 || s.snow > 0.4) {
      final whole = Path.combine(PathOperation.union, _cpath(m.body, cw), _cpath(m.cab, cw));
      c.save();
      c.clipPath(whole);
      if (pass.abs() < 3 && lightsOn > 0.2) {
        final k = (1 - pass.abs() / 3) * lightsOn, yy = -m.height + 0.01 + _cl((3 - pass) / 6) * 0.25;
        final hr = Rect.fromCenter(center: p(0, yy), width: cw * 0.95, height: cw * 0.08);
        c.drawOval(hr, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFD9A0).withOpacity(0.4 * k), const Color(0x00FFD9A0)]).createShader(hr));
      }
      if (wet > 0.3) {
        final pts = [for (int i = 0; i < 40; i++) p(-0.48 + _hash(i + 120) * 0.96, -m.height + _hash(i + 121) * (m.height - 0.1))];
        c.drawPoints(ui.PointMode.points, pts, Paint()
          ..strokeWidth = cw * 0.006
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(0.3 * wet));
      }
      c.restore();
    }
    if (s.snow > 0.4) {
      final sn = Paint()..color = Colors.white.withOpacity(0.92 * s.snow);
      final rf = m.roof;
      c.drawPath(_cpath([[0, rf[0] - 0.01, rf[1]], [3, rf[0] * 0.55, rf[1] - 0.035, rf[2] * 0.55, rf[1] - 0.035, rf[2] + 0.01, rf[1]], [3, rf[2] * 0.55, rf[1] - 0.008, rf[0] * 0.55, rf[1] - 0.008, rf[0] - 0.01, rf[1]]], cw), sn);
      final top = m.body[4][2];
      c.drawPath(_cpath([[0, -0.37, top + 0.002], [3, -0.2, top - 0.02, 0.2, top - 0.02, 0.37, top + 0.002], [3, 0.2, top - 0.006, -0.2, top - 0.006, -0.37, top + 0.002]], cw), sn);
    }
    // الأضواء الخلفية: تعبئة + توهّج إضافي (بلا تمويه)
    for (final sd in const [-1.0, 1.0]) {
      final here = blinkOn && s.blink == sd, cc = here ? const Color(0xFFFFA51F) : red, lp = _cpath(m.lamp, cw, sx: sd);
      c.drawPath(lp, Paint()..color = cc);
      final bnd = lp.getBounds();
      _glow(bnd.center, bnd.width * (0.7 + 0.5 * (here ? 1 : brake)), cc.withOpacity(_cl(0.18 + 0.5 * (here ? 1 : lit))));
    }
    final led = _cpath(m.led, cw, close: false);
    for (final wv in [(0.05 + 0.05 * brake, 0.12 + 0.2 * lit), (0.022 + 0.02 * brake, 0.25 + 0.4 * lit)]) {
      c.drawPath(led, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cw * wv.$1
        ..strokeCap = StrokeCap.round
        ..color = red.withOpacity(_cl(wv.$2)));
    }
    c.drawPath(led, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cw * 0.007
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(red, Colors.white, 0.35 * lit)!);
    final t3 = m.third, tb = r(t3[0], t3[1], t3[2], t3[3]);
    if (brake > 0.05) {
      c.drawRRect(RRect.fromRectAndRadius(tb, Radius.circular(cw * 0.004)), Paint()..color = Color.lerp(const Color(0xFF2A0508), const Color(0xFFFF4050), brake)!);
      _glow(tb.center, tb.width * 0.9, const Color(0xFFFF2236).withOpacity(0.55 * brake));
    }
    if (lightsOn > 0.2) {
      final pl = r(m.plate[0], m.plate[1], m.plate[2], m.plate[3]);
      _glow(Offset(pl.center.dx, pl.top), pl.width * 0.7, const Color(0xFFFFF4E0).withOpacity(0.35 * lightsOn));
    }
    _flush(c);
  }

  @override
  bool shouldRepaint(covariant _World o) => o.g.hz != g.hz || o.g.cx != g.cx || o.g.carY != g.carY || o.g.cw != g.cw || o.g.dpr != g.dpr;
}
