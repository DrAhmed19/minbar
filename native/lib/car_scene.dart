part of 'car.dart';

// ======================= المنطقة: تحديد المحافظة والحي ونوع المكان =======================
const _bCity = 0, _bDesert = 1, _bFarm = 2, _bMount = 3, _bMarsh = 4;
const _biomeNames = {-1: 'تلقائي', _bCity: 'مدينة', _bDesert: 'صحراء', _bFarm: 'ريف ونخيل', _bMount: 'جبال', _bMarsh: 'أهوار'};

class _Region {
  final String place, sub;
  final int biome;
  const _Region(this.place, this.sub, this.biome);
}

int _biomeFor(String gov, String country, bool urban) {
  bool has(List<String> ks) => ks.any((k) => gov.contains(k));
  if (urban) return _bCity;
  if (has(['دهوك', 'أربيل', 'اربيل', 'السليمانية', 'حلبجة', 'Duhok', 'Erbil', 'Sulay', 'Halabja'])) return _bMount;
  if (has(['البصرة', 'ميسان', 'ذي قار', 'Basra', 'Maysan', 'Dhi Qar'])) return _bMarsh;
  if (has(['الأنبار', 'الانبار', 'المثنى', 'Anbar', 'Muthanna'])) return _bDesert;
  return _bFarm;
}

/// تحويل الإحداثيات إلى اسم المحافظة والحي (OpenStreetMap)، ومعرفة إن كان المكان مدينة أو خارجها
Future<_Region?> _reverse(double lat, double lon) async {
  final c = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..userAgent = 'MinbarApp/1.0 (Android; car mode)';
  try {
    final rq = await c.getUrl(Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat.toStringAsFixed(5)}&lon=${lon.toStringAsFixed(5)}&zoom=16&accept-language=ar'));
    final r = await rq.close().timeout(const Duration(seconds: 10));
    final m = jsonDecode(await r.transform(utf8.decoder).join()) as Map<String, dynamic>;
    final a = (m['address'] as Map?)?.cast<String, dynamic>() ?? {};
    String g(String k) => (a[k] ?? '').toString();
    var gov = g('state');
    gov = gov.replaceFirst('محافظة ', '').trim();
    final city = [g('city'), g('town')].firstWhere((x) => x.isNotEmpty, orElse: () => '');
    final hood = [g('neighbourhood'), g('suburb'), g('quarter'), g('city_district')].firstWhere((x) => x.isNotEmpty, orElse: () => '');
    final rural = [g('village'), g('hamlet')].firstWhere((x) => x.isNotEmpty, orElse: () => '');
    final type = (m['addresstype'] ?? '').toString();
    final urban = (city.isNotEmpty && hood.isNotEmpty) || const ['suburb', 'neighbourhood', 'quarter', 'city_block', 'residential'].contains(type);
    final sub = hood.isNotEmpty ? hood : (city.isNotEmpty ? city : (rural.isNotEmpty ? rural : g('road')));
    final place = gov.isNotEmpty ? gov : (city.isNotEmpty ? city : g('country'));
    return _Region(place, sub == place ? '' : sub, _biomeFor('${g('state')} $gov', g('country'), urban));
  } catch (e) {
    debugPrint('car geo fail $e');
    return null;
  } finally {
    c.close();
  }
}

/// معالم بارزة تظهر بالأفق باتجاهها الحقيقي عند الاقتراب منها (أقل من 45 كم)
const _landmarks = <(double, double, int)>[
  (33.3127, 44.3730, 0), // برج بغداد
  (33.3438, 44.4236, 1), // نصب الشهيد
  (33.0934, 44.5804, 2), // طاق كسرى
  (36.1912, 44.0093, 3), // قلعة أربيل
  (30.9626, 46.1031, 4), // زقورة أور
];

// ======================= نباتات ومبانٍ صغيرة كصور متجهة مسجّلة =======================
class _Flora {
  static final Map<String, ui.Picture> _pics = {};
  static Color _t(int day, double light, double dust) => _mix(_mix(const Color(0xFF0E1216), Color(day), light), const Color(0xFFD8BC8A), dust * 0.45);

  /// type: 0 كالبتوس، 1 صنوبر، 2 بلوط، 3 شجيرة صحراوية، 4 قصب، 5 صخرة، 6 بيت طيني، 7 مضيف قصب
  static ui.Picture get(int type, int v, double light, double dust) {
    final lq = (light * 14).round(), dq = (dust * 3).round(), key = '$type|$v|$lq|$dq';
    return _pics[key] ??= () {
      if (_pics.length > 90) _pics.clear();
      final rec = ui.PictureRecorder(), c = Canvas(rec), r = math.Random(type * 97 + v * 13);
      Color L(int d) => _t(d, lq / 14, dq / 3);
      // الإحداثيات: القاعدة عند (0,0)، الارتفاع 100 وحدة للأشجار
      switch (type) {
        case 0: // كالبتوس: جذع رفيع فاتح وتاج متدلٍّ من عناقيد
          c.drawPath(
              Path()
                ..moveTo(-3, 0)
                ..quadraticBezierTo(-2 + v * 2.0, -50, 1 + v * 3.0, -78)
                ..lineTo(4 + v * 3.0, -78)
                ..quadraticBezierTo(2 + v * 2.0, -50, 3, 0)
                ..close(),
              Paint()..color = L(0xFFB8AA92));
          for (int i = 0; i < 26; i++) {
            final a = r.nextDouble() * math.pi * 2, d = r.nextDouble();
            final x = 2 + v * 3.0 + math.cos(a) * 22 * d, y = -82 + math.sin(a) * 18 * d + d * 6;
            c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 12 + r.nextDouble() * 10, height: 9 + r.nextDouble() * 9), Paint()..color = L(_mix(const Color(0xFF3E5A2E), const Color(0xFF6E8A4E), r.nextDouble() * (0.4 + 0.6 * (1 - d))).value));
          }
        case 1: // صنوبر: طبقات مثلثية
          c.drawRect(const Rect.fromLTWH(-3, -14, 6, 14), Paint()..color = L(0xFF4A3420));
          for (int i = 0; i < 6; i++) {
            final y = -12 - i * 14.0, wd = 34 - i * 5.0;
            c.drawPath(
                Path()
                  ..moveTo(-wd, y)
                  ..lineTo(0, y - 26)
                  ..lineTo(wd, y)
                  ..close(),
                Paint()..color = L(_mix(const Color(0xFF1E3A22), const Color(0xFF2F5A33), i / 6).value));
          }
        case 2: // بلوط: تاج دائري كثيف
          c.drawPath(
              Path()
                ..moveTo(-4, 0)
                ..lineTo(-3, -40)
                ..lineTo(3, -40)
                ..lineTo(4, 0)
                ..close(),
              Paint()..color = L(0xFF4A3420));
          for (int i = 0; i < 18; i++) {
            final a = r.nextDouble() * math.pi * 2, d = math.sqrt(r.nextDouble());
            c.drawCircle(Offset(math.cos(a) * 26 * d, -58 + math.sin(a) * 20 * d), 10 + r.nextDouble() * 8, Paint()..color = L(_mix(const Color(0xFF2E4A24), const Color(0xFF5A7A3A), (1 - math.sin(a)) * 0.4 + r.nextDouble() * 0.3).value));
          }
        case 3: // شجيرة صحراوية (عاقول)
          for (int i = 0; i < 22; i++) {
            final a = -math.pi + r.nextDouble() * math.pi, l = 8 + r.nextDouble() * 12;
            c.drawLine(Offset.zero, Offset(math.cos(a) * l * 1.4, math.sin(a) * l), Paint()
              ..strokeWidth = 1.6
              ..color = L(_mix(const Color(0xFF6B6A3A), const Color(0xFF8F8550), r.nextDouble()).value));
          }
        case 4: // قصب
          for (int i = 0; i < 26; i++) {
            final x = (r.nextDouble() - 0.5) * 30, hgt = 40 + r.nextDouble() * 45, lean = (r.nextDouble() - 0.5) * 12;
            c.drawLine(Offset(x, 0), Offset(x + lean, -hgt), Paint()
              ..strokeWidth = 1.8
              ..color = L(_mix(const Color(0xFF7A8A4A), const Color(0xFFB8A86A), r.nextDouble()).value));
            if (r.nextDouble() < 0.4) c.drawOval(Rect.fromCenter(center: Offset(x + lean, -hgt), width: 4, height: 9), Paint()..color = L(0xFFC9B48A));
          }
        case 5: // صخرة
          final pa = Path()..moveTo(-14, 0);
          for (int i = 0; i <= 6; i++) {
            final a = math.pi + i / 6 * math.pi;
            pa.lineTo(math.cos(a) * (12 + r.nextDouble() * 5), math.sin(a) * (7 + r.nextDouble() * 6));
          }
          pa.close();
          c.drawPath(pa, Paint()..shader = ui.Gradient.linear(const Offset(0, -12), Offset.zero, [L(0xFF9A8C78), L(0xFF5E5446)]));
        case 6: // بيت طيني بسيط مع سياج سطح
          c.drawRect(const Rect.fromLTWH(-30, -26, 60, 26), Paint()..color = L(0xFFB89A6A));
          c.drawRect(const Rect.fromLTWH(-30, -30, 60, 4), Paint()..color = L(0xFFA08458));
          c.drawRect(const Rect.fromLTWH(-6, -16, 12, 16), Paint()..color = L(0xFF3A2A18));
          for (final x in const [-22.0, 14.0]) {
            c.drawRect(Rect.fromLTWH(x, -20, 8, 7), Paint()..color = L(0xFF2A2018));
          }
          c.drawRect(const Rect.fromLTWH(16, -40, 10, 10), Paint()..color = L(0xFFD8D8D0)); // خزان ماء
        case 7: // مضيف قصب أهواري بأقواس
          final hut = Path()
            ..moveTo(-40, 0)
            ..lineTo(-40, -18)
            ..cubicTo(-40, -44, 40, -44, 40, -18)
            ..lineTo(40, 0)
            ..close();
          c.drawPath(hut, Paint()..shader = ui.Gradient.linear(const Offset(0, -40), Offset.zero, [L(0xFFD6BE84), L(0xFF9A8250)]));
          for (int i = -3; i <= 3; i++) {
            c.drawLine(Offset(i * 11.0, -2), Offset(i * 11.0 * 0.9, -34 + i.abs() * 2.2), Paint()
              ..strokeWidth = 1.4
              ..color = L(0xFF7A6438));
          }
          c.drawPath(
              Path()
                ..moveTo(-8, 0)
                ..lineTo(-8, -14)
                ..quadraticBezierTo(0, -24, 8, -14)
                ..lineTo(8, 0)
                ..close(),
              Paint()..color = L(0xFF2A2010));
      }
      return rec.endRecording();
    }();
  }
}

