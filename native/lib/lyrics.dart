import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// الكلمات — منقولة من player.js (شريط منزلق + انتقالات + مظهر)
const kLF = [('F0', 'كايرو', 700), ('F1', 'تجوّل', 700), ('F2', 'أميري', 700), ('F8', 'نسخ', 700), ('F13', 'شهرزاد', 700), ('F17', 'لطيف', 700), ('F3', 'رقعة', 700), ('F10', 'رقعة الحبر', 700), ('F12', 'ميرزا', 700), ('F5', 'المسيري', 700), ('F4', 'ريم كوفي', 700), ('F15', 'ريم الحبر', 400), ('F14', 'كوفي', 700), ('F6', 'لالزار', 400), ('F9', 'رقّاص', 400), ('F7', 'كاتبة', 400), ('F16', 'بلاكا', 400), ('F11', 'فايبز', 400)];
// ألوان أساسية فقط — لون واحد لكل نوع
const kLyCols = [Color(0xFFE8C468), Color(0xFFFFFFFF), Color(0xFF2FBF8F), Color(0xFF8EC9FF), Color(0xFFCDB4FF), Color(0xFFFF9DB1), Color(0xFFFF6B6B), Color(0xFFFFB36B)];
const kLyColN = ['ذهبي', 'أبيض', 'أخضر', 'أزرق', 'بنفسجي', 'وردي', 'أحمر', 'برتقالي'];
const kTRS = [('slide', 'انزلاق'), ('scroll', 'تمرير'), ('fade', 'تلاشٍ'), ('zoom', 'تكبير'), ('kar', 'تعبئة'), ('blur', 'ضبابي'), ('rise', 'صعود'), ('flip', 'انقلاب'), ('glow', 'توهّج'), ('focus', 'تركيز')];
const kTRI = [Icons.swap_vert, Icons.unfold_more, Icons.gradient, Icons.zoom_in, Icons.format_color_fill, Icons.blur_on, Icons.north, Icons.flip, Icons.auto_awesome, Icons.center_focus_strong];

Color lyColorNow() => kLyCols[app.player.lyColor % kLyCols.length];

TextStyle lyStyle({double base = 24, Color? color, double? weight}) {
  final f = kLF[app.player.lyFont % kLF.length];
  return TextStyle(
    fontFamily: f.$1,
    fontFamilyFallback: const ['F0', 'CairoLatin'],
    fontSize: base * app.player.lySize,
    fontWeight: (weight ?? f.$3) >= 600 ? FontWeight.w700 : FontWeight.w400,
    color: color ?? lyColorNow(),
    height: 1.55,
    shadows: const [Shadow(color: Color(0xD9000000), blurRadius: 12, offset: Offset(0, 2))],
  );
}

/// تقسيم الأسطر الطويلة (نفس splitLong)
List<Lyric> splitLong(List<Lyric> L, [int? maxChars]) {
  if (app.player.lySplit == 0) return L;
  final lim = maxChars ?? (36 / app.player.lySize).round(), o = <Lyric>[];
  for (var i = 0; i < L.length; i++) {
    final x = L[i], s = x.l.trim();
    if (s.length <= lim || !s.contains(' ')) {
      o.add(x);
      continue;
    }
    final ws = s.split(' ');
    final half = s.length / 2;
    var acc = 0, cut = 1;
    var best = 1e9;
    for (var k = 1; k < ws.length; k++) {
      acc += ws[k - 1].length + 1;
      final d = (acc - half).abs();
      if (d < best) {
        best = d;
        cut = k;
      }
    }
    final a = ws.sublist(0, cut).join(' '), b = ws.sublist(cut).join(' ');
    final nt = i + 1 < L.length ? L[i + 1].t : x.t + 5, r = a.length / s.length;
    o.add(Lyric(x.t, a, x.gap));
    o.add(Lyric(x.t + math.min(nt - x.t, 8.0) * r * 0.95, b, x.gap));
  }
  return o;
}

