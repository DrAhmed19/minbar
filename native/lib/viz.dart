import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'analysis.dart';
import 'state.dart';
import 'viz_dev.dart';

/// منبر — مرئيات المشغّل (منقولة من plrviz.js بنفس الرسم والقيم)
const double tau = math.pi * 2;

class Th {
  final Color a, a2, i, s;
  final List<Color> b;
  const Th(this.a, this.a2, this.i, this.b, this.s);
}

const kThemes = <String, Th>{
  'mihrab': Th(Color(0xFFE8C468), Color(0xFFF3D88A), Color(0xFF2A2106), [Color(0xFF0C4A39), Color(0xFF07281E), Color(0xFF04140F)], Color(0xFF0F2A22)),
  'retro': Th(Color(0xFFF2A541), Color(0xFFFFD39A), Color(0xFF1B1206), [Color(0xFF2A2724), Color(0xFF171513), Color(0xFF0B0A09)], Color(0xFF1E1B18)),
  'scope': Th(Color(0xFF6CFF9E), Color(0xFFC9FFD9), Color(0xFF02140A), [Color(0xFF06170F), Color(0xFF030C07), Color(0xFF010503)], Color(0xFF05120B)),
  'metal': Th(Color(0xFFD9DEE2), Color(0xFFFFFFFF), Color(0xFF15181A), [Color(0xFF2E3236), Color(0xFF1A1D20), Color(0xFF0C0E0F)], Color(0xFF1D2023)),
  'water': Th(Color(0xFF7FD3E8), Color(0xFFCFF3FB), Color(0xFF032029), [Color(0xFF0B4552), Color(0xFF05252D), Color(0xFF021217)], Color(0xFF062A33)),
  'glass': Th(Color(0xFFFFFFFF), Color(0xFFF3D88A), Color(0xFF0F2A22), [Color(0xFF1F3D35), Color(0xFF122722), Color(0xFF081512)], Color(0xEB142822)),
  'silk': Th(Color(0xFFE9C7FF), Color(0xFFF3D88A), Color(0xFF2A1530), [Color(0xFF3A2244), Color(0xFF1F1226), Color(0xFF0F0913)], Color(0xFF24142B)),
  'wood': Th(Color(0xFFE8A85C), Color(0xFFFFD7A6), Color(0xFF2A1606), [Color(0xFF3A2414), Color(0xFF21140A), Color(0xFF100904)], Color(0xFF26170C)),
  'neon': Th(Color(0xFF36F1CD), Color(0xFFFF4FD8), Color(0xFF03110E), [Color(0xFF120F22), Color(0xFF0A0814), Color(0xFF040309)], Color(0xFF0D0B18)),
  'night': Th(Color(0xFFF3D88A), Color(0xFFBFD1FF), Color(0xFF1C1A10), [Color(0xFF16244A), Color(0xFF0B142C), Color(0xFF050914)], Color(0xFF0E1833)),
};
const kVizIds = ['mihrab', 'ambient', 'wring', 'cover', 'vinyl', 'cassette', 'jog', 'reels', 'knob', 'speaker', 'scope', 'pond', 'dots', 'card', 'silk', 'strings', 'candles', 'halo', 'bars', 'blob', 'wave', 'spectrum', 'orbit', 'pulse', 'star', 'dust', 'neon'];
const kVizTitles = ['المحراب', 'أجواء', 'حلقة الموجة', 'غلاف', 'أسطوانة', 'الكاسيت', 'عجلة الدوران', 'جهاز البكرات', 'مقبض الصوت', 'السمّاعة', 'جهاز الذبذبات', 'البركة', 'ذرّات الغلاف', 'البطاقة الزجاجية', 'الحرير المضيء', 'الأوتار', 'الشموع', 'هالة', 'حلقة الأعمدة', 'موجة دائرية', 'خط الصوت', 'أعمدة الطيف', 'مدارات', 'نبض', 'النجمة الثمانية', 'غبار ذهبي', 'إطار مضيء'];
const _vth = {'mihrab': 'mihrab', 'ambient': 'mihrab', 'cover': 'mihrab', 'wring': 'silk', 'cassette': 'retro', 'jog': 'retro', 'reels': 'retro', 'knob': 'metal', 'speaker': 'metal', 'scope': 'scope', 'pond': 'water', 'dots': 'glass', 'card': 'glass', 'vinyl': 'retro', 'silk': 'silk', 'strings': 'wood', 'candles': 'wood', 'neon': 'neon', 'pulse': 'neon', 'spectrum': 'neon', 'bars': 'neon', 'halo': 'night', 'star': 'night', 'orbit': 'night', 'dust': 'night', 'blob': 'night', 'wave': 'night'};
const _thx = {
  'mihrab': ('F2', 'arch', 'glass', 'line'),
  'retro': ('F14', 'disc', 'metal', 'tape'),
  'scope': ('F1', 'squ', 'outline', 'seg'),
  'metal': ('F0', 'disc', 'metal', 'thick'),
  'water': ('F13', 'glass', 'float', 'glow'),
  'glass': ('F5', 'glass', 'float', 'line'),
  'silk': ('F12', 'squ', 'float', 'glow'),
  'wood': ('F3', 'circle', 'bar', 'thick'),
  'neon': ('F4', 'ring', 'outline', 'glow'),
  'night': ('F2', 'circle', 'glass', 'line'),
};

