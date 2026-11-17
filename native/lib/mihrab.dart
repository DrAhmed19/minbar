import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ========== افتتاحية المحراب: القوس + الأعمدة + اسم «منبر» ==========
/// نفس تصميم الويب (mihrab.js): قوس يُرسم من قمته، ينفتح منه ضوء، ذرات ذهب تتجمع على شكل الاسم،
/// ثم يصغر القوس ويرتفع فوق الاسم وتعلو الأعمدة، وأخيراً لمعة على الاسم وسطر الإهداء.
class MihrabAssets {
  static ui.Image? name;
  static List<_Pt> pts = const [];
  static Future<void>? _f;
  static Future<void> load() => _f ??= _load();
  static Future<void> _load() async {
    try {
      final d = await rootBundle.load('assets/name.png');
      final c = await ui.instantiateImageCodec(d.buffer.asUint8List());
      final img = (await c.getNextFrame()).image;
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final r = math.Random(7), a = <_Pt>[];
      if (bd != null) {
        final w = img.width, h = img.height;
        final st = (w / 120).round().clamp(2, 20);
        for (var y = 0; y < h; y += st) {
          for (var x = 0; x < w; x += st) {
            if (bd.getUint8((y * w + x) * 4 + 3) > 150) a.add(_Pt(x / w, y / h, 0, 0, 0));
          }
        }
        a.shuffle(r);
      }
      pts = a.take(420).map((p) => _Pt(p.x, p.y, r.nextDouble() * .35, (r.nextDouble() - .5) * 60, r.nextDouble() * 20)).toList();
      name = img;
    } catch (_) {}
  }
}

class _Pt {
  final double x, y, d, ox, oy;
  const _Pt(this.x, this.y, this.d, this.ox, this.oy);
}

double _r(double p, double a, double b) => ((p - a) / (b - a)).clamp(0.0, 1.0);
double _e(double t) => t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
double _sm(double t) => t * t * (3 - 2 * t);
double _l(double a, double b, double t) => a + (b - a) * t;
double _ob(double v) {
  const c1 = .7, c3 = c1 + 1;
  return 1 + c3 * math.pow(v - 1, 3) + c1 * math.pow(v - 1, 2);
}

double _bk(double w, int i) => .3 + .7 * (.5 + .5 * math.sin(w * 6.283 + i * 1.1));

const _W = 360.0, _H = 640.0;
const _xs = [23.5, 39.5, 55.5, 71.5, 87.5], _hs = [50.0, 72.0, 90.0, 72.0, 50.0];
const _S0 = 2.45, _S1 = 1.5, _AY1 = 140.0, _NW0 = 200.0, _NW1 = 205.0;
const _AY0 = _H * .5 - 64 * _S0;
double _nh(double w) => w * 662 / 960;

final Path _archL = Path()
  ..moveTo(60, 6)
  ..quadraticBezierTo(14, 22, 14, 58)
  ..lineTo(14, 118);
final Path _archR = Path()
  ..moveTo(60, 6)
  ..quadraticBezierTo(106, 22, 106, 58)
  ..lineTo(106, 118);
final Path _archLI = Path()
  ..moveTo(60, 14)
  ..quadraticBezierTo(21, 28, 21, 60)
  ..lineTo(21, 116);
final Path _archRI = Path()
  ..moveTo(60, 14)
  ..quadraticBezierTo(99, 28, 99, 60)
  ..lineTo(99, 116);
final Path _inner = Path()
  ..moveTo(15, 118)
  ..lineTo(15, 58)
  ..quadraticBezierTo(15, 23, 60, 7)
  ..quadraticBezierTo(105, 23, 105, 58)
  ..lineTo(105, 118)
  ..close();

Path _part(Path p, double a, double b) {
  final out = Path();
  for (final m in p.computeMetrics()) {
    out.addPath(m.extractPath(m.length * a, m.length * b), Offset.zero);
  }
  return out;
}

Offset _tip(Path p, double t) {
  for (final m in p.computeMetrics()) {
    return m.getTangentForOffset(m.length * t.clamp(0.0, 1.0))?.position ?? Offset.zero;
  }
  return Offset.zero;
}

final _motes = List.generate(34, (i) {
  final r = math.Random(i * 31 + 5);
  return [r.nextDouble(), r.nextDouble(), .4 + r.nextDouble() * 1.1, .04 + r.nextDouble() * .08, r.nextDouble() * 6];
});

