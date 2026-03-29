import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/theme/app_theme.dart';

class ScoreGauge extends StatefulWidget {
  const ScoreGauge({required this.score, required this.signal, super.key});

  final int score;
  final String signal;

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(ScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;
    final color = c.scoreColor(widget.score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedScore = (_animation.value * widget.score).round();
        return Column(
          children: [
            SizedBox(
              width: 200,
              height: 120,
              child: CustomPaint(
                painter: _Painter(
                  progress: _animation.value * widget.score / 100,
                  color: color,
                  trackColor: c.border,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    '$animatedScore',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.signal,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.outOf100,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
        );
      },
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress; // 0.0 to 1.0
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final r = size.width / 2 - 14;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      pi,
      pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        pi,
        progress * pi,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.progress != progress;
}
