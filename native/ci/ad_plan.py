"""يولّد خطة إعلان وضع السيارة: ci/ad_timeline.json (للرسم) و /tmp/ad/plan.json (للعناوين)"""
import json, math, os, sys
FPS = 30; DUR = 50.0; N = int(FPS * DUR)
W, H = 405.0, 720.0
HZ, CARY, CW = 0.35 * H, 0.69 * H, 0.42 * W
COLORS = ['gold', 'blue', 'red', 'silver', 'white', 'black', 'green']
COLN = {'gold': 'ذهبي', 'blue': 'أزرق', 'red': 'أحمر', 'silver': 'فضي', 'white': 'أبيض', 'black': 'أسود', 'green': 'أخضر منبر'}
MODN = {'sport': 'رياضية', 'sedan': 'سيدان', 'suv': 'دفع رباعي'}
WX = {
 'clear': dict(rain=0, snow=0, cloud=0.05, fog=0, dust=0, storm=0, wind=2, temp=24, label='صافٍ', icon='sun'),
 'cloudy': dict(rain=0, snow=0, cloud=0.9, fog=0, dust=0, storm=0, wind=3, temp=19, label='غائم', icon='cloud'),
 'rain': dict(rain=0.75, snow=0, cloud=0.95, fog=0, dust=0, storm=0, wind=3, temp=14, label='مطر', icon='rain'),
 'storm': dict(rain=0.9, snow=0, cloud=1, fog=0, dust=0, storm=1, wind=8, temp=12, label='عاصفة رعدية', icon='storm'),
 'fog': dict(rain=0, snow=0, cloud=0.6, fog=0.8, dust=0, storm=0, wind=1, temp=9, label='ضباب', icon='fog'),
 'dust': dict(rain=0, snow=0, cloud=0.2, fog=0, dust=0.85, storm=0, wind=9, temp=33, label='غبار', icon='fog'),
 'snow': dict(rain=0, snow=0.8, cloud=0.95, fog=0, dust=0, storm=0, wind=2, temp=-1, label='ثلج', icon='snow'),
}
# (بداية، نهاية، مفتاح، نوع منطقة، طقس، وقت، سرعة كم/س)
BIO = {'city': 0, 'desert': 1, 'farm': 2, 'mount': 3, 'marsh': 4}
SEG = [
 (0, 5, 'intro', 'city', 'clear', 'night', 70),
 (5, 9.6, 'colors', 'city', 'clear', 'night', 70),
 (9.6, 13.2, 'models', 'city', 'clear', 'night', 70),
 (13.2, 15.6, 'w_clear', 'city', 'clear', 'day', 80),
 (15.6, 18.0, 'w_cloudy', 'farm', 'cloudy', 'day', 80),
 (18.0, 21.0, 'w_rain', 'farm', 'rain', 'day', 70),
 (21.0, 24.4, 'w_storm', 'farm', 'storm', 'night', 60),
 (24.4, 26.8, 'w_fog', 'farm', 'fog', 'day', 45),
 (26.8, 29.2, 'w_dust', 'desert', 'dust', 'day', 70),
 (29.2, 32.0, 'w_snow', 'mount', 'snow', 'day', 50),
 (32.0, 33.2, 'r_city', 'city', 'clear', 'day', 70),
 (33.2, 34.4, 'r_farm', 'farm', 'clear', 'day', 85),
 (34.4, 35.6, 'r_desert', 'desert', 'clear', 'day', 100),
 (35.6, 36.8, 'r_mount', 'mount', 'clear', 'day', 70),
 (36.8, 38.0, 'r_marsh', 'marsh', 'clear', 'day', 60),
 (38.0, 42.0, 'tod', 'farm', 'clear', 'tod', 80),
 (42.0, 47.0, 'turn', 'city', 'rain', 'night', 80),
 (47.0, 50.0, 'outro', 'city', 'clear', 'night', 90),
]
PLACE = {'r_city': 'بغداد', 'r_farm': 'ديالى', 'r_desert': 'الأنبار', 'r_mount': 'دهوك', 'r_marsh': 'البصرة'}

def seg_at(t):
    for s in SEG:
        if s[0] <= t < s[1]: return s
    return SEG[-1]

def sm(a, b, x):
    u = min(1, max(0, (x - a) / (b - a))); return u * u * (3 - 2 * u)

def tod_el(u):
    if u < 0.35: return -8 + 63 * sm(0, 0.35, u)
    if u < 0.62: return 55
    if u < 0.82: return 55 - 52 * sm(0.62, 0.82, u)
    return 3 - 28 * sm(0.82, 1.0, u)

def sun_state(kind, t, seg, heading):
    if kind == 'tod':
        u = (t - seg[0]) / (seg[1] - seg[0]); el = tod_el(u)
        return el, heading + 25 - 40 * u, max(-30, min(40, -el * 0.9)), heading + 14
    if kind == 'day': return 55, heading + 25, -20, heading + 14
    if kind == 'sunset': return 4, heading + 22, -20, heading + 14
    return -30, heading, 38, heading + 14

