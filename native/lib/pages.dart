import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// ========== الافتتاح + الدخول ==========
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  final DateTime _t0 = DateTime.now();
  bool _minDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _minDone = true);
    });
    app.auth.addListener(_r);
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    app.auth.removeListener(_r);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = app.auth;
    final ready = _minDone && a.state != AuthState.init && a.state != AuthState.loading;
    if (ready && a.isIn) return const HomeShell();
    if (!ready) return _splash();
    return LoginPage(onRetry: () => setState(() {}));
  }

  Widget _splash() => Scaffold(
        backgroundColor: kDeep,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.25), radius: 1.2, colors: [Color(0xFF0F4A38), Color(0xFF072A20), Color(0xFF03140F)]),
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final el = DateTime.now().difference(_t0).inMilliseconds / 1000.0;
                  return SizedBox(width: 128, height: 138, child: CustomPaint(painter: LogoPainter(_c.value, draw: (el / 1.1).clamp(0, 1))));
                },
              ),
              const SizedBox(height: 6),
              Text('منبر', style: tx(54, w: FontWeight.w800, c: const Color(0xFFF3EAD0))),
              const SizedBox(height: 6),
              Text('صوت المنبر', style: tx(15, c: const Color(0xFF9FBDB0))),
            ]),
          ),
        ),
      );
}