ui.Picture? _patPic;
ui.Picture _pattern() {
  if (_patPic != null) return _patPic!;
  final rec = ui.PictureRecorder(), c = Canvas(rec);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .6
    ..color = const Color(0xFFE8C878);
  const t = 36.0;
  var row = 0;
  for (var y = -t; y < _H + t; y += t, row++) {
    for (var x = -t; x < _W + t; x += t) {
      final cx = x + (row.isOdd ? t / 2 : 0);
      for (final a in [0.0, math.pi / 4]) {
        c.save();
        c.translate(cx, y);
        c.rotate(a);
        c.drawRect(const Rect.fromLTWH(-9, -9, 18, 18), p);
        c.restore();
      }
      c.drawCircle(Offset(cx, y), 3, p);
    }
  }
  return _patPic = rec.endRecording();
}

Shader _gold(Rect r) => ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFFF4DB92), Color(0xFFE3BF66), Color(0xFFCFA34A)], const [0, .5, 1]);

class MihrabPainter extends CustomPainter {
  final double t; // ثوانٍ منذ البداية
  final bool compact; // الشعار النهائي فقط (شاشة الدخول)
  final String dedication;
  MihrabPainter(this.t, {this.compact = false, this.dedication = 'إهداء إلى الحاج باسم الكربلائي'});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    double hc = _H;
    canvas.save();
    if (compact) {
      final k = math.min(size.width / 272, size.height / 408);
      canvas.translate(size.width / 2 - 180 * k, size.height / 2 - 312 * k);
      canvas.scale(k);
    } else {
      final k = math.min(size.width / _W, size.height / _H);
      hc = size.height / k;
      canvas.translate((size.width - _W * k) / 2, (size.height - _H * k) / 2);
      canvas.scale(k);
    }
    _scene(canvas, hc);
    canvas.restore();
  }

  void _scene(Canvas c, double hc) {
    final w = t / 1.8, el = compact ? 9.0 : t * 1.6;
    final mvT = _r(el, 2.7, 3.9), mv = 1 - math.pow(2, -9 * mvT) * (1 - mvT);
    final s = _l(_S0, _S1, mv), ax = _W / 2 - 60 * s, ay = _l(_AY0, _AY1, mv);
    final done = _r(el, 4.3, 5), lo = _sm(_r(el, .8, 1.9)) * (1 - _sm(_r(el, 2.6, 3.6)));
    final br = done * (_bk(w, 2) * .5 + _bk(w, 0) * .5);
    final big = const Rect.fromLTWH(-1500, -1500, 3360, 3640);
    final ctr = Offset(_W / 2, ay + 70 * s);

    if (!compact) {
      final cy = _l(_H * .5, ay + 64 * s, mv);
      c.drawRect(big, Paint()..shader = ui.Gradient.radial(Offset(_W / 2, cy), 620, const [Color(0xFF0E4636), Color(0xFF06281E), Color(0xFF010A07)], const [0, .45, 1]));
      c.drawRect(big, Paint()..shader = ui.Gradient.radial(const Offset(_W / 2, _H / 2), _H * .75, const [Color(0x00000000), Color(0x00000000), Color(0x73000000)], const [0, .4, 1]));
      // زخرفة هندسية خافتة يكشفها الضوء
      final pa = (.05 + .16 * lo + .03 * done).clamp(0.0, 1.0);
      final pr = Rect.fromCircle(center: ctr, radius: 90 * s + 90);
      c.saveLayer(pr, Paint()..color = Color.fromRGBO(0, 0, 0, pa));
      c.drawPicture(_pattern());
      c.drawRect(pr, Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.radial(ctr, 90 * s + 90, const [Color(0xFF000000), Color(0x00000000)]));
      c.restore();
    }
    // هالة
    final ha = .07 + .2 * lo + .06 * _r(el, 0, 1) + .07 * br;
    c.drawRect(big, Paint()..shader = ui.Gradient.radial(ctr, compact ? 125 : 95 * s + 60, [Color.fromRGBO(240, 205, 120, ha.clamp(0.0, 1.0)), const Color(0x00F0CD78)]));

    // ضوء المحراب
    if (lo > .001) {
      c.save();
      c.translate(ax, ay);
      c.scale(s);
      const lr = Rect.fromLTWH(0, 0, 120, 130);
      c.saveLayer(lr, Paint()
        ..blendMode = BlendMode.plus
        ..color = Color.fromRGBO(0, 0, 0, (lo * .9).clamp(0.0, 1.0)));
      c.clipPath(_inner);
      final hw = 8 + lo * 48;
      c.drawRect(lr, Paint()..shader = ui.Gradient.linear(Offset(60 - hw, 0), Offset(60 + hw, 0), const [Color(0x00FFECAA), Color(0x9EFFE8AA), Color(0x00FFECAA)], const [0, .5, 1]));
      final rp = Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, -120), const [Color(0x38FFECBE), Color(0x00FFF0C8)]);
      for (var i = -4; i <= 4; i++) {
        c.save();
        c.translate(60, 124);
        c.rotate(i * .11 + math.sin(el * .7 + i) * .01);
        c.drawPath(Path()
          ..moveTo(-1.2, 0)
          ..lineTo(1.2, 0)
          ..lineTo(4, -120)
          ..lineTo(-4, -120)
          ..close(), rp);
        c.restore();
      }
      final mp = Paint()
        ..blendMode = BlendMode.plus
        ..color = const Color(0xE6FFFAE6);
      for (final m in _motes) {
        final yy = 118 - ((m[1] * 118 + el * m[3] * 120) % 112), xx = 60 + (m[0] - .5) * hw * 1.6 + math.sin(el + m[4]) * 2;
        c.drawCircle(Offset(xx, yy), m[2] * .6, mp);
      }
      c.drawRect(lr, Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 118), const [Color(0x8C000000), Color(0xFF000000), Color(0xBF000000), Color(0x00000000)], const [0, .6, .88, 1]));
      c.restore();
      c.restore();
      // انعكاس الأرض
      final fy = ay + 118 * s;
      c.save();
      c.translate(_W / 2, fy);
      c.scale(1, .18);
      c.drawCircle(Offset.zero, 70 * s, Paint()..shader = ui.Gradient.radial(Offset.zero, 70 * s, [Color.fromRGBO(255, 230, 160, .28 * lo), const Color(0x00FFE6A0)]));
      c.restore();
    }

    // القوس
    final dr = _e(_r(el, 0, 1.05)), lw = 4.6 / s;
    c.save();
    c.translate(ax, ay);
    c.scale(s);
    final aL = _part(_archL, 0, dr), aR = _part(_archR, 0, dr);
    const ar = Rect.fromLTWH(0, 0, 120, 120);
    final sh = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0x99000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 / s);
    c.save();
    c.translate(0, 3 / s);
    c.drawPath(aL, sh);
    c.drawPath(aR, sh);
    c.restore();
    final gl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xD9F6D782)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, (3 + 8 * lo + 3 * br) / s);
    c.drawPath(aL, gl);
    c.drawPath(aR, gl);
    final gp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = _gold(ar);
    c.drawPath(aL, gp);
    c.drawPath(aR, gp);
    final hp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw * .28
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x8CFFFAE1);
    c.drawPath(aL, hp);
    c.drawPath(aR, hp);
    final di = _e(_r(el, .35, 1.35));
    if (di > 0) {
      final ip = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * .32
        ..strokeCap = StrokeCap.round
        ..shader = _gold(ar);
      c.saveLayer(const Rect.fromLTWH(-10, -10, 140, 140), Paint()..color = const Color(0x8C000000));
      c.drawPath(_part(_archLI, 0, di), ip);
      c.drawPath(_part(_archRI, 0, di), ip);
      c.restore();
    }
    if (el > 4.2) {
      final ph = ((t + 10) % 3.2) / 3.2;
      if (ph < .55) {
        final q = _sm(ph / .55) * 1.2, a = (q - .16).clamp(0.0, 1.0), b = q.clamp(0.0, 1.0);
        if (b > a) {
          final sp = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = lw * .7
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xD9FFFCEB)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 / s);
          c.drawPath(_part(_archL, a, b), sp);
          c.drawPath(_part(_archR, a, b), sp);
        }
      }
    }
    c.restore();
    if (dr > 0 && dr < 1) {
      for (final p in [_archL, _archR]) {
        final o = _tip(p, dr);
        _spark(c, Offset(ax + o.dx * s, ay + o.dy * s), 9);
      }
    }

    // الأعمدة
    final rs = _r(el, 3.35, 4.3);
    if (rs > 0) {
      c.save();
      c.translate(ax, ay);
      c.scale(s);
      final bp = Paint()..shader = _gold(ar);
      final bs = Paint()
        ..color = const Color(0x59000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 / s);
      final bg = Paint()
        ..color = Color.fromRGBO(246, 215, 130, .55 + .2 * br)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (3 + 3 * br) / s);
      final bh = Paint()..color = const Color(0x8CFFFAE1);
      for (var i = 0; i < 5; i++) {
        final r = _ob((rs * 1.7 - i * .17).clamp(0.0, 1.0)).clamp(0.0, 1.15), h = _hs[i] * _bk(w, i) * r;
        if (h < .6) continue;
        final rr = RRect.fromRectAndRadius(Rect.fromLTWH(_xs[i], 116 - h, 9, h), const Radius.circular(4.5));
        c.drawRRect(rr.shift(Offset(0, 2.5 / s)), bs);
        c.drawRRect(rr, bg);
        c.drawRRect(rr, bp);
        if (h > 6) c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(_xs[i] + 2.2, 116 - h + 3, 1.3, h - 6), const Radius.circular(.65)), bh);
      }
      c.restore();
    }

    // الاسم: ذرات ذهب تطلع من ضوء المحراب وتتجمع على شكله
    final ep = _sm(_r(el, 1.15, 2.75)), img = MihrabAssets.name;
    if (ep > 0 && img != null) {
      final nw = _l(_NW0, _NW1, mv), nh = _nh(nw);
      final ccy = _l(_AY0 + 70 * _S0, _AY1 + 130 * _S1 + 18 + _nh(_NW1) / 2, mv);
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromLTWH(-nw / 2, -nh / 2, nw, nh);
      c.save();
      c.translate(_W / 2, ccy);
      final sc = _l(.97, 1, ep);
      c.scale(sc);
      final na = _sm(_r(ep, .5, 1));
      if (na > 0) {
        // ظل غامق
        c.saveLayer(dst.inflate(30), Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 6 + 4 * lo, sigmaY: 6 + 4 * lo)
          ..colorFilter = ColorFilter.mode(Color.fromRGBO(20, 10, 0, (.5 + .35 * lo) * na), BlendMode.srcIn));
        c.drawImageRect(img, src, dst.shift(const Offset(0, 4)), Paint());
        c.restore();
        // توهج ذهبي
        final gs = 3 + 5 * lo + 2.5 * br;
        c.saveLayer(dst.inflate(30), Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: gs, sigmaY: gs)
          ..colorFilter = ColorFilter.mode(Color.fromRGBO(246, 215, 130, .75 * na), BlendMode.srcIn));
        c.drawImageRect(img, src, dst, Paint());
        c.restore();
        // الاسم + لمعة
        c.saveLayer(dst, Paint()..color = Color.fromRGBO(0, 0, 0, na));
        c.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.high);
        final sp = compact ? (t % 8) / 1.7 : _r(el, 4.2, 5.8);
        if (sp > 0 && sp < 1) {
          final cc = 1.3 - 1.6 * _e(sp);
          double k(double v) => v.clamp(0.0, 1.0);
          c.drawRect(dst, Paint()
            ..blendMode = BlendMode.srcATop
            ..shader = ui.Gradient.linear(dst.topLeft, Offset(dst.right, dst.top + dst.height * .39), const [Color(0x00FFFAE6), Color(0x00FFFAE6), Color(0xBFFFFCEE), Color(0x00FFFAE6), Color(0x00FFFAE6)], [0, k(cc - .17), k(cc), k(cc + .17), 1]));
        }
        c.restore();
      }
      if (ep < 1 && MihrabAssets.pts.isNotEmpty) {
        final sy = (ay + 118 * s) - ccy, fade = 1 - _sm(_r(ep, .7, 1));
        final pp = Paint()
          ..blendMode = BlendMode.plus
          ..color = Color.fromRGBO(255, 236, 170, .85 * fade);
        for (final p in MihrabAssets.pts) {
          final tt = _sm(_r(ep, p.d, p.d + .62));
          if (tt <= 0) continue;
          final tx = -nw / 2 + p.x * nw, ty = -nh / 2 + p.y * nh;
          c.drawCircle(Offset(_l(p.ox, tx, tt), _l(sy - p.oy, ty, tt) - math.sin(tt * math.pi) * 22), .85, pp);
        }
      }
      c.restore();
    }

    // الإهداء
    if (!compact) {
      final ta = _sm(_r(el, 4.8, 5.6));
      if (ta > 0) {
        final tp = TextPainter(
          text: TextSpan(text: dedication, style: TextStyle(fontFamily: 'Amiri', fontSize: 14, color: Color.fromRGBO(205, 187, 138, .75 * ta))),
          textDirection: TextDirection.rtl,
        )..layout();
        final y = _H + (hc - _H) / 2 - 44;
        tp.paint(c, Offset(_W / 2 - tp.width / 2, y - tp.height * .78));
      }
    }
  }

  void _spark(Canvas c, Offset p, double r) {
    c.drawCircle(p, r, Paint()..shader = ui.Gradient.radial(p, r, const [Color(0xFFFFFFF5), Color(0xD9FFECAA), Color(0x00E8C46A)], const [0, .25, 1]));
  }

  @override
  bool shouldRepaint(covariant MihrabPainter o) => o.t != t || o.compact != compact;
}

