import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/theme/app_theme.dart';

class IndicatorRow extends StatelessWidget {
  const IndicatorRow({
    required this.label,
    required this.value,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeScope.of(context).colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