/// (خط العنوان، شكل زر التشغيل، شكل الشريط السفلي، شكل خط التقدّم) لكل قالب
({String font, String btn, String dock, String pg}) thx(int viz) {
  final r = _thx[_vth[kVizIds[viz % kVizIds.length]] ?? 'mihrab']!;
  return (font: r.$1, btn: r.$2, dock: r.$3, pg: r.$4);
}

Th themeOf(int viz) => kThemes[_vth[kVizIds[viz % kVizIds.length]] ?? 'mihrab']!;

/// ألوان الخلفية: من الغلاف / لون القالب / ألوان ثابتة
const kBgKeys = ['auto', 'theme', '#000000', '#0d1b2a', '#0c4a39', '#4a0f1a', '#2b1640', '#3a2414', '#23272b', '#0f3b44'];
const kBgTitles = ['من الغلاف', 'لون القالب', 'أسود فاخر', 'كحلي', 'أخضر', 'عنابي', 'بنفسجي', 'بني', 'فحمي', 'فيروزي'];

Color hsl(double h, double s, double l) => HSLColor.fromAHSL(1, h % 360, (s / 100).clamp(0.0, 1.0), (l / 100).clamp(0.0, 1.0)).toColor();

class Pal {
  final List<Color> b;
  final Color? a;
  const Pal(this.b, [this.a]);
}

/// نفس bgPal في الويب
Pal bgPal(int bg, Th th, ({double h, double s, bool mono})? hue) {
  final k = kBgKeys[bg % kBgKeys.length];
  if (k == 'theme') return Pal(th.b);
  if (k == '#000000') return Pal(const [Color(0xFF151515), Color(0xFF0A0A0A), Color(0xFF000000)], th.a == const Color(0xFFFFFFFF) ? const Color(0xFFE8C468) : null);
  double h, s;
  if (k == 'auto') {
    if (hue == null) return Pal(th.b);
    if (hue.mono) return const Pal([Color(0xFF1A1A1A), Color(0xFF0D0D0D), Color(0xFF030303)]);
    h = hue.h;
    s = math.max(28.0, hue.s);
  } else {
    final c = HSLColor.fromColor(Color(int.parse('FF${k.substring(1)}', radix: 16)));
    h = c.hue;
    s = c.saturation * 100;
    if (s < 6) return Pal([hsl(h, s, 16), hsl(h, s, 9), hsl(h, s, 4)]);
  }
  final ah = HSLColor.fromColor(th.a).hue;
  final dh = math.min((ah - h).abs(), 360 - (ah - h).abs());
  Color? a;
  if (dh < 28 && th.a != const Color(0xFFFFFFFF)) a = th.a == const Color(0xFFE8C468) ? const Color(0xFFF5F0E6) : const Color(0xFFE8C468);
  return Pal([hsl(h, s * 0.75, 22), hsl(h, s * 0.7, 12), hsl(h, s * 0.6, 5)], a);
}

// ---------- الغلاف كصورة للرسم + لونه الغالب ----------
final Map<String, ui.Image> _imgs = {};
final Map<String, ({double h, double s, bool mono})?> _hues = {};

Future<ui.Image?> coverImage(String url, {String? file}) async {
  if (url.isEmpty) return null;
  if (_imgs.containsKey(url)) return _imgs[url];
  final c = Completer<ui.Image?>();
  ImageProvider p = CachedNetworkImageProvider(url);
  if (file != null && File(file).existsSync()) p = FileImage(File(file));
  final s = p.resolve(ImageConfiguration.empty);
  late ImageStreamListener l;
  l = ImageStreamListener((info, _) {
    if (!c.isCompleted) c.complete(info.image);
    s.removeListener(l);
  }, onError: (_, __) {
    if (!c.isCompleted) c.complete(null);
    s.removeListener(l);
  });
  s.addListener(l);
  final im = await c.future.timeout(const Duration(seconds: 15), onTimeout: () => null);
  if (im != null) {
    if (_imgs.length > 12) _imgs.clear();
    _imgs[url] = im;
  }
  return im;
}

Future<({double h, double s, bool mono})?> coverHue(String url, ui.Image im) async {
  if (_hues.containsKey(url)) return _hues[url];
  ({double h, double s, bool mono})? res;
  try {
    final rec = ui.PictureRecorder();
    Canvas(rec).drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), const Rect.fromLTWH(0, 0, 32, 32), Paint()..filterQuality = FilterQuality.low);
    final small = await rec.endRecording().toImage(32, 32);
    final bd = await small.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd != null) {
      final bins = List<double>.filled(36, 0), sat = List<double>.filled(36, 0);
      var n = 0;
      for (var i = 0; i < bd.lengthInBytes; i += 4) {
        final c = HSLColor.fromColor(Color.fromARGB(255, bd.getUint8(i), bd.getUint8(i + 1), bd.getUint8(i + 2)));
        final s = c.saturation * 100, l = c.lightness * 100;
        n++;
        if (s < 18 || l < 10 || l > 90) continue;
        final w = (s / 100) * (1 - (l - 50).abs() / 50);
        final k = (c.hue / 10).floor() % 36;
        bins[k] += w;
        sat[k] += s * w;
      }
      var bk = -1;
      var bv = 0.0;
      for (var k = 0; k < 36; k++) {
        final v = bins[k] + (bins[(k + 35) % 36] + bins[(k + 1) % 36]) * 0.5;
        if (v > bv) {
          bv = v;
          bk = k;
        }
      }
      res = bv > n * 0.02 ? (h: bk * 10 + 5.0, s: math.min(70.0, sat[bk] / bins[bk]), mono: false) : (h: 150.0, s: 8.0, mono: true);
    }
  } catch (_) {}
  _hues[url] = res;
  return res;
}

