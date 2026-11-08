import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'analysis.dart';
import 'data.dart';
import 'home.dart';
import 'player_ui.dart';
import 'state.dart';
import 'ui.dart';

/// عينات: مقطع مختار من كل قصيدة (أقوى جزء) يتبدّل بالسحب العمودي
class SamplesPage extends StatefulWidget {
  const SamplesPage({super.key});
  @override
  State<SamplesPage> createState() => _SamplesPageState();
}

class _SamplesPageState extends State<SamplesPage> {
  static const segLen = 24.0;
  late final List<Track> list;
  final pc = PageController();
  final Map<String, double> _start = {};
  final Map<String, List<Lyric>> _ly = {};
  bool _keep = false;
  int page = 0;
  double segStart = 0, segEnd = 0;
  double pos = 0;
  StreamSubscription<Duration>? _sub;
  // حفظ الحالة السابقة لإرجاعها عند الخروج
  late final List<Track> _oq;
  late final int _oi;
  late final Duration _op;
  late final bool _wasPlaying;

  @override
  void initState() {
    super.initState();
    final pl = app.player;
    _oq = List.of(pl.queue);
    _oi = pl.index;
    _op = pl.p.position;
    _wasPlaying = pl.p.playing;
    pl.quiet = true;
    list = List.of(app.repo.tracks.where((t) => t.audio.isNotEmpty))..shuffle(math.Random());
    _sub = pl.p.positionStream.listen(_tick);
    if (list.isNotEmpty) _go(0);
  }

  void _tick(Duration d) {
    final s = d.inMilliseconds / 1000.0;
    if (!mounted) return;
    if (segEnd > 0 && s >= segEnd) {
      app.player.p.seek(Duration(milliseconds: (segStart * 1000).round()));
      return;
    }
    setState(() => pos = s);
  }

  Future<double> _best(Track t) async {
    if (_start.containsKey(t.id)) return _start[t.id]!;
    double st = 0;
    final a = await Analysis.load(t.id);
    if (a != null) {
      final secs = (a.nf / a.fps).floor();
      final env = a.envelope(secs.clamp(1, 100000));
      final w = segLen.toInt();
      if (secs > w + 10) {
        var best = -1.0;
        var run = 0.0;
        for (var i = 0; i < w; i++) {
          run += env[i];
        }
        for (var i = 0; i + w <= secs; i++) {
          if (i > 0) run += env[i + w - 1] - env[i - 1];
          // نتجنّب أول 8 ثوانٍ وآخر 10
          if (i >= 8 && i + w <= secs - 10 && run > best) {
            best = run;
            st = i.toDouble();
          }
        }
      } else {
        st = math.max(0, secs * 0.2);
      }
    } else {
      st = 20;
    }
    _start[t.id] = st;
    return st;
  }

  Future<void> _go(int i) async {
    if (i < 0 || i >= list.length) return;
    final t = list[i];
    setState(() {
      page = i;
      segEnd = 0;
      pos = 0;
    });
    repoLy(t);
    final st = await _best(t);
    if (!mounted || page != i) return;
    segStart = st;
    final pl = app.player;
    await pl.playList([t], 0, pos: Duration(milliseconds: (st * 1000).round()));
    if (!mounted || page != i) return;
    setState(() => segEnd = st + segLen);
  }

  Future<void> repoLy(Track t) async {
    if (_ly.containsKey(t.id)) return;
    final l = await app.repo.lyricsFor(t);
    _ly[t.id] = l;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    final pl = app.player;
    pl.quiet = false;
    if (_keep) {
    } else if (_oq.isNotEmpty && _oi >= 0) {
      pl.playList(_oq, _oi, pos: _op, play: _wasPlaying);
    } else {
      pl.p.stop();
    }
    pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: list.isEmpty
            ? Center(child: Text('لا توجد قصائد', style: tx(14, c: Colors.white70)))
            : Stack(children: [
                PageView.builder(
                  controller: pc,
                  scrollDirection: Axis.vertical,
                  itemCount: list.length,
                  onPageChanged: _go,
                  itemBuilder: (_, i) => _card(list[i], i == page),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const PIcon(Ic.back, color: Colors.white)),
                      Text('عينات', style: tx(18, c: Colors.white, w: FontWeight.w800)),
                    ]),
                  ),
                ),
              ]),
      ),
    );
  }

  Widget _card(Track t, bool on) {
    final r = app.repo;
    final ly = _ly[t.id] ?? const <Lyric>[];
    final rel = pos;
    var ci = -1;
    for (var k = 0; k < ly.length; k++) {
      if (ly[k].t <= rel + app.player.lyOffset) {
        ci = k;
      } else {
        break;
      }
    }
    final prog = on && segEnd > segStart ? ((rel - segStart) / (segEnd - segStart)).clamp(0.0, 1.0) : 0.0;
    return Stack(fit: StackFit.expand, children: [
      Cover(t.coverUrl, size: 900, radius: 0),
      Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99000000), Color(0xCC000000), Color(0xF2000000)]))),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 24),
          child: Column(children: [
            const Spacer(),
            Cover(t.coverUrl, size: 150, radius: 22),
            const SizedBox(height: 18),
            Text(t.title, textAlign: TextAlign.center, maxLines: 2, style: tx(22, c: Colors.white, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(t.reciter, style: tx(14, c: kGold, w: FontWeight.w700)),
            const SizedBox(height: 22),
            SizedBox(
              height: 92,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    on && ci >= 0 ? ly[ci].l : (on ? '♪' : ''),
                    key: ValueKey('${t.id}$ci'),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: tx(21, c: Colors.white, w: FontWeight.w700, h: 1.7),
                  ),
                ),
              ),
            ),
            const Spacer(),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: prog, minHeight: 3, backgroundColor: Colors.white24, color: kGold)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(
                onPressed: () => setState(() => r.toggleFav(t.id)),
                icon: PIcon(r.isFav(t.id) ? Ic.heartF : Ic.heart, color: r.isFav(t.id) ? const Color(0xFFFF6B6B) : Colors.white, size: 28),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${kBase}?p=${t.id}'));
                  snack(context, 'نُسخ رابط المشاركة');
                },
                icon: const PIcon(Ic.share, color: Colors.white, size: 26),
              ),
              IconButton(onPressed: () => trackSheet(context, t), icon: const PIcon(Ic.more, color: Colors.white, size: 28)),
            ]),
            const SizedBox(height: 8),
            GoldButton('استمع كاملة', () {
              final pl = app.player;
              _keep = true;
              pl.quiet = false;
              pl.playList(r.tracks, r.tracks.indexWhere((x) => x.id == t.id));
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlayerPage()));
            }, icon: Ic.play),
          ]),
        ),
      ),
    ]);
  }
}
