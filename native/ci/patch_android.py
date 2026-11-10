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
'''
if 'FOREGROUND_SERVICE_MEDIA_PLAYBACK' not in s:
    s = s.replace('<application', perms + '    <application', 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="منبر"', s, count=1)
s = s.replace('android:name=".MainActivity"', 'android:name="com.ryanheise.audioservice.AudioServiceActivity"')
svc = '''        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
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
# MainActivity
for kt in root.rglob('MainActivity.*'):
    pkg = re.search(r'^package\s+([\w.]+)', kt.read_text(encoding='utf-8'), re.M).group(1)
    if kt.suffix == '.kt':
        kt.write_text(f'package {pkg}\n\nimport com.ryanheise.audioservice.AudioServiceActivity\n\nclass MainActivity : AudioServiceActivity()\n', encoding='utf-8')
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
