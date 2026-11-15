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

  /// عدّاد السرعة بوسط السماء: اضغطه لتشغيل/إيقاف السرعة الحقيقية (GPS)
  Widget _speedo(double g) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          gps ? _gpsOff() : _gpsOn();
        },
        child: SizedBox(
          width: g,
          height: g * 0.72,
          child: AnimatedBuilder(
            animation: _frame,
            builder: (_, __) {
              final k = gps ? _sc.kmh : 0.0, hot = k > 120;
              final col = !gps ? Colors.white38 : (hot ? const Color(0xFFFF5A64) : Colors.white);
              return CustomPaint(
                painter: _GaugePainter(k, gps),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: g * 0.17),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('${k.round()}',
                            style: tx(g * 0.27, c: col, h: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()], shadows: gps ? [Shadow(color: hot ? const Color(0xFFFF5A64) : _RoadPainter.neon, blurRadius: 18)] : null)),
                      ),
                      Text('كم/س', style: tx(g * 0.075, c: _RoadPainter.neon.withOpacity(gps ? 0.9 : 0.5), h: 1.3)),
                      if (!gps) Text('اضغط لتفعيل السرعة', style: tx(g * 0.062, c: Colors.white54, h: 1.4)),
                      if (gps && _trip > 100) Text('${(_trip / 1000).toStringAsFixed(1)} كم', style: tx(g * 0.066, c: kGold, h: 1.4)),
                    ]),
                  ),
                ),
              );
            },
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
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x9935E3C1), width: 2), boxShadow: const [BoxShadow(color: Color(0x4435E3C1), blurRadius: 16)]),
            child: Stack(alignment: Alignment.center, children: [
              ClipOval(child: Cover(t?.coverUrl ?? '', size: s - 4, radius: 0)),
              Container(width: s * 0.16, height: s * 0.16, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF04140F), border: Border.all(color: kGold, width: 1.5))),
            ]),
          ),
        ),
      );

  Widget _scene(Track? t) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight, hz = h * 0.42;
        final g = math.min(w * 0.46, hz * 1.5).clamp(110.0, 240.0).toDouble();
        final cs = math.min(w * 0.19, hz * 0.6).clamp(50.0, 118.0).toDouble();
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(children: [
            Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _RoadPainter(_sc, _frame)))),
            Positioned(top: 4, left: (w - g) / 2, child: _speedo(g)),
            Positioned(
                left: 10,
                top: 10,
                child: SizedBox(width: cs, height: cs, child: ValueListenableBuilder<DateTime>(valueListenable: _clock, builder: (_, d, __) => CustomPaint(painter: _ClockPainter(d))))),
            Positioned(right: 10, top: 10, child: _disc(t, cs)),
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

