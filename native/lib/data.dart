import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'occasion.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kBase = 'https://minbar-95z.pages.dev/';

String absUrl(String p) {
  if (p.isEmpty) return '';
  if (p.startsWith('http')) return p;
  return kBase + (p.startsWith('/') ? p.substring(1) : p);
}

/// تطبيع عربي متسامح للبحث (تشكيل/همزات/ة-ه/ى-ي)
String norm(String s) {
  var r = s.toLowerCase();
  r = r.replaceAll(RegExp('[ً-ٰٟـ]'), '');
  r = r.replaceAll(RegExp('[أإآٱ]'), 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ؤ', 'و').replaceAll('ئ', 'ي');
  return r.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String fmt(double s) {
  if (s.isNaN || s < 0) s = 0;
  final m = s ~/ 60, x = (s % 60).floor();
  return '$m:${x.toString().padLeft(2, '0')}';
}

String fmt2(double s) {
  if (s.isNaN || s < 0) s = 0;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).floor().toString().padLeft(2, '0')}';
}

class Lyric {
  final double t;
  final String l;
  final bool gap;
  const Lyric(this.t, this.l, this.gap);

  static List<Lyric> parse(dynamic raw) {
    try {
      final List a = raw is String ? jsonDecode(raw) as List : raw as List;
      final out = a
          .whereType<Map>()
          .map((e) => Lyric(((e['t'] ?? 0) as num).toDouble(), (e['l'] ?? '').toString(), e['gap'] == true))
          .toList();
      // بدون ترتيب حسب الوقت: نفس ترتيب الملف مثل الويب (الترتيب كان يخلط الأبيات المكررة ويقفز للخلف)
      return out;
    } catch (_) {
      return [];
    }
  }
}

class Album {
  final String id, name, reciter, cover;
  final int at;
  Album(this.id, this.name, this.reciter, this.cover, [this.at = 0]);
}

class Track {
  final String id, title, reciter, poet, audio, cover, album, albumName, cat;
  final int at;
  final List<Lyric> lyrics;
  Track({
    required this.id,
    required this.title,
    required this.reciter,
    required this.poet,
    required this.audio,
    required this.cover,
    required this.album,
    required this.albumName,
    required this.cat,
    required this.at,
    required this.lyrics,
  });

  String get audioUrl => absUrl(audio);
  String get coverUrl => absUrl(cover);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'reciter': reciter,
        'poet': poet,
        'audio': audio,
        'cover': cover,
        'album': album,
        'albumName': albumName,
        'cat': cat,
        'at': at,
      };

  factory Track.fromJson(Map m) => Track(
        id: '${m['id']}',
        title: '${m['title'] ?? ''}',
        reciter: '${m['reciter'] ?? ''}',
        poet: '${m['poet'] ?? ''}',
        audio: '${m['audio'] ?? ''}',
        cover: '${m['cover'] ?? ''}',
        album: '${m['album'] ?? ''}',
        albumName: '${m['albumName'] ?? ''}',
        cat: '${m['cat'] ?? 'أخرى'}',
        at: (m['at'] is num) ? (m['at'] as num).toInt() : 0,
        lyrics: const [],
      );
}

class Pl {
  final String id;
  String name;
  List<String> ids;
  Pl(this.id, this.name, this.ids);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'ids': ids};
}

class Repo extends ChangeNotifier {
  List<Pl> pls = [];
  Set<String> follows = {}, offline = {};
  List<String> recent = [];
  Map<String, int> durs = {};
  String offDir = '';
  List<MapEntry<String, int>> hotPlays = [], hotLikes = [];
  DateTime _hotAt = DateTime(2000);
  final Map<String, String> allLy = {};
  bool _allLyLoading = false;
  List<Track> tracks = [];
  Map<String, Album> albums = {};
  Set<String> favs = {};
  bool loaded = false, netOff = false;
  final Map<String, List<Lyric>> _ly = {};
  SharedPreferences? _p;

