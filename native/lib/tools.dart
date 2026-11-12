import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'analysis.dart';
import 'data.dart';
import 'lyrics.dart';
import 'state.dart';
import 'ui.dart';

/// أدوات القصيدة: وضع اللطم، وضع الحسينية، المجلس، الإحصائيات
Analysis? curAn;

void _toast(BuildContext c, String s) {
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s, style: tx(13, c: Colors.white)), duration: const Duration(seconds: 3)));
}

// ================= وضع اللطم =================
class Latm {
  static bool on = false;
  static Timer? _t;
  static int _last = 0;
  static void toggle() {
    on = !on;
    _t?.cancel();
    _t = null;
    if (!on) return;
    _t = Timer.periodic(const Duration(milliseconds: 40), (_) {
      final pl = app.player.p;
      if (!pl.playing || curAn == null) return;
      final b = curAn!.beatAt(pl.position.inMilliseconds / 1000.0);
      final n = DateTime.now().millisecondsSinceEpoch;
      if (b > 0.55 && n - _last > 220) {
        _last = n;
        b > 0.8 ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
      }
    });
  }
}

// ================= وضع الحسينية =================
class HusnPage extends StatefulWidget {
  final List<Lyric> ly;
  const HusnPage(this.ly, {super.key});
  @override
  State<HusnPage> createState() => _HusnPageState();
}

class _HusnPageState extends State<HusnPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = app.player.cur;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onDoubleTap: app.player.toggle,
          child: Stack(children: [
            Positioned.fill(child: LyricStrip(lines: widget.ly, base: 42)),
            Positioned(
              top: 18,
              left: 14,
              right: 14,
              child: SafeArea(
                child: Row(children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const PIcon(Ic.x, color: Colors.white54, size: 26)),
                  const Spacer(),
                  Text(t?.title ?? '', style: tx(15, c: Colors.white38)),
                ]),
              ),
            ),
            Positioned(
              bottom: 22,
              left: 0,
              right: 0,
              child: Center(child: Text('ضغطتان للتشغيل/الإيقاف', style: tx(11, c: Colors.white24))),
            ),
          ]),
        ),
      ),
    );
  }
}

// ================= المجلس (استماع مشترك متزامن، متوافق مع الويب) =================
class Majlis extends ChangeNotifier {
  bool on = false, host = false;
  String code = '';
  StreamSubscription? _un, _ps, _sug;
  List<Map<String, dynamic>> sug = [];
  Timer? _iv;
  Map<String, dynamic>? d;
  int _push = 0, _sk = 0;
  String? _lastTrack;

