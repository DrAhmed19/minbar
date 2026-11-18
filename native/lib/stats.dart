import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// صفحة الإحصائيات للأدمن: تقرأ /api/stats (Google Analytics) وتعرض النشطين الآن والمستخدمين والمخططات والدول
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, dynamic>? _d;
  String _err = '';
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _err = '';
    });
    try {
      final tk = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (tk == null) throw 'سجّل الدخول';
      final c = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      final rq = await c.getUrl(Uri.parse('${kBase}api/stats'));
      rq.headers.set('authorization', 'Bearer $tk');
      final rs = await rq.close().timeout(const Duration(seconds: 30));
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

  String _f(num n) => n.toInt().toString();

  Widget _box(String v, String l) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [Text(v, style: tx(20, w: FontWeight.w800, c: kGreen)), Text(l, style: tx(11, c: kMuted))]),
        ),
      );

  Widget _bars(List s, String k, Color col) {
    final mx = s.fold<num>(1, (m, e) => (e[k] as num) > m ? e[k] as num : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final e in s)
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(_f(e[k] as num), style: tx(9.5, c: kMuted)),
                const SizedBox(height: 2),
                Container(height: 4 + 86 * ((e[k] as num) / mx), margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: col, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
                const SizedBox(height: 3),
                Text('${'${e['d']}'.substring(6)}/${'${e['d']}'.substring(4, 6)}', style: tx(8.5, c: kMuted)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _sec(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 8), child: Text(t, style: tx(14.5, w: FontWeight.w800, c: kGreen)));

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
          actions: [IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: _busy
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : d == null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_err, textAlign: TextAlign.center, style: tx(14, c: kMuted))))
                : ListView(padding: const EdgeInsets.all(14), children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(18)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(_f(d['now'] as num), style: tx(40, w: FontWeight.w800, c: Colors.white)),
                        const SizedBox(width: 10),
                        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('نشط الآن (آخر 30 دقيقة)', style: tx(12.5, c: Colors.white70))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [_box(_f(d['users']['t']), 'اليوم'), _box(_f(d['users']['w']), 'آخر 7 أيام'), _box(_f(d['users']['m']), 'آخر 30 يوم')]),
                    const SizedBox(height: 8),
                    Row(children: [_box(_f(d['fresh']['t']), 'جدد اليوم'), _box(_f(d['fresh']['w']), 'جدد 7 أيام'), _box(_f(d['fresh']['m']), 'جدد 30 يوم')]),
                    _sec('المستخدمون النشطون يومياً'),
                    _bars(d['series'] as List, 'u', kGreen),
                    _sec('الجلسات (مرات الفتح)'),
                    _bars(d['series'] as List, 's', const Color(0xFFC9A84C)),
                    _sec('الدول (آخر 30 يوم)'),
                    for (final c in (d['countries'] as List))
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [Text('${c[0]}', style: tx(13.5)), const Spacer(), Text(_f(c[1] as num), style: tx(13.5, w: FontWeight.w800, c: kGreen))]),
                      ),
                    const SizedBox(height: 10),
                    Text('البيانات تتأخر قليلاً عن الواقع', textAlign: TextAlign.center, style: tx(11, c: kMuted)),
                  ]),
      ),
    );
  }
}
