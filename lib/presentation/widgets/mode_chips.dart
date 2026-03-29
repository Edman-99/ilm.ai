import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

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
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final modes = t.strings.modes;
    final width = MediaQuery.of(context).size.width;

    final crossCount = width > 1100 ? 3 : (width > 640 ? 2 : 1);
    final entries = modes.entries.toList();

    return Column(
      children: [
        for (int row = 0; row < (entries.length / crossCount).ceil(); row++)
          Padding(
            padding: EdgeInsets.only(
              bottom: row < (entries.length / crossCount).ceil() - 1 ? 14 : 0,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int col = 0; col < crossCount; col++) ...[
                    if (col > 0) const SizedBox(width: 14),
                    Expanded(
                      child: () {
                        final idx = row * crossCount + col;
                        if (idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final entry = entries[idx];
                        return _ModeCard(
                          info: entry.value,
                          isActive: entry.key == selected,
                          colors: c,
                          onTap: () => onSelected(entry.key),
                        );
                      }(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.info,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  final ModeInfo info;
  final bool isActive;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final info = widget.info;
    final isActive = widget.isActive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive
                ? c.cardActive
                : _hovered
                    ? c.cardHover
                    : c.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? c.accent
                  : _hovered
                      ? (c.isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC))
                      : c.border,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: _hovered || isActive
                ? [
                    BoxShadow(
                      color: c.isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + check
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.check_circle_rounded, size: 20, color: c.accent),
                ],
              ),

              const SizedBox(height: 4),

              // Bank
              Text(
                info.bank,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),

              const SizedBox(height: 10),

              // Description
              Text(
                info.description,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
