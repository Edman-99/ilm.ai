import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/theme/app_theme.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({required this.isWide, super.key});

  final bool isWide;

  static const _icons = [
    Icons.search_rounded,
    Icons.auto_awesome_rounded,
    Icons.assessment_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;
    final steps = s.howItWorksSteps;

    return Column(
      children: [
        Text(
          s.howItWorks,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.howItWorksSubtitle,
          style: TextStyle(fontSize: 15, color: c.textSecondary),
        ),
        const SizedBox(height: 36),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  if (i > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: c.textSecondary.withOpacity(0.3),
                        size: 20,
                      ),
                    ),
                  ],
                  Expanded(
                    child: _StepCard(
                      title: steps[i].title,
                      description: steps[i].description,
                      icon: _icons[i],
                      colors: c,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StepCard(
                    title: steps[i].title,
                    description: steps[i].description,
                    icon: _icons[i],
                    colors: c,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _StepCard extends StatefulWidget {
  const _StepCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String description;
  final IconData icon;
  final AppColors colors;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered
              ? (colors.isDark
                  ? const Color(0xFF111111)
                  : const Color(0xFFF5F5F5))
              : colors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? (colors.isDark
                    ? const Color(0xFF555555)
                    : const Color(0xFFCCCCCC))
                : colors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: colors.isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        transform: _hovered
            ? (Matrix4.identity()..setTranslationRaw(0.0, -3.0, 0.0))
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Icon(widget.icon, size: 22, color: colors.textSecondary),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