  /// هوية صاحب البيانات الشخصية (المفضلة والمتابعات والقوائم والسجل): uid الحساب أو guest، فلا تختلط بين الحسابات والضيف
  String ns = '';
  String _k(String b) => 'u.$ns.$b';

  /// أول هوية تدخل بعد هذا التحديث ترث بيانات النسخة القديمة (كانت مشتركة) مرة وحدة
  void _loadUser() {
    final p = _p;
    if (p == null) return;
    favs = {};
    follows = {};
    recent = [];
    pls = [];
    if (ns.isEmpty) return;
    if (!(p.getBool('u.legacyDone') ?? false)) {
      p.setBool('u.legacyDone', true);
      for (final b in ['fav', 'fol', 'recent']) {
        final v = p.getStringList(b);
        if (v != null) p.setStringList(_k(b), v);
      }
      final pl = p.getString('pls');
      if (pl != null) p.setString(_k('pls'), pl);
      final li = p.getString('last.id');
      if (li != null) p.setString(_k('last.id'), li);
      for (final key in p.getKeys().where((e) => e.startsWith('pos.')).toList()) {
        final v = p.getInt(key);
        if (v != null) p.setInt(_k(key), v);
      }
    }
    favs = (p.getStringList(_k('fav')) ?? []).toSet();
    follows = (p.getStringList(_k('fol')) ?? []).toSet();
    recent = p.getStringList(_k('recent')) ?? [];
    try {
      final j = jsonDecode(p.getString(_k('pls')) ?? '[]') as List;
      pls = j.whereType<Map>().map((m) => Pl('${m['id']}', '${m['name']}', ((m['ids'] ?? []) as List).map((e) => '$e').toList())).toList();
    } catch (_) {}
  }

  void useUser(String n) {
    if (n == ns) return;
    ns = n;
    _loadUser();
    notifyListeners();
  }

  // ---- ملفات من جهاز المستخدم (تُنسخ داخل التطبيق وتعمل بدون إنترنت) ----
  List<Track> locals = [];
  bool _noConn = false;
  bool get noNet => netOff || _noConn;

  /// المحمّلة + ملفات الجهاز (للتشغيل بدون إنترنت)
  List<Track> get playableOffline => [...locals, ...tracks.where((t) => offline.contains(t.id))];

  void _watchNet() {
    Connectivity().checkConnectivity().then((r) {
      _noConn = r.every((e) => e == ConnectivityResult.none);
      notifyListeners();
    }).catchError((_) {});
    Connectivity().onConnectivityChanged.listen((r) {
      final off = r.every((e) => e == ConnectivityResult.none);
      if (off != _noConn) {
        _noConn = off;
        if (!off) netOff = false;
        notifyListeners();
      }
    });
  }

  void _saveLocals() => _p?.setString('locals', jsonEncode(locals.map((e) => e.toJson()).toList()));

  Future<int> importLocal() async {
    if (offDir.isEmpty) return 0;
    final r = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (r == null) return 0;
    var n = 0;
    for (final f in r.files) {
      final p = f.path;
      if (p == null) continue;
      final id = 'loc_${DateTime.now().microsecondsSinceEpoch}_$n';
      try {
        await File(p).copy('$offDir/$id.audio');
      } catch (_) {
        continue;
      }
      final title = f.name.replaceAll(RegExp(r'\.[A-Za-z0-9]{2,5}$'), '').replaceAll('_', ' ');
      locals.add(Track(id: id, title: title, reciter: 'ملف من جهازك', poet: '', audio: '', cover: '', album: '', albumName: '', cat: 'محلي', at: DateTime.now().millisecondsSinceEpoch, lyrics: const []));
      n++;
    }
    _saveLocals();
    notifyListeners();
    return n;
  }

