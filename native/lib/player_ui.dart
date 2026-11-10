import 'dart:async';
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
import 'viz.dart';
import 'lyrics.dart';
import 'audio.dart';
import 'social.dart';
import 'tools.dart';

Color kA = const Color(0xFFE8C468), kA2 = const Color(0xFFF3D88A);

const kLyFonts = ['Amiri', 'Cairo', 'Tajawal', 'Aref Ruqaa', 'Reem Kufi', 'Lateef', 'El Messiri', 'Noto Naskh Arabic', 'Scheherazade New', 'Katibeh', 'Mirza', 'Rakkas', 'Lalezar', 'Noto Kufi Arabic'];
const kLyFontNames = ['أميري', 'كايرو', 'تجوال', 'عارف رقعة', 'ريم كوفي', 'لطيف', 'المسيري', 'نسخ', 'شهرزاد', 'كتيبة', 'ميرزا', 'رقاص', 'لالزار', 'كوفي'];
const kLyColors = [Color(0xFFF3EAD0), Color(0xFFF6DE8E), Color(0xFFFFFFFF), Color(0xFF7FE0B5), Color(0xFFF4B6B6), Color(0xFFBFD8FF)];

TextStyle lyricStyle({double? size, Color? color, FontWeight w = FontWeight.w700}) => TextStyle(fontFamily: 'F2', fontFamilyFallback: const ['F0'], fontSize: size ?? 22, color: color ?? const Color(0xFFF3D88A), fontWeight: w, height: 1.5);

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
  List<double> env = [];
  bool lyView = false;
  ui.Image? img;
  ({double h, double s, bool mono})? hue;

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
    env = [];
    img = null;
    hue = null;
    social.start();
    social.load(t);
    coverImage(t.coverUrl, file: app.repo.offDir.isEmpty ? null : '${app.repo.offDir}/${t.id}.cover').then((im) async {
      if (im == null || !mounted || app.player.cur?.id != t.id) return;
      final h = await coverHue(t.coverUrl, im);
      if (mounted && app.player.cur?.id == t.id) {
        setState(() {
          img = im;
          hue = h;
        });
      }
    });
    Analysis.load(t.id).then((a) {
      if (mounted && app.player.cur?.id == t.id) {
        setState(() {
          an = a;
          curAn = a;
          env = a?.envelope(400) ?? [];
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
    if (t == null) return Scaffold(backgroundColor: kDeep);
    final fav = app.repo.isFav(t.id);
    final th = themeOf(pc.viz);
    kA = bgPal(pc.bg, th, hue).a ?? th.a;
    kA2 = th.a2;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(child: _Background(t, hue)),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(children: [
                  _box(Ic.down, () => Navigator.pop(context)),
                  Expanded(child: Center(child: Text('${pc.index + 1} من ${pc.queue.length}', style: tx(15, c: Colors.white60)))),
                  _box(fav ? Ic.heartF : Ic.heart, () {
                    app.repo.toggleFav(t.id);
                    setState(() {});
                  }),
                  SizedBox(width: 8),
                  _box(Ic.chat, () => showCommentsSheet(context)),
                ]),
              ),
              Expanded(
                child: Stack(children: [
                  Positioned.fill(child: lyView ? _lyricsView() : _stage(t)),
                  const Positioned.fill(child: CmLayer()),
                  const Positioned(right: 4, bottom: 0, child: RxLayer()),
                ]),
              ),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: tx(13, c: Colors.white)), duration: Duration(seconds: 2)));
  }

  Widget _box(String ic, VoidCallback f, {double size = 52, Color? color}) => GestureDetector(
        onTap: f,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Color(0x14FFFFFF), border: Border.all(color: Color(0x73E8C468), width: 1.3)),
          child: Center(child: PIcon(ic, color: color ?? kA, size: 24)),
        ),
      );

  Widget _stage(Track t) {
    final pc = app.player;
    Widget st = Column(children: [
      Expanded(
        flex: 5,
        child: VizStage(an: an, img: img, viz: pc.viz, env: env),
      ),
      Expanded(
        flex: 3,
        child: LyricStrip(lines: ly, base: 22, onLong: () => showLyricsSheet(context, ly)),
      ),
    ]);
    if (pc.layout == 1) {
      st = Container(
        margin: EdgeInsets.fromLTRB(14, 6, 14, 0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Color(0x0DFFFFFF), border: Border.all(color: Color(0x1FFFFFFF))),
        child: st,
      );
    }
    return st;
  }

  final _sc = ScrollController();
  int _lastIdx = -2;

  Widget _lyricsView() => LyricStrip(lines: ly, base: 27, onLong: () => showLyricsSheet(context, ly));

  Widget _bottom(Track t) {
    final pc = app.player;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 6, 18, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _box(Ic.moon, _sleepSheet, size: 54, color: pc.sleepAt != null ? kA2 : kA),
          Expanded(
            child: Column(children: [
              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontFamily: thx(pc.viz).font, fontFamilyFallback: const ['F0'], fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700, height: 1.4)),
              Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: tx(17, c: Color(0xFFE8C468))),
            ]),
          ),
          _box(Ic.more, _settingsSheet, size: 54),
        ]),
        SizedBox(height: 6),
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
                ProgLine(pg: thx(pc.viz).pg, p: dur > 0 ? pos / dur : 0, onSeek: (f) {
                  if (dur > 0) pc.seek(f * dur);
                }),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Row(textDirection: TextDirection.ltr, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(fmt(pos), style: tx(14, c: Colors.white60)),
                    Text(fmt(dur), style: tx(14, c: Colors.white60)),
                  ]),
                ),
              ]);
            },
          ),
        ),
        SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            HoldSeek(dir: -1, onTap: pc.prev, child: PIcon(Ic.prev, color: thx(pc.viz).btn == 'ring' ? kA : kA, size: 40)),
            StreamBuilder<PlayerState>(
              stream: pc.p.playerStateStream,
              builder: (_, s) {
                final st = s.data;
                final busy = st != null && st.playing && (st.processingState == ProcessingState.loading || st.processingState == ProcessingState.buffering);
                final x = thx(pc.viz), playing = st?.playing ?? false;
                BoxDecoration dec;
                var icol = const Color(0xFF2A2106);
                switch (x.btn) {
                  case 'squ':
                    dec = BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(colors: [kA2, kA], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: kA.withOpacity(0.35), blurRadius: 26)]);
                  case 'disc':
                    dec = BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [kA2, kA, const Color(0xFF3B3226)], stops: const [0, 0.42, 1]), border: Border.all(color: const Color(0x40000000), width: 4), boxShadow: [BoxShadow(color: kA.withOpacity(0.35), blurRadius: 30)]);
                  case 'glass':
                    dec = BoxDecoration(shape: BoxShape.circle, color: const Color(0x24FFFFFF), border: Border.all(color: const Color(0x66FFFFFF)), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))]);
                    icol = Colors.white;
                  case 'ring':
                    dec = BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kA, width: 2), boxShadow: [BoxShadow(color: kA.withOpacity(playing ? 0.55 : 0.3), blurRadius: playing ? 30 : 18)]);
                    icol = kA;
                  case 'circle':
                    dec = BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kA2, kA], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: kA.withOpacity(0.35), blurRadius: 26)]);
                  default:
                    dec = BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(46), topRight: Radius.circular(46), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)), gradient: LinearGradient(colors: [kA2, kA], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: kA.withOpacity(0.35), blurRadius: 26)], border: playing ? Border.all(color: kA2.withOpacity(0.6), width: 1.5) : null);
                }
                return GestureDetector(
                  onTap: pc.toggle,
                  child: AnimatedScale(
                    scale: x.dock == 'metal' && !playing ? 0.94 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: dec,
                      child: busy
                          ? Padding(padding: const EdgeInsets.all(30), child: CircularProgressIndicator(strokeWidth: 3.5, color: icol))
                          : Center(child: PIcon(playing ? Ic.pause : Ic.play, size: 44, color: icol)),
                    ),
                  ),
                );
              },
            ),
            HoldSeek(dir: 1, onTap: pc.next, child: PIcon(Ic.next, color: kA, size: 40)),
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
              margin: EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: act ? Color(0x14FFFFFF) : Colors.transparent),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                PIcon(ic, color: on ? kA : Color(0xB3E8C468), size: 26),
                SizedBox(height: 3),
                Text(s, style: tx(13, c: on ? kA : Color(0xB3E8C468))),
              ]),
            ),
          ),
        );
    final dk = thx(pc.viz).dock;
    BoxDecoration dd;
    var mg = EdgeInsets.zero;
    switch (dk) {
      case 'metal':
        dd = const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3D4043), Color(0xFF1B1D1F)]), border: Border(top: BorderSide(color: Color(0x2EFFFFFF))));
      case 'outline':
        dd = BoxDecoration(border: Border(top: BorderSide(color: kA.withOpacity(0.45))), boxShadow: [BoxShadow(color: kA.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, -8))]);
      case 'float':
        dd = BoxDecoration(color: const Color(0x52000000), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0x24FFFFFF)));
        mg = const EdgeInsets.fromLTRB(14, 0, 14, 10);
      case 'bar':
        dd = BoxDecoration(color: const Color(0x59000000), border: Border(top: BorderSide(color: kA.withOpacity(0.45))));
      default:
        dd = const BoxDecoration(color: Color(0xF2171210), borderRadius: BorderRadius.vertical(top: Radius.circular(30)));
    }
    return Container(
      margin: mg,
      padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: dd,
      child: Row(children: [
        b(Ic.rep, 'تكرار', pc.loop != LoopMode.off, pc.cycleLoop),
        b(Ic.text, 'الكلمات', false, () => showLyricsSheet(context, ly)),
        b(Ic.eq, 'الصوت', false, () => showAudioSheet(context)),
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
      backgroundColor: Color(0xFF16100B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(builder: (c2, ss) => SafeArea(child: b(c2, ss))),
      ),
    );
  }

  Widget _h(String s) => Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child: Text(s, style: tx(13.5, c: Colors.white70, w: FontWeight.w700)));

  Widget _chips(int n, int sel, String Function(int) name, void Function(int) on) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < n; i++)
          GestureDetector(
            onTap: () => on(i),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: sel == i ? kA : Color(0x14FFFFFF),
                border: Border.all(color: sel == i ? kA : Color(0x26FFFFFF)),
              ),
              child: Text(name(i), style: tx(13.5, c: sel == i ? Color(0xFF2A2106) : Colors.white)),
            ),
          ),
      ]);

  Widget _sc2(String ic, String title, Widget child, {String? chip}) => Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Color(0x0FFFFFFF), border: Border.all(color: Color(0x2EE8C468))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0x1FE8C468)), child: Center(child: PIcon(ic, color: kA, size: 21))),
            SizedBox(width: 10),
            Text(title, style: tx(16, c: Colors.white)),
            Spacer(),
            if (chip != null) Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Color(0x14FFFFFF)), child: Text(chip, style: tx(13, c: kA))),
          ]),
          SizedBox(height: 12),
          child,
        ]),
      );

  Widget _tile(String ic, String t, String sub, VoidCallback f, {bool neu = false}) => GestureDetector(
        onTap: f,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Color(0x0FFFFFFF), border: Border.all(color: Color(0x24FFFFFF))),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: Color(0x24E8C468)), child: Center(child: PIcon(ic, color: kA, size: 22))),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14.5, c: Colors.white)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: Colors.white54)),
              ])),
            ]),
          ),
          if (neu) Positioned(top: -8, right: 18, child: Container(padding: EdgeInsets.symmetric(horizontal: 9, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: kA), child: Text('جديد', style: tx(10.5, c: Color(0xFF2A2106))))),
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
          padding: EdgeInsets.fromLTRB(14, 10, 14, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 54, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)))),
            SizedBox(height: 10),
            Row(children: [
              _box(Ic.x, () => Navigator.pop(c), size: 46, color: Colors.white),
              SizedBox(width: 12),
              Text('إعدادات العرض والتشغيل', style: tx(19, c: Colors.white)),
            ].reversed.toList()),
            SizedBox(height: 14),
            _sc2(Ic.eq, 'قوالب العرض', chip: kVizTitles[pc.viz % kVizTitles.length], SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kVizIds.length,
                separatorBuilder: (_, __) => SizedBox(width: 10),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => u(() => pc.setPref('viz', i)),
                  child: Container(
                    width: 86,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: RadialGradient(colors: [Color(0xFF14664F), Color(0xFF073D2E)]), border: Border.all(color: pc.viz == i ? kA : Colors.transparent, width: 2.2)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(18), child: IgnorePointer(child: VizStage(an: null, img: img, viz: i, still: true))),
                  ),
                ),
              ),
            )),
            _sc2(Ic.lay, 'ترتيب الواجهة', Row(children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => u(() {
                      pc.setPref('layout', i);
                      lyView = i == 2;
                    }),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: pc.layout == i ? Color(0x2EE8C468) : Color(0x14FFFFFF), border: Border.all(color: pc.layout == i ? kA : Color(0x24FFFFFF), width: pc.layout == i ? 2 : 1.2)),
                      child: Column(children: [
                        Container(width: 38, height: 54, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: pc.layout == i ? kA.withOpacity(0.55) : Colors.white24), child: Icon(i == 2 ? Icons.notes : (i == 1 ? Icons.crop_square : Icons.circle), size: 16, color: Colors.white70)),
                        SizedBox(height: 8),
                        Text(['غامر', 'كلاسيكي', 'الكلمات أولاً'][i], style: tx(14, c: pc.layout == i ? kA : Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ],
            ])),
            _sc2(Ic.color, 'لون الخلفية', chip: kBgTitles[pc.bg % kBgTitles.length], SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kBgKeys.length,
                separatorBuilder: (_, __) => SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final p = bgPal(i, themeOf(pc.viz), hue);
                  return GestureDetector(
                    onTap: () => u(() => pc.setPref('bg', i)),
                    child: Column(children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.b[0], p.b[2]]), border: Border.all(color: pc.bg == i ? kA : Colors.white24, width: pc.bg == i ? 3 : 1)),
                        child: i < 2 ? Center(child: PIcon(i == 0 ? Ic.spark : Ic.lay, color: Colors.white, size: 20)) : null,
                      ),
                      SizedBox(height: 4),
                      Text(kBgTitles[i], style: tx(12, c: pc.bg == i ? kA : Colors.white70)),
                    ]),
                  );
                },
              ),
            )),
            _sc2(Ic.spark, 'أدوات القصيدة', GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
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
                        backgroundColor: Color(0xFF1C1612),
                        title: Text(t.title, style: tx(18, c: Colors.white)),
                        content: Text([
                          if (t.reciter.isNotEmpty) 'الرادود: ${t.reciter}',
                          if (t.poet.isNotEmpty) 'الشاعر: ${t.poet}',
                          if (t.albumName.isNotEmpty) 'الإصدار: ${t.albumName}',
                          if (t.cat.isNotEmpty) 'التصنيف: ${t.cat}',
                        ].join('\n'), style: tx(14, c: Colors.white70, h: 1.9)),
                        actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text('إغلاق', style: tx(13, c: kA)))],
                      ),
                    ),
                  );
                }),
                _tile(Ic.share, 'مشاركة اللحظة', 'من الدقيقة الحالية', () async {
                  final sec = pc.p.position.inSeconds;
                  await Clipboard.setData(ClipboardData(text: '${kBase}?p=${t.id}&t=$sec'));
                  snack2('نُسخ رابط اللحظة');
                }),
                _tile(Ic.flame, 'الذروة', social.rx.isEmpty ? 'لا إعجابات' : 'أكثر لحظة إعجاباً', () {
                  final pk = social.peakT();
                  if (pk == null) return snack2('لا توجد إعجابات بعد');
                  Navigator.pop(c);
                  pc.seek(pk);
                  if (!pc.p.playing) pc.toggle();
                }),
                _tile(Ic.users, 'المجلس', majlis.on ? 'مفعّل · ${majlis.code}' : 'استماع مشترك', () {
                  Navigator.pop(c);
                  showMajlisSheet(context);
                }, neu: true),
                _tile(Ic.text, 'وضع الحسينية', 'كلمات كبيرة للشاشة', () {
                  Navigator.pop(c);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HusnPage(ly)));
                }),
                _tile(Ic.pulse, 'تحليل الصوت', 'كل القصائد محلّلة', soon),
                _tile(Ic.wave, 'وضع الأداء', 'أخفّ وأثبت بالتطبيق', soon),
                _tile(Ic.eq, 'الإحصائيات', 'الاستماعات والإعجابات', () => showStatsSheet(context)),
                _tile(Ic.pulse, 'وضع اللطم', Latm.on ? 'مفعّل — اضغط للإيقاف' : 'اهتزاز مع الإيقاع', () {
                  Latm.toggle();
                  ss(() {});
                  snack2(Latm.on ? 'وضع اللطم مفعّل: يهتز الهاتف مع الإيقاع' : 'أُوقف وضع اللطم');
                }),
              ],
            )),
            _sc2(Ic.speed, 'سرعة التشغيل', Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Color(0x66000000)),
              child: Row(children: [
                for (final v in spd)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => u(() => pc.setSpeed(v)),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: pc.speed == v ? kA : Colors.transparent),
                        child: Center(child: Text('${v}x', style: tx(16, c: pc.speed == v ? Color(0xFF2A2106) : Colors.white))),
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
        padding: EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          SizedBox(height: 12),
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
                  decoration: BoxDecoration(color: kLyColors[i], shape: BoxShape.circle, border: Border.all(color: pc.lyColor == i ? kA : Colors.white24, width: pc.lyColor == i ? 3 : 1)),
                ),
              ),
          ]),
          _h('الحجم'),
          SliderTheme(
            data: SliderTheme.of(c).copyWith(activeTrackColor: kA, inactiveTrackColor: Colors.white24, thumbColor: kA2),
            child: Slider(value: pc.lySize.clamp(16.0, 40.0), min: 16, max: 40, onChanged: (v) => u(() => pc.setPref('lySize', v))),
          ),
        ]),
      );
    });
  }

  void _sleepSheet() {
    final pc = app.player;
    _sheet((c, ss) => Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 18),
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
      backgroundColor: Color(0xFF16100B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Row(children: [
                  Expanded(child: Text('قائمة التشغيل · ${pc.queue.length}', style: tx(15.5, w: FontWeight.w800, c: Colors.white))),
                  IconButton(onPressed: pc.toggleShuffle, icon: PIcon(Ic.shuf, color: pc.shuffle ? kA : Colors.white54)),
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
                      title: Text(q.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14, w: FontWeight.w800, c: on ? kA : Colors.white)),
                      subtitle: Text(q.reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: Colors.white54, w: FontWeight.w500)),
                      trailing: on ? PIcon(Ic.eq, color: kA) : IconButton(icon: PIcon(Ic.x, color: Colors.white38, size: 20), onPressed: () => pc.removeAt(i)),
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
  final ({double h, double s, bool mono})? hue;
  _Background(this.t, this.hue);

  @override
  Widget build(BuildContext context) {
    final pc = app.player;
    final pal = bgPal(pc.bg, themeOf(pc.viz), hue);
    return Stack(fit: StackFit.expand, children: [
      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: pal.b))),
      if (t.coverUrl.isNotEmpty)
        Opacity(
          opacity: pc.layout == 2 ? 0.35 : 0.16,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: pc.layout == 2 ? 6 : 40, sigmaY: pc.layout == 2 ? 6 : 40),
            child: CachedNetworkImage(imageUrl: t.coverUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => SizedBox()),
          ),
        ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.55)]),
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
    final on = Paint()..color = kA;
    final off = Paint()..color = Colors.white24;
    final mid = size.height / 2;
    for (var i = 0; i < n; i++) {
      final f = i / n;
      final e = env.isEmpty ? 0.25 + 0.2 * math.sin(i * 0.7).abs() : env[(f * (env.length - 1)).round()];
      final h = 3 + e * (size.height - 6);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(i * step, mid - h / 2, bw, h), Radius.circular(1.2));
      canvas.drawRRect(r, f <= p ? on : off);
    }
    final x = (p * size.width).clamp(0.0, size.width);
    canvas.drawCircle(Offset(x, mid), 5, Paint()..color = kA2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter o) => o.p != p || o.env != env;
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
    final outer = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1 * k..color = kA.withOpacity(0.32);
    final inner = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6 * k..strokeCap = StrokeCap.round..color = kA.withOpacity(0.85);
    final gap = mini ? 3.0 : 14.0;
    canvas.drawPath(_arch(px - gap * 0.4, w - px + gap * 0.4, py - gap * 0.9, h * 0.52, h - py + 8), outer);
    canvas.drawPath(_arch(px + gap * 0.6, w - px - gap * 0.6, py + gap * 0.4, h * 0.5, h - py - 2), inner);
    if (!mini) {
      final z = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = kA.withOpacity(0.6);
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


/// الضغط المستمر على التالي/السابق = تقديم/ترجيع متسارع (مثل الويب)
class HoldSeek extends StatefulWidget {
  final int dir;
  final VoidCallback onTap;
  final Widget child;
  const HoldSeek({super.key, required this.dir, required this.onTap, required this.child});
  @override
  State<HoldSeek> createState() => _HoldSeekState();
}

class _HoldSeekState extends State<HoldSeek> {
  Timer? _t0, _iv;
  bool held = false;
  int st0 = 0;
  void _down() {
    held = false;
    st0 = DateTime.now().millisecondsSinceEpoch;
    _t0 = Timer(const Duration(milliseconds: 380), () {
      held = true;
      HapticFeedback.lightImpact();
      _iv = Timer.periodic(const Duration(milliseconds: 160), (_) {
        final el = (DateTime.now().millisecondsSinceEpoch - st0) / 1000, s = el < 1.6 ? 2 : (el < 3.5 ? 5 : 12);
        final p = app.player.p, d = (p.duration?.inMilliseconds ?? 0) / 1000.0;
        if (d > 0) app.player.seek((p.position.inMilliseconds / 1000.0 + widget.dir * s).clamp(0.0, d - 0.5));
      });
    });
  }

  void _up() {
    _t0?.cancel();
    _iv?.cancel();
    if (!held) widget.onTap();
    held = false;
  }

  @override
  void dispose() {
    _t0?.cancel();
    _iv?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapUp: (_) => _up(),
        onTapCancel: () {
          _t0?.cancel();
          _iv?.cancel();
          held = false;
        },
        child: Padding(padding: const EdgeInsets.all(10), child: widget.child),
      );
}

/// خط التقدّم بأشكال القوالب (line / thick / tape / seg / glow)
class ProgLine extends StatelessWidget {
  final String pg;
  final double p;
  final ValueChanged<double> onSeek;
  const ProgLine({super.key, required this.pg, required this.p, required this.onSeek});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onSeek((d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0)),
          onHorizontalDragUpdate: (d) => onSeek((d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0)),
          child: SizedBox(height: 26, width: c.maxWidth, child: CustomPaint(painter: _PgPainter(pg, p.clamp(0.0, 1.0), kA, kA2))),
        ),
      );
}

