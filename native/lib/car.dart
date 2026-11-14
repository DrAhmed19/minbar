import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'data.dart';
import 'lyrics.dart';
import 'state.dart';
import 'ui.dart';

/// وضع السيارة: لوحة قيادة حيّة — طريق يتحرك مع سرعة السيارة الحقيقية (GPS)،
/// سيارة تضيء فراملها عند التوقف، عدّاد سرعة، ساعة، قرص الغلاف، كلمات، وأزرار كبيرة.

/// حالة المشهد (تتحدّث كل إطار بدون إعادة بناء الصفحة)
class _Scene {
  double phase = 0; // تقدّم الطريق
  double spin = 0; // دوران قرص الغلاف
  double v = 0; // سرعة الحركة المعروضة (0..1.6) بعد التنعيم
  double kmh = 0; // السرعة المعروضة بعد التنعيم
  double brake = 0; // شدة ضوء الفرامل
  double sway = 0;
}

class CarPage extends StatefulWidget {
  const CarPage({super.key});
  @override
  State<CarPage> createState() => _CarPageState();
}

class _CarPageState extends State<CarPage> with SingleTickerProviderStateMixin {
  List<Lyric> ly = const [];
  String? _id;
  final _sc = _Scene();
  final _frame = ValueNotifier<int>(0);
  final _clock = ValueNotifier<DateTime>(DateTime.now());
  late final Ticker _tk;
  Duration _last = Duration.zero;
  Timer? _ct;
  StreamSubscription<Position>? _gs;
  bool gps = false, night = false;
  double _gpsKmh = 0, _trip = 0, _max = 0;
  Position? _lp;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    app.player.addListener(_r);
    _r();
    _tk = createTicker(_tick)..start();
    _ct = Timer.periodic(const Duration(seconds: 1), (_) => _clock.value = DateTime.now());
    SharedPreferences.getInstance().then((p) {
      if (p.getBool('car.gps') ?? false) _gpsOn(ask: false);
    });
  }

  void _tick(Duration e) {
    final dt = ((e - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = e;
    final playing = app.player.p.playing;
    // مع GPS: الطريق يتبع السرعة الحقيقية. بدونه: يتحرك مع التشغيل ويتوقف مع الإيقاف
    final double target = gps ? (_gpsKmh / 70).clamp(0.0, 1.6).toDouble() : (playing ? 0.8 : 0.0);
    _sc.v += (target - _sc.v) * math.min(1, dt * 1.6);
    _sc.kmh += (_gpsKmh - _sc.kmh) * math.min(1, dt * 3);
    final stopped = gps ? _gpsKmh < 2 : !playing;
    _sc.brake += ((stopped ? 1.0 : 0.0) - _sc.brake) * math.min(1, dt * 5);
    _sc.phase += dt * _sc.v * 1.5;
    _sc.sway += dt * (0.6 + _sc.v);
    if (playing) _sc.spin += dt * 0.9;
    _frame.value++;
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
        if (ask) _say('ما انطت صلاحية الموقع — السرعة تحتاجها');
        return;
      }
      await _gs?.cancel();
      _gs = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation)).listen((pos) {
        var k = pos.speed.isFinite ? pos.speed * 3.6 : 0.0;
        if (k < 2) k = 0;
        _gpsKmh = k;
        if (k > _max) _max = k;
        final lp = _lp;
        if (lp != null && k > 0) _trip += Geolocator.distanceBetween(lp.latitude, lp.longitude, pos.latitude, pos.longitude);
        _lp = pos;
      }, onError: (_) {});
      if (mounted) setState(() => gps = true);
      (await SharedPreferences.getInstance()).setBool('car.gps', true);
    } catch (_) {
      if (ask) _say('تعذّر تشغيل عدّاد السرعة');
    }
  }

  Future<void> _gpsOff() async {
    await _gs?.cancel();
    _gs = null;
    _gpsKmh = 0;
    if (mounted) setState(() => gps = false);
    (await SharedPreferences.getInstance()).setBool('car.gps', false);
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: tx(14, c: Colors.white)), duration: const Duration(seconds: 3)));
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
    WakelockPlus.disable();
    app.player.removeListener(_r);
    _tk.dispose();
    _ct?.cancel();
    _gs?.cancel();
    _frame.dispose();
    _clock.dispose();
    super.dispose();
  }

  // ---------- عناصر ----------
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
            color: main ? null : (on ? const Color(0x33E8C468) : const Color(0x1AFFFFFF)),
            border: Border.all(color: main ? kGold2 : (on ? kGold : const Color(0x33FFFFFF)), width: 1.6),
            boxShadow: main ? const [BoxShadow(color: Color(0x66E8C468), blurRadius: 26)] : null,
          ),
          child: Center(child: PIcon(ic, color: main ? const Color(0xFF2A2106) : (on ? kGold : Colors.white), size: s * 0.44)),
        ),
      );

  static const _days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _top() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 14, 0),
        child: Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const PIcon(Ic.x, color: Colors.white70, size: 26)),
          IconButton(onPressed: () => setState(() => night = !night), icon: PIcon(Ic.moon, color: night ? kGold : Colors.white54, size: 22)),
          const Spacer(),
          ValueListenableBuilder<DateTime>(
            valueListenable: _clock,
            builder: (_, d, __) => Row(children: [
              Text('${_days[d.weekday - 1]} ${d.day}/${d.month}', style: tx(13, c: Colors.white54)),
              const SizedBox(width: 10),
              Directionality(textDirection: TextDirection.ltr, child: Text('${_two(d.hour)}:${_two(d.minute)}', style: tx(26, c: Colors.white).copyWith(fontFeatures: const [FontFeature.tabularFigures()]))),
            ]),
          ),
        ]),
      );

  /// عدّاد السرعة: اضغطه لتشغيل/إيقاف السرعة الحقيقية
  Widget _speedo(double s) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          gps ? _gpsOff() : _gpsOn();
        },
        child: SizedBox(
          width: s,
          height: s,
          child: AnimatedBuilder(
            animation: _frame,
            builder: (_, __) => CustomPaint(
              painter: _GaugePainter(gps ? _sc.kmh : 0, gps),
              child: Center(
                child: gps
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${_sc.kmh.round()}', style: tx(s * 0.3, c: _sc.kmh > 120 ? const Color(0xFFFF6B6B) : Colors.white, h: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                        Text('كم/س', style: tx(s * 0.1, c: Colors.white54, h: 1.2)),
                        if (_trip > 100) Text('${(_trip / 1000).toStringAsFixed(1)} كم', style: tx(s * 0.085, c: kGold, h: 1.4)),
                      ])
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        PIcon(Ic.speed, color: kGold, size: s * 0.26),
                        Text('اضغط للسرعة', style: tx(s * 0.095, c: Colors.white60, h: 1.5)),
                      ]),
              ),
            ),
          ),
        ),
      );

  /// قرص الغلاف يدور مع التشغيل
  Widget _disc(Track? t, double s) => SizedBox(
        width: s,
        height: s,
        child: AnimatedBuilder(
          animation: _frame,
          builder: (_, child) => Transform.rotate(angle: _sc.spin, child: child),
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x66E8C468), width: 2), boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 14)]),
            child: Stack(alignment: Alignment.center, children: [
              ClipOval(child: Cover(t?.coverUrl ?? '', size: s - 4, radius: 0)),
              Container(width: s * 0.16, height: s * 0.16, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF04140F), border: Border.all(color: kGold, width: 1.5))),
            ]),
          ),
        ),
      );

  Widget _scene(Track? t) => LayoutBuilder(builder: (_, c) {
        final g = math.min(c.maxWidth * 0.3, c.maxHeight * 0.46).clamp(72.0, 150.0).toDouble();
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(children: [
            Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _RoadPainter(_sc, _frame)))),
            Positioned(left: 10, top: 10, child: Directionality(textDirection: TextDirection.rtl, child: _speedo(g))),
            Positioned(right: 10, top: 10, child: _disc(t, g)),
          ]),
        );
      });

  Widget _title(Track? t, {double big = 26}) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t?.title ?? 'اختر قصيدة', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: tx(big, c: Colors.white, h: 1.4)),
        Text(t?.reciter ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(big * 0.6, c: kGold)),
      ]);

  String _fmt(Duration d) => '${d.inMinutes}:${_two(d.inSeconds % 60)}';

  Widget _progress() => StreamBuilder<Duration>(
        stream: app.player.p.positionStream,
        builder: (_, s) {
          final pos = s.data ?? Duration.zero, dur = app.player.p.duration ?? Duration.zero;
          final f = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0).toDouble() : 0.0;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              Text(_fmt(pos), style: tx(12, c: Colors.white54)),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      if (dur.inMilliseconds > 0) app.player.seek(dur.inMilliseconds / 1000 * (d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: f, minHeight: 6, backgroundColor: const Color(0x22FFFFFF), valueColor: const AlwaysStoppedAnimation(kGold))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_fmt(dur), style: tx(12, c: Colors.white54)),
            ]),
          );
        },
      );

  Widget _controls(Track? t, double u) {
    final pc = app.player;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _btn(Ic.prev, pc.prev, s: u),
          StreamBuilder<PlayerState>(stream: pc.p.playerStateStream, builder: (_, s) => _btn((s.data?.playing ?? false) ? Ic.pause : Ic.play, pc.toggle, s: u * 1.35, main: true)),
          _btn(Ic.next, pc.next, s: u),
        ]),
      ),
      SizedBox(height: u * 0.2),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _btn(Ic.rw, () => pc.seek((pc.p.position.inSeconds - 15).clamp(0, 1 << 30).toDouble()), s: u * 0.68),
          _btn(t != null && app.repo.isFav(t.id) ? Ic.heartF : Ic.heart, () {
            if (t != null) app.repo.toggleFav(t.id);
            setState(() {});
          }, s: u * 0.68, on: t != null && app.repo.isFav(t.id)),
          _btn(Ic.shuf, pc.toggleShuffle, s: u * 0.68, on: pc.shuffle),
          _btn(Ic.fw, () => pc.seek(pc.p.position.inSeconds + 15.0), s: u * 0.68),
        ]),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = app.player.cur;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF020B08),
        body: SafeArea(
          child: Stack(children: [
            LayoutBuilder(builder: (_, c) {
              final land = c.maxWidth > c.maxHeight * 1.15;
              if (land) {
                final u = (c.maxHeight * 0.19).clamp(54.0, 92.0).toDouble();
                return Row(children: [
                  Expanded(flex: 11, child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 6, 10), child: _scene(t))),
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 12, 8),
                      child: Column(children: [
                        _top(),
                        const Spacer(),
                        _title(t, big: 22),
                        if (ly.isNotEmpty) SizedBox(height: (c.maxHeight * 0.2).clamp(54.0, 96.0).toDouble(), child: LyricStrip(lines: ly, base: 20)),
                        _progress(),
                        _controls(t, u),
                      ]),
                    ),
                  ),
                ]);
              }
              final u = (c.maxWidth * 0.21).clamp(64.0, 96.0).toDouble();
              return Column(children: [
                _top(),
                Expanded(flex: 10, child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 6), child: _scene(t))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _title(t)),
                SizedBox(height: (c.maxHeight * 0.13).clamp(64.0, 120.0).toDouble(), child: ly.isEmpty ? const SizedBox() : LyricStrip(lines: ly, base: 24)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _progress()),
                _controls(t, u),
                SizedBox(height: (c.maxHeight * 0.025).clamp(8.0, 24.0).toDouble()),
              ]);
            }),
            // الوضع الليلي: تعتيم خفيف يريّح العين بالليل
            if (night) const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x8C000000)))),
          ]),
        ),
      ),
    );
  }
}

