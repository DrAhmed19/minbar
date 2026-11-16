import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analysis.dart';
import 'state.dart';
import 'ui.dart';

/// قسم الصوت — معادل 12 نطاقاً (كالويب) يُطبَّق على معادل أندرويد + تعزيز المستوى + طبقة الصوت
final auEq = AndroidEqualizer();
final auLoud = AndroidLoudnessEnhancer();

/// تحليل القصيدة الحالية (للطيف الحي خلف منحنى المعادل)
Analysis? auAn;

const kEQF = [30, 50, 90, 160, 300, 500, 1000, 1600, 3000, 5000, 9000, 16000];
String fmtF(int f) => f >= 1000 ? '${f % 1000 == 0 ? f ~/ 1000 : (f / 1000)}k' : '$f';

class AuPreset {
  final String id, name;
  final List<double> eq;
  final Map<String, double> k;
  final bool agc;
  const AuPreset(this.id, this.name, this.eq, [this.k = const {}, this.agc = false]);
}

const kAUP = [
  AuPreset('flat', 'مسطّح (الأصلي)', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  AuPreset('vocal', 'وضوح صوت الرادود', [-3, -3, -2, -1, 0, 1, 2.5, 3.5, 4, 3, 1.5, 0], {'cp': 35}),
  AuPreset('bt', 'تعزيز الجهير والحدّة', [5, 4.5, 3.5, 2, 0, -1, -1, 0, 1.5, 3, 4, 4.5]),
  AuPreset('vb', 'الصوت والجهير', [4.5, 4, 3, 1, -0.5, 0, 1.5, 3, 3, 1.5, 0.5, 0]),
  AuPreset('hall', 'صدى القاعة', [1, 1, 0.5, 0, 0, 0, 0.5, 1, 1.5, 1.5, 1, 0.5], {'rev': 45, 'cp': 25}),
  AuPreset('live', 'أداء حي', [2.5, 2.5, 2, 1, 0, 0, 0.5, 1.5, 2, 2, 2, 1.5], {'rev': 22, 'cp': 40, 'wid': 40}),
  AuPreset('speech', 'وضوح الكلام', [-6, -5, -3, -1, 0, 1.5, 3, 4, 3.5, 2, 0, -2], {'cp': 55}, true),
  AuPreset('deep', 'جهير عميق', [7, 6.5, 5, 3, 1, 0, 0, 0, 0, 0.5, 0.5, 0], {'zb': 30}),
  AuPreset('bright', 'حدّة عالية', [0, 0, 0, 0, 0, 0, 1, 2, 3.5, 5, 6, 6], {'zt': 25}),
  AuPreset('night', 'الاستماع الليلي', [-4, -3, -1.5, 0, 0.5, 1, 1, 0.5, 0, -1, -2.5, -4], {'cp': 80}, true),
  AuPreset('radio', 'إذاعي', [-12, -9, -5, -1, 2, 4, 4, 3, 2, 0, -3, -6], {'cp': 70}),
  AuPreset('head', 'سماعات الرأس', [3, 2.5, 1.5, 0, -1, -1, 0, 1, 2, 2.5, 2, 1], {'wid': 30}),
  AuPreset('d8', 'صوت محيطي 8D', [1, 1, 0.5, 0, 0, 0, 0, 0.5, 1, 1, 1, 0.5], {'rev': 15, 'wid': 35, 'rot': 30}),
];

class AuState {
  String pre = 'flat';
  double pitch = 0, preamp = 0;
  bool lim = true, agc = false;
  List<double> eq = List.filled(12, 0);
  double bal = 0;
  Map<String, double> k = {'zb': 0, 'zm': 0, 'zt': 0, 'cp': 0, 'rev': 0, 'wid': 0, 'rot': 0};
  Map<String, bool> on = {'zb': false, 'zm': false, 'zt': false, 'cp': false, 'rev': false, 'wid': false, 'rot': false};

  Map<String, dynamic> toJson() => {'pre': pre, 'pitch': pitch, 'preamp': preamp, 'lim': lim, 'agc': agc, 'bal': bal, 'eq': eq, 'k': k, 'on': on};
  void fromJson(Map m) {
    pre = '${m['pre'] ?? 'flat'}';
    pitch = (m['pitch'] as num?)?.toDouble() ?? 0;
    preamp = (m['preamp'] as num?)?.toDouble() ?? 0;
    lim = m['lim'] != false;
    agc = m['agc'] == true;
    bal = (m['bal'] as num?)?.toDouble() ?? 0;
    final e = m['eq'];
    if (e is List && e.length == 12) eq = [for (final v in e) (v as num).toDouble()];
    final kk = m['k'];
    if (kk is Map) kk.forEach((a, b) => k['$a'] = (b as num).toDouble());
    final o = m['on'];
    if (o is Map) o.forEach((a, b) => on['$a'] = b == true);
  }
}

final au = AuState();
List<Map<String, dynamic>> auCustom = [];

Future<void> auLoad() async {
  final sp = await SharedPreferences.getInstance();
  try {
    final s = sp.getString('au');
    if (s != null) au.fromJson(jsonDecode(s) as Map);
    final c = sp.getString('auCustom');
    if (c != null) auCustom = [for (final x in jsonDecode(c) as List) Map<String, dynamic>.from(x as Map)];
  } catch (_) {}
  app.player.p.androidAudioSessionIdStream.listen((id) {
    if (id != null) auFx();
  });
  app.player.p.durationStream.listen((d) {
    if (d != null) auApply();
  });
  await auApply();
  unawaited(auDevStart());
}

Future<void> auSave() async {
  if (auPerDev) {
    _auDev[auDevKey] = au.toJson();
    SharedPreferences.getInstance().then((sp) => sp.setString('auDev', jsonEncode(_auDev)));
  }
  final sp = await SharedPreferences.getInstance();
  await sp.setString('au', jsonEncode(au.toJson()));
  await sp.setString('auCustom', jsonEncode(auCustom));
}

/// قيمة المعادل عند تردد معيّن (استيفاء لوغاريتمي) + مقابض الجهير/الوسط/الحدّة
double eqAt(double hz) {
  final lf = math.log(hz);
  double g;
  if (hz <= kEQF.first) {
    g = au.eq.first;
  } else if (hz >= kEQF.last) {
    g = au.eq.last;
  } else {
    var i = 0;
    while (kEQF[i + 1] < hz) {
      i++;
    }
    final a = math.log(kEQF[i]), b = math.log(kEQF[i + 1]), f = (lf - a) / (b - a);
    g = au.eq[i] + (au.eq[i + 1] - au.eq[i]) * f;
  }
  double bell(double c, double w) => math.exp(-math.pow((lf - math.log(c)) / w, 2));
  if (au.on['zb'] == true) g += au.k['zb']! / 100 * 9 * (hz < 150 ? 1 : bell(80, 0.9));
  if (au.on['zm'] == true) g += au.k['zm']! / 100 * 7 * bell(1500, 0.8);
  if (au.on['zt'] == true) g += au.k['zt']! / 100 * 9 * (hz > 6000 ? 1 : bell(9000, 0.9));
  return g;
}

int _applyN = 0;
Future<void> auApply() async {
  final my = ++_applyN;
  try {
    final flat = au.eq.every((v) => v == 0) && !au.on.values.any((v) => v);
    await auEq.setEnabled(!flat);
    if (!flat) {
      final ps = await auEq.parameters;
      if (my != _applyN) return;
      for (final b in ps.bands) {
        final g = eqAt(b.centerFrequency).clamp(ps.minDecibels, ps.maxDecibels);
        await b.setGain(g);
      }
    }
    // التضخيم المسبق + الضاغط/التحكم التلقائي ← تعزيز المستوى
    var boost = au.preamp;
    if (au.on['cp'] == true) boost += au.k['cp']! / 100 * 4;
    if (au.agc) boost += 2;
    if (au.lim) boost = math.min(boost, 9.0);
    await auLoud.setEnabled(boost > 0.05);
    if (boost > 0.05) await auLoud.setTargetGain(boost);
    await app.player.p.setPitch(math.pow(2, au.pitch / 12).toDouble());
  } catch (_) {}
  await auFx();
}

/// مؤثرات أندرويد الأصلية: التوسيع، صدى القاعة، التوازن، والدوران 8D (توازن متحرك)
const _fx = MethodChannel('minbar/fx');
List<bool> fxOk = const [true, true, true];
Timer? _rotT;
Future<void> auFx() async {
  try {
    final s = app.player.p.androidAudioSessionId;
    if (s == null) return;
    final r = await _fx.invokeMethod('attach', {'s': s});
    if (r is List) fxOk = [for (final x in r) x == true];
    final w = au.on['wid'] == true ? (au.k['wid']! * 10).round() : 0;
    await _fx.invokeMethod('virt', {'v': w});
    final rv = au.on['rev'] == true ? au.k['rev']! : 0.0;
    await _fx.invokeMethod('rev', {'v': rv <= 0 ? 0 : (rv < 25 ? 1 : (rv < 50 ? 2 : (rv < 75 ? 4 : 5)))});
    _rotT?.cancel();
    if (au.on['rot'] == true && au.k['rot']! > 0) {
      final t0 = DateTime.now();
      _rotT = Timer.periodic(const Duration(milliseconds: 90), (_) {
        final t = DateTime.now().difference(t0).inMilliseconds / 1000;
        _bal(au.bal + math.sin(t * 2 * math.pi / 8) * au.k['rot']! / 100);
      });
    } else {
      await _bal(au.bal);
    }
  } catch (_) {}
}

Future<void> _bal(double b) async {
  b = b.clamp(-1.0, 1.0);
  double db(double x) => x <= 0.001 ? -60 : 20 * math.log(x) / math.ln10;
  try {
    await _fx.invokeMethod('bal', {'l': b > 0 ? db(1 - b) : 0.0, 'r': b < 0 ? db(1 + b) : 0.0});
  } catch (_) {}
}

void auPreset(String id) {
  final c = auCustom.where((x) => x['id'] == id);
  if (c.isNotEmpty) {
    final m = c.first;
    au.fromJson(m['s'] as Map);
    au.pre = id;
  } else {
    final p = kAUP.firstWhere((x) => x.id == id, orElse: () => kAUP.first);
    au.pre = p.id;
    au.eq = List.of(p.eq);
    au.agc = p.agc;
    au.preamp = 0;
    au.bal = 0;
    for (final key in au.k.keys.toList()) {
      au.k[key] = p.k[key] ?? 0;
      au.on[key] = (p.k[key] ?? 0) > 0;
    }
  }
  auApply();
  auSave();
}

String auPresetName() {
  for (final p in kAUP) {
    if (p.id == au.pre) return p.name;
  }
  for (final c in auCustom) {
    if (c['id'] == au.pre) return '${c['name']}';
  }
  return 'مخصّص';
}

// ================= الواجهة =================
const _bg = Color(0xFF1C1612), _card = Color(0x0FFFFFFF), _line = Color(0x24FFFFFF);

void showAudioSheet(BuildContext context) {
  var tab = 0;
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (c, _, __) => StatefulBuilder(builder: (c, ss) {
      void ch() {
        au.pre = kAUP.any((p) => p.id == au.pre) || auCustom.any((x) => x['id'] == au.pre) ? au.pre : 'custom';
        auApply();
        auSave();
        ss(() {});
      }

      void edited() {
        au.pre = 'custom';
        ch();
      }

      Widget sq(String ic, VoidCallback f) => GestureDetector(
            onTap: f,
            child: Container(width: 46, height: 46, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _card, border: Border.all(color: _line)), child: Center(child: PIcon(ic, color: Colors.white, size: 21))),
          );
      final tabs = ['النطاقات', 'المؤثرات', 'متقدّم'];
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(children: [
                Text('الصوت', style: tx(20, c: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await _presetsSheet(c);
                      ss(() {});
                    },
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _card, border: Border.all(color: _line)),
                      child: Row(children: [
                        Expanded(child: Text(auPresetName(), maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14.5, c: Colors.white))),
                        const PIcon(Ic.down, color: kGold, size: 18),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                sq(Ic.reset, () {
                  auPreset('flat');
                  ss(() {});
                }),
                sq(Ic.x, () => Navigator.pop(c)),
              ]),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x66000000)),
              child: Row(children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ss(() => tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: tab == i ? kGold : Colors.transparent),
                        child: Center(child: Text(tabs[i], style: tx(15, c: tab == i ? const Color(0xFF2A2106) : Colors.white))),
                      ),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
                if (tab == 0) ..._bands(c, ss, edited),
                if (tab == 1) ..._effects(ss, edited),
                if (tab == 2) ..._adv(ss, edited),
              ]),
            ),
          ]),
          ),
        ),
      );
    }),
      transitionsBuilder: (_, a, __, ch) => SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: ch),
    ),
  );
}

