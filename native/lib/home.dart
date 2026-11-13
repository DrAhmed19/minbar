import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'data.dart';
import 'occasion.dart';
import 'player_ui.dart';
import 'samples.dart';
import 'state.dart';
import 'tools.dart';
import 'extras.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_links/app_links.dart';
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
  StreamSubscription? _linkSub;

  /// فتح رابط الموقع داخل التطبيق: ?p=<id>&t=<ثانية>
  Future<void> _link(Uri? u) async {
    final mj = u?.queryParameters['mj'];
    if (mj != null && RegExp(r'^\d{4,6}$').hasMatch(mj)) {
      for (var i = 0; i < 40 && !app.repo.loaded; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
      if (!mounted) return;
      await majlis.start(context, false, mj);
      if (mounted && majlis.on) {
        openPlayer(context);
        showMajlisSheet(context);
      }
      return;
    }
    final id = u?.queryParameters['p'];
    if (id == null) return;
    for (var i = 0; i < 40 && !app.repo.loaded; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    final t = app.repo.byId(id);
    if (t == null || !mounted) return;
    final at = double.tryParse(u!.queryParameters['t'] ?? '') ?? 0;
    final all = app.repo.tracks;
    app.player.playList(all, all.indexOf(t), pos: Duration(milliseconds: (at * 1000).round()));
    openPlayer(context);
  }

  @override
  void initState() {
    super.initState();
    app.repo.addListener(_r);
    app.player.addListener(_r);
    if (app.repo.loaded) app.player.restore();
    Future.delayed(const Duration(seconds: 4), _checkUpdate);
    Future.delayed(const Duration(seconds: 6), extrasStart);
    final al = AppLinks();
    al.getInitialLink().then(_link).catchError((_) {});
    _linkSub = al.uriLinkStream.listen(_link, onError: (_) {});
    app.repo.loadHot();
  }

  void _r() {
    if (mounted) setState(() {});
    if (app.repo.loaded) app.player.restore();
  }

  Future<void> _checkUpdate() async {
    final up = await latestUpdate();
    final n = up.build;
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
                launchApk(up.url);
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
    _linkSub?.cancel();
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
          // لا نغلق التطبيق: يُخفى فقط (مثل زر الرئيسية) فيرجع بنفس المكان فوراً والصوت مستمر
          const MethodChannel('minbar/fx').invokeMethod('bg').catchError((_) => SystemNavigator.pop());
        } else {
          _lastBack = now;
          snack(context, 'اضغط رجوع مرة ثانية لإخفاء التطبيق');
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: kCream,
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x330E5C46), Color(0x000E5C46)])),
                child: Column(children: [_header(), if (nav == 0 && !searching) _subTabs()]),
              ),
              Expanded(child: _body()),
              _mini(),
            ]),
          ),
          bottomNavigationBar: _nav(),
        ),
      ),
    );
  }

  Widget _ib(String ic, VoidCallback f, [String? label]) => Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: f,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0x210E5C46)), color: const Color(0x0DFFFFFF)),
          child: Center(child: PIcon(ic, color: const Color(0xFF083B2D), size: 21)),
        ),
      ));

  Widget _header() => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Image.asset('assets/brand-mark.png', width: 34, height: 34),
          const SizedBox(width: 9),
          if (!searching) Text('منبر', style: tx(21, w: FontWeight.w800, c: const Color(0xFF083B2D))),
          if (searching)
            Expanded(
              child: TextField(
                controller: _sc,
                autofocus: true,
                style: tx(14),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم القصيدة أو الرادود أو الشاعر',
                  hintStyle: tx(12.5, c: kMuted),
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
          if (!searching) _ib('mic', () => recognizePoem(context), 'التعرف على القصيدة'),
          if (!searching) _ib(Ic.users, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), 'الإعدادات'),
          _ib(searching ? Ic.x : Ic.search, () => setState(() {
                searching = !searching;
                if (!searching) {
                  q = '';
                  _sc.clear();
                }
              })),
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
        return HomeTab(onPlay: _play, onSub: (i) => setState(() => sub = i));
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
          trailing: Transform.flip(flipX: true, child: const PIcon(Ic.back, color: kMuted)),
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
          child: GoldPill('قائمة جديدة', Ic.plus, () async {
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
                    trailing: IconButton(icon: const PIcon(Ic.x, color: kMuted), onPressed: () => r.delPl(p)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(p.name, tl))),
                  );
                },
              ),
      ),
    ]);
  }

  void _accountSheet() {
    final a = app.auth;
    showMSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (s) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                CircleAvatar(radius: 26, backgroundColor: kGreen, child: const PIcon(Ic.users, color: kGold)),
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
                leading: const PIcon(Ic.reset, color: kGreen),
                title: Text('تحديث المكتبة', style: tx(14)),
                onTap: () {
                  Navigator.pop(s);
                  app.repo.refresh();
                  snack(context, 'جارٍ التحديث…');
                },
              ),
              ListTile(
                leading: const PIcon(Ic.down, color: kGreen),
                title: Text('التحقق من تحديث التطبيق', style: tx(14)),
                subtitle: Text('نسخة 1.0 · بناء $kBuild', style: tx(11.5, c: kMuted)),
                onTap: () async {
                  Navigator.pop(s);
                  final up = await latestUpdate();
                  if (!mounted) return;
                  if (up.build > kBuild) {
                    launchApk(up.url);
                  } else {
                    snack(context, 'أنت على آخر نسخة');
                  }
                },
              ),
              ListTile(
                leading: const PIcon(Ic.power, color: kGreen),
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
    return Semantics(label: 'فتح المشغل', button: true, child: GestureDetector(
      onTap: () => openPlayer(context),
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -250) openPlayer(context);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x2E0E5C46), blurRadius: 24, offset: Offset(0, 8))]),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          StreamBuilder<Duration>(
            stream: app.player.p.positionStream,
            builder: (_, s) {
              final d = app.player.p.duration?.inMilliseconds ?? 0;
              final v = d > 0 ? ((s.data?.inMilliseconds ?? 0) / d).clamp(0.0, 1.0) : 0.0;
              return LinearProgressIndicator(value: v, minHeight: 3, backgroundColor: const Color(0x1A0E5C46), color: const Color(0xFFC8A24B));
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(children: [
              Cover(t.coverUrl, size: 44, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14.5)),
                  Text(t.reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: kMuted)),
                ]),
              ),
              StreamBuilder<bool>(
                stream: app.player.p.playingStream,
                builder: (_, s) => IconButton(onPressed: app.player.toggle, icon: PIcon((s.data ?? false) ? Ic.pause : Ic.play, size: 24, color: kGreen)),
              ),
              IconButton(onPressed: app.player.next, icon: const PIcon(Ic.next, size: 22, color: kGreen)),
            ]),
          ),
        ]),
      ),
    ));
  }

  Widget _nav() {
    Widget item(int i, String ic, String s, {VoidCallback? f}) {
      final on = nav == i;
      return Expanded(
        child: InkWell(
          onTap: f ?? () => setState(() => nav = i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PIcon(ic, color: on ? kGreen : kMuted, size: 23),
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
            item(0, Ic.lib, 'المكتبة'),
            item(1, Ic.heart, 'المفضلة'),
            item(2, Ic.pulse, 'عينات', f: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SamplesPage()))),
            item(3, Ic.plist, 'القوائم'),
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
      opaque: false,
      pageBuilder: (_, __, ___) => const PlayerPage(),
      transitionsBuilder: (_, a, __, c) => SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c),
    ),
  );
}

