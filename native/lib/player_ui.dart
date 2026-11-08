import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'analysis.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

const kVizNames = ['حلقة الأعمدة', 'هالة', 'نبض', 'أعمدة الطيف', 'موجة دائرية', 'خط الصوت'];
const kBgNames = ['من الغلاف', 'أسود فاخر', 'كحلي', 'أخضر', 'عنابي', 'بنفسجي', 'بني', 'فيروزي'];
const kBgColors = [null, Color(0xFF000000), Color(0xFF0D1B2A), Color(0xFF0C4A39), Color(0xFF4A0F1A), Color(0xFF2B1640), Color(0xFF3A2414), Color(0xFF0F3B44)];
const kLyFonts = ['Amiri', 'Cairo', 'Tajawal', 'Aref Ruqaa', 'Reem Kufi', 'Lateef', 'El Messiri', 'Noto Naskh Arabic', 'Scheherazade New', 'Katibeh', 'Mirza', 'Rakkas', 'Lalezar', 'Noto Kufi Arabic'];
const kLyFontNames = ['أميري', 'كايرو', 'تجوال', 'عارف رقعة', 'ريم كوفي', 'لطيف', 'المسيري', 'نسخ', 'شهرزاد', 'كتيبة', 'ميرزا', 'رقاص', 'لالزار', 'كوفي'];
const kLyColors = [Color(0xFFF3EAD0), Color(0xFFF6DE8E), Color(0xFFFFFFFF), Color(0xFF7FE0B5), Color(0xFFF4B6B6), Color(0xFFBFD8FF)];

TextStyle lyricStyle({double? size, Color? color, FontWeight w = FontWeight.w700}) {
  final c = app.player;
  final base = TextStyle(fontSize: size ?? c.lySize, color: color ?? kLyColors[c.lyColor % kLyColors.length], fontWeight: w, height: 1.7);
  try {
    return GoogleFonts.getFont(kLyFonts[c.lyFont % kLyFonts.length], textStyle: base);
  } catch (_) {
    return GoogleFonts.cairo(textStyle: base);
  }
}

