import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
import 'extras.dart';

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
          auAn = a;
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
            child: Transform.translate(offset: Offset(0, _pull), child: Column(children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (d) => setState(() => _pull = (_pull + d.delta.dy).clamp(0.0, 400.0)),
                onVerticalDragEnd: (d) {
                  if (_pull > 120 || (d.primaryVelocity ?? 0) > 900) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _pull = 0);
                  }
                },
                child: Padding(
                padding: EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(children: [
                  _box(Ic.down, () => Navigator.pop(context), label: 'إغلاق المشغل'),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () {
                        HapticFeedback.selectionClick();
                        pc.setPref('viz', (pc.viz + 1) % kVizIds.length);
                        setState(() {});
                        snack2(kVizTitles[pc.viz]);
                      },
                      child: SizedBox(height: 36, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (pc.layout == 0) Text('يُشغَّل الآن', style: tx(10.5, c: Colors.white54)),
                        Text('${pc.index + 1} من ${pc.queue.length}', style: tx(pc.layout == 0 ? 12 : 13, c: Colors.white70)),
                      ]))),
                    ),
                  ),
                  _box(Ic.more, _settingsSheet, label: 'إعدادات المشغل'),
                ]),
              )),
              Expanded(
                child: Stack(children: [
                  Positioned.fill(child: pc.layout == 2 ? _lyricsView(t) : _stage(t)),
                  const Positioned.fill(child: CmLayer()),
                  const Positioned(right: 4, bottom: 70, child: RxLayer()),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _scrub == null ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          color: const Color(0xB3000000),
                          alignment: Alignment.center,
                          child: Text('${fmt2((_scrub ?? 0) * _scrubDur)} | ${fmt2(_scrubDur)}', textDirection: TextDirection.ltr, style: tx(40, c: Colors.white, w: FontWeight.w300)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              _bottom(t),
              _dock(),
            ])),
          ),
        ]),
      ),
    );
  }

  void snack2(String m) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: tx(13, c: Colors.white)), duration: Duration(seconds: 2)));
  }

  Widget _box(String ic, VoidCallback f, {double size = 36, Color? color, String? label}) => Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: f,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: Color(0x14FFFFFF), border: Border.all(color: Color(0x73E8C468), width: 1)),
          child: Center(child: PIcon(ic, color: color ?? kA, size: size * 0.47)),
        ),
      ));

  Widget _stage(Track t) {
    final pc = app.player;
    Widget st = Column(children: [
      Expanded(
        flex: 7,
        child: Padding(padding: EdgeInsets.only(top: 6), child: VizStage(an: an, img: img, viz: pc.viz, env: env)),
      ),
      Expanded(
        flex: 2,
        child: LyricStrip(lines: ly, base: 25, onLong: () => showLyricsSheet(context, ly)),
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

  double _pull = 0;
  double? _scrub;
  double _scrubDur = 0;
  final _sc = ScrollController();
  int _lastIdx = -2;

  /// زر الإعجاب الموحّد: ضغطة = إعجاب بهذه اللحظة (+ المفضلة أول مرة)، ضغطة مطوّلة = إزالة من المفضلة
  Widget _favBtn(Track t, {double size = 25}) => GestureDetector(
        onTap: () async {
          await social.like(context);
          setState(() {});
        },
        onLongPress: () {
          if (!app.repo.isFav(t.id)) return;
          app.repo.toggleFav(t.id);
          setState(() {});
          snack2('أُزيلت من المفضلة');
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ListenableBuilder(
            listenable: social,
            builder: (_, __) {
              final n = social.rx.length, on = app.repo.isFav(t.id);
              return Column(mainAxisSize: MainAxisSize.min, children: [
                PIcon(on ? Ic.heartF : Ic.heart, color: on ? const Color(0xFFFF4D6D) : kA, size: size),
                if (n > 0) Text(n > 999 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n', style: tx(10.5, c: on ? const Color(0xFFFF8FA3) : Colors.white60)),
              ]);
            },
          ),
        ),
      );
  Widget _cmBtn({double size = 23}) => GestureDetector(
        onTap: () => showCommentsSheet(context),
        child: Padding(padding: const EdgeInsets.all(6), child: PIcon(Ic.chat, color: kA, size: size)),
      );
  Widget _titleCol(Track t, {TextAlign al = TextAlign.center, double fs = 22}) => Column(crossAxisAlignment: al == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
        Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: al, style: TextStyle(fontFamily: thx(app.player.viz).font, fontFamilyFallback: const ['F0'], fontSize: fs, color: Colors.white, fontWeight: FontWeight.w700, height: 1.4)),
        FittedBox(fit: BoxFit.scaleDown, child: Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, textAlign: al, style: tx(15.5, c: kA))),
      ]);

  /// الكلمات أولاً: غلاف صغير + العنوان + القلب، والكلمات تملأ الشاشة
  Widget _lyricsView(Track t) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 48, height: 48, child: img != null ? RawImage(image: img, fit: BoxFit.cover) : Container(color: const Color(0x22FFFFFF)))),
            const SizedBox(width: 10),
            Expanded(child: _titleCol(t, al: TextAlign.start, fs: 19)),
            _favBtn(t),
          ]),
        ),
        Expanded(child: LyricStrip(lines: ly, base: 28, onLong: () => showLyricsSheet(context, ly))),
      ]);

  Widget _bottom(Track t) {
    final pc = app.player;
    final body = Padding(
      padding: EdgeInsets.fromLTRB(18, 6, 18, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (pc.layout != 2) Row(children: [_favBtn(t), Expanded(child: _titleCol(t)), _cmBtn()]),
        SizedBox(height: pc.layout == 2 ? 0 : 6),
        StreamBuilder<Duration>(
          stream: pc.p.positionStream,
          builder: (_, s) => StreamBuilder<Duration?>(
            stream: pc.p.durationStream,
            builder: (_, d) {
              final dur = (d.data?.inMilliseconds ?? 0) / 1000.0;
              final pos = ((s.data?.inMilliseconds ?? 0) / 1000.0).clamp(0.0, dur > 0 ? dur : 1.0);
              return Column(children: [
                if (pc.layout == 0) ...[
                  SizedBox(height: 40, child: SpecBar(an: an)),
                  ProgLine(pg: thx(pc.viz).pg, p: dur > 0 ? pos / dur : 0, heat: social.rx, dur: dur, onSeek: (f) {
                    if (dur > 0) pc.seek(f * dur);
                  }),
                ] else
                  SizedBox(
                    height: 40,
                    child: WaveBar(
                      env: env,
                      progress: _scrub ?? (dur > 0 ? pos / dur : 0),
                      onScrub: (f) => setState(() {
                        _scrub = f;
                        _scrubDur = dur;
                      }),
                      onSeek: (f) {
                        if (dur > 0) pc.seek(f * dur);
                      },
                    ),
                  ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Row(textDirection: TextDirection.ltr, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(fmt2(pos), style: tx(12, c: Colors.white60)),
                    Text(fmt2(dur), style: tx(12, c: Colors.white60)),
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
            _ctl(Ic.shuf, pc.shuffle, pc.toggleShuffle),
            HoldSeek(dir: -1, onTap: pc.prev, child: PIcon(Ic.prev, color: kA, size: 26)),
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
                    dec = BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [kA2, kA], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: kA.withOpacity(0.35), blurRadius: 26)]);
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
                    dec = BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(33), topRight: Radius.circular(33), bottomLeft: Radius.circular(13), bottomRight: Radius.circular(13)), gradient: LinearGradient(colors: [kA2, kA], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: kA.withOpacity(0.35), blurRadius: 26)], border: playing ? Border.all(color: kA2.withOpacity(0.6), width: 1.5) : null);
                }
                return Semantics(label: 'تشغيل أو إيقاف', button: true, child: GestureDetector(
                  onTap: pc.toggle,
                  child: AnimatedScale(
                    scale: x.dock == 'metal' && !playing ? 0.94 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: dec,
                      child: busy
                          ? Padding(padding: const EdgeInsets.all(21), child: CircularProgressIndicator(strokeWidth: 3, color: icol))
                          : Center(child: PIcon(playing ? Ic.pause : Ic.play, size: 30, color: icol)),
                    ),
                  ),
                ));
              },
            ),
            HoldSeek(dir: 1, onTap: pc.next, child: PIcon(Ic.next, color: kA, size: 26)),
            _ctl(Ic.rep, pc.loop != LoopMode.off, pc.cycleLoop),
          ]),
        ),
      ]),
    );
    if (pc.layout != 0) return body;
    // الغامر: كل التحكم داخل لوحة زجاجية واحدة
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: const Color(0x1AFFFFFF), border: Border.all(color: const Color(0x24FFFFFF))),
      child: body,
    );
  }

  Widget _ctl(String ic, bool on, VoidCallback f) => GestureDetector(
        onTap: () {
          f();
          setState(() {});
        },
        child: Padding(padding: const EdgeInsets.all(6), child: PIcon(ic, color: on ? kA : kA.withOpacity(0.45), size: 22)),
      );

  Widget _dock() {
    final pc = app.player;
    Widget b(String ic, String s, bool on, VoidCallback f, {bool act = false}) => Expanded(
          child: GestureDetector(
            onTap: f,
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: act ? Color(0x14FFFFFF) : Colors.transparent),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                PIcon(ic, color: on ? kA : Color(0xB3E8C468), size: 20),
                SizedBox(height: 3),
                Text(s, style: tx(10.5, c: on ? kA : Color(0xB3E8C468))),
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
        b(Ic.queue, 'القائمة', false, _queueSheet),
        if (pc.layout == 2) b(Ic.eq, 'القالب', false, _settingsSheet) else b(Ic.text, 'الكلمات', false, () => showLyricsSheet(context, ly)),
        b(Ic.pulse, 'الصوت', false, () => showAudioSheet(context)),
      ]),
    );
  }

  // ---------- الأوراق ----------
  Future<void> _sheet(Widget Function(BuildContext, StateSetter) b, {double h = 0.0}) {
    return showMSheet(
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
                color: sel == i ? kGold : Color(0x14FFFFFF),
                border: Border.all(color: sel == i ? kGold : Color(0x26FFFFFF)),
              ),
              child: Text(name(i), style: tx(13.5, c: sel == i ? Color(0xFF2A2106) : Colors.white)),
            ),
          ),
      ]);

  Widget _sc2(String ic, String title, Widget child, {String? chip}) => Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Color(0x0FFFFFFF), border: Border.all(color: Color(0x2EE8C468))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Color(0x1FE8C468)), child: Center(child: PIcon(ic, color: kGold, size: 14))),
            SizedBox(width: 8),
            Text(title, style: tx(13, c: Colors.white)),
            Spacer(),
            if (chip != null) Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0x14FFFFFF)), child: Text(chip, style: tx(10.5, c: kGold))),
          ]),
          SizedBox(height: 10),
          child,
        ]),
      );

  Widget _list(List<Widget> rows) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Color(0x0AFFFFFF), border: Border.all(color: Color(0x1FFFFFFF))),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 1, margin: EdgeInsets.symmetric(horizontal: 12), color: Color(0x14FFFFFF)),
            rows[i],
          ],
        ]),
      );

  Widget _tile(String ic, String t, String sub, VoidCallback f, {bool neu = false, bool? sw}) => GestureDetector(
        onTap: f,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(children: [
            PIcon(ic, color: kGold, size: 18),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t, style: tx(13.5, c: Colors.white, w: FontWeight.w700)),
                if (neu) Container(margin: EdgeInsets.only(right: 6), padding: EdgeInsets.symmetric(horizontal: 7, vertical: 1), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: kGold), child: Text('جديد', style: tx(9.5, c: Color(0xFF2A2106)))),
              ]),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11, c: Colors.white54)),
            ])),
            if (sw != null)
              AnimatedContainer(
                duration: Duration(milliseconds: 180),
                width: 36,
                height: 20,
                padding: EdgeInsets.all(2),
                alignment: sw ? Alignment.centerLeft : Alignment.centerRight,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: sw ? kGold : Color(0x26FFFFFF)),
                child: Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: sw ? Color(0xFF2A2106) : Colors.white70)),
              ),
          ]),
        ),
      );

  int _stab = 0, _vcat = -1;
  static const _vcats = [
    ('كلاسيكية', ['mihrab', 'ambient', 'cover', 'card', 'dots', 'silk']),
    ('أجهزة', ['vinyl', 'cassette', 'jog', 'reels', 'knob', 'speaker', 'scope']),
    ('حيّة', ['wring', 'halo', 'bars', 'blob', 'wave', 'spectrum', 'orbit', 'pulse', 'star', 'dust', 'neon', 'pond', 'strings', 'candles']),
  ];

  Widget _grp(String s) => Padding(padding: EdgeInsets.only(top: 12, bottom: 8, right: 2), child: Text(s, style: tx(12, c: kGold, w: FontWeight.w700)));

  void _settingsSheet() {
    final pc = app.player;
    final t = pc.cur!;
    if (_vcat < 0) {
      final id = kVizIds[pc.viz % kVizIds.length];
      _vcat = _vcats.indexWhere((e) => e.$2.contains(id));
      if (_vcat < 0) _vcat = 0;
    }
    _sheet((c, ss) {
      void u(VoidCallback f) {
        f();
        ss(() {});
        setState(() {});
      }

      Widget seg(List<String> l, int sel, void Function(int) on, {double fs = 13}) => Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Color(0x40000000)),
            child: Row(children: [
              for (var i = 0; i < l.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => on(i),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: sel == i ? kGold : Colors.transparent),
                      child: Center(child: Text(l[i], style: tx(fs, c: sel == i ? Color(0xFF2A2106) : Colors.white70, w: FontWeight.w700))),
                    ),
                  ),
                ),
            ]),
          );

      final ids = _vcats[_vcat].$2;
      final view = <Widget>[
            _sc2(Ic.eq, 'قوالب العرض', chip: kVizTitles[pc.viz % kVizTitles.length], Column(children: [
              seg([for (final e in _vcats) e.$1], _vcat, (i) => u(() => _vcat = i), fs: 11.5),
              SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
                children: [
                  for (final id in ids)
                    Builder(builder: (_) {
                      final i = kVizIds.indexOf(id), on = pc.viz == i;
                      return GestureDetector(
                        onTap: () => u(() => pc.setPref('viz', i)),
                        child: Column(children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: RadialGradient(colors: [Color(0xFF14664F), Color(0xFF073D2E)]), border: Border.all(color: on ? kGold : Colors.transparent, width: 2)),
                              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: IgnorePointer(child: VizStage(an: null, img: img, viz: i, still: true))),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(kVizTitles[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(10, c: on ? kGold : Colors.white60)),
                        ]),
                      );
                    }),
                ],
              ),
            ])),
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
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: pc.layout == i ? Color(0x2EE8C468) : Color(0x14FFFFFF), border: Border.all(color: pc.layout == i ? kGold : Color(0x24FFFFFF), width: pc.layout == i ? 2 : 1.2)),
                      child: Column(children: [
                        Container(width: 22, height: 32, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: pc.layout == i ? kGold.withOpacity(0.55) : Colors.white24), child: Icon(i == 2 ? Icons.notes : (i == 1 ? Icons.crop_square : Icons.circle), size: 11, color: Colors.white70)),
                        SizedBox(height: 6),
                        Text(['غامر', 'كلاسيكي', 'الكلمات أولاً'][i], style: tx(11.5, c: pc.layout == i ? kGold : Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ],
            ])),
            _sc2(Ic.color, 'لون الخلفية', chip: kBgTitles[pc.bg % kBgTitles.length], SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kBgKeys.length,
                separatorBuilder: (_, __) => SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = bgPal(i, themeOf(pc.viz), hue);
                  return GestureDetector(
                    onTap: () => u(() => pc.setPref('bg', i)),
                    child: Column(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.b[0], p.b[2]]), border: Border.all(color: pc.bg == i ? kGold : Colors.white24, width: pc.bg == i ? 3 : 1)),
                        child: i < 2 ? Center(child: PIcon(i == 0 ? Ic.spark : Ic.lay, color: Colors.white, size: 20)) : null,
                      ),
                      SizedBox(height: 4),
                      Text(kBgTitles[i], style: tx(12, c: pc.bg == i ? kGold : Colors.white70)),
                    ]),
                  );
                },
              ),
            )),
      ];
      final tools = <Widget>[
            _grp('القصيدة'),
            _list([
                _tile(Ic.moon, 'مؤقت النوم', pc.sleepAt != null ? 'مفعّل — اضغط للتعديل' : 'إيقاف التشغيل بعد مدة', () {
                  Navigator.pop(c);
                  _sleepSheet();
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
                _tile(Ic.flame, 'الذروة', social.rx.isEmpty ? 'لا إعجابات' : 'أكثر لحظة إعجاباً', () {
                  final pk = social.peakT();
                  if (pk == null) return snack2('لا توجد إعجابات بعد');
                  Navigator.pop(c);
                  pc.seek(pk);
                  if (!pc.p.playing) pc.toggle();
                }),
              ]),
            _grp('أوضاع الاستماع'),
            _list([
                _tile(Ic.users, 'المجلس', majlis.on ? 'مفعّل · ${majlis.code}' : 'استماع مشترك', () {
                  Navigator.pop(c);
                  showMajlisSheet(context);
                }, neu: true),
                _tile(Ic.text, 'وضع الحسينية', 'كلمات كبيرة للشاشة', () {
                  Navigator.pop(c);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HusnPage(ly)));
                }),
                _tile(Ic.speed, 'وضع السيارة', 'أزرار كبيرة للقيادة', () {
                  Navigator.pop(c);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CarPage()));
                }),
                _tile(Ic.pulse, 'وضع اللطم', 'اهتزاز مع الإيقاع', sw: Latm.on, () {
                  Latm.toggle();
                  ss(() {});
                  snack2(Latm.on ? 'وضع اللطم مفعّل: يهتز الهاتف مع الإيقاع' : 'أُوقف وضع اللطم');
                }),
              ]),
            _grp('الجهاز'),
            _list([
                _tile(Ic.wave, 'وضع الأداء', 'رسوم أخف للأجهزة الضعيفة', sw: pc.perf == 1, () {
                  pc.setPref('perf', pc.perf == 1 ? 0 : 1);
                  ss(() {});
                  snack2(pc.perf == 1 ? 'وضع الأداء مفعّل: يُطبَّق عند فتح المشغّل من جديد' : 'أُوقف وضع الأداء');
                }),
              ]),
      ];
      return SizedBox(
        height: MediaQuery.of(c).size.height * 0.85,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)))),
              SizedBox(height: 10),
              Row(children: [
                Text('إعدادات المشغل', style: tx(15.5, c: Colors.white, w: FontWeight.w700)),
                Spacer(),
                _box(Ic.x, () => Navigator.pop(c), size: 32, color: Colors.white),
              ]),
              SizedBox(height: 12),
              seg(['العرض', 'الأدوات'], _stab, (i) => u(() => _stab = i)),
              SizedBox(height: 6),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14, 6, 14, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _stab == 0 ? view : tools),
            ),
          ),
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
              pc.sleepFade = Opt.fade;
              pc.setSleep([0, 10, 15, 30, 60][i]);
              Navigator.pop(c);
              setState(() {});
            }),
          ]),
        ));
  }

  void _queueSheet() {
    final pc = app.player;
    String fd(int ms) {
      final m = ms ~/ 60000, sx = (ms ~/ 1000) % 60;
      return '${m.toString().padLeft(2, '0')}:${sx.toString().padLeft(2, '0')}';
    }

    Widget hb(String ic, bool on, VoidCallback f) => GestureDetector(
          onTap: f,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: on ? const Color(0x2EE8C468) : const Color(0x12FFFFFF), border: Border.all(color: on ? kGold : const Color(0x24FFFFFF))),
            child: Center(child: PIcon(ic, color: on ? kGold : Colors.white, size: 20)),
          ),
        );
    Widget row(Track q, {Widget? end, bool cur = false}) => Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: cur ? const Color(0x2EE8C468) : const Color(0x0DFFFFFF), border: cur ? Border.all(color: kGold.withOpacity(0.7), width: 1.4) : null),
          child: Row(children: [
            Cover(q.coverUrl, size: 50, radius: 12),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(15.5, w: FontWeight.w800, c: cur ? kGold : Colors.white)),
              Text(q.reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: Colors.white54)),
            ])),
            if ((app.repo.durs[q.id] ?? 0) > 0) Text(fd(app.repo.durs[q.id]!), textDirection: TextDirection.ltr, style: tx(12.5, c: Colors.white54)),
            if (end != null) end,
          ]),
        );
    showMSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16100B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.92,
          builder: (c2, sc) => ListenableBuilder(
            listenable: pc,
            builder: (_, __) {
              final n = pc.queue.length, ci = pc.index.clamp(0, n == 0 ? 0 : n - 1);
              final next = n == 0 ? <Track>[] : pc.queue.sublist(ci + 1);
              final tot = pc.queue.fold<int>(0, (a, q) => a + (app.repo.durs[q.id] ?? 0));
              final hdr = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('قائمة التشغيل', style: tx(19, w: FontWeight.w800, c: Colors.white)),
                      Text('$n قصيدة${tot > 0 ? ' · ${fd(tot)}' : ''}', style: tx(12.5, c: Colors.white54)),
                    ])),
                    hb(Ic.shuf, pc.shuffle, pc.toggleShuffle),
                    hb(Ic.rep, pc.loop != LoopMode.off, pc.cycleLoop),
                  ]),
                ),
                if (n > 0) ...[
                  Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 8), child: Text('يُشغَّل الآن', style: tx(13, c: Colors.white60))),
                  StreamBuilder<Duration>(
                    stream: pc.p.positionStream,
                    builder: (_, s) {
                      final d = pc.p.duration?.inMilliseconds ?? 0, pos = s.data?.inMilliseconds ?? 0;
                      return Stack(children: [
                        row(pc.queue[ci], cur: true),
                        if (d > 0)
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 1,
                            child: Align(alignment: Alignment.centerRight, child: FractionallySizedBox(widthFactor: (pos / d).clamp(0.0, 1.0), child: Container(height: 3, decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(2))))),
                          ),
                      ]);
                    },
                  ),
                  if (next.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 8), child: Text('التالي', style: tx(13, c: Colors.white60))),
                ],
              ]);
              return ReorderableListView.builder(
                scrollController: sc,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                buildDefaultDragHandles: false,
                header: hdr,
                itemCount: next.length,
                proxyDecorator: (w, _, __) => Material(color: Colors.transparent, elevation: 8, borderRadius: BorderRadius.circular(18), child: w),
                onReorder: (o, nw) {
                  if (nw > o) nw--;
                  HapticFeedback.selectionClick();
                  pc.moveQ(ci + 1 + o, ci + 1 + nw);
                },
                itemBuilder: (_, k) {
                  final q = next[k];
                  return Padding(
                    key: ValueKey('q${q.id}_$k'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: ValueKey('d${q.id}_$k'),
                      direction: DismissDirection.horizontal,
                      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x33FF6B6B)), child: Text('إزالة', style: tx(13, c: const Color(0xFFFF8F8F)))),
                      secondaryBackground: Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x33FF6B6B)), child: Text('إزالة', style: tx(13, c: const Color(0xFFFF8F8F)))),
                      onDismissed: (_) {
                        HapticFeedback.lightImpact();
                        pc.removeAt(ci + 1 + k);
                      },
                      child: GestureDetector(
                        onTap: () => pc.jump(ci + 1 + k),
                        child: row(q, end: ReorderableDragStartListener(index: k, child: const Padding(padding: EdgeInsets.fromLTRB(4, 8, 10, 8), child: Icon(Icons.drag_handle_rounded, color: Colors.white54, size: 26)))),
                      ),
                    ),
                  );
                },
              );
            },
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
      if (t.coverUrl.isNotEmpty && pc.perf == 0)
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
  final void Function(double?)? onScrub;
  const WaveBar({super.key, required this.env, required this.progress, required this.onSeek, this.onScrub});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(builder: (_, c) {
        double f(Offset o) => (o.dx / c.maxWidth).clamp(0.0, 1.0);
        var last = progress;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onSeek(f(d.localPosition)),
          onHorizontalDragStart: (d) => onScrub?.call(f(d.localPosition)),
          onHorizontalDragUpdate: (d) {
            last = f(d.localPosition);
            onScrub == null ? onSeek(last) : onScrub!(last);
          },
          onHorizontalDragEnd: (_) {
            onSeek(last);
            onScrub?.call(null);
          },
          onHorizontalDragCancel: () => onScrub?.call(null),
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
  final List<double> heat;
  final double dur;
  const ProgLine({super.key, required this.pg, required this.p, required this.onSeek, this.heat = const [], this.dur = 0});
  /// خريطة الإعجابات (40 خانة) مثل heatUi في الويب
  List<double>? _heat() {
    if (heat.isEmpty || dur <= 0) return null;
    final b = List<double>.filled(40, 0);
    for (final t in heat) {
      final i = (t / dur * 40).floor();
      if (i >= 0 && i < 40) b[i] += 1;
    }
    final s = List<double>.filled(40, 0);
    for (var i = 0; i < 40; i++) {
      s[i] = b[i] + (i > 0 ? b[i - 1] * 0.5 : 0) + (i < 39 ? b[i + 1] * 0.5 : 0);
    }
    final mx = s.reduce(math.max);
    return mx <= 0 ? null : [for (final v in s) v / mx];
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onSeek((d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0)),
          onHorizontalDragUpdate: (d) => onSeek((d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0)),
          child: SizedBox(height: 26, width: c.maxWidth, child: CustomPaint(painter: _PgPainter(pg, p.clamp(0.0, 1.0), kA, kA2, _heat()))),
        ),
      );
}