/// ========== تبويب الرئيسية ==========
class HomeTab extends StatelessWidget {
  final void Function(List<Track>, Track) onPlay;
  final ValueChanged<int>? onSub;
  const HomeTab({super.key, required this.onPlay, this.onSub});

  Widget _sec(String s, [VoidCallback? all]) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Text(s, style: tx(18, c: const Color(0xFF17231E))),
          const Spacer(),
          if (all != null) GestureDetector(onTap: all, child: Text('الكل', style: tx(14, c: kGreen))),
        ]),
      );

  Widget _row(List<Widget> c, {double h = 196}) => SizedBox(
        height: h,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: c),
      );

  Widget _card(Track t, List<Track> ctx, {String? sub, double? prog, bool heart = false}) => GestureDetector(
        onTap: () => onPlay(ctx, t),
        onLongPress: () => trackSheet(_ctx!, t),
        child: Container(
          width: 136,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Cover(t.coverUrl, size: 136, radius: 18),
              if (app.repo.offline.contains(t.id)) const Positioned(top: 6, left: 6, child: PIcon(Ic.check, color: kGold, size: 18)),
              if (prog != null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: prog.clamp(0.0, 1.0), minHeight: 4, backgroundColor: Colors.black38, color: kGold)),
                ),
            ]),
            const SizedBox(height: 6),
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14)),
            if (heart)
              Row(children: [const PIcon(Ic.heartF, size: 12, color: kMuted), const SizedBox(width: 4), Text(sub ?? '', style: tx(12, c: kMuted))])
            else
              Text(sub ?? t.reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: kMuted)),
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
          body.add(_occ('مناسبة اليوم', o.t, l.isNotEmpty ? '${l.length} قصيدة مناسبة' : 'لا توجد قصائد مصنّفة لهذه المناسبة بعد', l.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(o.t, l))), play: l.isEmpty ? null : () => app.player.playList(l, 0)));
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
          body.add(_sec('جديد الإصدارات', onSub == null ? null : () => onSub!(2)));
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
          body.add(_row([for (final e in likes) _card(e.$1!, all, sub: '${e.$2}', heart: true)]));
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

  Widget _occ(String k, String t, String s, VoidCallback? f, {VoidCallback? play}) => GestureDetector(
        onTap: f,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x59E8C468)), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF0C4A39), Color(0xFF123A2F)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: tx(11.5, c: kGold, w: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(t, style: tx(19, c: Colors.white, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(s, style: tx(12.5, c: Colors.white70, w: FontWeight.w500)),
            if (play != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: play,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: kGold),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const PIcon(Ic.play, color: Color(0xFF2A2106), size: 16), const SizedBox(width: 6), Text('تشغيل', style: tx(13, c: const Color(0xFF2A2106)))]),
                ),
              ),
            ],
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
  bool _dl = false;
  Future<void> _downloadAll(List<Track> tl) async {
    if (_dl) return;
    final todo = tl.where((x) => !app.repo.offline.contains(x.id)).toList();
    if (todo.isEmpty) {
      snack(context, 'كلها منزّلة');
      return;
    }
    _dl = true;
    var ok = 0;
    for (var i = 0; i < todo.length; i++) {
      if (!mounted) break;
      snack(context, 'جارٍ التنزيل ${i + 1} من ${todo.length}…');
      if (await app.repo.offSave(todo[i], (_) {})) ok++;
      if (mounted) setState(() {});
    }
    _dl = false;
    if (mounted) snack(context, 'نُزّلت $ok من ${todo.length} — تعمل بدون إنترنت');
  }

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
                    GoldPill('تشغيل', Ic.play, tl.isEmpty ? () {} : () => app.player.playList(tl, 0)),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'تنزيل الكل',
                      onPressed: () => _downloadAll(tl),
                      icon: PIcon(tl.every((x) => r.offline.contains(x.id)) ? Ic.check : Ic.down, color: kGreen, size: 24),
                    ),
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
  showMSheet(
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
              _q(Ic.play, 'تشغيل الآن', () {
                Navigator.pop(sheet);
                pc.playList([t], 0);
              }),
              if (pc.cur != null && pc.cur!.id != t.id) ...[
                _q(Ic.queue, 'التالي', () {
                  Navigator.pop(sheet);
                  pc.playNext(t);
                  snack(context, 'ستُشغَّل بعد الحالية');
                }),
                _q(Ic.plist, 'آخر القائمة', () {
                  Navigator.pop(sheet);
                  pc.addToEnd(t);
                  snack(context, 'أُضيفت إلى قائمة التشغيل');
                }),
              ],
            ]),
            if (majlis.on && !majlis.host)
              _a(Ic.users, 'اقترح للمجلس', () {
                Navigator.pop(sheet);
                majlis.suggest(context, t);
              }),
            _a(r.isFav(t.id) ? Ic.heartF : Ic.heart, r.isFav(t.id) ? 'إزالة من المفضلة' : 'إضافة للمفضلة', () {
              Navigator.pop(sheet);
              r.toggleFav(t.id);
            }),
            _a(Ic.plist, 'إضافة إلى قائمة', () async {
              Navigator.pop(sheet);
              final pick = await showMSheet<Pl>(
                context: context,
                backgroundColor: Colors.white,
                builder: (s2) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: SafeArea(
                    child: ListView(shrinkWrap: true, children: [
                      for (final p in r.pls) ListTile(title: Text(p.name, style: tx(14.5)), subtitle: Text('${p.ids.length} قصيدة', style: tx(11.5, c: kMuted)), onTap: () => Navigator.pop(s2, p)),
                      ListTile(
                        leading: const PIcon(Ic.plus, color: kGreen),
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
            _a(Ic.share, 'مشاركة (رابط و QR)', () {
              Navigator.pop(sheet);
              shareTrack(context, t);
            }),
            if (r.offline.contains(t.id))
              _a(Ic.x, 'حذف التنزيل', () {
                Navigator.pop(sheet);
                r.offDel(t);
                snack(context, 'حُذف التنزيل');
              })
            else
              _a(Ic.down, 'تنزيل للاستماع بدون إنترنت', () async {
                Navigator.pop(sheet);
                snack(context, 'جارٍ تنزيل «${t.title}»…');
                final ok = await r.offSave(t, (_) {});
                if (context.mounted) snack(context, ok ? 'نُزّلت — تعمل بدون إنترنت' : 'تعذّر التنزيل');
              }),
            if (t.album.isNotEmpty && r.albums.containsKey(t.album))
              _a(Ic.lib, 'الذهاب للإصدار', () {
                Navigator.pop(sheet);
                final a = r.albums[t.album]!;
                Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(a.name, r.tracks.where((x) => x.album == a.id).toList(), sub: a.reciter, cover: absUrl(a.cover))));
              }),
            if (t.reciter.trim().isNotEmpty)
              _a(Ic.users, 'الذهاب للرادود', () {
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

Widget _q(String i, String s, VoidCallback f) => Expanded(
      child: InkWell(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(children: [PIcon(i, color: kGreen, size: 26), const SizedBox(height: 3), Text(s, style: tx(11.5, w: FontWeight.w700))]),
        ),
      ),
    );

Widget _a(String i, String s, VoidCallback f) => ListTile(leading: PIcon(i, color: kGreen), title: Text(s, style: tx(14)), onTap: f);

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
        if (app.repo.offline.contains(t.id)) const Padding(padding: EdgeInsetsDirectional.only(end: 4), child: PIcon(Ic.check, size: 14, color: kGreen)),
        Expanded(child: Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: kMuted, w: FontWeight.w500))),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (cur) const PIcon(Ic.eq, color: kGold),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => app.repo.toggleFav(t.id),
          icon: PIcon(fav ? Ic.heartF : Ic.heart, size: 20, color: fav ? const Color(0xFFD9534F) : kMuted),
        ),
      ]),
    );
  }
}


/// مشاركة القصيدة: رمز QR + نسخ الرابط + مشاركة عبر التطبيقات
void shareTrack(BuildContext context, Track t, {int? at}) {
  final url = '${kBase}?p=${t.id}${at != null ? '&t=$at' : ''}';
  showDialog(
    context: context,
    builder: (d) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: kCream,
        title: Text(t.title, textAlign: TextAlign.center, style: tx(17, c: kGreen)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: SizedBox(width: 200, height: 200, child: QrImageView(data: url, size: 200, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: kGreen), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: kGreen))),
          ),
          const SizedBox(height: 10),
          Text(t.reciter, style: tx(13, c: kMuted)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(d);
              snack(context, 'نُسخ الرابط');
            },
            child: Text('نسخ الرابط', style: tx(14, c: kGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(d);
              Share.share('${t.title} — ${t.reciter}\n$url');
            },
            child: Text('مشاركة', style: tx(14, c: kGreen)),
          ),
        ],
      ),
    ),
  );
}
