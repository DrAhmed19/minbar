import 'dart:io';
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