/// شريط الكلمات المنزلق: كل الأسطر في عمود يصعد بسلاسة والحالي في الوسط
class LyricStrip extends StatefulWidget {
  final List<Lyric> lines;
  final double base;
  final VoidCallback? onLong;
  final bool demo;
  const LyricStrip({super.key, required this.lines, this.base = 24, this.onLong, this.demo = false});
  @override
  State<LyricStrip> createState() => _LyricStripState();
}

class _LyricStripState extends State<LyricStrip> with SingleTickerProviderStateMixin {
  List<Lyric> L = const [];
  String _key = '';
  double _drag = 0;
  bool _dragging = false;
  int _dk = -1;
  late final AnimationController _demo = AnimationController(vsync: this, duration: const Duration(seconds: 13));

  @override
  void initState() {
    super.initState();
    if (widget.demo) _demo.repeat();
  }

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  double _w = 0;
  void _prep() {
    // حد التقسيم حسب العرض الفعلي وحجم الخط (لا سطر يلتف على سطرين)
    final cw = widget.base * app.player.lySize * 0.5;
    final lim = _w > 0 ? ((_w - 36) / cw).floor().clamp(12, 60) : null;
    final k = '${widget.lines.length}|${widget.lines.isEmpty ? '' : widget.lines.first.l}|${app.player.lySplit}|${app.player.lySize}|$lim';
    if (k != _key) {
      _key = k;
      L = splitLong(widget.lines, lim);
    }
  }