// ======================= العالم =======================
/// العالم: سماء حقيقية، أرض حسب المنطقة، طريق بمنظور هندسي بالأمتار، أجسام جانبية، طقس، وسيارة
class _World extends CustomPainter {
  /// مستوى الجودة يتكيّف مع قدرة الجهاز: 2 كامل، 1 أخف، 0 أخف ما يمكن
  static int q = 2;
  final _Scene s;
  final _Stage g;
  _World(this.s, this.g, Listenable r) : super(repaint: r);
  static TextPainter? _plate;
  static double _plateW = 0;
  static const _r64 = Rect.fromLTWH(0, 0, 64, 64);
  static const half = 5.4, shoulder = 1.6, qMin = -0.9, qMax = 70.0;

  late Canvas c;
  late double w, h, hz, cx, hh, fc, s0, qc, el, day, golden, over, light0, light, lightsOn, murk, wet;
  late Color top, mid, hor, land;

  // دفعة توهّجات تُرسم بنداء واحد
  final _gT = <RSTransform>[], _gC = <Color>[];
  void _glow(Offset o, double r, Color col) {
    if (r < 0.5 || col.alpha < 3) return;
    _gT.add(RSTransform.fromComponents(rotation: 0, scale: r / 32, anchorX: 32, anchorY: 32, translateX: o.dx, translateY: o.dy));
    _gC.add(col);
  }

  void _flush() {
    if (_gT.isEmpty) return;
    if (_Art.ready) c.drawAtlas(_Art.dot, _gT, List.filled(_gT.length, _r64), _gC, BlendMode.modulate, null, Paint());
    _gT.clear();
    _gC.clear();
  }

  // ---------- الإسقاط ----------
  double f(double q) => 1 / (1 + q);
  double off(double q) {
    final d = q - qc;
    return s.curv * 3.125 * d * d / (1 + d.abs() / 30);
  }

  double X(double xm, double q) => cx + (xm + off(q)) * s0 * f(q);
  double Y(double q, [double ym = 0]) => hz + (hh - ym * s0) * f(q);
  Offset P(double xm, double q, [double ym = 0]) => Offset(X(xm, q), Y(q, ym));
  double sxOf(double az) => cx + (((az - s.heading + 540) % 360) - 180) / 55 * (w / 2);
  double skyY(double e) => hz - _cl(e / 42, -0.1, 1.1) * hz * 0.95;

  List<double> _qs(double q0, double q1, int n) {
    final f0 = f(q0), f1 = f(q1);
    return List<double>.generate(n + 1, (i) => 1 / (f0 * math.pow(f1 / f0, i / n)) - 1);
  }

  void strip(double x0, double x1, double q0, double q1, Paint p, [int n = 36]) {
    final qs = _qs(q0, q1, n), pa = Path();
    for (int i = 0; i <= n; i++) {
      i == 0 ? pa.moveTo(X(x0, qs[i]), Y(qs[i])) : pa.lineTo(X(x0, qs[i]), Y(qs[i]));
    }
    for (int i = n; i >= 0; i--) {
      pa.lineTo(X(x1, qs[i]), Y(qs[i]));
    }
    c.drawPath(pa..close(), p);
  }

  void ribbon(double xm, double y0, double y1, double q0, double q1, Paint p, [int n = 40]) {
    final qs = _qs(q0, q1, n), pa = Path();
    for (int i = 0; i <= n; i++) {
      i == 0 ? pa.moveTo(X(xm, qs[i]), Y(qs[i], y1)) : pa.lineTo(X(xm, qs[i]), Y(qs[i], y1));
    }
    for (int i = n; i >= 0; i--) {
      pa.lineTo(X(xm, qs[i]), Y(qs[i], y0));
    }
    c.drawPath(pa..close(), p);
  }

  Color shadeL(Color dayC, [Color? nightC]) => _mix(nightC ?? _mix(dayC, const Color(0xFF05080C), 0.88), dayC, light);

  @override
  void paint(Canvas canvas, Size z) {
    _Art.ensure();
    c = canvas;
    w = z.width;
    h = z.height;
    hz = g.hz;
    cx = g.cx;
    hh = h - hz;
    fc = _cl((g.carY - hz) / hh, 0.05, 0.95);
    s0 = g.cw / (1.85 * fc);
    qc = 1 / fc - 1;
    el = s.sunEl;
    day = _sm(-7, 7, el);
    golden = el > -6 ? _cl(1 - (el - 2).abs() / 10) : 0.0;
    over = _cl(s.cloud * 0.75 + s.rain * 0.25);
    light0 = _cl((0.06 + 0.94 * day) * (1 - 0.35 * over));
    light = _cl(light0 + s.flash * 0.6);
    lightsOn = 1 - _sm(-3, 5, el);
    murk = math.max(s.fog, s.dust);
    wet = _cl(s.rain * 1.4 + s.snow * 0.5);
    _sky();
    _horizon();
    _ground();
    _road();
    _sides();
    _atmos();
    _beam();
    _car();
    _weather();
  }