Widget _box(Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: _card, border: Border.all(color: const Color(0x14FFFFFF))),
      child: child,
    );

SliderThemeData _sth() => SliderThemeData(activeTrackColor: kGold, inactiveTrackColor: Colors.white12, thumbColor: kGold2, overlayColor: kGold.withOpacity(0.15), trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 3), overlayShape: const RoundSliderOverlayShape(overlayRadius: 26));

List<Widget> _bands(BuildContext c, StateSetter ss, VoidCallback edited) => [
      Container(
        height: 170,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0xFF07120D), border: Border.all(color: const Color(0xFF1F3A2C)), boxShadow: const [BoxShadow(color: Color(0x1F2FBF8F), blurRadius: 18, spreadRadius: -6)]),
        child: IgnorePointer(child: EqGraph(onChange: () {}, onEnd: () {})),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Text('التضخيم المسبق', style: tx(14, c: Colors.white)),
        Expanded(
          child: SliderTheme(
            data: _sth(),
            child: Slider(value: au.preamp, min: 0, max: 12, onChanged: (v) {
              au.preamp = auSnap(v, 0, 12);
              ss(() {});
            }, onChangeEnd: (_) => edited()),
          ),
        ),
        Text('${au.preamp.toStringAsFixed(1)} dB', style: tx(13, c: kGold)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            au.lim = !au.lim;
            edited();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: au.lim ? const Color(0x2EE8C468) : _card, border: Border.all(color: au.lim ? kGold : _line)),
            child: Row(children: [PIcon(Ic.power, color: au.lim ? kGold : Colors.white54, size: 15), const SizedBox(width: 5), Text('المحدِّد', style: tx(13, c: au.lim ? kGold : Colors.white54))]),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      const SizedBox(height: 10),
      EqConsole(onChange: () => ss(() {}), onEnd: edited),
      const SizedBox(height: 8),
      Text('يُطبَّق على معادل أندرويد للجهاز (عادة 5 نطاقات)، لذلك يُقرَّب منحنى الـ12 نطاقاً عليه.', style: tx(11.5, c: Colors.white38)),
    ];

