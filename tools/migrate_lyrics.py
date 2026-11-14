# ترحيل لمرة واحدة: مكان واحد للكلمات (lyrApproved) وتنظيف بقايا الضبط التلقائي
import json, os
from google.cloud import firestore
db = firestore.Client(project='minbar-8f037')
APPLY = os.environ.get('APPLY') == 'true'
tracks = {d.id: d.to_dict() for d in db.collection('tracks').stream()}
appr = {d.id: d.to_dict() for d in db.collection('lyrApproved').stream()}
edits = [d for d in db.collection('lyrEdits').stream()]
def ser(o):
    return json.loads(json.dumps(o, default=str, ensure_ascii=False))
json.dump({'tracks': {k: {f: v.get(f) for f in ('title', 'lyrics', 'lyrRaw', 'lyrQ', 'lyrEst') if f in v} for k, v in tracks.items()}, 'lyrApproved': ser(appr), 'lyrEdits': ser({d.id: d.to_dict() for d in edits})}, open('backup.json', 'w'), ensure_ascii=False)
made = cleanedT = cleanedA = orphan = 0
for tid, t in tracks.items():
    a = appr.get(tid); has = False
    try: has = bool(a and len(json.loads(a.get('json') or '[]')) > 0)
    except Exception: has = False
    L = t.get('lyrics')
    if isinstance(L, str):
        try: L = json.loads(L)
        except Exception: L = []
    if not has and isinstance(L, list) and len(L) > 0:
        made += 1; print('＋ نسخ إلى lyrApproved:', t.get('title'), len(L))
        if APPLY: db.collection('lyrApproved').document(tid).set({'json': json.dumps([{'t': x.get('t') or 0, 'l': x.get('l') or ''} for x in L if isinstance(x, dict)], ensure_ascii=False), 'title': t.get('title') or '', 'at': firestore.SERVER_TIMESTAMP})
    junk = [f for f in ('lyrRaw', 'lyrQ', 'lyrEst') if f in t]
    if junk:
        cleanedT += 1
        if APPLY: db.collection('tracks').document(tid).update({f: firestore.DELETE_FIELD for f in junk})
for aid, a in appr.items():
    if aid not in tracks: orphan += 1; print('؟ كلمات بلا قصيدة:', aid, a.get('title'))
    junk = [f for f in ('prev', 'low') if f in a]
    if junk:
        cleanedA += 1
        if APPLY: db.collection('lyrApproved').document(aid).update({f: firestore.DELETE_FIELD for f in junk})
if APPLY:
    for d in edits: d.reference.delete()
print(f'قصائد {len(tracks)} — كلمات معتمدة {len(appr)} — نُسخت {made} — نُظّفت قصائد {cleanedT} — نُظّفت كلمات {cleanedA} — تصويتات محذوفة {len(edits)} — يتيمة {orphan} — تطبيق={APPLY}')