  int _idx(double t) {
    var k = -1;
    for (var i = 0; i < L.length; i++) {
      if (t >= L[i].t - 0.05) {
        k = i;
      } else {
        break;
      }
    }
    return k;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return Center(child: Text('لا تتوفر كلمات لهذه القصيدة', style: tx(13, c: Colors.white38)));
    return LayoutBuilder(builder: (_, c) {
      _w = c.maxWidth;
      _prep();
      final w = c.maxWidth - 24, h = c.maxHeight;
      final tr = kTRS[app.player.lyTr % kTRS.length].$1;
      // ارتفاع كل سطر (الحالي بحجم أكبر)
      final hs = <double>[];
      for (final l in L) {
        final tp = TextPainter(text: TextSpan(text: l.l, style: lyStyle(base: widget.base)), textDirection: TextDirection.rtl, textAlign: TextAlign.center)..layout(maxWidth: w);
        hs.add(tp.height + 4);
      }
      final tops = <double>[];
      var acc = 0.0;
      for (final x in hs) {
        tops.add(acc);
        acc += x;
      }
      Widget body(int k, double p) {
        final kk = _dragging ? _dk : k;
        final idx = kk < 0 ? 0 : kk;
        var y = h / 2 - (tops[idx] + hs[idx] / 2);
        if (kk < 0) y += hs[0];
        if (_dragging) y = _drag;
        final dur = Duration(milliseconds: _dragging ? 0 : (tr == 'scroll' ? 1100 : (tr == 'rise' ? 900 : 750)));
        return ShaderMask(
          shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent], stops: [0, 0.25, 0.75, 1]).createShader(r),
          blendMode: BlendMode.dstIn,
          child: ClipRect(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: y),
              duration: dur,
              curve: const Cubic(0.22, 1, 0.36, 1),
              builder: (_, yy, __) => Stack(clipBehavior: Clip.none, children: [
                for (var i = 0; i < L.length; i++)
                  if (tops[i] + yy + hs[i] > -40 && tops[i] + yy < h + 40)
                    Positioned(
                      top: tops[i] + yy,
                      left: 12,
                      right: 12,
                      height: hs[i],
                      child: _line(L[i].l, i == kk ? 2 : ((i - kk).abs() == 1 ? 1 : 0), tr, i == kk ? p : 0, ab: (i == kk && tr == 'kar' && !widget.demo) ? [L[i].t, i + 1 < L.length ? L[i + 1].t : L[i].t + 4] : null),
                    ),
              ]),
            ),
          ),
        );
      }

      Widget wrap(Widget child, int k) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: widget.onLong == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onLong!();
                  },
            onVerticalDragStart: widget.demo
                ? null
                : (_) {
                    final idx = k < 0 ? 0 : k;
                    setState(() {
                      _dragging = true;
                      _dk = idx;
                      _drag = h / 2 - (tops[idx] + hs[idx] / 2);
                    });
                  },
            onVerticalDragUpdate: widget.demo
                ? null
                : (d) {
                    _drag += d.delta.dy;
                    final cc = h / 2 - _drag;
                    var best = 0;
                    var bd = 1e9;
                    for (var i = 0; i < L.length; i++) {
                      final m = tops[i] + hs[i] / 2, dd = (m - cc).abs();
                      if (dd < bd) {
                        bd = dd;
                        best = i;
                      }
                    }
                    if (best != _dk) HapticFeedback.selectionClick();
                    setState(() => _dk = best);
                  },
            onVerticalDragEnd: widget.demo
                ? null
                : (_) {
                    final q = L[_dk.clamp(0, L.length - 1)];
                    final pl = app.player;
                    final dur = (pl.p.duration?.inMilliseconds ?? 0) / 1000.0;
                    if (dur > 0) {
                      pl.seek(math.max(0.0, math.min(dur - 0.1, q.t + 0.12)));
                      if (!pl.p.playing) pl.toggle();
                    }
                    setState(() => _dragging = false);
                  },
            child: child,
          );

      if (widget.demo) {
        return AnimatedBuilder(
          animation: _demo,
          builder: (_, __) {
            final e = _demo.value * L.length;
            return body(e.floor() % L.length, e % 1);
          },
        );
      }
      return StreamBuilder<Duration>(
        stream: app.player.p.positionStream,
        builder: (_, s) {
          final t = (s.data?.inMilliseconds ?? 0) / 1000.0 + app.player.lyOffset;
          final k = _idx(t);
          var p = 0.0;
          if (tr == 'kar' && k >= 0) {
            final a = L[k].t, b = k + 1 < L.length ? L[k + 1].t : a + 4;
            p = ((t - a) / math.max(0.4, b - a)).clamp(0.0, 1.0);
          }
          return wrap(body(k, p), k);
        },
      );
    });
  }

  /// st: 2 حالي، 1 مجاور، 0 بعيد
  Widget _line(String s, int st, String tr, double kp, {List<double>? ab}) {
    final col = lyColorNow();
    // فواصل المقاطع (***** أو ----) تُعرض كزخرفة
    if (RegExp(r'^[\s\*\-–—_\.•~=]+$').hasMatch(s)) {
      return Center(child: Opacity(opacity: st == 2 ? 0.9 : 0.4, child: Text('۞', style: TextStyle(fontSize: widget.base * 0.8, color: kGold))));
    }
    var op = st == 2 ? 1.0 : (st == 1 ? 0.42 : 0.26);
    var sc = st == 2 ? 1.0 : 0.8;
    double blur = 0, rx = 0, dy = 0;
    switch (tr) {
      case 'fade':
        sc = 1;
        op = st == 2 ? 1 : 0.12;
      case 'zoom':
        sc = st == 2 ? 1.08 : 0.7;
      case 'blur':
        sc = 1;
        blur = st == 2 ? 0 : 2.5;
        op = st == 2 ? 1 : 0.22;
      case 'focus':
        blur = st == 2 ? 0 : 1.6;
        op = st == 2 ? 1 : 0.18;
      case 'rise':
        sc = st == 2 ? 1 : 0.9;
        dy = st == 2 ? 0 : 16;
      case 'flip':
        rx = st == 2 ? 0 : 60 * math.pi / 180;
        sc = st == 2 ? 1 : 0.9;
    }
    var style = lyStyle(base: widget.base);
    if (st == 2 && tr == 'glow') {
      style = style.copyWith(color: Colors.white, shadows: [Shadow(color: kGold.withOpacity(0.9), blurRadius: 18), const Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2))]);
    } else if (st == 2) {
      style = style.copyWith(shadows: [const Shadow(color: Color(0xE6000000), blurRadius: 14, offset: Offset(0, 2)), Shadow(color: kGold.withOpacity(0.4), blurRadius: 8)]);
    }
    Widget t = Text(s, textAlign: TextAlign.center, style: style);
    if (st == 2 && tr == 'kar') {
      // التلوين يصير بفرشاة النص نفسه (foreground shader) بدل قناع الطبقة،
      // فأطراف الحروف النازلة (ي، ع، ج…) تتلوّن صح ولا يطلع أي أثر أبيض تحت الكتابة بأي خط
      final plain = style.copyWith(shadows: const []);
      Widget fillAt(double p) => LayoutBuilder(builder: (_, c) {
            final tp = TextPainter(text: TextSpan(text: s, style: plain), textDirection: TextDirection.rtl, textAlign: TextAlign.center)..layout(maxWidth: c.maxWidth);
            final tw = tp.width, bw = math.max(c.minWidth, tw), ox = (bw - tw) / 2;
            final sh = LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [col, col, Colors.white.withOpacity(0.38), Colors.white.withOpacity(0.38)],
              stops: [0, (p - 0.025).clamp(0.0, 1.0), (p + 0.025).clamp(0.0, 1.0), 1],
            ).createShader(Rect.fromLTWH(ox, 0, math.max(1.0, tw), 10));
            return Text(
              s,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: plain.fontFamily,
                fontFamilyFallback: plain.fontFamilyFallback,
                fontSize: plain.fontSize,
                fontWeight: plain.fontWeight,
                height: plain.height,
                letterSpacing: plain.letterSpacing,
                wordSpacing: plain.wordSpacing,
                foreground: Paint()..shader = sh,
                shadows: const [Shadow(color: Color(0x8C000000), blurRadius: 10, offset: Offset(0, 2))],
              ),
            );
          });
      t = ab == null ? fillAt(kp) : _KarTick(a: ab[0], b: ab[1], build: fillAt);
    }
    if (blur > 0) t = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: t);
    return AnimatedOpacity(
      duration: Duration(milliseconds: tr == 'fade' ? 900 : 600),
      opacity: op,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: 1),
        duration: Duration.zero,
        builder: (_, __, ___) => AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: const Cubic(0.22, 1, 0.36, 1),
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, dy)
            ..setEntry(3, 2, rx == 0 ? 0 : 0.0016)
            ..rotateX(rx)
            ..scale(sc),
          child: Center(child: t),
        ),
      ),
    );
  }
}