/// منحنى المعادل مثل الويب: شبكة بالترددات، نقاط النطاقات (تُسحب للأعلى والأسفل)، والطيف الحي خلفه أثناء التشغيل
const _cl = 30.0, _cb = 20.0;
double _gxF(double hz, double w) => _cl + (w - _cl - 8) * (math.log(hz / 20) / math.log(1000));
double _gy(double g, double h) => (h - _cb) / 2 - g / 12 * ((h - _cb) / 2 - 10);

class EqGraph extends StatefulWidget {
  final VoidCallback onChange, onEnd;
  const EqGraph({super.key, required this.onChange, required this.onEnd});
  @override
  State<EqGraph> createState() => _EqGraphState();
}

class _EqGraphState extends State<EqGraph> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final _raw = List<double>.filled(22, 0), _v = List<double>.filled(22, 0);
  int? _drag;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _at(Offset o, Size s, {bool start = false}) {
    if (start) {
      var best = 0, bd = 1e9;
      for (var i = 0; i < kEQF.length; i++) {
        final d = (_gxF(kEQF[i].toDouble(), s.width) - o.dx).abs();
        if (d < bd) {
          bd = d;
          best = i;
        }
      }
      _drag = best;
    }
    final i = _drag;
    if (i == null) return;
    final half = (s.height - _cb) / 2 - 10;
    final g = (((s.height - _cb) / 2 - o.dy) / half * 12).clamp(-12.0, 12.0);
    au.eq[i] = (g * 10).round() / 10;
    au.pre = 'custom';
    widget.onChange();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) {
          final sz = Size(c.maxWidth, c.maxHeight);
          return GestureDetector(
            onPanStart: (d) => _at(d.localPosition, sz, start: true),
            onPanUpdate: (d) => _at(d.localPosition, sz),
            onPanEnd: (_) {
              _drag = null;
              widget.onEnd();
            },
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, __) {
                final pl = app.player.p;
                if (pl.playing && auAn != null) {
                  auAn!.bandsAt(pl.position.inMilliseconds / 1000.0, _raw);
                } else {
                  _raw.fillRange(0, 22, 0);
                }
                for (var k = 0; k < 22; k++) {
                  _v[k] += (_raw[k] - _v[k]) * (_raw[k] > _v[k] ? 0.45 : 0.12);
                }
                return CustomPaint(painter: _CurvePainter(_v, _drag), size: sz);
              },
            ),
          );
        },
      );
}

