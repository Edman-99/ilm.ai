import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/data/user_plan.dart';
import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;
    final isWide = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      backgroundColor: c.bg,
      body: BlocBuilder<AnalysisCubit, AnalysisState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: isWide ? 80 : 48),

                      Text(
                        s.choosePlan,
                        style: TextStyle(
                          fontSize: isWide ? 40 : 28,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.choosePlanSubtitle,
                        style: TextStyle(
                          fontSize: isWide ? 16 : 14,
                          color: c.textSecondary,
                        ),
                      ),

                      SizedBox(height: isWide ? 48 : 32),

                      if (isWide)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final plan in UserPlan.values) ...[
                                if (plan != UserPlan.free)
                                  const SizedBox(width: 16),
                                Expanded(
                                  child: _PlanCard(
                                    plan: plan,
                                    info: plans[plan]!,
                                    isCurrent: state.userPlan == plan,
                                    currentPlan: state.userPlan,
                                    colors: c,
                                    strings: s,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (final plan in UserPlan.values) ...[
                              if (plan != UserPlan.free)
                                const SizedBox(height: 16),
                              _PlanCard(
                                plan: plan,
                                info: plans[plan]!,
                                isCurrent: state.userPlan == plan,
                                currentPlan: state.userPlan,
                                colors: c,
                                strings: s,
                              ),
                            ],
                          ],
                        ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: c.border),
                              ),
                            ),
                            icon: Icon(Icons.arrow_back_rounded,
                                size: 18, color: c.textSecondary),
                            label: Text(
                              s.back,
                              style: TextStyle(
                                  fontSize: 15, color: c.textSecondary),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.info,
    required this.isCurrent,
    required this.currentPlan,
    required this.colors,
    required this.strings,
  });

  final UserPlan plan;
  final PlanInfo info;
  final bool isCurrent;
  final UserPlan currentPlan;
  final AppColors colors;
  final AppStrings strings;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final s = widget.strings;
    final info = widget.info;
    final isCurrent = widget.isCurrent;
    final isPopular = info.isPopular;
    final features = s.featuresFor(widget.plan);

    // Determine if this is an upgrade (plan index > current plan index)
    final isUpgrade = widget.plan.index > widget.currentPlan.index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hovered
              ? (c.isDark
                  ? const Color(0xFF111111)
                  : const Color(0xFFF5F5F5))
              : c.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular
                ? (c.isDark
                    ? const Color(0xFF555555)
                    : const Color(0xFFAAAAAA))
                : isCurrent
                    ? c.accent
                    : _hovered
                        ? (c.isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFFCCCCCC))
                        : c.border,
            width: isPopular || isCurrent ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: c.isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.06),
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
            // Popular badge
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: c.accent),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.popular,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),

            // Plan name
            Text(
              info.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  info.price,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                if (widget.plan != UserPlan.free)
                  Text(
                    s.perMonth,
                    style: TextStyle(
                      fontSize: 15,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Daily limit
            Text(
              s.dailyLimitLabel(info.dailyLimit),
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            // Divider
            Container(height: 1, color: c.border),

            const SizedBox(height: 20),

            // Features
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        f.included
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 16,
                        color: f.included ? c.textPrimary : c.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: f.included
                                ? c.textPrimary
                                : c.textSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 8),

            // Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: c.border),
                      ),
                      child: Text(
                        s.currentPlan,
                        style: TextStyle(
                          fontSize: 15,
                          color: c.textSecondary,
                        ),
                      ),
                    )
                  : isUpgrade
                      // Upgrade blocked — "Coming soon"
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: c.border),
                          ),
                          child: Text(
                            s.comingSoon,
                            style: TextStyle(
                              fontSize: 15,
                              color: c.textSecondary,
                            ),
                          ),
                        )
                      // Downgrade allowed
                      : ElevatedButton(
                          onPressed: () {
                            context
                                .read<AnalysisCubit>()
                                .setPlan(widget.plan);
                            Navigator.of(context).pop();
                          },
                          child: Text(s.select),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