class LoginPage extends StatelessWidget {
  final VoidCallback onRetry;
  const LoginPage({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final a = app.auth;
    Widget body;
    switch (a.state) {
      case AuthState.form:
        body = Column(children: [
          Text('مرحباً ${a.user?.displayName ?? ''}', style: tx(16, c: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('التطبيق قيد التطوير. سجّل مسبقاً بحسابك وسيتم اختيار عدد محدود من المستخدمين لتجربته.',
              style: tx(13, w: FontWeight.w500, c: const Color(0xFF8FA69B), h: 1.7), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          GoldButton('تسجيل مسبق', a.register),
          const SizedBox(height: 10),
          GoldButton('الدخول كضيف', a.enterGuest, outline: true),
          const SizedBox(height: 6),
          TextButton(onPressed: a.signOut, child: Text('تغيير الحساب', style: tx(13, c: const Color(0xFF8FA69B)))),
        ]);
        break;
      case AuthState.wait:
      case AuthState.rejected:
        body = Column(children: [
          Icon(a.state == AuthState.wait ? Icons.hourglass_top_rounded : Icons.favorite_border, color: kGold, size: 36),
          const SizedBox(height: 10),
          Text(
              a.state == AuthState.rejected
                  ? 'نشكر لك اهتمامك. لم يتم اختيارك ضمن مرحلة التجربة الحالية، وسنوافيك عند الإطلاق العام.'
                  : 'تم تسجيلك في قائمة الانتظار. عند اختيارك ستدخل تلقائياً بنفس الحساب.',
              style: tx(13.5, w: FontWeight.w500, c: const Color(0xFFCBD8D1), h: 1.8),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          GoldButton('الدخول كضيف', a.enterGuest),
          const SizedBox(height: 6),
          TextButton(onPressed: a.signOut, child: Text('تغيير الحساب', style: tx(13, c: const Color(0xFF8FA69B)))),
        ]);
        break;
      default:
        body = Column(children: [
          GoldButton('الدخول بحساب Google', a.google, icon: Icons.account_circle_outlined),
          const SizedBox(height: 10),
          GoldButton('الدخول كضيف', a.enterGuest, outline: true),
          if (a.error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(a.error, style: tx(12.5, c: const Color(0xFFE8A0A0)), textAlign: TextAlign.center),
          ],
        ]);
    }
    return Scaffold(
      backgroundColor: kDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.5), radius: 1.3, colors: [Color(0xFF0F4A38), Color(0xFF072A20), Color(0xFF03140F)]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 96, height: 104, child: CustomPaint(painter: LogoPainter(0.15))),
                const SizedBox(height: 8),
                Text('منبر', style: tx(44, w: FontWeight.w800, c: const Color(0xFFF3EAD0))),
                Text('قصائد ومراثي', style: tx(14, w: FontWeight.w500, c: const Color(0xFF9FBDB0))),
                const SizedBox(height: 36),
                body,
              ]),
            ),
          ),
        ),
      ),
    );
  }
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
    app.repo.loaded ? app.player.restore() : null;
  }

  void _r() {
    if (mounted) setState(() {});
    if (app.repo.loaded) app.player.restore();
  }

  @override
  void dispose() {
    app.repo.removeListener(_r);
    app.player.removeListener(_r);
    _sc.dispose();
    super.dispose();
  }

  List<Track> get _all {
    final k = norm(q);
    if (k.isEmpty) return app.repo.tracks;
    return app.repo.tracks.where((t) => norm('${t.title} ${t.reciter} ${t.poet} ${t.albumName}').contains(k)).toList();
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
          // الخروج من الواجهة فقط، والصوت يستمر بالخلفية
          SystemNavigator.pop();
        } else {
          _lastBack = now;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(app.player.p.playing ? 'اضغط رجوع مرة ثانية للخروج (الصوت يستمر بالخلفية)' : 'اضغط رجوع مرة ثانية للخروج', style: tx(13, c: Colors.white)),
            duration: const Duration(seconds: 2),
          ));
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
              if (nav == 0) _subTabs(),
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
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
                onChanged: (v) => setState(() => q = v),
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
    if (nav == 1) {
      final l = _all.where((t) => r.isFav(t.id)).toList();
      return l.isEmpty ? _empty('ما عندك مفضلة بعد') : _list(l);
    }
    if (nav == 2) return _account();
    if (q.isNotEmpty) return _list(_all);
    switch (sub) {
      case 1:
        return _poems();
      case 2:
        return _albums();
      case 3:
        return _reciters();
      default:
        return _homeTab();
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
    final al = app.repo.albums.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82),
      itemCount: al.length,
      itemBuilder: (_, i) {
        final a = al[i];
        final tl = app.repo.tracks.where((t) => t.album == a.id).toList();
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListPage(a.name, tl, sub: a.reciter))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: LayoutBuilder(builder: (_, c) => Cover(absUrl(a.cover), size: c.maxWidth, radius: 16))),
            const SizedBox(height: 6),
            Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13.5, w: FontWeight.w800)),
            Text('${tl.length} قصيدة', style: tx(11.5, c: kMuted, w: FontWeight.w500)),
          ]),
        );
      },
    );
  }

  Widget _reciters() {
    final m = <String, List<Track>>{};
    for (final t in app.repo.tracks) {
      if (t.reciter.isEmpty) continue;
      m.putIfAbsent(t.reciter, () => []).add(t);
    }
    final ks = m.keys.toList()..sort();
    return ListView.builder(
      itemCount: ks.length,
      itemBuilder: (_, i) {
        final l = m[ks[i]]!;
        return ListTile(
          leading: Cover(l.first.coverUrl, size: 46, radius: 23),
          title: Text(ks[i], style: tx(14.5, w: FontWeight.w800)),
          subtitle: Text('${l.length} قصيدة', style: tx(12, c: kMuted, w: FontWeight.w500)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListPage(ks[i], l))),
        );
      },
    );
  }

  Widget _homeTab() {
    final r = app.repo;
    final last = r.lastId == null ? null : r.byId(r.lastId!);
    final news = r.tracks.take(12).toList();
    final al = r.albums.values.take(12).toList();
    Widget sec(String s) => Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Text(s, style: tx(17, w: FontWeight.w800)));
    return ListView(padding: const EdgeInsets.only(bottom: 14), children: [
      if (last != null) ...[
        sec('أكمل الاستماع'),
        TrackTile(last, onTap: () => app.player.playList(r.tracks, r.tracks.indexOf(last), pos: Duration(milliseconds: r.posOf(last.id)))),
      ],
      sec('جديد القصائد'),
      SizedBox(
        height: 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: news.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _play(news, news[i]),
            child: Container(
              width: 128,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Cover(news[i].coverUrl, size: 128, radius: 16),
                const SizedBox(height: 6),
                Text(news[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, w: FontWeight.w800)),
                Text(news[i].reciter, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11.5, c: kMuted, w: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ),
      if (al.isNotEmpty) ...[
        sec('جديد الإصدارات'),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: al.length,
            itemBuilder: (_, i) {
              final a = al[i];
              final tl = r.tracks.where((t) => t.album == a.id).toList();
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListPage(a.name, tl, sub: a.reciter))),
                child: Container(
                  width: 112,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Cover(absUrl(a.cover), size: 112, radius: 16),
                    const SizedBox(height: 6),
                    Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12.5, w: FontWeight.w800)),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    ]);
  }

  Widget _account() {
    final a = app.auth;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          CircleAvatar(radius: 26, backgroundColor: kGreen, child: const Icon(Icons.person, color: kGold)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.guest ? 'ضيف' : (a.user?.displayName ?? ''), style: tx(16, w: FontWeight.w800)),
              Text(a.guest ? 'تستمع بدون حساب' : (a.user?.email ?? ''), style: tx(12, c: kMuted, w: FontWeight.w500)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: const Icon(Icons.refresh, color: kGreen),
        title: Text('تحديث المكتبة', style: tx(14)),
        onTap: () {
          app.repo.refresh();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('جارٍ التحديث…', style: tx(13, c: Colors.white))));
        },
      ),
      const SizedBox(height: 8),
      ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: const Icon(Icons.logout, color: kGreen),
        title: Text(a.guest ? 'تسجيل الدخول بحساب' : 'تسجيل الخروج', style: tx(14)),
        onTap: a.signOut,
      ),
      const SizedBox(height: 20),
      Center(child: Text('منبر · نسخة التطبيق 1.0', style: tx(11.5, c: kMuted, w: FontWeight.w500))),
    ]);
  }

  Widget _mini() {
    final t = app.player.cur;
    if (t == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const PlayerPage(), transitionsBuilder: (_, a, __, c) => SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c))),
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
            IconButton(onPressed: app.player.next, icon: const Icon(Icons.skip_next_rounded, size: 28, color: kGreen)),
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
    Widget item(int i, IconData ic, String s) {
      final on = nav == i;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => nav = i),
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
          child: Row(children: [item(0, Icons.library_music_outlined, 'المكتبة'), item(1, Icons.favorite_border, 'المفضلة'), item(2, Icons.person_outline, 'حسابي')]),
        ),
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  final Track t;
  final VoidCallback onTap;
  const TrackTile(this.t, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cur = app.player.cur?.id == t.id;
    return ListTile(
      onTap: onTap,
      leading: Cover(t.coverUrl, size: 50, radius: 12),
      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14.5, w: FontWeight.w800, c: cur ? kGreen : kInk)),
      subtitle: Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: kMuted, w: FontWeight.w500)),
      trailing: cur ? const Icon(Icons.graphic_eq, color: kGold) : null,
    );
  }
}

