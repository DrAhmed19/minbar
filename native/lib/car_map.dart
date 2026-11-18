part of 'car.dart';

// ======================= خريطة مصغرة مخصصة (تُرسم من بيانات العراق المحلية، بدون إنترنت) =======================

/// دائرة خريطة: حدود المحافظات وبلداتها حول موقعك، تدور مع اتجاه السير، وسهم ذهبي بالمركز
class _MapPainter extends CustomPainter {
  final _CarPageState st;
  _MapPainter(this.st, Listenable repaint) : super(repaint: repaint);
  static final _tp = <String, TextPainter>{};
  static TextPainter _label(String t) => _tp[t] ??= TextPainter(
        text: TextSpan(text: t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 9.5, color: Color(0xFFE6EEE9), fontWeight: FontWeight.w700, shadows: [Shadow(color: Color(0xFF000000), blurRadius: 3)])),
        textDirection: TextDirection.rtl,
      )..layout();

  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    // موقع محسوب بين تحديثين (حركة ناعمة)
    final hd = st._mapHead * math.pi / 180, age = _cl(st._now - st._fixAt, 0, 1.5), dist = st._sc.v * age;
    final lat = st._lat + dist * math.cos(hd) / 111200, lon = st._lon + dist * math.sin(hd) / (111200 * math.cos(st._lat * math.pi / 180));
    const viewKm = 36.0;
    final k = r / viewKm, cosL = math.cos(lat * math.pi / 180);
    Offset pt(double la, double lo) => Offset((lo - lon) * cosL * 111.2 * k, -(la - lat) * 111.2 * k);
    c.drawCircle(Offset(r, r), r, Paint()..color = const Color(0xFF0B1914));
    final cur = st._region?.govKey;
    c.save();
    c.translate(r, r);
    c.rotate(-hd);
    final fill = Paint()..style = PaintingStyle.fill, line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.3..color = const Color(0x995FAE8A);
    for (final key in _govPoly.keys) {
      for (final ring in _ringsOf(key)) {
        final p = Path();
        for (int i = 0; i < ring.length; i += 2) {
          final o = pt(ring[i], ring[i + 1]);
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        p.close();
        c.drawPath(p, fill..color = key == cur ? const Color(0xFF1F4A38) : const Color(0xFF14291F));
        c.drawPath(p, line);
      }
    }
    final near = <(double, Offset, String)>[];
    final dot = Paint()..color = const Color(0xFFE8C468);
    for (final t in _towns) {
      final o = pt(t.$2, t.$3), d = o.distance;
      if (d > r * 1.25) continue;
      c.drawCircle(o, t.$4 > 6 ? 3.2 : 2.2, dot);
      if (d < r * 0.82) near.add((d, o, t.$1));
    }
    c.restore();
    // أسماء أقرب 3 بلدات (تبقى أفقية)
    near.sort((a, b) => a.$1.compareTo(b.$1));
    final ca = math.cos(-hd), sa = math.sin(-hd);
    for (final n in near.take(3)) {
      final o = Offset(r + n.$2.dx * ca - n.$2.dy * sa, r + n.$2.dx * sa + n.$2.dy * ca);
      final tp = _label(n.$3);
      tp.paint(c, o + Offset(-tp.width / 2, 4));
    }
    // سهم السيارة
    final a = Path()
      ..moveTo(r, r - 9)
      ..lineTo(r + 6.5, r + 7)
      ..lineTo(r, r + 3)
      ..lineTo(r - 6.5, r + 7)
      ..close();
    c.drawPath(a, Paint()..color = const Color(0xFFE8C468));
    c.drawPath(a, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0xFF0B1914));
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) => true;
}

/// معلومات الشريط: البلدة الحالية/الأخيرة، البلدة القادمة بالاتجاه، المتبقي
class _NavInfo {
  final String from, to;
  final double km, frac;
  const _NavInfo(this.from, this.to, this.km, this.frac);
}

int _lastTownIdx = -1;

_NavInfo? _navCompute(double lat, double lon, double heading, bool moving) {
  int ni = -1;
  double nd = 1e9;
  for (int i = 0; i < _towns.length; i++) {
    final d = _kmBetween(lat, lon, _towns[i].$2, _towns[i].$3);
    if (d < nd) {
      nd = d;
      ni = i;
    }
  }
  if (ni < 0) return null;
  if (_lastTownIdx < 0 || nd <= _towns[ni].$4 * 1.5) _lastTownIdx = ni;
  if (!moving) return null;
  final from = _towns[_lastTownIdx];
  int bi = -1;
  double bd = 1e9;
  for (int i = 0; i < _towns.length; i++) {
    if (i == _lastTownIdx) continue;
    final t = _towns[i], d = _kmBetween(lat, lon, t.$2, t.$3);
    if (d < 2 || d > 150 || d >= bd) continue;
    final b = (math.atan2((t.$3 - lon) * math.cos(lat * math.pi / 180), t.$2 - lat) * 180 / math.pi + 360) % 360;
    final dh = ((b - heading + 540) % 360) - 180;
    if (dh.abs() < 55) {
      bd = d;
      bi = i;
    }
  }
  if (bi < 0) return null;
  final to = _towns[bi], total = _kmBetween(from.$2, from.$3, to.$2, to.$3);
  return _NavInfo(from.$1, to.$1, bd, total <= 0 ? 0 : _cl(1 - bd / total));
}
