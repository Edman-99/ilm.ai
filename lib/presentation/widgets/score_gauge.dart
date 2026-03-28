import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/theme/app_theme.dart';

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({required this.score, required this.signal, super.key});

  final int score;
  final String signal;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;
    final color = c.scoreColor(score);

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 120,
          child: CustomPaint(
            painter: _Painter(score: score, color: color, trackColor: c.border),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                '$score',
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
            signal,
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
  }
}

class _Painter extends CustomPainter {
  _Painter({
    required this.score,
    required this.color,
    required this.trackColor,
  });

  final int score;
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

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      pi,
      (score / 100) * pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Painter old) => old.score != score;
}