/// ========== المشغّل الكامل ==========
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  List<Lyric> ly = [];
  String lyFor = '';
  Analysis? an;
  List<double> env = const [];
  bool lyView = false;

  @override
  void initState() {
    super.initState();
    app.player.addListener(_r);
    _load();
  }

  void _r() {
    if (!mounted) return;
    setState(() {});
    _load();
  }

  Future<void> _load() async {
    final t = app.player.cur;
    if (t == null || lyFor == t.id) return;
    lyFor = t.id;
    ly = [];
    an = null;
    env = const [];
    Analysis.load(t.id).then((a) {
      if (mounted && app.player.cur?.id == t.id) {
        setState(() {
          an = a;
          env = a?.envelope(400) ?? const [];
        });
      }
    });
    final r = await app.repo.lyricsFor(t);
    if (mounted && app.player.cur?.id == t.id) setState(() => ly = r);
  }

  @override
  void dispose() {
    app.player.removeListener(_r);
    super.dispose();
  }

  int _idx(double pos) {
    var k = -1;
    final off = app.player.lyOffset;
    for (var i = 0; i < ly.length; i++) {
      if (ly[i].t <= pos + 0.15 - off) {
        k = i;
      } else {
        break;
      }
    }
    return k;
  }

  @override
  Widget build(BuildContext context) {
    final pc = app.player;
    final t = pc.cur;
    if (t == null) return const Scaffold(backgroundColor: kDeep);
    final fav = app.repo.isFav(t.id);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(child: _Background(t)),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 32)),
                  Expanded(child: Center(child: Text('${pc.index + 1} من ${pc.queue.length}', style: tx(12.5, c: Colors.white60, w: FontWeight.w600)))),
                  IconButton(
                    onPressed: () {
                      app.repo.toggleFav(t.id);
                      setState(() {});
                    },
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? const Color(0xFFE8776F) : Colors.white70),
                  ),
                ]),
              ),
              Expanded(child: lyView ? _lyricsView() : _stage(t)),
              _bottom(t),
              _dock(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stage(Track t) {
    final pc = app.player;
    return Column(children: [
      Expanded(
        flex: 5,
        child: LayoutBuilder(builder: (_, c) {
          final box = math.min(c.maxWidth, c.maxHeight);
          final r = (box * 0.27).clamp(60.0, 150.0);
          return Stack(alignment: Alignment.center, children: [
            Positioned.fill(child: VizLayer(an: an, mode: pc.viz, coverR: r)),
            Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kGold.withOpacity(0.7), width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24)]),
              child: ClipOval(child: Cover(t.coverUrl, size: r * 2 - 4, radius: 0)),
            ),
          ]);
        }),
      ),
      Expanded(
        flex: 3,
        child: StreamBuilder<Duration>(
          stream: pc.p.positionStream,
          builder: (_, s) {
            final pos = (s.data?.inMilliseconds ?? 0) / 1000.0;
            final i = _idx(pos);
            String line(int k) => k >= 0 && k < ly.length ? ly[k].l : '';
            return GestureDetector(
              onTap: ly.isEmpty ? null : () => setState(() => lyView = true),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ly.isEmpty
                    ? Center(child: Text('لا تتوفر كلمات لهذه القصيدة', style: tx(13, c: Colors.white38, w: FontWeight.w500)))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(line(i - 1), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: lyricStyle(size: 14, color: Colors.white38, w: FontWeight.w500)),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Text(i < 0 ? '♪' : line(i), key: ValueKey(i), textAlign: TextAlign.center, maxLines: 3, style: lyricStyle()),
                        ),
                        Text(line(i + 1), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: lyricStyle(size: 14, color: Colors.white38, w: FontWeight.w500)),
                      ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  final _sc = ScrollController();
  int _lastIdx = -2;

  Widget _lyricsView() => Stack(children: [
        StreamBuilder<Duration>(
          stream: app.player.p.positionStream,
          builder: (_, s) {
            final pos = (s.data?.inMilliseconds ?? 0) / 1000.0;
            final i = _idx(pos);
            final h = app.player.lySize * 3.4;
            if (i != _lastIdx && _sc.hasClients) {
              _lastIdx = i;
              final target = (i * h - 140).clamp(0.0, _sc.position.maxScrollExtent);
              _sc.animateTo(target, duration: const Duration(milliseconds: 380), curve: Curves.easeOut);
            }
            return ListView.builder(
              controller: _sc,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 80),
              itemCount: ly.length,
              itemExtent: h,
              itemBuilder: (_, k) {
                final on = k == i;
                return InkWell(
                  onTap: () => app.player.seek(ly[k].t + app.player.lyOffset),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: lyricStyle(size: on ? app.player.lySize : app.player.lySize * 0.78, color: on ? null : Colors.white38),
                      textAlign: TextAlign.center,
                      child: Text(ly[k].l, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Center(
            child: GoldPill('مظهر الكلمات', Icons.text_fields_rounded, _lyStyleSheet),
          ),
        ),
      ]);

  Widget _bottom(Track t) {
    final pc = app.player;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          IconButton(
            onPressed: _sleepSheet,
            icon: Icon(Icons.nightlight_round, color: pc.sleepAt != null ? kGold : Colors.white54, size: 22),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(19, w: FontWeight.w800, c: Colors.white)),
              Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12.5, c: Colors.white60, w: FontWeight.w500)),
            ]),
          ),
          IconButton(onPressed: _settingsSheet, icon: const Icon(Icons.more_vert, color: Colors.white70)),
        ]),
        StreamBuilder<Duration>(
          stream: pc.p.positionStream,
          builder: (_, s) => StreamBuilder<Duration?>(
            stream: pc.p.durationStream,
            builder: (_, d) {
              final dur = (d.data?.inMilliseconds ?? 0) / 1000.0;
              final pos = ((s.data?.inMilliseconds ?? 0) / 1000.0).clamp(0.0, dur > 0 ? dur : 1.0);
              return Column(children: [
                SizedBox(
                  height: 38,
                  child: WaveBar(env: env, progress: dur > 0 ? pos / dur : 0, onSeek: (f) {
                    if (dur > 0) pc.seek(f * dur);
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(fmt(pos), style: tx(11.5, c: Colors.white60, w: FontWeight.w500)),
                    Text(fmt(dur), style: tx(11.5, c: Colors.white60, w: FontWeight.w500)),
                  ]),
                ),
              ]);
            },
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(onPressed: () => pc.seek((pc.p.position.inMilliseconds / 1000.0 - 10).clamp(0.0, 1e9)), icon: const Icon(Icons.replay_10_rounded, color: Colors.white60, size: 26)),
            IconButton(onPressed: pc.prev, icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 38)),
            StreamBuilder<PlayerState>(
              stream: pc.p.playerStateStream,
              builder: (_, s) {
                final st = s.data;
                final busy = st != null && st.playing && (st.processingState == ProcessingState.loading || st.processingState == ProcessingState.buffering);
                return GestureDetector(
                  onTap: pc.toggle,
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kGold2, kGold], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: busy
                        ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF3A2D08)))
                        : Icon((st?.playing ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: const Color(0xFF3A2D08)),
                  ),
                );
              },
            ),
            IconButton(onPressed: pc.next, icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 38)),
            IconButton(onPressed: () => pc.seek(pc.p.position.inMilliseconds / 1000.0 + 10), icon: const Icon(Icons.forward_10_rounded, color: Colors.white60, size: 26)),
          ]),
        ),
      ]),
    );
  }

  Widget _dock() {
    final pc = app.player;
    Widget b(IconData ic, String s, bool on, VoidCallback f) => Expanded(
          child: InkWell(
            onTap: f,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(ic, color: on ? kGold : Colors.white60, size: 23),
                const SizedBox(height: 2),
                Text(s, style: tx(10.5, c: on ? kGold : Colors.white54, w: FontWeight.w600)),
              ]),
            ),
          ),
        );
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x14FFFFFF)))),
      child: Row(children: [
        b(pc.loop == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded, 'تكرار', pc.loop != LoopMode.off, pc.cycleLoop),
        b(Icons.text_fields_rounded, 'الكلمات', lyView, () => setState(() => lyView = true)),
        b(Icons.graphic_eq_rounded, 'الصوت', !lyView, () => setState(() => lyView = false)),
        b(Icons.queue_music_rounded, 'القائمة', false, _queueSheet),
        b(Icons.shuffle_rounded, 'عشوائي', pc.shuffle, pc.toggleShuffle),
      ]),
    );
  }

  // ---------- الأوراق ----------
  Future<void> _sheet(Widget Function(BuildContext, StateSetter) b, {double h = 0.0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16100B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(builder: (c2, ss) => SafeArea(child: b(c2, ss))),
      ),
    );
  }

  Widget _h(String s) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(s, style: tx(13.5, c: Colors.white70, w: FontWeight.w700)));

  Widget _chips(int n, int sel, String Function(int) name, void Function(int) on) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < n; i++)
          ChoiceChip(
            label: Text(name(i), style: tx(12.5, c: sel == i ? const Color(0xFF3A2D08) : Colors.white)),
            selected: sel == i,
            selectedColor: kGold,
            backgroundColor: Colors.white12,
            showCheckmark: false,
            side: BorderSide.none,
            onSelected: (_) => on(i),
          ),
      ]);

  void _settingsSheet() {
    final pc = app.player;
    _sheet((c, ss) {
      void u(VoidCallback f) {
        f();
        ss(() {});
        setState(() {});
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          _h('قوالب العرض'),
          _chips(kVizNames.length, pc.viz, (i) => kVizNames[i], (i) => u(() => pc.setPref('viz', i))),
          _h('لون الخلفية'),
          _chips(kBgNames.length, pc.bg, (i) => kBgNames[i], (i) => u(() => pc.setPref('bg', i))),
          _h('سرعة التشغيل'),
          _chips(5, [0.75, 1.0, 1.25, 1.5, 2.0].indexOf(pc.speed), (i) => '${[0.75, 1.0, 1.25, 1.5, 2.0][i]}x', (i) => u(() => pc.setSpeed([0.75, 1.0, 1.25, 1.5, 2.0][i]))),
          _h('تأخير الكلمات (للسماعات اللاسلكية)'),
          _chips(5, [0.0, 0.2, 0.4, 0.6, 0.8].indexOf(pc.lyOffset), (i) => i == 0 ? 'بدون' : '${[0.0, 0.2, 0.4, 0.6, 0.8][i]} ث', (i) => u(() => pc.setLyOffset([0.0, 0.2, 0.4, 0.6, 0.8][i]))),
        ]),
      );
    });
  }

  void _lyStyleSheet() {
    final pc = app.player;
    _sheet((c, ss) {
      void u(VoidCallback f) {
        f();
        ss(() {});
        setState(() {});
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Center(child: Text('بسم الله الرحمن الرحيم', style: lyricStyle())),
          _h('الخط'),
          _chips(kLyFonts.length, pc.lyFont, (i) => kLyFontNames[i], (i) => u(() => pc.setPref('lyFont', i))),
          _h('اللون'),
          Wrap(spacing: 12, children: [
            for (var i = 0; i < kLyColors.length; i++)
              GestureDetector(
                onTap: () => u(() => pc.setPref('lyColor', i)),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: kLyColors[i], shape: BoxShape.circle, border: Border.all(color: pc.lyColor == i ? kGold : Colors.white24, width: pc.lyColor == i ? 3 : 1)),
                ),
              ),
          ]),
          _h('الحجم'),
          SliderTheme(
            data: SliderTheme.of(c).copyWith(activeTrackColor: kGold, inactiveTrackColor: Colors.white24, thumbColor: kGold2),
            child: Slider(value: pc.lySize.clamp(16.0, 40.0), min: 16, max: 40, onChanged: (v) => u(() => pc.setPref('lySize', v))),
          ),
        ]),
      );
    });
  }

  void _sleepSheet() {
    final pc = app.player;
    _sheet((c, ss) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            _h(pc.sleepAt == null ? 'مؤقت الإيقاف' : 'مؤقت الإيقاف (فعّال)'),
            _chips(5, -1, (i) => ['إيقاف', '10 د', '15 د', '30 د', '60 د'][i], (i) {
              pc.setSleep([0, 10, 15, 30, 60][i]);
              Navigator.pop(c);
              setState(() {});
            }),
          ]),
        ));
  }

  void _queueSheet() {
    final pc = app.player;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16100B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (c2, sc) => ListenableBuilder(
            listenable: pc,
            builder: (_, __) => Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Row(children: [
                  Expanded(child: Text('قائمة التشغيل · ${pc.queue.length}', style: tx(15.5, w: FontWeight.w800, c: Colors.white))),
                  IconButton(onPressed: pc.toggleShuffle, icon: Icon(Icons.shuffle_rounded, color: pc.shuffle ? kGold : Colors.white54)),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  itemCount: pc.queue.length,
                  itemBuilder: (_, i) {
                    final q = pc.queue[i];
                    final on = i == pc.index;
                    return ListTile(
                      onTap: () => pc.jump(i),
                      leading: Cover(q.coverUrl, size: 44, radius: 10),
                      title: Text(q.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14, w: FontWeight.w800, c: on ? kGold : Colors.white)),
                      subtitle: Text(q.reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: Colors.white54, w: FontWeight.w500)),
                      trailing: on ? const Icon(Icons.graphic_eq, color: kGold) : IconButton(icon: const Icon(Icons.close, color: Colors.white38, size: 20), onPressed: () => pc.removeAt(i)),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// خلفية: غلاف مموّه أو لون ثابت، مع تدرّج داكن لقراءة النص
class _Background extends StatelessWidget {
  final Track t;
  const _Background(this.t);

  @override
  Widget build(BuildContext context) {
    final pc = app.player;
    final solid = kBgColors[pc.bg % kBgColors.length];
    return Stack(fit: StackFit.expand, children: [
      if (solid == null && t.coverUrl.isNotEmpty)
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 38, sigmaY: 38),
          child: CachedNetworkImage(imageUrl: t.coverUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => const SizedBox()),
        ),
      Container(color: solid ?? const Color(0xFF1C140E).withOpacity(0.55)),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.25), Colors.black.withOpacity(0.35), Colors.black.withOpacity(0.78)]),
        ),
      ),
    ]);
  }
}

