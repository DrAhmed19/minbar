import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  Album(this.id, this.name, this.reciter, this.cover);
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

class Repo extends ChangeNotifier {
  List<Track> tracks = [];
  Map<String, Album> albums = {};
  Set<String> favs = {};
  bool loaded = false, offline = false;
  final Map<String, List<Lyric>> _ly = {};
  SharedPreferences? _p;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    favs = (_p!.getStringList('fav') ?? []).toSet();
    try {
      final j = jsonDecode(_p!.getString('tracks') ?? '[]') as List;
      tracks = j.whereType<Map>().map(Track.fromJson).toList();
      final a = jsonDecode(_p!.getString('albums') ?? '[]') as List;
      for (final m in a.whereType<Map>()) {
        albums['${m['id']}'] = Album('${m['id']}', '${m['name']}', '${m['reciter']}', '${m['cover']}');
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
        albs[d.id] = Album(d.id, '${x['name'] ?? ''}', '${x['reciter'] ?? ''}', '${x['cover'] ?? ''}');
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
      offline = false;
      await _p?.setString('tracks', jsonEncode(out.map((e) => e.toJson()).toList()));
      await _p?.setString(
          'albums', jsonEncode(albs.values.map((a) => {'id': a.id, 'name': a.name, 'reciter': a.reciter, 'cover': a.cover}).toList()));
    } catch (_) {
      offline = true;
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
  void savePos(String id, int ms) {
    _p?.setInt('pos.$id', ms);
    _p?.setString('last.id', id);
  }
}