/// ورقة «الكلمات ← المظهر» (مثل الويب)
void showLyricsSheet(BuildContext context, List<Lyric> lines) {
  showMSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1612),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => StatefulBuilder(builder: (c, ss) {
      final pc = app.player;
      void u(String k, num v) {
        pc.setPref(k, v);
        ss(() {});
      }

      Widget sec(String s) => Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 10), child: Text(s, style: tx(14, c: Colors.white60)));
      Widget pill(String s, bool on, VoidCallback f, {TextStyle? st}) => GestureDetector(
            onTap: f,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: on ? const Color(0x2EE8C468) : const Color(0x12FFFFFF), border: Border.all(color: on ? kGold : const Color(0x24FFFFFF), width: on ? 1.6 : 1)),
              child: Text(s, style: st ?? tx(14, c: on ? kGold : Colors.white)),
            ),
          );
      const demo = ['السلام عليك يا أبا عبد الله', 'وعلى الأرواح التي حلّت بفنائك', 'عليك منّي سلام الله أبداً', 'ما بقيتُ وبقي الليل والنهار', 'ولا جعله الله آخر العهد منّي'];
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.88,
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 54, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Text('الكلمات', style: tx(19, c: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(c),
                  child: Container(width: 46, height: 46, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: kGold), child: const Center(child: PIcon(Ic.check, color: Color(0xFF2A2106), size: 22))),
                ),
              ]),
            ),
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0x66000000), border: Border.all(color: const Color(0x2EE8C468))),
              child: LyricStrip(key: ValueKey('${pc.lyFont}${pc.lyColor}${pc.lySize}${pc.lyTr}'), lines: [for (var i = 0; i < demo.length; i++) Lyric(i * 2.6, demo[i], false)], base: 20, demo: true),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
                sec('الخط'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < kLF.length; i++) pill(kLF[i].$2, pc.lyFont == i, () => u('lyFont', i), st: TextStyle(fontFamily: kLF[i].$1, fontFamilyFallback: const ['F0'], fontSize: 17, fontWeight: kLF[i].$3 >= 600 ? FontWeight.w700 : FontWeight.w400, color: pc.lyFont == i ? kGold : Colors.white)),
                ]),
                sec('اللون'),
                Wrap(spacing: 14, runSpacing: 12, children: [
                  for (var i = 0; i < kLyCols.length; i++)
                    GestureDetector(
                      onTap: () => u('lyColor', i),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: kLyCols[i], border: Border.all(color: pc.lyColor % kLyCols.length == i ? kGold : Colors.transparent, width: 3))),
                        const SizedBox(height: 4),
                        Text(kLyColN[i], style: tx(11, c: pc.lyColor % kLyCols.length == i ? kGold : Colors.white60)),
                      ]),
                    ),
                ]),
                sec('الحجم  ${(pc.lySize * 100).round()}%'),
                SliderTheme(
                  data: SliderThemeData(activeTrackColor: kGold, inactiveTrackColor: Colors.white24, thumbColor: kGold2, overlayColor: kGold.withOpacity(0.15)),
                  child: Slider(value: pc.lySize.clamp(0.85, 1.2), min: 0.85, max: 1.2, divisions: 35, onChanged: (v) => u('lySize', v)),
                ),
                sec('الانتقال'),
                GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                  children: [
                    for (var i = 0; i < kTRS.length; i++)
                      GestureDetector(
                        onTap: () => u('lyTr', i),
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: pc.lyTr == i ? const Color(0x2EE8C468) : const Color(0x12FFFFFF), border: Border.all(color: pc.lyTr == i ? kGold : const Color(0x24FFFFFF), width: pc.lyTr == i ? 1.6 : 1)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(kTRI[i], size: 22, color: pc.lyTr == i ? kGold : Colors.white70),
                            const SizedBox(height: 4),
                            Text(kTRS[i].$2, style: tx(11, c: pc.lyTr == i ? kGold : Colors.white70)),
                          ]),
                        ),
                      ),
                  ],
                ),
                sec('تقسيم الأسطر الطويلة'),
                Wrap(spacing: 8, children: [pill('تلقائي', pc.lySplit == 1, () => u('lySp', 1)), pill('إيقاف', pc.lySplit == 0, () => u('lySp', 0))]),
                sec('تأخير الكلمات (للسماعات اللاسلكية)'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final v in [0.0, 0.2, 0.4, 0.6, 0.8])
                    pill(v == 0 ? 'بدون' : '$v ث', pc.lyOffset == v, () {
                      pc.setLyOffset(v);
                      ss(() {});
                    }),
                ]),
              ]),
            ),
          ]),
        ),
      );
    }),
  );
}

// للاستعمال لاحقاً
typedef PlayerStateT = PlayerState;

class _KarTick extends StatefulWidget {
  final double a, b;
  final Widget Function(double) build;
  const _KarTick({required this.a, required this.b, required this.build});
  @override
  State<_KarTick> createState() => _KarTickS();
}

class _KarTickS extends State<_KarTick> with SingleTickerProviderStateMixin {
  late final Ticker _t = createTicker((_) {
    if (mounted) setState(() {});
  });
  @override
  void initState() {
    super.initState();
    _t.start();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pl = app.player;
    final t = pl.p.position.inMilliseconds / 1000.0 + pl.lyOffset;
    return widget.build(((t - widget.a) / math.max(0.4, widget.b - widget.a)).clamp(0.0, 1.0));
  }
}
