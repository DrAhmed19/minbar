import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state.dart';
import 'ui.dart';

/// قسم الصوت — معادل 12 نطاقاً (كالويب) يُطبَّق على معادل أندرويد + تعزيز المستوى + طبقة الصوت
final auEq = AndroidEqualizer();
final auLoud = AndroidLoudnessEnhancer();

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
}

Future<void> auSave() async {
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
  showMSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => StatefulBuilder(builder: (c, ss) {
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
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.86,
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 54, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
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
      );
    }),
  );
}

Widget _box(Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: _card, border: Border.all(color: _line)),
      child: child,
    );

SliderThemeData _sth() => SliderThemeData(activeTrackColor: kGold, inactiveTrackColor: Colors.white12, thumbColor: kGold2, overlayColor: kGold.withOpacity(0.15), trackHeight: 5);

List<Widget> _bands(BuildContext c, StateSetter ss, VoidCallback edited) => [
      _box(SizedBox(height: 150, child: CustomPaint(painter: _CurvePainter(), size: Size.infinite))),
      Row(children: [
        Text('التضخيم المسبق', style: tx(14, c: Colors.white)),
        Expanded(
          child: SliderTheme(
            data: _sth(),
            child: Slider(value: au.preamp, min: 0, max: 12, onChanged: (v) {
              au.preamp = v;
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
      _box(SizedBox(
        height: 250,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            for (var i = 0; i < 12; i++)
              Expanded(
                child: Column(children: [
                  Text(au.eq[i].toStringAsFixed(1), style: tx(10, c: kGold)),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: _sth().copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9)),
                        child: Slider(value: au.eq[i], min: -12, max: 12, onChanged: (v) {
                          au.eq[i] = (v * 2).round() / 2;
                          ss(() {});
                        }, onChangeEnd: (_) => edited()),
                      ),
                    ),
                  ),
                  Text(fmtF(kEQF[i]), style: tx(9.5, c: Colors.white54)),
                ]),
              ),
          ]),
        ),
      )),
      Text('يُطبَّق على معادل أندرويد للجهاز (عادة 5 نطاقات)، لذلك يُقرَّب منحنى الـ12 نطاقاً عليه.', style: tx(11.5, c: Colors.white38)),
    ];

class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas x, Size s) {
    final g = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    for (final d in [12, 6, 0, -6, -12]) {
      final y = s.height / 2 - d / 12 * (s.height / 2 - 10);
      x.drawLine(Offset(28, y), Offset(s.width, y), g);
      final tp = TextPainter(text: TextSpan(text: d > 0 ? '+$d' : '$d', style: const TextStyle(fontSize: 10, color: Colors.white54)), textDirection: TextDirection.ltr)..layout();
      tp.paint(x, Offset(0, y - 7));
    }
    final p = Path();
    for (var i = 0; i <= 100; i++) {
      final hz = 20 * math.pow(1000, i / 100).toDouble();
      final px = 28 + (s.width - 28) * i / 100, py = s.height / 2 - eqAt(hz).clamp(-15.0, 15.0) / 12 * (s.height / 2 - 10);
      i == 0 ? p.moveTo(px, py) : p.lineTo(px, py);
    }
    x.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = kGold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

List<Widget> _effects(StateSetter ss, VoidCallback edited) {
  Widget knob(String k, String name) {
    final on = au.on[k] == true;
    return Expanded(
      child: _box(Column(children: [
        GestureDetector(
          onPanUpdate: (d) {
            // تدوير حقيقي حول مركز المقبض (60،55)
            final p = d.localPosition - const Offset(60, 55), q = p - d.delta;
            var da = math.atan2(p.dy, p.dx) - math.atan2(q.dy, q.dx);
            if (da > math.pi) da -= 2 * math.pi;
            if (da < -math.pi) da += 2 * math.pi;
            au.k[k] = (au.k[k]! + da / (math.pi * 1.5) * 100).clamp(0.0, 100.0);
            au.on[k] = au.k[k]! > 0;
            ss(() {});
          },
          onPanEnd: (_) => edited(),
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
      ])),
    );
  }

  return [
    _box(GestureDetector(
      onTap: () {
        au.agc = !au.agc;
        edited();
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [PIcon(Ic.power, color: au.agc ? kGold : Colors.white60, size: 17), const SizedBox(width: 8), Text('التحكم التلقائي بالمستوى', style: tx(15, c: au.agc ? kGold : Colors.white70))]),
    )),
    Row(children: [knob('zb', 'تعزيز الجهير'), const SizedBox(width: 10), knob('cp', 'الضاغط')]),
    Row(children: [knob('zm', 'تعزيز الوسط'), const SizedBox(width: 10), knob('zt', 'تعزيز الحدّة')]),
    _box(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text('التوازن', style: tx(14, c: Colors.white)), const Spacer(), Text(au.bal == 0 ? 'وسط' : (au.bal < 0 ? 'يسار ${(-au.bal * 100).round()}%' : 'يمين ${(au.bal * 100).round()}%'), style: tx(12.5, c: kGold))]),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          Text('L', style: tx(12, c: Colors.white54)),
          Expanded(child: Slider(value: au.bal, min: -1, max: 1, activeColor: kGold, inactiveColor: Colors.white12, onChanged: (v) {
            au.bal = (v.abs() < 0.04 ? 0.0 : v);
            ss(() {});
          }, onChangeEnd: (_) => edited())),
          Text('R', style: tx(12, c: Colors.white54)),
        ]),
      ),
    ])),
    Row(children: [knob('rev', 'صدى القاعة'), const SizedBox(width: 10), knob('wid', 'توسيع الصوت')]),
    Row(children: [knob('rot', 'دوران 8D'), const SizedBox(width: 10), const Expanded(child: SizedBox())]),
    if (!fxOk.every((x) => x)) Text('بعض المؤثرات غير مدعومة على هذا الجهاز.', style: tx(11.5, c: Colors.white38)),
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
        Row(children: [
          Text(lo, style: tx(12, c: Colors.white54)),
          Expanded(child: SliderTheme(data: _sth(), child: Slider(value: v.clamp(mn, mx), min: mn, max: mx, onChanged: f, onChangeEnd: (_) => end()))),
          Text(hi, style: tx(12, c: Colors.white54)),
        ]),
      ]));
  final pc = app.player;
  return [
    row('طبقة الصوت', au.pitch.toStringAsFixed(1), '+12', '-12', -au.pitch, -12, 12, (v) {
      au.pitch = -(v * 2).round() / 2;
      ss(() {});
    }, edited),
    row('سرعة التشغيل', '×${pc.speed.toStringAsFixed(2)}', '2×', '0.5×', 2.5 - pc.speed, 0.5, 2, (v) {
      pc.setSpeed(((2.5 - v) * 20).round() / 20);
      ss(() {});
    }, () {}),
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
