import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'audio.dart';
import 'data.dart';

class PlayerCtl extends ChangeNotifier {
  /// تفعيل وضع الأداء تلقائياً لهذه الجلسة فقط
  void autoPerf(String why) {
    if (perf == 1) return;
    perf = 1;
    debugPrint('MBPERF auto: $why');
    notifyListeners();
  }

  final AudioPlayer p = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [auLoud, auEq]));
  final Repo repo;
  List<Track> queue = [];
  int index = -1;
  bool shuffle = false;
  LoopMode loop = LoopMode.off;
  double speed = 1.0;
  double lyOffset = 0; // تأخير الكلمات (سماعات بلوتوث)
  int viz = 0, bg = 0, lyFont = 2, lyColor = 0, layout = 0, lyTr = 0, lySplit = 1, perf = 0, cmOn = 1, cmDens = 2, cmView = 0;
  double lySize = 1;
  ConcatenatingAudioSource? _cs;
  bool quiet = false; // أثناء العينات: لا نحفظ الموضع ولا نحسب الاستماع
  String lastError = '';
  int _errs = 0;
  int _lastSave = 0;
  String _counted = '';
  Timer? sleepTimer;
  DateTime? sleepAt;

  PlayerCtl(this.repo);

  Track? get cur => (index >= 0 && index < queue.length) ? queue[index] : null;

  void init() {
    p.currentIndexStream.listen((i) {
      if (i != null && i != index) {
        index = i;
        notifyListeners();
      }
    });
    p.positionStream.listen((pos) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final t = quiet ? null : cur;
      if (t != null && now - _lastSave > 4000 && pos.inSeconds > 0) {
        _lastSave = now;
        repo.savePos(t.id, pos.inMilliseconds, dur: p.duration?.inMilliseconds ?? 0);
      }
      if (t != null && pos.inSeconds >= 30 && _counted != t.id) {
        _counted = t.id;
        repo.countPlay(t.id);
      }
    });
    p.playingStream.listen((_) => notifyListeners());
    /* أخطاء التشغيل (ملف تالف/انقطاع شبكة): ننتقل للتالي بدل التوقف، مع حد لتفادي حلقة لا نهائية */
    p.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      lastError = 'تعذّر تشغيل المقطع';
      notifyListeners();
      if (++_errs <= 3 && p.hasNext) {
        p.seekToNext().then((_) => p.play());
      }
    });
    p.processingStateStream.listen((s) {
      if (s == ProcessingState.ready) _errs = 0;
    });
    SharedPreferences.getInstance().then((sp) {
      lyOffset = sp.getDouble('lyOffset') ?? 0;
      viz = sp.getInt('viz4') ?? 0;
      layout = sp.getInt('layout') ?? 0;
      bg = sp.getInt('bg3') ?? 0;
      lyFont = sp.getInt('lyF') ?? 2;
      lyColor = sp.getInt('lyC') ?? 0;
      lySize = sp.getDouble('lyS') ?? 1;
      lyTr = sp.getInt('lyTr') ?? 0;
      lySplit = sp.getInt('lySp') ?? 1;
      perf = 0; // كل جلسة تبدأ بالشكل الكامل، ويتحوّل تلقائياً لوضع الأداء عند البطء أو الخطأ
      cmOn = sp.getInt('cmOn') ?? 1;
      cmDens = sp.getInt('cmDens') ?? 2;
      cmView = sp.getInt('cmView') ?? 0;
      notifyListeners();
      speed = sp.getDouble('speed') ?? 1.0;
    });
  }

  AudioSource _src(Track t) {
    final off = repo.offPath(t.id);
    final tag = MediaItem(
          id: t.id,
          title: t.title,
          artist: t.reciter,
          album: t.albumName.isEmpty ? null : t.albumName,
          artUri: t.coverUrl.isEmpty ? null : Uri.parse(t.coverUrl),
    );
    if (off != null && File(off).existsSync()) return AudioSource.file(off, tag: tag);
    return AudioSource.uri(Uri.parse(t.audioUrl), tag: tag);
  }

  Future<void> playList(List<Track> list, int start, {Duration? pos, bool play = true}) async {
    if (list.isEmpty || start < 0 || start >= list.length) return;
    queue = list;
    index = start;
    notifyListeners();
    try {
      _cs = ConcatenatingAudioSource(children: list.map(_src).toList());
      await p.setAudioSource(
        _cs!,
        initialIndex: start,
        initialPosition: pos ?? _resumeAt(list[start]),
      );
      await p.setSpeed(speed);
      await p.setLoopMode(loop);
      await p.setShuffleModeEnabled(shuffle);
      if (play) unawaited(p.play());
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  /// مثل يوتيوب: القصيدة تكمل بصمت من حيث توقفت (إلا إذا كانت بالبداية أو قريبة من النهاية)
  Duration _resumeAt(Track t) {
    final ms = repo.posOf(t.id), d = repo.durs[t.id] ?? 0;
    if (ms < 15000 || (d > 0 && ms > d - 20000)) return Duration.zero;
    return Duration(milliseconds: ms - 1500);
  }

  /// استعادة آخر أثر (متوقفاً) عند فتح التطبيق
  bool _restoring = false;
  Future<void> restore() async {
    if (cur != null || repo.tracks.isEmpty || _restoring) return;
    _restoring = true;
    final id = repo.lastId;
    if (id == null) return;
    final i = repo.tracks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final ms = repo.posOf(id);
    await playList(repo.tracks, i, pos: Duration(milliseconds: ms > 2000 ? ms - 1500 : 0), play: false);
  }

  Future<void> playNext(Track t) async {
    if (_cs == null || cur == null) return playList([t], 0);
    final at = (p.currentIndex ?? index) + 1;
    try {
      await _cs!.insert(at, _src(t));
      queue = List<Track>.from(queue)..insert(at, t);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addToEnd(Track t) async {
    if (_cs == null || cur == null) return playList([t], 0);
    try {
      await _cs!.add(_src(t));
      queue = List<Track>.from(queue)..add(t);
    } catch (_) {}
    notifyListeners();
  }

  void toggle() => p.playing ? p.pause() : p.play();
  void next() => p.seekToNext();
  void prev() {
    if (p.position.inSeconds > 4) {
      p.seek(Duration.zero);
    } else {
      p.seekToPrevious();
    }
  }

  void seek(double sec) => p.seek(Duration(milliseconds: (sec * 1000).round()));

  void toggleShuffle() {
    shuffle = !shuffle;
    p.setShuffleModeEnabled(shuffle);
    notifyListeners();
  }

  void cycleLoop() {
    loop = loop == LoopMode.off ? LoopMode.all : (loop == LoopMode.all ? LoopMode.one : LoopMode.off);
    p.setLoopMode(loop);
    notifyListeners();
  }

  void setPref(String k, num v) {
    switch (k) {
      case 'viz':
        viz = v.toInt();
        break;
      case 'layout':
        layout = v.toInt();
        break;
      case 'bg':
        bg = v.toInt();
        break;
      case 'lyFont':
        lyFont = v.toInt();
        break;
      case 'lyColor':
        lyColor = v.toInt();
        break;
      case 'lySize':
        lySize = v.toDouble();
        break;
      case 'lyTr':
        lyTr = v.toInt();
        break;
      case 'lySp':
        lySplit = v.toInt();
        break;
      case 'perf':
        perf = v.toInt();
        break;
      case 'cmOn':
        cmOn = v.toInt();
        break;
      case 'cmDens':
        cmDens = v.toInt();
        break;
      case 'cmView':
        cmView = v.toInt();
        break;
    }
    SharedPreferences.getInstance().then((sp) => v is int ? sp.setInt(const {'viz': 'viz4', 'bg': 'bg3', 'lyFont': 'lyF', 'lyColor': 'lyC'}[k] ?? k, v) : sp.setDouble(k == 'lySize' ? 'lyS' : k, v.toDouble()));
    notifyListeners();
  }

  void jump(int i) {
    if (i < 0 || i >= queue.length) return;
    p.seek(Duration.zero, index: i);
    p.play();
  }

  Future<void> removeAt(int i) async {
    if (queue.length <= 1 || i < 0 || i >= queue.length) return;
    try {
      await _cs?.removeAt(i);
      queue = List<Track>.from(queue)..removeAt(i);
      index = (p.currentIndex ?? index).clamp(0, queue.length - 1);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> moveQ(int from, int to) async {
    if (from == to || from < 0 || to < 0 || from >= queue.length || to >= queue.length) return;
    try {
      await _cs?.move(from, to);
      final l = List<Track>.from(queue);
      final t = l.removeAt(from);
      l.insert(to, t);
      queue = l;
      index = p.currentIndex ?? index;
    } catch (_) {}
    notifyListeners();
  }

  void setLyOffset(double v) {
    lyOffset = v;
    SharedPreferences.getInstance().then((sp) => sp.setDouble('lyOffset', v));
    notifyListeners();
  }

  void setSpeed(double s) {
    speed = s;
    SharedPreferences.getInstance().then((sp) => sp.setDouble('speed', s));
    p.setSpeed(s);
    notifyListeners();
  }

  bool sleepFade = true;
  Timer? _fadeT;
  void setSleep(int minutes) {
    sleepTimer?.cancel();
    _fadeT?.cancel();
    p.setVolume(1);
    sleepAt = null;
    if (minutes > 0) {
      sleepAt = DateTime.now().add(Duration(minutes: minutes));
      const fadeSec = 30;
      final total = minutes * 60;
      void finish() {
        _fadeT?.cancel();
        p.pause();
        p.setVolume(1);
        sleepAt = null;
        notifyListeners();
      }

      if (!sleepFade) {
        sleepTimer = Timer(Duration(seconds: total), finish);
      } else {
        // إطفاء تدريجي: آخر 30 ثانية ينخفض الصوت شيئاً فشيئاً
        sleepTimer = Timer(Duration(seconds: total - fadeSec), () {
          var k = 0;
          _fadeT = Timer.periodic(const Duration(milliseconds: 500), (_) {
            k++;
            final v = 1 - k / (fadeSec * 2);
            if (v <= 0.02) {
              finish();
            } else {
              p.setVolume(v * v);
            }
          });
        });
      }
    }
    notifyListeners();
  }
}

enum AuthState { init, out, loading, form, wait, rejected, ok }

class AuthCtl extends ChangeNotifier {
  AuthState state = AuthState.init;
  User? user;
  bool guest = false;
  String error = '';
  bool admin = false;
  SharedPreferences? _p;
  StreamSubscription<User?>? _sub;

  bool get isIn => state == AuthState.ok;
  String get name => guest ? 'ضيف' : (user?.displayName ?? '');

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    guest = _p!.getBool('guest') ?? false;
    if (guest) {
      state = AuthState.ok;
      notifyListeners();
    }
    _sub = FirebaseAuth.instance.authStateChanges().listen(_on);
  }

  Future<void> _on(User? u) async {
    user = u;
    if (u == null) {
      if (!guest) {
        state = AuthState.out;
        notifyListeners();
      }
      return;
    }
    guest = false;
    await _p?.setBool('guest', false);
    final cachedOk = _p?.getString('okUid') == u.uid;
    state = cachedOk ? AuthState.ok : AuthState.loading;
    notifyListeners();
    try {
      final db = FirebaseFirestore.instance;
      var open = false;
      try {
        final c = await db.doc('config/app').get();
        if (c.exists) open = c.data()?['open'] == true;
      } catch (_) {}
      try {
        await db.collection('waitlist').limit(1).get();
        admin = true;
      } catch (_) {
        admin = false;
      }
      if (admin || open) {
        state = AuthState.ok;
      } else {
        final d = await db.doc('waitlist/${u.uid}').get();
        if (!d.exists) {
          state = AuthState.form;
        } else {
          final st = d.data()?['status'];
          state = st == 'approved' ? AuthState.ok : (st == 'rejected' ? AuthState.rejected : AuthState.wait);
        }
      }
    } catch (e) {
      if (!cachedOk) {
        error = 'مشكلة بالاتصال';
        state = AuthState.out;
      }
    }
    if (state == AuthState.ok) {
      await _p?.setString('okUid', u.uid);
    } else {
      await _p?.remove('okUid');
    }
    notifyListeners();
  }

  Future<void> google() async {
    error = '';
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
    } on FirebaseAuthException catch (e) {
      if (e.code != 'canceled' && e.code != 'web-context-canceled') error = 'تعذّر الدخول: ${e.code}';
      notifyListeners();
    } catch (e) {
      error = 'تعذّر الدخول';
      notifyListeners();
    }
  }

  Future<void> enterGuest() async {
    guest = true;
    await _p?.setBool('guest', true);
    state = AuthState.ok;
    notifyListeners();
  }

  Future<void> register() async {
    final u = user;
    if (u == null) return;
    try {
      await FirebaseFirestore.instance.doc('waitlist/${u.uid}').set({
        'name': u.displayName ?? '',
        'email': u.email ?? '',
        'photo': u.photoURL ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = AuthState.wait;
    } catch (e) {
      error = 'تعذّر التسجيل';
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    guest = false;
    await _p?.setBool('guest', false);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    user = null;
    state = AuthState.out;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// فحص التحديثات: يقارن رقم البناء المدمج بآخر إصدار منشور على GitHub
const kBuild = int.fromEnvironment('BUILD', defaultValue: 0);
final kNav = GlobalKey<NavigatorState>();

/// تحديث داخل التطبيق: تنزيل مع شريط تقدّم ثم فتح شاشة التثبيت مباشرة
void launchApk([String? url]) {
  final u = url == null || url.isEmpty ? kApkUrl : url;
  final ctx = kNav.currentContext;
  if (ctx == null) {
    launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    return;
  }
  final prog = ValueNotifier<double?>(null), msg = ValueNotifier<String>('جارٍ تنزيل التحديث…');
  StreamSubscription<OtaEvent>? sub;
  var open = true;
  void close() {
    if (open && (kNav.currentState?.canPop() ?? false)) kNav.currentState!.pop();
    open = false;
  }

  showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF16100B),
        title: const Text('تحديث منبر', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ValueListenableBuilder<String>(valueListenable: msg, builder: (_, m, __) => Text(m, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          const SizedBox(height: 14),
          ValueListenableBuilder<double?>(
            valueListenable: prog,
            builder: (_, p, __) => Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: p, minHeight: 7, color: const Color(0xFFE8C468), backgroundColor: Colors.white12)),
              const SizedBox(height: 6),
              Text(p == null ? '' : '${(p * 100).round()}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              sub?.cancel();
              close();
            },
            child: const Text('إلغاء', style: TextStyle(color: Color(0xFFE8C468))),
          ),
        ],
      ),
    ),
  ).then((_) => open = false);
  try {
    sub = OtaUpdate().execute(u, destinationFilename: 'minbar.apk').listen((e) {
      switch (e.status) {
        case OtaStatus.DOWNLOADING:
          final v = double.tryParse('${e.value}');
          if (v != null) prog.value = v / 100;
        case OtaStatus.INSTALLING:
          prog.value = 1;
          msg.value = 'اكتمل التنزيل — وافق على التثبيت';
          Future.delayed(const Duration(seconds: 2), close);
        case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
          msg.value = 'اسمح لمنبر بتثبيت التطبيقات من الإعدادات ثم أعد المحاولة';
        case OtaStatus.DOWNLOAD_ERROR:
        case OtaStatus.INTERNAL_ERROR:
          close();
          launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
        default:
          close();
      }
    }, onError: (_) {
      close();
      launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    });
  } catch (_) {
    close();
    launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
  }
}
final kApkUrl = 'https://github.com/DrAhmed19/minbar-releases/raw/main/${Abi.current() == Abi.androidArm ? 'minbar-arm32' : 'minbar'}.apk';

/// آخر نسخة منشورة: من وثيقة config/app (apkBuild, apkUrl) التي يكتبها البناء تلقائياً،
/// وإن تعذّر فمن إصدار GitHub (يعمل فقط إن كان المستودع عاماً)
Future<({int build, String url})> latestUpdate() async {
  try {
    final d = await FirebaseFirestore.instance.doc('config/app').get().timeout(const Duration(seconds: 8));
    final b = (d.data()?['apkBuild'] as num?)?.toInt() ?? 0;
    const u = ''; // النسخ الجديدة تختار الملف حسب المعالج (kApkUrl)؛ apkUrl للنسخ القديمة فقط
    if (b > 0) return (build: b, url: u);
  } catch (_) {}
  return (build: await latestBuild(), url: '');
}

Future<int> latestBuild() async {
  final c = HttpClient();
  try {
    final rq = await c.getUrl(Uri.parse('https://raw.githubusercontent.com/DrAhmed19/minbar-releases/main/version.txt'));
    rq.headers.set('User-Agent', 'minbar-app');
    final r = await rq.close();
    if (r.statusCode != 200) return 0;
    final body = await r.transform(utf8.decoder).join();
    return int.tryParse(body.trim()) ?? 0;
  } catch (_) {
    return 0;
  } finally {
    c.close(force: true);
  }
}

class AppState {
  final repo = Repo();
  late final player = PlayerCtl(repo);
  final auth = AuthCtl();
}

final app = AppState();