class _PgPainter extends CustomPainter {
  final String pg;
  final double p;
  final Color a, a2;
  final List<double>? heat;
  _PgPainter(this.pg, this.p, this.a, this.a2, this.heat);
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
      if (heat != null) {
        for (var i = 0; i < 40; i++) {
          final v = heat![i];
          if (v < 0.05) continue;
          x.drawRect(Rect.fromLTWH(w * i / 40, y, w / 40 + 0.5, h), Paint()..color = Color.fromRGBO((255 - v * 40).round(), (255 - v * 170).round(), (255 - v * 190).round(), 0.18 + v * 0.55));
        }
      }
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
  bool shouldRepaint(covariant _PgPainter o) => true;
}


/// شكل الصوت الحي (الغامر) — مثل plrspec في الويب
class SpecBar extends StatefulWidget {
  final Analysis? an;
  const SpecBar({super.key, this.an});
  @override
  State<SpecBar> createState() => _SpecBarState();
}

class _SpecBarState extends State<SpecBar> with SingleTickerProviderStateMixin {
  late final Ticker _t;
  final _raw = List<double>.filled(22, 0), _v = List<double>.filled(22, 0);
  @override
  void initState() {
    super.initState();
    _t = createTicker((e) {
      final pl = app.player.p, sec = pl.position.inMilliseconds / 1000.0, now = e.inMilliseconds / 1000.0;
      if (pl.playing && widget.an != null) {
        widget.an!.bandsAt(sec, _raw);
      } else {
        for (var k = 0; k < 22; k++) {
          _raw[k] = pl.playing ? 0.25 + 0.2 * math.sin(now * 6 + k * 0.6).abs() : 0;
        }
      }
      for (var k = 0; k < 22; k++) {
        _v[k] += (_raw[k] - _v[k]) * (_raw[k] > _v[k] ? 0.5 : 0.15);
      }
      setState(() {});
    })
      ..start();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.infinite, painter: _SpecPainter(_v));
}

class _SpecPainter extends CustomPainter {
  final List<double> v;
  _SpecPainter(this.v);
  @override
  void paint(Canvas c, Size s) {
    const step = 5.0, bw = 2.6;
    final n = (s.width / step).floor(), mid = s.height / 2;
    for (var i = 0; i < n; i++) {
      final d = ((i - n / 2).abs() / (n / 2)), k = (d * 21).round().clamp(0, 21);
      final e = v[k] * (1 - d * 0.35);
      final h = 2 + e * (s.height - 4);
      final col = Color.lerp(kA2, kA, d)!.withOpacity(0.45 + e * 0.55);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * step, mid - h / 2, bw, h), const Radius.circular(1.3)), Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _SpecPainter o) => true;
}
