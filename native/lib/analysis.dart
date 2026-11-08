import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'data.dart';

/// التحليل المحسوب مسبقاً لكل قصيدة (نفس ملفات الويب: media/u/n/<id>-v1.bin)
/// 22 نطاقاً ترددياً (dB) + مدخلات الأعمدة لكل إطار، بدون أي معالجة صوت لحظية
class Analysis {
  final Uint8List d;
  final int fps, nf, w;
  Analysis(this.d, this.fps, this.nf, this.w);

  static Future<Analysis?> load(String id) async {
    final c = HttpClient();
    try {
      final r = await (await c.getUrl(Uri.parse(absUrl('media/u/n/$id-v1.bin')))).close();
      if (r.statusCode != 200) return null;
      final b = BytesBuilder();
      await for (final ch in r) {
        b.add(ch);
      }
      final d = b.takeBytes();
      if (d.length < 12 || d[0] != 77 || d[1] != 66 || d[2] != 65) return null;
      final nf = ByteData.sublistView(d).getUint32(8, Endian.little);
      final w = d[5] + d[6];
      if (nf < 2 || w < 22) return null;
      return Analysis(d, d[4], nf, w);
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  /// غلاف الموجة (للشريط النقطي) بعدد خانات B، مطبّع 0..1
  List<double> envelope(int B) {
    final e = List<double>.filled(B, 0);
    var mx = 0.0;
    for (var i = 0; i < B; i++) {
      final f0 = (i * nf / B).floor(), f1 = ((i + 1) * nf / B).floor().clamp(f0 + 1, nf);
      var s = 0.0;
      var c = 0;
      for (var f = f0; f < f1 && f < nf; f++) {
        final o = 12 + f * w;
        for (var k = 2; k < 20; k += 3) {
          final db = d[o + k] / 1.5 - 140;
          s += math.pow(10, db / 20).toDouble();
          c++;
        }
      }
      e[i] = c == 0 ? 0 : s / c;
      if (e[i] > mx) mx = e[i];
    }
    if (mx > 0) {
      for (var i = 0; i < B; i++) {
        e[i] = math.pow(e[i] / mx, 0.6).toDouble();
      }
    }
    return e;
  }

  /// قوة الإيقاع (باص + قفزة طاقة) 0..1 عند ثانية معيّنة — لوضع اللطم والنبض
  double beatAt(double sec) {
    final i = ((sec < 0 ? 0 : sec) * fps).floor().clamp(0, nf - 1);
    final o = 12 + i * w;
    final low = d[o + 28] / 12.0, mid = d[o + 29] / 12.0;
    return ((low * 0.7 + mid * 0.3) / 6).clamp(0.0, 1.0);
  }

  /// قيم النطاقات الـ22 مطبّعة 0..1 عند ثانية معيّنة (مع استيفاء بين الإطارين)
  void bandsAt(double sec, List<double> out) {
    var x = (sec < 0 ? 0 : sec) * fps;
    var i = x.floor();
    if (i >= nf - 1) {
      i = nf - 1;
      x = i.toDouble();
    }
    final f = x - i;
    final i1 = i + 1 < nf ? i + 1 : i;
    final a = 12 + i * w, b = 12 + i1 * w;
    for (var k = 0; k < 22; k++) {
      final q = d[a + k] + (d[b + k] - d[a + k]) * f;
      final db = q / 1.5 - 140;
      out[k] = ((db + 92) / 52).clamp(0.0, 1.0);
    }
  }
}