class _CurvePainter extends CustomPainter {
  final List<double> sp;
  final int? hot;
  _CurvePainter(this.sp, this.hot);
  @override
  void paint(Canvas x, Size s) {
    final w = s.width, h = s.height;
    final g = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    // الطيف الحي
    final bw = (w - _cl - 8) / sp.length;
    for (var k = 0; k < sp.length; k++) {
      final v = sp[k].clamp(0.0, 1.0);
      if (v < 0.01) continue;
      final top = _gy(-12 + v * 20, h);
      x.drawRect(Rect.fromLTRB(_cl + k * bw, top, _cl + (k + 1) * bw - 1, _gy(-12, h)), Paint()..color = const Color(0xFF2FBF8F).withOpacity(0.18 + v * 0.18));
    }
    for (final d in [12, 6, 0, -6, -12]) {
      final y = _gy(d.toDouble(), h);
      x.drawLine(Offset(_cl, y), Offset(w, y), g);
      final tp = TextPainter(text: TextSpan(text: d > 0 ? '+$d' : '$d', style: const TextStyle(fontSize: 10, color: Colors.white54)), textDirection: TextDirection.ltr)..layout();
      tp.paint(x, Offset(0, y - 7));
    }
    for (var i = 0; i < kEQF.length; i++) {
      final px = _gxF(kEQF[i].toDouble(), w);
      x.drawLine(Offset(px, 4), Offset(px, h - _cb), g);
      if (i.isEven || i == kEQF.length - 1) {
        final tp = TextPainter(text: TextSpan(text: fmtF(kEQF[i]), style: const TextStyle(fontSize: 10, color: Colors.white54)), textDirection: TextDirection.ltr)..layout();
        tp.paint(x, Offset(px - tp.width / 2, h - _cb + 4));
      }
    }
    final p = Path();
    for (var i = 0; i <= 100; i++) {
      final hz = 20 * math.pow(1000, i / 100).toDouble();
      final px = _gxF(hz, w), py = _gy(eqAt(hz).clamp(-15.0, 15.0), h);
      i == 0 ? p.moveTo(px, py) : p.lineTo(px, py);
    }
    x.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = kGold);
    for (var i = 0; i < kEQF.length; i++) {
      final c = Offset(_gxF(kEQF[i].toDouble(), w), _gy(au.eq[i], h));
      x.drawCircle(c, hot == i ? 8 : 5.5, Paint()..color = kGold);
      x.drawCircle(c, hot == i ? 8 : 5.5, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF1C1612));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

Widget _knob(StateSetter ss, VoidCallback edited, String k, String name) {
  final on = au.on[k] == true;
  return Expanded(
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: on ? const Color(0x14E8C468) : _card, border: Border.all(color: on ? const Color(0x59E8C468) : const Color(0x14FFFFFF))),
      child: Column(children: [
      RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _WinPan: GestureRecognizerFactoryWithHandlers<_WinPan>(() => _WinPan(), (r) {
            r
              ..dragStartBehavior = DragStartBehavior.down
              ..onUpdate = (d) {
          // تدوير حقيقي حول مركز المقبض (60،55)
          final p = d.localPosition - const Offset(60, 55), q = p - d.delta;
          var da = math.atan2(p.dy, p.dx) - math.atan2(q.dy, q.dx);
          if (da > math.pi) da -= 2 * math.pi;
          if (da < -math.pi) da += 2 * math.pi;
          au.k[k] = (au.k[k]! + da / (math.pi * 1.5) * 100).clamp(0.0, 100.0);
          au.on[k] = au.k[k]! > 0;
          ss(() {});
        }
              ..onEnd = (_) => edited();
          }),
        },
        child: SizedBox(width: 120, height: 110, child: CustomPaint(painter: _KnobPainter(au.k[k]! / 100, on))),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () {
          au.on[k] = !on;
          if (au.on[k]! && au.k[k] == 0) au.k[k] = 40;
          edited();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: on ? const Color(0x2EE8C468) : Colors.transparent, border: Border.all(color: on ? kGold : _line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [PIcon(Ic.power, color: on ? kGold : Colors.white60, size: 15), const SizedBox(width: 6), Text(name, style: tx(13.5, c: on ? kGold : Colors.white70))]),
        ),
      ),
    ]),
    ),
  );
}

