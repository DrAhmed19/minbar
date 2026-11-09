import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'state.dart';
import 'viz.dart';

/// منبر — التصاميم التفاعلية (أجهزة وآلات) منقولة من plrdev.js
/// تُرسم بإطار افتراضي ارتفاعه 320 وتتحكم بالتشغيل باللمس
const kDevIds = {'wring', 'cassette', 'jog', 'reels', 'knob', 'speaker', 'scope', 'pond', 'dots', 'card', 'silk'};

class Kc {
  double p = 0, dur = 0, speed = 1, vol = 1;
  bool playing = false;
  String title = '', sub = '';
  List<double> peaks = const [];
}

final kc = Kc();

/// التمرير بالدوران (مثل الويب: زاوية ÷ السرعة الطبيعية = ثوانٍ)
class Scrub {
  static double nat = 1.15, acc = 0;
  static int _last = 0;
  static void begin(double n) {
    nat = n;
    acc = 0;
  }

  static void turn(double d) {
    acc += d / nat * kc.speed;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _last > 60 && acc.abs() > 0.02) {
      _last = now;
      final pl = app.player.p;
      final t = (pl.position.inMilliseconds / 1000.0 + acc).clamp(0.0, kc.dur > 0 ? kc.dur - 0.2 : 0.0);
      acc = 0;
      app.player.seek(t);
    }
  }
}

double _cl(double a, double b, double c) => math.max(b, math.min(c, a));

class DevS {
  final Map<String, dynamic> m = {'t': 0.0, 'dt': 0.016};
  double g(String k, [double d = 0]) => (m[k] as num?)?.toDouble() ?? d;
  void set(String k, dynamic v) => m[k] = v;
  // تحويل الإطار
  double k = 1, ox = 0, oy = 0;
  List<_Dot>? dots;
  ui.Image? dotSrc;
  bool dotBusy = false;
}

class _Dot {
  final double u, v, l;
  final Color c;
  double x = 0, y = 0, vx = 0, vy = 0, r;
  _Dot(this.u, this.v, this.c, this.l, this.r);
}

final Map<String, DevS> devStates = {};
DevS devState(String id, bool thumb) => devStates.putIfAbsent(id + (thumb ? '_t' : ''), () => DevS()..m['t'] = thumb ? 1.2 : 0.0);

Future<void> _prepDots(DevS s, ui.Image img, int n) async {
  if (s.dotBusy) return;
  s.dotBusy = true;
  try {
    final rec = ui.PictureRecorder();
    final iw = img.width.toDouble(), ih = img.height.toDouble(), q = math.min(iw, ih);
    Canvas(rec).drawImageRect(img, Rect.fromLTWH((iw - q) / 2, (ih - q) / 2, q, q), Rect.fromLTWH(0, 0, n.toDouble(), n.toDouble()), Paint());
    final sm = await rec.endRecording().toImage(n, n);
    final bd = await sm.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd != null) {
      final rnd = math.Random();
      final pts = <_Dot>[];
      for (var j = 0; j < n; j++) {
        for (var i = 0; i < n; i++) {
          final k = (j * n + i) * 4;
          final r = bd.getUint8(k), gg = bd.getUint8(k + 1), b = bd.getUint8(k + 2);
          pts.add(_Dot(i / (n - 1) * 2 - 1, j / (n - 1) * 2 - 1, Color.fromARGB(255, r, gg, b), (r * 0.3 + gg * 0.59 + b * 0.11) / 255, rnd.nextDouble() * tau));
        }
      }
      s.dots = pts;
      s.dotSrc = img;
    }
  } catch (_) {}
  s.dotBusy = false;
}

class DevPainter extends CustomPainter {
  final String id;
  final VizF F;
  final DevS s;
  final ui.Image? img;
  final bool thumb;
  DevPainter(this.id, this.F, this.s, this.img, this.thumb);

  static const G = Color(0xFFE8C468), G2 = Color(0xFFF3D88A);
  late Canvas x;

  Paint fill(Color c) => Paint()..color = c;
  Paint stroke(Color c, double w, {StrokeCap cap = StrokeCap.butt}) => Paint()
    ..style = PaintingStyle.stroke
    ..color = c
    ..strokeWidth = w
    ..strokeCap = cap
    ..strokeJoin = StrokeJoin.round;
  RRect rr(double a, double b, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(a, b, w, h), Radius.circular(math.max(0.0, r)));
  Color ga(double a) => G.withOpacity(_cl(a, 0, 1));
  Color wa(double a) => Colors.white.withOpacity(_cl(a, 0, 1));
  Color rgba(int r, int g, int b, double a) => Color.fromRGBO(r, g, b, _cl(a, 0, 1));

  void glow(double cx, double cy, double r0, double r1, double a) {
    x.drawCircle(Offset(cx, cy), r1, Paint()..shader = ui.Gradient.radial(Offset(cx, cy), r1, [ga(a), ga(0)], [r1 > 0 ? _cl(r0 / r1, 0, 1) : 0, 1]));
  }

  void cov(double cx, double cy, double r, String sh) {
    final dst = Rect.fromLTWH(cx - r, cy - r, 2 * r, 2 * r);
    final p = Path();
    sh == 'c' ? p.addOval(dst) : p.addRRect(RRect.fromRectAndRadius(dst, Radius.circular(r * 0.14)));
    x.save();
    x.clipPath(p);
    if (img != null) {
      final iw = img!.width.toDouble(), ih = img!.height.toDouble(), q = math.min(iw, ih);
      x.drawImageRect(img!, Rect.fromLTWH((iw - q) / 2, (ih - q) / 2, q, q), dst, Paint()..filterQuality = FilterQuality.medium);
    } else {
      x.drawRect(dst, Paint()..shader = ui.Gradient.radial(Offset(cx, cy - r * 0.2), r * 1.4, const [Color(0xFF13755A), Color(0xFF04241B)]));
    }
    x.restore();
  }

  void imgRect(Rect src01, Rect dst, {double alpha = 1}) {
    if (img == null) return;
    final iw = img!.width.toDouble(), ih = img!.height.toDouble(), q = math.min(iw, ih), ox = (iw - q) / 2, oy = (ih - q) / 2;
    x.drawImageRect(img!, Rect.fromLTWH(ox + src01.left * q, oy + src01.top * q, src01.width * q, src01.height * q), dst, Paint()..color = Colors.white.withOpacity(_cl(alpha, 0, 1)));
  }

