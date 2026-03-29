import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/theme/app_theme.dart';

class AnalysisSkeleton extends StatefulWidget {
  const AnalysisSkeleton({
    required this.ticker,
    required this.mode,
    super.key,
  });

  final String ticker;
  final String mode;

  @override
  State<AnalysisSkeleton> createState() => _AnalysisSkeletonState();
}

class _AnalysisSkeletonState extends State<AnalysisSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeScope.of(context).colors;
    final s = AppThemeScope.of(context).strings;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 960;

    return SingleChildScrollView(
      key: const ValueKey('skeleton'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    _ShimmerBox(w: 80, h: 28, c: c, animation: _shimmer),
                    const SizedBox(width: 14),
                    _ShimmerBox(w: 100, h: 22, c: c, animation: _shimmer),
                    const SizedBox(width: 8),
                    _ShimmerBox(w: 60, h: 22, c: c, animation: _shimmer),
                    const Spacer(),
                    _ShimmerBox(w: 100, h: 30, c: c, animation: _shimmer),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: c.border),

                const SizedBox(height: 24),

                // Status line
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${s.analyze}...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.ticker.toUpperCase()} · ${widget.mode}',
                        style: TextStyle(
                          fontSize: 13,
                          color: c.textSecondary.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 180,
                        child: LinearProgressIndicator(
                          backgroundColor: c.border,
                          color: c.accent.withOpacity(0.4),
                          minHeight: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3 cards skeleton
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _SkeletonCard(c: c, animation: _shimmer, lines: 4)),
                        const SizedBox(width: 16),
                        Expanded(child: _SkeletonCard(c: c, animation: _shimmer, lines: 6)),
                        const SizedBox(width: 16),
                        Expanded(child: _SkeletonCard(c: c, animation: _shimmer, lines: 5)),
                      ],
                    ),
                  )
                else ...[
                  _SkeletonCard(c: c, animation: _shimmer, lines: 4),
                  const SizedBox(height: 16),
                  _SkeletonCard(c: c, animation: _shimmer, lines: 6),
                  const SizedBox(height: 16),
                  _SkeletonCard(c: c, animation: _shimmer, lines: 5),
                ],

                const SizedBox(height: 32),

                // AI analysis skeleton
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _SkeletonCard(c: c, animation: _shimmer, lines: 3),
                            const SizedBox(height: 12),
                            _SkeletonCard(c: c, animation: _shimmer, lines: 8),
                            const SizedBox(height: 12),
                            _SkeletonCard(c: c, animation: _shimmer, lines: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 340,
                        child: _SkeletonCard(c: c, animation: _shimmer, lines: 12),
                      ),
                    ],
                  )
                else ...[
                  _SkeletonCard(c: c, animation: _shimmer, lines: 3),
                  const SizedBox(height: 12),
                  _SkeletonCard(c: c, animation: _shimmer, lines: 8),
                  const SizedBox(height: 12),
                  _SkeletonCard(c: c, animation: _shimmer, lines: 6),
                  const SizedBox(height: 12),
                  _SkeletonCard(c: c, animation: _shimmer, lines: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer line ──

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.w,
    required this.h,
    required this.c,
    required this.animation,
  });

  final double w;
  final double h;
  final AppColors c;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          c.card,
          c.border,
          (animation.value * 2 - 1).abs() * 0.5,
        )!;

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}

// ── Skeleton card ──

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.c,
    required this.animation,
    required this.lines,
  });

  final AppColors c;
  final Animation<double> animation;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(w: 120, h: 18, c: c, animation: animation),
          const SizedBox(height: 6),
          _ShimmerBox(w: 80, h: 12, c: c, animation: animation),
          const SizedBox(height: 16),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 14),
          for (int i = 0; i < lines; i++) ...[
            _ShimmerBox(
              w: i.isEven ? double.infinity : 200,
              h: 14,
              c: c,
              animation: animation,
            ),
            if (i < lines - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
