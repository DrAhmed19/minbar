import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minbar_native/car.dart';

void main() {
  testWidgets('render ad scene', (tester) async {
    await tester.runAsync(() async {
      final fl = FontLoader('Cairo')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Cairo.ttf').readAsBytesSync())));
      await fl.load();
      await AdScene.init();
      final frames = jsonDecode(File('ci/ad_timeline.json').readAsStringSync()) as List;
      final lim = int.tryParse(Platform.environment['AD_FRAMES'] ?? '') ?? frames.length;
      const pw = 1080, ph = 1920;
      final out = Platform.environment['AD_OUT'] ?? '/tmp/scene.mp4';
      final ff = await Process.start('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${pw}x$ph', '-r', '30', '-i', '-', '-c:v', 'libx264', '-crf', '15', '-preset', 'veryfast', '-pix_fmt', 'yuv420p', out]);
      ff.stderr.listen((e) => stderr.add(e));
      final sw = Stopwatch()..start();
      for (int i = 0; i < lim; i++) {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        c.scale(pw / 405.0);
        AdScene.paint(c, const Size(405, 720), (frames[i] as Map).cast<String, dynamic>());
        final img = await rec.endRecording().toImage(pw, ph);
        final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        ff.stdin.add(bd!.buffer.asUint8List());
        if (i % 50 == 0) {
          stdout.writeln('frame $i ${sw.elapsed.inSeconds}s');
          if (i == 0 || i == 200 || i == 650) {
            final pngd = await img.toByteData(format: ui.ImageByteFormat.png);
            File('/tmp/f$i.png').writeAsBytesSync(pngd!.buffer.asUint8List());
          }
        }
        img.dispose();
      }
      await ff.stdin.close();
      await ff.exitCode;
      stdout.writeln('done ${sw.elapsed.inSeconds}s');
    });
  }, timeout: const Timeout(Duration(hours: 3)));
}
