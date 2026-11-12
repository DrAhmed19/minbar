import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
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

  Widget _sb(String ic, String label, VoidCallback f, {Color c = Colors.white}) => GestureDetector(
        onTap: f,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(width: 48, height: 48, color: const Color(0x47000000), alignment: Alignment.center, child: PIcon(ic, color: c, size: 24)),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: tx(11, c: Colors.white, w: FontWeight.w600).copyWith(shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)])),
          ]),
        ),
      );

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
    final fav = r.isFav(t.id), off = r.offline.contains(t.id);
    final sub = [t.reciter, t.poet].where((x) => x.trim().isNotEmpty).join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: on ? app.player.toggle : null,
      child: Stack(fit: StackFit.expand, children: [
        Cover(t.coverUrl, size: 900, radius: 0),
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99000000), Color(0xCC000000), Color(0xF2000000)]))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 24),
            child: Column(children: [
              // شريط تقدم المقطع بالأعلى (مثل الويب)
              ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: prog, minHeight: 3, backgroundColor: Colors.white24, color: Colors.white)),
              const Spacer(),
              Cover(t.coverUrl, size: 170, radius: 24),
              const SizedBox(height: 18),
              Text(t.title, textAlign: TextAlign.center, maxLines: 2, style: tx(24, c: Colors.white, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(sub, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14, c: kGold, w: FontWeight.w700)),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.only(right: 56),
                child: SizedBox(
                  height: 96,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        on && ci >= 0 ? ly[ci].l : (on ? '♪' : ''),
                        key: ValueKey('${t.id}$ci'),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: tx(22, c: Colors.white, w: FontWeight.w700, h: 1.7).copyWith(shadows: const [Shadow(color: Color(0xB3000000), blurRadius: 14, offset: Offset(0, 2))]),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
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
        // أزرار جانبية دائرية زجاجية (مثل الويب) + زر الخيارات
        Positioned(
          right: 10,
          bottom: 120,
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _sb(fav ? Ic.heartF : Ic.heart, 'أعجبني', () {
                setState(() => r.toggleFav(t.id));
                if (!fav) snack(context, 'أُضيفت للمفضلة');
              }, c: fav ? const Color(0xFFFF4D6D) : Colors.white),
              _sb(off ? Ic.check : Ic.down, off ? 'منزّلة' : 'تنزيل', () async {
                if (off) return snack(context, 'منزّلة مسبقاً — تعمل بدون إنترنت');
                snack(context, 'جارٍ تنزيل «${t.title}»…');
                final ok = await r.offSave(t, (_) {});
                if (mounted) {
                  setState(() {});
                  snack(context, ok ? 'نُزّلت — تعمل بدون إنترنت' : 'تعذّر التنزيل');
                }
              }),
              _sb(Ic.share, 'مشاركة', () => shareTrack(context, t, at: segStart.round())),
              _sb(Ic.more, 'خيارات', () => trackSheet(context, t)),
            ]),
          ),
        ),
        // زر التشغيل وسط الشاشة عند الإيقاف
        if (on)
          IgnorePointer(
            child: StreamBuilder<bool>(
              stream: app.player.p.playingStream,
              builder: (_, s) => AnimatedOpacity(
                opacity: (s.data ?? true) ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x66000000)),
                    child: const Center(child: PIcon(Ic.play, color: Colors.white, size: 36)),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
