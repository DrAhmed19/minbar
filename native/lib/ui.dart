import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kGold = Color(0xFFE8C468);
const kGold2 = Color(0xFFF6DE8E);
const kGreen = Color(0xFF0C4A39);
const kDeep = Color(0xFF072A20);
const kCream = Color(0xFFF6F1E6);
const kInk = Color(0xFF13201A);
const kMuted = Color(0xFF5A6F64);

TextStyle tx(double size, {FontWeight w = FontWeight.w600, Color c = kInk, double? h}) =>
    GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: h);

/// شعار منبر: قوس ذهبي وأعمدة صوت (نفس شعار الويب)
class LogoPainter extends CustomPainter {
  final double t; // 0..1 حركة الأعمدة
  final double draw; // 0..1 رسم القوس
  LogoPainter(this.t, {this.draw = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    canvas.save();
    canvas.scale(s, s);
    final shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF6DF8F), Color(0xFFC8963A)])
        .createShader(const Rect.fromLTWH(0, 0, 120, 130));
    final arch = Path()
      ..moveTo(14, 118)
      ..lineTo(14, 58)
      ..quadraticBezierTo(14, 22, 60, 6)
      ..quadraticBezierTo(106, 22, 106, 58)
      ..lineTo(106, 118);
    final sp = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in arch.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * draw.clamp(0, 1)), sp);
    }
    final fp = Paint()..shader = shader;
    const xs = [32.0, 45.0, 56.0, 67.0, 80.0];
    const hs = [56.0, 74.0, 88.0, 70.0, 52.0];
    for (var i = 0; i < 5; i++) {
      final k = 0.25 + 0.75 * (0.5 + 0.5 * _wave(t * 6.283 + i * 1.1));
      final h = hs[i] * k;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(xs[i], 118 - h, 9, h), const Radius.circular(4.5)), fp);
    }
    canvas.restore();
  }

  double _wave(double x) => math.sin(x);

  @override
  bool shouldRepaint(covariant LogoPainter o) => o.t != t || o.draw != draw;
}

class Cover extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  const Cover(this.url, {super.key, this.size = 56, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(colors: [kGreen, kDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(Icons.graphic_eq, color: kGold, size: size * 0.4),
    );
    if (url.isEmpty) return ph;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ph,
        errorWidget: (_, __, ___) => ph,
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outline;
  const GoldButton(this.label, this.onTap, {super.key, this.icon, this.outline = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: outline ? null : const LinearGradient(colors: [kGold2, kGold, Color(0xFFD9A93E)]),
          border: outline ? Border.all(color: const Color(0x33FFFFFF)) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, color: outline ? kGold : const Color(0xFF3A2D08), size: 20), const SizedBox(width: 8)],
              Text(label, style: tx(15.5, w: FontWeight.w800, c: outline ? const Color(0xFFF3F6F4) : const Color(0xFF3A2D08))),
            ]),
          ),
        ),
      ),
    );
  }
}

class GoldPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const GoldPill(this.label, this.icon, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => Material(
        color: kGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: kGold, size: 20),
              const SizedBox(width: 6),
              Text(label, style: tx(13.5, w: FontWeight.w800, c: Colors.white)),
            ]),
          ),
        ),
      );
}
