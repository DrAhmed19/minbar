import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'data.dart';
import 'occasion.dart';
import 'player_ui.dart';
import 'samples.dart';
import 'state.dart';
import 'ui.dart';

void snack(BuildContext c, String s) {
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s, style: tx(13, c: Colors.white)), duration: const Duration(seconds: 2)));
}

/// ========== الشاشة الرئيسية ==========
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int nav = 0, sub = 0;
  String cat = 'الكل';
  String q = '';
  bool searching = false;
  final _sc = TextEditingController();
  DateTime _lastBack = DateTime(2000);

  @override
  void initState() {
    super.initState();
    app.repo.addListener(_r);
    app.player.addListener(_r);
    if (app.repo.loaded) app.player.restore();
    Future.delayed(const Duration(seconds: 4), _checkUpdate);
    app.repo.loadHot();
  }

  void _r() {
    if (mounted) setState(() {});
    if (app.repo.loaded) app.player.restore();
  }

  Future<void> _checkUpdate() async {
    final n = await latestBuild();
    if (!mounted || kBuild == 0 || n <= kBuild) return;
    showDialog(
      context: context,
      builder: (d) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تحديث جديد', style: tx(17, w: FontWeight.w800)),
          content: Text('نزلت نسخة أحدث من منبر. حمّلها وثبّتها فوق النسخة الحالية (بياناتك تبقى).', style: tx(13.5, w: FontWeight.w500, h: 1.7)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text('لاحقاً', style: tx(13, c: kMuted))),
            TextButton(
              onPressed: () {
                Navigator.pop(d);
                launchApk();
              },
              child: Text('تحديث', style: tx(13.5, c: kGreen, w: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    app.repo.removeListener(_r);
    app.player.removeListener(_r);
    _sc.dispose();
    super.dispose();
  }

  List<Track> get _found {
    final k = norm(q);
    final r = app.repo;
    if (k.isEmpty) return r.tracks;
    return r.tracks.where((t) => norm('${t.title} ${t.reciter} ${t.poet} ${t.albumName} ${t.cat}').contains(k) || norm(r.allLy[t.id] ?? '').contains(k)).toList();
  }

  void _play(List<Track> l, Track t) => app.player.playList(l, l.indexOf(t));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (searching) {
          setState(() {
            searching = false;
            q = '';
            _sc.clear();
          });
          return;
        }
        if (nav != 0 || sub != 0) {
          setState(() {
            nav = 0;
            sub = 0;
          });
          return;
        }
        final now = DateTime.now();
        if (now.difference(_lastBack).inMilliseconds < 2200) {
          SystemNavigator.pop();
        } else {
          _lastBack = now;
          snack(context, app.player.p.playing ? 'اضغط رجوع مرة ثانية للخروج (الصوت يستمر بالخلفية)' : 'اضغط رجوع مرة ثانية للخروج');
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: kCream,
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              _header(),
              if (nav == 0 && !searching) _subTabs(),
              Expanded(child: _body()),
              _mini(),
            ]),
          ),
          bottomNavigationBar: _nav(),
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 6),
        child: Row(children: [
          SizedBox(width: 28, height: 30, child: CustomPaint(painter: LogoPainter(0.2))),
          const SizedBox(width: 8),
          if (!searching) Text('منبر', style: tx(24, w: FontWeight.w800, c: kGreen)),
          if (searching)
            Expanded(
              child: TextField(
                controller: _sc,
                autofocus: true,
                style: tx(14),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الرادود أو الكلمات…',
                  hintStyle: tx(13, c: kMuted),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onChanged: (v) {
                  setState(() => q = v);
                  app.repo.loadAllLyrics();
                },
              ),
            ),
          if (!searching) const Spacer(),
          IconButton(
            onPressed: () => setState(() {
              searching = !searching;
              if (!searching) {
                q = '';
                _sc.clear();
              }
            }),
            icon: Icon(searching ? Icons.close : Icons.search, color: kGreen),
          ),
          if (!searching) IconButton(onPressed: _accountSheet, icon: const Icon(Icons.person_outline, color: kGreen)),
        ]),
      );

  Widget _subTabs() {
    const names = ['الرئيسية', 'القصائد', 'الإصدارات', 'الرواديد'];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE9E2D0), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: List.generate(4, (i) {
          final on = sub == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => sub = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Text(names[i], textAlign: TextAlign.center, style: tx(13, c: on ? kGreen : kMuted, w: on ? FontWeight.w800 : FontWeight.w600)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _body() {
    final r = app.repo;
    if (!r.loaded) return const Center(child: CircularProgressIndicator(color: kGreen));
    if (searching && q.isNotEmpty) {
      final l = _found;
      return l.isEmpty ? _empty('ما لقيت نتائج') : _list(l);
    }
    if (nav == 1) {
      final l = r.tracks.where((t) => r.isFav(t.id)).toList();
      return l.isEmpty ? _empty('ما عندك مفضلة بعد') : _list(l);
    }
    if (nav == 3) return _playlists();
    switch (sub) {
      case 1:
        return _poems();
      case 2:
        return _albums();
      case 3:
        return _reciters();
      default:
        return HomeTab(onPlay: _play);
    }
  }

  Widget _empty(String s) => Center(child: Text(s, style: tx(14, c: kMuted)));

  Widget _list(List<Track> l) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: l.length,
        itemBuilder: (_, i) => TrackTile(l[i], onTap: () => _play(l, l[i])),
      );

  Widget _poems() {
    final cats = ['الكل', ...{for (final t in app.repo.tracks) t.cat}];
    final l = app.repo.tracks.where((t) => cat == 'الكل' || t.cat == cat).toList();
    return Column(children: [
      SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: [
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: ChoiceChip(
                  label: Text(c, style: tx(12.5, c: cat == c ? Colors.white : kGreen)),
                  selected: cat == c,
                  selectedColor: kGreen,
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => cat = c),
                ),
              ),
          ],
        ),
      ),
      Expanded(child: _list(l)),
    ]);
  }

  Widget _albums() {
    final al = app.repo.albums.values.where((a) => app.repo.tracks.any((t) => t.album == a.id)).toList()..sort((a, b) => b.at.compareTo(a.at));
    if (al.isEmpty) return _empty('لا توجد إصدارات بعد');
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82),
      itemCount: al.length,
      itemBuilder: (_, i) => AlbumCard(al[i], big: true),
    );
  }

  Widget _reciters() {
    final m = <String, List<Track>>{};
    for (final t in app.repo.tracks) {
      final k = t.reciter.trim().isEmpty ? 'غير معروف' : t.reciter.trim();
      m.putIfAbsent(k, () => []).add(t);
    }
    final ks = m.keys.toList()..sort((a, b) => m[b]!.length.compareTo(m[a]!.length));
    return ListView.builder(
      itemCount: ks.length,
      itemBuilder: (_, i) {
        final l = m[ks[i]]!;
        final na = l.map((t) => t.album).where((e) => e.isNotEmpty).toSet().length;
        return ListTile(
          leading: Cover(l.first.coverUrl, size: 48, radius: 24),
          title: Text(ks[i], style: tx(14.5, w: FontWeight.w800)),
          subtitle: Text('${l.length} قصيدة${na > 0 ? ' · $na إصدار' : ''}', style: tx(12, c: kMuted, w: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_left, color: kMuted),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(ks[i], l, reciter: ks[i]))),
        );
      },
    );
  }

  Widget _playlists() {
    final r = app.repo;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: GoldPill('قائمة جديدة', Icons.add, () async {
            final n = await askName(context);
            if (n != null) r.newPl(n);
          }),
        ),
      ),
      Expanded(
        child: r.pls.isEmpty
            ? _empty('ما عندك قوائم. اضغط مطوّلاً على أي قصيدة لإضافتها.')
            : ListView.builder(
                itemCount: r.pls.length,
                itemBuilder: (_, i) {
                  final p = r.pls[i];
                  final tl = r.plTracks(p);
                  return ListTile(
                    leading: Cover(tl.isEmpty ? '' : tl.first.coverUrl, size: 50, radius: 12),
                    title: Text(p.name, style: tx(14.5, w: FontWeight.w800)),
                    subtitle: Text('${tl.length} قصيدة', style: tx(12, c: kMuted, w: FontWeight.w500)),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: kMuted), onPressed: () => r.delPl(p)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(p.name, tl))),
                  );
                },
              ),
      ),
    ]);
  }

  void _accountSheet() {
    final a = app.auth;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (s) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                CircleAvatar(radius: 26, backgroundColor: kGreen, child: const Icon(Icons.person, color: kGold)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.guest ? 'ضيف' : (a.user?.displayName ?? ''), style: tx(16, w: FontWeight.w800)),
                    Text(a.guest ? 'تستمع بدون حساب' : (a.user?.email ?? ''), style: tx(12, c: kMuted, w: FontWeight.w500)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.refresh, color: kGreen),
                title: Text('تحديث المكتبة', style: tx(14)),
                onTap: () {
                  Navigator.pop(s);
                  app.repo.refresh();
                  snack(context, 'جارٍ التحديث…');
                },
              ),
              ListTile(
                leading: const Icon(Icons.system_update_alt, color: kGreen),
                title: Text('التحقق من تحديث التطبيق', style: tx(14)),
                subtitle: Text('نسخة 1.0 · بناء $kBuild', style: tx(11.5, c: kMuted)),
                onTap: () async {
                  Navigator.pop(s);
                  final n = await latestBuild();
                  if (!mounted) return;
                  if (n > kBuild) {
                    launchApk();
                  } else {
                    snack(context, 'أنت على آخر نسخة');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: kGreen),
                title: Text(a.guest ? 'تسجيل الدخول بحساب' : 'تسجيل الخروج', style: tx(14)),
                onTap: () {
                  Navigator.pop(s);
                  a.signOut();
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _mini() {
    final t = app.player.cur;
    if (t == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => openPlayer(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Cover(t.coverUrl, size: 42, radius: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14, w: FontWeight.w800)),
                Text(t.reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: kMuted, w: FontWeight.w500)),
              ]),
            ),
            StreamBuilder<bool>(
              stream: app.player.p.playingStream,
              builder: (_, s) => IconButton(onPressed: app.player.toggle, icon: Icon((s.data ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32, color: kGreen)),
            ),
            IconButton(onPressed: app.player.next, icon: const Icon(Icons.skip_previous_rounded, size: 28, color: kGreen)),
          ]),
          StreamBuilder<Duration>(
            stream: app.player.p.positionStream,
            builder: (_, s) {
              final d = app.player.p.duration?.inMilliseconds ?? 0;
              final v = d > 0 ? ((s.data?.inMilliseconds ?? 0) / d).clamp(0.0, 1.0) : 0.0;
              return LinearProgressIndicator(value: v, minHeight: 2.5, backgroundColor: const Color(0x14000000), color: kGold);
            },
          ),
        ]),
      ),
    );
  }

  Widget _nav() {
    Widget item(int i, IconData ic, String s, {VoidCallback? f}) {
      final on = nav == i;
      return Expanded(
        child: InkWell(
          onTap: f ?? () => setState(() => nav = i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(ic, color: on ? kGreen : kMuted, size: 23),
              const SizedBox(height: 2),
              Text(s, style: tx(11, c: on ? kGreen : kMuted, w: on ? FontWeight.w800 : FontWeight.w600)),
            ]),
          ),
        ),
      );
    }

    return Container(
      color: kCream,
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(children: [
            item(0, Icons.library_music_outlined, 'المكتبة'),
            item(1, Icons.favorite_border, 'المفضلة'),
            item(2, Icons.slow_motion_video_rounded, 'عينات', f: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SamplesPage()))),
            item(3, Icons.queue_music_rounded, 'القوائم'),
          ]),
        ),
      ),
    );
  }
}

