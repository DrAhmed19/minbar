import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int nav = 0, sub = 0, msub = 0;
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
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) showPermsOnce(context);
    });
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
    final sp = await SharedPreferences.getInstance();
    if (DateTime.now().millisecondsSinceEpoch - (sp.getInt('upSnooze') ?? 0) < 86400000) return;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (d) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تحديث جديد', style: tx(17, w: FontWeight.w800)),
          content: Text('نزلت نسخة أحدث من منبر (إصدار $n). قبل التحميل:\n• يفضّل الاتصال بشبكة Wi‑Fi (الحجم نحو 30 ميغا).\n• يتوقف التشغيل لحظة التثبيت.\n• بياناتك ومفضلتك تبقى كما هي.', style: tx(13.5, w: FontWeight.w500, h: 1.8)),
          actions: [
            TextButton(
              onPressed: () {
                sp.setInt('upSnooze', DateTime.now().millisecondsSinceEpoch);
                Navigator.pop(d);
              },
              child: Text('ذكّرني غداً', style: tx(13, c: kMuted)),
            ),
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

  void _play(List<Track> l, Track t) {
    app.player.playList(l, l.indexOf(t));
    openPlayer(context);
  }

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
        if (nav != 0 || sub != 0 || msub != 0) {
          setState(() {
            nav = 0;
            sub = 0;
            msub = 0;
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
                child: Column(children: [_header(), if (app.repo.noNet) _offBanner(), if ((nav == 1 || nav == 2) && !searching && !app.repo.noNet) _subTabs()]),
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
          if (!searching) Text(const ['منبر', 'استكشاف', 'مكتبتي', 'منبر', 'صفحتي'][nav], style: tx(21, w: FontWeight.w800, c: const Color(0xFF083B2D))),
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
    final names = nav == 1 ? const ['التصنيفات', 'الإصدارات', 'الرواديد', 'الشعراء', 'القصائد'] : const ['المفضلة', 'قوائمي', 'السجل', 'التنزيلات'];
    final cur = nav == 1 ? sub : msub;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: kGreen.withOpacity(.07), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: List.generate(names.length, (i) {
          final on = cur == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => nav == 1 ? sub = i : msub = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: on ? const [BoxShadow(color: Color(0x1F0E3C2D), blurRadius: 8, offset: Offset(0, 2))] : null),
                child: Text(names[i], textAlign: TextAlign.center, maxLines: 1, style: tx(12, c: on ? const Color(0xFF083B2D) : const Color(0xFF4D6A5E), w: on ? FontWeight.w800 : FontWeight.w600)),
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
    if (nav == 4) return const ProfilePage(embedded: true);
    if (nav == 2) return _library();
    if (r.noNet && (nav == 0 || nav == 1)) {
      final l = r.playableOffline;
      return l.isEmpty ? _empty('ما عندك قصائد محمّلة. حمّل قصائد وأنت متصل لتسمعها بدون إنترنت، أو أضف ملفات من جهازك من تبويب القوائم.') : _list(l);
    }
    if (nav == 1) {
      switch (sub) {
        case 1:
          return _albums();
        case 2:
          return _people(false);
        case 3:
          return _people(true);
        case 4:
          return _poems();
        default:
          return _cats();
      }
    }
    return HomeTab(onPlay: _play, onSub: (i) => setState(() {
          nav = 1;
          sub = i;
        }));
  }

  Widget _library() {
    final r = app.repo;
    switch (msub) {
      case 1:
        return _playlists();
      case 2:
        final h = [for (final id in r.recent.reversed) if (r.byId(id) != null) r.byId(id)!];
        return h.isEmpty ? _empty('لا يوجد سجل استماع بعد') : _list(h);
      case 3:
        final d = r.tracks.where((t) => r.offline.contains(t.id)).toList();
        return d.isEmpty ? _empty('لا توجد تنزيلات. من ⋮ بجانب القصيدة اختر التنزيل.') : _list(d);
      default:
        final l = r.tracks.where((t) => r.isFav(t.id)).toList();
        return l.isEmpty ? _empty('ما عندك مفضلة بعد') : _list(l);
    }
  }

  static const _catCols = [
    [Color(0xFF0E5C46), Color(0xFF14805F)],
    [Color(0xFF8A5A14), Color(0xFFC58A22)],
    [Color(0xFF3B3A6B), Color(0xFF5A58A6)],
    [Color(0xFF7A2E2E), Color(0xFFB04848)],
    [Color(0xFF1F4F6B), Color(0xFF2F7FA6)],
    [Color(0xFF4A3B2A), Color(0xFF7A6246)],
  ];

  Widget _cats() {
    final m = <String, List<Track>>{};
    for (final t in app.repo.tracks) {
      m.putIfAbsent(t.cat.isEmpty ? 'أخرى' : t.cat, () => []).add(t);
    }
    if (m.isEmpty) return _empty('لا توجد قصائد بعد');
    final ks = m.keys.toList()..sort((a, b) => m[b]!.length.compareTo(m[a]!.length));
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: ks.length == 1 ? 1 : 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: ks.length == 1 ? 2.6 : 1.45),
      itemCount: ks.length,
      itemBuilder: (_, i) {
        final l = m[ks[i]]!;
        final c = _catCols[i % _catCols.length];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(ks[i], l))),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: c), boxShadow: const [BoxShadow(color: Color(0x2E0E3C2D), blurRadius: 16, offset: Offset(0, 8))]),
            child: Stack(children: [
              Positioned(
                left: -14,
                bottom: -14,
                child: Transform.rotate(angle: -.28, child: Cover(l.first.coverUrl, size: 72, radius: 12)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ks[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(16, w: FontWeight.w800, c: Colors.white)),
                  const SizedBox(height: 2),
                  Text('${l.length} قصيدة', style: tx(12, c: Colors.white70, w: FontWeight.w500)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _offBanner() => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8C468))),
        child: Row(children: [
          const PIcon(Ic.wifiOff, color: Color(0xFF8A6A12), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('بدون إنترنت — تظهر القصائد المحمّلة وملفات جهازك', style: tx(12.5, w: FontWeight.w600, c: const Color(0xFF6B5210)))),
          GestureDetector(onTap: () => app.repo.refresh(), child: Text('إعادة', style: tx(12.5, w: FontWeight.w800, c: kGreen))),
        ]),
      );

  Widget _empty(String s) => Center(child: Text(s, style: tx(14, c: kMuted)));

  Widget _list(List<Track> l) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: l.length,
        itemBuilder: (_, i) => TrackTile(l[i], onTap: () => _play(l, l[i])),
      );

  // ترتيب وفلاتر صفحة القصائد (تُحفظ أثناء الجلسة)
  String _sort = 'new';
  final Set<String> _fRec = {}, _fPoet = {}, _fAlb = {};
  bool _fLy = false, _fOff = false, _fFav = false;
  static const _sorts = {'new': 'الأحدث', 'old': 'الأقدم', 'az': 'أبجدياً', 'hot': 'الأكثر استماعاً', 'fav': 'المفضلة أولاً'};
  int get _fCount => _fRec.length + _fPoet.length + _fAlb.length + (_fLy ? 1 : 0) + (_fOff ? 1 : 0) + (_fFav ? 1 : 0) + (cat != 'الكل' ? 1 : 0);

  List<Track> _poemList() {
    final r = app.repo;
    var l = r.tracks.where((t) {
      if (cat != 'الكل' && t.cat != cat) return false;
      if (_fRec.isNotEmpty && !_fRec.contains(t.reciter)) return false;
      if (_fPoet.isNotEmpty && !_fPoet.contains(t.poet)) return false;
      if (_fAlb.isNotEmpty && !_fAlb.contains(t.albumName)) return false;
      if (_fLy && !r.allLy.containsKey(t.id) && t.lyrics.isEmpty) return false;
      if (_fOff && !r.offline.contains(t.id)) return false;
      if (_fFav && !r.isFav(t.id)) return false;
      return true;
    }).toList();
    final hot = {for (final e in r.hotPlays) e.key: e.value};
    int cmp(Track a, Track b) {
      switch (_sort) {
        case 'old':
          return a.at.compareTo(b.at);
        case 'az':
          return a.title.compareTo(b.title);
        case 'hot':
          return (hot[b.id] ?? 0).compareTo(hot[a.id] ?? 0);
        case 'fav':
          final x = r.isFav(b.id) ? 1 : 0, y = r.isFav(a.id) ? 1 : 0;
          return x != y ? x - y : b.at.compareTo(a.at);
        default:
          return b.at.compareTo(a.at);
      }
    }

    l.sort(cmp);
    return l;
  }

  Widget _tbBtn(String ic, String label, VoidCallback f, {int badge = 0}) => GestureDetector(
        onTap: f,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: badge > 0 ? kGreen : Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: kGreen.withOpacity(.25))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            PIcon(ic, color: badge > 0 ? Colors.white : kGreen, size: 16),
            const SizedBox(width: 6),
            Text(badge > 0 ? '$label · $badge' : label, style: tx(12.5, w: FontWeight.w700, c: badge > 0 ? Colors.white : kGreen)),
          ]),
        ),
      );

  void _sortSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: kCream,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.all(14), child: Text('ترتيب القصائد', style: tx(16, w: FontWeight.w800))),
            for (final e in _sorts.entries)
              ListTile(
                dense: true,
                title: Text(e.value, style: tx(14.5, w: _sort == e.key ? FontWeight.w800 : FontWeight.w500, c: _sort == e.key ? kGreen : kInk)),
                trailing: _sort == e.key ? const Icon(Icons.check_rounded, color: kGreen) : null,
                onTap: () {
                  setState(() => _sort = e.key);
                  Navigator.pop(c);
                },
              ),
            const SizedBox(height: 8),
          ]),
        ),
      );

  void _filterSheet() {
    final r = app.repo;
    List<String> uniq(String Function(Track) f) => ({for (final t in r.tracks) f(t)}..remove('')).toList()..sort();
    final cats = ['الكل', ...{for (final t in r.tracks) t.cat}];
    final recs = uniq((t) => t.reciter), poets = uniq((t) => t.poet), albs = uniq((t) => t.albumName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => StatefulBuilder(builder: (c, ss) {
        void up(VoidCallback f) {
          f();
          ss(() {});
          setState(() {});
        }

        Widget chips(String title, List<String> all, Set<String> sel) => all.length < 2
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: tx(13, w: FontWeight.w800, c: kMuted)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 2, children: [
                    for (final v in all)
                      FilterChip(
                        label: Text(v, style: tx(12, c: sel.contains(v) ? Colors.white : kGreen)),
                        selected: sel.contains(v),
                        selectedColor: kGreen,
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => up(() => sel.contains(v) ? sel.remove(v) : sel.add(v)),
                      ),
                  ]),
                ]),
              );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .75,
          maxChildSize: .92,
          builder: (_, sc) => ListView(controller: sc, children: [
            Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Text('تصنيف القصائد', style: tx(16, w: FontWeight.w800)),
                const Spacer(),
                if (_fCount > 0)
                  TextButton(
                      onPressed: () => up(() {
                            cat = 'الكل';
                            _fRec.clear();
                            _fPoet.clear();
                            _fAlb.clear();
                            _fLy = _fOff = _fFav = false;
                          }),
                      child: Text('مسح الكل', style: tx(13, c: Colors.red.shade700))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('النوع', style: tx(13, w: FontWeight.w800, c: kMuted)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [
                  for (final v in cats)
                    ChoiceChip(
                      label: Text(v, style: tx(12, c: cat == v ? Colors.white : kGreen)),
                      selected: cat == v,
                      selectedColor: kGreen,
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => up(() => cat = v),
                    ),
                ]),
              ]),
            ),
            chips('الرادود', recs, _fRec),
            chips('الشاعر', poets, _fPoet),
            chips('الإصدار', albs, _fAlb),
            SwitchListTile(dense: true, activeColor: kGreen, title: Text('لها كلمات متزامنة', style: tx(14)), value: _fLy, onChanged: (v) => up(() => _fLy = v)),
            SwitchListTile(dense: true, activeColor: kGreen, title: Text('المحمّلة على الجهاز فقط', style: tx(14)), value: _fOff, onChanged: (v) => up(() => _fOff = v)),
            SwitchListTile(dense: true, activeColor: kGreen, title: Text('المفضلة فقط', style: tx(14)), value: _fFav, onChanged: (v) => up(() => _fFav = v)),
            Padding(padding: const EdgeInsets.all(16), child: GoldButton('عرض ${_poemList().length} قصيدة', () => Navigator.pop(c))),
          ]),
        );
      }),
    );
  }

  Widget _poems() {
    final l = _poemList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Row(children: [
          _tbBtn(Ic.filter, 'تصنيف', _filterSheet, badge: _fCount),
          const SizedBox(width: 8),
          _tbBtn(Ic.sort, _sorts[_sort]!, _sortSheet),
          const Spacer(),
          Text('${l.length} قصيدة', style: tx(12, c: kMuted, w: FontWeight.w600)),
        ]),
      ),
      Expanded(child: l.isEmpty ? _empty('ما اكو قصائد بهذا التصنيف') : _list(l)),
    ]);
  }

  Widget _albums() {
    final al = app.repo.albums.values.where((a) => app.repo.tracks.any((t) => t.album == a.id)).toList()..sort((a, b) => b.at.compareTo(a.at));
    if (al.isEmpty) return _empty('لا توجد إصدارات بعد');
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.8),
      itemCount: al.length,
      itemBuilder: (_, i) => AlbumCard(al[i], big: true),
    );
  }

  Widget _people(bool poet) {
    final m = <String, List<Track>>{};
    for (final t in app.repo.tracks) {
      final k = (poet ? t.poet : t.reciter).trim();
      if (k.isEmpty) {
        if (poet) continue;
      }
      m.putIfAbsent(k.isEmpty ? 'غير معروف' : k, () => []).add(t);
    }
    if (m.isEmpty) return _empty(poet ? 'لا توجد أسماء شعراء بعد' : 'لا توجد رواديد بعد');
    final ks = m.keys.toList()..sort((a, b) => m[b]!.length.compareTo(m[a]!.length));
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x120E3C2D), blurRadius: 16, offset: Offset(0, 4))]),
          child: Column(children: [
            for (var i = 0; i < ks.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0x120E5C46)),
              Builder(builder: (_) {
                final l = m[ks[i]]!;
                final na = l.map((t) => t.album).where((e) => e.isNotEmpty).toSet().length;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Cover(l.first.coverUrl, size: 56, radius: 28),
                  title: Text(ks[i], style: tx(15, w: FontWeight.w800)),
                  subtitle: Text('${l.length} قصيدة${(!poet && na > 0) ? ' · $na إصدار' : ''}', style: tx(12, c: kMuted, w: FontWeight.w500)),
                  trailing: Transform.flip(flipX: true, child: const PIcon(Ic.back, color: kMuted, size: 18)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(ks[i], l, reciter: poet ? null : ks[i]))),
                );
              }),
            ],
          ]),
        ),
      ],
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
      ListTile(
        leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(12)), child: const Center(child: PIcon(Ic.folder, color: kGold, size: 24))),
        title: Text('ملفات من جهازك', style: tx(14.5, w: FontWeight.w800)),
        subtitle: Text(r.locals.isEmpty ? 'شغّل لطمياتك المحفوظة بالهاتف، وأرفق كلماتها' : '${r.locals.length} ملف · تعمل بدون إنترنت', style: tx(12, c: kMuted, w: FontWeight.w500)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalPage())),
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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: kGreen,
                  backgroundImage: (!a.guest && (a.user?.photoURL ?? '').isNotEmpty) ? NetworkImage(a.user!.photoURL!) : null,
                  child: (!a.guest && (a.user?.photoURL ?? '').isNotEmpty) ? null : const PIcon(Ic.users, color: kGold),
                ),
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
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300) {
          app.player.next();
        } else if (v > 300) {
          app.player.prev();
        }
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: f ?? () => setState(() => nav = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: on ? kGreen.withOpacity(.1) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PIcon(ic, color: on ? kGreen : kMuted, size: 24),
              const SizedBox(height: 3),
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
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x380E3C2D), blurRadius: 28, offset: Offset(0, 10))]),
            child: Row(children: [
              item(0, Ic.home, 'الرئيسية'),
              item(1, Ic.compass, 'استكشاف'),
              item(2, Ic.lib, 'مكتبتي'),
              item(3, Ic.pulse, 'عينات', f: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SamplesPage()))),
              item(4, Ic.user, 'صفحتي'),
            ]),
          ),
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
          body.add(_sec('جديد الإصدارات', onSub == null ? null : () => onSub!(1)));
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


