import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'data.dart';
import 'state.dart';
import 'ui.dart';

/// ========== مقاطعنا على تيك توك ==========
/// فوق: بطاقة الحساب الرسمية (تتحدث وحدها بآخر المقاطع).
/// تحت: مقاطع مختارة يثبّتها المشرف بلصق الرابط، وتنفتح داخل التطبيق بمشغل تيك توك مع الإعجابات والتعليقات.
const kTikTokUser = 'a1h9mad';

class TtItem {
  final String id, vid, url, title;
  final int order;
  String thumb;
  TtItem(this.id, this.vid, this.url, this.title, this.thumb, this.order);
}

/// معلومات المقطع من خادم الموقع (يحوّل الروابط المختصرة ويجلب العنوان والصورة)
Future<Map<String, dynamic>?> ttInfo(String link) async {
  try {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    final rq = await c.getUrl(Uri.parse('${kBase}api/tt?url=${Uri.encodeComponent(link)}'));
    final rs = await rq.close().timeout(const Duration(seconds: 20));
    final body = await rs.transform(utf8.decoder).join();
    c.close();
    final m = jsonDecode(body) as Map<String, dynamic>;
    return m;
  } catch (_) {
    return null;
  }
}

class TikTokPage extends StatefulWidget {
  const TikTokPage({super.key});
  @override
  State<TikTokPage> createState() => _TikTokPageState();
}

class _TikTokPageState extends State<TikTokPage> {
  List<TtItem> _items = [];
  bool _loading = true, _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final q = await FirebaseFirestore.instance.collection('tiktok').orderBy('order').limit(60).get();
      _items = q.docs.map((d) {
        final m = d.data();
        return TtItem(d.id, '${m['vid'] ?? ''}', '${m['url'] ?? ''}', '${m['title'] ?? ''}', '${m['thumb'] ?? ''}', (m['order'] as num?)?.toInt() ?? 0);
      }).where((e) => e.vid.isNotEmpty).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    // صور المقاطع من تيك توك تنتهي صلاحيتها، فنجدّدها بالخلفية
    for (final it in _items) {
      ttInfo(it.url).then((m) {
        final t = '${m?['thumb'] ?? ''}';
        if (t.isNotEmpty && mounted) setState(() => it.thumb = t);
      });
    }
  }

  /// أي رابط يحاول يطلع من مشغل التضمين (فتح التطبيق، الملف الشخصي...) نفتحه خارجياً
  NavigationDecision _nav(NavigationRequest r) {
    final u = r.url;
    if (!r.isMainFrame || u.startsWith(kBase) || u.startsWith('about:')) return NavigationDecision.navigate;
    launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  Future<void> _add() async {
    if (_adding) return;
    final ctl = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (d) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إضافة مقطع', style: tx(16, w: FontWeight.w800)),
          content: TextField(controller: ctl, autofocus: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'الصق رابط مقطع أو أكثر (سطر لكل رابط)'), maxLines: 4, minLines: 1),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(d, ctl.text.trim()), child: const Text('إضافة')),
          ],
        ),
      ),
    );
    if (link == null || link.isEmpty) return;
    setState(() => _adding = true);
    int ok = 0;
    String err = '';
    for (final u in link.split(RegExp(r'[\s,]+')).where((e) => e.isNotEmpty)) {
      var m = await ttInfo(u);
      if (m == null || m['id'] == null) {
        final x = RegExp(r'@([\w.-]+)/video/(\d{8,25})').firstMatch(u);
        if (x == null) {
          err = 'الرابط ما فيه رقم مقطع، انسخه من «مشاركة ← نسخ الرابط» للمقطع نفسه';
          continue;
        }
        m = {'id': x.group(2), 'url': 'https://www.tiktok.com/@${x.group(1)}/video/${x.group(2)}', 'title': '', 'thumb': ''};
      }
      if (_items.any((e) => e.vid == m!['id'])) {
        err = 'مضاف مسبقاً';
        continue;
      }
      try {
        final top = _items.isEmpty ? 0 : _items.map((e) => e.order).reduce((a, b) => a < b ? a : b);
        await FirebaseFirestore.instance.collection('tiktok').doc(m['id']).set({
          'vid': m['id'],
          'url': m['url'],
          'title': '${m['title'] ?? ''}',
          'thumb': '${m['thumb'] ?? ''}',
          'order': top - 1,
          'at': FieldValue.serverTimestamp(),
        });
        ok++;
        await _load();
      } catch (e) {
        err = 'تعذّر الحفظ: $e';
      }
    }
    _snack(ok > 0 ? 'تمت إضافة $ok${err.isEmpty ? '' : ' — $err'}' : (err.isEmpty ? 'تعذّرت الإضافة' : err));
    if (mounted) setState(() => _adding = false);
  }

  Future<void> _del(TtItem it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إزالة المقطع من الصفحة؟', style: tx(15, w: FontWeight.w800)),
          actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('إزالة'))],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection('tiktok').doc(it.id).delete();
      setState(() => _items.remove(it));
    } catch (_) {
      _snack('تعذّر الحذف');
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: tx(13, c: Colors.white))));

  @override
  Widget build(BuildContext context) {
    final admin = app.auth.admin;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(backgroundColor: kCream, elevation: 0, scrolledUnderElevation: 0, foregroundColor: kGreen, title: Text('مقاطعنا على تيك توك', style: tx(18, w: FontWeight.w800, c: kGreen))),
        floatingActionButton: admin
            ? FloatingActionButton.extended(
                backgroundColor: kGreen,
                onPressed: _adding ? null : _add,
                icon: _adding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const PIcon(Ic.plus, color: Colors.white, size: 20),
                label: Text('إضافة مقطع', style: tx(13.5, w: FontWeight.w700, c: Colors.white)),
              )
            : null,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 4))]),
              child: Column(children: [
                const Icon(Icons.music_note_rounded, size: 38, color: Color(0xFFFE2C55)),
                const SizedBox(height: 6),
                Text('@$kTikTokUser', style: tx(17, w: FontWeight.w800, c: kGreen)),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: TextButton(
                style: TextButton.styleFrom(backgroundColor: const Color(0xFFFE2C55), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => launchUrl(Uri.parse('https://www.tiktok.com/@$kTikTokUser'), mode: LaunchMode.externalApplication),
                child: Text('فتح الحساب في TikTok', style: tx(13.5, w: FontWeight.w700, c: Colors.white)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(children: [
                Text('مقاطع مختارة', style: tx(16, w: FontWeight.w800, c: kGreen)),
                const Spacer(),
                if (admin) Text('اضغط مطولاً للإزالة', style: tx(11, c: kMuted)),
              ]),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: kGreen))))
          else if (_items.isEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(30), child: Text(admin ? 'أضف أول مقطع بزر «إضافة مقطع»' : 'لا توجد مقاطع مختارة بعد', style: tx(13, c: kMuted), textAlign: TextAlign.center)))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .58),
                delegate: SliverChildBuilderDelegate((_, i) {
                  final it = _items[i];
                  return GestureDetector(
                    onTap: () => launchUrl(Uri.parse(it.url), mode: LaunchMode.externalApplication),
                    onLongPress: admin ? () => _del(it) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(fit: StackFit.expand, children: [
                        Container(color: kGreen),
                        if (it.thumb.isNotEmpty) CachedNetworkImage(imageUrl: it.thumb, fit: BoxFit.cover, errorWidget: (_, __, ___) => const SizedBox()),
                        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x00000000), Color(0xCC000000)], stops: [0, .55, 1]))),
                        const Center(child: CircleAvatar(radius: 22, backgroundColor: Color(0x66000000), child: PIcon(Ic.play, color: Colors.white, size: 22))),
                        Positioned(left: 10, right: 10, bottom: 10, child: Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: tx(12, w: FontWeight.w600, c: Colors.white, h: 1.4))),
                      ]),
                    ),
                  );
                }, childCount: _items.length),
              ),
            ),
        ]),
      ),
    );
  }
}

