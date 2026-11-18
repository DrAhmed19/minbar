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

part 'car_scene.dart';
part 'car_geo.dart';
part 'car_map.dart';

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
const _modelNames = {'sport': 'رياضية', 'sedan': 'سيدان', 'suv': 'دفع رباعي'};
const _colorNames = {'green': 'أخضر منبر', 'black': 'أسود', 'white': 'أبيض', 'silver': 'فضي', 'red': 'أحمر', 'blue': 'أزرق', 'gold': 'ذهبي'};

/// حالة المشهد الحيّة (تتحدث كل إطار بلا إعادة بناء الصفحة)
class _Scene {
  double t = 0, q = 0, v = 0, a = 0, brake = 0, tail = 0.3, curv = 0, lean = 0, blink = 0, pitch = 0, spin = 0, flash = 0, splash = 0;
  double sunEl = 45, sunAz = 180, moonEl = -20, moonAz = 0, moonPh = 0.5, heading = 180;
  double rain = 0, snow = 0, cloud = 0, fog = 0, dust = 0, storm = 0, wind = 0;
  int biome = 2; // نوع المنطقة الحالية
  double temp = double.nan;
  List<(double, double, int)> marks = const []; // معالم قريبة: (اتجاه، كم، نوع)
  int bolt = 0;
  bool over = false; // تجاوز حد السرعة
  String model = 'sport', color = 'green';
}

/// أبعاد المسرح المحسوبة من التخطيط
class _Stage {
  final double hz, cx, carY, cw, dpr;
  const _Stage(this.hz, this.cx, this.carY, this.cw, this.dpr);
}

/// موارد الرسم: نقوش وجزيئات تُولَّد بكسلاتها على المعالج (بلا رسم خارج الشاشة)،
/// ونخيل وغيوم كـ«صور متجهة» مسجّلة مرة لكل مستوى إضاءة — تجنباً لأعطال بعض المعالجات الرسومية
class _Art {
  static bool _started = false, ready = false;
  static late ui.Image dot, streak, flake, asphalt, sand;

