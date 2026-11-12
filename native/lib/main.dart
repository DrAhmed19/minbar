import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
  FlutterError.onError = (d) => debugPrint('MBERR ui: ${d.exception}\n${(d.stack ?? '').toString().split('\n').take(6).join('\n')}');
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
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
      home: const Gate(),
    );
  }
}