void openPlayer(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const PlayerPage(),
      transitionsBuilder: (_, a, __, c) => SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c),
    ),
  );
}

/// ========== تبويب الرئيسية ==========
class HomeTab extends StatelessWidget {
  final void Function(List<Track>, Track) onPlay;
  const HomeTab({super.key, required this.onPlay});

  Widget _sec(String s) => Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(s, style: tx(17, w: FontWeight.w800)));

  Widget _row(List<Widget> c, {double h = 196}) => SizedBox(
        height: h,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: c),
      );

  Widget _card(Track t, List<Track> ctx, {String? sub, double? prog}) => GestureDetector(
        onTap: () => onPlay(ctx, t),
        onLongPress: () => trackSheet(_ctx!, t),
        child: Container(
          width: 128,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Cover(t.coverUrl, size: 128, radius: 16),
              if (app.repo.offline.contains(t.id)) const Positioned(top: 6, left: 6, child: Icon(Icons.download_done_rounded, color: kGold, size: 18)),
              if (prog != null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: prog.clamp(0.0, 1.0), minHeight: 4, backgroundColor: Colors.black38, color: kGold)),
                ),
            ]),
            const SizedBox(height: 6),
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, w: FontWeight.w800)),
            Text(sub ?? t.reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: kMuted, w: FontWeight.w500)),
          ]),
        ),
      );

  static BuildContext? _ctx;

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    return ListenableBuilder(
      listenable: app.repo,
      builder: (_, __) {
        final r = app.repo;
        final all = r.tracks;
        final body = <Widget>[];

        // مناسبة اليوم / القادمة
        final o = occasionToday();
        if (o != null) {
          final l = all.where((t) => o.k.any((k) => '${t.title} ${t.cat} ${t.poet}'.contains(k))).toList();
          body.add(_occ('مناسبة اليوم', o.t, l.isNotEmpty ? '${l.length} قصيدة مناسبة' : 'لا توجد قصائد مصنّفة لهذه المناسبة بعد', l.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(o.t, l)))));
        } else {
          final nx = occasionNext();
          if (nx != null) body.add(_occ('مناسبة قادمة', nx.t, nx.d == 1 ? 'غداً' : 'بعد ${nx.d} أيام', null));
        }

        // أكمل الاستماع
        final cont = r.recent.reversed.map(r.byId).whereType<Track>().where((t) {
          final d = r.durs[t.id] ?? 0, p = r.posOf(t.id);
          return p > 15000 && (d == 0 || p < d - 20000);
        }).take(10).toList();
        if (cont.isNotEmpty) {
          body.add(_sec('أكمل الاستماع'));
          body.add(_row([
            for (final t in cont)
              _card(t, all, sub: (r.durs[t.id] ?? 0) > 0 ? 'متبقٍ ${fmt(((r.durs[t.id]! - r.posOf(t.id)) / 1000).toDouble())}' : 'من ${fmt(r.posOf(t.id) / 1000)}', prog: (r.durs[t.id] ?? 0) > 0 ? r.posOf(t.id) / r.durs[t.id]! : 0.0),
          ]));
        }

        // رواديد تتابعهم
        final fol = all.where((t) => r.follows.contains(t.reciter.trim())).take(12).toList();
        if (fol.isNotEmpty) {
          body.add(_sec('من رواديد تتابعهم'));
          body.add(_row([for (final t in fol) _card(t, all)]));
        }

        // جديد الإصدارات
        final albs = r.albums.values.where((a) => all.any((t) => t.album == a.id)).toList()..sort((a, b) => b.at.compareTo(a.at));
        if (albs.isNotEmpty) {
          body.add(_sec('جديد الإصدارات'));
          body.add(_row([for (final a in albs.take(10)) AlbumCard(a)], h: 186));
        }

        // أُضيفت حديثاً
        final fresh = all.where((t) => t.at > 0).take(12).toList();
        if (fresh.isNotEmpty) {
          body.add(_sec('أُضيفت حديثاً'));
          body.add(_row([for (final t in fresh) _card(t, all)]));
        }

        // الأكثر إعجاباً / استماعاً
        final likes = r.hotLikes.map((e) => (r.byId(e.key), e.value)).where((e) => e.$1 != null).toList();
        if (likes.isNotEmpty) {
          body.add(_sec('الأكثر إعجاباً هذا الأسبوع'));
          body.add(_row([for (final e in likes) _card(e.$1!, all, sub: '❤ ${e.$2}')]));
        }
        final plays = r.hotPlays.map((e) => (r.byId(e.key), e.value)).where((e) => e.$1 != null).toList();
        if (plays.isNotEmpty) {
          body.add(_sec('الأكثر استماعاً'));
          body.add(_row([for (final e in plays) _card(e.$1!, all, sub: '${e.$2} استماع')]));
        }

        // التنزيلات
        final offs = r.offline.map(r.byId).whereType<Track>().toList();
        if (offs.isNotEmpty) {
          body.add(_sec('التنزيلات (بدون إنترنت)'));
          body.add(_row([for (final t in offs) _card(t, offs)]));
        }

        if (body.isEmpty || (body.length == 1 && o == null)) {
          body.add(Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(all.isEmpty ? 'لا توجد قصائد بعد' : 'ابدأ الاستماع لتظهر هنا اقتراحاتك', style: tx(14, c: kMuted)))));
        }
        return RefreshIndicator(
          color: kGreen,
          onRefresh: () async {
            await r.refresh();
            r.loadHot();
          },
          child: ListView(padding: const EdgeInsets.only(bottom: 14), children: body),
        );
      },
    );
  }

  Widget _occ(String k, String t, String s, VoidCallback? f) => GestureDetector(
        onTap: f,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF1F6A52), Color(0xFF0C4A39)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: tx(11.5, c: kGold, w: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(t, style: tx(19, c: Colors.white, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(s, style: tx(12.5, c: Colors.white70, w: FontWeight.w500)),
          ]),
        ),
      );
}

