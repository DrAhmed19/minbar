import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// صفحة الإحصائيات للأدمن: Google Analytics عبر /api/stats (نشطون الآن، مقارنات، رسم بياني، منصّات، أجهزة، دول، أوقات، قصائد)
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

const _kGold = Color(0xFFC9A84C), _kBlue = Color(0xFF3B82C4), _kPurple = Color(0xFFA35CC4);
const _kPl = {'Android': 'أندرويد', 'web': 'الموقع', 'iOS': 'آيفون'};
const _kEv = {'session_start': 'بدء جلسة', 'first_open': 'أول فتح للتطبيق', 'first_visit': 'أول زيارة', 'screen_view': 'عرض شاشة', 'page_view': 'عرض صفحة', 'user_engagement': 'تفاعل المستخدم', 'app_open': 'فتح التطبيق', 'scroll': 'تمرير', 'click': 'نقرة'};
const _kMet = {'u': ['المستخدمون', Color(0xFF1B7F5C)], 'n': ['جدد', _kGold], 's': ['الجلسات', _kBlue], 'v': ['المشاهدات', _kPurple]};

class _StatsPageState extends State<StatsPage> {
  Map<String, dynamic>? _d;
  String _err = '', _per = 'w', _met = 'u';
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool fresh = false}) async {
    setState(() {
      _busy = true;
      _err = '';
    });
    try {
      final tk = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (tk == null) throw 'سجّل الدخول';
      final c = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      final rq = await c.getUrl(Uri.parse('${kBase}api/stats${fresh ? '?fresh=1' : ''}'));
      rq.headers.set('authorization', 'Bearer $tk');
      final rs = await rq.close().timeout(const Duration(seconds: 40));
      final body = await rs.transform(utf8.decoder).join();
      c.close();
      final j = jsonDecode(body) as Map<String, dynamic>;
      if (rs.statusCode != 200) throw '${j['error'] ?? 'تعذّر التحميل'}';
      _d = j;
    } catch (e) {
      _err = '$e';
    }
    if (mounted) setState(() => _busy = false);
  }

  static String _f(num n) {
    final s = n.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String _dur(num s) => '${s ~/ 60}:${(s.round() % 60).toString().padLeft(2, '0')}';
  num _n(dynamic v) => (v as num?) ?? 0;

  Widget _card(Widget c, {EdgeInsets? pad}) => Container(
        width: double.infinity,
        padding: pad ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: c,
      );

  Widget _sec(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 20, 4, 8), child: Text(t, style: tx(14.5, w: FontWeight.w800, c: kGreen)));

  Widget _tabs(List<List<String>> items, String cur, void Function(String) on, {double fs = 13}) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.black.withOpacity(.06), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final e in items)
            Expanded(
              child: GestureDetector(
                onTap: () => on(e[0]),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(color: cur == e[0] ? kGreen : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: Text(e[1], style: tx(fs, w: cur == e[0] ? FontWeight.w800 : FontWeight.w500, c: cur == e[0] ? Colors.white : kGreen)),
                ),
              ),
            ),
        ]),
      );

  Widget _delta(num a, num b) {
    if (b == 0) return a > 0 ? Text('جديد', style: tx(11, w: FontWeight.w800, c: const Color(0xFF1B8F4D))) : const SizedBox(height: 14);
    final p = ((a - b) / b * 100).round();
    return Text('${p >= 0 ? '▲' : '▼'} ${p.abs()}%', style: tx(11, w: FontWeight.w800, c: p >= 0 ? const Color(0xFF1B8F4D) : const Color(0xFFC0392B)));
  }

  Widget _kpi(String l, String v, Widget sub) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: tx(11.5, c: kMuted)), Text(v, style: tx(26, w: FontWeight.w800, c: kGreen)), sub]),
      );

  List<Map<String, num>> _days(int n) {
    final m = <String, Map<String, dynamic>>{for (final e in (_d!['series'] as List)) '${e['d']}': Map<String, dynamic>.from(e as Map)};
    final out = <Map<String, num>>[];
    final now = DateTime.now();
    for (var i = n - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      final e = m[k];
      out.add({'d': int.parse(k), 'u': _n(e?['u']), 'n': _n(e?['n']), 's': _n(e?['s']), 'v': _n(e?['v'])});
    }
    return out;
  }

  Widget _list(List? a, {String Function(String)? fmt, Color col = kGreen}) {
    final l = [for (final e in (a ?? [])) if (_n(e[1]) > 0) e];
    if (l.isEmpty) return Text('لا بيانات بعد', style: tx(12, c: kMuted));
    final mx = l.map((e) => _n(e[1])).reduce(math.max), tot = l.fold<num>(0, (s, e) => s + _n(e[1]));
    return Column(children: [
      for (final e in l)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(fmt != null ? fmt('${e[0]}') : '${e[0]}', style: tx(13), overflow: TextOverflow.ellipsis)),
              Text('${_f(_n(e[1]))}  ', style: tx(13, w: FontWeight.w800, c: kGreen)),
              Text('${(_n(e[1]) / tot * 100).round()}%', style: tx(11, c: kMuted)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (_n(e[1]) / mx).toDouble().clamp(.03, 1), minHeight: 6, backgroundColor: Colors.black12, valueColor: AlwaysStoppedAnimation(col))),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(
          backgroundColor: kCream,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: kGreen,
          title: Text('الإحصائيات', style: tx(18, w: FontWeight.w800, c: kGreen)),
          actions: [IconButton(onPressed: _busy ? null : () => _load(fresh: true), icon: const Icon(Icons.refresh_rounded))],
        ),
        body: d == null
            ? Center(child: _busy ? const CircularProgressIndicator(color: kGreen) : Padding(padding: const EdgeInsets.all(24), child: Text(_err, textAlign: TextAlign.center, style: tx(14, c: kMuted))))
            : RefreshIndicator(color: kGreen, onRefresh: () => _load(fresh: true), child: ListView(padding: const EdgeInsets.fromLTRB(14, 4, 14, 30), children: _body(d))),
      ),
    );
  }

  List<Widget> _body(Map<String, dynamic> d) {
    final nw = d['now'] as Map, kp = d['kpi'] as Map;
    const pm = {'t': 'y', 'w': 'pw', 'm': 'pm'};
    final k = (kp[_per] as Map?) ?? {}, p = (kp[pm[_per]] as Map?) ?? {};
    final ser = _days(_per == 'm' ? 30 : 7);
    final nvr = d['nvr'] as Map, nT = math.max(1, _n(nvr['n']) + _n(nvr['r']));
    final tops = (d['top'] as List?) ?? [];
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0C4A39), Color(0xFF136B52)]), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF4CFF9A), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF4CFF9A), blurRadius: 10)])),
            const SizedBox(width: 10),
            Text(_f(_n(nw['total'])), style: tx(42, w: FontWeight.w800, c: Colors.white)),
            const SizedBox(width: 10),
            Text('نشط الآن (آخر 30 دقيقة)', style: tx(12.5, c: Colors.white70)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final e in (nw['platforms'] as List)) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text('${_kPl[e[0]] ?? e[0]}  ${_f(_n(e[1]))}', style: tx(12, c: Colors.white))),
            if ((nw['platforms'] as List).isEmpty) Text('لا أحد الآن', style: tx(12, c: Colors.white70)),
          ]),
          if ((nw['cities'] as List).any((e) => _n(e[1]) > 0)) Padding(padding: const EdgeInsets.only(top: 8), child: Text([for (final e in (nw['cities'] as List)) if (_n(e[1]) > 0) '${e[0]} · ${_f(_n(e[1]))}'].join('   |   '), style: tx(11.5, c: Colors.white70))),
        ]),
      ),
      const SizedBox(height: 12),
      _tabs([['t', 'اليوم'], ['w', '7 أيام'], ['m', '30 يوم']], _per, (v) => setState(() => _per = v)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
        children: [
          _kpi('المستخدمون', _f(_n(k['u'])), _delta(_n(k['u']), _n(p['u']))),
          _kpi('مستخدمون جدد', _f(_n(k['n'])), _delta(_n(k['n']), _n(p['n']))),
          _kpi('الجلسات (مرات الفتح)', _f(_n(k['s'])), _delta(_n(k['s']), _n(p['s']))),
          _kpi('مشاهدات الشاشات', _f(_n(k['v'])), _delta(_n(k['v']), _n(p['v']))),
          _kpi('متوسط وقت المستخدم', _dur(_n(k['u']) > 0 ? _n(k['e']) / _n(k['u']) : 0), Text('دقيقة:ثانية', style: tx(10.5, c: kMuted))),
          _kpi('جلسات لكل مستخدم', _n(k['u']) > 0 ? (_n(k['s']) / _n(k['u'])).toStringAsFixed(1) : '0', Text('أعلى = ولاء أكثر', style: tx(10.5, c: kMuted))),
        ],
      ),
      Padding(padding: const EdgeInsets.only(top: 6), child: Text('المقارنة بالفترة السابقة المماثلة', textAlign: TextAlign.center, style: tx(10.5, c: kMuted))),
      const SizedBox(height: 12),
      _card(Column(children: [
        _tabs([for (final e in _kMet.entries) [e.key, e.value[0] as String]], _met, (v) => setState(() => _met = v), fs: 11.5),
        const SizedBox(height: 14),
        SizedBox(height: 160, width: double.infinity, child: CustomPaint(painter: _LineP(ser, _met, _kMet[_met]![1] as Color))),
      ])),
      _sec('المنصّات'),
      _card(Row(children: [
        SizedBox(width: 100, height: 100, child: CustomPaint(painter: _DonutP([for (final e in (d['platform'] as List)) _n(e[1])]), child: Center(child: Text(_f((d['platform'] as List).fold<num>(0, (s, e) => s + _n(e[1]))), style: tx(16, w: FontWeight.w800, c: kGreen))))),
        const SizedBox(width: 16),
        Expanded(
          child: Column(children: [
            for (var i = 0; i < (d['platform'] as List).length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _DonutP.cols[i % 4], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${_kPl[(d['platform'] as List)[i][0]] ?? (d['platform'] as List)[i][0]}', style: tx(13))),
                  Text(_f(_n((d['platform'] as List)[i][1])), style: tx(13, w: FontWeight.w800, c: kGreen)),
                ]),
              ),
          ]),
        ),
      ])),
      _sec('جدد مقابل عائدين (30 يوم)'),
      _card(Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Row(textDirection: TextDirection.ltr, children: [Expanded(flex: math.max(1, (_n(nvr['n']) / nT * 1000).round()), child: Container(height: 14, color: kGreen)), Expanded(flex: math.max(1, (_n(nvr['r']) / nT * 1000).round()), child: Container(height: 14, color: _kGold))])),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('جدد ${_f(_n(nvr['n']))} (${(_n(nvr['n']) / nT * 100).round()}%)', style: tx(12)), Text('عائدون ${_f(_n(nvr['r']))} (${(_n(nvr['r']) / nT * 100).round()}%)', style: tx(12))]),
      ])),
      _sec('أوقات النشاط خلال اليوم (بتوقيت بغداد)'),
      _card(SizedBox(height: 100, width: double.infinity, child: CustomPaint(painter: _HoursP([for (final v in (d['hour'] as List)) _n(v)])))),
      _sec('أكثر القصائد استماعاً'),
      _card(
        tops.isEmpty
            ? Text('لا بيانات', style: tx(12, c: kMuted))
            : Column(children: [
                for (var i = 0; i < tops.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(width: 24, height: 24, alignment: Alignment.center, decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle), child: Text('${i + 1}', style: tx(11, c: Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${tops[i]['title']}', style: tx(13, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis), Text('${tops[i]['reciter']}', style: tx(11, c: kMuted), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                      Text(_f(_n(tops[i]['plays'])), style: tx(14, w: FontWeight.w800, c: kGreen)),
                    ]),
                  ),
              ]),
      ),
      _sec('الدول'),
      _card(_list(d['country'] as List?)),
      _sec('المدن'),
      _card(_list(d['city'] as List?, col: _kGold)),
      _sec('الشاشات الأكثر زيارة'),
      _card(_list(d['screens'] as List?, col: _kBlue)),
      _sec('الأجهزة'),
      _card(_list(d['device'] as List?, fmt: (x) => {'mobile': 'جوال', 'desktop': 'كمبيوتر', 'tablet': 'تابلت'}[x] ?? x)),
      _sec('موديلات الجوال'),
      _card(_list(d['model'] as List?, col: _kPurple)),
      _sec('نظام التشغيل'),
      _card(_list(d['os'] as List?, col: _kBlue)),
      _sec('إصدارات التطبيق'),
      _card(_list(d['appv'] as List?, col: _kGold)),
      _sec('اللغات'),
      _card(_list(d['lang'] as List?)),
      _sec('أكثر الأحداث'),
      _card(_list(d['events'] as List?, fmt: (x) => _kEv[x] ?? x, col: _kPurple)),
      Padding(padding: const EdgeInsets.only(top: 16), child: Text('الأرقام تتأخر قليلاً وتُحفظ دقيقتين · اسحب للتحديث', textAlign: TextAlign.center, style: tx(11, c: kMuted))),
    ];
  }
}