List<Widget> _effects(StateSetter ss, VoidCallback edited) {
  Widget knob(String k, String name) => _knob(ss, edited, k, name);

  return [
    _box(GestureDetector(
      onTap: () {
        au.agc = !au.agc;
        edited();
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [PIcon(Ic.power, color: au.agc ? kGold : Colors.white60, size: 17), const SizedBox(width: 8), Text('التحكم التلقائي بالمستوى', style: tx(15, c: au.agc ? kGold : Colors.white70))]),
    )),
    _box(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text('التوازن', style: tx(14, c: Colors.white)), const Spacer(), Text(au.bal == 0 ? 'الوسط' : (au.bal < 0 ? 'يسار ${(-au.bal * 100).round()}%' : 'يمين ${(au.bal * 100).round()}%'), style: tx(12.5, c: kGold))]),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          Text('يسار', style: tx(12, c: Colors.white54)),
          Expanded(child: Slider(value: au.bal, min: -1, max: 1, divisions: 100, activeColor: kGold, inactiveColor: Colors.white12, onChanged: (v0) {
            final v = auSnap(v0, 0, 2);
            au.bal = (v.abs() < 0.04 ? 0.0 : v);
            ss(() {});
          }, onChangeEnd: (_) => edited())),
          Text('يمين', style: tx(12, c: Colors.white54)),
        ]),
      ),
    ])),
    Row(children: [knob('zb', 'تعزيز الجهير'), const SizedBox(width: 10), knob('cp', 'الضاغط')]),
    Row(children: [knob('zm', 'تعزيز الوسط'), const SizedBox(width: 10), knob('zt', 'تعزيز الحدّة')]),

  ];
}

