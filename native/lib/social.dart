import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// التفاعلات (❤️ بلحظتها) والتعليقات العائمة والذروة — مثل الويب (مجموعتا rx و cmts)
class Cm {
  final String id, text, name, uid;
  final double t;
  final bool mine;
  Cm(this.id, this.t, this.text, this.name, this.uid, this.mine);
}

class Social extends ChangeNotifier {
  String? trackId;
  List<double> rx = [];
  List<Cm> cm = [];
  StreamSubscription? _rxSub;
  final _fly = StreamController<bool>.broadcast(); // true = خاص بي
  final _bubble = StreamController<Cm>.broadcast();
  Stream<bool> get fly => _fly.stream;
  Stream<Cm> get bubble => _bubble.stream;
  int _rxPtr = 0, _cmPtr = 0;
  double _last = 0;
  DateTime _sent = DateTime(2000), _burst = DateTime(2000);
  StreamSubscription? _pos;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  bool get signed => uid != null && !(FirebaseAuth.instance.currentUser?.isAnonymous ?? true);

  void start() {
    _pos ??= app.player.p.positionStream.listen(_tick);
  }

  Future<void> load(Track t) async {
    if (trackId == t.id) return;
    trackId = t.id;
    rx = [];
    cm = [];
    _reset();
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    try {
      final loc = (jsonDecode(sp.getString('rxLocal') ?? '{}') as Map)[t.id];
      if (loc is List) rx.addAll(loc.map((e) => (e as num).toDouble()));
    } catch (_) {}
    await _rxSub?.cancel();
    var first = true;
    try {
      _rxSub = FirebaseFirestore.instance.collection('rx').where('track', isEqualTo: t.id).snapshots().listen((q) {
        if (trackId != t.id) return;
        if (first) {
          first = false;
          for (final d in q.docs) {
            final v = d.data()['t'];
            if (v is num) rx.add(v.toDouble());
          }
          rx.sort();
          _reset();
          notifyListeners();
          return;
        }
        var live = 0;
        for (final c in q.docChanges) {
          if (c.type != DocumentChangeType.added || c.doc.metadata.hasPendingWrites) continue;
          final x = c.doc.data();
          if (x == null || x['t'] is! num || x['uid'] == uid) continue;
          rx.add((x['t'] as num).toDouble());
          live++;
        }
        if (live > 0) {
          for (var i = 0; i < math.min(live * 2, 6); i++) {
            Future.delayed(Duration(milliseconds: i * 140), () => _fly.add(false));
          }
          rx.sort();
          _reset();
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {}
    try {
      final q = await FirebaseFirestore.instance.collection('cmts').where('track', isEqualTo: t.id).get();
      if (trackId != t.id) return;
      final me = uid;
      for (final d in q.docs) {
        final x = d.data();
        if (x['t'] is! num || x['text'] == null) continue;
        final mine = me != null && x['uid'] == me, st = '${x['st'] ?? 'ok'}';
        if (st == 'block' || (st == 'review' && !mine)) continue;
        final s = '${x['text']}';
        cm.add(Cm(d.id, (x['t'] as num).toDouble(), s.length > 70 ? s.substring(0, 70) : s, '${x['name'] ?? ''}', '${x['uid'] ?? ''}', mine));
      }
      cm.sort((a, b) => a.t.compareTo(b.t));
      _reset();
      notifyListeners();
    } catch (_) {}
  }

  void _reset() {
    final now = app.player.p.position.inMilliseconds / 1000.0;
    _rxPtr = 0;
    while (_rxPtr < rx.length && rx[_rxPtr] < now) {
      _rxPtr++;
    }
    _cmPtr = 0;
    while (_cmPtr < cm.length && cm[_cmPtr].t < now - 3) {
      _cmPtr++;
    }
    _last = now;
  }

  void _tick(Duration d) {
    if (!app.player.p.playing || app.player.quiet || app.player.cmOn == 0) return;
    final now = d.inMilliseconds / 1000.0;
    if ((now - _last).abs() > 1.5) _reset();
    _last = now;
    while (_rxPtr < rx.length && rx[_rxPtr] <= now) {
      final pn = DateTime.now();
      if (pn.difference(_burst).inMilliseconds > 140) {
        _fly.add(false);
        _burst = pn;
      }
      _rxPtr++;
    }
    while (_cmPtr < cm.length && cm[_cmPtr].t <= now) {
      if (cm[_cmPtr].t > now - 7) _bubble.add(cm[_cmPtr]);
      _cmPtr++;
    }
  }

  Future<void> sendRx(BuildContext ctx) async {
    final t = app.player.cur;
    if (t == null) return;
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () => _fly.add(true));
    }
    HapticFeedback.lightImpact();
    final n = DateTime.now();
    if (n.difference(_sent).inMilliseconds < 1200) return;
    _sent = n;
    final at = (app.player.p.position.inMilliseconds / 10).round() / 100;
    rx.add(at);
    rx.sort();
    _reset();
    notifyListeners();
    var ok = false;
    if (signed) {
      try {
        await FirebaseFirestore.instance.collection('rx').add({'track': t.id, 't': at, 'e': '❤️', 'uid': uid, 'at': FieldValue.serverTimestamp()});
        ok = true;
      } catch (_) {}
    } else if (ctx.mounted) {
      _toast(ctx, 'سجّل الدخول ليظهر إعجابك للآخرين');
    }
    if (!ok) {
      final sp = await SharedPreferences.getInstance();
      final all = jsonDecode(sp.getString('rxLocal') ?? '{}') as Map;
      (all[t.id] ??= []).add(at);
      await sp.setString('rxLocal', jsonEncode(all));
    }
  }

  static final _bad = RegExp(r'(https?:|www\.|\.com|\.net|t\.me|@\w)', caseSensitive: false);
  Future<String?> sendCm(String text) async {
    final t = app.player.cur;
    text = text.trim();
    if (t == null || text.isEmpty) return null;
    if (text.length > 70) text = text.substring(0, 70);
    if (_bad.hasMatch(text) || RegExp(r'(.)\1{6,}').hasMatch(text)) return 'لا يُسمح بالروابط أو التكرار';
    final at = (app.player.p.position.inMilliseconds / 10).round() / 100;
    final u = FirebaseAuth.instance.currentUser;
    final name = (u?.displayName ?? '').trim().split(' ').first;
    final c = Cm('', at, text, name, uid ?? '', true);
    cm.add(c);
    cm.sort((a, b) => a.t.compareTo(b.t));
    _bubble.add(c);
    notifyListeners();
    if (!signed) return 'سجّل الدخول ليظهر تعليقك للآخرين';
    try {
      await FirebaseFirestore.instance.collection('cmts').add({'track': t.id, 't': at, 'text': text, 'uid': u!.uid, 'name': name, 'st': 'ok', 'at': FieldValue.serverTimestamp()});
    } catch (_) {
      return 'تعذّر الإرسال';
    }
    return null;
  }

  /// الذروة: أكثر نافذة 10 ثوانٍ إعجاباً
  double? peakT() {
    if (rx.isEmpty) return null;
    var best = 0, bt = rx.first;
    for (var i = 0, j = 0; i < rx.length; i++) {
      while (rx[i] - rx[j] > 10) {
        j++;
      }
      if (i - j + 1 > best) {
        best = i - j + 1;
        bt = rx[j];
      }
    }
    return math.max(0.0, bt - 2);
  }
}

final social = Social();

void _toast(BuildContext c, String s) {
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s, style: tx(13, c: Colors.white)), duration: const Duration(seconds: 2)));
}