/// عدّاد علوي: قوس بشرطات تضيء مع السرعة (حتى 160)
class _GaugePainter extends CustomPainter {
  final double kmh;
  final bool on;
  _GaugePainter(this.kmh, this.on);
  @override
  void paint(Canvas c, Size s) {
    const neon = _RoadPainter.neon;
    final ctr = Offset(s.width / 2, s.width * 0.52), r = s.width * 0.46;
    const a0 = math.pi * 1.06, sw = math.pi * 0.88;
    final gr = Rect.fromCircle(center: ctr, radius: r);
    c.drawCircle(ctr, r * 0.75, Paint()..shader = RadialGradient(colors: [neon.withOpacity(on ? 0.22 : 0.1), neon.withOpacity(0)]).createShader(Rect.fromCircle(center: ctr, radius: r * 0.75)));
    c.drawArc(gr, a0, sw, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = neon.withOpacity(0.35));
    final f = on ? (kmh / 160).clamp(0.0, 1.0).toDouble() : 0.0;
    const n = 32;
    for (int i = 0; i <= n; i++) {
      final a = a0 + sw * i / n, d = Offset(math.cos(a), math.sin(a)), lg = i % 4 == 0, act = on && i / n <= f + 0.001;
      final p = Paint()
        ..strokeWidth = lg ? 2.4 : 1.6
        ..strokeCap = StrokeCap.round
        ..color = act ? Color.lerp(neon, const Color(0xFFFF5A64), (i / n - 0.6).clamp(0.0, 0.4).toDouble() * 2.5)! : Colors.white.withOpacity(0.28);
      if (act) c.drawLine(ctr + d * (r * (lg ? 0.8 : 0.85)), ctr + d * (r * 0.94), Paint()..strokeWidth = 6..color = p.color.withOpacity(0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      c.drawLine(ctr + d * (r * (lg ? 0.8 : 0.85)), ctr + d * (r * 0.94), p);
    }
    if (f > 0) {
      c.drawArc(gr.inflate(3), a0, sw * f, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = neon
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3));
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.kmh != kmh || o.on != on;
}

/// ساعة عقارب بزجاج داكن
class _ClockPainter extends CustomPainter {
  final DateTime t;
  _ClockPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    const neon = _RoadPainter.neon;
    final ctr = s.center(Offset.zero), r = s.width / 2 - 2, rc = Rect.fromCircle(center: ctr, radius: r);
    c.drawCircle(ctr, r, Paint()..shader = const RadialGradient(colors: [Color(0xE60C2A26), Color(0xF2020B08)]).createShader(rc));
    c.drawCircle(ctr, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = neon.withOpacity(0.6));
    for (int i = 0; i < 60; i++) {
      final a = i * math.pi / 30, d = Offset(math.sin(a), -math.cos(a)), lg = i % 5 == 0;
      c.drawLine(ctr + d * (r * (lg ? 0.78 : 0.86)), ctr + d * (r * 0.92), Paint()
        ..strokeWidth = lg ? 2 : 0.8
        ..color = Colors.white.withOpacity(lg ? 0.85 : 0.35));
    }
    void hand(double a, double len, double wd, Color col) {
      final d = Offset(math.sin(a), -math.cos(a));
      c.drawLine(ctr - d * (r * 0.12), ctr + d * (r * len), Paint()
        ..strokeWidth = wd
        ..strokeCap = StrokeCap.round
        ..color = col);
    }
    final hr = (t.hour % 12 + t.minute / 60) * math.pi / 6, mn = (t.minute + t.second / 60) * math.pi / 30, sc = t.second * math.pi / 30;
    hand(hr, 0.48, r * 0.07, Colors.white);
    hand(mn, 0.7, r * 0.045, Colors.white);
    hand(sc, 0.8, r * 0.022, kGold);
    c.drawCircle(ctr, r * 0.07, Paint()..color = kGold);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter o) => o.t != t;
}

/// المشهد: سماء ونجوم، جبال وأفق قباب ومنارات، أرضية شبكية، طريق مرتفع بحواف مضيئة،
/// خطوط سرعة تتدفق، ضوء أمامي، وسيارة رياضية لامعة بشريط إضاءة خلفي
class _RoadPainter extends CustomPainter {
  final _Scene sc;
  _RoadPainter(this.sc, Listenable r) : super(repaint: r);
  static const neon = Color(0xFF35E3C1);
  static TextPainter? _plate;
  static double _plateW = 0;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, hz = h * 0.42, cx = w / 2, H = h - hz, v = sc.v, full = Offset.zero & s;
    // السماء
    c.drawRect(full, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF010708), Color(0xFF04201F), Color(0xFF0A403A)], stops: [0, 0.25, 0.42]).createShader(full));
    final sky = Rect.fromLTRB(0, 0, w, hz);
    c.drawRect(sky, Paint()..shader = const RadialGradient(center: Alignment(0.55, -1.2), radius: 1.2, colors: [Color(0x3384EAD8), Color(0x00000000)]).createShader(sky));
    final rnd = math.Random(7);
    for (int i = 0; i < 64; i++) {
      final x = rnd.nextDouble() * w, y = rnd.nextDouble() * hz * 0.85, rr = 0.5 + rnd.nextDouble(), tw = 0.32 + 0.35 * math.sin(sc.sway * 0.8 + i * 1.7);
      c.drawCircle(Offset(x, y), rr, Paint()..color = Colors.white.withOpacity(tw.clamp(0.06, 0.75).toDouble()));
    }
    // وهج الأفق
    final hgr = Rect.fromCenter(center: Offset(cx, hz), width: w * 1.3, height: H * 0.9);
    c.drawOval(hgr, Paint()..shader = RadialGradient(colors: [neon.withOpacity(0.38), neon.withOpacity(0)]).createShader(hgr));
    // جبال بعيدة
    final mt = Path()..moveTo(0, hz);
    for (double x = 0; x <= w + 1; x += w / 48) {
      mt.lineTo(x, hz - H * 0.07 - math.sin(x / w * 7 + 1) * H * 0.035 - math.sin(x / w * 19) * H * 0.012);
    }
    mt
      ..lineTo(w, hz)
      ..close();
    c.drawPath(mt, Paint()..color = const Color(0xFF07302C));
    // أفق المدينة: قباب ومنارات بحافة مضيئة
    final sk = Path()..moveTo(0, hz);
    final u = w / 24, tips = <Offset>[];
    void dome(double x, double r) {
      sk.lineTo(x - r, hz);
      sk.lineTo(x - r, hz - r * 0.5);
      sk.quadraticBezierTo(x - r, hz - r * 1.5, x, hz - r * 1.9);
      sk.quadraticBezierTo(x + r, hz - r * 1.5, x + r, hz - r * 0.5);
      sk.lineTo(x + r, hz);
      tips.add(Offset(x, hz - r * 1.9));
    }
    void minaret(double x, double hh) {
      final m = u * 0.22;
      sk.lineTo(x - m, hz);
      sk.lineTo(x - m, hz - hh);
      sk.lineTo(x - m * 1.6, hz - hh);
      sk.lineTo(x - m * 1.6, hz - hh - m * 0.8);
      sk.lineTo(x - m, hz - hh - m * 0.8);
      sk.lineTo(x, hz - hh - m * 3.4);
      sk.lineTo(x + m, hz - hh - m * 0.8);
      sk.lineTo(x + m * 1.6, hz - hh - m * 0.8);
      sk.lineTo(x + m * 1.6, hz - hh);
      sk.lineTo(x + m, hz - hh);
      sk.lineTo(x + m, hz);
      tips.add(Offset(x, hz - hh - m * 3.4));
    }
    void block(double x, double bw, double bh) {
      sk.lineTo(x, hz);
      sk.lineTo(x, hz - bh);
      sk.lineTo(x + bw, hz - bh);
      sk.lineTo(x + bw, hz);
    }
    block(u * 0.4, u * 1.6, u * 0.9);
    minaret(u * 3.2, u * 2.6);
    dome(u * 5, u * 1.2);
    minaret(u * 6.8, u * 2.6);
    block(u * 7.6, u * 2, u * 0.7);
    block(u * 14.2, u * 1.8, u * 0.8);
    minaret(u * 17, u * 3.2);
    dome(u * 19, u * 1.5);
    minaret(u * 21, u * 3.2);
    block(u * 21.8, u * 1.8, u * 1);
    sk
      ..lineTo(w, hz)
      ..close();
    c.drawPath(sk, Paint()..color = const Color(0xFF021614));
    c.drawPath(sk, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = neon.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
    for (final t in tips) {
      c.drawCircle(t, 1.6, Paint()..color = kGold2..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
    }
    // الأرض
    final gr = Rect.fromLTRB(0, hz, w, h);
    c.drawRect(gr, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF05211D), Color(0xFF010807)]).createShader(gr));
    // الإسقاط: u مسافة للأمام، X عرضي، Y ارتفاع
    double f(double q) => 1 / (1 + q);
    Offset P(double X, double q, [double Y = 0]) {
      final ff = f(q);
      return Offset(cx + X * ff, hz + (H - Y) * ff);
    }
    final rb = w * 0.5, ph = sc.phase % 1, vp = Offset(cx, hz);
    // الشبكة الأرضية
    final gp = Paint()..strokeWidth = 1;
    for (int i = -9; i <= 9; i++) {
      gp.color = neon.withOpacity(0.07);
      c.drawLine(vp, Offset(cx + i * rb / 2.4, h), gp);
    }
    for (int k = 0; k < 30; k++) {
      final y = hz + H * f(k + 1 - ph);
      gp.color = neon.withOpacity(0.04 + 0.16 * f(k + 1 - ph));
      c.drawLine(Offset(0, y), Offset(w, y), gp);
    }
    // جانبا الطريق المرتفع
    for (final sd in const [-1.0, 1.0]) {
      final face = Path()
        ..moveTo(vp.dx, vp.dy)
        ..lineTo(cx + sd * rb, h)
        ..lineTo(cx + sd * rb * 1.08, h + H * 0.12)
        ..close();
      c.drawPath(face, Paint()..color = const Color(0xFF0B3A33));
    }
    // سطح الطريق
    final road = Path()
      ..moveTo(vp.dx, vp.dy)
      ..lineTo(cx + rb, h)
      ..lineTo(cx - rb, h)
      ..close();
    c.drawPath(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0C2E2A), Color(0xFF153F39)]).createShader(gr));
    // ضوء أمامي ينير الطريق
    final carU = 0.12, beamTop = P(0, 10).dy, beamBot = P(0, carU + 0.9).dy;
    final beam = Path()
      ..moveTo(P(-rb * 0.32, carU + 0.9).dx, beamBot)
      ..lineTo(P(rb * 0.32, carU + 0.9).dx, beamBot)
      ..lineTo(P(rb * 0.55, 10).dx, beamTop)
      ..lineTo(P(-rb * 0.55, 10).dx, beamTop)
      ..close();
    c.drawPath(beam, Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.white.withOpacity(0.1 + 0.14 * v.clamp(0.0, 1.0)), Colors.white.withOpacity(0)]).createShader(Rect.fromLTRB(0, beamTop, w, beamBot)));
    // شبكة سطح الطريق
    for (int k = 0; k < 24; k++) {
      final q = k + 1 - ph, ff = f(q);
      c.drawLine(P(-rb, q), P(rb, q), Paint()
        ..strokeWidth = 1
        ..color = neon.withOpacity(0.05 + 0.2 * ff));
    }
    for (int i = -2; i <= 2; i++) {
      if (i == 0) continue;
      c.drawLine(vp, Offset(cx + i * rb / 3, h), Paint()
        ..strokeWidth = 1
        ..color = neon.withOpacity(0.1));
    }
    // خطوط المسارات المتقطعة
    for (int k = 0; k < 16; k++) {
      final q0 = k + 1 - ph, q1 = q0 + 0.45;
      for (final sd in const [-1.0, 1.0]) {
        final X = sd * rb / 3, dw = rb * 0.022;
        final a = P(X - dw, q0), b = P(X + dw, q0), cc = P(X + dw, q1), d = P(X - dw, q1);
        c.drawPath(
            Path()
              ..moveTo(a.dx, a.dy)
              ..lineTo(b.dx, b.dy)
              ..lineTo(cc.dx, cc.dy)
              ..lineTo(d.dx, d.dy)
              ..close(),
            Paint()..color = Colors.white.withOpacity(0.85 * math.sqrt(f(q0))));
      }
    }
    // الحواف المضيئة
    for (final sd in const [-1.0, 1.0]) {
      final e = Offset(cx + sd * rb, h);
      c.drawLine(vp, e, Paint()
        ..strokeWidth = 8
        ..color = neon.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawLine(vp, e, Paint()
        ..strokeWidth = 2.2
        ..color = neon);
    }
    // خطوط السرعة: تتدفق على الجانبين وتزيد مع السرعة
    if (v > 0.03) {
      final sp = Paint()..strokeCap = StrokeCap.round;
      final vv = v.clamp(0.0, 1.0).toDouble();
      for (int i = 0; i < 28; i++) {
        final sd = i.isEven ? 1.0 : -1.0, X = sd * rb * (1.2 + ((i * 0.37) % 1) * 2.4), Y = H * (((i * 0.61) % 1) * 1.7 - 0.1);
        final q = ((i * 3.7) % 14 - sc.phase * 2.6) % 14, len = 0.25 + 2.4 * v;
        final ff = f(q);
        sp
          ..strokeWidth = 1 + 2.6 * ff
          ..color = (i % 3 == 0 ? kGold2 : neon).withOpacity(vv * (0.2 + 0.65 * ff));
        c.drawLine(P(X, q + len, Y), P(X, q, Y), sp);
      }
    }
    // السيارة
    final cw = math.min(w * 0.36, H * 1.3), by = h - H * 0.09;
    final sx = math.sin(sc.sway * 0.7) * w * 0.01 * v, bob = math.sin(sc.sway * 9) * 0.6 * v;
    // وهج المصابيح الأمامية فوق السيارة
    final gl = Rect.fromCenter(center: Offset(cx + sx, by - cw * 0.66), width: cw * 1.5, height: cw * 0.7);
    c.drawOval(gl, Paint()..shader = RadialGradient(colors: [Colors.white.withOpacity(0.22 + 0.2 * v.clamp(0.0, 1.0)), Colors.white.withOpacity(0)]).createShader(gl));
    _car(c, cx + sx, by + bob, cw, sc.brake);
  }

  void _car(Canvas c, double ox, double by, double cw, double br) {
    final ch = cw * 0.6;
    Offset p(double x, double y) => Offset(ox + x * cw, by + y * ch);
    void mv(Path pa, double x, double y) {
      final o = p(x, y);
      pa.moveTo(o.dx, o.dy);
    }
    void ln(Path pa, double x, double y) {
      final o = p(x, y);
      pa.lineTo(o.dx, o.dy);
    }
    void cb(Path pa, double x1, double y1, double x2, double y2, double x3, double y3) {
      final a = p(x1, y1), b = p(x2, y2), d = p(x3, y3);
      pa.cubicTo(a.dx, a.dy, b.dx, b.dy, d.dx, d.dy);
    }
    void qd(Path pa, double x1, double y1, double x2, double y2) {
      final a = p(x1, y1), b = p(x2, y2);
      pa.quadraticBezierTo(a.dx, a.dy, b.dx, b.dy);
    }
    final lc = Color.lerp(const Color(0xFFB3141F), const Color(0xFFFF2B3A), br)!;
    // الظل وانعكاس الأضواء على الطريق
    c.drawOval(Rect.fromCenter(center: p(0, 0.01), width: cw * 1.15, height: ch * 0.22), Paint()
      ..color = const Color(0xD9000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    for (final sd in const [-1.0, 1.0]) {
      final r = Rect.fromLTRB(ox + sd * cw * 0.34 - cw * 0.08, by, ox + sd * cw * 0.34 + cw * 0.08, by + ch * 0.55);
      c.drawRect(r, Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lc.withOpacity(0.28 + 0.32 * br), lc.withOpacity(0)]).createShader(r)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
    // العجلات
    for (final sd in const [-1.0, 1.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(sd * 0.33, -0.18), p(sd * 0.475, 0.0)), Radius.circular(cw * 0.03)), Paint()..color = const Color(0xFF030505));
    }
    // الهيكل: خلفية سيارة رياضية بأوراك عريضة ومقصورة منحنية
    final b = Path();
    mv(b, -0.44, -0.05);
    ln(b, -0.485, -0.15);
    cb(b, -0.515, -0.27, -0.515, -0.43, -0.475, -0.52);
    cb(b, -0.45, -0.585, -0.40, -0.62, -0.32, -0.64);
    cb(b, -0.28, -0.655, -0.26, -0.70, -0.245, -0.76);
    cb(b, -0.20, -0.93, -0.10, -1.0, 0, -1.0);
    cb(b, 0.10, -1.0, 0.20, -0.93, 0.245, -0.76);
    cb(b, 0.26, -0.70, 0.28, -0.655, 0.32, -0.64);
    cb(b, 0.40, -0.62, 0.45, -0.585, 0.475, -0.52);
    cb(b, 0.515, -0.43, 0.515, -0.27, 0.485, -0.15);
    ln(b, 0.44, -0.05);
    qd(b, 0, -0.01, -0.44, -0.05);
    b.close();
    final bb = b.getBounds();
    c.drawPath(b, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF46B89D), Color(0xFF16675A), Color(0xFF0B3E34), Color(0xFF041A15)], stops: [0, 0.3, 0.62, 1]).createShader(bb));
    // لمعان الطلاء
    c.save();
    c.clipPath(b);
    c.drawOval(Rect.fromCenter(center: p(0, -0.9), width: cw * 0.42, height: ch * 0.18), Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.04));
    for (final sd in const [-1.0, 1.0]) {
      c.drawOval(Rect.fromCenter(center: p(sd * 0.4, -0.57), width: cw * 0.2, height: ch * 0.07), Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.025));
    }
    c.restore();
    c.drawPath(b, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = neon.withOpacity(0.4));
    // الزجاج الخلفي
    final g = Path();
    mv(g, -0.205, -0.705);
    cb(g, -0.18, -0.86, -0.09, -0.935, 0, -0.935);
    cb(g, 0.09, -0.935, 0.18, -0.86, 0.205, -0.705);
    qd(g, 0, -0.67, -0.205, -0.705);
    g.close();
    c.drawPath(g, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A524C), Color(0xFF03100D)]).createShader(g.getBounds()));
    c.save();
    c.clipPath(g);
    final st = Path();
    mv(st, -0.1, -1.0);
    ln(st, 0.0, -1.0);
    ln(st, -0.12, -0.6);
    ln(st, -0.22, -0.6);
    st.close();
    c.drawPath(st, Paint()..color = Colors.white.withOpacity(0.12));
    c.restore();
    // ضوء الفرامل العلوي
    final tb = RRect.fromRectAndRadius(Rect.fromPoints(p(-0.075, -0.915), p(0.075, -0.893)), const Radius.circular(3));
    if (br > 0.05) c.drawRRect(tb.inflate(3), Paint()..color = lc.withOpacity(0.5 * br)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawRRect(tb, Paint()..color = Color.lerp(const Color(0xFF3A0A0E), lc, 0.3 + 0.7 * br)!);
    // شبك المحرك
    for (int k = 0; k < 4; k++) {
      final y = -0.57 - k * 0.024;
      c.drawLine(p(-0.13, y), p(0.13, y), Paint()
        ..strokeWidth = math.max(1.0, ch * 0.009)
        ..color = Colors.black.withOpacity(0.45));
    }
    // المرايا
    for (final sd in const [-1.0, 1.0]) {
      c.drawOval(Rect.fromCenter(center: p(sd * 0.335, -0.70), width: cw * 0.09, height: ch * 0.06), Paint()..color = const Color(0xFF0F5446));
    }
    // شريط الإضاءة الخلفي الكامل
    final lb = Path();
    mv(lb, -0.46, -0.49);
    qd(lb, 0, -0.535, 0.46, -0.49);
    c.drawPath(lb, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ch * (0.08 + 0.06 * br)
      ..strokeCap = StrokeCap.round
      ..color = lc.withOpacity(0.35 + 0.4 * br)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + 8 * br));
    c.drawPath(lb, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ch * 0.032
      ..strokeCap = StrokeCap.round
      ..color = lc);
    c.drawPath(lb, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ch * 0.01
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(lc, Colors.white, 0.55)!);
    for (final sd in const [-1.0, 1.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p(sd * 0.41, -0.495), width: cw * 0.1, height: ch * 0.055), Radius.circular(ch * 0.03)), Paint()..color = lc);
    }
    c.drawCircle(p(0, -0.45), cw * 0.017, Paint()..color = kGold);
    // المصد والناشر والعادم
    c.drawLine(p(-0.47, -0.25), p(0.47, -0.25), Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.14));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(-0.40, -0.19), p(0.40, -0.045)), Radius.circular(cw * 0.025)), Paint()..color = const Color(0xFF051210));
    for (double x = -0.24; x <= 0.241; x += 0.08) {
      c.drawLine(p(x, -0.17), p(x, -0.06), Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.08));
    }
    for (final sd in const [-1.0, 1.0]) {
      final ex = Rect.fromCenter(center: p(sd * 0.3, -0.115), width: cw * 0.085, height: ch * 0.06);
      c.drawRRect(RRect.fromRectAndRadius(ex, Radius.circular(ch * 0.03)), Paint()..shader = const LinearGradient(colors: [Color(0xFFB9C4C0), Color(0xFF3A4442)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(ex));
      c.drawRRect(RRect.fromRectAndRadius(ex.deflate(ch * 0.012), Radius.circular(ch * 0.02)), Paint()..color = const Color(0xFF070909));
    }
    // اللوحة
    final pl = Rect.fromCenter(center: p(0, -0.32), width: cw * 0.24, height: ch * 0.095);
    c.drawRRect(RRect.fromRectAndRadius(pl, Radius.circular(ch * 0.015)), Paint()..color = const Color(0xFFEDEAE0));
    if (_plate == null || (_plateW - cw).abs() > 1) {
      _plateW = cw;
      _plate = TextPainter(text: TextSpan(text: 'منبر', style: TextStyle(fontFamily: 'Cairo', fontSize: ch * 0.068, fontWeight: FontWeight.w700, color: kGreen, height: 1)), textDirection: TextDirection.rtl)..layout();
    }
    final tp = _plate!;
    tp.paint(c, pl.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RoadPainter o) => false;
}
