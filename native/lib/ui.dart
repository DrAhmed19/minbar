import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state.dart';

const kGold = Color(0xFFE8C468);
const kGold2 = Color(0xFFF6DE8E);
const kGreen = Color(0xFF0C4A39);
const kDeep = Color(0xFF072A20);
const kCream = Color(0xFFF6F1E6);
const kInk = Color(0xFF13201A);
const kMuted = Color(0xFF5A6F64);

TextStyle tx(double size, {FontWeight w = FontWeight.w600, Color c = kInk, double? h}) =>
    TextStyle(fontFamily: 'Cairo', fontFamilyFallback: const ['CairoLatin'], fontSize: size, fontWeight: FontWeight.w700, color: c, height: h);

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
      canvas.drawPath(m.extractPath(0, m.length * draw.clamp(0.0, 1.0)), sp);
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
      child: PIcon(Ic.eq, color: kGold, size: size * 0.4),
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
        errorWidget: (_, __, ___) {
          final f = app.repo.coverFile(url);
          return f == null ? ph : Image.file(File(f), width: size, height: size, fit: BoxFit.cover);
        },
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? icon;
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
              if (icon != null) ...[PIcon(icon!, color: outline ? kGold : const Color(0xFF3A2D08), size: 20), const SizedBox(width: 8)],
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
  final String icon;
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
              PIcon(icon, color: kGold, size: 20),
              const SizedBox(width: 6),
              Text(label, style: tx(13.5, w: FontWeight.w800, c: Colors.white)),
            ]),
          ),
        ),
      );
}

/// أيقونات الويب نفسها (مسارات SVG من player.js) — تُحمَّل مرة واحدة عند الإقلاع
class Ic {
  static const play = 'play', pause = 'pause', prev = 'prev', next = 'next', heart = 'heart', heartF = 'heartF', lib = 'lib', pulse = 'pulse', plist = 'plist',
      search = 'search', x = 'x', users = 'users', back = 'back', plus = 'plus', reset = 'reset', down = 'down', power = 'power', check = 'check', dl = 'dl',
      chat = 'chat', info = 'info', flame = 'flame', spark = 'spark', color = 'color', lay = 'lay', speed = 'speed', wave = 'wave',
      queue = 'queue', share = 'share', eq = 'eq', more = 'more', text = 'text', moon = 'moon', rw = 'rw', fw = 'fw', rep = 'rep', shuf = 'shuf', timer = 'timer';
}

Map<String, String> _icons = {};
Future<void> loadIcons() async {
  try {
    final m = jsonDecode(await rootBundle.loadString('assets/icons.json')) as Map;
    _icons = m.map((k, v) => MapEntry('$k', '$v'));
    _icons['dl'] = '<path d="M12 4v11M7.5 10.5L12 15l4.5-4.5"/><path d="M5 19h14"/>';
  } catch (_) {}
}

class PIcon extends StatelessWidget {
  final String n;
  final Color? color;
  final double? size;
  const PIcon(this.n, {super.key, this.color, this.size});
  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? kInk;
    final sz = size ?? IconTheme.of(context).size ?? 24;
    final filled = n.endsWith('F');
    final body = _icons[filled ? n.substring(0, n.length - 1) : n] ?? '';
    final hex = '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${filled ? hex : 'none'}" stroke="$hex" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${body.replaceAll('currentColor', hex)}</svg>';
    return SizedBox(width: sz, height: sz, child: Opacity(opacity: c.alpha / 255, child: SvgPicture.string(svg)));
  }
}


/// ورقة سفلية تُغلق بالسحب للأسفل حتى لو كان محتواها قابلاً للتمرير
Future<T?> showMSheet<T>({required BuildContext context, required WidgetBuilder builder, bool isScrollControlled = false, Color? backgroundColor, ShapeBorder? shape}) =>
    showModalBottomSheet<T>(context: context, isScrollControlled: isScrollControlled, backgroundColor: backgroundColor, shape: shape, builder: (c) => SheetPull(child: builder(c)));

class SheetPull extends StatefulWidget {
  final Widget child;
  const SheetPull({super.key, required this.child});
  @override
  State<SheetPull> createState() => _SheetPullState();
}

class _SheetPullState extends State<SheetPull> {
  double pull = 0;
  bool done = false;
  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (done) return false;
          if (n is OverscrollNotification && n.overscroll < 0 && n.dragDetails != null && n.metrics.axis == Axis.vertical) {
            setState(() => pull += -n.overscroll);
            if (pull > 110) {
              done = true;
              Navigator.of(context).maybePop();
            }
          } else if (n is ScrollUpdateNotification && pull > 0 && (n.scrollDelta ?? 0) > 0) {
            setState(() => pull = 0);
          } else if (n is ScrollEndNotification && pull > 0) {
            setState(() => pull = 0);
          }
          return false;
        },
        child: Transform.translate(offset: Offset(0, pull * 0.7), child: widget.child),
      );
}