class _PgPainter extends CustomPainter {
  final String pg;
  final double p;
  final Color a, a2;
  _PgPainter(this.pg, this.p, this.a, this.a2);
  @override
  void paint(Canvas x, Size s) {
    final h = pg == 'thick' ? 6.0 : (pg == 'tape' ? 8.0 : 4.0), y = s.height / 2 - h / 2, w = s.width;
    final px = w * p; // من اليسار لليمين مثل الويب
    if (pg == 'tape' || pg == 'seg') {
      final on = pg == 'seg' ? 5.0 : 6.0, gap = pg == 'seg' ? 3.0 : 3.0;
      var i = 0;
      for (var xx = 0.0; xx < w; xx += on + gap) {
        final done = xx < px;
        x.drawRect(Rect.fromLTWH(xx, y, on, h), Paint()..color = done ? (pg == 'tape' && i.isOdd ? a2 : a) : Colors.white.withOpacity(pg == 'seg' ? 0.18 : 0.14));
        i++;
      }
    } else {
      x.drawRRect(RRect.fromLTRBR(0, y, w, y + h, Radius.circular(h / 2)), Paint()..color = Colors.white24);
      final fp = Paint()..color = a;
      if (pg == 'glow') x.drawRRect(RRect.fromLTRBR(0, y, px, y + h, Radius.circular(h / 2)), Paint()..color = a.withOpacity(0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      x.drawRRect(RRect.fromLTRBR(0, y, px, y + h, Radius.circular(h / 2)), fp);
    }
    final th = Paint()..color = a2;
    if (pg == 'thick') {
      x.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(px, s.height / 2), width: 16, height: 16), const Radius.circular(5)), th);
    } else if (pg == 'tape') {
      x.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(px, s.height / 2), width: 10, height: 18), const Radius.circular(3)), th);
    } else {
      x.drawCircle(Offset(px, s.height / 2), 9, th);
      x.drawCircle(Offset(px, s.height / 2), 9, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black26);
    }
  }

  @override
  bool shouldRepaint(covariant _PgPainter o) => o.p != p || o.pg != pg || o.a != a;
}