class _KnobPainter extends CustomPainter {
  final double v;
  final bool on;
  _KnobPainter(this.v, this.on);
  @override
  void paint(Canvas x, Size s) {
    final c = Offset(s.width / 2, s.height / 2), r = math.min(s.width, s.height) / 2 - 8;
    const a0 = math.pi * 0.75, sw = math.pi * 1.5;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white10;
    x.drawArc(Rect.fromCircle(center: c, radius: r), a0, sw, false, bg);
    if (v > 0) x.drawArc(Rect.fromCircle(center: c, radius: r), a0, sw * v, false, bg..color = on ? kGold : Colors.white30);
    final a = a0 + sw * v;
    x.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 10, Paint()..color = on ? kGold2 : Colors.grey);
    final tp = TextPainter(text: TextSpan(text: '${(v * 100).round()}', style: TextStyle(fontSize: 26, color: on ? Colors.white : Colors.white54)), textDirection: TextDirection.ltr)..layout();
    tp.paint(x, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _KnobPainter o) => o.v != v || o.on != on;
}

List<Widget> _adv(StateSetter ss, VoidCallback edited) {
  Widget row(String t, String val, String lo, String hi, double v, double mn, double mx, ValueChanged<double> f, VoidCallback end) => _box(Column(children: [
        Row(children: [Text(t, style: tx(15, c: Colors.white)), const Spacer(), Text(val, style: tx(14, c: kGold))]),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            Text(lo, style: tx(12, c: Colors.white54)),
            Expanded(child: SliderTheme(data: _sth(), child: Slider(value: v.clamp(mn, mx), min: mn, max: mx, onChanged: (x) => f(mn < 0 && mx > 0 ? auSnap(x, 0, mx - mn) : (mn == 0.5 && mx == 2 ? auSnap(x, 1, 1.5) : x)), onChangeEnd: (_) => end()))),
            Text(hi, style: tx(12, c: Colors.white54)),
          ]),
        ),
      ]));
  final pc = app.player;
  return [
    row('طبقة الصوت', au.pitch.toStringAsFixed(1), '-12', '+12', au.pitch, -12, 12, (v) {
      au.pitch = (v * 10).round() / 10;
      ss(() {});
    }, edited),
    row('سرعة التشغيل', '×${pc.speed.toStringAsFixed(2)}', '0.5×', '2×', pc.speed, 0.5, 2, (v) {
      pc.setSpeed((v * 20).round() / 20);
      ss(() {});
    }, () {}),
    Row(children: [_knob(ss, edited, 'rev', 'الترديد'), const SizedBox(width: 10), _knob(ss, edited, 'wid', 'اتساع المجال')]),
    Row(children: [_knob(ss, edited, 'rot', 'الدوران 8D'), const SizedBox(width: 10), const Expanded(child: SizedBox())]),
    if (!fxOk.every((x) => x)) Text('بعض المؤثرات غير مدعومة على هذا الجهاز.', style: tx(11.5, c: Colors.white38)),
    _box(GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await auSetPerDev(!auPerDev);
        ss(() {});
      },
      child: Row(children: [
        PIcon(Ic.power, color: auPerDev ? kGold : Colors.white54, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('إعداد خاص لكل جهاز', style: tx(14.5, c: auPerDev ? kGold : Colors.white)),
          Text('يتذكّر إعداد سماعة الهاتف والسلكية والبلوتوث كلٌّ على حدة — الآن: ${kDevName[auDevKey]}', style: tx(11, c: Colors.white54)),
        ])),
      ]),
    )),
  ];
}

