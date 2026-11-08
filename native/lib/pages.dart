import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// ========== الافتتاح + الدخول ==========
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  final DateTime _t0 = DateTime.now();
  bool _minDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _minDone = true);
    });
    app.auth.addListener(_r);
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    app.auth.removeListener(_r);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = app.auth;
    final ready = _minDone && a.state != AuthState.init && a.state != AuthState.loading;
    if (ready && a.isIn) return const HomeShell();
    if (!ready) return _splash();
    return LoginPage(onRetry: () => setState(() {}));
  }

  Widget _splash() => Scaffold(
        backgroundColor: kDeep,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.25), radius: 1.2, colors: [Color(0xFF0F4A38), Color(0xFF072A20), Color(0xFF03140F)]),
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final el = DateTime.now().difference(_t0).inMilliseconds / 1000.0;
                  return SizedBox(width: 128, height: 138, child: CustomPaint(painter: LogoPainter(_c.value, draw: (el / 1.1).clamp(0.0, 1.0))));
                },
              ),
              const SizedBox(height: 6),
              Text('منبر', style: tx(54, w: FontWeight.w800, c: const Color(0xFFF3EAD0))),
              const SizedBox(height: 6),
              Text('صوت المنبر', style: tx(15, c: const Color(0xFF9FBDB0))),
            ]),
          ),
        ),
      );
}

class LoginPage extends StatelessWidget {
  final VoidCallback onRetry;
  const LoginPage({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final a = app.auth;
    Widget body;
    switch (a.state) {
      case AuthState.form:
        body = Column(children: [
          Text('مرحباً ${a.user?.displayName ?? ''}', style: tx(16, c: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('التطبيق قيد التطوير. سجّل مسبقاً بحسابك وسيتم اختيار عدد محدود من المستخدمين لتجربته.',
              style: tx(13, w: FontWeight.w500, c: const Color(0xFF8FA69B), h: 1.7), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          GoldButton('تسجيل مسبق', a.register),
          const SizedBox(height: 10),
          GoldButton('الدخول كضيف', a.enterGuest, outline: true),
          const SizedBox(height: 6),
          TextButton(onPressed: a.signOut, child: Text('تغيير الحساب', style: tx(13, c: const Color(0xFF8FA69B)))),
        ]);
        break;
      case AuthState.wait:
      case AuthState.rejected:
        body = Column(children: [
          PIcon(a.state == AuthState.wait ? Ic.timer : Ic.heart, color: kGold, size: 36),
          const SizedBox(height: 10),
          Text(
              a.state == AuthState.rejected
                  ? 'نشكر لك اهتمامك. لم يتم اختيارك ضمن مرحلة التجربة الحالية، وسنوافيك عند الإطلاق العام.'
                  : 'تم تسجيلك في قائمة الانتظار. عند اختيارك ستدخل تلقائياً بنفس الحساب.',
              style: tx(13.5, w: FontWeight.w500, c: const Color(0xFFCBD8D1), h: 1.8),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          GoldButton('الدخول كضيف', a.enterGuest),
          const SizedBox(height: 6),
          TextButton(onPressed: a.signOut, child: Text('تغيير الحساب', style: tx(13, c: const Color(0xFF8FA69B)))),
        ]);
        break;
      default:
        body = Column(children: [
          GoldButton('الدخول بحساب Google', a.google, icon: Ic.users),
          const SizedBox(height: 10),
          GoldButton('الدخول كضيف', a.enterGuest, outline: true),
          if (a.error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(a.error, style: tx(12.5, c: const Color(0xFFE8A0A0)), textAlign: TextAlign.center),
          ],
        ]);
    }
    return Scaffold(
      backgroundColor: kDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.5), radius: 1.3, colors: [Color(0xFF0F4A38), Color(0xFF072A20), Color(0xFF03140F)]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 96, height: 104, child: CustomPaint(painter: LogoPainter(0.15))),
                const SizedBox(height: 8),
                Text('منبر', style: tx(44, w: FontWeight.w800, c: const Color(0xFFF3EAD0))),
                Text('قصائد ومراثي', style: tx(14, w: FontWeight.w500, c: const Color(0xFF9FBDB0))),
                const SizedBox(height: 36),
                body,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