/// تشغيل المقطع داخل التطبيق بمشغل تيك توك الرسمي (يعرض الإعجابات والتعليقات)
class TtPlayer extends StatefulWidget {
  final TtItem it;
  const TtPlayer(this.it, {super.key});
  @override
  State<TtPlayer> createState() => _TtPlayerState();
}

class _TtPlayerState extends State<TtPlayer> {
  bool _ready = false;
  late final WebViewController _c = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) {
        if (mounted) setState(() => _ready = true);
      },
      onNavigationRequest: (r) {
        final u = r.url;
        if (!r.isMainFrame || u.startsWith(kBase) || u.startsWith('about:')) return NavigationDecision.navigate;
        launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },
    ))
    ..loadRequest(Uri.parse('${kBase}tt.html?v=${widget.it.vid}&u=${RegExp(r'@([\w.-]+)').firstMatch(widget.it.url)?.group(1) ?? kTikTokUser}'));

  @override
  void initState() {
    super.initState();
    // الصوت داخل المقطع: نوقف القصيدة الشغالة حتى ما يتداخل الصوت
    try {
      if (app.player.p.playing) app.player.p.pause();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.it.title.isEmpty ? 'تيك توك' : widget.it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(14, c: Colors.white)),
          actions: [
            IconButton(
              tooltip: 'فتح في تيك توك',
              onPressed: () => launchUrl(Uri.parse(widget.it.url), mode: LaunchMode.externalApplication),
              icon: const PIcon(Ic.share, color: Colors.white, size: 20),
            ),
          ],
        ),
        body: Stack(children: [
          WebViewWidget(controller: _c),
          if (!_ready) const Center(child: CircularProgressIndicator(color: kGold)),
        ]),
      ),
    );
  }
}