// ---------- قيم الصوت لكل إطار ----------
class VizF {
  final List<double> vals = List.filled(22, 0);
  double bass = 0, mid = 0, hi = 0, vol = 0, beat = 0;
  final List<double> wave = List.filled(96, 0);
  double operator [](String k) => k == 'bass' ? bass : (k == 'mid' ? mid : hi);
}

class VizState {
  double va = 0, vw = 0, arm = 0, ab = 0, av = 0, am = 0;
  bool vdrag = false;
  final List<List<double>> aps = [];
  final List<({double t, double a})> rings = [];
  double lastBeat = 0;
  final List<_P> dust = [];
  final List<double> peaks = List.filled(32, 0);
}

class _P {
  double a, r, v, l, z;
  bool w;
  _P(this.a, this.r, this.v, this.l, this.z, this.w);
}

/// مرحلة المرئيات: تحسب القيم من التحليل المسبق وترسم القالب
class VizStage extends StatefulWidget {
  final Analysis? an;
  final ui.Image? img;
  final int viz;
  final double scale;
  final bool still;
  final List<double> env;
  const VizStage({super.key, required this.an, required this.img, required this.viz, this.scale = 1, this.still = false, this.env = const []});
  @override
  State<VizStage> createState() => _VizStageState();
}

class _VizStageState extends State<VizStage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(days: 1));
  final f = VizF();
  final vs = VizState();
  final _raw = List<double>.filled(22, 0);
  double _last = 0;
  final _sw = Stopwatch()..start();
  Timer? _pt;

  @override
  void initState() {
    super.initState();
    if (!widget.still) {
      if (app.player.perf == 1) {
        _pt = Timer.periodic(const Duration(milliseconds: 66), (_) {
          if (mounted) setState(() {});
        });
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _pt?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _tick(double now) {
    final pl = app.player.p;
    final playing = pl.playing;
    final sec = pl.position.inMilliseconds / 1000.0;
    if (widget.still) {
      for (var k = 0; k < 22; k++) {
        _raw[k] = 0.35 + 0.3 * math.sin(k * 0.7).abs();
      }
    } else if (playing && widget.an != null) {
      widget.an!.bandsAt(sec, _raw);
    } else if (playing) {
      for (var k = 0; k < 22; k++) {
        _raw[k] = 0.25 + 0.2 * math.sin(now * 6 + k * 0.6).abs();
      }
    } else {
      for (var k = 0; k < 22; k++) {
        _raw[k] = 0;
      }
    }
    for (var k = 0; k < 22; k++) {
      final t = _raw[k];
      f.vals[k] += (t - f.vals[k]) * (t > f.vals[k] ? 0.55 : 0.14);
    }
    double avg(int a, int b) {
      var s = 0.0;
      for (var k = a; k < b; k++) {
        s += f.vals[k];
      }
      return s / (b - a);
    }

    f.bass = avg(0, 4);
    f.mid = avg(4, 13);
    f.hi = avg(13, 22);
    f.vol = avg(0, 22);
    final bt = playing && widget.an != null ? widget.an!.beatAt(sec) : (playing ? f.bass * 0.6 : 0.0);
    f.beat += (bt - f.beat) * (bt > f.beat ? 0.7 : 0.2);
    for (var i = 0; i < f.wave.length; i++) {
      var w = 0.0;
      for (var k = 0; k < 22; k += 3) {
        w += math.sin(i * (0.12 + k * 0.05) + now * (4 + k)) * f.vals[k];
      }
      f.wave[i] = w * 0.09;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget frame() {
          final now = _sw.elapsedMicroseconds / 1e6;
          final dt = (now - _last).clamp(0.0, 0.1);
          _last = now;
          _tick(now);
          final id = kVizIds[widget.viz % kVizIds.length];
          if (kDevIds.contains(id)) {
            if (!widget.still) kcUpdate(widget.env);
            final ds = devState(id, widget.still);
            ds.m['dt'] = dt == 0 ? 0.016 : dt;
            final cp = CustomPaint(painter: DevPainter(id, f, ds, widget.img, widget.still), size: Size.infinite);
            if (widget.still) return cp;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => DevTouch.down(id, ds, d.localPosition),
              onPanUpdate: (d) => DevTouch.move(id, ds, d.localPosition),
              onPanEnd: (_) => DevTouch.up(id, ds),
              onPanCancel: () => DevTouch.up(id, ds),
              child: cp,
            );
          }
          final vp = CustomPaint(
            painter: VizPainter(id, f, vs, widget.img, now, dt == 0 ? 0.016 : dt, !app.player.p.playing, widget.scale),
            size: Size.infinite,
          );
          if (widget.still) return vp;
          if (id == 'vinyl') {
            return LayoutBuilder(builder: (_, c) {
              final o = Offset(c.maxWidth / 2, c.maxHeight / 2);
              double la = 0, mv = 0;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) {
                  la = math.atan2(d.localPosition.dy - o.dy, d.localPosition.dx - o.dx);
                  mv = 0;
                },
                onPanStart: (_) {
                  vs.vdrag = true;
                  Scrub.begin(1.15);
                },
                onPanUpdate: (d) {
                  final a = math.atan2(d.localPosition.dy - o.dy, d.localPosition.dx - o.dx);
                  var da = a - la;
                  if (da > math.pi) da -= 2 * math.pi;
                  if (da < -math.pi) da += 2 * math.pi;
                  la = a;
                  mv += da.abs();
                  vs.va += da;
                  Scrub.turn(da);
                },
                onPanEnd: (_) {
                  vs.vdrag = false;
                  Scrub.end();
                },
                onPanCancel: () {
                  vs.vdrag = false;
                  Scrub.end();
                },
                onTap: app.player.toggle,
                child: vp,
              );
            });
          }
          return GestureDetector(behavior: HitTestBehavior.translucent, onTap: app.player.toggle, child: vp);
    }

    return RepaintBoundary(child: app.player.perf == 1 || widget.still ? frame() : AnimatedBuilder(animation: _c, builder: (_, __) => frame()));
  }
}

