"""ضبط كلمات القصائد تلقائياً على الصوت (يعمل على GitHub Actions).
يسمع الصوت بموديل Whisper كبير، يطابق الأبيات مع المسموع (مع اكتشاف تكرار المستهل والأبيات)،
ثم يكتب النتيجة في lyrApproved ليقرأها التطبيق والويب مباشرة.
"""
import os, re, sys, json, time, math, subprocess, tempfile, urllib.request, urllib.parse
from rapidfuzz import fuzz
from google.cloud import firestore

BASE = 'https://minbar-95z.pages.dev/'
ALBUM = os.environ.get('ALBUM', '').strip()
WRITE = os.environ.get('WRITE', 'false').lower() == 'true'
LIMIT = int(os.environ.get('LIMIT') or 50)
MODEL = os.environ.get('MODEL') or 'large-v3-turbo'
ONLY = os.environ.get('ONLY', '').strip()
VOCALS = os.environ.get('VOCALS', 'true').lower() == 'true'
SHARD = int(os.environ.get('SHARD') or 0); SHARDS = int(os.environ.get('SHARDS') or 1)

SEP = re.compile(r'^[\s\*\-–—_\.•~=♪…]+$')
def norm(s):
    s = re.sub(r'[ً-ٰٟـ]', '', s)
    s = re.sub('[أإآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه').replace('ؤ', 'و').replace('ئ', 'ي')
    s = s.replace('گ', 'ك').replace('ق', 'ك').replace('چ', 'ج').replace('ض', 'ظ')
    s = re.sub(r'[^ء-ي\s]', ' ', s)
    return re.sub(r'\s+', ' ', s).strip()

def transcribe(path, hot):
    from faster_whisper import WhisperModel
    global _M
    if '_M' not in globals():
        _M = WhisperModel(MODEL, device='cpu', compute_type='int8', cpu_threads=os.cpu_count() or 4)
    segs, info = _M.transcribe(path, language='ar', beam_size=2, word_timestamps=True, condition_on_previous_text=False,
                               vad_filter=False, hotwords=hot or None, no_speech_threshold=0.8)
    W = []
    for s in segs:
        for w in (s.words or []):
            for part in norm(w.word).split():
                W.append((part, float(w.start), float(w.end)))
    return W

def clean_ar(l):
    l = re.sub(r'[\u064B-\u065F\u0670\u0640]', '', l)
    l = re.sub(r'[^\u0621-\u064A\s]', ' ', l)
    return [w for w in l.split() if w]

def forced_align(wav, seq_lines):
    """محاذاة إجبارية (MMS): يأخذ النص الصحيح بترتيب الإنشاد ويحدد وقت كل كلمة على الصوت."""
    import torch
    from ctc_forced_aligner import load_audio, load_alignment_model, generate_emissions, preprocess_text, get_alignments, get_spans, postprocess_results
    global _FA
    if '_FA' not in globals(): _FA = load_alignment_model('cpu', dtype=torch.float32)
    model, tok = _FA
    words = [clean_ar(l) or ['ا'] for l in seq_lines]
    text = ' '.join(' '.join(w) for w in words)
    audio = load_audio(wav, model.dtype, model.device)
    em, stride = generate_emissions(model, audio, batch_size=4)
    tokens, starred = preprocess_text(text, romanize=True, language='ara')
    segs, scores, blank = get_alignments(em, tokens, tok)
    spans = get_spans(tokens, segs, blank)
    res = [r for r in postprocess_results(starred, spans, stride, scores) if '<star>' not in r['text']]
    n = sum(len(w) for w in words)
    if len(res) != n:
        print(f'  تنبيه: عدد كلمات المحاذاة {len(res)} ≠ {n}'); return None
    out, k = [], 0
    for w in words:
        part = res[k:k + len(w)]; k += len(w)
        out.append((float(part[0]['start']), float(part[-1]['end']), sum(float(x.get('score', 0)) for x in part) / len(part)))
    return out