class AlbumCard extends StatelessWidget {
  final Album a;
  final bool big;
  const AlbumCard(this.a, {super.key, this.big = false});

  @override
  Widget build(BuildContext context) {
    final tl = app.repo.tracks.where((t) => t.album == a.id).toList();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(a.name, tl, sub: a.reciter, cover: absUrl(a.cover)))),
      child: Container(
        width: big ? null : 112,
        margin: big ? null : const EdgeInsets.symmetric(horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          big ? Expanded(child: LayoutBuilder(builder: (_, c) => Cover(absUrl(a.cover), size: c.maxWidth, radius: 16))) : Cover(absUrl(a.cover), size: 112, radius: 16),
          const SizedBox(height: 6),
          Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(big ? 13.5 : 12.5, w: FontWeight.w800)),
          Text('${a.reciter.isEmpty ? '' : '${a.reciter} · '}${tl.length} قصيدة', maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: kMuted, w: FontWeight.w500)),
        ]),
      ),
    );
  }
}

/// ========== صفحة مجموعة: إصدار / رادود / قائمة ==========
class GroupPage extends StatefulWidget {
  final String title, sub, cover;
  final String? reciter;
  final List<Track> tracks;
  const GroupPage(this.title, this.tracks, {super.key, this.sub = '', this.cover = '', this.reciter});
  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  @override
  Widget build(BuildContext context) {
    final r = app.repo, tl = widget.tracks;
    final cv = widget.cover.isNotEmpty ? widget.cover : (tl.isEmpty ? '' : tl.first.coverUrl);
    final fol = widget.reciter != null && r.follows.contains(widget.reciter!);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(backgroundColor: kCream, elevation: 0, foregroundColor: kGreen),
        body: ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: [
              Cover(cv, size: 104, radius: widget.reciter != null ? 52 : 18),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: tx(19, w: FontWeight.w800, c: kGreen)),
                  Text([widget.sub, '${tl.length} قصيدة'].where((e) => e.isNotEmpty).join(' · '), style: tx(12.5, c: kMuted, w: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(children: [
                    GoldPill('تشغيل', Icons.play_arrow_rounded, tl.isEmpty ? () {} : () => app.player.playList(tl, 0)),
                    if (widget.reciter != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          r.toggleFollow(widget.reciter!);
                          setState(() {});
                          snack(context, fol ? 'ألغيت متابعة ${widget.reciter}' : 'تتابع ${widget.reciter}');
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: kGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11)),
                        child: Text(fol ? '✓ تتابعه' : '＋ متابعة', style: tx(13, c: kGreen, w: FontWeight.w800)),
                      ),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),
          for (var i = 0; i < tl.length; i++) TrackTile(tl[i], onTap: () => app.player.playList(tl, i)),
        ]),
      ),
    );
  }
}