class _LineP extends CustomPainter {
  final List<Map<String, num>> s;
  final String k;
  final Color col;
  _LineP(this.s, this.k, this.col);
  @override
  void paint(Canvas c, Size z) {
    const pl = 30.0, pb = 20.0, pt = 8.0;
    final n = s.length;
    final mx = math.max(3, s.map((e) => e[k]!).reduce(math.max)).toDouble();
    double x(int i) => pl + i * (z.width - pl - 6) / math.max(1, n - 1);
    double y(num v) => pt + (z.height - pt - pb) * (1 - v / mx);
    final grid = Paint()..color = Colors.black12;
    for (final r in [0.0, .5, 1.0]) {
      c.drawLine(Offset(pl, y(mx * r)), Offset(z.width - 6, y(mx * r)), grid);
      final tp = TextPainter(text: TextSpan(text: _StatsPageState._f(mx * r), style: const TextStyle(fontSize: 9, color: Colors.black45)), textDirection: TextDirection.ltr)..layout();
      tp.paint(c, Offset(pl - 4 - tp.width, y(mx * r) - tp.height / 2));
    }
    final path = Path()..moveTo(x(0), y(s[0][k]!));
    for (var i = 1; i < n; i++) {
      final cx = (x(i - 1) + x(i)) / 2;
      path.cubicTo(cx, y(s[i - 1][k]!), cx, y(s[i][k]!), x(i), y(s[i][k]!));
    }
    final area = Path.from(path)..lineTo(x(n - 1), z.height - pb)..lineTo(x(0), z.height - pb)..close();
    c.drawPath(area, Paint()..color = col.withOpacity(.14));
    c.drawPath(path, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round);
    for (var i = 0; i < n; i++) {
      final o = Offset(x(i), y(s[i][k]!));
      c.drawCircle(o, n <= 7 ? 4.2 : 2.4, Paint()..color = Colors.white);
      c.drawCircle(o, n <= 7 ? 4.2 : 2.4, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 2);
      if (n <= 7 || i % 5 == 0 || i == n - 1) {
        final d = s[i]['d']!.toInt().toString();
        final tp = TextPainter(text: TextSpan(text: '${d.substring(6)}/${d.substring(4, 6)}', style: const TextStyle(fontSize: 9, color: Colors.black45)), textDirection: TextDirection.ltr)..layout();
        tp.paint(c, Offset(x(i) - tp.width / 2, z.height - pb + 5));
      }
    }
  }