def main():
    dt = 1 / FPS
    v = 0.0; a = 0.0; brake = 1.0; pitch = 0.0; curv = 0.0; lean = 0.0; q = 0.0; heading = 180.0; turn = 0.0
    wx = dict(WX['clear']); cur = dict(rain=0, snow=0, cloud=0, fog=0, dust=0, storm=0, wind=2)
    sun = [-30.0, 180.0, 38.0, 194.0]; flash = 0.0; bolt = 0
    frames, plan = [], []
    bolts = [21.6, 22.5, 22.8, 23.7]
    for i in range(N):
        t = i * dt; seg = seg_at(t); key = seg[2]
        # سرعة مستهدفة
        tgt = seg[6] / 3.6
        if key == 'intro': tgt = 70 / 3.6 * sm(0.2, 3.8, t)
        tr = 0.0; blink = 0
        if key == 'turn':
            u = t - 42
            tgt = (80 if u < 1.5 else (28 if u < 3.7 else 70)) / 3.6
            if 2.1 < u < 4.4: tr = -0.30 * math.sin(math.pi * (u - 2.1) / 2.3)
            if 1.8 < u < 4.8: blink = -1
        if key == 'w_storm' and False: pass
        # فيزياء مثل التطبيق
        prev = v
        v += (tgt - v) * min(1, dt * 2.4)
        a += ((v - prev) / dt - a) * min(1, dt * 4)
        braking = (a < -0.7 and v > 0.5) or v < 0.35
        brake += ((1.0 if braking else 0.0) - brake) * min(1, dt * 14)
        q += v * dt / 2.5
        turn += (tr - turn) * 0.6
        heading = (heading + math.degrees(turn) * dt) % 360
        k = max(-0.03, min(0.03, turn / v)) if v > 2.5 else 0.0
        curv += (k - curv) * min(1, dt * 1.2)
        lean += ((max(-0.5, min(0.5, v * turn / 9.8))) - lean) * min(1, dt * 3)
        pitch += (max(-2.5, min(2.5, -a * 0.5)) - pitch) * min(1, dt * 5)
        # طقس
        target_wx = WX[seg[4]]
        m = min(1, dt * 3.2)
        for f in cur: cur[f] += (target_wx[f] - cur[f]) * m
        wx['temp'] += (target_wx['temp'] - wx['temp']) * m
        # شمس/قمر
        tod = seg[5]
        want = sun_state(tod, t, seg, heading)
        if tod == 'tod': sun = list(want)
        else:
            for j in range(4): sun[j] += (want[j] - sun[j]) * min(1, dt * 4)
        # برق
        flash *= math.exp(-dt * 7)
        for bt in bolts:
            if abs(t - bt) < dt / 2: flash = 1.0; bolt += 1
        # نقاط بارزة
        marks = []
        if seg[3] == 'city' and key in ('intro', 'colors', 'models', 'turn', 'outro', 'r_city', 'w_clear'):
            marks = [[heading - 14, 9.0, 0], [heading + 24, 14.0, 1]]
        if seg[3] == 'mount': marks = [[heading + 18, 22.0, 3]]
        if seg[3] == 'desert': marks = [[heading - 20, 30.0, 4]]
        # أشكال
        color = 'green'; model = 'sport'
        if key == 'colors': color = COLORS[min(6, int((t - 5) / (4.6 / 7)))]
        elif key == 'models':
            model = ['sport', 'sedan', 'suv'][min(2, int((t - 9.6) / 1.2))]; color = 'green'
        elif key == 'turn': model = 'suv'
        elif t >= 13.2 and key not in ('outro',):
            color = ['silver', 'blue', 'white', 'black', 'gold', 'red', 'silver', 'blue', 'white', 'gold', 'black', 'red', 'blue'][min(12, int((t - 13.2) / 1.5))]
            model = ['sedan', 'sport', 'suv'][int((t - 13.2) / 4) % 3]
        if key == 'outro': color, model = 'green', 'sport'
        if key == 'colors': model = 'sport'
        fr = dict(t=round(t, 4), q=round(q, 4), v=round(v, 3), a=round(a, 3), brake=round(brake, 3), tail=0.3,
                  curv=round(curv, 5), lean=round(lean, 4), blink=blink, pitch=round(pitch, 3), spin=0, flash=round(flash, 3),
                  splash=round(min(1, v / 20) * cur['rain'], 3), sunEl=round(sun[0], 2), sunAz=round(sun[1] % 360, 2), moonEl=round(sun[2], 2),
                  moonAz=round(sun[3] % 360, 2), moonPh=0.3, heading=round(heading, 2),
                  rain=round(cur['rain'], 3), snow=round(cur['snow'], 3), cloud=round(cur['cloud'], 3), fog=round(cur['fog'], 3),
                  dust=round(cur['dust'], 3), storm=round(cur['storm'], 3), wind=round(cur['wind'], 2), biome=BIO[seg[3]], temp=round(wx['temp'], 1),
                  marks=marks, bolt=bolt, model=model, color=color, hz=HZ, cx=W / 2, carY=CARY, cw=CW, dpr=1080 / W)
        frames.append(fr)
        plan.append(dict(t=round(t, 3), key=key, kmh=round(v * 3.6, 1), color=color, model=model, biome=seg[3], wx=seg[4], temp=round(wx['temp']), blink=blink, brake=round(brake, 2),
                         sunEl=round(sun[0], 1), tod=tod, place=PLACE.get(key, '')))
    json.dump(frames, open(os.path.join(os.path.dirname(__file__), 'ad_timeline.json'), 'w'), separators=(',', ':'))
    os.makedirs('/tmp/ad', exist_ok=True)
    json.dump(dict(plan=plan, seg=SEG, coln=COLN, modn=MODN, wx=WX), open('/tmp/ad/plan.json', 'w'), ensure_ascii=False)
    print('frames', len(frames), os.path.getsize(os.path.join(os.path.dirname(__file__), 'ad_timeline.json')) // 1024, 'KB')
main()