  void text(String t, double cx, double y, double size, Color c, {String al = 'c', FontWeight w = FontWeight.w400}) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontFamily: 'Cairo', fontFamilyFallback: const ['CairoLatin'], fontSize: size, color: c, fontWeight: w)), textDirection: TextDirection.rtl, maxLines: 1)..layout();
    final dx = al == 'c' ? cx - tp.width / 2 : (al == 'r' ? cx - tp.width : cx);
    tp.paint(x, Offset(dx, y - tp.height * 0.78));
  }

  String tfmt(double v) {
    final q = math.max(0, v.floor());
    return '${(q ~/ 60).toString().padLeft(2, '0')}:${(q % 60).toString().padLeft(2, '0')}';
  }

  List<double> peaksOf(int n) {
    final e = kc.peaks, o = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      o[i] = e.isNotEmpty ? 0.15 + 0.85 * e[(i / n * e.length).floor()] : 0.25 + 0.75 * (math.sin(i * 0.31) * math.sin(i * 0.07 + 1)).abs();
    }
    return o;
  }

  double v24(int i) {
    final v = F.vals, m = v.length;
    final f = (i % 24) / 23 * (m - 1), a = f.floor(), b = math.min(m - 1, a + 1);
    return _cl(v[a] + (v[b] - v[a]) * (f - a), 0, 1);
  }

  List<double> get wave {
    final w = F.wave;
    var mx = 0.0;
    for (final q in w) {
      mx = math.max(mx, q.abs());
    }
    final k = mx > 0.002 ? math.min(6.0, 0.85 / mx) * _cl(F.vol * 1.4, 0.15, 1) : 0.0;
    return [for (final q in w) q * k];
  }

  @override
  void paint(Canvas canvas, Size size) {
    x = canvas;
    final k = size.height * 0.94 / 320, wv = math.min(size.width / k, 420.0);
    s.k = k;
    s.ox = size.width / 2 - wv * k / 2;
    s.oy = size.height / 2 - 160 * k;
    if (!thumb) s.m['t'] = s.g('t') + s.g('dt', 0.016);
    x.save();
    x.translate(s.ox, s.oy);
    x.scale(k);
    final W = wv;
    const H = 320.0;
    switch (id) {
      case 'cassette':
        _cassette(W, H);
      case 'jog':
        _jog(W, H);
      case 'reels':
        _reels(W, H);
      case 'wring':
        _wring(W, H);
      case 'knob':
        _knob(W, H);
      case 'speaker':
        _speaker(W, H);
      case 'scope':
        _scope(W, H);
      case 'pond':
        _pond(W, H);
      case 'dots':
        _dots(W, H);
      case 'card':
        _card(W, H);
      case 'silk':
        _silk(W, H);
    }
    x.restore();
  }

  // ============ الكاسيت ============
  void _cassette(double W, double H) {
    final bw = math.min(W * 0.86, 330.0), bh = bw * 0.62, bx = (W - bw) / 2, by = (H - bh) / 2, p = kc.p;
    if (s.m['drag'] == null) s.m['a'] = s.g('a') + s.g('dt') * 2.4 * (kc.playing ? kc.speed : 0);
    x.drawRRect(rr(bx + 4, by + 8, bw, bh, 14), fill(const Color(0x59000000)));
    x.drawRRect(rr(bx, by, bw, bh, 14), Paint()..shader = ui.Gradient.linear(Offset(0, by), Offset(0, by + bh), const [Color(0xFF2B2F33), Color(0xFF16191B)]));
    x.drawRRect(rr(bx, by, bw, bh, 14), stroke(wa(0.12), 1));
    final lx = bx + bw * 0.06, ly = by + bh * 0.08, lw = bw * 0.88, lh = bh * 0.62;
    x.save();
    x.clipRRect(rr(lx, ly, lw, lh, 8));
    if (img != null) {
      imgRect(const Rect.fromLTWH(0, 0, 1, 1), Rect.fromLTWH(lx, ly - lw * 0.3, lw, lw));
    } else {
      x.drawRect(Rect.fromLTWH(lx, ly, lw, lh), fill(const Color(0xFF0E5C46)));
    }
    x.drawRect(Rect.fromLTWH(lx, ly, lw, lh), Paint()..shader = ui.Gradient.linear(Offset(0, ly), Offset(0, ly + lh), const [Color(0x0D000000), Color(0x99000000)]));
    x.restore();
    text(kc.title.length > 26 ? kc.title.substring(0, 26) : kc.title, lx + lw - 10, ly + lh * 0.22, bw * 0.05, Colors.white, al: 'r', w: FontWeight.w700);
    text(kc.sub.length > 30 ? kc.sub.substring(0, 30) : kc.sub, lx + lw - 10, ly + lh * 0.36, bw * 0.035, wa(0.75), al: 'r');
    final wx = bx + bw * 0.24, wy = by + bh * 0.38, ww = bw * 0.52, wh = bh * 0.26;
    x.drawRRect(rr(wx, wy, ww, wh, wh / 2), fill(const Color(0xFF0B0C0D)));
    final rA = Offset(bx + bw * 0.335, wy + wh / 2), rB = Offset(bx + bw * 0.665, wy + wh / 2), mx = wh * 0.95, mn = wh * 0.32, ra = mn + (mx - mn) * (1 - p), rb = mn + (mx - mn) * p;
    x.save();
    x.clipRRect(rr(wx, wy, ww, wh, wh / 2));
    for (final (c, r) in [(rA, ra), (rB, rb)]) {
      x.drawCircle(c, r, fill(const Color(0xFF3A2A1A)));
      for (var q = mn; q < r; q += 2) {
        x.drawCircle(c, q, stroke(const Color(0x1FFFDCAA), 1));
      }
    }
    x.restore();
    for (var j = 0; j < 2; j++) {
      final c = j == 0 ? rA : rB;
      x.save();
      x.translate(c.dx, c.dy);
      x.rotate(s.g('a') * (j == 1 ? (0.6 + p) : (1.6 - p)));
      x.drawCircle(Offset.zero, wh * 0.3, fill(const Color(0xFFF4F1EA)));
      for (var k = 0; k < 6; k++) {
        x.rotate(tau / 6);
        x.drawRect(Rect.fromLTWH(-wh * 0.035, wh * 0.13, wh * 0.07, wh * 0.12), fill(const Color(0xFF16191B)));
      }
      x.drawCircle(Offset.zero, wh * 0.11, fill(const Color(0xFF16191B)));
      x.restore();
    }
    for (var i = 0; i < 10; i++) {
      final v = v24(i * 2);
      x.drawRect(Rect.fromLTWH(bx + bw * 0.3 + i * bw * 0.04, by + bh * 0.84, bw * 0.03, bh * 0.05), fill(i < 7 ? rgba(127, 224, 181, 0.2 + v * 0.8) : rgba(232, 96, 80, 0.2 + v * 0.8)));
    }
    for (final q in [0.12, 0.88]) {
      x.drawCircle(Offset(bx + bw * q, by + bh * 0.88), bh * 0.04, fill(const Color(0xFF24282B)));
    }
    s.m['geo'] = [rA, rB, mx, bx, by, bw, bh];
  }

  // ============ عجلة الدوران ============
  void _jog(double W, double H) {
    final R = math.min(W, H) * 0.4, cx = W * 0.46, cy = H / 2, p = kc.p;
    if (s.m['drag'] == null) s.m['a'] = s.g('a') + s.g('dt') * 1.2 * (kc.playing ? kc.speed : 0);
    x.drawCircle(Offset(cx + 3, cy + 7), R * 1.08, fill(const Color(0x66000000)));
    x.drawCircle(Offset(cx, cy), R * 1.08, Paint()..shader = ui.Gradient.radial(Offset(cx - R * 0.3, cy - R * 0.4), R * 1.08, const [Color(0xFF3A3F44), Color(0xFF111315)], const [0.18, 1]));
    const n = 64;
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i / n * tau, on = i / n < p, v = v24(i);
      x.drawCircle(Offset(cx + math.cos(a) * R, cy + math.sin(a) * R), R * 0.022, fill(on ? ga(0.55 + v * 0.45) : wa(0.07 + F.beat * 0.08)));
    }
    x.save();
    x.translate(cx, cy);
    x.rotate(s.g('a'));
    x.drawCircle(Offset.zero, R * 0.92, Paint()..shader = ui.Gradient.radial(Offset.zero, R * 0.92, const [Color(0xFF2A2E31), Color(0xFF1A1D1F)], const [0.65, 1]));
    for (var i = 0; i < 48; i++) {
      x.rotate(tau / 48);
      x.drawRect(Rect.fromLTWH(R * 0.74, -R * 0.012, R * 0.15, R * 0.024), fill(wa(0.06)));
    }
    cov(0, 0, R * 0.62, 'c');
    x.drawRect(Rect.fromLTWH(-1.5, -R * 0.62, 3, R * 0.12), fill(Colors.white));
    x.restore();
    x.drawCircle(Offset(cx, cy), R * 0.62, stroke(G, 2));
    final sx = W * 0.9, sy0 = cy - R * 0.8, sh = R * 1.6, sp = (2 - kc.speed) / 1.5;
    x.drawRRect(rr(sx - 6, sy0, 12, sh, 6), fill(const Color(0xFF0D0F10)));
    for (var i = 0; i <= 6; i++) {
      x.drawRect(Rect.fromLTWH(sx - 14, sy0 + i * sh / 6, 5, 1), fill(wa(0.25)));
    }
    x.drawRRect(rr(sx - 14, sy0 + sp * sh - 8, 28, 16, 4), fill(const Color(0xFFD9DDE0)));
    x.drawRect(Rect.fromLTWH(sx - 14, sy0 + sp * sh - 1, 28, 2), fill(G));
    text('×${kc.speed.toStringAsFixed(2)}', sx, sy0 - 8, 11, wa(0.7));
    s.m['geo'] = [cx, cy, R, sx, sy0, sh];
  }

  // ============ جهاز البكرات ============
  void _reels(double W, double H) {
    final cxA = W * 0.3, cxB = W * 0.7, cy = H * 0.38, R = math.min(W * 0.19, H * 0.28), p = kc.p;
    if (s.m['drag'] == null) s.m['a'] = s.g('a') + s.g('dt') * 1.6 * (kc.playing ? kc.speed : 0);
    x.drawRRect(rr(W * 0.06, H * 0.06, W * 0.88, H * 0.88, 18), fill(const Color(0xFF1B1E20)));
    x.drawRRect(rr(W * 0.06, H * 0.06, W * 0.88, H * 0.88, 18), stroke(wa(0.08), 1));
    x.drawPath(
        Path()
          ..moveTo(cxA - R * 0.2, cy + R * 0.95)
          ..lineTo(W / 2, cy + R * 1.25)
          ..lineTo(cxB + R * 0.2, cy + R * 0.95),
        stroke(const Color(0xFF5A4428), 3));
    x.drawRRect(rr(W / 2 - 18, cy + R * 1.15, 36, 14, 4), fill(const Color(0xFF8C9196)));
    for (var j = 0; j < 2; j++) {
      final c = j == 0 ? cxA : cxB, am = j == 0 ? 1 - p : p;
      x.save();
      x.translate(c, cy);
      x.rotate(s.g('a') * (j == 1 ? 1 : 1.3));
      x.drawCircle(Offset.zero, R * (0.3 + 0.62 * am), fill(const Color(0xFF4B3620)));
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: R));
      for (var k = 0; k < 3; k++) {
        final a0 = k * tau / 3 + 0.35;
        path.moveTo(math.cos(a0) * R * 0.85, math.sin(a0) * R * 0.85);
        path.arcTo(Rect.fromCircle(center: Offset.zero, radius: R * 0.85), a0, 1.3, false);
        path.arcTo(Rect.fromCircle(center: Offset.zero, radius: R * 0.4), a0 + 1.3, -1.3, false);
        path.close();
      }
      x.drawPath(path, Paint()..shader = ui.Gradient.radial(Offset(-R * 0.3, -R * 0.3), R, const [Color(0x8CE6EAEC), Color(0x598C9296)]));
      x.drawCircle(Offset.zero, R, stroke(const Color(0xFFC9CED2), 2));
      cov(0, 0, R * 0.33, 'c');
      x.restore();
      x.drawCircle(Offset(c, cy), R * 0.33, stroke(G, 2));
      x.drawCircle(Offset(c, cy), R * 0.05, fill(const Color(0xFFD6DADD)));
    }
    for (var j = 0; j < 2; j++) {
      final mx = j == 0 ? W * 0.3 : W * 0.7, v = v24(j == 0 ? 2 : 8);
      final nk = 'n$j';
      s.m[nk] = s.g(nk) + (v - s.g(nk)) * 0.2;
      final my = H * 0.82, mw = W * 0.26, mh = H * 0.14;
      x.drawRRect(rr(mx - mw / 2, my - mh / 2, mw, mh, 6), fill(const Color(0xFFEFE3C2)));
      final arcR = Rect.fromCircle(center: Offset(mx, my + mh * 0.55), radius: mh * 0.85);
      x.drawArc(arcR, -math.pi * 0.8, math.pi * 0.6, false, stroke(const Color(0xFF6B5A3A), 1));
      x.drawArc(arcR, -math.pi * 0.33, math.pi * 0.13, false, stroke(const Color(0xFFB8352F), 1));
      final a = -math.pi * 0.8 + math.pi * 0.6 * s.g(nk);
      x.drawLine(Offset(mx, my + mh * 0.55), Offset(mx + math.cos(a) * mh * 0.95, my + mh * 0.55 + math.sin(a) * mh * 0.95), stroke(const Color(0xFF222222), 1.5));
      text('VU', mx, my + mh * 0.3, 9, const Color(0xFF6B5A3A));
    }
    s.m['geo'] = [cxA, cxB, cy, R];
  }

  // ============ حلقة الموجة ============
  void _wring(double W, double H) {
    final cx = W / 2, cy = H / 2, R = math.min(W, H) * 0.27, p = s.m['drag'] == true ? s.g('p') : kc.p;
    glow(cx, cy, R * 0.5, R * 1.8, 0.08 + F.bass * 0.18);
    const n = 180;
    if (s.m['pk'] == null || s.g('t') - s.g('pkt') > 3) {
      s.m['pk'] = peaksOf(n);
      s.m['pkt'] = s.g('t');
    }
    final pk = s.m['pk'] as List<double>;
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i / n * tau, on = i / n <= p, h = R * (0.12 + pk[i] * 0.38) * (on && (i / n - p).abs() < 0.03 ? 1 + F.beat * 0.4 : 1);
      x.drawLine(Offset(cx + math.cos(a) * R * 1.12, cy + math.sin(a) * R * 1.12), Offset(cx + math.cos(a) * (R * 1.12 + h), cy + math.sin(a) * (R * 1.12 + h)), stroke(on ? G : wa(0.18), math.max(1.5, R * tau / n * 0.55), cap: StrokeCap.round));
    }
    final tr = R * 1.0, tw = R * 0.075;
    x.drawCircle(Offset(cx, cy), tr, stroke(wa(0.12), tw));
    x.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: tr), -math.pi / 2, math.max(0.001, p) * tau, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tw
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(Offset(cx - tr, cy - tr), Offset(cx + tr, cy + tr), const [Color(0xFFF3D88A), Color(0xFFC99A3C)]));
    cov(cx, cy, R * 0.9 * (1 + F.bass * 0.02), 'c');
    x.drawCircle(Offset(cx, cy), R * 0.9, stroke(ga(0.5), 1.2));
    final a = -math.pi / 2 + p * tau, kx = cx + math.cos(a) * tr, ky = cy + math.sin(a) * tr;
    glow(kx, ky, 0, R * 0.3, 0.75);
    x.drawCircle(Offset(kx, ky), tw * (s.m['drag'] == true ? 1.15 : 0.85), fill(G2));
    x.drawCircle(Offset(kx, ky), tw * 0.35, fill(Colors.white));
    if (s.m['drag'] == true) {
      x.drawRRect(rr(cx - 36, cy - 14, 72, 28, 14), fill(const Color(0x8C000000)));
      text(tfmt(p * kc.dur), cx, cy + 6, 14, Colors.white, w: FontWeight.w600);
    }
    s.m['geo'] = [cx, cy, R];
  }

  // ============ مقبض الصوت ============
  void _knob(double W, double H) {
    final cx = W / 2, cy = H / 2, R = math.min(W, H) * 0.32, v = kc.vol, a0 = math.pi * 0.75, a1 = math.pi * 2.25, lvl = kc.playing ? _cl(F.vol * 1.25, 0, 1) : 0.0;
    const n = 31;
    for (var i = 0; i < n; i++) {
      final f = i / (n - 1), a = a0 + (a1 - a0) * f, lit = f <= v, lv = f <= v * lvl;
      x.drawCircle(Offset(cx + math.cos(a) * R * 1.25, cy + math.sin(a) * R * 1.25), R * 0.035, fill(lv ? (f > 0.85 ? const Color(0xFFE8604F) : G) : (lit ? ga(0.3) : wa(0.08))));
    }
    x.drawCircle(Offset(cx + 4, cy + 9), R * 1.05, fill(const Color(0x73000000)));
    x.drawCircle(Offset(cx, cy), R * 1.05, Paint()..shader = ui.Gradient.linear(Offset(cx - R, cy - R), Offset(cx + R, cy + R), const [Color(0xFFE9ECEE), Color(0xFF8D9397), Color(0xFF3D4245)], const [0, 0.5, 1]));
    for (var i = 0; i < 90; i++) {
      final a = i / 90 * tau;
      x.drawLine(Offset(cx + math.cos(a) * R * 0.92, cy + math.sin(a) * R * 0.92), Offset(cx + math.cos(a) * R * 1.05, cy + math.sin(a) * R * 1.05), stroke(const Color(0x2E000000), 1));
    }
    cov(cx, cy, R * 0.88, 'c');
    x.drawCircle(Offset(cx, cy), R * 0.88, Paint()..shader = ui.Gradient.linear(Offset(cx, cy - R), Offset(cx, cy + R), const [Color(0x38FFFFFF), Color(0x00FFFFFF), Color(0x4D000000)], const [0, 0.5, 1]));
    final a = a0 + (a1 - a0) * v;
    x.drawCircle(Offset(cx + math.cos(a) * R * 0.97, cy + math.sin(a) * R * 0.97), R * 0.045, fill(G2));
    text('${(v * 100).round()}%', cx, cy + R * 1.5, 13, wa(0.75), w: FontWeight.w600);
    s.m['geo'] = [cx, cy, R];
  }

  // ============ السمّاعة ============
  void _speaker(double W, double H) {
    final cx = W / 2, cy = H / 2, R = math.min(W, H) * 0.4;
    s.m['k'] = s.g('k') * 0.85;
    final push = F.bass * 0.06 + s.g('k') * 0.08;
    x.drawCircle(Offset(cx, cy), R * 1.05, Paint()..shader = ui.Gradient.linear(Offset(0, cy - R), Offset(0, cy + R), const [Color(0xFF2B2F32), Color(0xFF0E1011)]));
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * tau + 0.4;
      x.drawCircle(Offset(cx + math.cos(a) * R * 0.99, cy + math.sin(a) * R * 0.99), R * 0.02, fill(const Color(0xFF8D9397)));
    }
    final sr = R * 0.9 * (1 + push * 0.2);
    x.drawCircle(Offset(cx, cy), sr, Paint()..shader = ui.Gradient.radial(Offset(cx - R * 0.2, cy - R * 0.25), sr, const [Color(0xFF2A2D2F), Color(0xFF2A2D2F), Color(0xFF4A4F53), Color(0xFF151718)], const [0, 0.66, 0.85, 1]));
    final cr = R * 0.78;
    x.drawCircle(Offset(cx, cy), cr, Paint()..shader = ui.Gradient.radial(Offset(cx, cy), cr, const [Color(0xFF1C1F21), Color(0xFF0C0D0E)], [0.3 / 0.78, 1]));
    for (var r = R * 0.4; r < cr; r += 4) {
      x.drawCircle(Offset(cx, cy), r, stroke(wa(0.04), 1));
    }
    final dr = R * 0.42 * (1 + push * 1.4);
    x.drawCircle(Offset(cx, cy + R * 0.03), dr * 1.04, fill(const Color(0x80000000)));
    cov(cx, cy, dr, 'c');
    x.drawCircle(Offset(cx, cy), dr, Paint()..shader = ui.Gradient.radial(Offset(cx - dr * 0.4, cy - dr * 0.5), dr, const [Color(0x59FFFFFF), Color(0x00FFFFFF)], const [0, 0.6]));
    x.drawCircle(Offset(cx, cy), dr, stroke(ga(0.8), 2));
    s.m['geo'] = [cx, cy, R];
  }

  // ============ جهاز الذبذبات ============
  void _scope(double W, double H) {
    final m = (s.m['sm'] as int?) ?? 0, z = s.g('z', 0.5), b = s.g('b', 0.6);
    final dw = math.min(W * 0.94, 380.0), dh = math.min(H * 0.84, dw * 0.78), dx = (W - dw) / 2, dy = (H - dh) / 2;
    x.drawRRect(rr(dx + 4, dy + 8, dw, dh, 18), fill(const Color(0x66000000)));
    x.drawRRect(rr(dx, dy, dw, dh, 18), Paint()..shader = ui.Gradient.linear(Offset(0, dy), Offset(0, dy + dh), const [Color(0xFF5B625E), Color(0xFF2E3431)]));
    x.drawRRect(rr(dx + 0.5, dy + 0.5, dw - 1, dh - 1, 18), stroke(wa(0.15), 1));
    final sx = dx + dw * 0.05, sy = dy + dh * 0.08, sw = dw * 0.6, sh = dh * 0.84;
    x.drawRRect(rr(sx - 6, sy - 6, sw + 12, sh + 12, sw * 0.12), fill(const Color(0xFF1A1D1C)));
    x.save();
    x.clipRRect(rr(sx, sy, sw, sh, sw * 0.1));
    x.drawRect(Rect.fromLTWH(sx, sy, sw, sh), fill(const Color(0xFF03130D)));
    final pts = <Offset>[], wv = wave, n = wv.length;
    if (m == 0) {
      final span = (n * (0.25 + z * 0.75)).round();
      for (var i = 0; i < span; i++) {
        pts.add(Offset(sx + i / (span - 1) * sw, sy + sh / 2 + wv[i] * sh * 0.38));
      }
    } else if (m == 1) {
      final o = (n / 4).round();
      for (var i = 0; i < n; i++) {
        pts.add(Offset(sx + sw / 2 + wv[i] * sw * 0.36 * (0.6 + z * 0.6), sy + sh / 2 + wv[(i + o) % n] * sh * 0.4 * (0.6 + z * 0.6)));
      }
      pts.add(pts.first);
    } else {
      const mm = 24;
      for (var i = 0; i < mm; i++) {
        final v = v24(i), X = sx + (i + 0.5) / mm * sw;
        pts.addAll([Offset(X - sw / mm * 0.35, sy + sh * 0.92), Offset(X - sw / mm * 0.35, sy + sh * 0.92 - v * sh * 0.8), Offset(X + sw / mm * 0.35, sy + sh * 0.92 - v * sh * 0.8), Offset(X + sw / mm * 0.35, sy + sh * 0.92)]);
      }
    }
    final path = Path()..addPolygon(pts, false);
    final br = 0.7 + b * 0.6;
    x.drawPath(path, stroke(rgba(120, 255, 170, 0.25 * br), 9));
    x.drawPath(path, stroke(rgba(160, 255, 190, 0.55 * br), 4));
    x.drawPath(path, stroke(rgba(230, 255, 235, 0.95), 1.6));
    for (var i = 1; i < 8; i++) {
      x.drawLine(Offset(sx + i * sw / 8, sy), Offset(sx + i * sw / 8, sy + sh), stroke(const Color(0x247FE0B5), 1));
    }
    for (var i = 1; i < 6; i++) {
      x.drawLine(Offset(sx, sy + i * sh / 6), Offset(sx + sw, sy + i * sh / 6), stroke(const Color(0x247FE0B5), 1));
    }
    x.drawRect(Rect.fromLTWH(sx, sy, sw, sh), Paint()..shader = ui.Gradient.radial(Offset(sx + sw / 2, sy + sh / 2), sw * 0.75, const [Color(0x00000000), Color(0xB3000000)], [sh * 0.25 / (sw * 0.75), 1]));
    x.drawRect(Rect.fromLTWH(sx, sy, sw, sh), Paint()..shader = ui.Gradient.linear(Offset(sx, sy), Offset(sx + sw * 0.5, sy + sh * 0.5), const [Color(0x21FFFFFF), Color(0x00FFFFFF)], const [0, 0.6]));
    x.restore();
    text(['موجة', 'دائري', 'طيف'][m], sx + 8, sy + 16, 9, rgba(160, 255, 190, 0.7), al: 'l', w: FontWeight.w600);
    final px = dx + dw * 0.7, cs = dw * 0.25;
    x.drawRRect(rr(px - 3, sy - 3, cs + 6, cs + 6, 6), fill(const Color(0xFF1D211F)));
    imgRect(const Rect.fromLTWH(0, 0, 1, 1), Rect.fromLTWH(px, sy, cs, cs));
    x.drawRect(Rect.fromLTWH(px, sy, cs, cs), stroke(ga(0.6), 1));
    final kg = <List<double>>[];
    for (var j = 0; j < 2; j++) {
      final v = j == 0 ? z : b, lb = j == 0 ? 'زمن' : 'سطوع';
      final kx = px + cs / 2, ky = sy + cs + dh * 0.17 + j * dh * 0.24, kr = math.min(cs * 0.3, dh * 0.08);
      x.drawCircle(Offset(kx + 1, ky + 3), kr, fill(const Color(0x66000000)));
      x.drawCircle(Offset(kx, ky), kr, Paint()..shader = ui.Gradient.radial(Offset(kx - kr * 0.3, ky - kr * 0.4), kr, const [Color(0xFF5A5F5C), Color(0xFF141615)]));
      final a = math.pi * 0.75 + v * math.pi * 1.5;
      x.drawLine(Offset(kx + math.cos(a) * kr * 0.3, ky + math.sin(a) * kr * 0.3), Offset(kx + math.cos(a) * kr * 0.85, ky + math.sin(a) * kr * 0.85), stroke(Colors.white, 2));
      for (var i = 0; i <= 8; i++) {
        final bb = math.pi * 0.75 + i / 8 * math.pi * 1.5;
        x.drawCircle(Offset(kx + math.cos(bb) * kr * 1.3, ky + math.sin(bb) * kr * 1.3), 1, fill(wa(0.4)));
      }
      text(lb, kx, ky + kr * 1.75 + 4, 9, wa(0.65));
      kg.add([kx, ky, kr]);
    }
    x.drawCircle(Offset(dx + dw * 0.95, dy + dh * 0.93), 3, fill(kc.playing ? rgba(255, 80, 60, 0.6 + F.beat * 0.4) : const Color(0x99782820)));
    s.m['kg'] = kg;
    s.m['geo'] = [sx, sy, sw, sh, px, cs];
  }

  // ============ البركة ============
  void _pond(double W, double H) {
    final t = s.g('t');
    final R = math.min(W, H) * 0.24, cx = W / 2, wl = H * 0.62, cy = wl - R - 6 + math.sin(t * 1.4) * 3;
    final rip = (s.m['r'] as List<List<double>>?) ?? <List<double>>[];
    s.m['r'] = rip;
    if (F.beat > 0.8 && (s.m['lb'] == null || t - s.g('lb') > 0.3)) {
      rip.add([cx, wl + 6, t, 1]);
      s.m['lb'] = t;
    }
    rip.removeWhere((q) => t - q[2] >= 2.2);
    x.drawRect(Rect.fromLTWH(0, wl, W, H - wl), Paint()..shader = ui.Gradient.linear(Offset(0, wl), Offset(0, H), const [Color(0xE60A3A2D), Color(0x0002110C)]));
    x.save();
    x.clipRect(Rect.fromLTWH(0, wl, W, H - wl));
    for (var y = 0.0; y < R * 2; y += 3) {
      final off = math.sin(y * 0.12 - t * 3) * (2 + F.vol * 3);
      imgRect(Rect.fromLTWH(0, 1 - (y + 3) / (R * 2), 1, 3 / (R * 2)), Rect.fromLTWH(cx - R + off, wl + y + 4, R * 2, 3), alpha: 0.32 * (1 - y / (R * 2)));
    }
    for (final q in rip) {
      final p = (t - q[2]) / 2.2;
      for (var k = 0; k < 3; k++) {
        final pp = p - k * 0.08;
        if (pp < 0) continue;
        x.drawOval(Rect.fromCenter(center: Offset(q[0], q[1]), width: pp * W, height: pp * W * 0.18), stroke(rgba(243, 216, 138, (1 - pp) * 0.5 * q[3]), 1.5));
      }
    }
    x.restore();
    x.drawOval(Rect.fromCenter(center: Offset(cx, wl + 4), width: R * 1.8, height: R * 0.16), fill(const Color(0x66000000)));
    glow(cx, cy, R * 0.6, R * 1.6, 0.06 + F.bass * 0.15);
    cov(cx, cy, R, 'r');
    x.drawRRect(rr(cx - R, cy - R, 2 * R, 2 * R, R * 0.14), stroke(ga(0.6), 1.5));
    s.m['geo'] = [wl, cx, cy, R];
  }

  // ============ ذرّات الغلاف ============
  void _dots(double W, double H) {
    final R = math.min(W, H) * 0.4, cx = W / 2, cy = H / 2, pl = kc.playing, t = s.g('t'), dt = s.g('dt', 0.016);
    const n = 42;
    if (img != null && s.dotSrc != img) _prepDots(s, img!, n);
    final pts = s.dots;
    if (pts == null) {
      cov(cx, cy, R, 'r');
      return;
    }
    final rp = (s.m['rp'] as List<double>?) ?? <double>[];
    s.m['rp'] = rp;
    if (F.beat > 0.8 && pl && (s.m['lb'] == null || t - s.g('lb') > 0.3)) {
      rp.add(t);
      s.m['lb'] = t;
    }
    rp.removeWhere((q) => t - q >= 1.2);
    final cell = R * 2 / n;
    final tpx = s.m['px'] as double?, tpy = s.m['py'] as double?;
    for (final p in pts) {
      var tx = cx + p.u * R, ty = cy + p.v * R;
      final dd = math.sqrt((tx - cx) * (tx - cx) + (ty - cy) * (ty - cy));
      var sc = 1.0;
      for (final q in rp) {
        final fr = (t - q) * R * 1.6, e = dd - fr;
        if (e.abs() < R * 0.18) {
          final k = math.cos(e / (R * 0.18) * math.pi / 2) * (1 - (t - q) / 1.2);
          tx += (tx - cx) / (dd == 0 ? 1 : dd) * k * R * 0.05;
          sc += k * 0.6;
        }
      }
      if (!pl) {
        p.r += dt * 0.6;
        tx += math.cos(p.r + p.u * 3) * R * 0.5 * (1 + p.l);
        ty += math.sin(p.r * 1.3 + p.v * 3) * R * 0.4 - R * 0.2;
      }
      if (tpx != null && tpy != null) {
        final ex = tx - tpx, ey = ty - tpy, e = math.sqrt(ex * ex + ey * ey), lr = R * 0.35;
        if (e < lr) {
          final k = 1 - e / lr;
          tx += ex / (e == 0 ? 1 : e) * k * lr * 0.45;
          ty += ey / (e == 0 ? 1 : e) * k * lr * 0.45;
          sc += k * 1.4;
        }
      }
      if (p.x == 0) {
        p.x = tx;
        p.y = ty;
      }
      p.vx += (tx - p.x) * (pl ? 0.09 : 0.02);
      p.vy += (ty - p.y) * (pl ? 0.09 : 0.02);
      p.vx *= 0.8;
      p.vy *= 0.8;
      p.x += p.vx;
      p.y += p.vy;
      x.drawCircle(Offset(p.x, p.y), cell * 0.5 * (0.3 + p.l * 0.85) * sc * (pl ? 1 : 0.6), fill(p.c));
    }
    if (tpx != null && tpy != null) x.drawCircle(Offset(tpx, tpy), R * 0.35, stroke(ga(0.5), 1.2));
    s.m['geo'] = [cx, cy, R];
  }

  // ============ البطاقة الزجاجية ============
  void _card(double W, double H) {
    final t = s.g('t');
    final R = math.min(W * 0.3, H * 0.3), cx = W / 2, cy = H * 0.42;
    s.m['fa'] = s.g('fa') + ((s.m['fl'] == true ? math.pi : 0) - s.g('fa')) * 0.12;
    if (s.m['px'] == null) {
      s.m['tx'] = math.sin(t * 0.7) * 0.22;
      s.m['ty'] = math.cos(t * 0.5) * 0.12 - F.beat * 0.06;
    }
    s.m['ax'] = s.g('ax') + (s.g('tx') - s.g('ax')) * 0.12;
    s.m['ay'] = s.g('ay') + (s.g('ty') - s.g('ay')) * 0.12;
    final ry = s.g('ax') + s.g('fa'), rx = s.g('ay');
    final front = math.cos(ry) > 0;
    final m4 = Matrix4.identity()
      ..translate(cx, cy)
      ..setEntry(3, 2, 1 / (3.2 * R))
      ..rotateX(rx)
      ..rotateY(ry);
    // الظل
    x.drawRRect(rr(cx - R + 5, cy - R + 10, 2 * R, 2 * R, 6), Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    x.save();
    x.transform(m4.storage);
    final face = Rect.fromLTWH(-R, -R, 2 * R, 2 * R);
    if (front) {
      x.save();
      x.clipRRect(RRect.fromRectAndRadius(face, const Radius.circular(4)));
      if (img != null) {
        imgRect(const Rect.fromLTWH(0, 0, 1, 1), face);
      } else {
        x.drawRect(face, fill(const Color(0xFF0E5C46)));
      }
      final sp = ((t * 0.22) % 1.8) - 0.4 + s.g('ax') * 0.6;
      x.drawRect(
          face,
          Paint()
            ..shader = ui.Gradient.linear(face.topLeft, face.bottomRight, const [Color(0x00FFFFFF), Color(0x4DFFFFFF), Color(0x00FFFFFF)], [_cl(sp - 0.12, 0, 1), _cl(sp, 0, 1), _cl(sp + 0.12, 0, 1)]));
      x.restore();
    } else {
      x.scale(-1, 1);
      x.drawRect(face, fill(const Color(0xF2041410)));
      if (img != null) imgRect(const Rect.fromLTWH(0, 0, 1, 1), face, alpha: 0.18);
      text(kc.title.length > 22 ? kc.title.substring(0, 22) : kc.title, 0, -R + R * 0.7, R * 0.17, G, w: FontWeight.w700);
      text(kc.sub.length > 28 ? kc.sub.substring(0, 28) : kc.sub, 0, -R + R * 0.92, R * 0.11, wa(0.8));
      final pk = peaksOf(60);
      for (var i = 0; i < 60; i++) {
        final h = (8 + pk[i] * 50) * R / 160;
        final X = -R + (25 + i * 4.5) * R / 160;
        x.drawLine(Offset(X, R * 0.44 - h / 2), Offset(X, R * 0.44 + h / 2), stroke(G, 3 * R / 160));
      }
      text(tfmt(kc.dur), 0, R * 0.82, R * 0.09, wa(0.5));
    }
    x.drawRect(face, stroke(wa(0.45), 1));
    x.restore();
    s.m['geo'] = [cx, cy, R];
  }

  // ============ الحرير المضيء ============
  void _silk(double W, double H) {
    final t = s.g('t'), dt = s.g('dt', 0.016);
    final R = math.min(W, H) * 0.25, cx = W / 2, cy = H / 2 + math.sin(t * 1.1) * 3;
    s.m['fv'] = s.g('fv') * 0.92;
    s.m['ph'] = s.g('ph') + dt * (0.5 + F.vol * 0.4) * (kc.playing ? 1 : 0.25) + s.g('fv');
    const cols = [[232, 196, 104], [127, 224, 181], [255, 240, 210], [200, 160, 70], [90, 200, 150]];
    final tpx = s.m['px'] as double?, tpy = s.m['py'] as double?;
    final tops = <List<Offset>>[];
    void ribbon(int k, double al) {
      final c = cols[k % 5], amp = H * (0.08 + v24(k * 4) * 0.12), wid = H * (0.025 + v24(k * 4 + 1) * 0.05), ph = s.g('ph') * (1 + k * 0.2) + k * 1.7, yo = (k - 2) * H * 0.05;
      final top = <Offset>[], bot = <Offset>[], tws = <double>[];
      for (var i = 0; i <= 60; i++) {
        final f = i / 60, X = f * W;
        var Y = cy + yo + math.sin(f * 4.2 + ph) * amp * math.sin(f * math.pi) * 1.3;
        if (tpx != null && tpy != null) {
          final d = X - tpx;
          Y += (tpy - Y) * math.exp(-d * d / (W * W * 0.012)) * 0.55;
        }
        final tw = math.cos(f * 6 + ph * 1.4), w = wid * (0.15 + 0.85 * tw.abs());
        top.add(Offset(X, Y - w));
        bot.add(Offset(X, Y + w));
        tws.add(tw);
      }
      for (var i = 0; i < 60; i++) {
        final lum = 0.35 + 0.65 * tws[i].abs(), edge = math.sin(i / 60 * math.pi);
        final p = Path()
          ..moveTo(top[i].dx, top[i].dy)
          ..lineTo(top[i + 1].dx + 0.5, top[i + 1].dy)
          ..lineTo(bot[i + 1].dx + 0.5, bot[i + 1].dy)
          ..lineTo(bot[i].dx, bot[i].dy)
          ..close();
        x.drawPath(
            p,
            Paint()
              ..blendMode = BlendMode.plus
              ..color = rgba(c[0], c[1], c[2], al * lum * edge * (0.4 + v24(k * 4) * 0.6)));
      }
      tops.add(top);
    }

    for (var k = 0; k < 3; k++) {
      ribbon(k, 0.55);
    }
    glow(cx, cy, R * 0.6, R * 1.7, 0.06 + F.bass * 0.15);
    x.drawRRect(rr(cx - R + 6, cy - R + 12, 2 * R, 2 * R, R * 0.14), fill(const Color(0x66000000)));
    cov(cx, cy, R, 'r');
    x.drawRRect(rr(cx - R, cy - R, 2 * R, 2 * R, R * 0.14), stroke(ga(0.55), 1.2));
    for (var k = 3; k < 5; k++) {
      ribbon(k, 0.4);
    }
    final sp = (s.m['sp'] as List<List<double>>?) ?? <List<double>>[];
    s.m['sp'] = sp;
    final rnd = math.Random();
    if (F.beat > 0.7) {
      for (var i = 0; i < 2; i++) {
        final tp = tops[rnd.nextInt(tops.length)], pt = tp[rnd.nextInt(60)];
        sp.add([pt.dx, pt.dy, t]);
      }
    }
    sp.removeWhere((q) => t - q[2] >= 0.9);
    for (final q in sp) {
      final a = 1 - (t - q[2]) / 0.9, r = 2 + a * 3, qy = q[1] - (1 - a) * 10;
      final p = Path();
      for (var i = 0; i < 16; i++) {
        final an = i * math.pi / 8, rq = i % 2 == 1 ? r * 0.45 : r;
        i == 0 ? p.moveTo(q[0] + math.cos(an) * rq, qy + math.sin(an) * rq) : p.lineTo(q[0] + math.cos(an) * rq, qy + math.sin(an) * rq);
      }
      p.close();
      x.drawPath(p, fill(rgba(255, 245, 215, a)));
    }
    s.m['geo'] = [W, cx, cy, R];
  }

  @override
  bool shouldRepaint(covariant DevPainter o) => true;
}

