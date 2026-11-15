import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'data.dart';
import 'state.dart';

/// جسر بين مشغّل just_audio وخدمة الصوت بالنظام:
/// الإشعار وشاشة القفل وأزرار السماعة، وAndroid Auto (قوائم تصفح، تشغيل، بحث صوتي).
class MinbarHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer p;
  MinbarHandler(this.p) {
    p.playbackEventStream.listen(_push, onError: (Object _, StackTrace __) {});
    p.playingStream.listen((_) => _push(p.playbackEvent));
    p.sequenceStateStream.listen((st) {
      final seq = st?.effectiveSequence ?? const <IndexedAudioSource>[];
      queue.add([for (final s in seq) if (s.tag is MediaItem) s.tag as MediaItem]);
      final cur = st?.currentSource?.tag;
      if (cur is MediaItem) mediaItem.add(cur.copyWith(duration: p.duration));
    });
    p.durationStream.listen((d) {
      final m = mediaItem.value;
      if (m != null && d != null && m.duration != d) mediaItem.add(m.copyWith(duration: d));
    });
  }

  static const _ps = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _push(PlaybackEvent e) {
    final playing = p.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.skipToPrevious, playing ? MediaControl.pause : MediaControl.play, MediaControl.skipToNext],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward, MediaAction.playFromMediaId, MediaAction.playFromSearch},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _ps[p.processingState]!,
      playing: playing,
      updatePosition: p.position,
      bufferedPosition: p.bufferedPosition,
      speed: p.speed,
      queueIndex: e.currentIndex,
    ));
  }

  @override
  Future<void> play() => p.play();
  @override
  Future<void> pause() => p.pause();
  @override
  Future<void> seek(Duration position) => p.seek(position);
  @override
  Future<void> stop() async {
    await p.pause();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => p.seekToNext();
  @override
  Future<void> skipToPrevious() async => app.player.prev();
  @override
  Future<void> skipToQueueItem(int index) => p.seek(Duration.zero, index: index);

  // ---------------- Android Auto ----------------
  Repo get _r => app.repo;

  List<Track> _list(String ctx) {
    final all = _r.tracks;
    if (ctx == 'fav') return all.where((t) => _r.isFav(t.id)).toList();
    if (ctx == AudioService.recentRootId) return _r.recent.reversed.map(_r.byId).whereType<Track>().toList();
    if (ctx == 'new') return ([...all]..sort((a, b) => b.at.compareTo(a.at))).take(60).toList();
    if (ctx.startsWith('al:')) return all.where((t) => t.album == ctx.substring(3)).toList();
    return all;
  }

  MediaItem _item(Track t, String ctx) => MediaItem(
        id: 't|$ctx|${t.id}',
        title: t.title,
        artist: t.reciter,
        album: t.albumName.isEmpty ? null : t.albumName,
        artUri: t.coverUrl.isEmpty ? null : Uri.tryParse(t.coverUrl),
        playable: true,
      );

  MediaItem _folder(String id, String title, [String? sub]) => MediaItem(id: id, title: title, displaySubtitle: sub, playable: false);

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async {
    switch (parentMediaId) {
      case AudioService.browsableRootId:
        return [
          _folder('fav', 'المفضلة', '${_r.favs.length} قصيدة'),
          _folder(AudioService.recentRootId, 'آخر ما استمعت'),
          _folder('new', 'الأحدث'),
          _folder('albums', 'الإصدارات', '${_r.albums.length} إصدار'),
        ];
      case 'albums':
        final al = _r.albums.values.toList()..sort((a, b) => b.at.compareTo(a.at));
        return [for (final a in al) MediaItem(id: 'al:${a.id}', title: a.name, artist: a.reciter, artUri: a.cover.isEmpty ? null : Uri.tryParse(a.cover), playable: false)];
      default:
        return [for (final t in _list(parentMediaId)) _item(t, parentMediaId)];
    }
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final parts = mediaId.split('|');
    final t = parts.length == 3 ? _r.byId(parts[2]) : _r.byId(mediaId);
    return t == null ? null : _item(t, parts.length == 3 ? parts[1] : 'all');
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    final parts = mediaId.split('|');
    if (parts.length != 3) return;
    final list = _list(parts[1]);
    final i = list.indexWhere((t) => t.id == parts[2]);
    if (i >= 0) await app.player.playList(list, i);
  }

  /// «شغّل … على منبر» من المساعد الصوتي
  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) async {
    String n(String s) => s.replaceAll(RegExp('[ً-ٟـ]'), '').replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').toLowerCase().trim();
    final q = n(query);
    var list = q.isEmpty ? _list('fav') : _r.tracks.where((t) => n('${t.title} ${t.reciter} ${t.albumName} ${t.poet}').contains(q)).toList();
    if (list.isEmpty) list = _list('new');
    if (list.isNotEmpty) await app.player.playList(list, 0);
  }
}