/// زر القلب الجانبي + القلوب الطائرة
class RxLayer extends StatefulWidget {
  const RxLayer({super.key});
  @override
  State<RxLayer> createState() => _RxLayerState();
}

class _Heart {
  final double dx, s, hue, dur;
  final bool me;
  final DateTime at = DateTime.now();
  _Heart(this.dx, this.s, this.hue, this.dur, this.me);
}

class _RxLayerState extends State<RxLayer> with SingleTickerProviderStateMixin {
  final hs = <_Heart>[];
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(days: 1));
  StreamSubscription? _s;
  final rnd = math.Random();
  double pop = 0;

  @override
  void initState() {
    super.initState();
    _s = social.fly.listen((me) {
      hs.add(_Heart(rnd.nextDouble() * 40 - 30, 0.8 + rnd.nextDouble() * 0.5 + (me ? 0.3 : 0), 340 + rnd.nextDouble() * 30, 2.6 + rnd.nextDouble() * 0.9, me));
      if (hs.length > 40) hs.removeAt(0);
      if (!_c.isAnimating) _c.forward(from: 0);
    });
    social.addListener(_r);
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _s?.cancel();
    social.removeListener(_r);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (app.player.cmOn == 0) return const SizedBox.shrink();
    final n = social.rx.length;
    return SizedBox(
      width: 70,
      height: 320,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final now = DateTime.now();
            hs.removeWhere((h) => now.difference(h.at).inMilliseconds / 1000 > h.dur);
            if (hs.isEmpty && _c.isAnimating) Future.microtask(() => _c.stop());
            return Stack(clipBehavior: Clip.none, children: [
              for (final h in hs)
                Builder(builder: (_) {
                  final p = (now.difference(h.at).inMilliseconds / 1000 / h.dur).clamp(0.0, 1.0);
                  final e = Curves.easeOutCubic.transform(p);
                  final op = p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85;
                  final sc = p < 0.15 ? 0.4 + (h.s - 0.4) * p / 0.15 : h.s * (1 - 0.1 * p);
                  return Positioned(
                    bottom: 40 + e * 250,
                    left: 23 + h.dx * e,
                    child: Opacity(opacity: op.clamp(0.0, 1.0), child: Transform.scale(scale: sc, child: Text('❤', style: TextStyle(fontSize: 22, color: h.me ? const Color(0xFFFF4D6D) : HSLColor.fromAHSL(1, h.hue % 360, 0.85, 0.64).toColor())))),
                  );
                }),
            ]);
          },
        ),
        Positioned(
          bottom: 0,
          child: GestureDetector(
            onTap: () => social.sendRx(context),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x33FFFFFF), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14)]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('❤', style: TextStyle(fontSize: 24, color: Colors.white)),
                if (n > 0) Text(n > 999 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n', style: tx(10, c: Colors.white70)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// التعليقات العائمة (جانبية، تصعد وتتلاشى)
class CmLayer extends StatefulWidget {
  const CmLayer({super.key});
  @override
  State<CmLayer> createState() => _CmLayerState();
}

class _CmLayerState extends State<CmLayer> {
  final items = <(Cm, DateTime, int)>[];
  StreamSubscription? _s;
  Timer? _t;
  int side = 0;

  @override
  void initState() {
    super.initState();
    _s = social.bubble.listen((c) {
      final mx = [3, 5, 8][(app.player.cmDens - 1).clamp(0, 2)];
      if (items.length >= mx) items.removeAt(0);
      side = 1 - side;
      items.add((c, DateTime.now(), c.mine ? 1 : side));
      _t ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
        items.removeWhere((x) => DateTime.now().difference(x.$2).inMilliseconds > 9000);
        if (items.isEmpty) {
          _t?.cancel();
          _t = null;
        }
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _s?.cancel();
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (_, c) {
        final H = c.maxHeight;
        return Stack(children: [
          for (var j = 0; j < items.length; j++)
            Builder(builder: (_) {
              final it = items[j];
              final p = DateTime.now().difference(it.$2).inMilliseconds / 9000;
              final bubble = Container(
                constraints: BoxConstraints(maxWidth: c.maxWidth * 0.62),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: it.$1.mine ? const Color(0xCC8A6A1E) : const Color(0x8C000000), border: Border.all(color: const Color(0x2EFFFFFF))),
                child: Text(it.$1.text, style: tx(13, c: Colors.white)),
              );
              if (app.player.cmView == 1) {
                // طائر عبر الشاشة بممرّات علوية
                final W = c.maxWidth, lane = (it.$2.millisecondsSinceEpoch ~/ 7) % 5;
                return Positioned(top: 6.0 + lane * 34, right: -W * 0.7 + p * W * 1.6, child: Opacity(opacity: p < 0.05 ? p / 0.05 : (p > 0.92 ? (1 - p) / 0.08 : 1.0), child: bubble));
              }
              final op = p < 0.08 ? p / 0.08 : (p > 0.8 ? (1 - p) / 0.2 : 1.0);
              final y = p < 0.08 ? 14 * (1 - p / 0.08) : -H * 0.62 * ((p - 0.08) / 0.72).clamp(0.0, 1.0) - (p > 0.8 ? H * 0.23 * (p - 0.8) / 0.2 : 0.0);
              return Positioned(
                bottom: 10 - y,
                right: it.$3 == 1 ? 10 : null,
                left: it.$3 == 0 ? 10 : null,
                child: Opacity(opacity: op.clamp(0.0, 1.0), child: bubble),
              );
            }),
        ]);
      }),
    );
  }
}