/// اللمس على الأجهزة (نفس منطق down/move/up في الويب)
class DevTouch {
  static double _ang(DevS s, double px, double py, double cx, double cy) {
    final a = math.atan2(py - cy, px - cx);
    var d = a - s.g('la');
    if (d > math.pi) d -= tau;
    if (d < -math.pi) d += tau;
    s.m['la'] = a;
    return d;
  }

  static double _hyp(double a, double b) => math.sqrt(a * a + b * b);

  static bool down(String id, DevS s, Offset o) {
    final px = (o.dx - s.ox) / s.k, py = (o.dy - s.oy) / s.k;
    final q = s.m['geo'] as List?;
    if (q == null) return false;
    switch (id) {
      case 'cassette':
        {
          for (final c in [q[0] as Offset, q[1] as Offset]) {
            if (_hyp(px - c.dx, py - c.dy) < (q[2] as double) * 1.1) {
              s.m['drag'] = c;
              s.m['la'] = math.atan2(py - c.dy, px - c.dx);
              Scrub.begin(2.4);
              return true;
            }
          }
          if (px > q[3] && px < q[3] + q[5] && py > q[4] && py < q[4] + q[6]) {
            s.m['tap'] = true;
            return true;
          }
          return false;
        }
      case 'jog':
        {
          final cx = q[0] as double, cy = q[1] as double, R = q[2] as double, sx = q[3] as double, sy0 = q[4] as double, sh = q[5] as double;
          if ((px - sx).abs() < 24 && py > sy0 - 14 && py < sy0 + sh + 14) {
            s.m['sl'] = true;
            app.player.setSpeed(2 - _cl((py - sy0) / sh, 0, 1) * 1.5);
            return true;
          }
          if (_hyp(px - cx, py - cy) < R * 1.08) {
            s.m['drag'] = Offset(cx, cy);
            s.m['la'] = math.atan2(py - cy, px - cx);
            Scrub.begin(1.2);
            return true;
          }
          return false;
        }
      case 'reels':
        {
          final cy = q[2] as double, R = q[3] as double;
          for (final c in [q[0] as double, q[1] as double]) {
            if (_hyp(px - c, py - cy) < R) {
              s.m['drag'] = Offset(c, cy);
              s.m['la'] = math.atan2(py - cy, px - c);
              Scrub.begin(1.6);
              return true;
            }
          }
          return false;
        }
      case 'wring':
        {
          final cx = q[0] as double, cy = q[1] as double, R = q[2] as double, d = _hyp(px - cx, py - cy);
          if (d > R * 0.88 && d < R * 1.75) {
            s.m['drag'] = true;
            move(id, s, o);
            return true;
          }
          if (d <= R * 0.88) {
            s.m['tap'] = true;
            return true;
          }
          return false;
        }
      case 'knob':
        {
          final cx = q[0] as double, cy = q[1] as double, R = q[2] as double;
          if (_hyp(px - cx, py - cy) < R * 1.35) {
            s.m['drag'] = Offset(cx, cy);
            s.m['mv'] = 0.0;
            s.m['la'] = math.atan2(py - cy, px - cx);
            return true;
          }
          return false;
        }
      case 'speaker':
        {
          final d = _hyp(px - (q[0] as double), py - (q[1] as double)), R = q[2] as double;
          if (d < R * 0.5) {
            s.m['tap'] = true;
            return true;
          }
          if (d < R * 1.05) {
            s.m['k'] = 1.0;
            return true;
          }
          return false;
        }
      case 'scope':
        {
          final kg = s.m['kg'] as List<List<double>>?;
          if (kg != null) {
            for (var j = 0; j < 2; j++) {
              if (_hyp(px - kg[j][0], py - kg[j][1]) < kg[j][2] * 1.6) {
                s.m['kd'] = j + 1;
                s.m['ly'] = py;
                return true;
              }
            }
          }
          final sx = q[0] as double, sy = q[1] as double, sw = q[2] as double, sh = q[3] as double, ppx = q[4] as double, cs = q[5] as double;
          if (px > sx && px < sx + sw && py > sy && py < sy + sh) {
            s.m['sm'] = (((s.m['sm'] as int?) ?? 0) + 1) % 3;
            return true;
          }
          if (px > ppx && px < ppx + cs && py > sy && py < sy + cs) {
            s.m['tap'] = true;
            return true;
          }
          return false;
        }
      case 'pond':
        {
          final wl = q[0] as double, cx = q[1] as double, cy = q[2] as double, R = q[3] as double;
          if (py > wl) {
            final rip = (s.m['r'] as List<List<double>>?) ?? <List<double>>[];
            s.m['r'] = rip;
            rip.add([px, py, s.g('t'), 1.4]);
            return true;
          }
          if ((px - cx).abs() < R && (py - cy).abs() < R) {
            s.m['tap'] = true;
            return true;
          }
          return false;
        }
      case 'dots':
      case 'card':
        {
          final cx = q[0] as double, cy = q[1] as double, R = q[2] as double, lim = id == 'dots' ? 1.1 : 1.2;
          if ((px - cx).abs() > R * lim || (py - cy).abs() > R * lim) return false;
          s.m['px'] = px;
          s.m['py'] = py;
          s.m['x0'] = px;
          s.m['y0'] = py;
          s.m['mv'] = 0.0;
          return true;
        }
      case 'silk':
        {
          s.m['px'] = px;
          s.m['py'] = py;
          s.m['x0'] = px;
          s.m['mv'] = 0.0;
          s.m['p0'] = kc.p;
          return true;
        }
    }
    return false;
  }

