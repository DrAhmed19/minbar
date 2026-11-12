// فلتر التعليقات — منقول حرفياً من cmfilter.js في الويب حتى يكون الحكم نفسه في المنصتين.
// النتيجة: (st: 'ok' | 'review' | 'block', hit)
import 'package:cloud_firestore/cloud_firestore.dart';

class CmFilter {
  static const _map = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ة': 'ه', 'گ': 'ك', 'ڪ': 'ك', 'ک': 'ك', 'ی': 'ي', 'چ': 'ج', 'ڤ': 'ف', 'پ': 'ب', 'ژ': 'ز'};
  static final _lat = <List<Object>>[
    ['kh', 'خ'], ['sh', 'ش'], ['th', 'ث'], ['ch', 'ج'], ['gh', 'غ'], ['3', 'ع'], ['7', 'ح'], ['5', 'خ'], ['2', 'ا'], ['9', 'ق'], ['6', 'ط'], ['8', 'غ'],
    ['k', 'ك'], ['s', 'س'], ['z', 'ز'], ['n', 'ن'], ['y', 'ي'], ['i', 'ي'], ['e', 'ي'], ['a', 'ا'], ['o', 'و'], ['u', 'و'], ['w', 'و'], ['r', 'ر'], ['b', 'ب'],
    ['m', 'م'], ['t', 'ت'], ['d', 'د'], ['q', 'ق'], ['f', 'ف'], ['l', 'ل'], ['h', 'ه'], ['j', 'ج'], ['g', 'ك'], ['p', 'ب'], ['v', 'ف'], ['c', 'ك'],
  ];
  static final _diac = RegExp('[ً-ٰٟۖ-ۭـ]');
  static final _rep = RegExp(r'(.)\1+');
  static final _nonAr = RegExp('[^ء-ي]+');
  static final _ar = RegExp('[ء-ي]');

  static String norm(String s) {
    s = s.toLowerCase().replaceAll(_diac, '');
    final b = StringBuffer();
    for (final ch in s.runes.map(String.fromCharCode)) {
      b.write(_map[ch] ?? ch);
    }
    var o = b.toString();
    if (RegExp(r'[a-z0-9]').hasMatch(o)) {
      for (final p in _lat) {
        o = o.replaceAll(p[0] as String, p[1] as String);
      }
    }
    return o;
  }

  static String _fold(String w) => w.replaceAllMapped(_rep, (m) => m[1]!);

  static List<String> tokens(String s) {
    final raw = norm(s).split(_nonAr).where((w) => w.isNotEmpty);
    final out = <String>[];
    var run = '';
    for (final w in raw) {
      if (w.length <= 1) {
        run += w;
        continue;
      }
      if (run.isNotEmpty) {
        out.add(run);
        run = '';
      }
      out.add(w);
    }
    if (run.isNotEmpty) out.add(run);
    return out.map(_fold).toList();
  }

  static final _bw = [
    r'^(و|يا|ف)?كس(م|ام|امك|مك|ك|ه|ها|هم|كم|خت|ختك|ختكم|امكم|اختك|اخت|ين)?$', r'^(و|يا)?كسخت(ك|كم|ه)?$', r'^(و|يا)?كسم(ك|كم)?$',
    r'^(و|يا)?اير(ي|ك|ه|كم|هم|نا)?$', r'^(و|يا)?عير(ي|ك|ه|كم)?$', r'^(و|يا)?زب(ي|ك|ه|كم|ر)?$', r'^(و|يا)?طيز(ك|ه|كم|ي)?$',
    r'^(ا|ن|ي|ت)?ني(ك|ج|ش|چ)(ك|ه|كم|ها|م|و)?$', r'^(ا|ن|ي|ت)?نيج(ك|ه|كم|ها)?$', r'^(ا|ن|ي)?نيش(ك|ه|كم|ها)?$', r'^(ا|و)?نيكو?$',
    r'^(و|يا)?(منيوك|منيوج|منيوش|منيكه|منيوكه|منيوكين)$', r'^(و|يا)?(قحب|قحبه|كحبه|قحاب|كحاب)$', r'^(و|يا)?(شرموط|شرموطه|شراميط)$',
    r'^(و|يا)?(عاهر|عاهره|عواهر)$', r'^(و|يا)?(ديوث|كواد|قواد|كوادين|قوادين)$', r'^(و|يا)?(لوطي|مخنث|مفعول)$', r'^(و|يا)?(نغل|نغول|فرخ|فروخ|زنيم)$',
    r'^(و|يا)?(خنيث|خنيثه)$',
  ].map(RegExp.new).toList();
  static const _bs = ['كسامك', 'كساختك', 'كسختك', 'كسمك', 'منيوك', 'شرموط', 'قحبه', 'انيجك', 'انيكك', 'انيشك', 'انيكم', 'انيجكم', 'ايريب', 'ايرك', 'ديوث', 'عاهره', 'كوادين', 'ابنالقحبه', 'ابنالكلب', 'يلعنابوك', 'ابوكالكلب', 'نيجامك', 'نيكامك', 'نيشامك'];
  static final _rw = [
    r'^(و|يا)?(كلب|كلاب|جلب|جلاب|حمار|حمير|زمال|حيوان|حيوانات|بهيمه|غبي|اغبياء|تافه|تافهين|زباله|خرا|خره|منحط|واطي|سافل|سافله|حقير|وسخ|وسخين|جحش|ثور)$',
    r'^(و|يا)?(اخرس|انجب|انقلع|طز|عيب)$',
  ].map(RegExp.new).toList();
  static const _sk = {'ش': 'س', 'ص': 'س', 'ث': 'س', 'ق': 'ك', 'ج': 'ك', 'ظ': 'ز', 'ض': 'ز', 'ذ': 'ز', 'ط': 'ت'};
  static String _skel(String w) => _fold(w.split('').map((c) => _sk[c] ?? c).join());
  static final _bsk = _bs.map(_skel).toList();
  static const _vow = ['كسمك', 'كسختك', 'كسمكم'];