  Future<void> start(BuildContext ctx, bool asHost, String c) async {
    stop(quiet: true);
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) {
      _toast(ctx, 'سجّل الدخول بحساب Google لاستعمال المجلس');
      return;
    }
    on = true;
    host = asHost;
    code = c;
    final db = FirebaseFirestore.instance;
    if (host) {
      _ps = app.player.p.playerStateStream.listen((_) => push(true));
      _iv = Timer.periodic(const Duration(seconds: 4), (_) => push(false));
      push(true);
      _toast(ctx, 'بدأ المجلس — رمزك $code');
      var first = true;
      _sug = db.collection('majlis/$code/sug').snapshots().listen((q) {
        sug = [for (final d in q.docs) {...d.data(), 'id': d.id}];
        if (!first && q.docChanges.any((c) => c.type == DocumentChangeType.added) && ctx.mounted) _toast(ctx, 'اقتراح جديد من الحضور (${sug.length})');
        first = false;
        notifyListeners();
      }, onError: (_) {});
    } else {
      _un = db.doc('majlis/$code').snapshots().listen((s) {
        if (!s.exists) {
          if (ctx.mounted) _toast(ctx, 'لا يوجد مجلس بهذا الرمز');
          stop();
          return;
        }
        final x = s.data()!;
        if (x['ended'] == true) {
          if (ctx.mounted) _toast(ctx, 'انتهى المجلس');
          stop();
          return;
        }
        if (x['ref'] is! num) return;
        _follow(x);
      }, onError: (_) {
        if (ctx.mounted) _toast(ctx, 'تعذّر الاتصال بالمجلس');
      });
      _iv = Timer.periodic(const Duration(milliseconds: 400), (_) => _tick());
      _toast(ctx, 'انضممت إلى المجلس $code');
    }
    notifyListeners();
  }

  void push(bool force) {
    if (!on || !host) return;
    final n = DateTime.now().millisecondsSinceEpoch;
    if (!force && n - _push < 4000) return;
    _push = n;
    final pl = app.player, t = pl.cur, u = FirebaseAuth.instance.currentUser;
    if (t == null || u == null) return;
    final o = <String, dynamic>{
      'uid': u.uid,
      'ended': false,
      'q': [for (final x in pl.queue.take(300)) x.id],
      'qs': '',
      'track': t.id,
      'pos': pl.p.position.inMilliseconds / 1000.0,
      'ref': n,
      'playing': pl.p.playing,
      'rate': pl.p.speed,
      'at': FieldValue.serverTimestamp(),
    };
    if (_lastTrack != t.id) {
      _lastTrack = t.id;
      o['ly'] = '';
    }
    FirebaseFirestore.instance.doc('majlis/$code').set(o, SetOptions(merge: true)).catchError((_) {});
  }

  double? _expected() {
    final x = d;
    if (x == null) return null;
    final pos = (x['pos'] as num).toDouble(), ref = (x['ref'] as num).toDouble(), rate = (x['rate'] as num?)?.toDouble() ?? 1;
    return pos + (x['playing'] == true ? math.max(0.0, DateTime.now().millisecondsSinceEpoch - ref) / 1000 * rate : 0.0);
  }

  void _follow(Map<String, dynamic> x) {
    d = x;
    final t = app.repo.byId('${x['track']}');
    if (t == null) return;
    final pl = app.player;
    if (pl.cur?.id != t.id) {
      final ids = (x['q'] as List?)?.map((e) => '$e').toList() ?? [t.id];
      final q = ids.map(app.repo.byId).whereType<Track>().toList();
      final list = q.isEmpty ? [t] : q;
      pl.playList(list, math.max(0, list.indexWhere((e) => e.id == t.id)), pos: Duration(milliseconds: ((_expected() ?? 0) * 1000).round()), play: x['playing'] == true);
      _sk = DateTime.now().millisecondsSinceEpoch;
    }
    _tick();
  }

  void _tick() {
    if (!on || host || d == null) return;
    final pl = app.player, x = d!;
    if (pl.cur?.id != x['track']) return;
    if (pl.p.processingState != ProcessingState.ready) return;
    final e = _expected()!, cur = pl.p.position.inMilliseconds / 1000.0, rate = (x['rate'] as num?)?.toDouble() ?? 1;
    if (pl.p.speed != rate) pl.setSpeed(rate);
    if (x['playing'] != true) {
      if (pl.p.playing) pl.p.pause();
      if ((e - cur).abs() > 0.3) pl.seek(e);
      return;
    }
    if (!pl.p.playing) pl.p.play();
    final n = DateTime.now().millisecondsSinceEpoch;
    if (n - _sk < 1600) return;
    if ((e - cur).abs() > 0.45) {
      _sk = n;
      pl.seek(e + 0.08);
    }
  }

  /// الضيف يقترح قصيدة على المضيف
  Future<void> suggest(BuildContext ctx, Track t) async {
    final u = FirebaseAuth.instance.currentUser;
    if (!on || host || u == null) return;
    try {
      await FirebaseFirestore.instance.doc('majlis/$code/sug/${u.uid}_${t.id}').set({'track': t.id, 'by': u.uid, 'at': FieldValue.serverTimestamp()});
      if (ctx.mounted) _toast(ctx, 'أُرسل الاقتراح للمضيف');
    } catch (_) {
      if (ctx.mounted) _toast(ctx, 'تعذّر إرسال الاقتراح');
    }
  }

  void acceptSug(Map<String, dynamic> x) {
    final t = app.repo.byId('${x['track']}');
    if (t != null) app.player.playNext(t);
    dropSug(x);
    push(true);
  }

  void dropSug(Map<String, dynamic> x) {
    FirebaseFirestore.instance.doc('majlis/$code/sug/${x['id']}').delete().catchError((_) {});
    sug.removeWhere((y) => y['id'] == x['id']);
    notifyListeners();
  }

  void stop({bool quiet = false}) {
    final wasHost = on && host;
    _un?.cancel();
    _ps?.cancel();
    _sug?.cancel();
    _sug = null;
    sug = [];
    _iv?.cancel();
    _un = _ps = null;
    _iv = null;
    d = null;
    if (!quiet && wasHost) FirebaseFirestore.instance.doc('majlis/$code').set({'ended': true, 'playing': false}, SetOptions(merge: true)).catchError((_) {});
    on = false;
    notifyListeners();
  }
}