/// عدّاد دائري: قوس ذهبي يمتلئ مع السرعة (حتى 160)
class _GaugePainter extends CustomPainter {
  final double kmh;
  final bool on;
  _GaugePainter(this.kmh, this.on);
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero), r = s.width / 2 - 5;
    c.drawCircle(ctr, r + 4, Paint()..color = const Color(0xB3020B08));
    const a0 = math.pi * 0.75, sw = math.pi * 1.5;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x26FFFFFF);
    c.drawArc(Rect.fromCircle(center: ctr, radius: r), a0, sw, false, bg);
    for (int i = 0; i <= 8; i++) {
      final a = a0 + sw * i / 8, d = Offset(math.cos(a), math.sin(a));
      c.drawLine(ctr + d * (r - 9), ctr + d * (r - 4), Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1.4);
    }
    if (!on) return;
    final f = (kmh / 160).clamp(0.0, 1.0).toDouble();
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(startAngle: 0, endAngle: math.pi * 2, colors: const [kGold, kGold2, Color(0xFFFF6B6B)], stops: const [0, 0.6, 1], transform: const GradientRotation(a0)).createShader(Rect.fromCircle(center: ctr, radius: r));
    c.drawArc(Rect.fromCircle(center: ctr, radius: r), a0, sw * f, false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.kmh != kmh || o.on != on;
}

