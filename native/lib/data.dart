import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      out.sort((a, b) => a.t.compareTo(b.t));
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

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    favs = (_p!.getStringList('fav') ?? []).toSet();
    follows = (_p!.getStringList('fol') ?? []).toSet();
    offline = (_p!.getStringList('off') ?? []).toSet();
    recent = _p!.getStringList('recent') ?? [];
    try {
      (jsonDecode(_p!.getString('durs') ?? '{}') as Map).forEach((k, v) => durs['$k'] = (v as num).toInt());
    } catch (_) {}
    try {
      final dir = await getApplicationDocumentsDirectory();
      offDir = '${dir.path}/off';
      await Directory(offDir).create(recursive: true);
    } catch (_) {}
    try {
      final j = jsonDecode(_p!.getString('pls') ?? '[]') as List;
      pls = j.whereType<Map>().map((m) => Pl('${m['id']}', '${m['name']}', ((m['ids'] ?? []) as List).map((e) => '$e').toList())).toList();
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
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _savePls() {
    _p?.setString('pls', jsonEncode(pls.map((e) => e.toJson()).toList()));
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
  void toggleFav(String id) {
    favs.contains(id) ? favs.remove(id) : favs.add(id);
    _p?.setStringList('fav', favs.toList());
    notifyListeners();
  }

  /// الكلمات المعتمدة للجميع (lyrApproved) ثم كلمات القصيدة نفسها
  Future<List<Lyric>> lyricsFor(Track t) async {
    if (_ly.containsKey(t.id)) return _ly[t.id]!;
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

  String? get lastId => _p?.getString('last.id');
  int posOf(String id) => _p?.getInt('pos.$id') ?? 0;
  void savePos(String id, int ms, {int dur = 0}) {
    _p?.setInt('pos.$id', ms);
    _p?.setString('last.id', id);
    if (dur > 0 && durs[id] != dur) {
      durs[id] = dur;
      _p?.setString('durs', jsonEncode(durs));
    }
    if (recent.isEmpty || recent.last != id) {
      recent.remove(id);
      recent.add(id);
      if (recent.length > 40) recent.removeAt(0);
      _p?.setStringList('recent', recent);
    }
  }

  void toggleFollow(String r) {
    follows.contains(r) ? follows.remove(r) : follows.add(r);
    _p?.setStringList('fol', follows.toList());
    notifyListeners();
  }

  // ---- التنزيل للاستماع بدون إنترنت ----
  String? offPath(String id) => offline.contains(id) && offDir.isNotEmpty ? '$offDir/$id.audio' : null;

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
    notifyListeners();
  }

  void countPlay(String id) {
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
