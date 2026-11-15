import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

/// وضع السيارة: مشهد قيادة حيّ بكامل الشاشة.
/// - السرعة من GPS مع تنقية (دقة السرعة، رفض القفزات، حساب احتياطي من المسافة/الزمن).
/// - الطريق يتحرك بالسرعة الحقيقية (بالمتر)، ينعطف مع اتجاه السيارة، والفرامل تضيء عند التباطؤ والتوقف، والإشارة عند الانعطاف.
/// - السماء حسب موقع الشمس والقمر الفعلي، والطقس الحقيقي (Open-Meteo): غيوم، مطر، عاصفة، ضباب، غبار، ثلج.

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

/// حالة المشهد الحيّة (تتحدث كل إطار بلا إعادة بناء الصفحة)
class _Scene {
  double t = 0, q = 0, v = 0, a = 0, brake = 0, tail = 0.3, curv = 0, lean = 0, blink = 0, pitch = 0, spin = 0, flash = 0, splash = 0;
  double sunEl = 45, sunAz = 180, moonEl = -20, moonAz = 0, moonPh = 0.5, heading = 180;
  double rain = 0, snow = 0, cloud = 0, fog = 0, dust = 0, storm = 0, wind = 0;
}

/// أبعاد المسرح المحسوبة من التخطيط (الأفق، مركز الطريق، موضع السيارة وعرضها)
class _Stage {
  final double hz, cx, carY, cw;
  const _Stage(this.hz, this.cx, this.carY, this.cw);
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
  Timer? _ct, _wt;
  StreamSubscription<Position>? _gs;
  bool gps = false;
  // GPS
  Position? _lp;
  double _lt = 0, _rawV = 0, _turn = 0, _acc = 99, _fixAt = -99, _trip = 0, _blinkHold = 0;
  double _lat = 32.616, _lon = 44.024; // كربلاء افتراضياً
  // الطقس والوقت
  _Wx _wx = _Wx();
  int _wMode = 0, _tMode = 0;
  final _rnd = math.Random();

  double get _now => DateTime.now().millisecondsSinceEpoch / 1000.0;

