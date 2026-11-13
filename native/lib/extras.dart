import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tz;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'data.dart';
import 'lyrics.dart';
import 'occasion.dart';
import 'state.dart';
import 'ui.dart';

/// إضافات التطبيق: الإعدادات، الإشعارات (قصائد جديدة + تذكير المناسبات)،
/// التنزيل التلقائي للمفضلة على الواي فاي، وضع السيارة.

// ================= خيارات عامة =================
class Opt {
  static SharedPreferences? _p;
  static bool notifNew = true, notifOcc = true, autoDl = false, fade = true;
  static Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    notifNew = _p!.getBool('o.notifNew') ?? true;
    notifOcc = _p!.getBool('o.notifOcc') ?? true;
    autoDl = _p!.getBool('o.autoDl') ?? false;
    fade = _p!.getBool('o.fade') ?? true;
  }

  static void set(String k, bool v) {
    switch (k) {
      case 'notifNew':
        notifNew = v;
      case 'notifOcc':
        notifOcc = v;
      case 'autoDl':
        autoDl = v;
      case 'fade':
        fade = v;
    }
    _p?.setBool('o.$k', v);
  }
}

// ================= الإشعارات =================
final _fln = FlutterLocalNotificationsPlugin();
bool _nReady = false;
const _chNew = AndroidNotificationDetails('new', 'قصائد جديدة', channelDescription: 'تنبيه عند إضافة قصيدة جديدة', importance: Importance.defaultImportance);
const _chOcc = AndroidNotificationDetails('occ', 'المناسبات', channelDescription: 'تذكير بالمناسبات الدينية', importance: Importance.defaultImportance);

