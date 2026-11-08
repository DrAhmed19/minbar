import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'pages.dart';
import 'state.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: kCream));
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.minbar.app.audio',
    androidNotificationChannelName: 'منبر',
    androidNotificationOngoing: true,
  );
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDUDRy0qyhVLJ5mYAkfqpWxeABwppmcQ-s',
      appId: '1:123319772563:web:d0dc07aefa58fbc25ef466',
      messagingSenderId: '123319772563',
      projectId: 'minbar-8f037',
      storageBucket: 'minbar-8f037.firebasestorage.app',
      authDomain: 'minbar-8f037.firebaseapp.com',
    ),
  );
  app.player.init();
  app.repo.init();
  app.auth.init();
  runApp(const MinbarApp());
}

class MinbarApp extends StatelessWidget {
  const MinbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
