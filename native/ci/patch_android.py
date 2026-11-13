import re, sys, pathlib
root = pathlib.Path('android')
# المانيفست: صلاحيات + خدمة الصوت
mf = root / 'app/src/main/AndroidManifest.xml'
s = mf.read_text(encoding='utf-8')
perms = '''    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
'''
if 'FOREGROUND_SERVICE_MEDIA_PLAYBACK' not in s:
    s = s.replace('<application', perms + '    <application', 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="منبر"', s, count=1)
# نبقي MainActivity (ترث AudioServiceActivity) لأن فيها قناة المؤثرات والويدجت
# singleTask: فتح التطبيق بعد التحديث لا يُنشئ نسخة ثانية في قائمة التطبيقات
s = s.replace('android:launchMode="singleTop"', 'android:launchMode="singleTask"')
svc = '''        <receiver android:name=".MinbarWidget" android:exported="false">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/minbar_widget_info" />
        </receiver>
        <provider android:name="sk.fourq.otaupdate.OtaUpdateFileProvider"
            android:authorities="${applicationId}.ota_update_provider"
            android:exported="false" android:grantUriPermissions="true">
            <meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/filepaths" />
        </provider>
        <receiver android:name="sk.fourq.otaupdate.InstallResultReceiver" android:exported="false">
            <intent-filter><action android:name="${applicationId}.ACTION_INSTALL_COMPLETE"/></intent-filter>
        </receiver>
        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
'''
if 'com.ryanheise.audioservice.AudioService"' not in s:
    s = s.replace('</application>', svc + '    </application>', 1)
if '<queries>' not in s:
    s = s.replace('<application', '<queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent><intent><action android:name="android.speech.RecognitionService"/></intent></queries>\n    <application', 1)
if 'xmlns:tools' not in s:
    s = s.replace('<manifest ', '<manifest xmlns:tools="http://schemas.android.com/tools" ', 1)
if 'minbar-95z.pages.dev' not in s:
    deep = '''            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https" android:host="minbar-95z.pages.dev"/>
            </intent-filter>
'''
    i = s.find('<category android:name="android.intent.category.LAUNCHER"')
    j = s.find('</intent-filter>', i) + len('</intent-filter>')
    s = s[:j] + '\n' + deep + s[j:]
mf.write_text(s, encoding='utf-8')

# مؤثرات أندرويد الأصلية للصوت: التوازن (DynamicsProcessing) + التوسيع (Virtualizer) + صدى القاعة (PresetReverb)
FX_KT = """import android.media.audiofx.DynamicsProcessing
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import android.os.Build
import android.os.Bundle
import android.app.ActivityManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var sid = -1
    private var virt: Virtualizer? = null
    private var rev: PresetReverb? = null
    private var dp: DynamicsProcessing? = null

    private fun fxFree() {
        try { virt?.release() } catch (e: Exception) {}
        try { rev?.release() } catch (e: Exception) {}
        try { dp?.release() } catch (e: Exception) {}
        virt = null; rev = null; dp = null
    }

    // بعد التحديث من داخل التطبيق تبقى مهمة قديمة بالتطبيقات الأخيرة: نزيل أي مهمة غير الحالية
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val am = getSystemService(ACTIVITY_SERVICE) as ActivityManager
            for (t in am.appTasks) {
                try {
                    @Suppress("DEPRECATION")
                    if (t.taskInfo.id != taskId) t.finishAndRemoveTask()
                } catch (e: Exception) {}
            }
        } catch (e: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "minbar/fx").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "attach" -> {
                        val s = (call.argument<Int>("s") ?: -1)
                        if (s > 0 && s != sid) {
                            fxFree(); sid = s
                            try { virt = Virtualizer(0, s) } catch (e: Exception) {}
                            try { rev = PresetReverb(0, s) } catch (e: Exception) {}
                            if (Build.VERSION.SDK_INT >= 28) {
                                try {
                                    val cfg = DynamicsProcessing.Config.Builder(DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION, 2, false, 0, false, 0, false, 0, false).build()
                                    dp = DynamicsProcessing(0, s, cfg)
                                } catch (e: Exception) {}
                            }
                        }
                        result.success(listOf(virt != null, rev != null, dp != null))
                    }
                    "virt" -> {
                        val v = (call.argument<Int>("v") ?: 0)
                        virt?.let { if (v > 0) { it.setStrength(v.toShort()); it.enabled = true } else it.enabled = false }
                        result.success(virt != null)
                    }
                    "rev" -> {
                        val v = (call.argument<Int>("v") ?: 0)
                        rev?.let { if (v > 0) { it.preset = v.toShort(); it.enabled = true } else it.enabled = false }
                        result.success(rev != null)
                    }
                    "bal" -> {
                        val l = (call.argument<Double>("l") ?: 0.0).toFloat()
                        val r = (call.argument<Double>("r") ?: 0.0).toFloat()
                        dp?.let { it.setInputGainbyChannel(0, l); it.setInputGainbyChannel(1, r); it.enabled = (l != 0f || r != 0f) }
                        result.success(dp != null)
                    }
                    "widget" -> { MinbarWidget.refresh(this); result.success(true) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.success(false) }
        }
    }
}
"""

WIDGET_KT = """import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import android.widget.RemoteViews

/** ويدجت الشاشة الرئيسية: القصيدة الحالية + سابق/تشغيل/تالي (أزرار وسائط تذهب لجلسة التشغيل) */
class MinbarWidget : AppWidgetProvider() {
    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) { for (id in ids) draw(ctx, mgr, id) }
    companion object {
        private fun media(ctx: Context, code: Int): PendingIntent {
            val i = Intent(Intent.ACTION_MEDIA_BUTTON).setComponent(ComponentName(ctx, "com.ryanheise.audioservice.MediaButtonReceiver"))
            i.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, code))
            return PendingIntent.getBroadcast(ctx, code, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        fun draw(ctx: Context, mgr: AppWidgetManager, id: Int) {
            val sp = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val v = RemoteViews(ctx.packageName, R.layout.minbar_widget)
            v.setTextViewText(R.id.w_title, sp.getString("flutter.w_title", "منبر"))
            v.setTextViewText(R.id.w_artist, sp.getString("flutter.w_artist", "اضغط للاستماع"))
            v.setImageViewResource(R.id.w_play, if (sp.getBoolean("flutter.w_playing", false)) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play)
            v.setOnClickPendingIntent(R.id.w_play, media(ctx, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
            v.setOnClickPendingIntent(R.id.w_next, media(ctx, KeyEvent.KEYCODE_MEDIA_NEXT))
            v.setOnClickPendingIntent(R.id.w_prev, media(ctx, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
            ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)?.let {
                v.setOnClickPendingIntent(R.id.w_root, PendingIntent.getActivity(ctx, 1, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
            }
            mgr.updateAppWidget(id, v)
        }
        fun refresh(ctx: Context) {
            val m = AppWidgetManager.getInstance(ctx)
            for (id in m.getAppWidgetIds(ComponentName(ctx, MinbarWidget::class.java))) draw(ctx, m, id)
        }
    }
}
"""

# MainActivity
for kt in root.rglob('MainActivity.*'):
    pkg = re.search(r'^package\s+([\w.]+)', kt.read_text(encoding='utf-8'), re.M).group(1)
    if kt.suffix == '.kt':
        kt.write_text(f'package {pkg}\n\n' + FX_KT, encoding='utf-8')
        (kt.parent / 'MinbarWidget.kt').write_text(f'package {pkg}\n\n' + WIDGET_KT, encoding='utf-8')
# minSdk 23
for g in [root / 'app/build.gradle.kts', root / 'app/build.gradle']:
    if g.exists():
        t = g.read_text(encoding='utf-8')
        t = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', t)
        t = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', t)
        g.write_text(t, encoding='utf-8')
print('patched')
# توقيع ثابت صريح (حتى لا يولّد Gradle مفتاحاً عشوائياً فيفشل دخول Google: invalid-cert-hash)
g = root / 'app/build.gradle.kts'
if g.exists():
    t = g.read_text(encoding='utf-8')
    if 'create("minbar")' not in t:
        t = t.replace('    buildTypes {', '''    signingConfigs {
        create("minbar") {
            storeFile = file("../../ci/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
    buildTypes {''', 1)
        t = t.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("minbar")')
        g.write_text(t, encoding='utf-8')
        print('signing patched', 'getByName("minbar")' in t)

# تفعيل desugaring المطلوب لمكتبة الإشعارات
if g.exists():
    t = g.read_text(encoding='utf-8')
    if 'isCoreLibraryDesugaringEnabled' not in t:
        t = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', t, count=1)
        t += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
        if 'multiDexEnabled' not in t:
            t = re.sub(r'defaultConfig\s*\{', 'defaultConfig {\n        multiDexEnabled = true', t, count=1)
        g.write_text(t, encoding='utf-8')
        print('desugar patched', 'isCoreLibraryDesugaringEnabled' in t)

# أيقونة الإشعارات البيضاء
import shutil
src = pathlib.Path(__file__).parent / 'res'
dst = pathlib.Path('android/app/src/main/res')
if src.exists():
    for d in src.iterdir():
        (dst / d.name).mkdir(parents=True, exist_ok=True)
        for f in d.iterdir():
            shutil.copy(f, dst / d.name / f.name)
    print('notification icon copied')

# تعطيل فحص lint عند بناء الإصدار (يتعطّل أحياناً داخل مكتبات خارجية بلا علاقة بكودنا)
if g.exists():
    t = g.read_text(encoding='utf-8')
    if 'checkReleaseBuilds' not in t:
        t = re.sub(r'(\nandroid\s*\{)', r'\1\n    lint {\n        checkReleaseBuilds = false\n        abortOnError = false\n    }', t, count=1)
        g.write_text(t, encoding='utf-8')
        print('lint disabled', 'checkReleaseBuilds' in t)