final majlis = Majlis();

void showMajlisSheet(BuildContext context) {
  final inp = TextEditingController();
  showMSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1612),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(c).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('المجلس', style: tx(20, c: Colors.white)),
          const SizedBox(height: 4),
          Text('استماع مشترك: الكل يسمع نفس القصيدة بنفس اللحظة.', style: tx(13, c: Colors.white54)),
          const SizedBox(height: 16),
          if (majlis.on) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x14E8C468), border: Border.all(color: kGold)),
              child: Column(children: [
                Text(majlis.host ? 'مجلسك قائم' : 'أنت في المجلس', style: tx(14, c: Colors.white70)),
                Text(majlis.code, textDirection: TextDirection.ltr, style: tx(34, c: kGold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(data: '${kBase}?mj=${majlis.code}', size: 170, padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 8),
                Text(majlis.host ? 'وجّه كاميرا الحاضر على الرمز، أو شارك الرابط' : 'كل ما يشغّله المضيف يصلك بنفس اللحظة', textAlign: TextAlign.center, style: tx(12, c: Colors.white54)),
                if (app.player.cur != null) ...[
                  const SizedBox(height: 10),
                  Text('يُشغَّل الآن: ${app.player.cur!.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, c: Colors.white)),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            if (majlis.host && majlis.sug.isNotEmpty) ...[
              Text('اقتراحات الحضور', style: tx(14, c: Colors.white70)),
              for (final x in List.of(majlis.sug))
                Builder(builder: (_) {
                  final t = app.repo.byId('${x['track']}');
                  if (t == null) return const SizedBox.shrink();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Cover(t.coverUrl, size: 40, radius: 8),
                    title: Text(t.title, style: tx(14, c: Colors.white)),
                    subtitle: Text('${x['name'] ?? ''}', style: tx(11.5, c: Colors.white38)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(onPressed: () {
                        majlis.acceptSug(x);
                        Navigator.pop(c);
                      }, child: Text('التالي', style: tx(13, c: kGold))),
                      TextButton(onPressed: () {
                        majlis.dropSug(x);
                        Navigator.pop(c);
                      }, child: Text('تجاهل', style: tx(13, c: Colors.white54))),
                    ]),
                  );
                }),
              const SizedBox(height: 8),
            ],
            Row(children: [
              Expanded(child: GoldButton('مشاركة الرابط', () => Share.share('انضم إلى مجلسي في منبر — نسمع معاً بنفس اللحظة:\n${kBase}?mj=${majlis.code}'), icon: Ic.share)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: majlis.code));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('نُسخ الرمز', style: tx(13, c: Colors.white))));
                },
                child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x14FFFFFF), border: Border.all(color: const Color(0x33FFFFFF))), child: Text('نسخ الرمز', style: tx(14, c: Colors.white))),
              ),
            ]),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                majlis.stop();
                Navigator.pop(c);
              },
              child: Text(majlis.host ? 'إنهاء المجلس' : 'مغادرة المجلس', style: tx(15, c: const Color(0xFFFF6B6B))),
            ),
          ] else ...[
            GoldButton('ابدأ مجلساً', () async {
              final code = (100000 + math.Random().nextInt(900000)).toString();
              Navigator.pop(c);
              await majlis.start(context, true, code);
              if (context.mounted && majlis.on) showMajlisSheet(context);
            }, icon: Ic.users),
            const SizedBox(height: 16),
            Text('أو انضم برمز', style: tx(13, c: Colors.white54)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: inp,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: tx(20, c: Colors.white),
                  decoration: InputDecoration(hintText: 'الرمز', hintStyle: tx(16, c: Colors.white24), filled: true, fillColor: const Color(0x14FFFFFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  final code = inp.text.trim();
                  if (code.isEmpty) return;
                  Navigator.pop(c);
                  majlis.start(context, false, code).then((_) {
                    if (context.mounted && majlis.on) showMajlisSheet(context);
                  });
                },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: kGold), child: Text('انضمام', style: tx(15, c: const Color(0xFF2A2106)))),
              ),
            ]),
          ],
        ]),
      ),
    ),
  );
}

