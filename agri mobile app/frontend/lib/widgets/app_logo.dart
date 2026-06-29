// lib/widgets/app_logo.dart
//
// Custom SVG-style logo matching the CropAI brand:
// Blue gear ring · Green leaves · Purple hand · Yellow sun
// Drop-in replacement for the old Icon(Icons.eco_rounded) circle.

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // ── 1. Outer gear (blue) ──────────────────────────────────────────────
    final gearPaint = Paint()
      ..color = const Color(0xFF29ABE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18;

    // Gear base circle
    canvas.drawCircle(Offset(cx, cy), r * 0.82, gearPaint);

    // Gear teeth — 12 teeth
    final toothPaint = Paint()
      ..color = const Color(0xFF29ABE2)
      ..style = PaintingStyle.fill;

    const teeth = 12;
    for (int i = 0; i < teeth; i++) {
      final angle = (i * 2 * 3.14159265) / teeth;
      final tx = cx + (r * 0.97) * (angle == 0 ? 1 : _cos(angle));
      final ty = cy + (r * 0.97) * _sin(angle);
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(angle);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: r * 0.14,
          height: r * 0.22,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(rrect, toothPaint);
      canvas.restore();
    }

    // ── 2. White inner fill ───────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.72, bgPaint);

    // ── 3. Sun (yellow/orange) ────────────────────────────────────────────
    final sunPaint = Paint()
      ..color = const Color(0xFFF7941D)
      ..style = PaintingStyle.fill;
    // Sun body
    canvas.drawCircle(Offset(cx, cy - r * 0.28), r * 0.16, sunPaint);
    // Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.045
      ..strokeCap = StrokeCap.round;
    const rays = 8;
    for (int i = 0; i < rays; i++) {
      final a = (i * 2 * 3.14159265) / rays;
      final x1 = cx + (r * 0.20) * _cos(a);
      final y1 = (cy - r * 0.28) + (r * 0.20) * _sin(a);
      final x2 = cx + (r * 0.30) * _cos(a);
      final y2 = (cy - r * 0.28) + (r * 0.30) * _sin(a);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
    }

    // ── 4. Left green leaf ────────────────────────────────────────────────
    final leafPaint = Paint()
      ..color = const Color(0xFF39B54A)
      ..style = PaintingStyle.fill;

    final leftLeaf = Path();
    leftLeaf.moveTo(cx - r * 0.05, cy - r * 0.05);
    leftLeaf.cubicTo(
      cx - r * 0.40, cy - r * 0.35,
      cx - r * 0.55, cy + r * 0.05,
      cx - r * 0.10, cy + r * 0.30,
    );
    leftLeaf.cubicTo(
      cx - r * 0.10, cy + r * 0.10,
      cx - r * 0.02, cy + r * 0.05,
      cx - r * 0.05, cy - r * 0.05,
    );
    canvas.drawPath(leftLeaf, leafPaint);

    // ── 5. Right green leaf ───────────────────────────────────────────────
    final rightLeaf = Path();
    rightLeaf.moveTo(cx + r * 0.05, cy - r * 0.05);
    rightLeaf.cubicTo(
      cx + r * 0.40, cy - r * 0.35,
      cx + r * 0.55, cy + r * 0.05,
      cx + r * 0.10, cy + r * 0.30,
    );
    rightLeaf.cubicTo(
      cx + r * 0.10, cy + r * 0.10,
      cx + r * 0.02, cy + r * 0.05,
      cx + r * 0.05, cy - r * 0.05,
    );
    canvas.drawPath(rightLeaf, leafPaint);

    // ── 6. Purple hand (cupped, lifting) ─────────────────────────────────
    final handPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.fill;

    final hand = Path();
    // Palm base
    hand.moveTo(cx - r * 0.22, cy + r * 0.45);
    hand.cubicTo(
      cx - r * 0.28, cy + r * 0.20,
      cx - r * 0.18, cy + r * 0.10,
      cx,            cy + r * 0.12,
    );
    hand.cubicTo(
      cx + r * 0.18, cy + r * 0.10,
      cx + r * 0.28, cy + r * 0.20,
      cx + r * 0.22, cy + r * 0.45,
    );
    hand.close();
    canvas.drawPath(hand, handPaint);

    // Thumb left
    final thumbL = Path();
    thumbL.moveTo(cx - r * 0.22, cy + r * 0.35);
    thumbL.cubicTo(
      cx - r * 0.38, cy + r * 0.25,
      cx - r * 0.42, cy + r * 0.42,
      cx - r * 0.28, cy + r * 0.48,
    );
    thumbL.cubicTo(
      cx - r * 0.24, cy + r * 0.48,
      cx - r * 0.22, cy + r * 0.45,
      cx - r * 0.22, cy + r * 0.35,
    );
    canvas.drawPath(thumbL, handPaint);

    // Thumb right
    final thumbR = Path();
    thumbR.moveTo(cx + r * 0.22, cy + r * 0.35);
    thumbR.cubicTo(
      cx + r * 0.38, cy + r * 0.25,
      cx + r * 0.42, cy + r * 0.42,
      cx + r * 0.28, cy + r * 0.48,
    );
    thumbR.cubicTo(
      cx + r * 0.24, cy + r * 0.48,
      cx + r * 0.22, cy + r * 0.45,
      cx + r * 0.22, cy + r * 0.35,
    );
    canvas.drawPath(thumbR, handPaint);
  }

  // trig helpers (dart:math not imported to keep it simple)
  double _cos(double a) => _trigTable(a, true);
  double _sin(double a) => _trigTable(a, false);

  double _trigTable(double a, bool isCos) {
    // Simple Taylor series — accurate enough for paint
    a = a % (2 * 3.14159265);
    if (isCos) {
      return 1 -
          (a * a) / 2 +
          (a * a * a * a) / 24 -
          (a * a * a * a * a * a) / 720;
    } else {
      return a -
          (a * a * a) / 6 +
          (a * a * a * a * a) / 120 -
          (a * a * a * a * a * a * a) / 5040;
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}