/// شريط التقدّم بشكل موجة الصوت الحقيقية (من التحليل المحسوب مسبقاً)
class WaveBar extends StatelessWidget {
  final List<double> env;
  final double progress;
  final void Function(double) onSeek;
  const WaveBar({super.key, required this.env, required this.progress, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(builder: (_, c) {
        double f(Offset o) => (o.dx / c.maxWidth).clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onSeek(f(d.localPosition)),
          onHorizontalDragUpdate: (d) => onSeek(f(d.localPosition)),
          child: CustomPaint(size: Size(c.maxWidth, c.maxHeight), painter: _WavePainter(env, progress)),
        );
      }),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> env;
  final double p;
  _WavePainter(this.env, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    const bw = 2.4, step = 5.0;
    final n = (size.width / step).floor();
    final on = Paint()..color = kGold;
    final off = Paint()..color = Colors.white24;
    final mid = size.height / 2;
    for (var i = 0; i < n; i++) {
      final f = i / n;
      final e = env.isEmpty ? 0.25 + 0.2 * math.sin(i * 0.7).abs() : env[(f * (env.length - 1)).round()];
      final h = 3 + e * (size.height - 6);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(i * step, mid - h / 2, bw, h), const Radius.circular(1.2));
      canvas.drawRRect(r, f <= p ? on : off);
    }
    final x = (p * size.width).clamp(0.0, size.width);
    canvas.drawCircle(Offset(x, mid), 5, Paint()..color = kGold2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter o) => o.p != p || o.env != env;
}

/// طبقة المرئيات: تقرأ الموضع من المشغّل وتأخذ النطاقات من التحليل المحسوب مسبقاً
class VizLayer extends StatefulWidget {
  final Analysis? an;
  final int mode;
  final double coverR;
  const VizLayer({super.key, required this.an, required this.mode, required this.coverR});
  @override
  State<VizLayer> createState() => _VizLayerState();
}

class _VizLayerState extends State<VizLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  final List<double> _raw = List.filled(22, 0.0), _sm = List.filled(22, 0.0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final pl = app.player.p;
          if (pl.playing && widget.an != null) {
            widget.an!.bandsAt(pl.position.inMilliseconds / 1000.0, _raw);
          } else if (pl.playing) {
            final t = _c.value * 40;
            for (var k = 0; k < 22; k++) {
              _raw[k] = 0.25 + 0.2 * math.sin(t + k * 0.6).abs();
            }
          } else {
            for (var k = 0; k < 22; k++) {
              _raw[k] = 0.0;
            }
          }
          for (var k = 0; k < 22; k++) {
            final t = _raw[k];
            _sm[k] += (t - _sm[k]) * (t > _sm[k] ? 0.55 : 0.14);
          }
          return CustomPaint(painter: VizPainter(List<double>.from(_sm), widget.mode, widget.coverR, _c.value));
        },
      ),
    );
  }
}