Future<bool> notifInit({bool ask = false}) async {
  try {
    if (!_nReady) {
      await _fln.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_minbar')));
      _nReady = true;
    }
    if (ask) {
      await _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
    return true;
  } catch (e) {
    debugPrint('MBERR notif init: $e');
    return false;
  }
}

/// جدولة تذكير المناسبات القادمة (مساء اليوم السابق + صباح اليوم نفسه)
Future<void> scheduleOccasions() async {
  if (!await notifInit()) return;
  try {
    for (var i = 100; i < 140; i++) {
      await _fln.cancel(id: i);
    }
    if (!Opt.notifOcc) return;
    tzd.initializeTimeZones();
    final now = DateTime.now();
    var id = 100;
    for (final o in occasionsUpcoming(45)) {
      final eve = DateTime(o.day.year, o.day.month, o.day.day - 1, 19);
      final morn = DateTime(o.day.year, o.day.month, o.day.day, 8);
      for (final (at, title, body) in [(eve, 'غداً: ${o.t}', 'جهّز قائمتك من قصائد المناسبة في منبر'), (morn, o.t, 'قصائد المناسبة بانتظارك في منبر')]) {
        if (at.isBefore(now) || id >= 140) continue;
        await _fln.zonedSchedule(id: id++, title: title, body: body, scheduledDate: tz.TZDateTime.from(at, tz.UTC), notificationDetails: const NotificationDetails(android: _chOcc), androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
  } catch (e) {
    debugPrint('MBERR occ schedule: $e');
  }
}

// ---- فحص القصائد الجديدة بالخلفية (بدون خادم): قراءة قائمة القصائد عبر REST كل بضع ساعات ----
const _fsBase = 'https://firestore.googleapis.com/v1/projects/minbar-8f037/databases/(default)/documents';
const _apiKey = 'AIzaSyCIgeO-PZ-F_H597PfhRhOG7O2dXIpbWhw';

Future<Map<String, (String, String)>?> _fetchTrackHeads() async {
  final c = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final out = <String, (String, String)>{};
  try {
    String? tok;
    for (var page = 0; page < 6; page++) {
      final u = Uri.parse('$_fsBase/tracks?pageSize=300&mask.fieldPaths=title&mask.fieldPaths=reciter&key=$_apiKey${tok != null ? '&pageToken=${Uri.encodeQueryComponent(tok)}' : ''}');
      final rq = await c.getUrl(u);
      rq.headers.set('X-Android-Package', 'com.minbar.minbar_native');
      rq.headers.set('X-Android-Cert', '33E9A192DA6241AB4B61F06EB37CE1F981FC97AF');
      final r = await rq.close();
      if (r.statusCode != 200) return null;
      final m = jsonDecode(await r.transform(utf8.decoder).join()) as Map;
      for (final d in (m['documents'] as List? ?? const [])) {
        final id = '${d['name']}'.split('/').last, f = d['fields'] as Map? ?? const {};
        out[id] = ('${(f['title'] as Map?)?['stringValue'] ?? ''}', '${(f['reciter'] as Map?)?['stringValue'] ?? ''}');
      }
      tok = m['nextPageToken'] as String?;
      if (tok == null) break;
    }
    return out;
  } catch (_) {
    return null;
  } finally {
    c.close(force: true);
  }
}

Future<void> bgCheckNew() async {
  final sp = await SharedPreferences.getInstance();
  if (!(sp.getBool('o.notifNew') ?? true)) return;
  final heads = await _fetchTrackHeads();
  if (heads == null || heads.isEmpty) return;
  final known = sp.getStringList('known.ids');
  await sp.setStringList('known.ids', heads.keys.toList());
  if (known == null) return; // أول مرة: نحفظ فقط
  final ks = known.toSet();
  final fresh = heads.keys.where((k) => !ks.contains(k)).toList();
  if (fresh.isEmpty) return;
  if (!await notifInit()) return;
  final h = heads[fresh.first]!;
  final title = fresh.length == 1 ? 'قصيدة جديدة في منبر' : '${fresh.length} قصائد جديدة في منبر';
  final body = fresh.length == 1 ? [h.$1, h.$2].where((e) => e.isNotEmpty).join(' — ') : '${h.$1} وغيرها';
  await _fln.show(id: 50, title: title, body: body, notificationDetails: const NotificationDetails(android: _chNew));
}

@pragma('vm:entry-point')
void bgDispatcher() {
  Workmanager().executeTask((task, data) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await bgCheckNew();
    } catch (_) {}
    return true;
  });
}

Future<void> bgSetup() async {
  try {
    await Workmanager().initialize(bgDispatcher);
    if (Opt.notifNew) {
      await Workmanager().registerPeriodicTask('minbar.new', 'checkNew', frequency: const Duration(hours: 6), initialDelay: const Duration(hours: 1), constraints: Constraints(networkType: NetworkType.connected), existingWorkPolicy: ExistingPeriodicWorkPolicy.keep);
    } else {
      await Workmanager().cancelByUniqueName('minbar.new');
    }
  } catch (e) {
    debugPrint('MBERR bg setup: $e');
  }
}

/// بعد تحديث المكتبة والتطبيق مفتوح: نحدّث قائمة المعروف حتى لا يصل إشعار عن قصيدة شافها المستخدم
Future<void> syncKnown() async {
  if (app.repo.tracks.isEmpty || app.repo.netOff) return;
  final sp = await SharedPreferences.getInstance();
  await sp.setStringList('known.ids', [for (final t in app.repo.tracks) t.id]);
}

// ================= تنزيل المفضلة تلقائياً على الواي فاي =================
bool _autoBusy = false;
Future<void> autoDownloadFavs() async {
  if (!Opt.autoDl || _autoBusy) return;
  _autoBusy = true;
  try {
    final r = app.repo;
    for (final t in r.tracks.where((t) => r.isFav(t.id) && !r.offline.contains(t.id)).toList()) {
      final net = await Connectivity().checkConnectivity();
      if (!net.contains(ConnectivityResult.wifi) || !Opt.autoDl) break;
      await r.offSave(t, (_) {});
    }
  } catch (_) {}
  _autoBusy = false;
}

/// تُستدعى مرة عند فتح الواجهة الرئيسية
Future<void> extrasStart() async {
  await Opt.load();
  app.repo.onFav = autoDownloadFavs;
  unawaited(scheduleOccasions());
  unawaited(bgSetup());
  unawaited(syncKnown());
  unawaited(autoDownloadFavs());
  widgetStart();
}

/// ويدجت الشاشة الرئيسية — يكتب القصيدة الحالية وحالة التشغيل ثم يطلب تحديث الويدجت
const _wch = MethodChannel('minbar/fx');
String _wLast = '';
void widgetStart() {
  final p = app.player.p;
  Future<void> push() async {
    try {
      final tag = p.sequenceState?.currentSource?.tag;
      final m = tag is MediaItem ? tag : null;
      final title = m?.title ?? 'منبر', artist = m?.artist ?? 'اضغط للاستماع', key = '$title|$artist|${p.playing}';
      if (key == _wLast) return;
      _wLast = key;
      final sp = await SharedPreferences.getInstance();
      await sp.setString('w_title', title);
      await sp.setString('w_artist', artist);
      await sp.setBool('w_playing', p.playing);
      await _wch.invokeMethod('widget');
    } catch (_) {}
  }

  p.playingStream.listen((_) => push());
  p.sequenceStateStream.listen((_) => push());
  push();
}

// ================= صفحة الإعدادات =================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _size = '…';

  @override
  void initState() {
    super.initState();
    _calc();
  }

  Future<void> _calc() async {
    var n = 0;
    try {
      final d = Directory(app.repo.offDir);
      if (await d.exists()) {
        await for (final f in d.list()) {
          if (f is File) n += await f.length();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _size = '${(n / 1048576).toStringAsFixed(1)} م.ب');
  }

  void _msg(String s) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s, style: tx(13, c: Colors.white)), duration: const Duration(seconds: 2)));
  }

  Widget _sec(String s) => Padding(padding: const EdgeInsets.fromLTRB(18, 20, 18, 6), child: Text(s, style: tx(13, c: kGreen)));

  Widget _card(List<Widget> ch) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0F0E5C46), blurRadius: 14, offset: Offset(0, 4))]),
        child: Column(children: ch),
      );

  Widget _sw(String t, String sub, bool v, ValueChanged<bool> f) => SwitchListTile(
        value: v,
        onChanged: f,
        activeColor: kGreen,
        title: Text(t, style: tx(14.5)),
        subtitle: Text(sub, style: tx(11.5, c: kMuted)),
      );

  Widget _row(String ic, String t, String sub, VoidCallback f) => ListTile(
        leading: PIcon(ic, color: kGreen, size: 22),
        title: Text(t, style: tx(14.5)),
        subtitle: sub.isEmpty ? null : Text(sub, style: tx(11.5, c: kMuted)),
        onTap: f,
      );

  @override
  Widget build(BuildContext context) {
    final a = app.auth, r = app.repo, pc = app.player;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(backgroundColor: kCream, elevation: 0, scrolledUnderElevation: 0, foregroundColor: kGreen, title: Text('الإعدادات', style: tx(19, c: kGreen))),
        body: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
          _sec('الحساب'),
          _card([
            ListTile(
              leading: const CircleAvatar(radius: 22, backgroundColor: kGreen, child: PIcon(Ic.users, color: kGold, size: 22)),
              title: Text(a.guest ? 'ضيف' : (a.user?.displayName ?? ''), style: tx(15.5)),
              subtitle: Text(a.guest ? 'تستمع بدون حساب — الإعجابات والتعليقات والمجلس تحتاج حساب Google' : (a.user?.email ?? ''), style: tx(11.5, c: kMuted)),
            ),
            _row(Ic.power, a.guest ? 'تسجيل الدخول بحساب Google' : 'تسجيل الخروج', '', () {
              Navigator.pop(context);
              a.signOut();
            }),
          ]),
          _sec('الإشعارات'),
          _card([
            _sw('قصيدة جديدة', 'تنبيه عند إضافة قصائد للمكتبة (فحص كل بضع ساعات)', Opt.notifNew, (v) async {
              Opt.set('notifNew', v);
              setState(() {});
              if (v) await notifInit(ask: true);
              bgSetup();
            }),
            _sw('تذكير المناسبات', 'مساء اليوم السابق وصباح المناسبة', Opt.notifOcc, (v) async {
              Opt.set('notifOcc', v);
              setState(() {});
              if (v) await notifInit(ask: true);
              scheduleOccasions();
            }),
          ]),
          _sec('التشغيل'),
          _card([
            _sw('إطفاء تدريجي مع مؤقت النوم', 'ينخفض الصوت تدريجياً قبل التوقف', Opt.fade, (v) {
              Opt.set('fade', v);
              setState(() {});
            }),
            _row(Ic.speed, 'وضع السيارة', 'أزرار كبيرة وشاشة لا تنطفئ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarPage()))),
          ]),
          _sec('التنزيلات'),
          _card([
            _sw('تنزيل المفضلة تلقائياً', 'على الواي فاي فقط', Opt.autoDl, (v) {
              Opt.set('autoDl', v);
              setState(() {});
              if (v) autoDownloadFavs().then((_) => _calc());
            }),
            _row(Ic.down, 'القصائد المنزّلة', '${r.offline.length} قصيدة · $_size', () {}),
            _row(Ic.x, 'حذف كل التنزيلات', '', () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: Text('حذف كل التنزيلات؟', style: tx(16)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: Text('إلغاء', style: tx(13, c: kMuted))),
                      TextButton(onPressed: () => Navigator.pop(d, true), child: Text('حذف', style: tx(13, c: const Color(0xFFD9534F)))),
                    ],
                  ),
                ),
              );
              if (ok != true) return;
              for (final id in r.offline.toList()) {
                final t = r.byId(id);
                if (t != null) await r.offDel(t);
              }
              await _calc();
              _msg('حُذفت التنزيلات');
            }),
          ]),
          _sec('التطبيق'),
          _card([
            _row(Ic.reset, 'تحديث المكتبة', '', () {
              r.refresh().then((_) => syncKnown());
              _msg('جارٍ التحديث…');
            }),
            _row(Ic.down, 'التحقق من تحديث التطبيق', 'نسخة 1.0 · بناء $kBuild', () async {
              final u = await latestUpdate();
              if (!mounted) return;
              if (u.build > kBuild) {
                launchApk(u.url);
              } else {
                _msg('أنت على آخر نسخة');
              }
            }),
            _row(Ic.info, 'الخصوصية', 'ما يُحفظ وأين', () {
              showDialog(
                context: context,
                builder: (d) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: Text('الخصوصية', style: tx(17)),
                    content: Text('• المفضلة والقوائم والتنزيلات ومواضع الاستماع تُحفظ على جهازك فقط.\n• عند الدخول بحساب Google يُستعمل اسمك مع تعليقاتك وإعجاباتك التي يراها الآخرون.\n• عدّاد الاستماع مجهول ولا يرتبط بحسابك.\n• الميكروفون يُستعمل فقط عند ضغط زر التعرّف على القصيدة.', style: tx(13.5, h: 1.8)),
                    actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text('تم', style: tx(13, c: kGreen)))],
                  ),
                ),
              );
            }),
          ]),
        ]),
      ),
    );
  }
}

