import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'car.dart';
import 'state.dart';
import 'ui.dart';

/// فتح وضع السيارة تلقائياً عند الاتصال ببلوتوث السيارة.
/// أول مرة يتصل جهاز صوتي جديد نسأل: «هل هذه سيارتك؟» ونتذكر الجواب.
class CarAuto with WidgetsBindingObserver {
  static final CarAuto I = CarAuto._();
  CarAuto._();
  static const _ch = MethodChannel('minbar/fx');
  Timer? _t;
  String? _last;
  bool _asking = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _t = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    Future.delayed(const Duration(seconds: 4), _check);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _t?.cancel();
      _t = Timer.periodic(const Duration(seconds: 5), (_) => _check());
      _check(resumed: true);
    } else if (s == AppLifecycleState.paused) {
      _t?.cancel();
    }
  }

  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();
  static Future<List<String>> cars() async => (await _p).getStringList('car.bt') ?? [];
  static Future<bool> enabled() async => (await _p).getBool('car.btAuto') ?? true;
  static Future<void> setEnabled(bool v) async => (await _p).setBool('car.btAuto', v);
  static Future<void> forget(String n) async {
    final p = await _p;
    p.setStringList('car.bt', (p.getStringList('car.bt') ?? [])..remove(n));
  }

  Future<void> _check({bool resumed = false}) async {
    String? name;
    try {
      name = await _ch.invokeMethod<String>('btOut');
    } catch (_) {}
    final prev = _last;
    _last = name;
    if (name == null || name.isEmpty) {
      if (prev != null && prev.isNotEmpty) resetShown();
      return;
    }
    // يفتح عند الاتصال الجديد، أو عند الرجوع للتطبيق وهو متصل (أندرويد يمنع الفتح من الخلفية)
    if (name == prev && !resumed) return;
    if (CarPage.open || !await enabled()) return;
    final p = await _p;
    final known = p.getStringList('car.bt') ?? [], no = p.getStringList('car.btNo') ?? [];
    if (known.contains(name)) {
      if (resumed && name == prev && p.getBool('car.btShown.$name') == true) return;
      p.setBool('car.btShown.$name', true);
      _openCar();
      return;
    }
    if (no.contains(name) || _asking) return;
    final ctx = kNav.currentContext;
    if (ctx == null) return;
    _asking = true;
    final yes = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text('اتصلت بـ «$name»', style: tx(17, w: FontWeight.w700)),
        content: Text('هل هذا بلوتوث سيارتك؟ إذا نعم، يفتح وضع السيارة تلقائياً كلما اتصلت به.', style: tx(14, h: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('لا', style: tx(14))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text('نعم، سيارتي', style: tx(14, c: Colors.white))),
        ],
      ),
    );
    _asking = false;
    if (yes == true) {
      p.setStringList('car.bt', [...known, name]);
      p.setBool('car.btShown.$name', true);
      _openCar();
    } else if (yes == false) {
      p.setStringList('car.btNo', [...no, name]);
    }
  }

  void _openCar() {
    final nav = kNav.currentState;
    if (nav == null || CarPage.open) return;
    nav.push(MaterialPageRoute(builder: (_) => const CarPage()));
  }

  /// عند فصل البلوتوث نسمح بالفتح مجدداً بالاتصال القادم
  void resetShown() async {
    final p = await _p;
    for (final k in p.getKeys().where((k) => k.startsWith('car.btShown.'))) {
      p.remove(k);
    }
  }
}