  // ======================= السماء =======================
  void _sky() {
    top = _mix(const Color(0xFF01040B), const Color(0xFF2A64B8), day);
    hor = _mix(const Color(0xFF0D1B2F), const Color(0xFFB7D8F0), day);
    top = _mix(top, const Color(0xFF2E3A66), golden * 0.55);
    hor = _mix(hor, const Color(0xFFF28A50), golden * 0.85);
    top = _mix(top, _mix(const Color(0xFF0D1115), const Color(0xFF6F7B87), day), over);
    hor = _mix(hor, _mix(const Color(0xFF171C21), const Color(0xFFA7AFB7), day), over);
    final dustC = _mix(const Color(0xFF2A2014), const Color(0xFFC99A5A), day);
    top = _mix(top, dustC, s.dust * 0.85);
    hor = _mix(hor, _mix(dustC, const Color(0xFFE0B676), day), s.dust);
    mid = _mix(_mix(top, hor, 0.55), const Color(0xFFE8A070), golden * 0.25);
    final sky = Rect.fromLTRB(0, 0, w, hz + 2);
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(top, Colors.white, s.flash * 0.5), _mix(mid, Colors.white, s.flash * 0.45), _mix(hor, Colors.white, s.flash * 0.4)], stops: const [0, 0.6, 1]).createShader(sky));
    final st = (1 - day) * (1 - over) * (1 - s.dust);
    if (st > 0.02) {
      final b = [<Offset>[], <Offset>[], <Offset>[]];
      for (int i = 0; i < 140; i++) {
        b[((_hash(i) * 7 + s.t * (0.2 + _hash(i + 9) * 0.5)) % 3).floor()].add(Offset(_hash(i) * w, _hash(i + 500) * hz * 0.92));
      }
      for (int k = 0; k < 3; k++) {
        c.drawPoints(ui.PointMode.points, b[k], Paint()
          ..strokeWidth = 1.1 + k * 0.7
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(_cl(st * (0.3 + k * 0.3))));
      }
    }
    if (el > -3) {
      final x = sxOf(s.sunAz), y = skyY(el), rs = w * 0.035, vis = _cl(1 - over * 0.85 - s.dust * 0.55);
      if (x > -w * 0.4 && x < w * 1.4) {
        final sc = _mix(const Color(0xFFFF8A40), const Color(0xFFFFF6DE), _sm(0, 22, el));
        _glow(Offset(x, y), rs * 9, sc.withOpacity(0.35 * vis + 0.08));
        _glow(Offset(x, y), rs * 3, sc.withOpacity(0.6 * vis + 0.1));
        _flush();
        c.drawCircle(Offset(x, y), rs, Paint()..color = _mix(sc, Colors.white, 0.3).withOpacity(_cl(vis + 0.2)));
      }
    }
    if (s.moonEl > -2 && day < 0.85) {
      final x = sxOf(s.moonAz), y = skyY(s.moonEl), rm = w * 0.026, vis = _cl((1 - day) * (1 - over * 0.8));
      if (x > -rm && x < w + rm && vis > 0.03) {
        _glow(Offset(x, y), rm * 6, const Color(0xFFF3EEDB).withOpacity(0.22 * vis));
        _flush();
        final disk = Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: rm));
        final ph = s.moonPh, k = ph < 0.5 ? -ph * 4 * rm : (1 - ph) * 4 * rm;
        final shd = Path()..addOval(Rect.fromCircle(center: Offset(x + k, y), radius: rm * 1.02));
        c.drawPath(disk, Paint()..color = const Color(0xFF2A2F38).withOpacity(0.55 * vis));
        c.drawPath(Path.combine(PathOperation.difference, disk, shd), Paint()..color = const Color(0xFFF3EEDB).withOpacity(vis));
        c.drawCircle(Offset(x - rm * 0.3, y - rm * 0.2), rm * 0.22, Paint()..color = const Color(0xFFCFC8B0).withOpacity(0.35 * vis));
      }
    }
    final cLit = _mix(_mix(_mix(Colors.white, const Color(0xFFFFC090), golden * 0.7), const Color(0xFFA2ABB4), over * 0.8), const Color(0xFF1B2128), 1 - light0);
    final cBase = _mix(_mix(const Color(0xFF8E98A3), const Color(0xFF5A6370), over), const Color(0xFF0B0E12), 1 - light0);
    final nCl = (2 + s.cloud * 10).round();
    for (int i = 0; i < nCl; i++) {
      final cw0 = w * (0.35 + _hash(i + 40) * 0.45) * (1 - _hash(i + 30) * 0.4);
      final x = ((_hash(i + 20) * (w + cw0) + s.t * (2 + s.wind * 1.5) * (0.4 + _hash(i))) % (w + cw0 * 2)) - cw0, y = _hash(i + 30) * hz * 0.6 - cw0 * 0.12;
      c.save();
      c.translate(x, y);
      c.scale(cw0 / 512);
      c.drawPicture(_Art.cloud(i % 3, _mix(cLit, Colors.white, s.flash), cBase, 0.85 + 0.15 * s.cloud));
      c.restore();
    }
    if (over > 0.55) {
      c.drawRect(Rect.fromLTRB(0, 0, w, hz * 0.7), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top.withOpacity(0.8 * (over - 0.55) / 0.45), top.withOpacity(0)]).createShader(Rect.fromLTRB(0, 0, w, hz * 0.7)));
    }
  }

  // ======================= الأفق: جبال/مدينة/بساتين حسب المنطقة + معالم =======================
  void _horizon() {
    final b = s.biome;
    land = switch (b) {
      _bCity => const Color(0xFF8E8778),
      _bFarm => const Color(0xFF8C8A55),
      _bMount => const Color(0xFF6E7F48),
      _bMarsh => const Color(0xFF7E8458),
      _ => const Color(0xFFC9A46C),
    };
    land = shadeL(land);
    land = _mix(land, _mix(const Color(0xFF16130E), _mix(land, Colors.black, 0.2), light), s.rain * 0.5);
    land = _mix(land, _mix(const Color(0xFF2A2D33), const Color(0xFFE9EDF0), light), s.snow);
    final hp = s.heading * math.pi / 180;
    // طبقات الجبال: عالية بالشمال، تلال خفيفة بغيره
    final layers = b == _bMount ? 3 : 2;
    for (int layer = 0; layer < layers; layer++) {
      final amp = b == _bMount ? [0.34, 0.22, 0.12][layer] : (b == _bDesert ? [0.06, 0.03][layer] : [0.035, 0.02][layer]);
      final fr = [2.2, 4.0, 7.0][layer];
      final pa = Path()..moveTo(0, hz);
      final pts = <Offset>[];
      for (int i = 0; i <= 80; i++) {
        final x = w * i / 80, u = x / w + hp * (0.6 + layer * 0.4);
        final n = 0.55 + 0.3 * math.sin(u * fr * 3.1 + layer) + 0.15 * math.sin(u * fr * 7.3 + 2) + 0.06 * math.sin(u * 37 + layer);
        final y = hz - hh * amp * _cl(n, 0.05, 1.2);
        pa.lineTo(x, y);
        pts.add(Offset(x, y));
      }
      pa
        ..lineTo(w, hz)
        ..close();
      final far = layers - 1 - layer; // 0 الأقرب
      final base = b == _bMount ? _mix(const Color(0xFF5A6E44), const Color(0xFF7A7E78), far / 2) : (b == _bDesert ? const Color(0xFFC09868) : const Color(0xFF7E8458));
      final hc0 = _mix(shadeL(base), hor, [0.25, 0.5, 0.72][math.min(far, 2)] + murk * 0.3);
      c.drawPath(pa, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(hc0, Colors.white, 0.08 * light), _mix(hc0, Colors.black, 0.12)]).createShader(Rect.fromLTRB(0, hz - hh * amp * 1.2, w, hz)));
      // قمم ثلجية بالجبال إذا الجو بارد أو ثلج
      if (b == _bMount && layer == 0 && (s.snow > 0.1 || (s.temp.isFinite && s.temp < 10))) {
        final cap = Path();
        for (int i = 1; i < pts.length - 1; i++) {
          final p0 = pts[i];
          if (p0.dy < hz - hh * amp * 0.75 && p0.dy <= pts[i - 1].dy && p0.dy <= pts[i + 1].dy) {
            cap.addPolygon([Offset(p0.dx - w * 0.04, p0.dy + hh * 0.04), p0, Offset(p0.dx + w * 0.04, p0.dy + hh * 0.04)], true);
          }
        }
        c.drawPath(cap, Paint()..color = _mix(_mix(Colors.white, const Color(0xFF8090A0), 1 - light), hor, 0.3));
      }
    }
    // خط أفق المدينة أو البساتين
    if (b == _bCity) {
      for (int i = 0; i < 46; i++) {
        final x = (_hash(i + 300) * w * 2.5 - s.heading / 360 * w * 2.5) % (w * 2.5) - w * 0.2;
        if (x < -40 || x > w + 40) continue;
        final bw = w * (0.02 + _hash(i + 301) * 0.05), bh = hh * (0.03 + _hash(i + 302) * 0.12);
        c.drawRect(Rect.fromLTWH(x, hz - bh, bw, bh + 1), Paint()..color = _mix(_mix(const Color(0xFF6A6C70), const Color(0xFF0A0C10), 1 - light), hor, 0.55 + murk * 0.3));
        if (lightsOn > 0.2) {
          for (int k = 0; k < 4; k++) {
            if (_hash(i * 9 + k) > 0.55) _glow(Offset(x + bw * (0.2 + 0.6 * _hash(i * 7 + k)), hz - bh * (0.2 + 0.7 * _hash(i * 5 + k))), 1.4, const Color(0xFFFFD69A).withOpacity(0.8 * lightsOn));
          }
        }
      }
      _flush();
    } else if (b == _bFarm || b == _bMarsh) {
      // صف بساتين بعيد على الأفق
      final pc = _mix(_mix(const Color(0xFF3E5A2E), const Color(0xFF0B0E0C), 1 - light), hor, 0.55 + murk * 0.3);
      final pa = Path()..moveTo(0, hz);
      for (int i = 0; i <= 120; i++) {
        final x = w * i / 120, u = x / w * 9 + hp * 4;
        pa.lineTo(x, hz - hh * (0.012 + 0.018 * (0.5 + 0.5 * math.sin(u * 3.7)) * (0.6 + 0.4 * math.sin(u * 1.3))));
      }
      c.drawPath(
          pa
            ..lineTo(w, hz)
            ..close(),
          Paint()..color = pc);
    }
    if (lightsOn > 0.1 && b != _bCity) {
      for (int i = 0; i < 60; i++) {
        final x = (_hash(i + 900) * w * 4 - s.heading / 360 * w * 4) % (w * 4);
        if (x > w) continue;
        _glow(Offset(x, hz - hh * (0.003 + _hash(i + 901) * 0.01)), 1.4 + _hash(i + 902) * 2, _mix(const Color(0xFFFFC27A), Colors.white, _hash(i + 903)).withOpacity(lightsOn * (0.35 + 0.5 * _hash(i + 904)) * (1 - murk)));
      }
      _flush();
    }
    for (final m in s.marks) {
      _landmark(m.$3, sxOf(m.$1), m.$2);
    }
  }

  /// معلم بالأفق: برج بغداد، نصب الشهيد، طاق كسرى، قلعة أربيل، زقورة أور
  void _landmark(int type, double x, double km) {
    final sz = w * _cl(0.05 + 3.0 / (km + 6), 0.05, 0.42), by = hz - hh * 0.01;
    if (x < -sz || x > w + sz) return;
    final haze = _cl(km / 50 + murk * 0.7, 0, 0.8);
    Color col(int d) => _mix(_mix(_mix(Color(d), const Color(0xFF080A0E), 0.85), Color(d), light), hor, haze);
    final p = Paint();
    switch (type) {
      case 0: // برج بغداد: عمود رفيع، صحن مطعم، هوائي
        c.drawRect(Rect.fromLTRB(x - sz * 0.035, by - sz * 1.2, x + sz * 0.035, by), p..color = col(0xFFB8B8B4));
        c.drawRect(Rect.fromLTRB(x - sz * 0.11, by - sz * 0.05, x + sz * 0.11, by), p..color = col(0xFF9A9A94));
        c.drawOval(Rect.fromCenter(center: Offset(x, by - sz * 1.2), width: sz * 0.36, height: sz * 0.14), p..color = col(0xFFA8AAA6));
        c.drawRect(Rect.fromLTRB(x - sz * 0.14, by - sz * 1.33, x + sz * 0.14, by - sz * 1.25), p..color = col(0xFF6E7A86));
        c.drawRect(Rect.fromLTRB(x - sz * 0.012, by - sz * 1.7, x + sz * 0.012, by - sz * 1.33), p..color = col(0xFFD0D0CC));
        if (lightsOn > 0.2) _glow(Offset(x, by - sz * 1.7), sz * 0.06, const Color(0xFFFF4040).withOpacity(lightsOn * (0.5 + 0.5 * math.sin(s.t * 3))));
      case 1: // نصب الشهيد: قبة فيروزية منشقة نصفين
        c.drawRect(Rect.fromLTRB(x - sz * 0.7, by - sz * 0.08, x + sz * 0.7, by), p..color = col(0xFF8A8278));
        for (final sd in const [-1.0, 1.0]) {
          final half0 = Path()
            ..moveTo(x + sd * sz * 0.06, by - sz * 0.08)
            ..lineTo(x + sd * sz * 0.06, by - sz * 0.62)
            ..cubicTo(x + sd * sz * 0.3, by - sz * 0.6, x + sd * sz * 0.48, by - sz * 0.35, x + sd * sz * 0.5, by - sz * 0.08)
            ..close();
          c.drawPath(half0, p..shader = LinearGradient(colors: [col(0xFF2FA8B8), col(0xFF1A6E7E)]).createShader(Rect.fromLTRB(x - sz * 0.5, by - sz * 0.62, x + sz * 0.5, by)));
          p.shader = null;
        }
        c.drawRect(Rect.fromLTRB(x - sz * 0.012, by - sz * 0.5, x + sz * 0.012, by - sz * 0.08), p..color = col(0xFFD8C890));
      case 2: // طاق كسرى: قوس فارسي عظيم وجدار بطاقات
        c.drawRect(Rect.fromLTRB(x - sz * 0.7, by - sz * 0.55, x - sz * 0.22, by), p..color = col(0xFFB09068));
        final arch = Path()
          ..moveTo(x - sz * 0.22, by)
          ..lineTo(x - sz * 0.22, by - sz * 0.45)
          ..quadraticBezierTo(x, by - sz * 1.05, x + sz * 0.22, by - sz * 0.45)
          ..lineTo(x + sz * 0.22, by)
          ..lineTo(x + sz * 0.15, by)
          ..lineTo(x + sz * 0.15, by - sz * 0.42)
          ..quadraticBezierTo(x, by - sz * 0.88, x - sz * 0.15, by - sz * 0.42)
          ..lineTo(x - sz * 0.15, by)
          ..close();
        c.drawPath(arch, p..color = col(0xFFC0A078));
        for (int k = 0; k < 4; k++) {
          for (int j = 0; j < 4; j++) {
            c.drawRect(Rect.fromLTWH(x - sz * (0.66 - j * 0.11), by - sz * (0.5 - k * 0.12), sz * 0.05, sz * 0.07), p..color = col(0xFF6A5438));
          }
        }
      case 3: // قلعة أربيل: تلة بجدار مسنّن
        final hill = Path()
          ..moveTo(x - sz * 0.9, by)
          ..quadraticBezierTo(x - sz * 0.75, by - sz * 0.32, x - sz * 0.55, by - sz * 0.34)
          ..lineTo(x + sz * 0.55, by - sz * 0.34)
          ..quadraticBezierTo(x + sz * 0.75, by - sz * 0.32, x + sz * 0.9, by)
          ..close();
        c.drawPath(hill, p..color = col(0xFFA8906A));
        c.drawRect(Rect.fromLTRB(x - sz * 0.55, by - sz * 0.48, x + sz * 0.55, by - sz * 0.33), p..color = col(0xFFC8B088));
        for (int k = 0; k < 12; k++) {
          c.drawRect(Rect.fromLTWH(x - sz * 0.55 + k * sz * 0.0917, by - sz * 0.52, sz * 0.05, sz * 0.05), p..color = col(0xFFC8B088));
        }
        c.drawRect(Rect.fromLTRB(x - sz * 0.07, by - sz * 0.42, x + sz * 0.07, by - sz * 0.33), p..color = col(0xFF4A3A28));
      case 4: // زقورة أور: مدرجات وسلالم
        for (int k = 0; k < 3; k++) {
          final ww = sz * (0.9 - k * 0.25), hh0 = sz * 0.16;
          c.drawRect(Rect.fromLTRB(x - ww, by - hh0 * (k + 1), x + ww, by - hh0 * k), p..color = col([0xFFB8946A, 0xFFAA8860, 0xFF9C7C56][k]));
        }
        c.drawPath(
            Path()
              ..moveTo(x - sz * 0.06, by)
              ..lineTo(x - sz * 0.04, by - sz * 0.48)
              ..lineTo(x + sz * 0.04, by - sz * 0.48)
              ..lineTo(x + sz * 0.06, by)
              ..close(),
            p..color = col(0xFF8A6A48));
    }
    _flush();
  }

  // ======================= الأرض حسب المنطقة =======================
  void _ground() {
    final gr = Rect.fromLTRB(0, hz, w, h);
    c.drawRect(gr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(land, hor, 0.5), land, _mix(land, Colors.black, 0.25)], stops: const [0, 0.35, 1]).createShader(gr));
    final b = s.biome;
    final period = 3.0, i0 = (s.q / period).floor();
    if (b == _bFarm || b == _bMarsh) {
      // حقول مزروعة: قطع مستطيلة بألوان متناوبة على الجانبين (ثابتة بالعالم)
      for (int k = -1; k < 22; k++) {
        final idx = i0 + k, q0 = idx * period - s.q, q1 = q0 + period;
        if (q1 < qMin || q0 > 60) continue;
        for (final sd in const [-1.0, 1.0]) {
          if (b == _bMarsh && _hash(idx * 3 + (sd > 0 ? 1 : 0)) > 0.45) continue;
          final hs = _hash(idx * 7 + (sd > 0 ? 3 : 0)), x0 = sd * (half + shoulder + 3 + _hash(idx + 5) * 4), x1 = sd * (half + shoulder + 60);
          final colr = [const Color(0xFF5E7A34), const Color(0xFF8A8A40), const Color(0xFF6E5A38), const Color(0xFF4E6E2E)][(hs * 4).floor()];
          strip(math.min(x0, x1), math.max(x0, x1), math.max(q0, qMin), q1 - 0.15, Paint()..color = _mix(shadeL(colr), hor, _cl(q0 / 60) * 0.5).withOpacity(0.85), 4);
        }
      }
    }
    if (b == _bMarsh) {
      // مياه الأهوار على الجانبين تعكس السماء وتتموج
      for (final sd in const [-1.0, 1.0]) {
        final x0 = sd * (half + shoulder + 9), x1 = sd * 400;
        strip(math.min(x0, x1), math.max(x0, x1), qMin, qMax, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_mix(hor, top, 0.2), _mix(_mix(top, const Color(0xFF1E3A40), 0.5), Colors.black, 0.3)]).createShader(Rect.fromLTRB(0, hz, w, h)), 30);
      }
      final rp = Paint()
        ..strokeWidth = 1.2
        ..color = Colors.white.withOpacity(0.15 + 0.15 * light);
      for (int i = 0; i < 70; i++) {
        final sd = i.isEven ? 1.0 : -1.0, q = (_hash(i + 40) * 30 + s.q * 0.0) % 30 + 0.5 - (s.q % 1.0), xm = sd * (half + shoulder + 10 + _hash(i + 41) * 40);
        final ln = (0.8 + _hash(i + 42) * 2) * s0 * f(q);
        final p0 = P(xm, q);
        c.drawLine(p0, p0 + Offset(ln, 0), rp);
      }
    }
    if (b == _bCity) {
      // أرصفة بحافة (كربستون) على الجانبين
      for (final sd in const [-1.0, 1.0]) {
        strip(sd * (half + shoulder), sd * (half + shoulder + 3.2), qMin, qMax, Paint()..color = shadeL(const Color(0xFFA8A49C)), 40);
        ribbon(sd * (half + shoulder), 0, 0.18, qMin, qMax, Paint()..color = shadeL(const Color(0xFFD8D4CA)), 40);
        // بلاط الرصيف: فواصل عرضية تتحرك
        for (int k = 0; k < 40; k++) {
          final q = k * 0.4 - (s.q % 0.4);
          if (q < qMin) continue;
          if (Y(q) - Y(q + 0.4) < 2) break;
          c.drawLine(P(sd * (half + shoulder), q, 0.18), P(sd * (half + shoulder + 3.2), q, 0.18), Paint()
            ..strokeWidth = 1
            ..color = Colors.black.withOpacity(0.15));
        }
      }
    }
    if (b == _bDesert || b == _bFarm) {
      // بقع رمل/تراب ثابتة بالعالم تعطي إحساس الحركة الحقيقي
      for (int k = -1; k < 26; k++) {
        final idx = i0 + k, q = idx * period - s.q + _hash(idx + 70) * period;
        if (q < qMin || q > 50) continue;
        for (int j = 0; j < 2; j++) {
          final sd = j == 0 ? 1.0 : -1.0, xm = sd * (half + shoulder + 2 + _hash(idx * 3 + j) * 30), wm = 2 + _hash(idx * 5 + j) * 6;
          final rc = Rect.fromLTRB(X(xm - wm, q), Y(q + 0.35), X(xm + wm, q), Y(math.max(q - 0.35, qMin)));
          c.drawOval(rc, Paint()..shader = RadialGradient(colors: [(_hash(idx * 11 + j) > 0.5 ? Colors.white : const Color(0xFF3A2A12)).withOpacity(0.1 * (0.4 + light)), Colors.transparent]).createShader(rc));
        }
      }
    }
  }

  // ======================= الطريق =======================
  void _road() {
    var asph = _mix(const Color(0xFF0D0F11), const Color(0xFF4C4F53), light);
    asph = _mix(asph, _mix(const Color(0xFF06080A), const Color(0xFF2A2D31), light), wet);
    if (s.biome != _bCity) strip(-half - shoulder, half + shoulder, qMin, qMax, Paint()..color = _mix(asph, land, 0.3), 48);
    strip(-half - (s.biome == _bCity ? shoulder : 0), half + (s.biome == _bCity ? shoulder : 0), qMin, qMax, Paint()..color = asph, 48);
    // حبيبات الأسفلت: نقاط ثابتة بالعالم مسقطة بالمنظور (تتحرك بالضبط مع السيارة)
    final dark = [<Offset>[], <Offset>[], <Offset>[]], lite = [<Offset>[], <Offset>[], <Offset>[]];
    final seg = (s.q).floor();
    for (int k = -1; k < 16; k++) {
      final idx = seg + k;
      for (int j = 0; j < (q >= 1 ? 26 : 12); j++) {
        final qq = idx + _hash(idx * 131 + j) - s.q;
        if (qq < qMin || qq > 15) continue;
        final xm = -half - 0.8 + _hash(idx * 71 + j * 3) * (2 * half + 1.6), o = P(xm, qq);
        final band = qq < 1.5 ? 0 : (qq < 5 ? 1 : 2);
        (_hash(idx * 17 + j) > 0.4 ? dark : lite)[band].add(o);
      }
    }
    for (int bnd = 0; bnd < 3; bnd++) {
      final sw = [3.2, 2.0, 1.2][bnd];
      c.drawPoints(ui.PointMode.points, dark[bnd], Paint()
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withOpacity(0.28));
      c.drawPoints(ui.PointMode.points, lite[bnd], Paint()
        ..strokeWidth = sw * 0.8
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.06 + 0.1 * light));
    }
    // آثار العجلات بمنتصف كل مسار
    for (final lcn in const [-3.6, 0.0, 3.6]) {
      for (final o in const [-0.8, 0.8]) {
        strip(lcn + o - 0.3, lcn + o + 0.3, qMin, 40, Paint()..color = wet > 0.3 ? hor.withOpacity(0.08 * wet) : Colors.black.withOpacity(0.05 + 0.07 * light), 40);
      }
    }
    // رقع وشقوق وبقع زيت ثابتة بالعالم
    for (int k = -1; k < 12; k++) {
      final idx = (s.q / 4).floor() + k, q = idx * 4 - s.q + _hash(idx + 11) * 2;
      if (q + 1 < qMin || q > 36) continue;
      final hsh = _hash(idx * 3 + 1);
      if (hsh < 0.3) {
        final x0 = -half + 0.3 + _hash(idx) * (2 * half - 3), q0 = math.max(q, qMin);
        strip(x0, x0 + 0.8 + _hash(idx + 4) * 1.6, q0, q0 + 0.3 + _hash(idx + 9) * 0.6, Paint()..color = Colors.black.withOpacity(0.08 + 0.06 * light), 6);
      } else if (hsh > 0.82 && q > qMin) {
        strip(-half, half, q, q + 0.025, Paint()..color = Colors.black.withOpacity(0.25), 2);
      } else if (hsh > 0.6 && q > qMin) {
        final lane = (-3.6 + (_hash(idx + 13) * 3).floor() * 3.6), rc = Rect.fromLTRB(X(lane - 0.35, q), Y(q + 0.25), X(lane + 0.35, q), Y(math.max(q - 0.25, qMin)));
        c.drawOval(rc, Paint()..shader = RadialGradient(colors: [Colors.black.withOpacity(0.18), Colors.transparent]).createShader(rc));
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
      strip(xm - 0.08, xm + 0.08, qMin, qMax, Paint()..color = (s.biome == _bCity && xm < 0 ? const Color(0xFFE8C030) : lineC).withOpacity(0.92), 48);
    }
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
    if (lightsOn > 0.3) {
      for (int k = 0; k < 16; k++) {
        final q = k * per * 0.5 - (s.q % (per * 0.5));
        if (q < qc + 0.3) continue;
        for (final xm in const [-half + 0.2, half - 0.2]) {
          _glow(P(xm, q), math.max(1.5, 0.25 * s0 * f(q)), const Color(0xFFFFC46B).withOpacity(lightsOn * _cl(f(q) * 6)));
        }
      }
      _flush();
    }
  }

  // ======================= الأجسام الجانبية حسب المنطقة (من البعيد للقريب) =======================
  final _wet = <Offset>[];
  void _sides() {
    _wet.clear();
    final b = s.biome;
    // (عمق، نوع، فهرس، جانب، إزاحة عرضية)
    final objs = <(double, int, int, double, double)>[];
    void every(double period, double phase, int type, double Function(int i) xOf, {double prob = 1, int salt = 0, double maxQ = qMax}) {
      final i0 = ((s.q - phase) / period).floor();
      for (int k = -1; k < (maxQ / period).ceil() + 2; k++) {
        final idx = i0 + k, q = idx * period + phase - s.q;
        if (q <= qMin || q >= maxQ) continue;
        if (prob < 1 && _hash(idx * 31 + salt) > prob) continue;
        final xm = xOf(idx);
        objs.add((q, type, idx, xm.sign, xm));
      }
    }

    // أعمدة إنارة: كل المناطق عدا الجبال الوعرة (أقل)، المدينة أكثر
    every(b == _bCity ? 10 : 14, 3, 100, (i) => half + shoulder + (b == _bCity ? 0.5 : 0.9), prob: b == _bMount ? 0.5 : 1, salt: 1);
    every(b == _bCity ? 10 : 14, 3, 100, (i) => -(half + shoulder + (b == _bCity ? 0.5 : 0.9)), prob: b == _bMount ? 0.5 : 1, salt: 2);
    switch (b) {
      case _bCity:
        // عمارات متلاصقة على الجانبين + نخيل رصيف
        every(9, 0, 200, (i) => half + shoulder + 3.2, salt: 3);
        every(9, 4.5, 200, (i) => -(half + shoulder + 3.2), salt: 4);
        every(7, 2, 10, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 1.6), prob: 0.5, salt: 5);
      case _bDesert:
        every(2.2, 0, 3, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 3 + _hash(i) * 40), prob: 0.7, salt: 6);
        every(3.1, 1, 5, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 4 + _hash(i + 3) * 35), prob: 0.5, salt: 7);
        every(48, 10, 300, (i) => -(half + shoulder + 22), salt: 8);
        every(20, 7, 10, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 15 + _hash(i) * 30), prob: 0.35, salt: 9);
      case _bFarm:
        every(3, 0, 10, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 4 + _hash(i) * 9), salt: 10);
        every(4, 1.5, 10, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 16 + _hash(i + 1) * 25), salt: 11);
        every(5, 2, 0, (i) => (i.isEven ? -1 : 1) * (half + shoulder + 3.5 + _hash(i + 2) * 4), prob: 0.5, salt: 12);
        every(22, 9, 6, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 14 + _hash(i) * 12), prob: 0.6, salt: 13);
        every(48, 20, 300, (i) => -(half + shoulder + 30), salt: 14);
      case _bMount:
        every(2.6, 0, 1, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 4 + _hash(i) * 30), prob: 0.8, salt: 15);
        every(3.4, 1, 2, (i) => (i.isEven ? -1 : 1) * (half + shoulder + 5 + _hash(i + 1) * 30), prob: 0.7, salt: 16);
        every(2.0, 0.5, 5, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 2 + _hash(i + 2) * 20), prob: 0.5, salt: 17);
      case _bMarsh:
        every(1.6, 0, 4, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 8 + _hash(i) * 6), prob: 0.8, salt: 18);
        every(5, 2, 10, (i) => (i.isEven ? -1 : 1) * (half + shoulder + 4 + _hash(i) * 3), prob: 0.6, salt: 19);
        every(26, 12, 7, (i) => (i.isEven ? 1 : -1) * (half + shoulder + 20 + _hash(i) * 15), prob: 0.7, salt: 20);
    }
    objs.sort((a, b) => b.$1.compareTo(a.$1));
    for (final o in objs) {
      final q = o.$1, sc = s0 * f(q);
      if (sc * 12 < 1.2) continue;
      switch (o.$2) {
        case 100:
          _lamp(q, o.$5, sc);
        case 200:
          _building(q, o.$3, o.$5);
        case 300:
          _pylon(q, o.$5, o.$3);
        case 10:
          _plant(q, o.$5, o.$3, sc, 10, 8 + _hash(o.$3 + 3) * 4);
        default:
          final hm = switch (o.$2) { 0 => 14.0 + _hash(o.$3) * 6, 1 => 9.0 + _hash(o.$3) * 7, 2 => 7.0 + _hash(o.$3) * 4, 3 => 1.2 + _hash(o.$3) * 0.8, 4 => 2.5, 5 => 0.8 + _hash(o.$3) * 1.2, 6 => 4.0, 7 => 5.0, _ => 3.0 };
          _plant(q, o.$5, o.$3, sc, o.$2, hm);
      }
    }
    _flush();
    _barriers();
  }

  /// نبات/جسم من الصور المسجّلة. type 10 = نخلة
  void _plant(double q, double xm, int idx, double sc, int type, double hm) {
    final bx = X(xm, q), by = Y(q);
    if (bx < -w * 0.6 || bx > w * 1.6) return;
    final sway = math.sin(s.t * 1.2 + idx) * (0.015 + s.wind * 0.005) * (type == 10 || type == 0 || type == 4 ? 1 : 0.3);
    c.save();
    c.translate(bx, by);
    if (_hash(idx + 8) > 0.5 && type != 6 && type != 7) c.scale(-1, 1);
    c.skew(sway, 0);
    if (type == 10) {
      final k = hm * sc / 250;
      c.scale(k);
      c.translate(-128, -318);
      c.drawPicture(_Art.palm(idx.abs() % 3, light0, s.dust));
    } else {
      final unit = type == 3 || type == 5 ? 20.0 : (type == 6 || type == 7 ? 40.0 : 100.0);
      c.scale(hm * sc / unit);
      c.drawPicture(_Flora.get(type, idx.abs() % 3, light0, s.dust));
    }
    c.restore();
  }

  void _lamp(double q, double xm, double sc) {
    const lampC = Color(0xFFFFB45A);
    final side = xm.sign, arm = s.biome == _bCity ? 3.0 : 2.4;
    final bx = X(xm, q), by = Y(q), ty0 = Y(q, 10), ax = X(xm - side * arm, q), ay = Y(q, 9.7);
    final poleC = _mix(const Color(0xFF16181A), const Color(0xFF9097A0), light);
    c.drawLine(Offset(bx, by), Offset(bx, ty0), Paint()
      ..strokeWidth = math.max(1.0, 0.22 * sc)
      ..color = poleC);
    c.drawPath(
        Path()
          ..moveTo(bx, ty0)
          ..quadraticBezierTo(bx, Y(q, 10.6), ax, ay),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 0.14 * sc)
          ..color = poleC);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(ax, ay + 0.1 * sc), width: 0.9 * sc, height: 0.25 * sc), Radius.circular(0.1 * sc)), Paint()..color = _mix(poleC, Colors.black, 0.3));
    if (lightsOn > 0.05) {
      _glow(Offset(ax, ay + 0.25 * sc), math.max(3.0, 2.2 * sc), lampC.withOpacity(0.55 * lightsOn));
      _glow(Offset(ax, ay + 0.25 * sc), math.max(1.5, 0.5 * sc), const Color(0xFFFFEBC4).withOpacity(lightsOn));
      final px = X(xm - side * arm, q), y0 = Y(math.max(q - 1.6, -0.85)), y1 = Y(q + 1.6);
      final pr = Rect.fromCenter(center: Offset(px, by), width: 9 * sc, height: (y0 - y1).abs() + 2);
      c.drawOval(pr, Paint()..shader = RadialGradient(colors: [lampC.withOpacity(0.28 * lightsOn), lampC.withOpacity(0)]).createShader(pr));
      if (wet > 0.1 && q > qc) _wet.add(Offset(px, by));
      final air = _cl(math.max(murk, s.rain * 0.7) * 1.3);
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

  /// برج كهرباء ضغط عالٍ بأسلاك متدلية للبرج التالي
  void _pylon(double q, double xm, int idx) {
    final sc = s0 * f(q);
    final steel = _mix(const Color(0xFF1A1C1E), const Color(0xFF8A9098), light).withOpacity(0.9);
    final p = Paint()
      ..strokeWidth = math.max(0.8, 0.12 * sc)
      ..color = steel;
    Offset o(double dx, double ym) => P(xm + dx, q, ym);
    c.drawLine(o(-2.5, 0), o(-0.6, 30), p);
    c.drawLine(o(2.5, 0), o(0.6, 30), p);
    for (int k = 0; k < 6; k++) {
      final y0 = k * 5.0, y1 = y0 + 5, w0 = 2.5 - y0 / 30 * 1.9, w1 = 2.5 - y1 / 30 * 1.9;
      c.drawLine(o(-w0, y0), o(w1, y1), p);
      c.drawLine(o(w0, y0), o(-w1, y1), p);
    }
    for (final ya in const [22.0, 27.0]) {
      c.drawLine(o(-5, ya), o(5, ya), p);
    }
    // الأسلاك نحو البرج التالي (48 وحدة أبعد)
    final q2 = q + 48;
    if (q2 < qMax) {
      final wp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = steel.withOpacity(0.6);
      for (final e in const [(-5.0, 22.0), (5.0, 22.0), (-5.0, 27.0), (5.0, 27.0)]) {
        final a = P(xm + e.$1, q, e.$2), bpt = P(xm + e.$1, q2, e.$2), m = P(xm + e.$1, q + 24, e.$2 - 3);
        c.drawPath(
            Path()
              ..moveTo(a.dx, a.dy)
              ..quadraticBezierTo(2 * m.dx - (a.dx + bpt.dx) / 2, 2 * m.dy - (a.dy + bpt.dy) / 2, bpt.dx, bpt.dy),
            wp);
      }
    }
  }

  /// عمارة: واجهة جانبية مطلّة على الطريق + واجهة أمامية، شبابيك بطوابق، محلات أرضية، وخزانات ماء على السطح
  void _building(double q0, int idx, double xm) {
    final side = xm.sign, depth = 3.0 + _hash(idx + 1) * 3, floors = 2 + (_hash(idx + 2) * 9).floor(), H = floors * 3.2 + 1;
    final q1 = q0 + depth, xa = xm, xb = xm + side * (8 + _hash(idx + 3) * 10);
    if (Y(q0) - Y(q1) < 1) return;
    final hue = _hash(idx + 4);
    final wall = _mix(const Color(0xFFCDBFA6), _mix(const Color(0xFFB8B0A4), const Color(0xFFD9CDB4), hue), hue);
    final wallSide = shadeL(_mix(wall, Colors.black, 0.12)), wallFront = shadeL(wall);
    // الواجهة الجانبية (تطل على الطريق)
    final sideFace = [P(xa, q0), P(xa, q1), P(xa, q1, H), P(xa, q0, H)];
    c.drawPath(Path()..addPolygon(sideFace, true), Paint()..color = wallSide);
    // الواجهة الأمامية (تواجه الكاميرا)
    final front = Rect.fromLTRB(math.min(X(xa, q0), X(xb, q0)), Y(q0, H), math.max(X(xa, q0), X(xb, q0)), Y(q0));
    if (front.right > -50 && front.left < w + 50) c.drawRect(front, Paint()..color = wallFront);
    final sc = s0 * f(q0);
    if (sc * 3 < 3) return;
    // شبابيك: الواجهة الجانبية بثنائية خطية
    Offset bil(double u, double v) {
      final qq = q0 + (q1 - q0) * u;
      return P(xa, qq, v * H);
    }

    final win = Path(), lit = Path(), night = lightsOn > 0.2;
    final cols = math.max(1, (depth / 2.6).floor());
    for (int fl = 0; fl < floors; fl++) {
      final v0 = (1.2 + fl * 3.2 + 3.2) / H, v1 = (1.2 + fl * 3.2 + 1.3) / H;
      if (fl == 0) continue;
      for (int k = 0; k < cols; k++) {
        final u0 = (k + 0.25) / cols, u1 = (k + 0.75) / cols;
        final quad = [bil(u0, v1), bil(u1, v1), bil(u1, v0), bil(u0, v0)];
        (night && _hash(idx * 97 + fl * 13 + k) > 0.45 ? lit : win).addPolygon(quad, true);
      }
    }
    // شبابيك الواجهة الأمامية
    final fw = (xb - xa).abs(), fcols = math.max(2, (fw / 3).floor());
    for (int fl = 1; fl < floors; fl++) {
      for (int k = 0; k < fcols; k++) {
        final x0 = xa + side * fw * (k + 0.25) / fcols, x1 = xa + side * fw * (k + 0.75) / fcols;
        final r = Rect.fromLTRB(math.min(X(x0, q0), X(x1, q0)), Y(q0, 1.2 + fl * 3.2 + 2.6), math.max(X(x0, q0), X(x1, q0)), Y(q0, 1.2 + fl * 3.2 + 0.7));
        (night && _hash(idx * 61 + fl * 7 + k) > 0.45 ? lit : win).addRect(r);
      }
    }
    c.drawPath(win, Paint()..color = _mix(_mix(const Color(0xFF2A3A48), const Color(0xFF6E8AA0), light), hor, 0.15));
    if (night) c.drawPath(lit, Paint()..color = _mix(const Color(0xFFFFD08A), const Color(0xFFFFF0D0), _hash(idx)).withOpacity(0.55 + 0.4 * lightsOn));
    // محلات أرضية: مظلة ملونة ولوحة تضيء ليلاً
    final aw = [const Color(0xFFB8322A), const Color(0xFF2A6EB8), const Color(0xFF2E8A4A), const Color(0xFFD8A030)][(hue * 4).floor()];
    c.drawPath(Path()..addPolygon([bil(0.05, 3.0 / H), bil(0.95, 3.0 / H), bil(0.95, 2.4 / H), bil(0.05, 2.4 / H)], true), Paint()..color = shadeL(aw));
    final sign = [bil(0.1, 3.9 / H), bil(0.9, 3.9 / H), bil(0.9, 3.1 / H), bil(0.1, 3.1 / H)];
    c.drawPath(Path()..addPolygon(sign, true), Paint()..color = night ? _mix(aw, Colors.white, 0.4) : shadeL(const Color(0xFFEDEAE0)));
    if (night) _glow(bil(0.5, 3.5 / H), sc * 2.2, aw.withOpacity(0.5 * lightsOn));
    c.drawPath(Path()..addPolygon([bil(0.08, 2.3 / H), bil(0.92, 2.3 / H), bil(0.92, 0.1 / H), bil(0.08, 0.1 / H)], true), Paint()..color = night ? const Color(0xFFFFE2A8).withOpacity(0.6 * lightsOn) : shadeL(const Color(0xFF3A4048)));
    // خزانات ماء وصحون على السطح
    for (int k = 0; k < 2; k++) {
      if (_hash(idx * 5 + k) < 0.4) continue;
      final xx = xa + side * fw * (0.2 + 0.5 * k), tw = 1.0 * s0 * f(q0), tp = P(xx, q0 + 0.5, H);
      c.drawRect(Rect.fromLTWH(tp.dx - tw / 2, tp.dy - tw * 1.1, tw, tw * 1.1), Paint()..color = shadeL(k == 0 ? const Color(0xFFE6E6E0) : const Color(0xFF2A5E9A)));
    }
    c.drawLine(P(xa, q0, H), P(xa, q1, H), Paint()
      ..strokeWidth = math.max(1.0, 0.15 * sc)
      ..color = shadeL(_mix(wall, Colors.white, 0.3)));
  }

  void _barriers() {
    if (s.biome == _bCity) return; // المدينة: أرصفة بدل الحواجز
    const gx = half + shoulder + 0.3, bxm = -(half + shoulder + 0.25);
    final steel = shadeL(const Color(0xFFB3B9BF), const Color(0xFF16181A)), conc = shadeL(const Color(0xFFB7B2A6), const Color(0xFF1C1C1A));
    final postP = Paint()..color = _mix(steel, Colors.black, 0.35);
    for (int k = 0; k < 60; k++) {
      final q = k * 0.8 - (s.q % 0.8);
      if (q < qMin) continue;
      if (q > qMax || (Y(q) - Y(q + 0.8)) < 2.5) break;
      postP.strokeWidth = math.max(1.0, 0.1 * s0 * f(q));
      c.drawLine(P(gx, q), P(gx, q, 0.75), postP);
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
      _glow(P(gx, q, 0.64), r0, Colors.white.withOpacity(gl));
      _glow(P(bxm, q, 0.6), r0, const Color(0xFFFFC21A).withOpacity(gl));
    }
    _flush();
  }

  // ======================= الجو: ضباب الأفق، غبار/ضباب، ستائر مطر، انعكاسات =======================
  void _atmos() {
    final hc = _mix(hor, land, 0.25);
    final hb = Rect.fromLTRB(0, hz - hh * 0.07, w, hz + hh * 0.12);
    c.drawRect(hb, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [hc.withOpacity(0), hc.withOpacity(0.9), hc.withOpacity(0)], stops: const [0, 0.38, 1]).createShader(hb));
    if (murk > 0.02) {
      final mc = s.dust > s.fog ? _mix(const Color(0xFF261C10), const Color(0xFFD7A764), light) : _mix(const Color(0xFF15181B), const Color(0xFFC9CDD1), light);
      c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mc.withOpacity(0.35 * murk), mc.withOpacity(0.92 * murk), mc.withOpacity(0.25 * murk)], stops: [0, hz / h, 1]).createShader(Rect.fromLTWH(0, 0, w, h)));
    }
    if (s.rain > 0.2) {
      for (int i = 0; i < 3; i++) {
        final x = ((_hash(i + 600) * w + s.t * (10 + s.wind * 4)) % (w * 1.6)) - w * 0.3, ww = w * (0.3 + _hash(i + 601) * 0.3);
        final rr = Rect.fromLTWH(x, hz - hh * 0.25, ww, hh * 0.5);
        c.drawRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [hor.withOpacity(0), _mix(hor, Colors.grey, 0.4).withOpacity(0.25 * s.rain), hor.withOpacity(0)]).createShader(rr));
      }
    }
    if (_wet.isNotEmpty && _Art.ready) {
      final rp = Paint()
        ..filterQuality = FilterQuality.low
        ..colorFilter = ColorFilter.mode(const Color(0xFFFFB45A).withOpacity(_cl(0.55 * wet * lightsOn)), BlendMode.modulate);
      for (final o in _wet) {
        final len = (h - o.dy) * 0.32, wd = math.max(4.0, len * 0.09);
        c.drawImageRect(_Art.dot, _r64, Rect.fromLTWH(o.dx - wd / 2, o.dy - len * 0.2, wd, len), rp);
      }
    }
  }

  void _beam() {
    final beamOn = math.max(lightsOn, murk * 0.8);
    if (beamOn < 0.05) return;
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

  // ======================= السيارة =======================
  static ui.Picture? _carPic;
  static String _carKey = '';
  void _car() {
    final m = _carModels[s.model] ?? _carModels['sport']!;
    final cw = g.cw;
    final bob = (math.sin(s.t * 11) * 0.5 + math.sin(s.t * 23 + 1) * 0.3) * _cl(s.v / 20) * cw * 0.004;
    final ox = cx + off(qc) * s0 * fc + s.lean * cw * 0.06, oy = g.carY + bob + s.pitch * cw * 0.004;
    final lq = (light0 * 24).round(), key = '${s.model}|${s.color}|${cw.round()}|$lq';
    if (key != _carKey || _carPic == null) {
      final rec = ui.PictureRecorder();
      carBody(Canvas(rec), m, _carColors[s.color] ?? _carColors['green']!, cw, lq / 24);
      _carPic = rec.endRecording();
      _carKey = key;
    }
    final lit = _cl(s.tail * 0.6 + s.brake * 0.9), red = Color.lerp(const Color(0xFF3A060C), const Color(0xFFFF2236), lit)!;
    final rel = ((s.sunAz - s.heading + 540) % 360 - 180) * math.pi / 180;
    final shL = _cl(1 / math.tan(math.max(el, 4) * math.pi / 180), 0, 3) * 0.22, shA = day * (1 - over) * (1 - s.dust * 0.7);
    if (shA > 0.05) {
      final sr = Rect.fromCenter(center: Offset(ox - math.sin(rel) * shL * 0.8 * cw, oy + (0.01 + math.cos(rel) * shL * 0.3) * cw), width: cw * (1.05 + (math.sin(rel) * shL).abs() * 0.9), height: cw * (0.08 + (math.cos(rel) * shL * 0.3).abs() * 0.5));
      c.drawOval(sr, Paint()..shader = RadialGradient(colors: [Colors.black.withOpacity(0.5 * shA), Colors.black.withOpacity(0.35 * shA), Colors.black.withOpacity(0)], stops: const [0, 0.6, 1]).createShader(sr));
    }
    if (wet > 0.2) {
      final rr = Rect.fromLTWH(ox - cw * 0.5, oy, cw, cw * 0.45);
      c.drawRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(_carColors[s.color]![2]).withOpacity(0.25 * wet * (0.3 + 0.7 * light0)), Colors.transparent]).createShader(rr));
    }
    final rl = 0.25 + 0.5 * wet;
    for (final sd in const [-1.0, 1.0]) {
      final rc = Rect.fromLTRB(ox + sd * cw * 0.36 - cw * 0.06, oy, ox + sd * cw * 0.36 + cw * 0.06, oy + cw * (0.2 + wet * 0.9));
      c.drawRect(rc, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [red.withOpacity(rl * lit), red.withOpacity(0)]).createShader(rc));
    }
    c.save();
    c.translate(ox, oy);
    c.rotate(s.lean * 0.035);
    c.drawPicture(_carPic!);
    final lpQ = ((s.q - 3) / 14).round() * 14 - s.q + 3 - qc;
    _carLive(m, cw, lpQ, red, lit);
    c.restore();
    if (s.splash > 0.05 && _Art.ready) {
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
  }

  /// الأجزاء الثابتة للسيارة بتفاصيل كاملة (تُسجَّل مرة وتعاد كل إطار)
  static void carBody(Canvas c, _CarM m, List<int> col, double cw, double light) {
    Offset p(double x, double y) => Offset(x * cw, y * cw);
    Rect r(double x0, double y0, double x1, double y1) => Rect.fromPoints(p(x0, y0), p(x1, y1));
    Color shade(int v) => Color.lerp(Color.lerp(Color(v), Colors.black, 0.78), Color(v), light)!;
    Paint stroke(Color cc, double wd) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, cw * wd)
      ..strokeCap = StrokeCap.round
      ..color = cc;
    Shader lin(double y0, double y1, List<Color> cols, [List<double>? st]) => LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols, stops: st).createShader(r(-0.6, y0, 0.6, y1));
    Shader linX(double x0, double x1, List<Color> cols, [List<double>? st]) => LinearGradient(colors: cols, stops: st).createShader(r(x0, -1, x1, 0));
    final ti0 = m.tire[0], ti1 = m.tire[1], th = m.tire[2], top = -m.height, bot = m.body[0][2], bp = m.bumper;
    // ظلال التلامس
    c.drawOval(r(-0.62, -0.045, 0.62, 0.075), Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.04));
    c.drawRect(r(-ti1, -th * 0.6, ti1, 0.0), Paint()
      ..color = Colors.black.withOpacity(0.92)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.012));
    for (final sd in const [-1.0, 1.0]) {
      c.drawOval(r(sd * (ti0 - 0.025), -0.022, sd * (ti1 + 0.02), 0.026), Paint()
        ..color = Colors.black
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.007));
    }
    // الإطارات: مطاط بجانب مظلل ومداس وحافة لامعة
    for (final sd in const [-1.0, 1.0]) {
      final tr = r(sd * ti0, -th, sd * ti1, 0.004), rr = RRect.fromRectAndRadius(tr, Radius.circular(cw * 0.035));
      c.drawRRect(rr, Paint()..color = const Color(0xFF0B0C0C));
      c.drawRRect(rr, Paint()..shader = linX(sd * ti0, sd * ti1, [Colors.black.withOpacity(0.7), const Color(0xFF34383A).withOpacity(0.35), Colors.black.withOpacity(0.75)]));
      for (int k = 1; k < 7; k++) {
        c.drawLine(p(sd * (ti0 + 0.014), -th + th * k / 7), p(sd * (ti1 - 0.014), -th + th * k / 7), stroke(Colors.black.withOpacity(0.5), 0.003));
      }
      c.drawLine(p(sd * (ti0 + 0.02), -th + 0.01), p(sd * (ti1 - 0.02), -th + 0.01), stroke(const Color(0xFF50585A).withOpacity(0.5), 0.004));
    }
    final body = _cpath(m.body, cw), cab = _cpath(m.cab, cw);
    final paintSh = lin(top, bot, [shade(col[0]), shade(col[1]), shade(col[2]), shade(col[3])], const [0, 0.3, 0.62, 1]);
    c.drawPath(cab, Paint()..shader = paintSh);
    c.drawPath(body, Paint()..shader = paintSh);
    c.save();
    c.clipPath(body);
    c.drawRect(r(-0.52, top, 0.52, 0), Paint()..shader = linX(-0.5, 0.5, const [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0x99000000)], const [0, 0.15, 0.85, 1]));
    c.drawRect(r(-0.52, bp - 0.1, 0.52, bp - 0.02), Paint()..shader = lin(bp - 0.1, bp - 0.02, [Colors.white.withOpacity(0), Colors.white.withOpacity(0.08 + 0.1 * light), Colors.white.withOpacity(0)]));
    c.drawRect(r(-0.52, bp + 0.005, 0.52, bot), Paint()..shader = lin(bp, bot, [Colors.transparent, Colors.black.withOpacity(0.35)]));
    c.restore();
    c.save();
    c.clipPath(cab);
    c.drawRect(r(-0.5, top, 0.5, 0), Paint()..shader = linX(-0.4, 0.4, const [Color(0x80000000), Color(0x00000000), Color(0x00000000), Color(0x80000000)], const [0, 0.2, 0.8, 1]));
    c.restore();
    final b = m.body;
    for (final sd in const [-1.0, 1.0]) {
      c.drawPath(
          Path()
            ..moveTo(sd * b[2][5] * cw, b[2][6] * cw)
            ..cubicTo(sd * b[3][1] * cw, b[3][2] * cw, sd * b[3][3] * cw, b[3][4] * cw, sd * b[3][5] * cw, b[3][6] * cw),
          stroke(Colors.white.withOpacity(0.12 + 0.4 * light), 0.009)..maskFilter = MaskFilter.blur(BlurStyle.normal, cw * 0.004));
      c.drawPath(
          Path()
            ..moveTo(sd * 0.5 * cw, (bp + 0.03) * cw)
            ..quadraticBezierTo(sd * 0.46 * cw, (bp - 0.02) * cw, sd * 0.38 * cw, (bp - 0.025) * cw),
          stroke(Colors.black.withOpacity(0.3), 0.004));
    }
    // الزجاج: تظليل، مساند رأس وظهر مقعد من الداخل، انعكاسات، وإطار
    final gl = _cpath(m.glass, cw), gy = m.glass[0][2];
    c.drawPath(gl, Paint()..shader = lin(top, gy, [Color.lerp(const Color(0xFF0E1A19), const Color(0xFF3B5E5A), light)!, const Color(0xFF050D0C)]));
    c.save();
    c.clipPath(gl);
    for (final sd in const [-1.0, 1.0]) {
      final hx = sd * 0.13, hy = gy - (gy - top) * 0.42;
      c.drawRRect(RRect.fromRectAndRadius(r(hx - 0.055, hy - 0.035, hx + 0.055, hy + 0.03), Radius.circular(cw * 0.03)), Paint()..color = Colors.black.withOpacity(0.55));
    }
    c.drawRect(r(-0.3, gy - (gy - top) * 0.18, 0.3, gy), Paint()..color = Colors.black.withOpacity(0.4));
    c.drawPath(_cpath([[0, -0.12, top], [1, -0.03, top], [1, -0.17, gy], [1, -0.26, gy]], cw), Paint()..color = Colors.white.withOpacity(0.05 + 0.08 * light));
    c.drawPath(_cpath([[0, 0.05, top], [1, 0.09, top], [1, -0.03, gy], [1, -0.07, gy]], cw), Paint()..color = Colors.white.withOpacity(0.03 + 0.05 * light));
    if (m.trunk != null) {
      for (int k = 0; k < 5; k++) {
        final y = gy - (gy - top) * (0.15 + k * 0.13);
        c.drawLine(p(-0.22, y), p(0.22, y), stroke(const Color(0xFF5A2010).withOpacity(0.35), 0.0025));
      }
    }
    c.restore();
    c.drawPath(gl, stroke(Colors.black.withOpacity(0.6), 0.006));
    if (m.rails) c.drawLine(p(0.0, gy - 0.015), p(-0.2, gy - 0.03), stroke(const Color(0xFF050505), 0.006));
    final rf = m.roof;
    c.drawPath(_cpath([[0, rf[0], rf[1]], [3, rf[0] * 0.55, rf[1] - 0.02, rf[2] * 0.55, rf[1] - 0.02, rf[2], rf[1]], [3, rf[2] * 0.55, rf[1] - 0.01, rf[0] * 0.55, rf[1] - 0.01, rf[0], rf[1]]], cw), Paint()..color = Colors.white.withOpacity(0.05 + 0.12 * light));
    c.drawPath(_cpath([[0, -0.025, rf[1] - 0.004], [2, 0.0, rf[1] - 0.05, 0.025, rf[1] - 0.004]], cw), Paint()..color = shade(col[3]));
    if (m.rails) {
      for (final sd in const [-1.0, 1.0]) {
        c.drawRRect(RRect.fromRectAndRadius(r(sd * 0.3, rf[1] - 0.03, sd * 0.34, rf[1] + 0.005), Radius.circular(cw * 0.006)), Paint()..color = const Color(0xFF1A1C1E));
      }
    }
    if (m.spoiler != null) {
      final sp = m.spoiler!;
      c.drawRRect(RRect.fromRectAndRadius(r(sp[0], sp[1] - 0.012, sp[2], sp[3]), Radius.circular(cw * 0.008)), Paint()..color = shade(col[2]));
    }
    if (m.grille != null) {
      // جناح خلفي رياضي فوق غطاء المحرك
      c.drawPath(_cpath([[0, -0.33, -0.432], [2, 0, -0.452, 0.33, -0.432], [1, 0.33, -0.425], [2, 0, -0.442, -0.33, -0.425]], cw), Paint()..color = shade(col[3]));
      final gr = m.grille!;
      for (int k = 0; k < gr[3].round(); k++) {
        c.drawLine(p(gr[0], gr[1] - k * 0.011), p(gr[2], gr[1] - k * 0.011), stroke(Colors.black.withOpacity(0.5), 0.004));
      }
    }
    if (m.trunk != null) c.drawLine(p(-0.42, m.trunk!), p(0.42, m.trunk!), stroke(Colors.black.withOpacity(0.35), 0.004));
    final mr = m.mirror;
    for (final sd in const [-1.0, 1.0]) {
      c.drawLine(p(sd * (mr[0] - 0.035), (mr[1] + mr[3]) / 2 + 0.008), p(sd * mr[0], (mr[1] + mr[3]) / 2), stroke(shade(col[2]), 0.012));
      c.drawRRect(RRect.fromRectAndRadius(r(sd * mr[0], mr[1], sd * mr[2], mr[3]), Radius.circular(cw * 0.018)), Paint()..color = shade(col[1]));
      c.drawRRect(RRect.fromRectAndRadius(r(sd * mr[0], mr[3] - 0.01, sd * mr[2], mr[3]), Radius.circular(cw * 0.006)), Paint()..color = const Color(0xFFFFA51F).withOpacity(0.5));
    }
    // أغطية الأضواء المطفأة بشرائح داخلية
    if (m.bar != null) c.drawPath(_cpath(m.bar!, cw), Paint()..color = const Color(0xFF1A0306));
    for (final sd in const [-1.0, 1.0]) {
      final lp = _cpath(m.lamp, cw, sx: sd), bd = lp.getBounds();
      c.drawPath(lp, Paint()..color = const Color(0xFF240407));
      c.save();
      c.clipPath(lp);
      for (int k = 1; k < 5; k++) {
        final x = bd.left + bd.width * k / 5;
        c.drawLine(Offset(x, bd.top), Offset(x, bd.bottom), Paint()
          ..strokeWidth = math.max(1.0, cw * 0.003)
          ..color = Colors.black.withOpacity(0.35));
      }
      c.drawRect(Rect.fromLTRB(bd.left + bd.width * (sd < 0 ? 0.15 : 0.55), bd.bottom - bd.height * 0.3, bd.left + bd.width * (sd < 0 ? 0.45 : 0.85), bd.bottom), Paint()..color = const Color(0xFFD8D8D8).withOpacity(0.35 + 0.2 * light));
      c.restore();
      c.drawPath(lp, stroke(Colors.black.withOpacity(0.5), 0.003));
    }
    final t3 = m.third;
    c.drawRRect(RRect.fromRectAndRadius(r(t3[0], t3[1], t3[2], t3[3]), Radius.circular(cw * 0.004)), Paint()..color = const Color(0xFF2A0508));
    // المصد: فاصل، حساسات، لوحة بإطار
    c.drawLine(p(-0.47, bp), p(0.47, bp), stroke(Colors.black.withOpacity(0.45), 0.004));
    c.drawLine(p(-0.47, bp + 0.003), p(0.47, bp + 0.003), stroke(Colors.white.withOpacity(0.02 + 0.08 * light), 0.003));
    for (final x in const [-0.3, -0.12, 0.12, 0.3]) {
      c.drawCircle(p(x, bp + 0.04), cw * 0.008, Paint()..color = shade(col[2]));
      c.drawCircle(p(x, bp + 0.04), cw * 0.008, stroke(Colors.black.withOpacity(0.4), 0.002));
    }
    final pl = r(m.plate[0], m.plate[1], m.plate[2], m.plate[3]);
    c.drawRRect(RRect.fromRectAndRadius(pl.inflate(cw * 0.008), Radius.circular(cw * 0.012)), Paint()..color = const Color(0xCC0A0A0A));
    c.drawRRect(RRect.fromRectAndRadius(pl, Radius.circular(cw * 0.008)), Paint()..color = Color.lerp(const Color(0xFF3A3A36), const Color(0xFFEEEBE2), light)!);
    c.drawRect(Rect.fromLTRB(pl.right - pl.width * 0.2, pl.top, pl.right, pl.bottom), Paint()..color = const Color(0xFF1E4FA8).withOpacity(0.85));
    if (_plate == null || (_plateW - cw).abs() > 1) {
      _plateW = cw;
      _plate = TextPainter(text: TextSpan(text: 'منبر', style: TextStyle(fontFamily: 'Cairo', fontSize: cw * 0.034, fontWeight: FontWeight.w700, color: kGreen, height: 1)), textDirection: TextDirection.rtl)..layout();
    }
    _plate!.paint(c, Offset(pl.left + pl.width * 0.4, pl.center.dy) - Offset(_plate!.width / 2, _plate!.height / 2));
    // الناشر بزعانف + عادم بحلقات كروم
    final df = m.diff, dr = RRect.fromRectAndRadius(r(df[0], df[1], df[2], df[3]), Radius.circular(cw * 0.02));
    c.drawRRect(dr, Paint()..color = const Color(0xFF050B0A));
    c.drawRRect(dr, Paint()..shader = lin(df[1], df[3], [const Color(0xFF2A3230).withOpacity(0.6), Colors.transparent]));
    for (double x = df[0] + 0.08; x < df[2] - 0.05; x += 0.08) {
      c.drawLine(p(x, df[1] + 0.005), p(x, df[3]), stroke(const Color(0xFF3A4442).withOpacity(0.8), 0.006));
    }
    for (final e in m.exh) {
      for (final sd in const [-1.0, 1.0]) {
        final ex = r(sd * e[0], e[1], sd * e[2], e[3]);
        c.drawRRect(RRect.fromRectAndRadius(ex, Radius.circular(cw * 0.02)), Paint()..shader = lin(e[1], e[3], [Color.lerp(const Color(0xFF4A5452), const Color(0xFFE5ECE9), light)!, const Color(0xFF2C3433)]));
        c.drawRRect(RRect.fromRectAndRadius(ex.deflate(cw * 0.006), Radius.circular(cw * 0.014)), Paint()..shader = lin(e[1], e[3], [Colors.black, const Color(0xFF1A1E1E)]));
      }
    }
    c.drawPath(body, stroke(Colors.white.withOpacity(0.05 + 0.06 * light), 0.0015));
  }

  /// الأجزاء الحيّة: الأضواء، لمعة الإنارة المارة، قطرات المطر، الثلج
  void _carLive(_CarM m, double cw, double pass, Color red, double lit) {
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
        c.drawPoints(ui.PointMode.points, [for (int i = 0; i < 40; i++) p(-0.48 + _hash(i + 120) * 0.96, -m.height + _hash(i + 121) * (m.height - 0.1))], Paint()
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
      final tp = m.body[4][2];
      c.drawPath(_cpath([[0, -0.37, tp + 0.002], [3, -0.2, tp - 0.02, 0.2, tp - 0.02, 0.37, tp + 0.002], [3, 0.2, tp - 0.006, -0.2, tp - 0.006, -0.37, tp + 0.002]], cw), sn);
    }
    for (final sd in const [-1.0, 1.0]) {
      final here = blinkOn && s.blink == sd, cc = here ? const Color(0xFFFFA51F) : red, lp = _cpath(m.lamp, cw, sx: sd), bnd = lp.getBounds();
      c.drawPath(lp, Paint()..color = cc);
      c.save();
      c.clipPath(lp);
      for (int k = 1; k < 5; k++) {
        final x = bnd.left + bnd.width * k / 5;
        c.drawLine(Offset(x, bnd.top), Offset(x, bnd.bottom), Paint()
          ..strokeWidth = math.max(1.0, cw * 0.003)
          ..color = Colors.black.withOpacity(0.22));
      }
      c.drawRect(Rect.fromLTRB(bnd.left, bnd.top, bnd.right, bnd.top + bnd.height * 0.35), Paint()..color = Colors.white.withOpacity(0.12 + 0.15 * lit));
      c.restore();
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
    _flush();
  }

  // ======================= المطر والثلج والغبار والبرق =======================
  void _weather() {
    if (s.rain > 0.02 && _Art.ready) {
      final n = ((80 + 380 * s.rain) * (q == 2 ? 1 : 0.5)).round(), rc0 = _mix(const Color(0xFF8C96A0), const Color(0xFFE6ECF2), light);
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
      c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _mix(const Color(0xFF0A0E12), const Color(0xFF8E99A4), light).withOpacity(0.08 * s.rain));
    }
    if (s.snow > 0.02 && _Art.ready) {
      final n = ((60 + 260 * s.snow) * (q == 2 ? 1 : 0.5)).round();
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
    if (s.flash > 0.01) c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withOpacity(0.3 * s.flash));
  }

  @override
  bool shouldRepaint(covariant _World o) => o.g.hz != g.hz || o.g.cx != g.cx || o.g.carY != g.carY || o.g.cw != g.cw || o.g.dpr != g.dpr;
}