class VizPainter extends CustomPainter {
  final List<double> v;
  final int mode;
  final double R, t;
  VizPainter(this.v, this.mode, this.R, this.t);

  double _at(double q) {
    final f = (q * 21).clamp(0.0, 21.0);
    final a = f.floor(), b = math.min(21, a + 1);
    return v[a] + (v[b] - v[a]) * (f - a);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final bass = (v[0] + v[1] + v[2] + v[3]) / 4;
    final gold = Paint()
      ..color = kGold
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    switch (mode) {
      case 0: { // حلقة الأعمدة
        const n = 72;
        gold.strokeWidth = 3.2;
        for (var i = 0; i < n; i++) {
          final p = i / n, q = p < 0.5 ? p * 2 : (1 - p) * 2;
          final a = p * math.pi * 2 - math.pi / 2, len = 4 + _at(q) * R * 0.38;
          final r0 = R + 10;
          canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * r0, c + Offset(math.cos(a), math.sin(a)) * (r0 + len), gold..color = kGold.withOpacity(0.55 + 0.45 * _at(q)));
        }
        break;
      }
      case 1: { // هالة
        for (var k = 0; k < 4; k++) {
          final rr = R + 14 + k * (R * 0.16) + bass * R * 0.25;
          canvas.drawCircle(c, rr, Paint()..shader = RadialGradient(colors: [kGold.withOpacity(0.0), kGold.withOpacity((0.22 - k * 0.04) * (0.4 + bass))], stops: const [0.7, 1.0]).createShader(Rect.fromCircle(center: c, radius: rr)));
        }
        canvas.drawCircle(c, R + 8, gold..strokeWidth = 2..color = kGold.withOpacity(0.4 + bass * 0.5));
        break;
      }
      case 2: { // نبض
        for (var k = 0; k < 3; k++) {
          final ph = (t * 8 + k / 3) % 1.0;
          canvas.drawCircle(c, R + 6 + ph * R * 0.8, gold..strokeWidth = 2..color = kGold.withOpacity((1 - ph) * (0.15 + bass * 0.7)));
        }
        break;
      }
      case 4: { // موجة دائرية
        final path = Path();
        const n = 96;
        for (var i = 0; i <= n; i++) {
          final p = i / n, q = p < 0.5 ? p * 2 : (1 - p) * 2;
          final a = p * math.pi * 2 - math.pi / 2, r = R + 12 + _at(q) * R * 0.3 + math.sin(p * 40 + t * 60) * 2 * bass;
          final o = c + Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        path.close();
        canvas.drawPath(path, gold..strokeWidth = 2.6..color = kGold);
        canvas.drawPath(path, Paint()..color = kGold.withOpacity(0.08 + bass * 0.12));
        break;
      }
      case 5: { // خط الصوت
        final path = Path();
        const n = 80;
        final w = size.width * 0.86, y = size.height - 18;
        for (var i = 0; i <= n; i++) {
          final q = i / n, amp = _at(q) * 34 * math.sin(q * math.pi);
          final o = Offset(size.width * 0.07 + q * w, y - amp * math.sin(q * 30 + t * 90).abs());
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(path, gold..strokeWidth = 2.6..color = kGold);
        break;
      }
      default: // أعمدة الطيف (أسفل المسرح)
        const n = 22;
        final gap = 4.0, bw = (size.width * 0.8 - gap * (n - 1)) / n, x0 = size.width * 0.1, base = size.height - 6;
        final fill = Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFC8963A), kGold2]).createShader(Rect.fromLTWH(0, base - 80, size.width, 80));
        for (var i = 0; i < n; i++) {
          final h = 3 + v[i] * 60;
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x0 + i * (bw + gap), base - h, bw, h), Radius.circular(bw / 2)), fill);
        }
    }
  }

  @override
  bool shouldRepaint(covariant VizPainter o) => true;
}