Future<String?> askName(BuildContext context) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('اسم القائمة', style: tx(16, w: FontWeight.w800)),
        content: TextField(controller: c, autofocus: true, style: tx(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: tx(13, c: kMuted))),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: Text('إنشاء', style: tx(13, c: kGreen, w: FontWeight.w800))),
        ],
      ),
    ),
  );
}

/// ========== قائمة إجراءات القصيدة ==========
void trackSheet(BuildContext context, Track t) {
  final r = app.repo, pc = app.player;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (sheet) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: Cover(t.coverUrl, size: 48, radius: 10), title: Text(t.title, style: tx(15, w: FontWeight.w800)), subtitle: Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), style: tx(12, c: kMuted, w: FontWeight.w500))),
            Row(children: [
              _q(Icons.play_arrow_rounded, 'تشغيل الآن', () {
                Navigator.pop(sheet);
                pc.playList([t], 0);
              }),
              if (pc.cur != null && pc.cur!.id != t.id) ...[
                _q(Icons.queue_play_next_rounded, 'التالي', () {
                  Navigator.pop(sheet);
                  pc.playNext(t);
                  snack(context, 'ستُشغَّل بعد الحالية');
                }),
                _q(Icons.playlist_add_rounded, 'آخر القائمة', () {
                  Navigator.pop(sheet);
                  pc.addToEnd(t);
                  snack(context, 'أُضيفت إلى قائمة التشغيل');
                }),
              ],
            ]),
            _a(r.isFav(t.id) ? Icons.favorite : Icons.favorite_border, r.isFav(t.id) ? 'إزالة من المفضلة' : 'إضافة للمفضلة', () {
              Navigator.pop(sheet);
              r.toggleFav(t.id);
            }),
            _a(Icons.playlist_add, 'إضافة إلى قائمة', () async {
              Navigator.pop(sheet);
              final pick = await showModalBottomSheet<Pl>(
                context: context,
                backgroundColor: Colors.white,
                builder: (s2) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: SafeArea(
                    child: ListView(shrinkWrap: true, children: [
                      for (final p in r.pls) ListTile(title: Text(p.name, style: tx(14.5)), subtitle: Text('${p.ids.length} قصيدة', style: tx(11.5, c: kMuted)), onTap: () => Navigator.pop(s2, p)),
                      ListTile(
                        leading: const Icon(Icons.add, color: kGreen),
                        title: Text('قائمة جديدة', style: tx(14.5, c: kGreen, w: FontWeight.w800)),
                        onTap: () async {
                          final n = await askName(s2);
                          if (n != null && s2.mounted) Navigator.pop(s2, r.newPl(n));
                        },
                      ),
                    ]),
                  ),
                ),
              );
              if (pick != null) {
                r.addToPl(pick, t.id);
                if (context.mounted) snack(context, 'أُضيفت إلى «${pick.name}»');
              }
            }),
            _a(Icons.share_outlined, 'نسخ رابط المشاركة', () {
              Navigator.pop(sheet);
              Clipboard.setData(ClipboardData(text: '${kBase}?p=${t.id}'));
              snack(context, 'نُسخ الرابط');
            }),
            if (r.offline.contains(t.id))
              _a(Icons.delete_outline, 'حذف التنزيل', () {
                Navigator.pop(sheet);
                r.offDel(t);
                snack(context, 'حُذف التنزيل');
              })
            else
              _a(Icons.download_rounded, 'تنزيل للاستماع بدون إنترنت', () async {
                Navigator.pop(sheet);
                snack(context, 'جارٍ تنزيل «${t.title}»…');
                final ok = await r.offSave(t, (_) {});
                if (context.mounted) snack(context, ok ? 'نُزّلت — تعمل بدون إنترنت' : 'تعذّر التنزيل');
              }),
            if (t.album.isNotEmpty && r.albums.containsKey(t.album))
              _a(Icons.album_outlined, 'الذهاب للإصدار', () {
                Navigator.pop(sheet);
                final a = r.albums[t.album]!;
                Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(a.name, r.tracks.where((x) => x.album == a.id).toList(), sub: a.reciter, cover: absUrl(a.cover))));
              }),
            if (t.reciter.trim().isNotEmpty)
              _a(Icons.person_outline, 'الذهاب للرادود', () {
                Navigator.pop(sheet);
                final k = t.reciter.trim();
                Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(k, r.tracks.where((x) => x.reciter.trim() == k).toList(), reciter: k)));
              }),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    ),
  );
}

