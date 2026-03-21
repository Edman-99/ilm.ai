import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/theme/app_theme.dart';

const modes = <String, String>{
  'full': 'Полный отчёт',
  'technical': 'Тех. анализ',
  'screener': 'Скрининг',
  'risk': 'Риски',
  'dcf': 'DCF',
  'earnings': 'Отчётность',
  'portfolio': 'Портфель',
  'dividends': 'Дивиденды',
  'competitors': 'Конкуренты',
};

class ModeChips extends StatelessWidget {
  const ModeChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeScope.of(context).colors;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.entries.map((e) {
        final isActive = e.key == selected;
        return GestureDetector(
          onTap: () => onSelected(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? c.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? c.accent : c.border,
              ),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? (c.isDark ? Colors.black : Colors.white)
                    : c.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