  static List<String> _xb = [], _xr = [], _xa = [];
  static bool _loaded = false;

  /// كلمات المشرف الإضافية (cmfilter/main) — نفس وثيقة الويب
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final d = await FirebaseFirestore.instance.doc('cmfilter/main').get();
      final m = d.data() ?? {};
      List<String> l(String k) => ((m[k] as List?) ?? []).map((e) => '$e').toList();
      _xb = l('block');
      _xr = l('review');
      _xa = l('allow');
      _loaded = true;
    } catch (_) {}
  }

  static ({String st, String hit}) check(String s) {
    final tk = tokens(s);
    if (tk.isEmpty) return (st: 'ok', hit: '');
    final allow = _xa.map((w) => tokens(w).join()).toSet();
    final comp = tk.join(), compAll = _fold(norm(s).replaceAll(_nonAr, ''));
    for (final w in tk) {
      if (allow.contains(w)) continue;
      for (final r in _bw) {
        if (r.hasMatch(w)) return (st: 'block', hit: w);
      }
    }
    for (final p in _bs) {
      if (comp.contains(p) || compAll.contains(p)) return (st: 'block', hit: p);
    }
    final sc = _skel(comp), sa = _skel(compAll), sv = sa.replaceAll(RegExp('[اوي]'), '');
    for (var i = 0; i < _bsk.length; i++) {
      if (sc.contains(_bsk[i]) || sa.contains(_bsk[i])) return (st: 'block', hit: _bs[i]);
    }
    for (final p in _vow) {
      if (sv.contains(p)) return (st: 'block', hit: p);
    }
    for (final w in tk) {
      if (w.length < 3 || allow.contains(w)) continue;
      final k = _skel(w);
      if (k != w) {
        for (final r in _bw) {
          if (r.hasMatch(k)) return (st: 'block', hit: w);
        }
      }
    }
    bool extra(List<String> l, String st) {
      for (final e in l) {
        final p = tokens(e).join();
        if (p.isNotEmpty && (tk.contains(p) || (p.length >= 4 && compAll.contains(p)))) return true;
      }
      return false;
    }

    if (extra(_xb, 'block')) return (st: 'block', hit: '');
    for (final w in tk) {
      if (allow.contains(w)) continue;
      for (final r in _rw) {
        if (r.hasMatch(w)) return (st: 'review', hit: w);
      }
    }
    if (extra(_xr, 'review')) return (st: 'review', hit: '');
    if (RegExp(r'(https?:|www\.|\.com|\.net|t\.me|@\w)', caseSensitive: false).hasMatch(s)) return (st: 'block', hit: 'رابط');
    if (RegExp(r'(.)\1{7,}').hasMatch(s)) return (st: 'review', hit: 'تكرار');
    if (!_ar.hasMatch(norm(s)) && !RegExp(r'^[\p{Emoji}\s]+$', unicode: true).hasMatch(s)) return (st: 'review', hit: 'غير عربي');
    return (st: 'ok', hit: '');
  }
}