Future<void> _presetsSheet(BuildContext context) async {
  final nameC = TextEditingController();
  await showMSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF13362C),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => StatefulBuilder(builder: (c, ss) {
      Widget item(String id, String name, {bool del = false}) => InkWell(
            onTap: () {
              auPreset(id);
              Navigator.pop(c);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF)))),
              child: Row(children: [
                Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: au.pre == id ? kGold : Colors.white38, width: 2)), child: au.pre == id ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: kGold))) : null),
                const SizedBox(width: 14),
                Expanded(child: Text(name, style: tx(16, c: au.pre == id ? kGold : Colors.white))),
                if (del)
                  GestureDetector(
                    onTap: () {
                      auCustom.removeWhere((x) => x['id'] == id);
                      auSave();
                      ss(() {});
                    },
                    child: const PIcon(Ic.x, color: Colors.white54, size: 18),
                  ),
              ]),
            ),
          );
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(c).size.height * 0.8,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: Row(children: [
                  Text('الإعدادات المسبقة', style: tx(19, c: Colors.white)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(c), child: const PIcon(Ic.x, color: Colors.white, size: 22)),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                  for (final p in kAUP) item(p.id, p.name),
                  for (final cst in auCustom) item('${cst['id']}', '${cst['name']}', del: true),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: nameC,
                      style: tx(14, c: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'اسم الإعداد',
                        hintStyle: tx(14, c: Colors.white38),
                        filled: true,
                        fillColor: const Color(0x1AFFFFFF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      final n = nameC.text.trim();
                      if (n.isEmpty) return;
                      final id = 'c${DateTime.now().millisecondsSinceEpoch}';
                      au.pre = id;
                      auCustom.add({'id': id, 'name': n, 's': au.toJson()});
                      auSave();
                      nameC.clear();
                      ss(() {});
                    },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: kGold), child: Text('حفظ الحالي', style: tx(15, c: const Color(0xFF2A2106)))),
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


// ================= إعداد صوت خاص لكل جهاز إخراج =================
bool auPerDev = false;
String auDevKey = 'spk';
Map<String, dynamic> _auDev = {};
const kDevName = {'spk': 'سماعة الهاتف', 'wired': 'سماعة سلكية', 'bt': 'بلوتوث (سماعة/سيارة)'};

String _devKeyOf(Set<AudioDevice> ds) {
  final t = ds.where((d) => d.isOutput).map((d) => d.type.toString().toLowerCase()).join(',');
  if (t.contains('bluetooth') || t.contains('ble')) return 'bt';
  if (t.contains('wired') || t.contains('usb') || t.contains('headset') || t.contains('headphones')) return 'wired';
  return 'spk';
}

Future<void> auDevStart() async {
  try {
    final sp = await SharedPreferences.getInstance();
    auPerDev = sp.getBool('auPerDev') ?? false;
    try {
      _auDev = Map<String, dynamic>.from(jsonDecode(sp.getString('auDev') ?? '{}') as Map);
    } catch (_) {}
    final s = await AudioSession.instance;
    auDevKey = _devKeyOf(await s.getDevices(includeInputs: false));
    s.devicesChangedEventStream.listen((_) async {
      final k = _devKeyOf(await s.getDevices(includeInputs: false));
      if (k == auDevKey) return;
      final old = auDevKey;
      auDevKey = k;
      if (!auPerDev) return;
      _auDev[old] = au.toJson();
      final m = _auDev[k];
      if (m is Map) au.fromJson(m);
      await sp.setString('auDev', jsonEncode(_auDev));
      await auSave();
      await auApply();
    });
  } catch (_) {}
}

Future<void> auSetPerDev(bool v) async {
  auPerDev = v;
  final sp = await SharedPreferences.getInstance();
  await sp.setBool('auPerDev', v);
  if (v) {
    _auDev[auDevKey] = au.toJson();
    await sp.setString('auDev', jsonEncode(_auDev));
  }
}


/// التصاق المنزلق بقيمته الطبيعية عند الاقتراب منها
double auSnap(double v, double def, double span) {
  if ((v - def).abs() < span * 0.045) {
    if (v != def) HapticFeedback.selectionClick();
    return def;
  }
  return v;
}

/// لوحة استوديو: 12 قناة، لكل قناة عدّاد LED حي + شاشة قيمة + فيدر معدني + ملصق التردد
class EqConsole extends StatefulWidget {
  final VoidCallback onChange, onEnd;
  const EqConsole({super.key, required this.onChange, required this.onEnd});
  @override
  State<EqConsole> createState() => _EqConsoleState();
}

class _EqConsoleState extends State<EqConsole> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final _raw = List<double>.filled(22, 0);
  final _lv = List<double>.filled(12, 0);
  final _snapped = List<bool>.filled(12, false);
  final _acc = List<double>.filled(12, 0);

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _tick() {
    final pl = app.player.p;
    if (pl.playing && auAn != null) {
      auAn!.bandsAt(pl.position.inMilliseconds / 1000.0, _raw);
    } else {
      _raw.fillRange(0, 22, 0);
    }
    for (var i = 0; i < 12; i++) {
      final bn = (math.log(kEQF[i] / 40) / math.log(400) * 22).round().clamp(0, 21);
      final v = _raw[bn];
      _lv[i] = v > _lv[i] ? v : _lv[i] * 0.9;
    }
  }

  void _drag(int i, double dy, double h) {
    _acc[i] += -dy / h * 24;
    var v = _acc[i].clamp(-12.0, 12.0);
    if (v.abs() < 1.1) {
      if (!_snapped[i]) {
        _snapped[i] = true;
        HapticFeedback.selectionClick();
      }
      v = 0;
    } else {
      _snapped[i] = false;
    }
    au.eq[i] = (v * 10).round() / 10;
    au.pre = 'custom';
    widget.onChange();
  }

  Widget _ch(int i) {
    return LayoutBuilder(builder: (_, c) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF1D1813), border: Border.all(color: const Color(0xFF2A2219))),
        child: Column(children: [
          SizedBox(width: 8, height: 44, child: CustomPaint(painter: _LedPainter(_lv[i]))),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF07120D), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF1F3A2C))),
            child: FittedBox(child: Text('${au.eq[i] > 0 ? '+' : ''}${au.eq[i].toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF7BE2B8), fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(builder: (_, fc) {
              final h = fc.maxHeight;
              return RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  _WinVDrag: GestureRecognizerFactoryWithHandlers<_WinVDrag>(() => _WinVDrag(), (r) {
                    r
                      ..dragStartBehavior = DragStartBehavior.down
                      ..onStart = (_) {
                        _acc[i] = au.eq[i];
                        _snapped[i] = false;
                      }
                      ..onUpdate = (d) => _drag(i, d.delta.dy, h - 13)
                      ..onEnd = (_) {
                        _snapped[i] = false;
                        widget.onEnd();
                      };
                  }),
                  DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(() => DoubleTapGestureRecognizer(), (r) {
                    r.onDoubleTap = () {
                      au.eq[i] = 0;
                      au.pre = 'custom';
                      widget.onChange();
                      widget.onEnd();
                    };
                  }),
                },
                child: CustomPaint(size: Size(fc.maxWidth, h), painter: _FaderPainter(au.eq[i], _snapped[i])),
              );
            }),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF26201A), borderRadius: BorderRadius.circular(4)),
            child: FittedBox(child: Text(fmtF(kEQF[i]), style: tx(9, c: const Color(0xFFB3A78F)))),
          ),
        ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 320,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B1611), Color(0xFF120E0A)]),
          border: Border.all(color: const Color(0xFF2F271F)),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedBuilder(
            animation: _t,
            builder: (_, __) {
              _tick();
              return Row(children: [for (var i = 0; i < 12; i++) Expanded(child: _ch(i))]);
            },
          ),
        ),
      );
}

