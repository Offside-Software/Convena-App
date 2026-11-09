import 'dart:math' as math;

import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vector-rendered Convena "C" + dot Brand Logo matching Web's `BrandLogo.tsx`.
class ConvenaBrandMark extends StatelessWidget {
  final double size;

  const ConvenaBrandMark({super.key, this.size = 36.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ConvenaBrandMarkPainter()),
    );
  }
}

class _ConvenaBrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 36.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 17.0 * scale;

    // 1. Dark circular background (#151515)
    final bgPaint = Paint()
      ..color = const Color(0xFF151515)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Border (#3D3D3D)
    final borderPaint = Paint()
      ..color = const Color(0xFF3D3D3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Geometric Extra-Bold "C" in #CFFE06
    final cPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7 * scale
      ..strokeCap = StrokeCap.butt;
    final cRect = Rect.fromCircle(
      center: Offset(18.2 * scale, 18.0 * scale),
      radius: 5.05 * scale,
    );
    const startAngle = 42.0 * (math.pi / 180.0);
    const sweepAngle = 276.0 * (math.pi / 180.0);
    canvas.drawArc(cRect, startAngle, sweepAngle, false, cPaint);

    // 4. Bottom-right accent dot in #CFFE06
    final dotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(28.5 * scale, 28.5 * scale),
      3.0 * scale,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConvenaBrandLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;

  const ConvenaBrandLogo({
    super.key,
    this.markSize = 34.0,
    this.fontSize = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConvenaBrandMark(size: markSize),
        const SizedBox(width: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Convena',
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
