import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/theme/app_theme.dart';

/// Animated ILM sail logo — adapts to light/dark theme.
class IlmLogo extends StatefulWidget {
  const IlmLogo({this.size = 80, super.key});

  final double size;

  @override
  State<IlmLogo> createState() => _IlmLogoState();
}

class _IlmLogoState extends State<IlmLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeScope.of(context).colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 0.88),
          painter: _IlmLogoPainter(
            progress: _controller.value,
            primary: c.textPrimary,
            secondary: c.textSecondary,
          ),
        );
      },
    );
  }
}

class _IlmLogoPainter extends CustomPainter {
  _IlmLogoPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scale factor from viewBox 340x300 → actual size
    final sx = w / 340;
    final sy = h / 300;

    canvas.save();
    canvas.scale(sx, sy);

    // Sway animation
    final swayAngle = sin(progress * 2 * pi) * 0.014; // ~0.8 deg
    final floatY = sin(progress * 2 * pi) * 2;

    canvas.translate(0, floatY);

    // Pivot for sway at mast base
    canvas.translate(170, 192);
    canvas.rotate(swayAngle);
    canvas.translate(-170, -192);

    // ── Mast ──
    final mastPaint = Paint()
      ..color = primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(170, 58), const Offset(170, 192), mastPaint);

    // ── Main sail (left, large) ──
    final sailPhase = sin(progress * 2 * pi);
    final mainSailQx = 108.0 + sailPhase * -6;
    final mainSailQy = 102.0 + sailPhase * 6;

    final mainSailPath = Path()
      ..moveTo(170, 66)
      ..quadraticBezierTo(mainSailQx, mainSailQy, 98 + sailPhase * -3, 182)
      ..lineTo(170, 182)
      ..close();

    canvas.drawPath(
      mainSailPath,
      Paint()..color = primary.withValues(alpha: 0.92),
    );

    // ── Small sail (right) ──
    final smallSailQx = 212.0 + sailPhase * 4;
    final smallSailQy = 96.0 + sailPhase * 4;

    final smallSailPath = Path()
      ..moveTo(170, 74)
      ..quadraticBezierTo(smallSailQx, smallSailQy, 222 + sailPhase * 3, 152)
      ..lineTo(170, 152)
      ..close();

    canvas.drawPath(
      smallSailPath,
      Paint()..color = primary.withValues(alpha: 0.45),
    );

    // ── Cross beam ──
    canvas.drawLine(
      const Offset(106, 102),
      const Offset(220, 102),
      Paint()
        ..color = primary.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Hull ──
    final hullPath = Path()
      ..moveTo(96, 188)
      ..quadraticBezierTo(100, 204, 170, 207)
      ..quadraticBezierTo(240, 204, 244, 188)
      ..close();

    canvas.drawPath(
      hullPath,
      Paint()..color = primary.withValues(alpha: 0.92),
    );

    // Reset sway for wave
    canvas.restore();
    canvas.save();
    canvas.scale(sx, sy);
    canvas.translate(0, floatY);

    // ── Wave ──
    final wavePhase = sin(progress * 2 * pi);
    final waveBaseY = 212.0 + wavePhase * 3;

    final wavePath = Path()..moveTo(78, waveBaseY);
    wavePath.quadraticBezierTo(108, waveBaseY - 6, 138, waveBaseY);
    wavePath.quadraticBezierTo(168, waveBaseY + 6, 198, waveBaseY);
    wavePath.quadraticBezierTo(228, waveBaseY - 6, 258, waveBaseY);

    canvas.drawPath(
      wavePath,
      Paint()
        ..color = primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // ── Dot at top ──
    canvas.save();
    canvas.scale(sx, sy);

    final dotOpacity = 0.4 + 0.6 * (0.5 + 0.5 * sin(progress * 2 * pi));
    canvas.drawCircle(
      Offset(170, 46 + floatY),
      5,
      Paint()..color = primary.withValues(alpha: dotOpacity),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_IlmLogoPainter old) =>
      old.progress != progress || old.primary != primary;
}