  /// ملف جاء من «فتح بواسطة منبر»: نحفظه ضمن ملفات الجهاز ونُرجع القصيدة
  Future<Track?> importPath(String p) async {
    if (offDir.isEmpty) return null;
    final id = 'loc_${DateTime.now().microsecondsSinceEpoch}_x';
    try {
      await File(p).copy('$offDir/$id.audio');
      final raw = p.split('/').last.replaceFirst(RegExp(r'^open_\d+_'), '');
      final t = Track(id: id, title: raw.replaceAll(RegExp(r'\.[A-Za-z0-9]{2,5}$'), '').replaceAll('_', ' '), reciter: 'ملف من جهازك', poet: '', audio: '', cover: '', album: '', albumName: '', cat: 'محلي', at: DateTime.now().millisecondsSinceEpoch, lyrics: const []);
      locals.add(t);
      _saveLocals();
      notifyListeners();
      try {
        await File(p).delete();
      } catch (_) {}
      return t;
    } catch (_) {
      return null;
    }
  }

  Future<void> delLocal(Track t) async {
    locals.removeWhere((e) => e.id == t.id);
    try {
      await File('$offDir/${t.id}.audio').delete();
    } catch (_) {}
    await _p?.remove('ly.${t.id}');
    _saveLocals();
    notifyListeners();
  }

