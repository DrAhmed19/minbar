import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'analysis.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

const kVizNames = ['المحراب', 'حلقة الأعمدة', 'هالة', 'نبض', 'أعمدة الطيف', 'موجة دائرية', 'خط الصوت'];
const kBgNames = ['من الغلاف', 'أسود فاخر', 'كحلي', 'أخضر', 'عنابي', 'بنفسجي', 'بني', 'فيروزي', 'فحمي'];
const kBgColors = [null, Color(0xFF000000), Color(0xFF0D1B2A), Color(0xFF0C4A39), Color(0xFF4A0F1A), Color(0xFF2B1640), Color(0xFF3A2414), Color(0xFF0F3B44), Color(0xFF1E2329)];
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
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(children: [
                  _box(Ic.down, () => Navigator.pop(context)),
                  Expanded(child: Center(child: Text('${pc.index + 1} من ${pc.queue.length}', style: tx(15, c: Colors.white60)))),
                  _box(fav ? Ic.heartF : Ic.heart, () {
                    app.repo.toggleFav(t.id);
                    setState(() {});
                  }),
                  const SizedBox(width: 8),
                  _box(Ic.chat, () => snack2('التعليقات في التحديث القادم')),
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

  void snack2(String m) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: tx(13, c: Colors.white)), duration: const Duration(seconds: 2)));
  }

  Widget _box(String ic, VoidCallback f, {double size = 52, Color? color}) => GestureDetector(
        onTap: f,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0x14FFFFFF), border: Border.all(color: const Color(0x73E8C468), width: 1.3)),
          child: Center(child: PIcon(ic, color: color ?? kGold, size: 24)),
        ),
      );

  Widget _stage(Track t) {
    final pc = app.player;
    Widget st = Column(children: [
      Expanded(
        flex: 5,
        child: LayoutBuilder(builder: (_, c) {
          if (pc.viz == 0) {
            var ah = c.maxHeight * 0.92;
            var aw = math.min(ah / 1.42, c.maxWidth * 0.62);
            ah = math.min(ah, aw * 1.42);
            final cs = aw * 0.68;
            return Center(
              child: SizedBox(
                width: aw + 24,
                height: ah + 24,
                child: Stack(alignment: Alignment.topCenter, children: [
                  Positioned.fill(child: CustomPaint(painter: MihrabPainter())),
                  Positioned(
                    top: ah * 0.28,
                    child: Container(
                      width: cs,
                      height: cs,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(cs * 0.1), border: Border.all(color: kGold.withOpacity(0.75), width: 1.6), boxShadow: [BoxShadow(color: kGold.withOpacity(0.18), blurRadius: 26), BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 10))]),
                      child: ClipRRect(borderRadius: BorderRadius.circular(cs * 0.1 - 1), child: Cover(t.coverUrl, size: cs - 3, radius: 0)),
                    ),
                  ),
                ]),
              ),
            );
          }
          final box = math.min(c.maxWidth, c.maxHeight);
          final r = (box * 0.27).clamp(60.0, 150.0);
          return Stack(alignment: Alignment.center, children: [
            Positioned.fill(child: VizLayer(an: an, mode: pc.viz - 1, coverR: r)),
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
                    ? Center(child: Text('لا تتوفر كلمات لهذه القصيدة', style: tx(13, c: Colors.white38)))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(line(i - 1), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: lyricStyle(size: 15, color: const Color(0x80C8B08A), w: FontWeight.w500)),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(i < 0 ? '♪' : line(i), key: ValueKey(i), textAlign: TextAlign.center, maxLines: 3, style: lyricStyle())),
                        ),
                        Text(line(i + 1), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: lyricStyle(size: 18, color: const Color(0x80C8B08A), w: FontWeight.w500)),
                      ]),
              ),
            );
          },
        ),
      ),
    ]);
    if (pc.layout == 1) {
      st = Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: const Color(0x0DFFFFFF), border: Border.all(color: const Color(0x1FFFFFFF))),
        child: st,
      );
    }
    return st;
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
            child: GoldPill('مظهر الكلمات', Ic.text, _lyStyleSheet),
          ),
        ),
      ]);

  Widget _bottom(Track t) {
    final pc = app.player;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _box(Ic.moon, _sleepSheet, size: 54, color: pc.sleepAt != null ? kGold2 : kGold),
          Expanded(
            child: Column(children: [
              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: lyricStyle(size: 24, color: Colors.white)),
              Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: tx(17, c: const Color(0xFFE8C468))),
            ]),
          ),
          _box(Ic.more, _settingsSheet, size: 54),
        ]),
        const SizedBox(height: 6),
        StreamBuilder<Duration>(
          stream: pc.p.positionStream,
          builder: (_, s) => StreamBuilder<Duration?>(
            stream: pc.p.durationStream,
            builder: (_, d) {
              final dur = (d.data?.inMilliseconds ?? 0) / 1000.0;
              final pos = ((s.data?.inMilliseconds ?? 0) / 1000.0).clamp(0.0, dur > 0 ? dur : 1.0);
              return Column(children: [
                SizedBox(
                  height: 44,
                  child: WaveBar(env: env, progress: dur > 0 ? pos / dur : 0, onSeek: (f) {
                    if (dur > 0) pc.seek(f * dur);
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(fmt(pos), style: tx(14, c: Colors.white60)),
                    Text(fmt(dur), style: tx(14, c: Colors.white60)),
                  ]),
                ),
              ]);
            },
          ),
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(onPressed: pc.prev, icon: const PIcon(Ic.prev, color: kGold, size: 40)),
            StreamBuilder<PlayerState>(
              stream: pc.p.playerStateStream,
              builder: (_, s) {
                final st = s.data;
                final busy = st != null && st.playing && (st.processingState == ProcessingState.loading || st.processingState == ProcessingState.buffering);
                return GestureDetector(
                  onTap: pc.toggle,
                  child: Container(
                    width: 94,
                    height: 94,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(46), topRight: Radius.circular(46), bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
                      gradient: const LinearGradient(colors: [kGold2, kGold], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: kGold.withOpacity(0.35), blurRadius: 26)],
                    ),
                    child: busy
                        ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(strokeWidth: 3.5, color: Color(0xFF3A2D08)))
                        : Center(child: PIcon((st?.playing ?? false) ? Ic.pause : Ic.play, size: 44, color: const Color(0xFF2A2106))),
                  ),
                );
              },
            ),
            IconButton(onPressed: pc.next, icon: const PIcon(Ic.next, color: kGold, size: 40)),
          ]),
        ),
      ]),
    );
  }

  Widget _dock() {
    final pc = app.player;
    Widget b(String ic, String s, bool on, VoidCallback f, {bool act = false}) => Expanded(
          child: GestureDetector(
            onTap: f,
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: act ? const Color(0x14FFFFFF) : Colors.transparent),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                PIcon(ic, color: on ? kGold : const Color(0xB3E8C468), size: 26),
                const SizedBox(height: 3),
                Text(s, style: tx(13, c: on ? kGold : const Color(0xB3E8C468))),
              ]),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: const BoxDecoration(color: Color(0xF2171210), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Row(children: [
        b(Ic.rep, 'تكرار', pc.loop != LoopMode.off, pc.cycleLoop),
        b(Ic.text, 'الكلمات', lyView, () => setState(() => lyView = true), act: lyView),
        b(Ic.eq, 'الصوت', !lyView, () => setState(() => lyView = false), act: !lyView),
        b(Ic.plist, 'القائمة', false, _queueSheet),
        b(Ic.shuf, 'عشوائي', pc.shuffle, pc.toggleShuffle),
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

  Widget _sc2(String ic, String title, Widget child, {String? chip}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: const Color(0x0FFFFFFF), border: Border.all(color: const Color(0x2EE8C468))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x1FE8C468)), child: Center(child: PIcon(ic, color: kGold, size: 21))),
            const SizedBox(width: 10),
            Text(title, style: tx(16, c: Colors.white)),
            const Spacer(),
            if (chip != null) Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x14FFFFFF)), child: Text(chip, style: tx(13, c: kGold))),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _tile(String ic, String t, String sub, VoidCallback f, {bool neu = false}) => GestureDetector(
        onTap: f,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x0FFFFFFF), border: Border.all(color: const Color(0x24FFFFFF))),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: const Color(0x24E8C468)), child: Center(child: PIcon(ic, color: kGold, size: 22))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14.5, c: Colors.white)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: Colors.white54)),
              ])),
            ]),
          ),
          if (neu) Positioned(top: -8, right: 18, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: kGold), child: Text('جديد', style: tx(10.5, c: const Color(0xFF2A2106))))),
        ]),
      );

  void _settingsSheet() {
    final pc = app.player;
    final t = pc.cur!;
    _sheet((c, ss) {
      void u(VoidCallback f) {
        f();
        ss(() {});
        setState(() {});
      }

      void soon() => snack2('هذه الأداة في التحديث القادم');
      final spd = [0.75, 1.0, 1.25, 1.5, 2.0];
      return SizedBox(
        height: MediaQuery.of(c).size.height * 0.88,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 54, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 10),
            Row(children: [
              _box(Ic.x, () => Navigator.pop(c), size: 46, color: Colors.white),
              const SizedBox(width: 12),
              Text('إعدادات العرض والتشغيل', style: tx(19, c: Colors.white)),
            ].reversed.toList()),
            const SizedBox(height: 14),
            _sc2(Ic.eq, 'قوالب العرض', chip: kVizNames[pc.viz % kVizNames.length], SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kVizNames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => u(() => pc.setPref('viz', i)),
                  child: Container(
                    width: 86,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const RadialGradient(colors: [Color(0xFF14664F), Color(0xFF073D2E)]), border: Border.all(color: pc.viz == i ? kGold : Colors.transparent, width: 2.2)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: i == 0
                          ? CustomPaint(painter: MihrabPainter(mini: true), child: Center(child: Padding(padding: const EdgeInsets.only(top: 6), child: Cover(t.coverUrl, size: 28, radius: 4))))
                          : Stack(alignment: Alignment.center, children: [
                              CustomPaint(size: const Size(86, 86), painter: VizPainter(List.filled(22, 0.55), i - 1, 17, 0)),
                              ClipOval(child: Cover(t.coverUrl, size: 34, radius: 17)),
                            ]),
                    ),
                  ),
                ),
              ),
            )),
            _sc2(Ic.lay, 'ترتيب الواجهة', Row(children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => u(() {
                      pc.setPref('layout', i);
                      lyView = i == 2;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: pc.layout == i ? const Color(0x2EE8C468) : const Color(0x14FFFFFF), border: Border.all(color: pc.layout == i ? kGold : const Color(0x24FFFFFF), width: pc.layout == i ? 2 : 1.2)),
                      child: Column(children: [
                        Container(width: 38, height: 54, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: pc.layout == i ? kGold.withOpacity(0.55) : Colors.white24), child: Icon(i == 2 ? Icons.notes : (i == 1 ? Icons.crop_square : Icons.circle), size: 16, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(['غامر', 'كلاسيكي', 'الكلمات أولاً'][i], style: tx(14, c: pc.layout == i ? kGold : Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ],
            ])),
            _sc2(Ic.color, 'لون الخلفية', chip: kBgNames[pc.bg % kBgNames.length], SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kBgNames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => u(() => pc.setPref('bg', i)),
                  child: Column(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: kBgColors[i] ?? const Color(0xFF4A3426), border: Border.all(color: pc.bg == i ? kGold : Colors.white24, width: pc.bg == i ? 3 : 1)),
                      child: i == 0 ? const Center(child: PIcon(Ic.spark, color: Colors.white, size: 20)) : null,
                    ),
                    const SizedBox(height: 4),
                    Text(kBgNames[i], style: tx(12, c: pc.bg == i ? kGold : Colors.white70)),
                  ]),
                ),
              ),
            )),
            _sc2(Ic.spark, 'أدوات القصيدة', GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.45,
              children: [
                _tile(Ic.info, 'الإصدار $kBuild', 'اضغط للتحقق من التحديث', () async {
                  final n = await latestBuild();
                  if (!mounted) return;
                  if (n > kBuild) {
                    launchApk();
                  } else {
                    snack2('أنت على آخر نسخة');
                  }
                }),
                _tile(Ic.info, 'عن القصيدة', 'الرادود والتفاصيل', () {
                  showDialog(
                    context: context,
                    builder: (d) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        backgroundColor: const Color(0xFF1C1612),
                        title: Text(t.title, style: tx(18, c: Colors.white)),
                        content: Text([
                          if (t.reciter.isNotEmpty) 'الرادود: ${t.reciter}',
                          if (t.poet.isNotEmpty) 'الشاعر: ${t.poet}',
                          if (t.albumName.isNotEmpty) 'الإصدار: ${t.albumName}',
                          if (t.cat.isNotEmpty) 'التصنيف: ${t.cat}',
                        ].join('\n'), style: tx(14, c: Colors.white70, h: 1.9)),
                        actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text('إغلاق', style: tx(13, c: kGold)))],
                      ),
                    ),
                  );
                }),
                _tile(Ic.share, 'مشاركة اللحظة', 'من الدقيقة الحالية', () async {
                  final sec = pc.p.position.inSeconds;
                  await Clipboard.setData(ClipboardData(text: '${kBase}?p=${t.id}&t=$sec'));
                  snack2('نُسخ رابط اللحظة');
                }),
                _tile(Ic.flame, 'الذروة', 'لا إعجابات', soon),
                _tile(Ic.users, 'المجلس', 'استماع مشترك', soon, neu: true),
                _tile(Ic.text, 'وضع الحسينية', 'كلمات كبيرة للشاشة', soon),
                _tile(Ic.pulse, 'تحليل الصوت', 'كل القصائد محلّلة', soon),
                _tile(Ic.wave, 'وضع الأداء', 'أخفّ وأثبت بالتطبيق', soon),
                _tile(Ic.eq, 'الإحصائيات', 'الاستماعات والإعجابات', soon),
                _tile(Ic.pulse, 'وضع اللطم', 'اهتزاز مع الإيقاع', soon),
              ],
            )),
            _sc2(Ic.speed, 'سرعة التشغيل', Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x66000000)),
              child: Row(children: [
                for (final v in spd)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => u(() => pc.setSpeed(v)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: pc.speed == v ? kGold : Colors.transparent),
                        child: Center(child: Text('${v}x', style: tx(16, c: pc.speed == v ? const Color(0xFF2A2106) : Colors.white))),
                      ),
                    ),
                  ),
              ],
            ))),
            _sc2(Ic.text, 'تأخير الكلمات (للسماعات اللاسلكية)', _chips(5, [0.0, 0.2, 0.4, 0.6, 0.8].indexOf(pc.lyOffset), (i) => i == 0 ? 'بدون' : '${[0.0, 0.2, 0.4, 0.6, 0.8][i]} ث', (i) => u(() => pc.setLyOffset([0.0, 0.2, 0.4, 0.6, 0.8][i])))),
          ]),
        ),
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
                  IconButton(onPressed: pc.toggleShuffle, icon: PIcon(Ic.shuf, color: pc.shuffle ? kGold : Colors.white54)),
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
                      trailing: on ? const PIcon(Ic.eq, color: kGold) : IconButton(icon: const PIcon(Ic.x, color: Colors.white38, size: 20), onPressed: () => pc.removeAt(i)),
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