  static void move(String id, DevS s, Offset o) {
    final px = (o.dx - s.ox) / s.k, py = (o.dy - s.oy) / s.k;
    switch (id) {
      case 'cassette':
      case 'reels':
      case 'jog':
        {
          if (s.m['sl'] == true) {
            final q = s.m['geo'] as List;
            app.player.setSpeed(2 - _cl((py - (q[4] as double)) / (q[5] as double), 0, 1) * 1.5);
            return;
          }
          final c = s.m['drag'] as Offset?;
          if (c == null) return;
          var d = _ang(s, px, py, c.dx, c.dy);
          if (id != 'jog' && ((d > 0 && kc.p > 0.997) || (d < 0 && kc.p < 0.003))) d = 0;
          s.m['a'] = s.g('a') + d;
          Scrub.turn(d);
        }
      case 'wring':
        {
          if (s.m['drag'] != true) return;
          final q = s.m['geo'] as List;
          var a = math.atan2(py - (q[1] as double), px - (q[0] as double)) + math.pi / 2;
          if (a < 0) a += tau;
          s.m['p'] = a / tau;
        }
      case 'knob':
        {
          final c = s.m['drag'] as Offset?;
          if (c == null) return;
          final d = _ang(s, px, py, c.dx, c.dy);
          s.m['mv'] = s.g('mv') + d.abs();
          app.player.p.setVolume(_cl(kc.vol + d / (math.pi * 1.5), 0, 1));
        }
      case 'scope':
        {
          final kd = s.m['kd'] as int?;
          if (kd == null || kd == 0) return;
          final d = (s.g('ly') - py) / 120;
          s.m['ly'] = py;
          if (kd == 1) {
            s.m['z'] = _cl(s.g('z', 0.5) + d, 0, 1);
          } else {
            s.m['b'] = _cl(s.g('b', 0.6) + d, 0, 1);
          }
        }
      case 'dots':
      case 'card':
        {
          if (s.m['px'] == null) return;
          s.m['mv'] = math.max(s.g('mv'), _hyp(px - s.g('x0'), py - s.g('y0')));
          if (id == 'dots') {
            s.m['px'] = px;
            s.m['py'] = py;
          } else {
            final q = s.m['geo'] as List, cx = q[0] as double, cy = q[1] as double, R = q[2] as double;
            s.m['tx'] = _cl((px - cx) / R, -1, 1) * 0.55;
            s.m['ty'] = -_cl((py - cy) / R, -1, 1) * 0.45;
          }
        }
      case 'silk':
        {
          if (s.m['px'] == null) return;
          s.m['fv'] = s.g('fv') - (px - s.g('px')) * 0.002;
          s.m['mv'] = math.max(s.g('mv'), (px - s.g('x0')).abs());
          s.m['px'] = px;
          s.m['py'] = py;
        }
    }
  }

