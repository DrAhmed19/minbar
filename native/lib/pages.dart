import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home.dart';
import 'mihrab.dart';
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
    MihrabAssets.load();
    // تحميل ذكي: أقل مدة 3.3 ثانية حتى تكتمل الحركة، ويبقى فقط لحد ما تجهز البيانات
    Future.delayed(const Duration(milliseconds: 3300), () {
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

  /// x: 0 = الافتتاح، 1 = انتهى الانتقال (تتلاشى الافتتاحية بنعومة فوق الرئيسية)
  Widget _splash(double x) {
    final e = Curves.easeInOutCubic.transform(x);
    return Opacity(
      opacity: 1 - e,
      child: Transform.scale(
        scale: 1 + .04 * e,
        child: Container(
          color: const Color(0xFF020E0A),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: MihrabPainter(DateTime.now().difference(_t0).inMilliseconds / 1000.0),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onRetry;
  const LoginPage({super.key, required this.onRetry});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// ظهور متدرّج لكل عنصر (من 0 إلى 1 حسب ترتيبه)
  Widget _rise(int i, Widget w) {
    final a = CurvedAnimation(parent: _in, curve: Interval((i * .1).clamp(0.0, .6), (i * .1 + .5).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: a,
      builder: (_, c) => Opacity(opacity: a.value, child: Transform.translate(offset: Offset(0, 14 * (1 - a.value)), child: c)),
      child: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = app.auth;
    const amiri = TextStyle(fontFamily: 'Amiri');
    return Scaffold(
      backgroundColor: const Color(0xFF020E0A),
      body: CustomPaint(
        painter: const MihrabBackdrop(cy: .3),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, bc) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: bc.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const SizedBox(height: 8),
                    Column(children: [
                      _rise(0, const MihrabMark(width: 230, height: 276)),
                      const SizedBox(height: 6),
                      _rise(1, Text('قصائد ومراثي', style: amiri.copyWith(fontSize: 21, color: const Color(0xFFE9D9AE), height: 1.4))),
                      const SizedBox(height: 10),
                      _rise(2, const _Orn()),
                    ]),
                    Column(children: [
                      const SizedBox(height: 26),
                      _rise(3, _GoogleBtn(busy: a.busy, onTap: a.busy ? null : a.google)),
                      const SizedBox(height: 12),
                      _rise(4, _GuestBtn(onTap: a.busy ? null : a.enterGuest)),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: a.error.isEmpty
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(a.error, style: tx(12.5, c: const Color(0xFFE8A0A0)), textAlign: TextAlign.center),
                              ),
                      ),
                      const SizedBox(height: 10),
                      _rise(5, Text('تصفّح واستمع كضيف، وسجّل دخولك لحفظ مفضّلتك والتعليق والتفاعل', style: tx(11.5, c: const Color(0xFF7F9A8E), h: 1.6), textAlign: TextAlign.center)),
                    ]),
                    _rise(6, Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 14),
                      child: Column(children: [
                        Text('بالمتابعة فإنك توافق على شروط الاستخدام وسياسة الخصوصية', style: tx(10.5, c: const Color(0xFF5F7C70)), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('إهداء إلى الحاج باسم الكربلائي', style: amiri.copyWith(fontSize: 14, color: const Color(0xFFCDBB8A))),
                        const SizedBox(height: 2),
                        Text('الإصدار $kVersion', style: tx(10, c: const Color(0xFF4F6B60))),
                      ]),
                    )),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// زخرفة صغيرة: خطّان يتلاشيان وبينهما معيّن
class _Orn extends StatelessWidget {
  const _Orn();
  @override
  Widget build(BuildContext context) {
    Widget line(bool r) => Container(
          width: 46,
          height: 1,
          decoration: BoxDecoration(gradient: LinearGradient(colors: r ? const [Color(0x00E2BE64), Color(0xCCE2BE64)] : const [Color(0xCCE2BE64), Color(0x00E2BE64)])),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      line(true),
      const SizedBox(width: 8),
      Transform.rotate(angle: .785, child: Container(width: 5, height: 5, color: const Color(0xFFE2BE64))),
      const SizedBox(width: 8),
      line(false),
    ]);
  }
}

class _GoogleBtn extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;
  const _GoogleBtn({required this.busy, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFCF2), Color(0xFFF1E9D4)]),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)), BoxShadow(color: Color(0x33E8C46A), blurRadius: 24)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2F6B55)))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('المتابعة بحساب Google', style: tx(15.5, w: FontWeight.w700, c: const Color(0xFF1F2A25))),
                    const SizedBox(width: 12),
                    const SizedBox(width: 22, height: 22, child: CustomPaint(painter: GoogleG())),
                  ]),
          ),
        ),
      ),
    );
  }
}

class _GuestBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _GuestBtn({this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x14FFFFFF),
        border: Border.all(color: const Color(0x40E2BE64)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(child: Text('المتابعة كضيف', style: tx(14.5, w: FontWeight.w600, c: const Color(0xFFE6DCC0)))),
        ),
      ),
    );
  }
}
