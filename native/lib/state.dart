import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

class PlayerCtl extends ChangeNotifier {
  final AudioPlayer p = AudioPlayer();
  final Repo repo;
  List<Track> queue = [];
  int index = -1;
  bool shuffle = false;
  LoopMode loop = LoopMode.off;
  double speed = 1.0;
  int _lastSave = 0;
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
      final t = cur;
      if (t != null && now - _lastSave > 4000 && pos.inSeconds > 0) {
        _lastSave = now;
        repo.savePos(t.id, pos.inMilliseconds);
      }
    });
    p.playingStream.listen((_) => notifyListeners());
  }

  AudioSource _src(Track t) => AudioSource.uri(
        Uri.parse(t.audioUrl),
        tag: MediaItem(
          id: t.id,
          title: t.title,
          artist: t.reciter,
          album: t.albumName.isEmpty ? null : t.albumName,
          artUri: t.coverUrl.isEmpty ? null : Uri.parse(t.coverUrl),
        ),
      );

  Future<void> playList(List<Track> list, int start, {Duration? pos, bool play = true}) async {
    if (list.isEmpty || start < 0 || start >= list.length) return;
    queue = list;
    index = start;
    notifyListeners();
    try {
      await p.setAudioSource(
        ConcatenatingAudioSource(children: list.map(_src).toList()),
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
  Future<void> restore() async {
    if (cur != null || repo.tracks.isEmpty) return;
    final id = repo.lastId;
    if (id == null) return;
    final i = repo.tracks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final ms = repo.posOf(id);
    await playList(repo.tracks, i, pos: Duration(milliseconds: ms > 2000 ? ms - 1500 : 0), play: false);
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

  void setSpeed(double s) {
    speed = s;
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
    state = AuthState.loading;
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
      error = 'مشكلة بالاتصال';
      state = AuthState.out;
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

class AppState {
  final repo = Repo();
  late final player = PlayerCtl(repo);
  final auth = AuthCtl();
}

final app = AppState();