// ================= وضع السيارة =================
class CarPage extends StatefulWidget {
  const CarPage({super.key});
  @override
  State<CarPage> createState() => _CarPageState();
}

class _CarPageState extends State<CarPage> {
  List<Lyric> ly = const [];
  String? _id;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    app.player.addListener(_r);
    _r();
  }

  void _r() {
    final t = app.player.cur;
    if (t != null && t.id != _id) {
      _id = t.id;
      ly = const [];
      app.repo.lyricsFor(t).then((l) {
        if (mounted && _id == t.id) setState(() => ly = l);
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    app.player.removeListener(_r);
    super.dispose();
  }

  Widget _btn(String ic, VoidCallback f, {double s = 96, bool main = false}) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          f();
        },
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(shape: BoxShape.circle, color: main ? kGold : const Color(0x1FFFFFFF), border: Border.all(color: main ? kGold2 : const Color(0x40FFFFFF), width: 2)),
          child: Center(child: PIcon(ic, color: main ? const Color(0xFF2A2106) : Colors.white, size: s * 0.46)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pc = app.player, t = pc.cur;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF04140F),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const PIcon(Ic.x, color: Colors.white70, size: 28)),
                const Spacer(),
                Text('وضع السيارة', style: tx(15, c: Colors.white38)),
              ]),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                Text(t?.title ?? 'اختر قصيدة', maxLines: 2, textAlign: TextAlign.center, style: tx(34, c: Colors.white, h: 1.4)),
                const SizedBox(height: 6),
                Text(t?.reciter ?? '', style: tx(20, c: kGold)),
              ]),
            ),
            SizedBox(height: 150, child: ly.isEmpty ? const SizedBox() : LyricStrip(lines: ly, base: 26)),
            const Spacer(),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _btn(Ic.prev, pc.prev),
                StreamBuilder<PlayerState>(stream: pc.p.playerStateStream, builder: (_, s) => _btn((s.data?.playing ?? false) ? Ic.pause : Ic.play, pc.toggle, s: 132, main: true)),
                _btn(Ic.next, pc.next),
              ]),
            ),
            const SizedBox(height: 28),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _btn(Ic.rw, () => pc.seek((pc.p.position.inSeconds - 15).clamp(0, 1 << 30).toDouble()), s: 72),
                _btn(t != null && app.repo.isFav(t.id) ? Ic.heartF : Ic.heart, () {
                  if (t != null) app.repo.toggleFav(t.id);
                  setState(() {});
                }, s: 72),
                _btn(Ic.fw, () => pc.seek(pc.p.position.inSeconds + 15.0), s: 72),
              ]),
            ),
            const SizedBox(height: 36),
          ]),
        ),
      ),
    );
  }
}
