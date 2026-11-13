import 'dart:math' as math;
import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'pages.dart';
import 'state.dart';
import 'audio.dart';
import 'extras.dart';
import 'ui.dart';

Future<void> main() async {
  runZonedGuarded(_start, (e, s) => debugPrint('MBERR zone: $e\n${s.toString().split('\n').take(6).join('\n')}'));
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (d) {
    debugPrint('MBERR ui: ${d.exception}\n${(d.stack ?? '').toString().split('\n').take(6).join('\n')}');
    try {
      app.player.autoPerf('error');
    } catch (_) {}
  };
  // مراقبة سلاسة الرسم: إذا صار الجهاز يتقطّع بشكل واضح يتحوّل تلقائياً لوضع الأداء
  var fr = 0, slow = 0;
  SchedulerBinding.instance.addTimingsCallback((ts) {
    for (final t in ts) {
      fr++;
      if (t.totalSpan.inMilliseconds > 32) slow++;
    }
    if (fr >= 180) {
      if (slow > fr * 0.28) {
        try {
          app.player.autoPerf('jank $slow/$fr');
        } catch (_) {}
      }
      fr = 0;
      slow = 0;
    }
  });
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: kCream));
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.minbar.app.audio',
    androidNotificationChannelName: 'منبر',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_stat_minbar',
  );
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCIgeO-PZ-F_H597PfhRhOG7O2dXIpbWhw',
      appId: '1:123319772563:android:f1cd07774f51c21d5ef466',
      messagingSenderId: '123319772563',
      projectId: 'minbar-8f037',
      storageBucket: 'minbar-8f037.firebasestorage.app',
      authDomain: 'minbar-8f037.firebaseapp.com',
    ),
  );
  /* جلسة صوت موسيقى: إيقاف عند المكالمات/فصل السماعة وتخفيض الصوت مع الإشعارات */
  try {
    final ses = await AudioSession.instance;
    await ses.configure(const AudioSessionConfiguration.music());
  } catch (_) {}
  app.player.init();
  auLoad();
  app.repo.init();
  app.auth.init();
  await loadIcons();
  runApp(const MinbarApp());
  // أندرويد 13+: بدون صلاحية الإشعارات لا تظهر لوحة التحكم بالإشعارات ولا على شاشة القفل
  Future.delayed(const Duration(seconds: 2), () => notifInit(ask: true));
}

class MinbarApp extends StatelessWidget {
  const MinbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: kNav,
      title: 'منبر',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, brightness: Brightness.light),
        scaffoldBackgroundColor: kCream,
      ),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: AutoScale(child: child ?? const SizedBox())),
      home: const Gate(),
    );
  }
}

/// تصميم ذكي حسب حجم الشاشة: كل الواجهة (أيقونات، نصوص، أزرار، لوحات) تتكبّر أو تتصغّر
/// بنسبة واحدة محسوبة من حجم الشاشة، فتبقى متناسقة بالشاشات الصغيرة والكبيرة
class AutoScale extends StatelessWidget {
  final Widget child;
  const AutoScale({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width, h = mq.size.height - mq.padding.vertical;
    if (w <= 0 || h <= 0) return child;
    var sc = math.min(w / 392, h / 800).clamp(0.8, 1.2).toDouble();
    if ((sc - 1).abs() < 0.03) return child;
    final lw = w / sc, lh = mq.size.height / sc;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: lw,
          height: lh,
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(lw, lh),
              padding: mq.padding / sc,
              viewPadding: mq.viewPadding / sc,
              viewInsets: mq.viewInsets / sc,
              devicePixelRatio: mq.devicePixelRatio * sc,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