/// المشهد: سماء ليلية، أفق بقباب ومنارات، طريق بمنظور يتحرك، وسيارة من الخلف
class _RoadPainter extends CustomPainter {
  final _Scene sc;
  _RoadPainter(this.sc, Listenable r) : super(repaint: r);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, hz = h * 0.44, cx = w / 2;
    // السماء
    c.drawRect(Offset.zero & s, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF020B08), Color(0xFF07261C), Color(0xFF0E4636)], stops: [0, 0.3, 0.46]).createShader(Offset.zero & s));
    // نجوم ثابتة تومض بهدوء
    final rnd = math.Random(7);
    for (int i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * w, y = rnd.nextDouble() * hz * 0.8, tw = 0.35 + 0.35 * math.sin(sc.sway * 0.8 + i * 1.7);
      c.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 0.9, Paint()..color = Colors.white.withOpacity(tw.clamp(0.1, 0.8).toDouble()));
    }
    // وهج الأفق
    c.drawRect(Rect.fromLTRB(0, hz - h * 0.2, w, hz + 2), Paint()..shader = RadialGradient(center: Alignment.bottomCenter, radius: 0.9, colors: [const Color(0x80E8C468), const Color(0x00E8C468)]).createShader(Rect.fromLTRB(0, hz - h * 0.2, w, hz + 2)));
    // أفق المدينة: قباب ومنارات
    final sk = Path()..moveTo(0, hz);
    final u = w / 24;
    void dome(double x, double r) {
      sk.lineTo(x - r, hz);
      sk.lineTo(x - r, hz - r * 0.5);
      sk.quadraticBezierTo(x - r, hz - r * 1.5, x, hz - r * 1.9);
      sk.quadraticBezierTo(x + r, hz - r * 1.5, x + r, hz - r * 0.5);
      sk.lineTo(x + r, hz);
    }
    void minaret(double x, double hh) {
      final m = u * 0.22;
      sk.lineTo(x - m, hz);
      sk.lineTo(x - m, hz - hh);
      sk.lineTo(x, hz - hh - m * 3);
      sk.lineTo(x + m, hz - hh);
      sk.lineTo(x + m, hz);
    }
    void block(double x, double bw, double bh) {
      sk.lineTo(x, hz);
      sk.lineTo(x, hz - bh);
      sk.lineTo(x + bw, hz - bh);
      sk.lineTo(x + bw, hz);
    }
    block(u * 0.5, u * 1.6, u * 0.9);
    minaret(u * 3.2, u * 2.6);
    dome(u * 5, u * 1.2);
    minaret(u * 6.8, u * 2.6);
    block(u * 7.6, u * 2, u * 0.7);
    block(u * 14.2, u * 1.8, u * 0.8);
    minaret(u * 17, u * 3.2);
    dome(u * 19, u * 1.5);
    minaret(u * 21, u * 3.2);
    block(u * 21.8, u * 1.8, u * 1);
    sk.lineTo(w, hz);
    sk.close();
    c.drawPath(sk, Paint()..color = const Color(0xFF031510));
    // الأرض
    c.drawRect(Rect.fromLTRB(0, hz, w, h), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF06221A), Color(0xFF020B08)]).createShader(Rect.fromLTRB(0, hz, w, h)));
    // الطريق
    final top = w * 0.035, bot = w * 0.62;
    final road = Path()
      ..moveTo(cx - top, hz)
      ..lineTo(cx + top, hz)
      ..lineTo(cx + bot, h)
      ..lineTo(cx - bot, h)
      ..close();
    c.drawPath(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B1512), Color(0xFF1A2622)]).createShader(Rect.fromLTRB(0, hz, w, h)));
    double py(double z) => hz + (h - hz) * z * z; // z: 0 الأفق … 1 القريب
    double pw(double z) => top + (bot - top) * z * z;
    // حافتا الطريق المضيئتان
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33E8C468), kGold]).createShader(Rect.fromLTRB(0, hz, w, h))
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    c.drawLine(Offset(cx - top, hz), Offset(cx - bot, h), edge);
    c.drawLine(Offset(cx + top, hz), Offset(cx + bot, h), edge);
    // خطوط المسار وأعمدة الإنارة تتحرك نحونا
    const n = 9;
    final ph = sc.phase % 1;
    for (int k = 0; k < n; k++) {
      final z0 = (k + ph) / n, z1 = math.min(1.0, z0 + 0.45 / n);
      if (z0 <= 0.02) continue;
      final y0 = py(z0), y1 = py(z1), a = (z0 * 1.6).clamp(0.0, 1.0).toDouble();
      final lw0 = pw(z0) * 0.035, lw1 = pw(z1) * 0.035;
      c.drawPath(
          Path()
            ..moveTo(cx - lw0, y0)
            ..lineTo(cx + lw0, y0)
            ..lineTo(cx + lw1, y1)
            ..lineTo(cx - lw1, y1)
            ..close(),
          Paint()..color = Colors.white.withOpacity(0.75 * a));
      // أعمدة إنارة على الجانبين
      for (final sd in const [-1.0, 1.0]) {
        final x = cx + sd * pw(z0) * 1.18, ph2 = (h - hz) * 0.5 * z0 * z0 + 3;
        c.drawLine(Offset(x, y0), Offset(x, y0 - ph2), Paint()..color = Color.fromRGBO(120, 150, 138, 0.6 * a)..strokeWidth = 1 + 2 * z0);
        c.drawCircle(Offset(x, y0 - ph2), 1.5 + 5 * z0 * z0, Paint()..color = kGold2.withOpacity(0.9 * a)..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 6 * z0));
      }
    }
    // السيارة (من الخلف) — تهتز بخفة مع الحركة
    final cw = math.min(w * 0.3, (h - hz) * 0.62), chh = cw * 0.62;
    final bob = math.sin(sc.sway * 9) * 0.6 * sc.v, sx = math.sin(sc.sway * 0.7) * w * 0.012 * sc.v;
    final ox = cx + sx, by = h - (h - hz) * 0.1 + bob; // أسفل العجلات
    // ظل
    c.drawOval(Rect.fromCenter(center: Offset(ox, by), width: cw * 1.15, height: chh * 0.22), Paint()..color = const Color(0x99000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // العجلات
    final wh = Paint()..color = const Color(0xFF050807);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ox - cw * 0.47, by - chh * 0.26, cw * 0.17, chh * 0.26), const Radius.circular(4)), wh);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ox + cw * 0.30, by - chh * 0.26, cw * 0.17, chh * 0.26), const Radius.circular(4)), wh);
    // الهيكل
    final body = RRect.fromRectAndCorners(Rect.fromLTWH(ox - cw / 2, by - chh * 0.62, cw, chh * 0.5), topLeft: Radius.circular(cw * 0.12), topRight: Radius.circular(cw * 0.12), bottomLeft: Radius.circular(cw * 0.05), bottomRight: Radius.circular(cw * 0.05));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C6B55), Color(0xFF0A3B2D), Color(0xFF052016)]).createShader(body.outerRect));
    // المقصورة والزجاج الخلفي
    final cab = Path()
      ..moveTo(ox - cw * 0.40, by - chh * 0.60)
      ..quadraticBezierTo(ox - cw * 0.34, by - chh * 0.98, ox - cw * 0.24, by - chh)
      ..lineTo(ox + cw * 0.24, by - chh)
      ..quadraticBezierTo(ox + cw * 0.34, by - chh * 0.98, ox + cw * 0.40, by - chh * 0.60)
      ..close();
    c.drawPath(cab, Paint()..color = const Color(0xFF0C4A39));
    final glass = Path()
      ..moveTo(ox - cw * 0.33, by - chh * 0.64)
      ..quadraticBezierTo(ox - cw * 0.29, by - chh * 0.92, ox - cw * 0.22, by - chh * 0.93)
      ..lineTo(ox + cw * 0.22, by - chh * 0.93)
      ..quadraticBezierTo(ox + cw * 0.29, by - chh * 0.92, ox + cw * 0.33, by - chh * 0.64)
      ..close();
    c.drawPath(glass, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF244E44), Color(0xFF07130F)]).createShader(glass.getBounds()));
    // خط ذهبي ولوحة
    c.drawLine(Offset(ox - cw * 0.46, by - chh * 0.36), Offset(ox + cw * 0.46, by - chh * 0.36), Paint()..color = const Color(0x99E8C468)..strokeWidth = 1.2);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(ox, by - chh * 0.24), width: cw * 0.24, height: chh * 0.1), const Radius.circular(2)), Paint()..color = const Color(0xFFE9E4D4));
    // الأضواء الخلفية: تتوهج أقوى عند التوقف (فرامل)
    final br = sc.brake, lc = Color.lerp(const Color(0xFFB3261E), const Color(0xFFFF3B30), br)!;
    for (final sd in const [-1.0, 1.0]) {
      final r = Rect.fromCenter(center: Offset(ox + sd * cw * 0.36, by - chh * 0.47), width: cw * 0.2, height: chh * 0.1);
      c.drawRRect(RRect.fromRectAndRadius(r.inflate(2 + 6 * br), const Radius.circular(8)), Paint()..color = lc.withOpacity(0.35 + 0.45 * br)..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 12 * br));
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = lc);
    }
    // انعكاس الأضواء على الطريق
    c.drawOval(Rect.fromCenter(center: Offset(ox, by + chh * 0.05), width: cw * 0.9, height: chh * 0.12), Paint()..color = lc.withOpacity(0.12 + 0.2 * br)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }

  @override
  bool shouldRepaint(covariant _RoadPainter o) => false;
}