/// شعار شاشة الدخول: التكوين النهائي مع نبض الأعمدة ولمعة دورية
class MihrabMark extends StatefulWidget {
  final double width, height;
  const MihrabMark({super.key, this.width = 200, this.height = 240});
  @override
  State<MihrabMark> createState() => _MihrabMarkState();
}

class _MihrabMarkState extends State<MihrabMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final _sw = Stopwatch()..start();
  @override
  void initState() {
    super.initState();
    MihrabAssets.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: MihrabPainter(_sw.elapsedMilliseconds / 1000 + 3, compact: true)),
        ),
      );
}

/// خلفية شاشة الدخول: نفس تدرّج الافتتاحية مع زخرفة هندسية خافتة حول الشعار
class MihrabBackdrop extends CustomPainter {
  final double cy; // مركز الإضاءة نسبةً لارتفاع الشاشة
  const MihrabBackdrop({this.cy = .3});
  @override
  void paint(Canvas c, Size z) {
    final r = Offset.zero & z, ctr = Offset(z.width / 2, z.height * cy);
    c.drawRect(r, Paint()..shader = ui.Gradient.radial(ctr, z.longestSide * .9, const [Color(0xFF0E4636), Color(0xFF06281E), Color(0xFF010A07)], const [0, .45, 1]));
    final k = z.width / _W;
    final pr = Rect.fromCircle(center: ctr, radius: z.width * .75);
    c.saveLayer(pr, Paint()..color = const Color(0x12000000));
    c.save();
    c.translate(0, ctr.dy - _H * k * .3);
    c.scale(k);
    c.drawPicture(_pattern());
    c.restore();
    c.drawRect(pr, Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = ui.Gradient.radial(ctr, z.width * .75, const [Color(0xFF000000), Color(0x00000000)]));
    c.restore();
    c.drawRect(r, Paint()..shader = ui.Gradient.radial(ctr, z.width * .7, const [Color(0x22F0CD78), Color(0x00F0CD78)]));
  }

  @override
  bool shouldRepaint(covariant MihrabBackdrop o) => o.cy != cy;
}

/// شعار Google الملوّن (حرف G)
class GoogleG extends CustomPainter {
  const GoogleG();
  @override
  void paint(Canvas c, Size z) {
    final s = z.shortestSide, ctr = Offset(z.width / 2, z.height / 2), r = s * .36, w = s * .2;
    final rect = Rect.fromCircle(center: ctr, radius: r);
    Paint p(Color col) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = col;
    const d = math.pi / 180;
    c.drawArc(rect, -40 * d, -95 * d, false, p(const Color(0xFFEA4335)));
    c.drawArc(rect, -135 * d, -90 * d, false, p(const Color(0xFFFBBC05)));
    c.drawArc(rect, 135 * d, -95 * d, false, p(const Color(0xFF34A853)));
    c.drawArc(rect, 40 * d, -40 * d, false, p(const Color(0xFF4285F4)));
    c.drawRect(Rect.fromLTWH(ctr.dx, ctr.dy - w / 2, r + w / 2, w), Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