  static Future<ui.Image> _pix(int w, int h, Uint8List rgba) {
    final cpl = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, cpl.complete);
    return cpl.future;
  }

  /// بقعة بيضاء ناعمة: a(d) دالة الشفافية حسب البعد عن المركز (0..1)
  static Uint8List _soft(int w, int h, double Function(double nx, double ny) a) {
    final px = Uint8List(w * h * 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final i = (y * w + x) * 4, v = (_cl(a((x + 0.5) / w * 2 - 1, (y + 0.5) / h * 2 - 1)) * 255).round();
        // ألوان مضروبة مسبقاً بالشفافية (المطلوب من المعالج الرسومي)
        px[i] = v;
        px[i + 1] = v;
        px[i + 2] = v;
        px[i + 3] = v;
      }
    }
    return px;
  }

  static void ensure() {
    if (_started) return;
    _started = true;
    _build();
  }

  static Future<void> _build() async {
    dot = await _pix(64, 64, _soft(64, 64, (x, y) {
      final d = math.sqrt(x * x + y * y);
      return d >= 1 ? 0 : math.pow(1 - d, 2.2).toDouble();
    }));
    streak = await _pix(8, 96, _soft(8, 96, (x, y) {
      final across = math.max(0.0, 1 - x.abs() * 1.6), along = y < 0.64 ? (y + 1) / 1.64 : 1 - (y - 0.64) / 0.36 * 0.75;
      return across * across * along * 0.95;
    }));
    flake = await _pix(32, 32, _soft(32, 32, (x, y) {
      final d = math.sqrt(x * x + y * y);
      return d >= 1 ? 0 : (d < 0.35 ? 1 : math.pow((1 - d) / 0.65, 1.5).toDouble());
    }));
    // أسفلت: حبيبات حصى داكنة وفاتحة على خلفية شفافة (قابلة للتكرار)
    final r = math.Random(5), ap = Uint8List(256 * 256 * 4);
    void dotPx(Uint8List b, int x, int y, int rr, int gg, int bb, int a) {
      final i = (((y & 255) * 256) + (x & 255)) * 4;
      if (b[i + 3] >= a) return;
      b[i] = rr * a ~/ 255;
      b[i + 1] = gg * a ~/ 255;
      b[i + 2] = bb * a ~/ 255;
      b[i + 3] = a;
    }

    for (int k = 0; k < 9000; k++) {
      final x = r.nextInt(256), y = r.nextInt(256), dark = r.nextDouble() < 0.62, a = dark ? 60 + r.nextInt(90) : 25 + r.nextInt(45), v = dark ? 0 : 255;
      dotPx(ap, x, y, v, v, v, a);
      if (r.nextDouble() < 0.35) {
        dotPx(ap, x + 1, y, v, v, v, a ~/ 2);
        dotPx(ap, x, y + 1, v, v, v, a ~/ 2);
      }
    }
    asphalt = await _pix(256, 256, ap);
    // رمل: تموجات ريح + حبيبات
    final sp = Uint8List(256 * 256 * 4);
    for (int y = 0; y < 256; y++) {
      for (int x = 0; x < 256; x++) {
        final w0 = math.sin((y + math.sin(x / 256 * math.pi * 4) * 5) / 256 * math.pi * 2 * 22);
        final i = (y * 256 + x) * 4;
        int a = 0, rr = 0, gg = 0, bb = 0;
        if (w0 > 0.55) {
          a = ((w0 - 0.55) * 90).round();
          rr = 255;
          gg = 245;
          bb = 225;
        } else if (w0 < -0.4) {
          a = ((-w0 - 0.4) * 80).round();
          rr = 60;
          gg = 40;
          bb = 15;
        }
        sp[i] = rr * a ~/ 255;
        sp[i + 1] = gg * a ~/ 255;
        sp[i + 2] = bb * a ~/ 255;
        sp[i + 3] = a;
      }
    }
    for (int k = 0; k < 2500; k++) {
      final dark = r.nextBool();
      dotPx(sp, r.nextInt(256), r.nextInt(256), dark ? 50 : 255, dark ? 35 : 250, dark ? 10 : 235, dark ? 70 : 50);
    }
    sand = await _pix(256, 256, sp);
    ready = true;
  }

  // ---------- نخيل وغيوم: صور متجهة مسجّلة حسب الإضاءة ----------
  static final Map<String, ui.Picture> _pics = {};
  static ui.Picture palm(int v, double light, double dust) {
    final key = 'p$v|${(light * 16).round()}|${(dust * 4).round()}';
    return _pics[key] ??= () {
      if (_pics.length > 60) _pics.clear();
      final rec = ui.PictureRecorder();
      _palm(Canvas(rec), v, (light * 16).round() / 16, (dust * 4).round() / 4);
      return rec.endRecording();
    }();
  }

  /// نخلة عراقية بإحداثيات 256×320 (القاعدة عند 128،318): جذع مخروطي بحلقات، سعف ورقي مسنّن بطبقتين، وعذوق تمر
  static void _palm(Canvas c, int v, double light, double dust) {
    Color L(int day) => _mix(_mix(const Color(0xFF0E1216), Color(day), light), const Color(0xFFD8BC8A), dust * 0.45);
    final r = math.Random(31 + v);
    const bx = 128.0, by = 318.0;
    final tx = 128.0 + (v - 1) * 12, ty = 72.0 + v * 6;
    final trunk = Path()
      ..moveTo(bx - 10, by)
      ..quadraticBezierTo(bx - 6, (by + ty) / 2, tx - 6, ty)
      ..lineTo(tx + 6, ty)
      ..quadraticBezierTo(bx + 7, (by + ty) / 2, bx + 10, by)
      ..close();
    c.drawPath(trunk, Paint()..shader = ui.Gradient.linear(const Offset(bx - 10, 0), const Offset(bx + 10, 0), [L(0xFF5B4329), L(0xFF8E6E46), L(0xFF45311C)], [0, 0.42, 1]));
    final ring = Paint()
      ..strokeWidth = 1.8
      ..color = L(0xFF2E2112);
    for (double u = 0.03; u < 0.97; u += 0.05) {
      final x = (1 - u) * (1 - u) * bx + 2 * (1 - u) * u * (bx - 1) + u * u * tx, y = by + (ty - by) * u, hw = 10 - 4 * u;
      c.drawLine(Offset(x - hw, y + 1.5), Offset(x, y - 1.5), ring);
      c.drawLine(Offset(x, y - 1.5), Offset(x + hw, y + 1.5), ring);
    }
    // سعفة: عرق منحني + شريط ورقي مسنّن على الجانبين يضيق نحو الطرف
    void frond(double a, double len, Color col) {
      final ex = tx + math.sin(a) * len, ey = ty - math.cos(a) * len * 0.3 + (a.abs() * 0.5 + 0.3) * len * 0.55;
      final cxq = tx + math.sin(a) * len * 0.5, cyq = ty - len * 0.36 - math.cos(a) * 10;
      Offset at(double u) => Offset((1 - u) * (1 - u) * tx + 2 * (1 - u) * u * cxq + u * u * ex, (1 - u) * (1 - u) * ty + 2 * (1 - u) * u * cyq + u * u * ey);
      final up = <Offset>[], dn = <Offset>[];
      for (int i = 0; i <= 18; i++) {
        final u = i / 18, pt = at(u), nx = at(math.min(1, u + 0.02)) - at(math.max(0, u - 0.02));
        final dl = nx.distance + 1e-6, n = Offset(-nx.dy / dl, nx.dx / dl), wd = (math.sin(u * math.pi) * 0.85 + 0.15) * (1 - u * 0.6) * 15 * (i.isEven ? 1 : 0.55);
        up.add(pt + n * wd + const Offset(0, 4));
        dn.add(pt - n * wd + const Offset(0, 4));
      }
      final leaf = Path()..moveTo(tx, ty);
      for (final o in up) {
        leaf.lineTo(o.dx, o.dy);
      }
      for (final o in dn.reversed) {
        leaf.lineTo(o.dx, o.dy);
      }
      leaf.close();
      c.drawPath(leaf, Paint()..color = col);
      c.drawPath(
          Path()
            ..moveTo(tx, ty)
            ..quadraticBezierTo(cxq, cyq, ex, ey),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = _mix(col, Colors.black, 0.3));
    }

    for (int i = 0; i < 8; i++) {
      frond(-1.9 + i * 0.54 + r.nextDouble() * 0.2, 92 + r.nextDouble() * 22, L(0xFF2A4A1D));
    }
    for (final sd in const [-1.0, 1.0]) {
      for (int k = 0; k < 10; k++) {
        c.drawCircle(Offset(tx + sd * (9 + r.nextDouble() * 9), ty + 9 + r.nextDouble() * 18), 3.2, Paint()..color = L(_mix(const Color(0xFFB8661E), const Color(0xFF6B3410), r.nextDouble()).value));
      }
    }
    for (int i = 0; i < 9; i++) {
      frond(-1.75 + i * 0.44 + r.nextDouble() * 0.15, 98 + r.nextDouble() * 26, L(_mix(const Color(0xFF4B7C31), const Color(0xFF6F9542), r.nextDouble()).value));
    }
    c.drawCircle(Offset(tx, ty + 2), 7, Paint()..color = L(0xFF3B5A26));
  }

  /// غيمة ركامية من كتل بتدرّج دائري ناعم (بلا تمويه): قمة مضاءة وقاعدة رمادية
  static ui.Picture cloud(int v, Color lit, Color base, double a) {
    final key = 'c$v|${lit.value}|${base.value}|${(a * 5).round()}';
    return _pics[key] ??= () {
      if (_pics.length > 60) _pics.clear();
      final rec = ui.PictureRecorder(), c = Canvas(rec), r = math.Random(70 + v);
      // غيمة ركامية: قاعدة مسطحة عريضة + قمم متدرجة؛ كتل معتمة بحواف ناعمة، الأعلى أفتح
      final blobs = <(double, double, double)>[];
      for (int i = 0; i < 14; i++) {
        final rad = 22 + r.nextDouble() * 16;
        blobs.add((60 + i * 28 + r.nextDouble() * 14, 150 - rad * 0.35, rad));
      }
      for (int i = 0; i < 9; i++) {
        final t = i / 8, rad = (30 + r.nextDouble() * 30) * (1 - (t - 0.5).abs() * 0.9);
        blobs.add((110 + t * 290 + r.nextDouble() * 20, 140 - rad * 0.9 - r.nextDouble() * 10, rad));
      }
      for (int i = 0; i < 5; i++) {
        final t = i / 4, rad = (26 + r.nextDouble() * 20) * (1 - (t - 0.5).abs());
        blobs.add((170 + t * 170 + r.nextDouble() * 15, 105 - rad * 0.7, rad));
      }
      blobs.sort((p, q) => q.$2.compareTo(p.$2));
      for (final b in blobs) {
        final k = _cl((155 - b.$2) / 110), cc = _mix(base, lit, 0.35 + 0.65 * k), hi = _mix(cc, Colors.white, 0.25 * k);
        c.drawCircle(Offset(b.$1, b.$2), b.$3, Paint()..shader = ui.Gradient.radial(Offset(b.$1 - b.$3 * 0.2, b.$2 - b.$3 * 0.35), b.$3 * 1.05, [hi.withOpacity(a), cc.withOpacity(a), cc.withOpacity(a), cc.withOpacity(0)], [0, 0.6, 0.78, 1]));
      }
      return rec.endRecording();
    }();
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
  double _posAt = -99, _gpsStartAt = -99, _lastRestart = -99;
  final _mapTick = ValueNotifier<int>(0);
  final _nav = ValueNotifier<_NavInfo?>(null);
  double _mapHead = 0;
  bool _mapOn = true;
  bool _gotFix = false, _useLM = true; // _useLM: GPS مباشر من الجهاز (يعمل بدون إنترنت) وإلا مزوّد جوجل
  // الطقس والوقت
  _Wx _wx = _Wx();
  int _wMode = 0, _tMode = 0;
  final _rnd = math.Random();
  // الإعدادات
  int _limit = 0; // 0 = بلا تنبيه
  int _qMode = 0; // جودة الرسوم: 0 تلقائي، 1 عالية، 2 متوسطة، 3 خفيفة
  int _bMode = -1; // المنطقة: -1 تلقائي
  _Region? _region;
  bool _hasPos = false, _geoBusy = false;
  double _gLat = 0, _gLon = 0;

  // خيارات المشهد (منطقة/وقت/طقس يدوي) للمشرف فقط للفحص؛ المستخدم دائماً تلقائي وحقيقي
  bool get _adm => app.auth.admin;
  int get _bM => _adm ? _bMode : -1;
  int get _wM => _adm ? _wMode : 0;
  int get _tM => _adm ? _tMode : 0;

  void _applyBiome() => _sc.biome = _bM >= 0 ? _bM : (_region?.biome ?? _bFarm);

  /// المحافظة والحي ونوع المشهد: محلياً بدون إنترنت (فوري)، وكل ما تتحرك 700 م يُحدَّث تلقائياً.
  /// الإنترنت احتياط فقط إذا الموقع خارج بيانات العراق.
  Future<void> _geo({bool force = false}) async {
    if (!_hasPos || _geoBusy) return;
    if (!force && _region != null && Geolocator.distanceBetween(_gLat, _gLon, _lat, _lon) < 700) return;
    final off = _offlineRegion(_lat, _lon);
    if (off != null) {
      _gLat = _lat;
      _gLon = _lon;
      final old = _region;
      if (old == null || old.place != off.place || old.sub != off.sub || old.biome != off.biome) {
        _region = off;
        _applyBiome();
        if (mounted) setState(() {});
      }
      return;
    }
    _geoBusy = true;
    final r = await _reverse(_lat, _lon);
    _geoBusy = false;
    if (r == null || !mounted) return;
    _gLat = _lat;
    _gLon = _lon;
    setState(() {
      _region = r;
      _applyBiome();
    });
  }
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
    if (_qMode != 0) {
      _ft.clear();
      return;
    }
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
    // بدون إنترنت: وضع السيارة يشغّل المحمّل وملفات الجهاز، والطقس والمنطقة يبقيان على آخر حالة
    if (app.repo.noNet && app.player.queue.isEmpty && app.repo.playableOffline.isNotEmpty) app.player.playList(app.repo.playableOffline, 0);
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
      _gpsWatch();
      if (DateTime.now().second == 30) _geo();
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
      _mapOn = p.getBool('car.map') ?? true;
      _qMode = p.getInt('car.q') ?? 0;
      _bMode = p.getInt('car.biome') ?? -1;
      _applyBiome();
      if (_qMode != 0) _World.q = 3 - _qMode;
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
    _posAt = _now;
    _gotFix = true;
    final now = p.timestamp.millisecondsSinceEpoch / 1000.0;
    _acc = p.accuracy;
    // 1) سرعة الجهاز (دوبلر): الأدق، نقبلها حتى لو دقتها متوسطة
    double? dop;
    if (p.speed.isFinite && p.speed >= 0 && (p.speedAccuracy <= 0 || p.speedAccuracy < 4)) dop = p.speed;
    // 2) سرعة محسوبة من المسافة/الزمن بين موقعين (احتياط)
    final lp = _lp;
    double? der;
    double d = 0, dt = 0;
    if (lp != null) {
      dt = now - _lt;
      if (dt > 0.25 && dt < 12) {
        d = Geolocator.distanceBetween(lp.latitude, lp.longitude, p.latitude, p.longitude);
        if (p.accuracy < 40 && lp.accuracy < 40) der = d / dt;
      }
    }
    double? sp = dop ?? der;
    // الجهاز أحياناً يعطي صفر رغم الحركة الفعلية: نعتمد المحسوبة إذا القفزة أكبر بوضوح من ضجيج الـGPS
    if (dop != null && dop < 0.5 && der != null && der > 3 && d > (p.accuracy + (lp?.accuracy ?? 0)) * 0.6) sp = der;
    // لا سرعة قابلة للاعتماد (دقة ضعيفة لحظياً): نُبقي آخر سرعة مع تخفيف بدل التوقف المفاجئ
    sp ??= _rawV * 0.85;
    if (lp != null && dt > 0.2 && dt < 15) {
      final lim = _rawV + 9 * dt; // رفض القفزات غير الممكنة
      if (sp > lim) sp = lim;
      if (sp > 1.2 && d < sp * dt * 1.6 + 6) _dist += d;
      if (sp > 2.5 && p.heading >= 0 && lp.heading >= 0 && (p.headingAccuracy <= 0 || p.headingAccuracy < 25)) {
        final dh = ((p.heading - lp.heading + 540) % 360) - 180;
        _turn += (_cl((dh / dt) * math.pi / 180, -0.6, 0.6) - _turn) * 0.6;
        _sc.heading = p.heading;
        _mapHead = (_mapHead + ((p.heading - _mapHead + 540) % 360 - 180) * 0.6 + 360) % 360;
      } else if (sp < 1.5) {
        _turn *= 0.5;
      }
    }
    _lp = p;
    _lt = now;
    _lat = p.latitude;
    _lon = p.longitude;
    if (!_hasPos) {
      _hasPos = true;
      _env();
    }
    _geo(); // تحديث المنطقة تلقائياً مع التنقل (محلي وفوري)
    if (_mapOn) {
      final nv = _navCompute(_lat, _lon, _mapHead, sp > 2.5);
      if (nv != null || sp > 2.5) _nav.value = nv;
    }
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
          _hasPos = true;
          _env();
          _geo();
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
      await _gpsStart();
      if (mounted) setState(() => gps = true);
      (await SharedPreferences.getInstance()).setBool('car.gps', true);
      final lp = await Geolocator.getLastKnownPosition();
      if (lp != null) {
        _lat = lp.latitude;
        _lon = lp.longitude;
        _hasPos = true;
        _env();
        _geo();
      }
    } catch (_) {
      if (ask) _say('تعذّر تشغيل عدّاد السرعة');
    }
  }

  /// اشتراك GPS: أولاً GPS الجهاز مباشرة (أدق، لا يحتاج إنترنت ولا خدمات جوجل)، وإذا لم يصل موقع يتحول للمزوّد البديل
  Future<void> _gpsStart() async {
    await _gs?.cancel();
    _gotFix = false;
    _gpsStartAt = _now;
    _posAt = _now;
    _gs = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 1000),
        forceLocationManager: _useLM,
      ),
    ).listen(_onPos, onError: (_) {
      Timer(const Duration(seconds: 2), () {
        if (mounted && gps) _gpsStart();
      });
    });
  }

  /// مراقب: إذا انقطع وصول المواقع أكثر من 6 ثوانٍ نعيد تشغيل الاشتراك، وإذا ما وصل أي موقع نبدّل المزوّد
  void _gpsWatch() {
    if (!gps || _gs == null) return;
    final t = _now;
    if (t - _posAt > 6 && t - _lastRestart > 10) {
      _lastRestart = t;
      if (!_gotFix) _useLM = !_useLM;
      _gpsStart();
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
    // معالم قريبة باتجاهها الحقيقي (فقط إذا موقعك معروف)
    final la1 = _lat * rad;
    double brg(double la, double lo) {
      final dl = (lo - _lon) * rad, l2 = la * rad;
      return (math.atan2(math.sin(dl) * math.cos(l2), math.cos(la1) * math.sin(l2) - math.sin(la1) * math.cos(l2) * math.cos(dl)) / rad + 360) % 360;
    }

    _sc.marks = !_hasPos
        ? const []
        : [
            for (final m in _landmarks)
              if (Geolocator.distanceBetween(_lat, _lon, m.$1, m.$2) < 45000) (brg(m.$1, m.$2), Geolocator.distanceBetween(_lat, _lon, m.$1, m.$2) / 1000, m.$3),
          ];
    final h = _sc.heading;
    switch (_tM) {
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
      _sc.temp = w.temp;
      if (mounted) setState(() => _wx = w);
    } catch (e) {
      debugPrint('car wx fail $e');
      _wt2?.cancel();
      _wt2 = Timer(const Duration(seconds: 60), _wxFetch); // إعادة المحاولة
    } finally {
      c.close();
    }
  }

  _Wx get _wxNow => _presets[_wM] ?? _wx;

  // ---------------- كل إطار ----------------
  void _tick(Duration e) {
    final dt = _cl((e - _last).inMicroseconds / 1e6, 0, 0.05);
    _last = e;
    if (dt <= 0) return;
    final s = _sc, playing = app.player.p.playing;
    s.t += dt;
    double target;
    final gp = gps;
    if (gps) {
      final age = _now - _fixAt;
      target = age < 6 ? _rawV : _rawV * _cl(1 - (age - 6) / 5); // فقدان الإشارة: تباطؤ تدريجي
    } else {
      target = playing ? 13.9 : 0; // بدون GPS: سير عرضي 50 كم/س مع التشغيل
    }
    final prev = s.v;
    s.v += (target - s.v) * math.min(1.0, dt * 2.4);
    final acc = (s.v - prev) / dt;
    s.a += (acc - s.a) * math.min(1.0, dt * 4);
    final braking = gp ? ((s.a < -0.7 && s.v > 0.5) || s.v < 0.35) : !playing;
    s.brake += ((braking ? 1.0 : 0.0) - s.brake) * math.min(1.0, dt * 14);
    s.q += s.v * dt / 2.5; // وحدة العمق = 2.5 م
    if (playing) s.spin += dt * 0.8;
    final k = gp && s.v > 2.5 ? _cl(_turn / s.v, -0.03, 0.03) : 0.0;
    s.curv += (k - s.curv) * math.min(1.0, dt * 1.2);
    s.lean += ((gp ? _cl(s.v * _turn / 9.8, -0.5, 0.5) : 0.0) - s.lean) * math.min(1.0, dt * 3);
    if (gp && _turn.abs() > 0.13 && s.v < 17) _blinkHold = 1.6 * _turn.sign;
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
    if (_mapOn && _frame.value % 6 == 0) _mapTick.value++;
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
    _mapTick.dispose();
    _nav.dispose();
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
    String? lastTrip;
    try {
      final p = await SharedPreferences.getInstance(), j = p.getString('car.lastTrip');
      if (j != null) {
        final m = jsonDecode(j) as Map<String, dynamic>;
        lastTrip = '${((m['d'] as num) / 1000).toStringAsFixed(1)} كم · ${_dur((m['t'] as num).toDouble())} · ${m['n']} قصيدة';
      }
    } catch (_) {}
    if (!mounted) return;
    _tk.muted = true; // إيقاف رسم المشهد خلف النافذة لتوفير المعالج
    Future<void> save(String k, Object v) async {
      final p = await SharedPreferences.getInstance();
      if (v is String) p.setString(k, v);
      if (v is int) p.setInt(k, v);
      if (v is bool) p.setBool(k, v);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(builder: (c, set) {
        void upd(VoidCallback f) {
          HapticFeedback.selectionClick();
          f();
          set(() {});
          setState(() {});
        }

        Widget chip(String label, bool on, VoidCallback f, {String? icon}) => GestureDetector(
              onTap: () => upd(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: on ? const Color(0x2EE8C468) : const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: on ? kGold : const Color(0x1FFFFFFF))),
                child: Text('${icon == null ? '' : '$icon '}$label', style: tx(13, c: on ? kGold : Colors.white70)),
              ),
            );
        Widget card(String icon, String title, List<Widget> kids, {String? note, bool admin = false}) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  child: Row(children: [
                    PIcon(icon, color: admin ? const Color(0xFFE59A9A) : kGold, size: 17),
                    const SizedBox(width: 8),
                    Text(title, style: tx(13.5, c: admin ? const Color(0xFFE59A9A) : kGold, w: FontWeight.w700)),
                    if (admin) ...[
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1), decoration: BoxDecoration(color: const Color(0x33E59A9A), borderRadius: BorderRadius.circular(8)), child: Text('مشرف', style: tx(10.5, c: const Color(0xFFE59A9A)))),
                    ],
                    const Spacer(),
                    if (note != null) Text(note, style: tx(11.5, c: Colors.white54)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x14FFFFFF))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: kids),
                ),
              ]),
            );
        Widget label(String t) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Text(t, style: tx(12, c: Colors.white54)));
        Widget wrap(List<Widget> k) => Wrap(spacing: 7, runSpacing: 7, children: k);
        // مفتاح تبديل مقسّم بحجم الشاشة (أنماط التطبيقات الحديثة)
        Widget seg(List<String> names, int sel, void Function(int) on) => Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: const Color(0x14000000), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                for (int i = 0; i < names.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => upd(() => on(i)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: sel == i ? const Color(0xFFE8C468) : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                        child: Text(names[i], style: tx(13, c: sel == i ? const Color(0xFF2A2106) : Colors.white70, w: sel == i ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ),
                  ),
              ]),
            );
        Widget tile(String icon, String title, String value, {Color? vc}) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [PIcon(icon, color: Colors.white54, size: 15), const SizedBox(width: 6), Text(title, style: tx(11.5, c: Colors.white54))]),
                  const SizedBox(height: 8),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: tx(14.5, c: vc ?? Colors.white, h: 1.35, w: FontWeight.w700)),
                ]),
              ),
            );
        Widget stat(String v, String l) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [Text(v, style: tx(17, c: Colors.white, h: 1.2, w: FontWeight.w700)), Text(l, style: tx(11, c: Colors.white54))]),
              ),
            );
        final total = DateTime.now().difference(_start).inSeconds.toDouble(), avg = _moveSec > 30 ? _dist / _moveSec * 3.6 : 0.0;
        final detected = _region == null ? 'غير محددة' : (_biomeNames[_region!.biome] ?? '');
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (c, sc) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF10261F), Color(0xFF07140F)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              border: Border(top: BorderSide(color: Color(0x40E8C468))),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), children: [
                Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text('إعدادات وضع السيارة', style: tx(19, c: kGold))),
                  IconButton(onPressed: () => Navigator.pop(c), icon: const PIcon(Ic.x, color: Colors.white70, size: 22)),
                ]),
                const SizedBox(height: 6),
                // الحالة الحالية: المنطقة (تلقائية وتعمل بدون إنترنت) والسرعة
                Row(children: [
                  tile(Ic.compass, 'المنطقة', _region == null ? (_hasPos ? 'جارٍ التحديد…' : 'الموقع غير متاح') : [_region!.place, if (_region!.sub.isNotEmpty) _region!.sub].join(' · ')),
                  tile(Ic.speed, 'عدّاد السرعة', !gps ? 'متوقف' : (_now - _posAt < 6 ? (_acc < 15 ? 'يعمل · دقيق' : 'يعمل · ±${_acc.round()} م') : 'ينتظر الإشارة'), vc: gps && _now - _posAt < 6 ? const Color(0xFF8EE0A8) : null),
                ]),
                const SizedBox(height: 16),
                card(Ic.color, 'السيارة', [
                  seg([for (final e in _modelNames.entries) e.value], _modelNames.keys.toList().indexOf(_sc.model), (i) {
                    _sc.model = _modelNames.keys.elementAt(i);
                    save('car.model', _sc.model);
                  }),
                  label('اللون: ${_colorNames[_sc.color] ?? ''}'),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (final e in _carColors.entries)
                      Semantics(
                        label: _colorNames[e.key],
                        button: true,
                        child: GestureDetector(
                          onTap: () => upd(() {
                            _sc.color = e.key;
                            save('car.color', e.key);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(e.value[0]), Color(e.value[1]), Color(e.value[3])]),
                              border: Border.all(color: _sc.color == e.key ? kGold : const Color(0x33FFFFFF), width: _sc.color == e.key ? 3 : 1),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ]),
                card(Ic.timer, 'القيادة الآمنة', [
                  Row(children: [
                    Expanded(child: Text('تنبيه السرعة', style: tx(14, c: Colors.white))),
                    Text(_limit == 0 ? 'متوقف' : '$_limit كم/س', style: tx(14, c: kGold, w: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 3),
                  Text('نغمة هادئة مرة وحدة عند التجاوز', style: tx(12, c: Colors.white54)),
                  const SizedBox(height: 10),
                  wrap([
                    for (final v in const [0, 60, 80, 100, 110, 120, 130, 140])
                      chip(v == 0 ? 'إيقاف' : '$v', _limit == v, () {
                        _limit = v;
                        _alertArmed = true;
                        save('car.limit', v);
                        if (v > 0 && !gps) _gpsOn();
                      }),
                  ]),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _restOn,
                    activeColor: kGold,
                    onChanged: (v) => upd(() {
                      _restOn = v;
                      save('car.rest', v);
                    }),
                    title: Text('تذكير بالاستراحة كل ساعتين قيادة', style: tx(14, c: Colors.white)),
                  ),
                ]),
                card(Ic.pulse, 'الأداء', [
                  Text('جودة الرسوم', style: tx(14, c: Colors.white)),
                  const SizedBox(height: 3),
                  Text('التلقائية تضبط الجودة حسب قدرة الجهاز', style: tx(12, c: Colors.white54)),
                  const SizedBox(height: 10),
                  seg(const ['تلقائية', 'عالية', 'متوسطة', 'خفيفة'], _qMode, (i) {
                    _qMode = i;
                    save('car.q', i);
                    _World.q = i == 0 ? (app.player.perf == 0 ? 2 : 1) : 3 - i;
                  }),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _mapOn,
                    activeColor: kGold,
                    onChanged: (v) => upd(() {
                      _mapOn = v;
                      save('car.map', v);
                      if (!v) _nav.value = null;
                    }),
                    title: Text('الخريطة المصغرة وشريط البلدات', style: tx(14, c: Colors.white)),
                    subtitle: Text('تعمل بدون إنترنت', style: tx(12, c: Colors.white54)),
                  ),
                ]),
                card(Ic.power, 'الاتصال بالسيارة', [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: auto,
                    activeColor: kGold,
                    onChanged: (v) => upd(() {
                      auto = v;
                      CarAuto.setEnabled(v);
                    }),
                    title: Text('فتح وضع السيارة تلقائياً مع بلوتوث السيارة', style: tx(14, c: Colors.white)),
                    subtitle: Text(cars.isEmpty ? 'أول ما تتصل ببلوتوث سيارتك نسألك عنه' : 'السيارات المحفوظة:', style: tx(12, c: Colors.white54)),
                  ),
                  if (cars.isNotEmpty)
                    wrap([
                      for (final n in [...cars])
                        chip(n, true, () {
                          CarAuto.forget(n);
                          cars.remove(n);
                        }, icon: '✕'),
                    ]),
                  const SizedBox(height: 8),
                  Text('Android Auto: افتح منبر من شاشة السيارة لتصفح المفضلة والإصدارات والتحكم بالتشغيل.', style: tx(12, c: Colors.white54, h: 1.6)),
                ]),
                card(Ic.eq, 'الرحلة الحالية', [
                  Row(children: [stat(gps ? '${(_dist / 1000).toStringAsFixed(1)}' : '—', 'كم'), stat(_dur(total), 'المدة'), stat('${_heard.length}', 'قصائد')]),
                  const SizedBox(height: 6),
                  Row(children: [stat(gps ? '${avg.round()}' : '—', 'المعدل'), stat(gps ? '${(_maxV * 3.6).round()}' : '—', 'الأعلى'), stat(gps ? _dur(_moveSec) : '—', 'الحركة')]),
                  if (lastTrip != null) ...[label('آخر رحلة'), Text(lastTrip, style: tx(13, c: Colors.white70))],
                ]),
                // للمشرف فقط: فحص المشهد والمعاينة
                if (_adm)
                  card(Ic.gear, 'فحص المشهد', admin: true, note: 'المكتشفة: $detected', [
                    label('المنطقة'),
                    wrap([
                      for (final e in _biomeNames.entries)
                        chip(e.value, _bMode == e.key, () {
                          _bMode = e.key;
                          save('car.biome', e.key);
                          _applyBiome();
                        }),
                    ]),
                    label('الوقت'),
                    wrap([
                      for (int i = 0; i < 4; i++)
                        chip(const ['تلقائي', 'نهار', 'غروب', 'ليل'][i], _tMode == i, () {
                          _tMode = i;
                          save('car.tm', i);
                          _env();
                        }, icon: const ['🕒', '☀', '🌇', '🌙'][i]),
                    ]),
                    label('الطقس'),
                    wrap([
                      for (int i = 0; i < _presets.length; i++)
                        chip(i == 0 ? 'الحقيقي' : _presets[i]!.label, _wMode == i, () {
                          _wMode = i;
                          save('car.wx', i);
                        }, icon: i == 0 ? '📡' : _presets[i]!.icon(false)),
                    ]),
                    label('معاينة السيارة'),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(height: 170, color: const Color(0xFF0B1F19), child: CustomPaint(painter: _CarPreview(_sc.model, _sc.color), size: Size.infinite)),
                    ),
                  ]),
              ]),
            ),
          ),
        );
      }),
    );
    _tk.muted = false;
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
    final t = w.temp.isNaN ? '' : '${w.temp.round()}° ';
    final place = _region?.place ?? (_hasPos ? 'جارِ تحديد المنطقة…' : 'حدّد موقعك');
    final sub = _region?.sub ?? '';
    Widget roundBtn(Widget child, {VoidCallback? onTap, VoidCallback? onLong, String? sem}) => Semantics(
          label: sem,
          button: true,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLong,
            child: Container(width: 42, height: 42, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1FFFFFFF)), child: child),
          ),
        );
    Widget div() => Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 8), color: const Color(0x26FFFFFF));
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0x8C000000), Color(0x66000000)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Row(children: [
          roundBtn(const PIcon(Ic.x, color: Colors.white, size: 22), onTap: () => _say('اضغط مطولاً على ✕ للخروج'), onLong: () {
            HapticFeedback.heavyImpact();
            _exit();
          }),
          div(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!gps) _gpsOn();
                _geo(force: true);
              },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📍 $place${sub.isEmpty ? '' : ' · $sub'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14, c: Colors.white, h: 1.25)),
                Text('${w.icon(night)} $t${w.label}${_wM == 0 ? '' : ' (معاينة)'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: Colors.white70, h: 1.3)),
              ]),
            ),
          ),
          div(),
          ValueListenableBuilder<DateTime>(
            valueListenable: _clock,
            builder: (_, d, __) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text('${_two(d.hour)}:${_two(d.minute)}', style: tx(21, c: Colors.white).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
          const SizedBox(width: 8),
          roundBtn(const PIcon(Ic.more, color: Colors.white, size: 20), onTap: _settings, sem: 'إعدادات السيارة'),
        ]),
      ),
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

  /// العنوان والصورة: فوق الكلمات إذا موجودة، وينزلون لتحت إذا اللطمية بلا كلمات (بدون ما يتحرك المشهد)
  Widget _titleBlock(Track? t, List<Lyric> lines, double base, {double? height}) {
    final has = lines.isNotEmpty;
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (_, c) {
        final hh = c.maxHeight.isFinite ? c.maxHeight : 120.0;
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            top: has ? 0 : hh - 58,
            height: 58,
            child: _titleRow(t),
          ),
          Positioned(left: 0, right: 0, top: 58, bottom: 0, child: AnimatedOpacity(opacity: has ? 1 : 0, duration: const Duration(milliseconds: 300), child: has ? LyricStrip(lines: lines, base: base) : const SizedBox())),
        ]);
      }),
    );
  }

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

  Widget _miniMap(double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kGold, width: 2), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10)]),
          child: ClipOval(child: RepaintBoundary(child: CustomPaint(painter: _MapPainter(this, _mapTick), size: Size(size, size)))),
        ),
      );

  Widget _navStrip(double w) => ValueListenableBuilder<_NavInfo?>(
        valueListenable: _nav,
        builder: (_, n, __) => n == null
            ? const SizedBox.shrink()
            : IgnorePointer(
                child: Container(
                  width: w,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x26FFFFFF))),
                  child: Row(children: [
                    Text(n.from, style: tx(11.5, c: Colors.white70)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(alignment: Alignment.center, children: [
                        Container(height: 3, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(2))),
                        Align(alignment: AlignmentDirectional.centerStart, child: FractionallySizedBox(widthFactor: n.frac.clamp(0.02, 1.0), child: Container(height: 3, decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(2))))),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text('${n.to} · ${n.km < 10 ? n.km.toStringAsFixed(1) : n.km.round()} كم', style: tx(11.5, c: Colors.white)),
                  ]),
                ),
              ),
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
              final hz = math.max(h * 0.36, top + 66 + g * 0.7 + 4), carY = h - pad.bottom - h * 0.05, cw = math.min(sw * 0.36, (carY - hz) * 0.85);
              return Stack(children: [
                Positioned.fill(child: _scene(_Stage(hz, sw * 0.5, carY, cw, dpr))),
                Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: pw + 40,
                    child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0x00000000), Color(0xB3000000), Color(0xD9000000)], stops: [0, 0.25, 1]))))),
                Positioned(left: 0, width: sw, top: 0, bottom: 0, child: _overlays(carY - cw * 0.4)),
                Positioned(top: top + 66, left: sw * 0.5 - g / 2, child: _speedo(g)),
                if (_mapOn && sw * 0.5 - g / 2 - 16 >= 62) Positioned(top: top + 66, left: 8, child: _miniMap(math.min(90.0, sw * 0.5 - g / 2 - 16))),
                if (_mapOn) Positioned(left: 0, width: sw, top: hz + 44, child: Center(child: _navStrip(math.min(sw * 0.84, 330.0)))),
                Positioned(top: top - 4, left: 0, right: 0, child: _topBar()),
                Positioned(left: 0, width: sw, top: hz + 8, child: _bannerW()),
                Positioned(
                  right: 12 + pad.right,
                  width: pw - 12,
                  top: top + 50,
                  bottom: pad.bottom + 8,
                  child: Column(children: [
                    Expanded(child: _titleBlock(t, ly, 20)),
                    _progress(),
                    _controls(t, u),
                  ]),
                ),
              ]);
            }
            final u = _cl(w * 0.19, 58, 88), lyH = _cl(h * 0.1, 54, 96);
            final panel = 58 + lyH + 30 + u * 1.3 + u * 0.16 + u * 0.64 + 14 + pad.bottom;
            final g = _cl(math.min(w * 0.44, h * 0.2), 100, 200);
            final hz = math.max(h * 0.3, top + 66 + g * 0.7 + 6), carY = h - panel - 4;
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
              Positioned(top: top + 66, left: (w - g) / 2, child: _speedo(g)),
              if (_mapOn && (w - g) / 2 - 16 >= 62) Positioned(top: top + 66, left: 8, child: _miniMap(math.min(90.0, (w - g) / 2 - 16))),
              if (_mapOn) Positioned(left: 0, right: 0, top: hz + 44, child: Center(child: _navStrip(math.min(w * 0.84, 330.0)))),
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
                    _titleBlock(t, ly, 22, height: 58.0 + lyH),
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