// ================= الإحصائيات =================
void showStatsSheet(BuildContext context) {
  showMSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1612),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: MediaQuery.of(c).size.height * 0.8,
        child: FutureBuilder<List<(Track, int, int)>>(
          future: () async {
            final db = FirebaseFirestore.instance;
            final r = await Future.wait([db.collection('stats').orderBy('plays', descending: true).limit(60).get(), db.collection('rx').limit(2000).get()]);
            final lk = <String, int>{};
            for (final d in r[1].docs) {
              final k = '${d.data()['track']}';
              lk[k] = (lk[k] ?? 0) + 1;
            }
            final out = <(Track, int, int)>[];
            for (final d in r[0].docs) {
              final t = app.repo.byId(d.id);
              if (t != null) out.add((t, (d.data()['plays'] as num?)?.toInt() ?? 0, lk[d.id] ?? 0));
            }
            return out;
          }(),
          builder: (_, s) {
            final l = s.data;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Row(children: [
                  Text('الإحصائيات', style: tx(20, c: Colors.white)),
                  const Spacer(),
                  Text('استماع', style: tx(12, c: Colors.white54)),
                  const SizedBox(width: 26),
                  Text('إعجاب', style: tx(12, c: Colors.white54)),
                ]),
              ),
              Expanded(
                child: l == null
                    ? Center(child: s.hasError ? Text('تعذّر التحميل', style: tx(14, c: Colors.white54)) : const CircularProgressIndicator(color: kGold))
                    : ListView.builder(
                        itemCount: l.length,
                        itemBuilder: (_, i) => ListTile(
                          leading: SizedBox(width: 28, child: Text('${i + 1}', style: tx(14, c: i < 3 ? kGold : Colors.white54))),
                          title: Text(l[i].$1.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14.5, c: Colors.white)),
                          subtitle: Text(l[i].$1.reciter, style: tx(11.5, c: Colors.white38)),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(width: 44, child: Text('${l[i].$2}', textAlign: TextAlign.center, style: tx(14, c: kGold))),
                            const SizedBox(width: 12),
                            SizedBox(width: 40, child: Text('${l[i].$3}', textAlign: TextAlign.center, style: tx(14, c: const Color(0xFFFF8FA3)))),
                          ]),
                        ),
                      ),
              ),
            ]);
          },
        ),
      ),
    ),
  );
}