  @override
  void initState() {
    super.initState();
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
      _env();
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
        // احتياطي: المسافة/الزمن عندما تكون الدقة جيدة
        if (sp == null && p.accuracy < 20 && lp.accuracy < 20) sp = d / dt;
        if (sp != null) {
          // رفض القفزات غير الممكنة (تسارع > 8 م/ث²)
          final lim = _rawV + 8 * dt;
          if (sp > lim) sp = lim;
          if (sp > 1.2 && d < sp * dt * 1.6 + 6) _trip += d;
        }
        // معدل الانعطاف من اتجاه الحركة
        if (sp != null && sp > 2.5 && p.heading >= 0 && lp.heading >= 0 && (p.headingAccuracy <= 0 || p.headingAccuracy < 25)) {
          final dh = ((p.heading - lp.heading + 540) % 360) - 180;
          final rate = (dh / dt) * math.pi / 180;
          _turn += (_cl(rate, -0.6, 0.6) - _turn) * 0.6;
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
    // عمر القمر من محاق مرجعي (6 يناير 2000)
    final ph = (((n - 5.1) / 29.530588853) % 1 + 1) % 1;
    final (me, ma) = _skyPos(lam + ph * 2 * math.pi, n, _lat, _lon);
    _sc
      ..sunEl = se
      ..sunAz = sa
      ..moonEl = me
      ..moonAz = ma
      ..moonPh = ph;
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
      final m = await get('https://api.open-meteo.com/v1/forecast?latitude=$la&longitude=$lo&current=temperature_2m,weather_code,cloud_cover,precipitation,wind_speed_10m,visibility');
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
      final vis = nv('visibility');
      w.fog = math.max(code == 45 || code == 48 ? 0.75 : 0.0, vis > 0 && vis < 8000 ? _cl(1 - vis / 8000) : 0.0);
      if (w.rain > 0 || w.snow > 0) w.cloud = math.max(w.cloud, 0.85);
      try {
        final aq = await get('https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$la&longitude=$lo&current=dust');
        final d = ((aq['current'] as Map<String, dynamic>)['dust'] as num?)?.toDouble() ?? 0.0;
        w.dust = _cl((d - 120) / 600);
      } catch (_) {}
      if (mounted) setState(() => _wx = w);
    } catch (_) {
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
    // الانعطاف: انحناء الطريق = معدل الدوران / السرعة
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
    // الطقس يتبدل بنعومة
    final w = _wxNow, m = math.min(1.0, dt * 0.6);
    s
      ..rain += (w.rain - s.rain) * m
      ..snow += (w.snow - s.snow) * m
      ..cloud += (w.cloud - s.cloud) * m
      ..fog += (w.fog - s.fog) * m
      ..dust += (w.dust - s.dust) * m
      ..storm += (w.storm - s.storm) * m
      ..wind += (w.wind - s.wind) * m;
    if (s.storm > 0.3 && _rnd.nextDouble() < dt * 0.12) s.flash = 1;
    s.flash = math.max(0.0, s.flash - dt * 3.5);
    final lightsOn = 1 - _sm(-3, 5, s.sunEl);
    final murk = math.max(math.max(s.fog, s.dust), s.rain * 0.8);
    s.tail += ((0.3 + 0.55 * math.max(lightsOn, murk)) - s.tail) * math.min(1.0, dt * 2);
    s.splash = s.rain * _cl(s.v / 15);
    _frame.value++;
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
    WakelockPlus.disable();
    app.player.removeListener(_r);
    _tk.dispose();
    _ct?.cancel();
    _wt?.cancel();
    _gs?.cancel();
    _frame.dispose();
    _clock.dispose();
    super.dispose();
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: const Color(0x59000000), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x33FFFFFF))),
          child: child,
        ),
      );

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _topBar() {
    final w = _wxNow, night = _sc.sunEl < -4;
    final t = w.temp.isNaN ? '' : ' ${w.temp.round()}°';
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 0),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const PIcon(Ic.x, color: Colors.white, size: 26)),
        Flexible(
          child: _chip(Text('${w.icon(night)}$t  ${w.label}${_wMode == 0 ? '' : ' · تجربة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, c: Colors.white)), () {
            setState(() => _wMode = (_wMode + 1) % _presets.length);
            SharedPreferences.getInstance().then((p) => p.setInt('car.wx', _wMode));
            _say(_wMode == 0 ? 'الطقس الحقيقي' : 'تجربة: ${_presets[_wMode]!.label}');
          }),
        ),
        const SizedBox(width: 6),
        _chip(PIcon(Ic.moon, color: _tMode == 0 ? Colors.white : kGold, size: 18), () {
          setState(() => _tMode = (_tMode + 1) % 4);
          SharedPreferences.getInstance().then((p) => p.setInt('car.tm', _tMode));
          _env();
          _say(_timeNames[_tMode]);
        }),
        const Spacer(),
        ValueListenableBuilder<DateTime>(
          valueListenable: _clock,
          builder: (_, d, __) => Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${_two(d.hour)}:${_two(d.minute)}', style: tx(24, c: Colors.white).copyWith(fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Color(0x99000000), blurRadius: 8)])),
          ),
        ),
      ]),
    );
  }

  /// عدّاد السرعة: اضغطه لتشغيل/إيقاف GPS
  Widget _speedo(double g) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          gps ? _gpsOff() : _gpsOn();
        },
        child: SizedBox(
          width: g,
          height: g * 0.7,
          child: AnimatedBuilder(
            animation: _frame,
            builder: (_, __) {
              final k = gps ? _sc.v * 3.6 : 0.0, hot = k > 120, weak = gps && (_acc > 30 || _now - _fixAt > 5);
              final col = !gps ? Colors.white54 : (hot ? const Color(0xFFFF5A64) : Colors.white);
              return CustomPaint(
                painter: _GaugePainter(k, gps),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: g * 0.15),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(gps ? '${k.round()}' : '--',
                            style: tx(g * 0.27, c: col, h: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 10)])),
                      ),
                      Text('كم/س', style: tx(g * 0.075, c: Colors.white70, h: 1.3)),
                      if (!gps) Text('اضغط لتفعيل السرعة', style: tx(g * 0.062, c: kGold, h: 1.4)),
                      if (weak) Text('إشارة GPS ضعيفة', style: tx(g * 0.06, c: const Color(0xFFFFB36B), h: 1.4)),
                      if (gps && !weak && _trip > 100) Text('${(_trip / 1000).toStringAsFixed(1)} كم', style: tx(g * 0.066, c: kGold, h: 1.4)),
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
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kGold, width: 1.5)),
            child: Stack(alignment: Alignment.center, children: [
              ClipOval(child: Cover(t?.coverUrl ?? '', size: s - 3, radius: 0)),
              Container(width: s * 0.18, height: s * 0.18, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF04140F), border: Border.all(color: kGold, width: 1))),
            ]),
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

  @override
  Widget build(BuildContext context) {
    final t = app.player.cur, pad = MediaQuery.of(context).padding;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth, h = c.maxHeight, land = w > h * 1.15;
          final top = pad.top + 4;
          if (land) {
            // أفقي: المشهد كامل، اللوحة على اليمين بزجاج متدرج
            final pw = w * 0.42, sw = w - pw, u = _cl(h * 0.17, 50, 84);
            final hz = h * 0.4, carY = h - pad.bottom - h * 0.07, cw = math.min(sw * 0.5, (carY - hz) * 1.05);
            final g = _cl(math.min(sw * 0.42, (hz - top - 44) / 0.7), 90, 210);
            return Stack(children: [
              Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _World(_sc, _Stage(hz, sw * 0.5, carY, cw), _frame)))),
              Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: pw + 40,
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0x00000000), Color(0xB3000000), Color(0xD9000000)], stops: [0, 0.25, 1])))),
              Positioned(top: top + 44, left: sw * 0.5 - g / 2, child: _speedo(g)),
              Positioned(top: top - 4, left: 0, right: 0, child: _topBar()),
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
          // عمودي: المشهد كامل، اللوحة أسفل بزجاج متدرج والسيارة فوقها مباشرة
          final u = _cl(w * 0.19, 58, 88), lyH = ly.isEmpty ? 0.0 : _cl(h * 0.1, 54, 96);
          final panel = 58 + lyH + 30 + u * 1.3 + u * 0.16 + u * 0.64 + 14 + pad.bottom;
          final hz = h * 0.3, carY = h - panel - 6;
          final cw = math.min(w * 0.5, (carY - hz) * 1.0);
          final g = _cl(math.min(w * 0.5, (hz - top - 48) / 0.7), 100, 230);
          return Stack(children: [
            Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _World(_sc, _Stage(hz, w / 2, carY, cw), _frame)))),
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panel + 50,
                child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xA6000000), Color(0xE6000000)], stops: [0, 0.22, 1])))),
            Positioned(top: top + 44, left: (w - g) / 2, child: _speedo(g)),
            Positioned(top: top - 4, left: 0, right: 0, child: _topBar()),
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
    const neon = Color(0xFF35E3C1);
    final ctr = Offset(s.width / 2, s.width * 0.52), r = s.width * 0.46;
    const a0 = math.pi * 1.06, sw = math.pi * 0.88;
    c.drawCircle(ctr, r * 0.8, Paint()..shader = const RadialGradient(colors: [Color(0x73000000), Color(0x00000000)]).createShader(Rect.fromCircle(center: ctr, radius: r * 0.8)));
    final f = on ? _cl(kmh / 160) : 0.0;
    const n = 32;
    for (int i = 0; i <= n; i++) {
      final a = a0 + sw * i / n, d = Offset(math.cos(a), math.sin(a)), lg = i % 4 == 0, act = on && i / n <= f + 0.001;
      final col = act ? Color.lerp(neon, const Color(0xFFFF5A64), _cl((i / n - 0.6) * 2.5))! : Colors.white.withOpacity(0.4);
      final p0 = ctr + d * (r * (lg ? 0.8 : 0.86)), p1 = ctr + d * (r * 0.94);
      if (act) {
        c.drawLine(p0, p1, Paint()
          ..strokeWidth = 6
          ..color = col.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      }
      c.drawLine(p0, p1, Paint()
        ..strokeWidth = lg ? 2.4 : 1.6
        ..strokeCap = StrokeCap.round
        ..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.kmh != kmh || o.on != on;
}

/// العالم: سماء حقيقية، أرض، طريق بمنظور هندسي بالأمتار، نخيل وأعمدة إنارة، طقس، وسيارة
class _World extends CustomPainter {
  final _Scene s;
  final _Stage g;
  _World(this.s, this.g, Listenable r) : super(repaint: r);
  static TextPainter? _plate;
  static double _plateW = 0;

  @override
  void paint(Canvas c, Size z) {
    final w = z.width, h = z.height, hz = g.hz, cx = g.cx, hh = h - hz;
    // الإسقاط: عرض السيارة 1.85 م، وحدة العمق 2.5 م، والكاميرا خلف السيارة
    final fc = _cl((g.carY - hz) / hh, 0.05, 0.95), s0 = g.cw / (1.85 * fc), qc = 1 / fc - 1;
    final el = s.sunEl, day = _sm(-7, 7, el), golden = el > -6 ? _cl(1 - (el - 2).abs() / 10) : 0.0;
    final over = _cl(s.cloud * 0.75 + s.rain * 0.25);
    final light = _cl((0.06 + 0.94 * day) * (1 - 0.35 * over) + s.flash * 0.6);
    final lightsOn = 1 - _sm(-3, 5, el);
    double f(double q) => 1 / (1 + q);
    double off(double q) {
      final d = q - qc;
      return s.curv * 3.125 * d * d;
    }

    double X(double xm, double q) => cx + (xm + off(q)) * s0 * f(q);
    double Y(double q, [double ym = 0]) => hz + (hh - ym * s0) * f(q);
    double sxOf(double az) => cx + (((az - s.heading + 540) % 360) - 180) / 55 * (w / 2);

    // ---------- السماء ----------
    var top = _mix(const Color(0xFF02060F), const Color(0xFF2F6FC4), day), hor = _mix(const Color(0xFF0C1A2E), const Color(0xFFA8D0EE), day);
    top = _mix(top, const Color(0xFF34406A), golden * 0.5);
    hor = _mix(hor, const Color(0xFFF08C55), golden * 0.85);
    top = _mix(top, _mix(const Color(0xFF0E1216), const Color(0xFF7C8792), day), over);
    hor = _mix(hor, _mix(const Color(0xFF181D22), const Color(0xFFAAB2B9), day), over);
    final dustC = _mix(const Color(0xFF2A2014), const Color(0xFFC99A5A), day);
    top = _mix(top, dustC, s.dust * 0.85);
    hor = _mix(hor, _mix(dustC, const Color(0xFFE0B676), day), s.dust);
    top = _mix(top, Colors.white, s.flash * 0.5);
    hor = _mix(hor, Colors.white, s.flash * 0.4);
    final sky = Rect.fromLTRB(0, 0, w, hz + 2);
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, hor]).createShader(sky));
    // النجوم
    final st = (1 - day) * (1 - over) * (1 - s.dust);
    if (st > 0.02) {
      for (int i = 0; i < 90; i++) {
        final x = _hash(i) * w, y = _hash(i + 500) * hz * 0.9, tw = 0.55 + 0.45 * math.sin(s.t * (1 + _hash(i + 9)) + i);
        c.drawCircle(Offset(x, y), 0.5 + _hash(i + 77) * 1.1, Paint()..color = Colors.white.withOpacity(_cl(st * tw * (1 - y / hz * 0.6))));
      }
    }
    double skyY(double e) => hz - _cl(e / 42, -0.1, 1.1) * hz * 0.95;
    // الشمس
    if (el > -3) {
      final x = sxOf(s.sunAz), y = skyY(el), rs = w * 0.04, vis = _cl(1 - over * 0.85 - s.dust * 0.6);
      if (x > -w * 0.3 && x < w * 1.3) {
        final sc = _mix(const Color(0xFFFF9A50), const Color(0xFFFFF4D6), _sm(0, 20, el));
        c.drawCircle(Offset(x, y), rs * 5, Paint()..shader = RadialGradient(colors: [sc.withOpacity(0.45 * vis + 0.1), sc.withOpacity(0)]).createShader(Rect.fromCircle(center: Offset(x, y), radius: rs * 5)));
        c.drawCircle(Offset(x, y), rs, Paint()..color = sc.withOpacity(_cl(vis + 0.15)));
      }
    }
    // القمر بطوره الحقيقي
    if (s.moonEl > -2 && day < 0.85) {
      final x = sxOf(s.moonAz), y = skyY(s.moonEl), rm = w * 0.028, vis = _cl((1 - day) * (1 - over * 0.8));
      if (x > -rm && x < w + rm && vis > 0.03) {
        c.drawCircle(Offset(x, y), rm * 4, Paint()..shader = RadialGradient(colors: [const Color(0xFFF3EEDB).withOpacity(0.25 * vis), const Color(0x00F3EEDB)]).createShader(Rect.fromCircle(center: Offset(x, y), radius: rm * 4)));
        final disk = Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: rm));
        final ph = s.moonPh, k = ph < 0.5 ? -ph * 4 * rm : (1 - ph) * 4 * rm;
        final shd = Path()..addOval(Rect.fromCircle(center: Offset(x + k, y), radius: rm * 1.02));
        c.drawPath(disk, Paint()..color = const Color(0xFF2A2F38).withOpacity(0.5 * vis));
        c.drawPath(Path.combine(PathOperation.difference, disk, shd), Paint()..color = const Color(0xFFF3EEDB).withOpacity(vis));
      }
    }
    // الغيوم تنساب مع الريح
    final nCl = (2 + s.cloud * 11).round();
    for (int i = 0; i < nCl; i++) {
      final cw0 = w * (0.25 + _hash(i + 40) * 0.35);
      final x = ((_hash(i + 20) * (w + cw0) + s.t * (3 + s.wind * 2) * (0.5 + _hash(i))) % (w + cw0 * 2)) - cw0, y = _hash(i + 30) * hz * 0.65;
      final cc = _mix(_mix(Colors.white, const Color(0xFF8A939C), over), const Color(0xFF151A20), 1 - light);
      c.drawOval(Rect.fromLTWH(x, y, cw0, cw0 * 0.24), Paint()
        ..color = cc.withOpacity(0.35 + 0.35 * s.cloud)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw0 * 0.07));
    }

    // ---------- الأرض ----------
    var land = _mix(const Color(0xFF0D0C0A), const Color(0xFFC4A16A), light);
    land = _mix(land, _mix(const Color(0xFF1A1712), const Color(0xFFB38E5C), light), s.rain * 0.6);
    land = _mix(land, _mix(const Color(0xFF2A2D33), const Color(0xFFE8ECEF), light), s.snow);
    final hills = Path()..moveTo(0, hz);
    final hp = s.heading * math.pi / 180 * 3;
    for (int i = 0; i <= 48; i++) {
      final x = w * i / 48;
      hills.lineTo(x, hz - hh * 0.035 - math.sin(x / w * 7 + 1 + hp) * hh * 0.02 - math.sin(x / w * 19 + hp * 2) * hh * 0.007);
    }
    hills
      ..lineTo(w, hz)
      ..close();
    c.drawPath(hills, Paint()..color = _mix(land, hor, 0.55));
    final gr = Rect.fromLTRB(0, hz, w, h);
    c.drawRect(gr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(land, hor, 0.45), land, _mix(land, Colors.black, 0.25)], stops: const [0, 0.35, 1]).createShader(gr));

    // ---------- الطريق: 3 مسارات × 3.6 م، كتف 1.6 م ----------
    const half = 5.4, shoulder = 1.6, qMin = -0.9, qMax = 70.0;
    void strip(double x0, double x1, double q0, double q1, Paint p, [int n = 36]) {
      final pa = Path(), f0 = f(q0), f1 = f(q1);
      for (int i = 0; i <= n; i++) {
        final q = 1 / (f0 + (f1 - f0) * i / n) - 1;
        i == 0 ? pa.moveTo(X(x0, q), Y(q)) : pa.lineTo(X(x0, q), Y(q));
      }
      for (int i = n; i >= 0; i--) {
        final q = 1 / (f0 + (f1 - f0) * i / n) - 1;
        pa.lineTo(X(x1, q), Y(q));
      }
      pa.close();
      c.drawPath(pa, p);
    }

    final wet = _cl(s.rain * 1.4 + s.snow * 0.5);
    var asph = _mix(const Color(0xFF0E1012), const Color(0xFF4A4D51), light);
    asph = _mix(asph, _mix(const Color(0xFF07090B), const Color(0xFF2B2E32), light), wet);
    strip(-half - shoulder, half + shoulder, qMin, qMax, Paint()..color = _mix(asph, land, 0.35), 48);
    strip(-half, half, qMin, qMax, Paint()..color = asph, 48);
    if (wet > 0.05) strip(-half, half, 3, qMax, Paint()..color = hor.withOpacity(0.12 * wet), 24); // لمعان الأسفلت المبلل
    final lineC = _mix(const Color(0xFF3A3C3E), const Color(0xFFF2F2F2), _cl(light + 0.25));
    for (final xm in const [-half + 0.2, half - 0.2]) {
      strip(xm - 0.08, xm + 0.08, qMin, qMax, Paint()..color = lineC.withOpacity(0.9), 48);
    }
    // الخطوط المتقطعة: 3 م خط / 9 م فراغ
    const per = 4.8, dash = 1.2;
    final base = s.q % per;
    for (final xm in const [-1.8, 1.8]) {
      for (int k = 0; k < 40; k++) {
        final q0 = k * per - base - 0.6;
        if (q0 + dash < qMin) continue;
        if (q0 > qMax || f(math.max(q0, qMin)) * s0 * 0.16 < 0.5) break; // نتوقف قبل أن تتلاصق الخطوط بالأفق
        strip(xm - 0.075, xm + 0.075, math.max(q0, qMin), q0 + dash, Paint()..color = lineC.withOpacity(0.85), 6);
      }
    }
    // عاكسات أرضية تلمع بالليل
    if (lightsOn > 0.3) {
      for (int k = 0; k < 16; k++) {
        final q = k * per * 0.5 - (s.q % (per * 0.5));
        if (q < qc + 0.3) continue;
        for (final xm in const [-half + 0.2, half - 0.2]) {
          c.drawCircle(Offset(X(xm, q), Y(q)), math.max(0.8, 0.09 * s0 * f(q)), Paint()..color = const Color(0xFFFFC46B).withOpacity(lightsOn * _cl(f(q) * 6)));
        }
      }
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
    for (final o in objs) {
      final q = o.$1, sc = s0 * f(q);
      if (o.$2 == 0) {
        final side = o.$3.isEven ? 1.0 : -1.0, xm = side * (half + shoulder + 4 + _hash(o.$3) * 7), ht = 7 + _hash(o.$3 + 3) * 4;
        final bx = X(xm, q), by = Y(q), tx0 = bx + side * 0.6 * sc, ty0 = Y(q, ht);
        final trunkC = _mix(const Color(0xFF080706), const Color(0xFF6B5132), light), leafC = _mix(const Color(0xFF060806), _mix(const Color(0xFF3F6E2F), const Color(0xFF7A8460), s.dust), light);
        final tr = Path()
          ..moveTo(bx, by)
          ..quadraticBezierTo(bx + side * 0.05 * sc, (by + ty0) / 2, tx0, ty0);
        c.drawPath(tr, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 0.4 * sc)
          ..strokeCap = StrokeCap.round
          ..color = trunkC);
        final sway = math.sin(s.t * 1.3 + o.$3) * (0.1 + s.wind * 0.02);
        for (int j = 0; j < 9; j++) {
          final a = (j - 4) * 0.42 + sway, len = (2.6 + _hash(o.$3 * 9 + j) * 0.8) * sc, droop = (0.5 + (j - 4).abs() * 0.28) * sc;
          final ex = tx0 + math.sin(a) * len, ey = ty0 - math.cos(a).abs() * len * 0.25 + droop;
          final fr = Path()
            ..moveTo(tx0, ty0)
            ..quadraticBezierTo(tx0 + math.sin(a) * len * 0.55, ty0 - len * 0.45, ex, ey);
          c.drawPath(fr, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, 0.32 * sc)
            ..strokeCap = StrokeCap.round
            ..color = leafC);
        }
      } else {
        for (final side in const [-1.0, 1.0]) {
          final xm = side * (half + shoulder + 0.6), bx = X(xm, q), by = Y(q), ty0 = Y(q, 10), ax = X(xm - side * 2.2, q);
          final pl = Paint()
            ..strokeWidth = math.max(1.0, 0.2 * sc)
            ..color = _mix(const Color(0xFF1A1C1E), const Color(0xFF8A8F95), light);
          c.drawLine(Offset(bx, by), Offset(bx, ty0), pl);
          c.drawLine(Offset(bx, ty0), Offset(ax, ty0), pl);
          if (lightsOn > 0.05) {
            c.drawCircle(Offset(ax, ty0 + 0.15 * sc), math.max(2.0, 1.6 * sc), Paint()
              ..color = lampC.withOpacity(0.5 * lightsOn)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, 1.6 * sc)));
            c.drawCircle(Offset(ax, ty0 + 0.15 * sc), math.max(0.8, 0.28 * sc), Paint()..color = const Color(0xFFFFE6B8).withOpacity(lightsOn));
            // بقعة الضوء على الطريق (مسقطة بالمنظور)
            final px = X(xm - side * 2.2, q), y0 = Y(math.max(q - 1.4, -0.85)), y1 = Y(q + 1.4);
            c.drawOval(Rect.fromCenter(center: Offset(px, by), width: 7 * sc, height: (y0 - y1).abs() + 2), Paint()
              ..color = lampC.withOpacity(0.18 * lightsOn)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, 1.2 * sc)));
            if (wet > 0.1 && q > qc) wetRefl.add(Offset(px, by));
          }
        }
      }
    }

    // ---------- ضباب الأفق (يُخفي تلاقي الخطوط البعيدة) ----------
    final hc = _mix(hor, land, 0.25);
    final hb = Rect.fromLTRB(0, hz - hh * 0.06, w, hz + hh * 0.1);
    c.drawRect(hb, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [hc.withOpacity(0), hc.withOpacity(0.95), hc.withOpacity(0)], stops: const [0, 0.38, 1]).createShader(hb));
    final murk = math.max(s.fog, s.dust);
    if (murk > 0.02) {
      final mc = s.dust > s.fog ? _mix(const Color(0xFF261C10), const Color(0xFFD7A764), light) : _mix(const Color(0xFF15181B), const Color(0xFFC9CDD1), light);
      c.drawRect(Offset.zero & z, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mc.withOpacity(0.35 * murk), mc.withOpacity(0.92 * murk), mc.withOpacity(0.25 * murk)], stops: [0, hz / h, 1]).createShader(Offset.zero & z));
    }
    // انعكاسات الإنارة على الأسفلت المبلل
    for (final o in wetRefl) {
      final rr = Rect.fromLTRB(o.dx - 3, o.dy, o.dx + 3, math.min(h, o.dy + (h - o.dy) * 0.35));
      c.drawRect(rr, Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lampC.withOpacity(0.35 * wet * lightsOn), lampC.withOpacity(0)]).createShader(rr)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }

    // ---------- ضوء السيارة الأمامي على الطريق ----------
    final beamOn = math.max(lightsOn, murk * 0.8);
    if (beamOn > 0.05) {
      final qa = qc + 1.6, qb = qc + 26, ya = Y(qa), yb = Y(qb);
      final bm = Path()
        ..moveTo(X(-1.1, qa), ya)
        ..lineTo(X(1.1, qa), ya)
        ..lineTo(X(4.5, qb), yb)
        ..lineTo(X(-4.5, qb), yb)
        ..close();
      c.drawPath(bm, Paint()
        ..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [const Color(0xFFFFF4DC).withOpacity(0.42 * beamOn), const Color(0x00FFF4DC)]).createShader(Rect.fromLTRB(0, yb, w, ya))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    // ---------- السيارة ----------
    final bob = (math.sin(s.t * 11) * 0.5 + math.sin(s.t * 23 + 1) * 0.3) * _cl(s.v / 20) * g.cw * 0.004;
    final ox = cx + off(qc) * s0 * fc + s.lean * g.cw * 0.06, oy = g.carY + bob + s.pitch * g.cw * 0.004;
    c.save();
    c.translate(ox, oy);
    c.rotate(s.lean * 0.035);
    _car(c, g.cw, light, wet, day, lightsOn);
    c.restore();

    // ---------- رذاذ الإطارات بالمطر ----------
    if (s.splash > 0.05) {
      for (int i = 0; i < 26; i++) {
        final side = i.isEven ? 1.0 : -1.0, life = (s.t * 2.2 + _hash(i)) % 1;
        final x = ox + side * g.cw * (0.4 + life * 0.25 * _hash(i + 5)), y = oy - g.cw * 0.03 + life * g.cw * 0.35;
        c.drawCircle(Offset(x, y), g.cw * (0.03 + life * 0.07), Paint()
          ..color = _mix(const Color(0xFF2A2E33), const Color(0xFFDDE3E8), light).withOpacity(0.22 * s.splash * (1 - life))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cw * 0.03));
      }
    }

    // ---------- المطر / الثلج ----------
    if (s.rain > 0.02) {
      final n = (40 + 220 * s.rain).round();
      final rp = Paint()
        ..strokeWidth = 1.1
        ..color = _mix(const Color(0xFF8C96A0), const Color(0xFFE2E8EE), light).withOpacity(0.28 + 0.2 * s.rain);
      final slant = s.wind * 0.03;
      for (int i = 0; i < n; i++) {
        final sp = 0.8 + _hash(i + 3) * 0.6, len = (14 + 16 * _hash(i + 7)) * (1 + s.v / 30);
        final x0 = _hash(i) * (w + 60) - 30, y = ((_hash(i + 1) * h + s.t * h * 1.4 * sp) % (h + len)) - len;
        final spread = (x0 - cx) / w * s.v * 0.03; // القطرات تتجه نحوك مع السرعة
        c.drawLine(Offset(x0, y), Offset(x0 - len * (slant + spread), y + len), rp);
      }
    }
    if (s.snow > 0.02) {
      final n = (30 + 160 * s.snow).round();
      for (int i = 0; i < n; i++) {
        final sz = 1 + _hash(i + 2) * 2.4, y = (_hash(i + 1) * h + s.t * (30 + 40 * _hash(i + 4)) * (1 + s.v / 15)) % h;
        final x = (_hash(i) * w + math.sin(s.t + i) * 12 + (_hash(i) * w - cx) * (y / h) * s.v * 0.01) % w;
        c.drawCircle(Offset(x, y), sz, Paint()..color = Colors.white.withOpacity(0.75));
      }
    }
    if (s.flash > 0.01) c.drawRect(Offset.zero & z, Paint()..color = Colors.white.withOpacity(0.35 * s.flash));
  }

  /// سيارة رياضية من الخلف (الوحدة = عرض السيارة؛ y سالب للأعلى، 0 = الأرض)
  void _car(Canvas c, double cw, double light, double wet, double day, double lightsOn) {
    Offset p(double x, double y) => Offset(x * cw, y * cw);
    Rect r(double x0, double y0, double x1, double y1) => Rect.fromPoints(p(x0, y0), p(x1, y1));
    // أوامر المسار: [0,x,y]=انتقال، [1,x,y]=خط، 4 قيم=منحنى تربيعي، 6 قيم=منحنى تكعيبي
    Path path(List<List<double>> cmds) {
      final pa = Path();
      for (final m in cmds) {
        if (m.length == 3) {
          m[0] == 0 ? pa.moveTo(m[1] * cw, m[2] * cw) : pa.lineTo(m[1] * cw, m[2] * cw);
        } else if (m.length == 4) {
          pa.quadraticBezierTo(m[0] * cw, m[1] * cw, m[2] * cw, m[3] * cw);
        } else if (m.length == 6) {
          pa.cubicTo(m[0] * cw, m[1] * cw, m[2] * cw, m[3] * cw, m[4] * cw, m[5] * cw);
        }
      }
      return pa..close();
    }

    final brake = s.brake, tail = s.tail;
    final lit = _cl(tail * 0.6 + brake * 0.9);
    final red = Color.lerp(const Color(0xFF3A060C), const Color(0xFFFF2236), lit)!;
    final blinkOn = s.blink != 0 && (s.t * 1.6) % 1 < 0.55;

    // الظل
    c.drawOval(r(-0.56, -0.03, 0.56, 0.05), Paint()
      ..color = Colors.black.withOpacity(0.55 + 0.25 * day)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.035));
    // انعكاس الأضواء الخلفية على الأرض (أطول على الأسفلت المبلل)
    final rl = 0.25 + 0.5 * wet;
    for (final sd in const [-1.0, 1.0]) {
      final rc = r(sd * 0.36, 0.0, sd * 0.47, 0.25 + wet * 0.9);
      c.drawRect(rc, Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [red.withOpacity(rl * lit), red.withOpacity(0)]).createShader(rc)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.02));
    }
    // الإطارات
    for (final sd in const [-1.0, 1.0]) {
      c.drawRRect(RRect.fromRectAndRadius(r(sd * 0.33, -0.2, sd * 0.478, 0), Radius.circular(cw * 0.03)), Paint()..color = const Color(0xFF060707));
      c.drawRect(r(sd * 0.34, -0.2, sd * 0.468, -0.17), Paint()..color = const Color(0xFF1A1D1D));
    }
    // الهيكل: أوراك عريضة فوق العجلات، ومقصورة منحنية أضيق
    final body = path([
      [0, -0.43, -0.075], [1, -0.488, -0.12],
      [-0.512, -0.17, -0.512, -0.30, -0.49, -0.355],
      [-0.475, -0.405, -0.43, -0.43, -0.37, -0.432],
      [-0.2, -0.44, 0.2, -0.44, 0.37, -0.432],
      [0.43, -0.43, 0.475, -0.405, 0.49, -0.355],
      [0.512, -0.30, 0.512, -0.17, 0.488, -0.12],
      [1, 0.43, -0.075],
      [0, -0.06, -0.43, -0.075],
    ]);
    final cab = path([
      [0, -0.325, -0.425],
      [-0.30, -0.50, -0.26, -0.585, -0.195, -0.612],
      [-0.1, -0.632, 0.1, -0.632, 0.195, -0.612],
      [0.26, -0.585, 0.30, -0.50, 0.325, -0.425],
    ]);
    Color pnt(int d, int n) => Color.lerp(Color(n), Color(d), light)!;
    final paintSh = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [pnt(0xFF57C6A9, 0xFF123A31), pnt(0xFF17705F, 0xFF0A2A23), pnt(0xFF0C4337, 0xFF061C17), pnt(0xFF05211B, 0xFF020A08)],
      stops: const [0, 0.3, 0.62, 1],
    ).createShader(r(-0.5, -0.64, 0.5, -0.06));
    c.drawPath(cab, Paint()..shader = paintSh);
    c.drawPath(body, Paint()..shader = paintSh);
    // تظليل أسطواني وخط لمعان الكتفين
    c.save();
    c.clipPath(body);
    c.drawRect(r(-0.52, -0.45, 0.52, 0), Paint()..shader = const LinearGradient(colors: [Color(0x8C000000), Color(0x00000000), Color(0x00000000), Color(0x8C000000)], stops: [0, 0.16, 0.84, 1]).createShader(r(-0.5, 0, 0.5, 0.01)));
    for (final sd in const [-1.0, 1.0]) {
      final hl = Path()
        ..moveTo(sd * 0.30 * cw, -0.43 * cw)
        ..cubicTo(sd * 0.42 * cw, -0.428 * cw, sd * 0.468 * cw, -0.41 * cw, sd * 0.485 * cw, -0.36 * cw);
      c.drawPath(hl, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cw * 0.008
        ..color = Colors.white.withOpacity(0.15 + 0.35 * light)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.004));
    }
    c.drawRect(r(-0.5, -0.36, 0.5, -0.3), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [red.withOpacity(0.25 * lit), red.withOpacity(0)]).createShader(r(-0.5, -0.36, 0.5, -0.3)));
    c.restore();
    // الزجاج الخلفي
    final gl = path([
      [0, -0.255, -0.44],
      [-0.235, -0.51, -0.205, -0.575, -0.16, -0.594],
      [-0.08, -0.606, 0.08, -0.606, 0.16, -0.594],
      [0.205, -0.575, 0.235, -0.51, 0.255, -0.44],
      [0, -0.432, -0.255, -0.44],
    ]);
    c.drawPath(gl, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [pnt(0xFF3B5E5A, 0xFF101C1B), const Color(0xFF040C0B)]).createShader(r(0, -0.6, 0.01, -0.44)));
    c.save();
    c.clipPath(gl);
    c.drawPath(path([[0, -0.12, -0.62], [1, -0.04, -0.62], [1, -0.16, -0.43], [1, -0.24, -0.43]]), Paint()..color = Colors.white.withOpacity(0.04 + 0.07 * light));
    if (wet > 0.1) {
      for (int i = 0; i < 12; i++) {
        c.drawCircle(p(-0.22 + _hash(i + 60) * 0.44, -0.59 + _hash(i + 61) * 0.14), cw * 0.004, Paint()..color = Colors.white.withOpacity(0.35 * wet));
      }
    }
    c.restore();
    // السقف كما يُرى من الأعلى قليلاً
    c.drawPath(path([[0, -0.18, -0.613], [-0.1, -0.632, 0.1, -0.632, 0.18, -0.613], [0.1, -0.622, -0.1, -0.622, -0.18, -0.613]]), Paint()..color = Colors.white.withOpacity(0.05 + 0.1 * light));
    // ضوء الفرامل الثالث أعلى الزجاج
    final tb = RRect.fromRectAndRadius(r(-0.06, -0.603, 0.06, -0.594), Radius.circular(cw * 0.004));
    if (brake > 0.05) {
      c.drawRRect(tb.inflate(cw * 0.01), Paint()
        ..color = const Color(0xFFFF2236).withOpacity(0.55 * brake)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.012));
    }
    c.drawRRect(tb, Paint()..color = Color.lerp(const Color(0xFF2A0508), const Color(0xFFFF4050), brake)!);
    // المرايا متصلة بالمقصورة
    for (final sd in const [-1.0, 1.0]) {
      c.drawLine(p(sd * 0.29, -0.465), p(sd * 0.33, -0.47), Paint()
        ..strokeWidth = cw * 0.012
        ..color = pnt(0xFF0E4A3D, 0xFF061A15));
      c.drawRRect(RRect.fromRectAndRadius(r(sd * 0.325, -0.495, sd * 0.41, -0.455), Radius.circular(cw * 0.018)), Paint()..color = pnt(0xFF16695A, 0xFF082219));
    }
    // شبك غطاء المحرك
    for (int k = 0; k < 4; k++) {
      final y = -0.392 - k * 0.011;
      c.drawLine(p(-0.15, y), p(0.15, y), Paint()
        ..strokeWidth = math.max(1.0, cw * 0.004)
        ..color = Colors.black.withOpacity(0.5));
    }
    // شريط الإضاءة الخلفي: غلاف مدخّن + خط LED، والطرفان كتلتان (فرامل/إشارة)
    final lb = path([[0, -0.475, -0.373], [-0.2, -0.392, 0.2, -0.392, 0.475, -0.373], [1, 0.475, -0.357], [0.2, -0.375, -0.2, -0.375, -0.475, -0.357]]);
    c.drawPath(lb, Paint()..color = const Color(0xFF1A0306));
    final led = Path()
      ..moveTo(-0.46 * cw, -0.366 * cw)
      ..cubicTo(-0.2 * cw, -0.384 * cw, 0.2 * cw, -0.384 * cw, 0.46 * cw, -0.366 * cw);
    c.drawPath(led, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cw * (0.04 + 0.05 * brake)
      ..color = red.withOpacity(0.25 + 0.5 * lit)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * (0.015 + 0.03 * brake)));
    c.drawPath(led, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cw * 0.007
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(red, Colors.white, 0.35 * lit)!);
    for (final sd in const [-1.0, 1.0]) {
      final blinkHere = blinkOn && s.blink == sd;
      final cl = path([[0, sd * 0.392, -0.383], [1, sd * 0.478, -0.372], [sd * 0.492, -0.366, sd * 0.49, -0.352], [1, sd * 0.395, -0.352]]);
      final cc = blinkHere ? const Color(0xFFFFA51F) : red;
      c.drawPath(cl, Paint()
        ..color = cc.withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * (0.02 + 0.03 * (blinkHere ? 1.0 : brake))));
      c.drawPath(cl, Paint()..color = cc);
      c.drawRRect(RRect.fromRectAndRadius(r(sd * 0.43, -0.16, sd * 0.47, -0.145), Radius.circular(cw * 0.005)), Paint()..color = const Color(0xFF7A0A14));
    }
    // خط المصد والشعار
    c.drawLine(p(-0.47, -0.2), p(0.47, -0.2), Paint()
      ..strokeWidth = math.max(1.0, cw * 0.004)
      ..color = Colors.black.withOpacity(0.45));
    c.drawCircle(p(0, -0.335), cw * 0.012, Paint()..color = kGold.withOpacity(0.5 + 0.5 * light));
    // اللوحة + إضاءتها بالليل
    final pl = r(-0.105, -0.29, 0.105, -0.235);
    c.drawRRect(RRect.fromRectAndRadius(pl, Radius.circular(cw * 0.008)), Paint()..color = Color.lerp(const Color(0xFF3A3A36), const Color(0xFFEEEBE2), _cl(light + lightsOn * 0.8))!);
    if (_plate == null || (_plateW - cw).abs() > 1) {
      _plateW = cw;
      _plate = TextPainter(text: TextSpan(text: 'منبر', style: TextStyle(fontFamily: 'Cairo', fontSize: cw * 0.038, fontWeight: FontWeight.w700, color: kGreen, height: 1)), textDirection: TextDirection.rtl)..layout();
    }
    _plate!.paint(c, pl.center - Offset(_plate!.width / 2, _plate!.height / 2));
    // الناشر والعادم
    c.drawRRect(RRect.fromRectAndRadius(r(-0.36, -0.165, 0.36, -0.075), Radius.circular(cw * 0.02)), Paint()..color = const Color(0xFF050C0B));
    for (final x in const [-0.2, -0.1, 0.0, 0.1, 0.2]) {
      c.drawLine(p(x, -0.155), p(x, -0.085), Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.08));
    }
    for (final sd in const [-1.0, 1.0]) {
      final ex = r(sd * 0.07, -0.14, sd * 0.15, -0.1);
      c.drawRRect(RRect.fromRectAndRadius(ex, Radius.circular(cw * 0.02)), Paint()..color = Color.lerp(const Color(0xFF3A4442), const Color(0xFFB9C4C0), light)!);
      c.drawRRect(RRect.fromRectAndRadius(ex.deflate(cw * 0.008), Radius.circular(cw * 0.014)), Paint()..color = const Color(0xFF070909));
    }
    c.drawPath(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.06 + 0.06 * light));
  }

  @override
  bool shouldRepaint(covariant _World o) => o.g.hz != g.hz || o.g.cx != g.cx || o.g.carY != g.carY || o.g.cw != g.cw;
}