Widget _q(IconData i, String s, VoidCallback f) => Expanded(
      child: InkWell(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(children: [Icon(i, color: kGreen, size: 26), const SizedBox(height: 3), Text(s, style: tx(11.5, w: FontWeight.w700))]),
        ),
      ),
    );

Widget _a(IconData i, String s, VoidCallback f) => ListTile(leading: Icon(i, color: kGreen), title: Text(s, style: tx(14)), onTap: f);

class TrackTile extends StatelessWidget {
  final Track t;
  final VoidCallback onTap;
  const TrackTile(this.t, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cur = app.player.cur?.id == t.id;
    final fav = app.repo.isFav(t.id);
    return ListTile(
      onTap: onTap,
      onLongPress: () => trackSheet(context, t),
      leading: Cover(t.coverUrl, size: 50, radius: 12),
      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14.5, w: FontWeight.w800, c: cur ? kGreen : kInk)),
      subtitle: Row(children: [
        if (app.repo.offline.contains(t.id)) const Padding(padding: EdgeInsetsDirectional.only(end: 4), child: Icon(Icons.download_done_rounded, size: 14, color: kGreen)),
        Expanded(child: Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: kMuted, w: FontWeight.w500))),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (cur) const Icon(Icons.graphic_eq, color: kGold),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => app.repo.toggleFav(t.id),
          icon: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 20, color: fav ? const Color(0xFFD9534F) : kMuted),
        ),
      ]),
    );
  }
}