class ListPage extends StatelessWidget {
  final String title;
  final String sub;
  final List<Track> tracks;
  const ListPage(this.title, this.tracks, {super.key, this.sub = ''});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(
          backgroundColor: kCream,
          elevation: 0,
          foregroundColor: kGreen,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: tx(17, w: FontWeight.w800, c: kGreen)),
            if (sub.isNotEmpty) Text(sub, style: tx(11.5, c: kMuted, w: FontWeight.w500)),
          ]),
          actions: [
            IconButton(onPressed: tracks.isEmpty ? null : () => app.player.playList(tracks, 0), icon: const Icon(Icons.play_circle_fill, color: kGreen, size: 30)),
          ],
        ),
        body: ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (_, i) => TrackTile(tracks[i], onTap: () => app.player.playList(tracks, i)),
        ),
      ),
    );
  }
}

/// ========== المشغّل الكامل ==========
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  List<Lyric> ly = [];
  String lyFor = '';
  bool showAll = false;
  final _sc = ScrollController();
  int _lastIdx = -1;

  @override
  void initState() {
    super.initState();
    app.player.addListener(_r);
    _loadLy();
  }

  void _r() {
    if (!mounted) return;
    setState(() {});
    _loadLy();
  }

  Future<void> _loadLy() async {
    final t = app.player.cur;
    if (t == null || lyFor == t.id) return;
    lyFor = t.id;
    ly = [];
    final r = await app.repo.lyricsFor(t);
    if (mounted && app.player.cur?.id == t.id) setState(() => ly = r);
  }

  @override
  void dispose() {
    app.player.removeListener(_r);
    _sc.dispose();
    super.dispose();
  }

  int _idx(double pos) {
    var k = -1;
    for (var i = 0; i < ly.length; i++) {
      if (ly[i].t <= pos + 0.15) {
        k = i;
      } else {
        break;
      }
    }
    return k;
  }

  @override
  Widget build(BuildContext context) {
    final pc = app.player;
    final t = pc.cur;
    if (t == null) return const Scaffold(backgroundColor: kDeep);
    final fav = app.repo.isFav(t.id);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A2C20), Color(0xFF1C140E), Color(0xFF0E0906)])),
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 32)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      app.repo.toggleFav(t.id);
                      setState(() {});
                    },
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? const Color(0xFFE8776F) : Colors.white70),
                  ),
                  IconButton(onPressed: _menu, icon: const Icon(Icons.more_vert, color: Colors.white70)),
                ]),
              ),
              Expanded(child: showAll ? _lyricsList() : _stage(t)),
              _controls(t),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _stage(Track t) => Column(children: [
        const SizedBox(height: 4),
        Expanded(
          flex: 5,
          child: Center(
            child: LayoutBuilder(builder: (_, c) {
              final s = (c.maxHeight < c.maxWidth * 0.9 ? c.maxHeight : c.maxWidth * 0.72).clamp(120.0, 340.0);
              return Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(s / 2), bottom: const Radius.circular(20)),
                  border: Border.all(color: kGold.withOpacity(0.55), width: 2),
                  boxShadow: [BoxShadow(color: kGold.withOpacity(0.12), blurRadius: 30)],
                ),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(s / 2 - 6), bottom: const Radius.circular(14)),
                  child: Cover(t.coverUrl, size: s - 16, radius: 0),
                ),
              );
            }),
          ),
        ),
        Expanded(
          flex: 3,
          child: StreamBuilder<Duration>(
            stream: app.player.p.positionStream,
            builder: (_, s) {
              final pos = (s.data?.inMilliseconds ?? 0) / 1000.0;
              final i = _idx(pos);
              final lines = <String>[];
              for (var k = i - 1; k <= i + 1; k++) {
                lines.add(k >= 0 && k < ly.length ? ly[k].l : '');
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GestureDetector(
                  onTap: ly.isEmpty ? null : () => setState(() => showAll = true),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(lines[0], maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: tx(14, c: Colors.white38, w: FontWeight.w500)),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        i < 0 ? (ly.isEmpty ? '' : '♪') : lines[1],
                        key: ValueKey(i),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: tx(21, c: kGold2, w: FontWeight.w800, h: 1.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(lines[2], maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: tx(14, c: Colors.white38, w: FontWeight.w500)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]);

  Widget _lyricsList() => GestureDetector(
        onTap: () => setState(() => showAll = false),
        child: StreamBuilder<Duration>(
          stream: app.player.p.positionStream,
          builder: (_, s) {
            final pos = (s.data?.inMilliseconds ?? 0) / 1000.0;
            final i = _idx(pos);
            if (i != _lastIdx && _sc.hasClients) {
              _lastIdx = i;
              final target = (i * 64.0 - 120).clamp(0.0, _sc.position.maxScrollExtent);
              _sc.animateTo(target, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
            }
            return ListView.builder(
              controller: _sc,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              itemCount: ly.length,
              itemExtent: 64,
              itemBuilder: (_, k) {
                final on = k == i;
                return InkWell(
                  onTap: () => app.player.seek(ly[k].t),
                  child: Center(
                    child: Text(ly[k].l, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: tx(on ? 19 : 15.5, c: on ? kGold2 : Colors.white38, w: on ? FontWeight.w800 : FontWeight.w600, h: 1.5)),
                  ),
                );
              },
            );
          },
        ),
      );

  Widget _controls(Track t) {
    final pc = app.player;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
          alignment: Alignment.centerRight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(19, w: FontWeight.w800, c: Colors.white)),
            Text([t.reciter, t.poet].where((e) => e.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12.5, c: Colors.white60, w: FontWeight.w500)),
          ]),
        ),
        StreamBuilder<Duration>(
          stream: pc.p.positionStream,
          builder: (_, s) => StreamBuilder<Duration?>(
            stream: pc.p.durationStream,
            builder: (_, d) {
              final dur = (d.data?.inMilliseconds ?? 0) / 1000.0;
              final pos = ((s.data?.inMilliseconds ?? 0) / 1000.0).clamp(0.0, dur > 0 ? dur : 1.0);
              return Column(children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), activeTrackColor: kGold, inactiveTrackColor: Colors.white24, thumbColor: kGold2, overlayColor: kGold.withOpacity(0.15)),
                  child: Slider(value: pos, min: 0, max: dur > 0 ? dur : 1.0, onChanged: dur > 0 ? pc.seek : null),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(fmt(pos), style: tx(11.5, c: Colors.white60, w: FontWeight.w500)),
                    Text(fmt(dur), style: tx(11.5, c: Colors.white60, w: FontWeight.w500)),
                  ]),
                ),
              ]);
            },
          ),
        ),
        Directionality(textDirection: TextDirection.ltr, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: pc.toggleShuffle, icon: Icon(Icons.shuffle_rounded, color: pc.shuffle ? kGold : Colors.white54)),
          IconButton(onPressed: pc.prev, icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36)),
          StreamBuilder<PlayerState>(
            stream: pc.p.playerStateStream,
            builder: (_, s) {
              final st = s.data;
              final busy = st != null && (st.processingState == ProcessingState.loading || st.processingState == ProcessingState.buffering) && st.playing;
              return GestureDetector(
                onTap: pc.toggle,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kGold2, kGold], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: busy
                      ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF3A2D08)))
                      : Icon((st?.playing ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: const Color(0xFF3A2D08)),
                ),
              );
            },
          ),
          IconButton(onPressed: pc.next, icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36)),
          IconButton(onPressed: pc.cycleLoop, icon: Icon(pc.loop == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded, color: pc.loop == LoopMode.off ? Colors.white54 : kGold)),
        ])),
      ]),
    );
  }

  void _menu() {
    final pc = app.player;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C140E),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('السرعة', style: tx(14, c: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final s in [0.75, 1.0, 1.25, 1.5])
                  ChoiceChip(
                    label: Text('${s}x', style: tx(12.5, c: pc.speed == s ? const Color(0xFF3A2D08) : Colors.white)),
                    selected: pc.speed == s,
                    selectedColor: kGold,
                    backgroundColor: Colors.white12,
                    showCheckmark: false,
                    onSelected: (_) {
                      pc.setSpeed(s);
                      Navigator.pop(context);
                    },
                  ),
              ]),
              const SizedBox(height: 16),
              Text(pc.sleepAt == null ? 'مؤقت النوم' : 'مؤقت النوم (فعّال)', style: tx(14, c: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final m in [0, 15, 30, 60])
                  ChoiceChip(
                    label: Text(m == 0 ? 'إيقاف' : '$m د', style: tx(12.5, c: Colors.white)),
                    selected: false,
                    backgroundColor: Colors.white12,
                    onSelected: (_) {
                      pc.setSleep(m);
                      Navigator.pop(context);
                    },
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