  static void up(String id, DevS s) {
    switch (id) {
      case 'wring':
        if (s.m['drag'] == true && kc.dur > 0) app.player.seek(s.g('p') * kc.dur);
      case 'knob':
        if (s.m['drag'] != null && s.g('mv') < 0.05) app.player.toggle();
      case 'dots':
        if (s.m['px'] != null && s.g('mv') < 6) app.player.toggle();
        s.m['px'] = null;
        s.m['py'] = null;
      case 'card':
        if (s.m['px'] != null && s.g('mv') < 6) s.m['fl'] = s.m['fl'] != true;
        s.m['px'] = null;
      case 'silk':
        if (s.m['px'] != null) {
          final q = s.m['geo'] as List, W = q[0] as double;
          if (s.g('mv') < 8) {
            if ((s.g('x0') - (q[1] as double)).abs() < (q[3] as double) && (s.g('py') - (q[2] as double)).abs() < (q[3] as double)) app.player.toggle();
          } else if (kc.dur > 0) {
            app.player.seek(_cl(s.g('p0') - (s.g('px') - s.g('x0')) / W * (60 / kc.dur), 0, 1) * kc.dur);
          }
        }
        s.m['px'] = null;
        s.m['py'] = null;
    }
    if (s.m['tap'] == true) app.player.toggle();
    s.m['tap'] = false;
    s.m['drag'] = null;
    s.m['sl'] = false;
    s.m['kd'] = 0;
  }
}

/// تحديث بيانات التحكم لكل إطار
void kcUpdate(List<double> env) {
  final pl = app.player.p, t = app.player.cur;
  kc.dur = (pl.duration?.inMilliseconds ?? 0) / 1000.0;
  kc.p = kc.dur > 0 ? _cl(pl.position.inMilliseconds / 1000.0 / kc.dur, 0, 1) : 0;
  kc.playing = pl.playing;
  kc.speed = pl.speed;
  kc.vol = pl.volume;
  kc.title = t?.title ?? 'منبر';
  kc.sub = t == null ? '' : [t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · ');
  kc.peaks = env;
}

Float64List? unused;