/// إطار المحراب الذهبي (قوس مزدوج + زخرفة سفلية)
class MihrabPainter extends CustomPainter {
  final bool mini;
  MihrabPainter({this.mini = false});

  Path _arch(double x0, double x1, double yt, double ys, double yb) {
    final cx = (x0 + x1) / 2, w = x1 - x0, h = yb - yt;
    return Path()
      ..moveTo(x0, yb)
      ..lineTo(x0, ys)
      ..cubicTo(x0, ys - h * 0.30, cx - w * 0.06, yt + h * 0.30, cx, yt)
      ..cubicTo(cx + w * 0.06, yt + h * 0.30, x1, ys - h * 0.30, x1, ys)
      ..lineTo(x1, yb);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final k = mini ? 0.55 : 1.0;
    final w = s.width, h = s.height;
    final px = mini ? w * 0.2 : 12.0, py = mini ? h * 0.12 : 12.0;
    final outer = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1 * k..color = kGold.withOpacity(0.32);
    final inner = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6 * k..strokeCap = StrokeCap.round..color = kGold.withOpacity(0.85);
    final gap = mini ? 3.0 : 14.0;
    canvas.drawPath(_arch(px - gap * 0.4, w - px + gap * 0.4, py - gap * 0.9, h * 0.52, h - py + 8), outer);
    canvas.drawPath(_arch(px + gap * 0.6, w - px - gap * 0.6, py + gap * 0.4, h * 0.5, h - py - 2), inner);
    if (!mini) {
      final z = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = kGold.withOpacity(0.6);
      final y = h - py - 18;
      final n = 22;
      final x0 = px + 30, x1 = w - px - 30, st = (x1 - x0) / n;
      for (var i = 0; i < n; i++) {
        final x = x0 + i * st;
        canvas.drawLine(Offset(x, y), Offset(x + st * 0.5, y + 5), z);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MihrabPainter o) => false;
}