class VizPainter extends CustomPainter {
  final String id;
  final VizF F;
  final VizState st;
  final ui.Image? img;
  final double t, dt, scale;
  final bool paused;
  VizPainter(this.id, this.F, this.st, this.img, this.t, this.dt, this.paused, this.scale);

  static const gold = Color(0xFFE8C468), gold2 = Color(0xFFF3D88A);
  Color ga(double a) => gold.withOpacity(a.clamp(0.0, 1.0));
  Color wa(double a) => Colors.white.withOpacity(a.clamp(0.0, 1.0));

  late Canvas x;
  late double W, H, cx, cy, R, u;

  RRect rr(double a, double b, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(a, b, w, h), Radius.circular(math.max(0.0, r)));

  void glow(double gx, double gy, double r0, double r1, double a) {
    final p = Paint()..shader = ui.Gradient.radial(Offset(gx, gy), r1, [ga(a), ga(0)], [r1 > 0 ? (r0 / r1).clamp(0.0, 1.0) : 0, 1]);
    x.drawCircle(Offset(gx, gy), r1, p);
  }

  void cover(double ccx, double ccy, double r, String shape, {bool ring = true}) {
    final sh = Paint()..shader = ui.Gradient.radial(Offset(ccx, ccy + r * 0.12), r * 1.25, [Colors.black.withOpacity(0.45), Colors.black.withOpacity(0)], [0.56, 1]);
    x.drawRect(Rect.fromLTWH(ccx - r * 1.3, ccy - r * 1.2, r * 2.6, r * 2.6), sh);
    final dst = Rect.fromLTWH(ccx - r, ccy - r, r * 2, r * 2);
    final path = Path();
    if (shape == 'c') {
      path.addOval(dst);
    } else {
      path.addRRect(RRect.fromRectAndRadius(dst, Radius.circular(r * 0.16)));
    }
    if (img != null) {
      x.save();
      x.clipPath(path);
      final iw = img!.width.toDouble(), ih = img!.height.toDouble(), s = math.min(iw, ih);
      x.drawImageRect(img!, Rect.fromLTWH((iw - s) / 2, (ih - s) / 2, s, s), dst, Paint()..filterQuality = FilterQuality.medium);
      x.restore();
    } else {
      x.drawPath(path, Paint()..color = const Color(0xFF0E5C46));
    }
    if (ring) {
      x.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, r * 0.018)
            ..color = ga(0.85));
    }
  }

  List<double> sym(int n) {
    final v = F.vals, m = v.length, o = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final p = i / n, q = p < 0.5 ? p * 2 : (1 - p) * 2, f = q * (m - 1), a = f.floor(), b = math.min(m - 1, a + 1);
      o[i] = v[a] + (v[b] - v[a]) * (f - a);
    }
    return o;
  }

  List<double> lin(int n) {
    final v = F.vals, m = v.length, o = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final f = i / (n - 1) * (m - 1), a = f.floor(), b = math.min(m - 1, a + 1);
      o[i] = v[a] + (v[b] - v[a]) * (f - a);
    }
    return o;
  }

  Paint stroke(Color c, double w, {StrokeCap cap = StrokeCap.butt}) => Paint()
    ..style = PaintingStyle.stroke
    ..color = c
    ..strokeWidth = w
    ..strokeCap = cap
    ..strokeJoin = StrokeJoin.round;
  Paint fill(Color c) => Paint()..color = c;

  @override
  void paint(Canvas canvas, Size size) {
    x = canvas;
    W = size.width;
    H = size.height;
    cx = W / 2;
    cy = H / 2;
    R = math.min(W * 0.33, H * 0.31) * scale;
    if (id == 'mihrab') R = math.min(W / 2.9, H / 3.1) * scale;
    u = math.max(1.0, R / 110);
    switch (id) {
      case 'strings':
        _strings();
      case 'halo':
        {
        final r = R * (1 + F.bass * 0.03);
        glow(cx, cy, r * 0.6, r * (1.7 + F.bass * 0.5), 0.1 + F.vol * 0.35);
        x.drawRRect(rr(cx - r * 1.08, cy - r * 1.08, r * 2.16, r * 2.16, r * 0.2), stroke(ga(0.25 + F.beat * 0.5), u * 2));
        cover(cx, cy, r, 'r');
        }
      case 'vinyl':
        _vinyl();
      case 'bars':
        {
        final r = R * 0.86, v = sym(72);
        glow(cx, cy, r, r * 1.9, 0.06 + F.bass * 0.18);
        for (var i = 0; i < 72; i++) {
          final a = -math.pi / 2 + i * tau / 72, l = r * (0.06 + v[i] * 0.55), r0 = r * 1.12;
          x.drawLine(Offset(cx + math.cos(a) * r0, cy + math.sin(a) * r0), Offset(cx + math.cos(a) * (r0 + l), cy + math.sin(a) * (r0 + l)), stroke(ga(0.45 + v[i] * 0.55), math.max(2.0, r * 0.035), cap: StrokeCap.round));
        }
        cover(cx, cy, r, 'c');
        }
      case 'blob':
        _blob();
      case 'wave':
        _wave();
      case 'spectrum':
        _spectrum();
      case 'orbit':
        _orbit();
      case 'pulse':
        _pulse();
      case 'star':
        _star();
      case 'dust':
        _dust();
      case 'candles':
        _candles();
      case 'neon':
        {
        final r = R * 0.86, e = r * 1.1, rad = r * 0.22, f = 0.6 + F.vol * 0.4 + F.beat * 0.3;
        for (final q in [(u * 14, 0.06), (u * 8, 0.12), (u * 4, 0.3)]) {
          x.drawRRect(rr(cx - e, cy - e, 2 * e, 2 * e, rad), stroke(ga(math.min(1.0, q.$2 * f * 1.6)), q.$1));
        }
        x.drawRRect(rr(cx - e, cy - e, 2 * e, 2 * e, rad), stroke(Color.fromRGBO(255, 240, 200, math.min(1.0, 0.7 * f + 0.2)), u * 1.6));
        cover(cx, cy, r, 'r', ring: false);
        }
      case 'cover':
        cover(cx, cy, R * 1.05, 'r');
      case 'ambient':
        _ambient();
      default:
        _mihrab();
    }
  }

  void _mihrab() {
    final r = R * 0.84, w = r * 2.3, h = r * 2.9, my = cy + r * 0.1, top = my - h * 0.5, bot = my + h * 0.5;
    Path arch(double sc) {
      final ww = w * sc, hh = h * sc, tp = my - hh * 0.5, bt = my + hh * 0.5, rr2 = ww / 2;
      return Path()
        ..moveTo(cx - rr2, bt)
        ..lineTo(cx - rr2, tp + rr2 * 0.95)
        ..cubicTo(cx - rr2, tp + rr2 * 0.2, cx - rr2 * 0.25, tp + rr2 * 0.05, cx, tp - rr2 * 0.32)
        ..cubicTo(cx + rr2 * 0.25, tp + rr2 * 0.05, cx + rr2, tp + rr2 * 0.2, cx + rr2, tp + rr2 * 0.95)
        ..lineTo(cx + rr2, bt);
    }

    x.drawPath(arch(1), Paint()..shader = ui.Gradient.linear(Offset(0, top), Offset(0, bot), [ga(0.16 + F.vol * 0.2), ga(0.02)]));
    x.drawPath(arch(1), stroke(ga(0.9), u * 1.8));
    x.drawPath(arch(1.07 + F.bass * 0.025), stroke(ga(0.3 + F.bass * 0.45), u));
    const n = 22;
    final vv = sym(n), bw = (w * 0.86) / n;
    for (var i = 0; i < n; i++) {
      final hh2 = math.max(u * 2, vv[i] * r * 0.5), px2 = cx - w * 0.43 + i * bw;
      x.drawRRect(rr(px2 + bw * 0.2, bot - hh2 - u * 4, bw * 0.6, hh2, bw * 0.3), fill(ga(0.55 + vv[i] * 0.45)));
    }
    cover(cx, my - r * 0.12, r * 0.8, 'r');
  }

  void _strings() {
    final r = R * 0.7;
    cover(cx, cy - r * 0.45, r, 'r');
    const n = 7;
    final top = cy + r * 0.75, gap = r * 0.13, w2 = math.min(W * 0.92, r * 3.6), x0 = cx - w2 / 2, v2 = lin(n);
    for (final bx in [x0, x0 + w2]) {
      x.drawRRect(rr(bx - u * 3, top - gap * 0.6, u * 6, gap * (n - 1) + gap * 1.2, u * 3), fill(ga(0.5)));
    }
    for (var s = 0; s < n; s++) {
      final y0 = top + s * gap, vv = v2[n - 1 - s], amp = vv * gap * 0.75, k = 1 + (s % 3), ph = t * (18 + s * 3);
      final p = Path();
      for (var i = 0; i <= 64; i++) {
        final f = i / 64, yy = y0 + math.sin(f * math.pi * k) * math.sin(ph) * amp * math.sin(f * math.pi);
        i == 0 ? p.moveTo(x0, yy) : p.lineTo(x0 + f * w2, yy);
      }
      x.drawPath(p, stroke(s % 2 == 1 ? ga(0.55 + vv * 0.45) : Color.fromRGBO(255, 248, 225, (0.45 + vv * 0.5).clamp(0.0, 1.0)), u * (0.8 + (n - s) * 0.18)));
    }
  }

  void _blob() {
    final r = R * 0.84;
    const n = 48;
    final v = sym(n), pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * tau / n, rr2 = r * (1.12 + v[i] * 0.42 + 0.03 * math.sin(t * 1.3 + i * 0.5));
      pts.add(Offset(cx + math.cos(a) * rr2, cy + math.sin(a) * rr2));
    }
    final p = Path();
    for (var i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
      if (i == 0) p.moveTo(p1.dx, p1.dy);
      p.cubicTo(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6, p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6, p2.dx, p2.dy);
    }
    p.close();
    x.drawPath(p, Paint()..shader = ui.Gradient.radial(Offset(cx, cy), r * 1.6, [ga(0.35), const Color(0x147FE0B5)], [0.625, 1]));
    x.drawPath(p, stroke(ga(0.9), u * 1.6));
    cover(cx, cy, r, 'c');
  }

  void _wave() {
    final r = R * 0.78;
    cover(cx, cy - r * 0.32, r, 'r');
    final w = F.wave, y0 = cy + r * 1.05, w2 = math.min(W * 0.9, r * 3.4), hh = r * 0.42;
    const n = 96;
    for (final q in [(ga(0.25), u * 6), (gold2, u * 2)]) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final f = i / (n - 1), v = w[(f * (w.length - 1)).floor()], env = math.sin(f * math.pi);
        final px = cx - w2 / 2 + f * w2, py = y0 + v * hh * 2.2 * env;
        i == 0 ? p.moveTo(px, py) : p.lineTo(px, py);
      }
      x.drawPath(p, stroke(q.$1, q.$2));
    }
  }

  void _spectrum() {
    final r = R * 0.72;
    cover(cx, cy - r * 0.42, r, 'r');
    const n = 32;
    final v = lin(n), w2 = math.min(W * 0.88, r * 3.3), bw = w2 / n * 0.62, base = cy + r * 1.35, hh = r * 0.85, s = st.peaks;
    final sh = ui.Gradient.linear(Offset(0, base - hh), Offset(0, base), [gold2, ga(0.55)]);
    for (var i = 0; i < n; i++) {
      final h = math.max(u * 3, v[i] * hh), px = cx - w2 / 2 + (i + 0.19) * (w2 / n);
      s[i] = math.max(v[i], s[i] - dt * 0.6);
      x.drawRRect(rr(px, base - h, bw, h, bw / 2), Paint()..shader = sh);
      x.drawRRect(rr(px, base + u * 3, bw, h * 0.35, bw / 2), fill(ga(0.13)));
      x.drawRect(Rect.fromLTWH(px, base - s[i] * hh - u * 5, bw, u * 2), fill(wa(0.85)));
    }
  }

  void _orbit() {
    final r = R * 0.8;
    glow(cx, cy, r, r * 1.8, 0.05 + F.vol * 0.15);
    final o = [(1.25, 0.4, 'bass', 7), (1.5, -0.27, 'mid', 11), (1.78, 0.19, 'hi', 16)];
    for (var j = 0; j < 3; j++) {
      final (k, sp, b, m) = o[j];
      final rad = r * (k + F[b] * 0.08);
      x.drawCircle(Offset(cx, cy), rad, stroke(ga(0.12 + F[b] * 0.25), u));
      for (var i = 0; i < m; i++) {
        final a = t * sp + i * tau / m + j, sz = u * (2 + F[b] * 5) * (i % 3 != 0 ? 1 : 1.6);
        x.drawCircle(Offset(cx + math.cos(a) * rad, cy + math.sin(a) * rad), sz, fill(i % 4 != 0 ? ga(0.6 + F[b] * 0.4) : const Color(0xD97FE0B5)));
      }
    }
    cover(cx, cy, r, 'c');
  }

  void _pulse() {
    final r = R * 0.84;
    if (F.beat > 0.45 && t - st.lastBeat > 0.18) {
      st.rings.add((t: t, a: math.min(1.0, F.beat)));
      st.lastBeat = t;
    }
    st.rings.removeWhere((o) => t - o.t >= 1.6);
    for (final o in st.rings) {
      final p = (t - o.t) / 1.6;
      x.drawCircle(Offset(cx, cy), r * (1.05 + p * 0.95), stroke(ga((1 - p) * 0.75 * o.a), u * (1 + (1 - p) * 4)));
    }
    glow(cx, cy, r * 0.9, r * 1.35, 0.1 + F.bass * 0.35);
    cover(cx, cy, r * (1 + F.bass * 0.035), 'c');
  }

  void _star() {
    final r = R * 0.74;
    glow(cx, cy, r, r * 1.9, 0.06 + F.bass * 0.2);
    Path star(double rad, double a0) {
      final p = Path();
      for (var sq = 0; sq < 2; sq++) {
        for (var i = 0; i <= 4; i++) {
          final a = a0 + sq * math.pi / 4 + i * math.pi / 2;
          final px = cx + math.cos(a) * rad, py = cy + math.sin(a) * rad;
          i == 0 ? p.moveTo(px, py) : p.lineTo(px, py);
        }
      }
      return p;
    }

    for (final q in [(1.45 + F.bass * 0.12, t * 0.05, 0.9, 1.6), (1.7 + F.mid * 0.1, -t * 0.035, 0.45, 1.0), (1.98 + F.hi * 0.1, t * 0.02, 0.22, 1.0)]) {
      x.drawPath(star(r * q.$1, q.$2 + math.pi / 4), stroke(ga(q.$3), u * q.$4));
    }
    cover(cx, cy, r, 'c');
  }

  static final _rnd = math.Random();
  void _dust() {
    final r = R * 0.84;
    final em = ((paused ? 0 : 1) * (1 + F.vol * 5 + F.beat * 8)).round();
    for (var i = 0; i < em; i++) {
      st.dust.add(_P(_rnd.nextDouble() * tau, r * 1.02, r * (0.25 + _rnd.nextDouble() * 0.6) * (0.6 + F.vol), 1, 0.6 + _rnd.nextDouble() * 1.4, _rnd.nextDouble() < 0.25));
    }
    if (st.dust.length > 260) st.dust.removeRange(0, st.dust.length - 260);
    glow(cx, cy, r, r * 1.6, 0.05 + F.bass * 0.18);
    for (final o in st.dust) {
      o.r += o.v * dt;
      o.l -= dt * 0.55;
      if (o.l <= 0) continue;
      x.drawCircle(Offset(cx + math.cos(o.a) * o.r, cy + math.sin(o.a) * o.r), u * o.z * (0.6 + o.l), fill(o.w ? wa(o.l * 0.8) : ga(o.l)));
    }
    st.dust.removeWhere((o) => o.l <= 0);
    cover(cx, cy, r, 'c');
  }

  void _candles() {
    final r = R * 0.74;
    cover(cx, cy - r * 0.28, r, 'r');
    const n = 5;
    final base = cy + r * 1.55, gap = r * 0.5, v2 = lin(n);
    for (var i = 0; i < n; i++) {
      final px = cx + (i - (n - 1) / 2) * gap, ch = r * (0.32 + (i % 2 == 1 ? 0.1 : 0.2) - (i - 2).abs() * 0.05), cw = r * 0.15, fl = 0.55 + v2[i] * 0.9 + 0.08 * math.sin(t * 13 + i * 2.1);
      glow(px, base - ch - r * 0.08, r * 0.01, r * (0.22 + fl * 0.22), 0.18 + fl * 0.18);
      x.drawRRect(rr(px - cw / 2, base - ch, cw, ch, cw * 0.2), Paint()..shader = ui.Gradient.linear(Offset(px - cw / 2, 0), Offset(px + cw / 2, 0), const [Color(0xFFD9CCB0), Color(0xFFFBF3DF), Color(0xFFC9B994)], const [0, 0.5, 1]));
      final fh = r * 0.16 * fl, sway = math.sin(t * 7 + i) * r * 0.012;
      x.save();
      x.translate(px + sway, base - ch - r * 0.015);
      final p = Path()
        ..moveTo(0, 0)
        ..cubicTo(fh * 0.32, -fh * 0.25, fh * 0.12, -fh * 0.7, 0, -fh)
        ..cubicTo(-fh * 0.12, -fh * 0.7, -fh * 0.32, -fh * 0.25, 0, 0);
      x.drawPath(p, Paint()..shader = ui.Gradient.radial(Offset(0, -fh * 0.35), math.max(0.1, fh * 0.6), const [Color(0xFFFFFBE8), Color(0xFFFFD36B), Color(0x00FF8C28)], const [0, 0.45, 1]));
      x.restore();
    }
    x.drawRect(Rect.fromLTWH(cx - gap * 2.6, base, gap * 5.2, u * 1.5), fill(ga(0.35)));
  }

  /// أجواء — مثل drawAmbient في الويب: بقع لونية، أشعة دوّارة، هالة تتنفس، جزيئات صاعدة
  void _ambient() {
    st.ab += (F.bass - st.ab) * 0.06;
    st.av += (F.vol - st.av) * 0.06;
    st.am += (F.mid - st.am) * 0.06;
    final rr = R * 1.12, L = math.sqrt(W * W + H * H) * 1.3;
    for (final (i, b) in [(0, [0.2, 0.15, 0.7, 0.27]), (1, [0.85, 0.7, 0.65, 0.21])]) {
      final bx = W * (b[0] + 0.08 * math.sin(t * b[3] * 0.5 + i * 2)), by = H * (b[1] + 0.06 * math.cos(t * b[3] * 0.4 + i)), rad = math.max(W, H) * b[2];
      final c = i == 0 ? const Color(0xFF1A8A68) : const Color(0xFF146E54);
      x.drawCircle(Offset(bx, by), rad, Paint()..shader = ui.Gradient.radial(Offset(bx, by), rad, [c.withOpacity(0.18 + st.av * 0.08), c.withOpacity(0)]));
    }
    x.save();
    x.translate(cx, cy);
    x.rotate(t * 0.02);
    final ra = (0.07 + st.am * 0.09).clamp(0.0, 1.0);
    for (var i = 0; i < 18; i++) {
      final a0 = i * tau / 18, w = 0.05;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a0 - w) * L, math.sin(a0 - w) * L)
        ..lineTo(math.cos(a0 + w) * L, math.sin(a0 + w) * L)
        ..close();
      x.drawPath(path, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(math.cos(a0) * L * 0.6, math.sin(a0) * L * 0.6), [gold.withOpacity(ra), gold.withOpacity(0)]));
    }
    x.restore();
    final hr = rr * (1.25 + st.ab * 0.18);
    x.drawCircle(Offset(cx, cy), hr * 1.6, Paint()..shader = ui.Gradient.radial(Offset(cx, cy), hr * 1.6, [ga(0.16 + st.ab * 0.22), ga(0)], [(rr * 0.85 / (hr * 1.6)).clamp(0.0, 1.0), 1]));
    x.drawCircle(Offset(cx, cy), rr * (1.12 + st.ab * 0.08), stroke(gold2.withOpacity((0.12 + st.ab * 0.3).clamp(0.0, 1.0)), math.max(1.0, u)));
    final rnd = math.Random();
    if (st.aps.isEmpty) {
      for (var i = 0; i < 34; i++) {
        st.aps.add([rnd.nextDouble(), rnd.nextDouble(), 0.5 + rnd.nextDouble(), i.toDouble()]);
      }
    }
    for (final q in st.aps) {
      q[1] -= (0.0005 + st.av * 0.0012) * q[2] * (dt / 0.016);
      if (q[1] < -0.02) {
        q[1] = 1.02;
        q[0] = rnd.nextDouble();
      }
      final px = (q[0] + 0.02 * math.sin(t * 0.4 + q[3])) * W;
      x.drawCircle(Offset(px, q[1] * H), (0.7 + q[2] * 1.2) * math.min(W, H) / 300, Paint()..color = gold2.withOpacity((0.1 + 0.22 * q[2] * (0.4 + st.av)).clamp(0.0, 1.0)));
    }
    cover(cx, cy, rr, 'c');
  }

  void _vinyl() {
    final on = paused ? 0.0 : 1.0;
    st.vw += (on * 1.15 - st.vw) * math.min(1.0, dt * 1.8);
    if (!st.vdrag) st.va += st.vw * dt;
    st.arm += (on - st.arm) * math.min(1.0, dt * 2.6);
    final r = R * 1.18, vx = cx - r * 0.06, vy = cy + r * 0.04;
    glow(vx, vy, r * 0.9, r * 1.45, 0.05 + F.bass * 0.22);
    x.save();
    x.translate(vx, vy);
    x.rotate(st.va);
    x.drawCircle(Offset.zero, r, Paint()..shader = ui.Gradient.radial(Offset.zero, r, const [Color(0xFF141617), Color(0xFF0B0C0D), Color(0xFF202325)], const [0.6, 0.92, 1]));
    for (var rd = r * 0.64; rd < r * 0.97; rd += math.max(1.5, r / 90)) {
      x.drawCircle(Offset.zero, rd, stroke(Colors.white.withOpacity(0.018 + 0.02 * math.pow(math.sin(rd * 0.7), 2).toDouble()), 1));
    }
    x.drawCircle(Offset.zero, r * 0.635, stroke(Colors.white.withOpacity(0.08), math.max(1.0, r * 0.012)));
    if (img != null) {
      x.save();
      x.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.62)));
      final iw = img!.width.toDouble(), ih = img!.height.toDouble(), s = math.min(iw, ih);
      x.drawImageRect(img!, Rect.fromLTWH((iw - s) / 2, (ih - s) / 2, s, s), Rect.fromCircle(center: Offset.zero, radius: r * 0.62), Paint()..filterQuality = FilterQuality.medium);
      x.restore();
    }
    x.restore();
    x.drawCircle(Offset(vx, vy), r * 0.045, Paint()..shader = ui.Gradient.radial(Offset(vx, vy), r * 0.05, const [Color(0xFFF4F4F4), Color(0xFF8A8F93)]));
    // الذراع
    final px = vx + r * 1.0, py = vy - r * 1.08, th = (78 + (121 - 78) * st.arm) * math.pi / 180, al = r * 0.64;
    x.save();
    x.translate(px, py);
    x.drawRRect(rr(-r * 0.17, -r * 0.17, r * 0.34, r * 0.34, r * 0.08), Paint()..shader = ui.Gradient.linear(Offset(0, -r * 0.17), Offset(0, r * 0.17), const [Color(0xFF3A3E42), Color(0xFF5B6166), Color(0xFF4A4F53), Color(0xFF25282B)], const [0, 0.45, 0.55, 1]));
    x.drawCircle(Offset.zero, r * 0.12, Paint()..shader = ui.Gradient.radial(Offset(-r * 0.03, -r * 0.03), r * 0.12, const [Color(0xFF9AA1A6), Color(0xFF2D3134)]));
    x.rotate(th);
    final arm = Path()
      ..moveTo(-r * 0.16, 0)
      ..lineTo(0, 0)
      ..cubicTo(al * 0.45, -r * 0.05, al * 0.68, r * 0.09, al * 0.93, r * 0.045);
    x.drawRRect(rr(-r * 0.36, -r * 0.085, r * 0.17, r * 0.17, r * 0.025), Paint()..shader = ui.Gradient.linear(Offset(0, -r * 0.085), Offset(0, r * 0.085), const [Color(0xFF55595D), Color(0xFFE6E9EB), Color(0xFFB9BEC2), Color(0xFF3F4346)], const [0, 0.45, 0.55, 1]));
    x.drawPath(arm, stroke(const Color(0xFF4B5155), r * 0.034, cap: StrokeCap.round));
    x.drawPath(arm, stroke(const Color(0xFFC3C8CC), r * 0.024, cap: StrokeCap.round));
    x.save();
    x.translate(al * 0.93, r * 0.045);
    x.rotate(0.38);
    final hd = Path()
      ..moveTo(0, -r * 0.032)
      ..lineTo(r * 0.19, -r * 0.048)
      ..quadraticBezierTo(r * 0.21, 0, r * 0.2, r * 0.05)
      ..lineTo(0, r * 0.032)
      ..close();
    x.drawPath(hd, fill(const Color(0xFFD4D8DB)));
    x.drawRect(Rect.fromLTWH(r * 0.07, -r * 0.03, r * 0.105, r * 0.06), fill(const Color(0xFF141516)));
    x.drawRect(Rect.fromLTWH(r * 0.07, -r * 0.03, r * 0.012, r * 0.06), fill(gold));
    x.restore();
    x.drawCircle(Offset.zero, r * 0.07, Paint()..shader = ui.Gradient.radial(Offset(-r * 0.02, -r * 0.025), r * 0.075, const [Color(0xFFFBFBFB), Color(0xFFA9AFB3), Color(0xFF585E62)], const [0, 0.6, 1]));
    x.drawCircle(Offset.zero, r * 0.022, fill(const Color(0xFF1D1F21)));
    x.restore();
  }

  @override
  bool shouldRepaint(covariant VizPainter o) => true;
}