  @override
  bool shouldRepaint(_LineP o) => true;
}

class _DonutP extends CustomPainter {
  static const cols = [Color(0xFF1B7F5C), _kGold, _kBlue, _kPurple];
  final List<num> v;
  _DonutP(this.v);
  @override
  void paint(Canvas c, Size z) {
    final tot = v.fold<num>(0, (a, b) => a + b);
    final r = Rect.fromCircle(center: z.center(Offset.zero), radius: z.width / 2 - 8);
    final bg = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..color = Colors.black12;
    if (tot == 0) {
      c.drawArc(r, 0, math.pi * 2, false, bg);
      return;
    }
    var a = -math.pi / 2;
    for (var i = 0; i < v.length; i++) {
      final sw = v[i] / tot * math.pi * 2;
      c.drawArc(r, a, sw, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 14..color = cols[i % 4]);
      a += sw;
    }
  }

  @override
  bool shouldRepaint(_DonutP o) => true;
}

class _HoursP extends CustomPainter {
  final List<num> h;
  _HoursP(this.h);
  @override
  void paint(Canvas c, Size z) {
    final mx = math.max(1, h.reduce(math.max)).toDouble();
    final w = z.width / 24;
    for (var i = 0; i < 24; i++) {
      final hh = math.max(2.0, (z.height - 16) * h[i] / mx);
      c.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(i * w + 1.5, z.height - 14 - hh, w - 3, hh), topLeft: const Radius.circular(3), topRight: const Radius.circular(3)), Paint()..color = Color(0xFF1B7F5C).withOpacity(h[i] > 0 ? 1 : .25));
      if (i % 3 == 0) {
        final tp = TextPainter(text: TextSpan(text: '$i', style: const TextStyle(fontSize: 9, color: Colors.black45)), textDirection: TextDirection.ltr)..layout();
        tp.paint(c, Offset(i * w + w / 2 - tp.width / 2, z.height - 12));
      }
    }
  }

  @override
  bool shouldRepaint(_HoursP o) => true;
}
