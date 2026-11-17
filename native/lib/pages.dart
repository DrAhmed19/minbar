import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home.dart';
import 'occasion.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// ========== الافتتاح + الدخول ==========
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  late final AnimationController _x = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  final DateTime _t0 = DateTime.now();
  bool _minDone = false, _gone = false;
  static const _hm = ['', 'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];

  @override
  void initState() {
    super.initState();
    // تحميل ذكي: أقل مدة 2.5 ثانية حتى تكتمل الحركة، ويبقى فقط لحد ما تجهز البيانات
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _minDone = true);
    });
    app.auth.addListener(_r);
    _x.addStatusListener((st) {
      if (st == AnimationStatus.completed && mounted) setState(() => _gone = true);
    });
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    app.auth.removeListener(_r);
    _c.dispose();
    _x.dispose();
    super.dispose();
  }

  String _greet() {
    final o = occasionToday();
    if (o != null) return o.t;
    final h = hijriOf(DateTime.now());
    return '${h.d} ${_hm[h.m]} ${h.y} هـ';
  }

  @override
  Widget build(BuildContext context) {
    final a = app.auth;
    final ready = _minDone && a.state != AuthState.init && a.state != AuthState.loading;
    const light = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF03140F),
        systemNavigationBarIconBrightness: Brightness.light);
    const dark = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: kCream,
        systemNavigationBarIconBrightness: Brightness.dark);
    if (ready && a.isIn) {
      if (!_gone && !_x.isAnimating && _x.value == 0) _x.forward();
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark,
        child: Stack(children: [
          const HomeShell(),
          if (!_gone) IgnorePointer(child: AnimatedBuilder(animation: _x, builder: (_, __) => _splash(_x.value))),
        ]),
      );
    }
    if (!ready) return AnnotatedRegion<SystemUiOverlayStyle>(value: light, child: _splash(0));
    return AnnotatedRegion<SystemUiOverlayStyle>(value: light, child: Material(type: MaterialType.transparency, child: LoginPage(onRetry: () => setState(() {}))));
  }

  /// x: 0 = الافتتاح، 1 = انتهى الانتقال (الشعار يصغر ويطير لمكانه بأعلى الرئيسية والخلفية تختفي)
  Widget _splash(double x) {
    final e = Curves.easeInOutCubic.transform(x);
    final sz = MediaQuery.of(context).size, top = MediaQuery.of(context).padding.top;
    // مكان شعار الرأس بالرئيسية تقريباً (يمين الشاشة بالأعلى)
    final dx = (sz.width / 2 - 34) * e, dy = -(sz.height / 2 - top - 36) * e;
    return Opacity(
      opacity: x < 0.75 ? 1 : (1 - (x - 0.75) / 0.25),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.25), radius: 1.2, colors: [
            const Color(0xFF0F4A38).withOpacity(1 - e),
            const Color(0xFF072A20).withOpacity(1 - e),
            const Color(0xFF03140F).withOpacity(1 - e),
          ]),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final el = DateTime.now().difference(_t0).inMilliseconds / 1000.0;
              double fade(double at) => ((el - at) / 0.5).clamp(0.0, 1.0);
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: 1 - 0.72 * e,
                    child: SizedBox(
                      width: 128,
                      height: 138,
                      child: CustomPaint(painter: LogoPainter(_c.value, rise: (el / 0.6).clamp(0.0, 1.0), draw: ((el - 0.3) / 0.7).clamp(0.0, 1.0))),
                    ),
                  ),
                ),
                Opacity(
                  opacity: 1 - e,
                  child: Column(children: [
                    const SizedBox(height: 14),
                    NameMark(width: 230, write: (el - 0.5) / 1.3, shine: (el - 1.9) / 0.7),
                    const SizedBox(height: 10),
                    Opacity(opacity: fade(1.9), child: Text('إهداء إلى باسم الكربلائي', style: tx(14, c: const Color(0xFFA9C6B8)))),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
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
          const SizedBox(height: 6),
          TextButton(onPressed: a.enterGuest, child: Text('المتابعة كضيف', style: tx(14, w: FontWeight.w600, c: const Color(0xFFB9CFC4)))),
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
                const SizedBox(height: 12),
                const NameLoop(width: 190),
                const SizedBox(height: 4),
                Text('قصائد ومراثي', style: tx(14, w: FontWeight.w500, c: const Color(0xFF9FBDB0))),
                const SizedBox(height: 18),
                Container(width: 42, height: 2, decoration: BoxDecoration(color: const Color(0x66F4CF55), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 30),
                body,
                const SizedBox(height: 28),
                Text('بالمتابعة فإنك توافق على شروط الاستخدام وسياسة الخصوصية', style: tx(10.5, c: const Color(0xFF6B887B)), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('مُهدى إلى باسم الكربلائي · نسخة تجريبية', style: tx(10.5, c: const Color(0xFF5E7A6E))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// اسم التطبيق (شعار الخط): كتابة بالقلم من اليمين لليسار ثم مسحة ضوء ذهبية
class NameMark extends StatelessWidget {
  final double width, write, shine;
  const NameMark({super.key, required this.width, required this.write, this.shine = -1});

  @override
  Widget build(BuildContext context) {
    final w = write.clamp(0.0, 1.0);
    final h = width * 662 / 960;
    if (w <= 0) return SizedBox(width: width, height: h);
    final img = Image.asset('assets/name.png', width: width, height: h, fit: BoxFit.contain, filterQuality: FilterQuality.high);
    final head = w * 1.2;
    final done = w >= 1;
    Widget base = done
        ? img
        : ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
              stops: [0, (head - 0.2).clamp(0.0, 1.0), head.clamp(0.0, 1.0)],
            ).createShader(r),
            child: img,
          );
    final s = shine;
    if (s > 0 && s < 1) {
      final c = 1.25 - 1.5 * Curves.easeInOut.transform(s);
      double k(double v) => v.clamp(0.0, 1.0);
      base = Stack(children: [
        base,
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => LinearGradient(
            begin: const Alignment(-1, -0.35),
            end: const Alignment(1, 0.35),
            colors: const [Color(0x00FFF4CC), Color(0x00FFF4CC), Color(0xE6FFF4CC), Color(0x00FFF4CC), Color(0x00FFF4CC)],
            stops: [0, k(c - 0.14), k(c), k(c + 0.14), 1],
          ).createShader(r),
          child: img,
        ),
      ]);
    }
    return SizedBox(width: width, height: h, child: base);
  }
}

/// نسخة شاشة الدخول: الاسم ثابت وتمرّ عليه مسحة ضوء كل بضع ثوانٍ
class NameLoop extends StatefulWidget {
  final double width;
  const NameLoop({super.key, required this.width});
  @override
  State<NameLoop> createState() => _NameLoopState();
}

class _NameLoopState extends State<NameLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 7000))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => NameMark(width: widget.width, write: 1, shine: _c.value < 0.12 ? _c.value / 0.12 : -1),
      );
}