/// ملفات من جهاز المستخدم: استيراد + تشغيل + إرفاق كلمات (LRC أو نص) — كلها تعمل بدون إنترنت
class LocalPage extends StatefulWidget {
  const LocalPage({super.key});
  @override
  State<LocalPage> createState() => _LocalPageState();
}

class _LocalPageState extends State<LocalPage> {
  bool _busy = false;
  void _r() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    app.repo.addListener(_r);
  }

  @override
  void dispose() {
    app.repo.removeListener(_r);
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    int n = 0;
    try {
      n = await app.repo.importLocal();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _busy = false);
    if (n > 0) snack(context, 'أُضيف $n ملف');
  }

  Future<void> _lyrics(Track t) async {
    final tc = TextEditingController();
    await showDialog(
      context: context,
      builder: (d) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('كلمات «${t.title}»', style: tx(16, w: FontWeight.w800)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('الصق الكلمات (سطر لكل بيت). ملف LRC يعطي تزامناً دقيقاً، والنص العادي يُوزَّع على مدة القصيدة.', style: tx(12, c: kMuted, h: 1.6)),
              const SizedBox(height: 8),
              TextField(controller: tc, maxLines: 8, minLines: 4, style: tx(14), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 6),
              TextButton.icon(
                icon: const PIcon(Ic.folder, color: kGreen, size: 18),
                label: Text('اختيار ملف LRC / نص', style: tx(13, c: kGreen)),
                onPressed: () async {
                  final f = await FilePicker.platform.pickFiles(type: FileType.any);
                  final p = f?.files.single.path;
                  if (p != null) {
                    try {
                      tc.text = await File(p).readAsString();
                    } catch (_) {}
                  }
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text('إلغاء', style: tx(13, c: kMuted))),
            TextButton(
              onPressed: () {
                final n = tc.text.trim().isEmpty ? 0 : app.repo.setLocalLyrics(t, tc.text);
                Navigator.pop(d);
                if (n > 0) snack(context, 'أُرفقت الكلمات ($n سطر)');
              },
              child: Text('حفظ', style: tx(13.5, c: kGreen, w: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = app.repo.locals;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(backgroundColor: kCream, elevation: 0, scrolledUnderElevation: 0, foregroundColor: kGreen, title: Text('ملفات من جهازك', style: tx(18, w: FontWeight.w800, c: kGreen))),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Align(alignment: Alignment.centerRight, child: GoldPill(_busy ? 'جارٍ النسخ…' : 'إضافة ملفات صوت', Ic.plus, _busy ? () {} : _import)),
          ),
          Expanded(
            child: l.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(30), child: Text('اختر ملفات الصوت من هاتفك (mp3 · m4a …) لتشغيلها داخل منبر بدون إنترنت.', style: tx(14, c: kMuted, h: 1.8), textAlign: TextAlign.center)))
                : ListView.builder(
                    itemCount: l.length,
                    itemBuilder: (_, i) {
                      final t = l[i];
                      return ListTile(
                        leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: kGreen.withOpacity(.1), borderRadius: BorderRadius.circular(12)), child: const Center(child: PIcon(Ic.music, color: kGreen, size: 22))),
                        title: Text(t.title, style: tx(14.5, w: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: FutureBuilder<List<Lyric>>(
                          future: app.repo.lyricsFor(t),
                          builder: (_, s) => Text((s.data ?? []).isEmpty ? 'بدون كلمات' : 'كلماتها مرفقة · ${s.data!.length} سطر', style: tx(12, c: kMuted, w: FontWeight.w500)),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'ly') _lyrics(t);
                            if (v == 'del') app.repo.delLocal(t);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'ly', child: Text('إرفاق كلمات', style: tx(14))),
                            PopupMenuItem(value: 'del', child: Text('حذف', style: tx(14, c: Colors.red.shade700))),
                          ],
                        ),
                        onTap: () {
                          app.player.playList(l, i);
                          openPlayer(context);
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
