"""يقود التطبيق على المحاكي حسب native/ci/shots.txt ويحفظ لقطات مصغّرة في shots/"""
import subprocess, time, re, os, sys, pathlib, shlex
PKG = 'com.minbar.minbar_native'
OUT = pathlib.Path('shots'); OUT.mkdir(exist_ok=True)

def adb(*a, out=False, t=60):
    try:
        r = subprocess.run(['adb', *a], capture_output=True, timeout=t)
        return r.stdout if out else r.returncode
    except Exception as e:
        print('adb err', a, e); return b'' if out else 1

def shot(name):
    png = adb('exec-out', 'screencap', '-p', out=True)
    p = OUT / (name + '.png'); p.write_bytes(png)
    try:
        from PIL import Image
        im = Image.open(p).convert('RGB'); im = im.resize((im.width // 2, im.height // 2)); im.save(OUT / (name + '.jpg'), quality=78); p.unlink()
    except Exception as e:
        print('img', e)
    print('shot', name, flush=True)

def dump():
    adb('shell', 'uiautomator', 'dump', '/sdcard/u.xml')
    return adb('exec-out', 'cat', '/sdcard/u.xml', out=True).decode('utf-8', 'ignore')

def anr(x=None):
    x = x if x is not None else dump()
    if "isn't responding" in x or 'keeps stopping' in x:
        for lbl in ('Wait', 'Close app'):
            m = re.search(r'<node [^>]*text="' + lbl + r'"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', x)
            if m:
                a, b, c, d = map(int, m.groups()); adb('shell', 'input', 'tap', str((a + c) // 2), str((b + d) // 2))
                print('anr dismissed', flush=True); time.sleep(3); return True
    return False

def tap_text(s, idx=0):
    for _ in range(3):
        x = dump()
        if anr(x): x = dump()
        hits = []
        for m in re.finditer(r'<node [^>]*>', x):
            n = m.group(0)
            if s in (re.search(r'text="([^"]*)"', n) or [0, ''])[1] or s in (re.search(r'content-desc="([^"]*)"', n) or [0, ''])[1]:
                b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
                if b: hits.append([int(v) for v in b.groups()])
        if len(hits) > idx:
            a, b, c, d = hits[idx]
            adb('shell', 'input', 'tap', str((a + c) // 2), str((b + d) // 2))
            print('tap', s, (a + c) // 2, (b + d) // 2, flush=True); return True
        time.sleep(2)
    print('NOT FOUND', s, flush=True); return False

subprocess.run([sys.executable, '-m', 'pip', 'install', '-q', 'pillow'], capture_output=True)
adb('install', '-r', 'minbar.apk', t=180)
for p in ['POST_NOTIFICATIONS', 'RECORD_AUDIO']:
    adb('shell', 'pm', 'grant', PKG, 'android.permission.' + p)
for k in ('hide_error_dialogs 1','anr_show_background 0'):
    adb('shell','settings','put','global',*k.split())
adb('shell','settings','put','secure','immersive_mode_confirmations','confirmed')
adb('shell','am','force-stop','com.android.systemui')
for _ in range(6):
    time.sleep(10)
    if not anr(): break
adb('logcat', '-c')
adb('shell', 'monkey', '-p', PKG, '-c', 'android.intent.category.LAUNCHER', '1')
for ln in open(os.environ.get('SHOTS_FILE') or 'native/ci/shots.txt', encoding='utf-8'):
    ln = ln.strip()
    if not ln or ln.startswith('#'): continue
    c = shlex.split(ln)
    try:
        if c[0] == 'wait': time.sleep(float(c[1]))
        elif c[0] == 'shot': anr(); shot(c[1])
        elif c[0] == 'until':
            for _ in range(int(c[2]) if len(c) > 2 else 6):
                if c[1] not in dump(): break
                tap_text(c[1]); time.sleep(8)
        elif c[0] == 'tap': adb('shell', 'input', 'tap', c[1], c[2])
        elif c[0] == 'text': tap_text(c[1], int(c[2]) if len(c) > 2 else 0)
        elif c[0] == 'swipe': adb('shell', 'input', 'swipe', *c[1:])
        elif c[0] == 'long': adb('shell', 'input', 'swipe', c[1], c[2], c[1], c[2], '900')
        elif c[0] == 'back': adb('shell', 'input', 'keyevent', '4')
        elif c[0] == 'app':
            f = adb('shell', 'dumpsys', 'window', out=True).decode('utf-8', 'ignore')
            m = re.search(r'mCurrentFocus=.*', f)
            if not m or PKG not in m.group(0):
                print('relaunch', flush=True)
                adb('shell', 'monkey', '-p', PKG, '-c', 'android.intent.category.LAUNCHER', '1'); time.sleep(8)
        elif c[0] == 'sys': (OUT / (c[1] + '.txt')).write_bytes(adb('shell', *c[2:], out=True))
        elif c[0] == 'dump': (OUT / (c[1] + '.xml')).write_text(dump(), encoding='utf-8')
    except Exception as e:
        print('step err', ln, e, flush=True)
log = adb('logcat', '-d', '-v', 'brief', out=True).decode('utf-8', 'ignore')
keep = [l for l in log.splitlines() if 'I/flutter' in l or 'E/flutter' in l or 'FATAL' in l or 'E/AndroidRuntime' in l or 'System.err' in l or re.search(r'(?i)audioservice|ryanheise|MediaSession|ForegroundService|minbar', l)]
(OUT / 'log.txt').write_text('\n'.join(keep[-1500:]), encoding='utf-8')