  /// كلمات من نص: ملف LRC ([دق:ثا.جزء] نص) يعطي تزامناً دقيقاً، والنص العادي يوزَّع على مدة القصيدة تقريباً
  int setLocalLyrics(Track t, String raw) {
    final out = <Map<String, dynamic>>[];
    final re = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final ms = re.allMatches(line).toList();
      final txt = line.replaceAll(re, '').trim();
      if (txt.isEmpty) continue;
      if (ms.isNotEmpty) {
        for (final m in ms) {
          final fr = m.group(3);
          final f = fr == null ? 0.0 : int.parse(fr) / math.pow(10, fr.length);
          out.add({'t': int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!) + f, 'l': txt});
        }
      }
    }
    if (out.isEmpty) {
      final lines = raw.split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final d = (durs[t.id] ?? 0) / 1000.0;
      final step = (d > 0 && lines.isNotEmpty) ? (d - 6) / lines.length : 4.0;
      for (var i = 0; i < lines.length; i++) {
        out.add({'t': 3 + i * step, 'l': lines[i]});
      }
    } else {
      out.sort((a, b) => (a['t'] as double).compareTo(b['t'] as double));
    }
    _p?.setString('ly.${t.id}', jsonEncode(out));
    _ly.remove(t.id);
    notifyListeners();
    return out.length;
  }

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    _watchNet();
    hijriAdj = _p!.getInt('hijriLocal') ?? _p!.getInt('hijriRemote') ?? 0;
    try {
      locals = (jsonDecode(_p!.getString('locals') ?? '[]') as List).whereType<Map>().map(Track.fromJson).toList();
    } catch (_) {}
    _loadUser();
    offline = (_p!.getStringList('off') ?? []).toSet();
    try {
      (jsonDecode(_p!.getString('durs') ?? '{}') as Map).forEach((k, v) => durs['$k'] = (v as num).toInt());
    } catch (_) {}
    try {
      final dir = await getApplicationDocumentsDirectory();
      offDir = '${dir.path}/off';
      await Directory(offDir).create(recursive: true);
    } catch (_) {}
    try {
      final j = jsonDecode(_p!.getString('tracks') ?? '[]') as List;
      tracks = j.whereType<Map>().map(Track.fromJson).toList();
      final a = jsonDecode(_p!.getString('albums') ?? '[]') as List;
      for (final m in a.whereType<Map>()) {
        albums['${m['id']}'] = Album('${m['id']}', '${m['name']}', '${m['reciter']}', '${m['cover']}', (m['at'] is num) ? (m['at'] as num).toInt() : 0);
      }
    } catch (_) {}
    if (tracks.isNotEmpty) {
      loaded = true;
      notifyListeners();
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final db = FirebaseFirestore.instance;
      final res = await Future.wait([db.collection('tracks').get(), db.collection('albums').get()]);
      final ts = res[0], as = res[1];
      final albs = <String, Album>{};
      for (final d in as.docs) {
        final x = d.data();
        albs[d.id] = Album(d.id, '${x['name'] ?? ''}', '${x['reciter'] ?? ''}', '${x['cover'] ?? ''}', (x['at'] is num) ? (x['at'] as num).toInt() : 0);
      }
      final out = <Track>[];
      for (final d in ts.docs) {
        final x = d.data();
        final audio = '${x['audio'] ?? ''}';
        if (audio.isEmpty || x['hidden'] == true) continue;
        final al = albs['${x['album'] ?? ''}'];
        final own = '${x['cover'] ?? ''}';
        out.add(Track(
          id: d.id,
          title: '${x['title'] ?? ''}',
          reciter: '${x['reciter'] ?? ''}',
          poet: '${x['poet'] ?? ''}',
          audio: audio,
          cover: own.isNotEmpty ? own : (al?.cover ?? ''),
          album: '${x['album'] ?? ''}',
          albumName: al?.name ?? '',
          cat: '${x['cat'] ?? 'أخرى'}',
          at: (x['at'] is num) ? (x['at'] as num).toInt() : 0,
          lyrics: Lyric.parse(x['lyrics'] ?? []),
        ));
      }
      out.sort((a, b) => b.at.compareTo(a.at));
      tracks = out;
      albums = albs;
      netOff = false;
      await _p?.setString('tracks', jsonEncode(out.map((e) => e.toJson()).toList()));
      await _p?.setString(
          'albums', jsonEncode(albs.values.map((a) => {'id': a.id, 'name': a.name, 'reciter': a.reciter, 'cover': a.cover, 'at': a.at}).toList()));
    } catch (_) {
      netOff = true;
    }
    loaded = true;
    notifyListeners();
  }

  Track? byId(String id) {
    for (final t in locals) {
      if (t.id == id) return t;
    }
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _savePls() {
    _p?.setString(_k('pls'), jsonEncode(pls.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Pl newPl(String name) {
    final p = Pl(DateTime.now().millisecondsSinceEpoch.toString(), name.trim().isEmpty ? 'قائمة جديدة' : name.trim(), []);
    pls.add(p);
    _savePls();
    return p;
  }

  void addToPl(Pl p, String id) {
    if (!p.ids.contains(id)) p.ids.add(id);
    _savePls();
  }

  void removeFromPl(Pl p, String id) {
    p.ids.remove(id);
    _savePls();
  }

  void delPl(Pl p) {
    pls.remove(p);
    _savePls();
  }

  List<Track> plTracks(Pl p) => p.ids.map(byId).whereType<Track>().toList();

  bool isFav(String id) => favs.contains(id);
  void Function()? onFav;
  void toggleFav(String id) {
    favs.contains(id) ? favs.remove(id) : favs.add(id);
    _p?.setStringList(_k('fav'), favs.toList());
    notifyListeners();
    onFav?.call();
  }

  /// الكلمات المعتمدة للجميع (lyrApproved) ثم كلمات القصيدة نفسها
  Future<List<Lyric>> lyricsFor(Track t) async {
    // بدون ذاكرة دائمة بالجلسة: كل فتح للقصيدة يجيب آخر تعديل (التعديلات من الويب تظهر فوراً)
    if (t.id.startsWith('loc_')) {
      final c = _p?.getString('ly.${t.id}');
      return c == null ? <Lyric>[] : Lyric.parse(c);
    }
    if (_ly.containsKey(t.id) && offline.contains(t.id)) return _ly[t.id]!;
    List<Lyric> r = [];
    final cached = _p?.getString('ly.${t.id}');
    if (cached != null) r = Lyric.parse(cached);
    if (r.isNotEmpty && offline.contains(t.id)) {
      _ly[t.id] = r;
      return r;
    }
    try {
      final d = await FirebaseFirestore.instance.doc('lyrApproved/${t.id}').get();
      if (d.exists) {
        final j = '${d.data()?['json'] ?? '[]'}';
        final n = Lyric.parse(j);
        if (n.isNotEmpty) {
          r = n;
          await _p?.setString('ly.${t.id}', j);
        }
      }
    } catch (_) {}
    if (r.isEmpty) r = t.lyrics;
    _ly[t.id] = r;
    return r;
  }

  String? get lastId => _p?.getString(_k('last.id'));
  int posOf(String id) => _p?.getInt(_k('pos.$id')) ?? 0;
  void savePos(String id, int ms, {int dur = 0}) {
    _p?.setInt(_k('pos.$id'), ms);
    _p?.setString(_k('last.id'), id);
    if (dur > 0 && durs[id] != dur) {
      durs[id] = dur;
      _p?.setString('durs', jsonEncode(durs));
    }
    if (recent.isEmpty || recent.last != id) {
      recent.remove(id);
      recent.add(id);
      if (recent.length > 40) recent.removeAt(0);
      _p?.setStringList(_k('recent'), recent);
    }
  }

  void toggleFollow(String r) {
    follows.contains(r) ? follows.remove(r) : follows.add(r);
    _p?.setStringList(_k('fol'), follows.toList());
    notifyListeners();
  }

  // ---- التنزيل للاستماع بدون إنترنت ----
  String? offPath(String id) => (offline.contains(id) || id.startsWith('loc_')) && offDir.isNotEmpty ? '$offDir/$id.audio' : null;

  Future<bool> offSave(Track t, void Function(double) prog) async {
    if (offDir.isEmpty) return false;
    final c = HttpClient();
    try {
      final r = await (await c.getUrl(Uri.parse(t.audioUrl))).close();
      if (r.statusCode != 200) return false;
      final f = File('$offDir/${t.id}.audio.tmp');
      final sink = f.openWrite();
      var got = 0;
      final total = r.contentLength;
      await for (final ch in r) {
        sink.add(ch);
        got += ch.length;
        if (total > 0) prog(got / total);
      }
      await sink.close();
      await f.rename('$offDir/${t.id}.audio');
      await lyricsFor(t); // الكلمات تُحفظ محلياً
      await _saveAux(t);
      offline.add(t.id);
      await _p?.setStringList('off', offline.toList());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      c.close(force: true);
    }
  }

  /// ملف التحليل (للمرئيات والموجة) + الغلاف يُحفظان مع التنزيل
  String? coverFile(String url) {
    if (offDir.isEmpty) return null;
    for (final t in tracks) {
      if (t.coverUrl == url && offline.contains(t.id)) {
        final f = '$offDir/${t.id}.cover';
        if (File(f).existsSync()) return f;
      }
    }
    return null;
  }

  Future<void> _saveAux(Track t) async {
    final c = HttpClient();
    try {
      final r = await (await c.getUrl(Uri.parse(absUrl('media/u/n/${t.id}-v1.bin')))).close();
      if (r.statusCode == 200) {
        final b = BytesBuilder();
        await for (final ch in r) {
          b.add(ch);
        }
        await File('$offDir/${t.id}.mba').writeAsBytes(b.takeBytes());
      }
    } catch (_) {}
    try {
      if (t.coverUrl.isNotEmpty) {
        final r = await (await c.getUrl(Uri.parse(t.coverUrl))).close();
        if (r.statusCode == 200) {
          final b = BytesBuilder();
          await for (final ch in r) {
            b.add(ch);
          }
          await File('$offDir/${t.id}.cover').writeAsBytes(b.takeBytes());
        }
      }
    } catch (_) {}
    c.close(force: true);
  }

  Future<void> offDel(Track t) async {
    try {
      for (final e in ['audio', 'mba', 'cover']) {
        final x = File('$offDir/${t.id}.$e');
        if (await x.exists()) await x.delete();
      }
    } catch (_) {}
    try {
      final f = File('$offDir/${t.id}.audio');
      if (await f.exists()) await f.delete();
    } catch (_) {}
    offline.remove(t.id);
    await _p?.setStringList('off', offline.toList());
    notifyListeners();
  }

  // ---- الأكثر استماعاً/إعجاباً ----
  Future<void> loadHot() async {
    if (DateTime.now().difference(_hotAt).inMinutes < 10) return;
    _hotAt = DateTime.now();
    final db = FirebaseFirestore.instance;
    try {
      // ضبط التاريخ الهجري العام (يحدده المشرف): يُحفظ للعمل بدون إنترنت
      final h = await db.doc('hijri/adj').get();
      final v = (h.data()?['v'] as num?)?.toInt();
      if (v != null) {
        await _p?.setInt('hijriRemote', v);
        if (_p?.getInt('hijriLocal') == null) hijriAdj = v;
      }
    } catch (_) {}
    // توفير حصة Firestore: الأكثر استماعاً/إعجاباً يُحفظ 3 ساعات بالجهاز
    final hc = _p?.getString('hot.v1');
    final hat = _p?.getInt('hot.at') ?? 0;
    var fromCache = false;
    if (hc != null && DateTime.now().millisecondsSinceEpoch - hat < 3 * 3600000) {
      try {
        final j = jsonDecode(hc) as Map;
        hotPlays = [for (final e in (j['p'] as List)) MapEntry('${e[0]}', (e[1] as num).toInt())];
        hotLikes = [for (final e in (j['l'] as List)) MapEntry('${e[0]}', (e[1] as num).toInt())];
        fromCache = true;
      } catch (_) {}
    }
    if (!fromCache) {
    try {
      final s = await db.collection('stats').orderBy('plays', descending: true).limit(12).get();
      hotPlays = s.docs.map((d) => MapEntry(d.id, ((d.data()['plays'] ?? 0) as num).toInt())).toList();
    } catch (_) {}
    try {
      final wk = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
      final s = await db.collection('rx').where('at', isGreaterThanOrEqualTo: wk).limit(800).get();
      final c = <String, int>{};
      for (final d in s.docs) {
        final k = '${d.data()['track']}';
        c[k] = (c[k] ?? 0) + 1;
      }
      final l = c.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      hotLikes = l.take(12).toList();
    } catch (_) {}
      try {
        await _p?.setString('hot.v1', jsonEncode({'p': [for (final e in hotPlays) [e.key, e.value]], 'l': [for (final e in hotLikes) [e.key, e.value]]}));
        await _p?.setInt('hot.at', DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}
    }
    notifyListeners();
  }

  void countPlay(String id) {
    if (id.startsWith('loc_')) return;
    FirebaseFirestore.instance.doc('stats/$id').set({'plays': FieldValue.increment(1)}, SetOptions(merge: true)).catchError((_) {});
  }

  // ---- بحث بنص الكلمات (يُحمَّل مرة ويُخزَّن) ----
  Future<void> loadAllLyrics() async {
    if (_allLyLoading || allLy.isNotEmpty) return;
    _allLyLoading = true;
    try {
      final at = _p?.getInt('allLy2.at') ?? 0;
      final cached = _p?.getString('allLy2');
      if (cached != null && DateTime.now().millisecondsSinceEpoch - at < 7 * 86400000) {
        (jsonDecode(cached) as Map).forEach((k, v) => allLy['$k'] = '$v');
      } else {
        final s = await FirebaseFirestore.instance.collection('lyrApproved').get();
        for (final d in s.docs) {
          allLy[d.id] = Lyric.parse(d.data()['json'] ?? '[]').map((e) => e.l).join('\n');
        }
        await _p?.setString('allLy2', jsonEncode(allLy));
        await _p?.setInt('allLy2.at', DateTime.now().millisecondsSinceEpoch);
      }
      notifyListeners();
    } catch (_) {}
    _allLyLoading = false;
  }
}
