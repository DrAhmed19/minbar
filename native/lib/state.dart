import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data.dart';

class PlayerCtl extends ChangeNotifier {
  final AudioPlayer p = AudioPlayer();
  final Repo repo;
  List<Track> queue = [];
  int index = -1;
  bool shuffle = false;
  LoopMode loop = LoopMode.off;
  double speed = 1.0;
  double lyOffset = 0; // تأخير الكلمات (سماعات بلوتوث)
  int viz = 0, bg = 0, lyFont = 2, lyColor = 0, layout = 0, lyTr = 0, lySplit = 1;
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
        initialPosition: pos ?? Duration.zero,
      );
      await p.setSpeed(speed);
      await p.setLoopMode(loop);
      await p.setShuffleModeEnabled(shuffle);
      if (play) unawaited(p.play());
    } catch (e) {
      debugPrint('play error: $e');
    }
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

  void setSleep(int minutes) {
    sleepTimer?.cancel();
    sleepAt = null;
    if (minutes > 0) {
      sleepAt = DateTime.now().add(Duration(minutes: minutes));
      sleepTimer = Timer(Duration(minutes: minutes), () {
        p.pause();
        sleepAt = null;
        notifyListeners();
      });
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
void launchApk() => launchUrl(Uri.parse(kApkUrl), mode: LaunchMode.externalApplication);
const kApkUrl = 'https://github.com/DrAhmed19/minbar/releases/download/apk-latest/minbar.apk';

Future<int> latestBuild() async {
  final c = HttpClient();
  try {
    final rq = await c.getUrl(Uri.parse('https://api.github.com/repos/DrAhmed19/minbar/releases/tags/apk-latest'));
    rq.headers.set('User-Agent', 'minbar-app');
    final r = await rq.close();
    if (r.statusCode != 200) return 0;
    final body = await r.transform(utf8.decoder).join();
    final m = RegExp(r'build:(\d+)').firstMatch(body);
    return m == null ? 0 : int.parse(m.group(1)!);
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