class _LedPainter extends CustomPainter {
  final double lv;
  _LedPainter(this.lv);
  @override
  void paint(Canvas c, Size s) {
    const n = 9;
    final sh = s.height / n;
    for (var k = 0; k < n; k++) {
      final fromTop = k / n;
      final col = fromTop < 0.14 ? const Color(0xFFE0503C) : fromTop < 0.36 ? const Color(0xFFE8C468) : const Color(0xFF2FBF8F);
      final on = (1 - fromTop) <= lv + 0.02;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, k * sh, s.width, sh - 2), const Radius.circular(1)), Paint()..color = on ? col : col.withOpacity(0.15));
    }
  }

  @override
  bool shouldRepaint(_LedPainter o) => o.lv != lv;
}

class _FaderPainter extends CustomPainter {
  final double v;
  final bool snap;
  _FaderPainter(this.v, this.snap);
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2, top = 6.5, bot = s.height - 6.5;
    final y = top + (12 - v) / 24 * (bot - top), y0 = (top + bot) / 2;
    for (var k = 0; k <= 8; k++) {
      final ty = top + k * (bot - top) / 8;
      c.drawLine(Offset(cx + 6, ty), Offset(cx + 9, ty), Paint()..color = const Color(0xFF6F6450)..strokeWidth = 1);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - 2, top, cx + 2, bot), const Radius.circular(2)), Paint()..color = const Color(0xFF050403));
    c.drawLine(Offset(cx - 9, y0), Offset(cx + 9, y0), Paint()..color = Colors.white38..strokeWidth = 1);
    if (v != 0) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - 2, math.min(y, y0), cx + 2, math.max(y, y0)), const Radius.circular(2)), Paint()..color = const Color(0xCCE8C468));
    }
    final cap = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y), width: math.min(22, s.width - 4), height: 13), const Radius.circular(3));
    if (snap) c.drawRRect(cap.inflate(3), Paint()..color = const Color(0x737BE2B8));
    c.drawRRect(cap.shift(const Offset(0, 2)), Paint()..color = Colors.black54);
    c.drawRRect(cap, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE6DFCC), Color(0xFFA9A08A)]).createShader(cap.outerRect));
    c.drawRect(Rect.fromCenter(center: Offset(cx, y), width: math.min(18, s.width - 8), height: 2), Paint()..color = const Color(0xFFD2553F));
  }

  @override
  bool shouldRepaint(_FaderPainter o) => o.v != v || o.snap != snap;
}


/// يفوز دائماً على تمرير الصفحة: اللمس على الفيدر أو المقبض ما يحرّك الصفحة
class _WinVDrag extends VerticalDragGestureRecognizer {
  _WinVDrag() {
    gestureSettings = const DeviceGestureSettings(touchSlop: 2);
  }
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void rejectGesture(int pointer) => acceptGesture(pointer);
}

class _WinPan extends PanGestureRecognizer {
  _WinPan() {
    gestureSettings = const DeviceGestureSettings(touchSlop: 2);
  }
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void rejectGesture(int pointer) => acceptGesture(pointer);
}