def align(lines, W, R):
    """lines: الأبيات (مطبّعة)، W: كلمات المسموع، R: عدد أبيات المستهل (أول مقطع).
    يرجع قائمة (فهرس البيت، وقت البداية أو None، الثقة) بترتيب الإنشاد مع التكرارات."""
    N, T = len(lines), len(W)
    flat = [l.replace(' ', '') for l in lines]
    wl = [max(1, len(l.split())) for l in lines]
    cache = {}
    def sim(i, a, n):
        if n == 0: return 0.0
        k = (i, a, n)
        v = cache.get(k)
        if v is None:
            v = cache[k] = fuzz.ratio(flat[i], ''.join(w[0] for w in W[a:a + n])) / 100.0
        return v
    def sc(i, a, n): return (sim(i, a, n) - 0.5) * max(6, len(flat[i])) / 10.0
    lens = [list(range(max(1, wl[i] // 2), min(16, int(wl[i] * 1.6) + 2))) for i in range(N)]
    SKIP, JP = 0.18, 0.35
    # الحالات لكل m (أبعد بيت وصلناه): (i,m) حيث i=m أو آخر 3 أبيات أو أبيات المستهل
    st, sid = [], {}
    for m in range(N):
        ids = sorted(set([m] + [i for i in range(max(0, m - 3), m)] + [i for i in range(min(R, m))]))
        for i in ids:
            sid[(i, m)] = len(st); st.append((i, m))
    S = len(st); NEG = -1e9
    D = [[NEG] * (T + 1) for _ in range(S)]
    BP = [[None] * (T + 1) for _ in range(S)]
    bestAny = [[NEG] * (T + 1) for _ in range(N)]; bestAnyS = [[-1] * (T + 1) for _ in range(N)]
    by_m = [[] for _ in range(N)]
    for s, (i, m) in enumerate(st): by_m[m].append(s)
    for t in range(T + 1):
        for m in range(N):
            for s in by_m[m]:
                i = st[s][0]; best = NEG; bp = None
                if t > 0 and D[s][t - 1] > NEG:  # تخطّي كلمة مسموعة
                    best = D[s][t - 1] - SKIP; bp = (s, t - 1, -1)
                if i == m:
                    for n in [0] + lens[i]:
                        a = t - n
                        if a < 0: break
                        if m == 0: prev, ps = -0.05 * a, -2
                        else: prev, ps = bestAny[m - 1][a], bestAnyS[m - 1][a]
                        if prev <= NEG: continue
                        v = prev + sc(i, a, n)
                        if v > best: best = v; bp = (ps, a, n)
                        if n > 0 and bestAny[m][a] > NEG:  # تكرار نفس البيت
                            v = bestAny[m][a] - JP + sc(i, a, n)
                            if v > best: best = v; bp = (bestAnyS[m][a], a, n)
                else:
                    seq = sid.get((i - 1, m))
                    for n in lens[i]:
                        a = t - n
                        if a < 0: break
                        x = sc(i, a, n)
                        if bestAny[m][a] > NEG:
                            v = bestAny[m][a] - JP + x
                            if v > best: best = v; bp = (bestAnyS[m][a], a, n)
                        if seq is not None and i - 1 != m and D[seq][a] > NEG:
                            v = D[seq][a] + x
                            if v > best: best = v; bp = (seq, a, n)
                D[s][t] = best; BP[s][t] = bp
                if best > bestAny[m][t]: bestAny[m][t] = best; bestAnyS[m][t] = s
    s, t = bestAnyS[N - 1][T], T
    out = []
    while s is not None and s >= 0:
        ps, a, n = BP[s][t]
        if n >= 0:
            i = st[s][0]
            out.append((i, W[a][1] if n > 0 else None, sim(i, a, n)))
        s, t = ps, a
        if ps == -2: break
    out.reverse()
    return out

def fix_times(seq, dur):
    ts = [t for _, t, _ in seq]
    n = len(ts)
    for k in range(n):  # لا رجوع بالوقت
        if ts[k] is not None and k and any(x is not None and x >= ts[k] for x in ts[:k]):
            ts[k] = None
    known = [k for k in range(n) if ts[k] is not None]
    if not known: return [round(dur * (k + 1) / (n + 2), 2) for k in range(n)]
    for k in range(n):
        if ts[k] is None:
            p = max([q for q in known if q < k], default=None); nx = min([q for q in known if q > k], default=None)
            a = ts[p] if p is not None else 0.0; b = ts[nx] if nx is not None else min(dur, a + 4.0 * (n - (p or 0)))
            pi = p if p is not None else -1; ni = nx if nx is not None else n
            ts[k] = a + (b - a) * (k - pi) / (ni - pi)
    return [round(max(0.0, x), 2) for x in ts]

def main():
    db = firestore.Client(project='minbar-8f037')
    albums = {d.id: d.to_dict() for d in db.collection('albums').stream()}
    tracks = [dict(d.to_dict(), id=d.id) for d in db.collection('tracks').stream()]
    if ONLY and not ALBUM: todo = tracks
    elif ALBUM:
        ids = [k for k, a in albums.items() if ALBUM in (a.get('name') or '')]
        todo = [t for t in tracks if t.get('album') in ids]
        print('الإصدار:', [albums[i].get('name') for i in ids], '— قصائد:', len(todo))
    else:
        todo = [t for t in tracks if t.get('lyrQ')]
        print('قصائد بانتظار الضبط:', len(todo))
    todo.sort(key=lambda t: t.get('at') or 0)
    if os.environ.get('RESTORE') == 'true':  # إرجاع التوقيت اليدوي السابق (قبل الضبط التلقائي)
        for t in (todo if SHARD == 0 else []):
            if ONLY and ONLY not in (t.get('title') or ''): continue
            ap = db.collection('lyrApproved').document(t['id']).get()
            pv = ap.exists and ap.to_dict().get('prev')
            if pv:
                db.collection('lyrApproved').document(t['id']).set({'json': pv, 'by': 'restore', 'low': [], 'at': firestore.SERVER_TIMESTAMP}, merge=True)
                print('↩ أُرجع التوقيت اليدوي:', t.get('title'))
            elif isinstance(t.get('lyrics'), list) and len(t['lyrics']) > 3:
                L = t['lyrics']; print('نسخة القصيدة الأصلية:', t.get('title'), 'lyrEst=', t.get('lyrEst'), [(x.get('t'), (x.get('l') or '')[:20]) for x in L[:6]])
                db.collection('lyrApproved').document(t['id']).set({'json': json.dumps([{'t': x.get('t'), 'l': x.get('l')} for x in L], ensure_ascii=False), 'by': 'restore', 'low': [], 'at': firestore.SERVER_TIMESTAMP}, merge=True)
                print('↩ أُرجعت من نسخة القصيدة الأصلية')
            else: print('لا توجد نسخة سابقة:', t.get('title'))
        return
    if ONLY: todo = [t for t in todo if ONLY in (t.get('title') or '')]
    todo = [t for t in todo if t.get('audio') and (t.get('lyrRaw') or t.get('lyrics'))][:LIMIT][SHARD::SHARDS]
    done = 0
    for t in todo[:LIMIT]:
        tid = t['id']; t0 = time.time()
        ap = db.collection('lyrApproved').document(tid).get()
        prev = None
        raw = t.get('lyrRaw')
        if raw: blocks = [[l.strip() for l in b.split('\n') if l.strip()] for b in re.split(r'\n\s*\n', raw)]
        else:
            if ap.exists:
                try: prev = json.loads(ap.to_dict().get('json') or '[]')
                except Exception: prev = None
            src = prev or t.get('lyrics') or []
            if isinstance(src, str):
                try: src = json.loads(src)
                except Exception: src = []
            blocks = [[(x.get('l') or '').strip() for x in src]]
        blocks = [[l for l in b if l and not SEP.match(l)] for b in blocks]; blocks = [b for b in blocks if b]
        lines = [l for b in blocks for l in b]
        print(f"\n=== {t.get('title')} ({tid}) — {len(lines)} بيت، مقاطع: {len(blocks)}", flush=True)
        if len(lines) < 2 or not t.get('audio'): print('  تخطّي: لا كلمات أو لا صوت'); continue
        R = len(blocks[0]) if len(blocks) > 1 else min(4, len(lines) // 3)
        url = t['audio'] if t['audio'].startswith('http') else BASE + urllib.parse.quote(t['audio'])
        with tempfile.TemporaryDirectory() as td:
            src_f = os.path.join(td, 'a.bin'); wav = os.path.join(td, 'a.wav')
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 minbar-align'})
            with urllib.request.urlopen(req, timeout=180) as r, open(src_f, 'wb') as f: f.write(r.read())
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', src_f, '-ac', '1', '-ar', '16000', wav], check=True)
            if VOCALS:  # فصل صوت الرادود عن اللطم والمؤثرات قبل السماع (أكبر سبب لضعف الدقة)
                tv = time.time()
                r = subprocess.run([sys.executable, '-m', 'demucs', '--two-stems=vocals', '-n', 'htdemucs', '-j', str(os.cpu_count() or 2), '-o', td, src_f], capture_output=True, text=True)
                vf = os.path.join(td, 'htdemucs', 'a', 'vocals.wav')
                if os.path.exists(vf):
                    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', vf, '-ac', '1', '-ar', '16000', '-af', 'highpass=f=120,lowpass=f=7000,dynaudnorm', wav], check=True)
                    print(f'  فُصل الصوت ({time.time() - tv:.0f}ث)', flush=True)
                else: print('  تعذّر الفصل:', r.stderr[-300:])
            dur = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', wav], capture_output=True, text=True).stdout.strip() or 0)
            hot = ' '.join(dict.fromkeys(' '.join(lines).split()))[:900]
            W = transcribe(wav, hot)
            import shutil; keep = os.path.join(tempfile.gettempdir(), tid + '.wav'); shutil.copy(wav, keep)
        print(f'  مدة {dur:.0f}ث — كلمات مسموعة {len(W)} — زمن السماع {time.time() - t0:.0f}ث', flush=True)
        if len(W) < 5: print('  تخطّي: ما انسمع كلام'); continue
        nl = [norm(l) or 'ا' for l in lines]
        seq = align(nl, W, R)
        ts = fix_times(seq, dur); ts_w = list(ts); fa = None
        if os.environ.get('FA', 'true') == 'true':
            try:
                tf = time.time(); fa = forced_align(keep, [lines[i] for i, _, _ in seq])
                if fa:
                    ts = [round(a, 2) for a, _, _ in fa]
                    for k in range(1, len(ts)): ts[k] = max(ts[k], ts[k - 1])
                    print(f'  محاذاة إجبارية ({time.time() - tf:.0f}ث)')
            except Exception as e: print('  فشلت المحاذاة الإجبارية:', repr(e)[:300])
        try: os.remove(keep)
        except Exception: pass
        arr = [{'t': ts[k], 'l': lines[i]} for k, (i, _, _) in enumerate(seq)]
        low = [k for k, (_, tt, c) in enumerate(seq) if tt is None or c < 0.45]
        conf = sum(c for _, _, c in seq) / max(1, len(seq))
        print(f'  النتيجة: {len(arr)} سطر (منها {len(arr) - len(lines)} تكرار مكتشف) — متوسط الثقة {conf:.2f} — يحتاج مراجعة {len(low)} — زمن كلي {time.time() - t0:.0f}ث')
        if prev and len(prev) > 3 and not t.get('lyrEst'):
            # مقارنة مع التوقيت السابق (اليدوي) إذا نفس الأسطر
            pm = {}
            for x in prev: pm.setdefault(norm(x.get('l') or ''), []).append(float(x.get('t') or 0))
            ds = []
            for x in arr:
                c = pm.get(norm(x['l']))
                if c: ds.append(min(abs(x['t'] - v) for v in c))
            if ds:
                ds.sort(); print(f'  مقارنة بالسابق: وسيط الفرق {ds[len(ds) // 2]:.1f}ث — ضمن ثانية {sum(d <= 1 for d in ds) * 100 // len(ds)}% — ضمن 3ث {sum(d <= 3 for d in ds) * 100 // len(ds)}%')
        for k, x in enumerate(arr[:400]):
            print(f"   {x['t']:7.2f} (سماع {ts_w[k]:7.2f}{f' ثقة {fa[k][2]:.2f}' if fa else ''}) {'⚠' if k in low else ' '} {x['l']}")
        if WRITE:
            doc = {'json': json.dumps(arr, ensure_ascii=False), 'title': t.get('title') or '', 'by': 'auto', 'at': firestore.SERVER_TIMESTAMP, 'low': low}
            if ap.exists and ap.to_dict().get('json') and ap.to_dict().get('by') != 'auto': doc['prev'] = ap.to_dict().get('json')
            db.collection('lyrApproved').document(tid).set(doc, merge=True)
            db.collection('tracks').document(tid).set({'lyrEst': False, 'lyrQ': firestore.DELETE_FIELD, 'upd': int(time.time() * 1000)}, merge=True)
            print('  ✓ حُفظت')
        done += 1
    print('\nتم:', done)

if __name__ == '__main__':
    main()