void showCommentsSheet(BuildContext context) {
  final inp = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1612),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => StatefulBuilder(builder: (c, ss) {
      final l = social.cm;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(c).size.height * 0.7,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Row(children: [
                  Text('التعليقات', style: tx(19, c: Colors.white)),
                  const SizedBox(width: 8),
                  Text('${l.length}', style: tx(14, c: kGold)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(c), child: const PIcon(Ic.x, color: Colors.white, size: 22)),
                ]),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('يظهر تعليقك عائماً للجميع عند هذه اللحظة من القصيدة', style: tx(12, c: Colors.white38))),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  _chip(app.player.cmOn == 1 ? 'العائمة: تشغيل' : 'العائمة: إيقاف', app.player.cmOn == 1, () {
                    app.player.setPref('cmOn', app.player.cmOn == 1 ? 0 : 1);
                    ss(() {});
                  }),
                  for (final d in [(1, 'قليلة'), (2, 'متوسطة'), (3, 'كثيرة')])
                    _chip(d.$2, app.player.cmDens == d.$1, () {
                      app.player.setPref('cmDens', d.$1);
                      ss(() {});
                    }),
                  _chip('جانبية', app.player.cmView == 0, () {
                    app.player.setPref('cmView', 0);
                    ss(() {});
                  }),
                  _chip('طائرة', app.player.cmView == 1, () {
                    app.player.setPref('cmView', 1);
                    ss(() {});
                  }),
                ]),
              ),
              Expanded(
                child: l.isEmpty
                    ? Center(child: Text('لا تعليقات بعد — كن أول من يعلّق', style: tx(14, c: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: l.length,
                        itemBuilder: (_, i) => InkWell(
                          onTap: () => app.player.seek(math.max(0.0, l[i].t - 1)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0x24E8C468)), child: Text(fmt(l[i].t), style: tx(11.5, c: kGold))),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  if (l[i].name.isNotEmpty) Text(l[i].name, style: tx(11.5, c: Colors.white54)),
                                  Text(l[i].text, style: tx(14, c: Colors.white)),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: inp,
                      maxLength: 70,
                      style: tx(14, c: Colors.white),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'اكتب تعليقاً عند ${fmt(app.player.p.position.inMilliseconds / 1000)}',
                        hintStyle: tx(13, c: Colors.white38),
                        filled: true,
                        fillColor: const Color(0x14FFFFFF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final e = await social.sendCm(inp.text);
                      inp.clear();
                      ss(() {});
                      if (e != null && c.mounted) _toast(c, e);
                    },
                    child: Container(width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: kGold), child: const Center(child: PIcon(Ic.back, color: Color(0xFF2A2106), size: 22))),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
    }),
  );
}

Widget _chip(String s, bool on, VoidCallback f) => GestureDetector(
      onTap: f,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: on ? const Color(0x2EE8C468) : const Color(0x12FFFFFF), border: Border.all(color: on ? kGold : const Color(0x24FFFFFF))),
        child: Text(s, style: tx(12.5, c: on ? kGold : Colors.white70)),
      ),
    );