// ================= التعرّف على القصيدة بالمايك =================
Future<void> recognizePoem(BuildContext context) async {
  final stt = SpeechToText();
  var ok = false;
  try {
    ok = await stt.initialize(onError: (_) {});
  } catch (_) {}
  if (!context.mounted) return;
  if (!ok) {
    _toast(context, 'يلزم السماح باستخدام الميكروفون وتوفّر خدمة التعرّف على الكلام من Google');
    return;
  }
  app.repo.loadAllLyrics();
  var heardText = '';
  var sec = 14;
  final st = ValueNotifier<String>('قرّب الهاتف من الصوت… $sec');
  var cancelled = false;
  final dlg = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (d) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1C1612),
        title: Text('التعرّف على القصيدة', style: tx(18, c: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const PIcon('mic', color: kGold, size: 48),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(valueListenable: st, builder: (_, v, __) => Text(v, textAlign: TextAlign.center, style: tx(14, c: Colors.white70))),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              stt.cancel();
              Navigator.pop(d);
            },
            child: Text('إلغاء', style: tx(14, c: kGold)),
          ),
        ],
      ),
    ),
  );
  final wasPlaying = app.player.p.playing;
  if (wasPlaying) app.player.p.pause();
  // العربية دائماً: لهجة عراقية إن وُجدت، وإلا أي عربية، وإلا نفرض ar-IQ
  var lid = 'ar-IQ';
  try {
    final locs = await stt.locales();
    final ids = locs.map((l) => l.localeId).toList();
    lid = ids.firstWhere((x) => x.replaceAll('_', '-').startsWith('ar-IQ'), orElse: () => ids.firstWhere((x) => x.startsWith('ar'), orElse: () => 'ar-IQ'));
  } catch (_) {}
  var acc = '', part = '';
  Future<void> go() => stt.listen(
        onResult: (r) {
          part = r.recognizedWords;
          if (r.finalResult) {
            acc = '$acc ${r.recognizedWords}';
            part = '';
          }
          heardText = '$acc $part'.trim();
        },
        localeId: lid,
        listenFor: const Duration(seconds: 14),
        pauseFor: const Duration(seconds: 6),
        listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: false, listenMode: ListenMode.dictation),
      );
  await go();
  sec = 14;
  while (sec > 0 && !cancelled) {
    await Future.delayed(const Duration(seconds: 1));
    sec--;
    // أندرويد يوقف الاستماع عند الصمت — نعيد تشغيله لنجمع أكثر
    if (!stt.isListening && sec > 2 && !cancelled) {
      try {
        await go();
      } catch (_) {}
    }
    st.value = sec > 0 ? 'قرّب الهاتف من الصوت… $sec\n$heardText' : 'جارٍ التحليل…';
  }
  await stt.stop();
  await Future.delayed(const Duration(milliseconds: 600));
  if (cancelled) return;
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  await dlg;
  final heard = _stems(heardText);
  if (!context.mounted) return;
  if (heard.length < 2) {
    _toast(context, 'لم يُسمع كلام واضح، حاول مرة أخرى');
    if (wasPlaying) app.player.p.play();
    return;
  }
  // مطابقة ذكية: نافذة من 3 أسطر متتالية، كلمات مجذّرة مع تسامح بحرف واحد، ومكافأة للكلمات المتتالية
  String? bestId;
  var bestS = 0.0, bestLine = '';
  final bestBy = <String, double>{};
  app.repo.allLy.forEach((id, txt) {
    final lines = txt.split('\n').where((x) => x.trim().isNotEmpty).toList();
    final ls = [for (final l in lines) _stems(l)];
    for (var i = 0; i < ls.length; i++) {
      final win = [...ls[i], if (i + 1 < ls.length) ...ls[i + 1], if (i + 2 < ls.length) ...ls[i + 2]];
      if (win.isEmpty) continue;
      var hit = 0, run = 0, bonus = 0;
      for (final w in heard) {
        if (win.any((x) => _near(w, x))) {
          hit++;
          run++;
          if (run >= 2) bonus++;
        } else {
          run = 0;
        }
      }
      final sc = hit / heard.length + bonus * 0.08;
      if (sc > (bestBy[id] ?? 0)) bestBy[id] = sc;
      if (sc > bestS) {
        bestS = sc;
        bestId = id;
        bestLine = lines[i];
      }
    }
  });
  if (bestS < 0.34) bestId = null;
  final t = bestId == null ? null : app.repo.byId(bestId!);
  if (t == null) {
    _toast(context, 'لم نتعرّف على القصيدة في المكتبة');
    if (wasPlaying) app.player.p.play();
    return;
  }
  final ly = await app.repo.lyricsFor(t);
  final at = ly.where((x) => x.l == bestLine).firstOrNull?.t ?? 0;
  final all = app.repo.tracks;
  app.player.playList(all, all.indexOf(t), pos: Duration(milliseconds: (at * 1000).round()));
  if (context.mounted) _toast(context, 'تم التعرّف: ${t.title}');
}


/// تجذير بسيط للعربية: توحيد الحروف وحذف «و/ال/ب/ف/ل» من البداية
List<String> _stems(String s) => norm(s).split(' ').where((x) => x.length > 1).map((w) {
      var x = w;
      for (final p in ['وال', 'بال', 'فال', 'كال', 'لل', 'ال']) {
        if (x.startsWith(p) && x.length - p.length >= 2) {
          x = x.substring(p.length);
          break;
        }
      }
      if (x.length > 3 && (x.startsWith('و') || x.startsWith('ف') || x.startsWith('ب'))) x = x.substring(1);
      return x;
    }).toList();

bool _near(String a, String b) {
  if (a == b) return true;
  if (a.length < 4 || b.length < 4 || (a.length - b.length).abs() > 1) return false;
  // مسافة تحرير ≤ 1
  var i = 0, j = 0, e = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++e > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (b.length > a.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return e + (a.length - i) + (b.length - j) <= 1;
}