/// معاينة السيارة بنافذة الإعدادات
class _CarPreview extends CustomPainter {
  final String model, color;
  _CarPreview(this.model, this.color);
  @override
  void paint(Canvas c, Size z) {
    final cw = math.min(z.width * 0.62, z.height * 1.05);
    final floor = Rect.fromLTWH(0, z.height * 0.72, z.width, z.height * 0.28);
    c.drawRect(floor, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF1A2A25), const Color(0xFF0B1F19)]).createShader(floor));
    c.drawOval(Rect.fromCenter(center: Offset(z.width / 2, z.height * 0.86), width: z.width * 0.9, height: z.height * 0.3), Paint()..shader = RadialGradient(colors: [const Color(0x40E8C468), const Color(0x00E8C468)]).createShader(Rect.fromCenter(center: Offset(z.width / 2, z.height * 0.86), width: z.width * 0.9, height: z.height * 0.3)));
    c.save();
    c.translate(z.width / 2, z.height * 0.86);
    final m = _carModels[model] ?? _carModels['sport']!;
    _World.carBody(c, m, _carColors[color] ?? _carColors['green']!, cw, 1);
    for (final sd in const [-1.0, 1.0]) {
      c.drawPath(_cpath(m.lamp, cw, sx: sd), Paint()..color = const Color(0xFFE0202E));
    }
    c.drawPath(
        _cpath(m.led, cw, close: false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cw * 0.007
          ..color = const Color(0xFFFF6070));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _CarPreview o) => o.model != model || o.color != color;
}
