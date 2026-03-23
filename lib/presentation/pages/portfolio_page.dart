import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:ai_stock_analyzer/data/analytics_service.dart';
import 'package:ai_stock_analyzer/data/portfolio_mock.dart';
import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _amountController = TextEditingController(text: '10000');
  PortfolioStrategy? _strategy;
  PortfolioResult? _result;

  // 0 = input, 1 = loading, 2 = result
  int _step = 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount {
    final text = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(text) ?? 0;
  }

  Future<void> _build() async {
    if (_strategy == null || _amount <= 0) return;

    AnalyticsService.instance.track('portfolio_build_started', {
      'amount': _amount,
      'strategy': _strategy!.name,
    });

    setState(() => _step = 1);

    // Fake delay
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _result = mockPortfolios[_strategy!];
      _step = 2;
    });

    AnalyticsService.instance.track('portfolio_build_completed', {
      'amount': _amount,
      'strategy': _strategy!.name,
    });
  }

  void _reset() {
    setState(() {
      _step = 0;
      _result = null;
      _strategy = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          s.buildPortfolio,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: c.border),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _step == 0
            ? _buildInput(c, s)
            : _step == 1
                ? _buildLoading(c, s)
                : _buildResult(c, s),
      ),
    );
  }

  // ── Step 0: Input ──

  Widget _buildInput(AppColors c, AppStrings s) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Amount
                Text(
                  s.enterAmount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.buildPortfolioSubtitle,
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: 1,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                    hintText: s.amountHint,
                    hintStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary.withValues(alpha: 0.3),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 40),

                // Strategy
                Text(
                  s.chooseStrategy,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                _StrategyCard(
                  title: s.strategyConservative,
                  description: s.strategyConservativeDesc,
                  icon: Icons.shield_rounded,
                  isSelected: _strategy == PortfolioStrategy.conservative,
                  c: c,
                  onTap: () => setState(
                    () => _strategy = PortfolioStrategy.conservative,
                  ),
                ),
                const SizedBox(height: 12),
                _StrategyCard(
                  title: s.strategyModerate,
                  description: s.strategyModerateDesc,
                  icon: Icons.balance_rounded,
                  isSelected: _strategy == PortfolioStrategy.moderate,
                  c: c,
                  onTap: () => setState(
                    () => _strategy = PortfolioStrategy.moderate,
                  ),
                ),
                const SizedBox(height: 12),
                _StrategyCard(
                  title: s.strategyAggressive,
                  description: s.strategyAggressiveDesc,
                  icon: Icons.rocket_launch_rounded,
                  isSelected: _strategy == PortfolioStrategy.aggressive,
                  c: c,
                  onTap: () => setState(
                    () => _strategy = PortfolioStrategy.aggressive,
                  ),
                ),

                const SizedBox(height: 32),

                // Build button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _strategy != null && _amount > 0 ? _build : null,
                    child: Text(s.buildPortfolio),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Loading ──

  Widget _buildLoading(AppColors c, AppStrings s) {
    return Center(
      key: const ValueKey(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: c.accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s.buildingPortfolio,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_amount.toStringAsFixed(0)} · ${_strategy?.name ?? ''}',
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: c.border,
              color: c.accent.withValues(alpha: 0.4),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Result ──

  Widget _buildResult(AppColors c, AppStrings s) {
    final result = _result!;
    final totalAmount = _amount;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 960;

    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  s.yourPortfolio,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: c.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // Stats cards
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: s.expectedReturn,
                            value: '${result.expectedReturn.toStringAsFixed(1)}%',
                            color: c.green,
                            c: c,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: s.annualRisk,
                            value: '${result.risk.toStringAsFixed(1)}%',
                            color: c.red,
                            c: c,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: s.sharpeRatio,
                            value: result.sharpe.toStringAsFixed(2),
                            color: c.accent,
                            c: c,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _StatCard(label: s.expectedReturn, value: '${result.expectedReturn.toStringAsFixed(1)}%', color: c.green, c: c),
                  const SizedBox(height: 12),
                  _StatCard(label: s.annualRisk, value: '${result.risk.toStringAsFixed(1)}%', color: c.red, c: c),
                  const SizedBox(height: 12),
                  _StatCard(label: s.sharpeRatio, value: result.sharpe.toStringAsFixed(2), color: c.accent, c: c),
                ],

                const SizedBox(height: 32),

                // Pie chart + positions table
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pie chart
                      SizedBox(
                        width: 320,
                        child: _PieChartCard(result: result, c: c, s: s),
                      ),
                      const SizedBox(width: 20),
                      // Positions
                      Expanded(
                        child: _PositionsCard(
                          result: result,
                          totalAmount: totalAmount,
                          c: c,
                          s: s,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _PieChartCard(result: result, c: c, s: s),
                  const SizedBox(height: 20),
                  _PositionsCard(
                    result: result,
                    totalAmount: totalAmount,
                    c: c,
                    s: s,
                  ),
                ],

                const SizedBox(height: 32),

                // AI analysis
                _AnalysisCard(analysis: result.analysis, c: c),

                const SizedBox(height: 24),

                // Disclaimer
                Text(
                  s.disclaimer,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Reset button
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 48,
                    child: TextButton.icon(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: c.border),
                        ),
                      ),
                      icon: Icon(Icons.refresh_rounded, size: 18, color: c.textSecondary),
                      label: Text(
                        s.back,
                        style: TextStyle(fontSize: 15, color: c.textSecondary),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Strategy card ──

class _StrategyCard extends StatefulWidget {
  const _StrategyCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.c,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final AppColors c;
  final VoidCallback onTap;

  @override
  State<_StrategyCard> createState() => _StrategyCardState();
}

class _StrategyCardState extends State<_StrategyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final selected = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected
                ? (c.isDark ? const Color(0xFF141414) : const Color(0xFFF0F0F0))
                : _hovered
                    ? (c.isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5))
                    : c.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? c.accent
                  : _hovered
                      ? (c.isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC))
                      : c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: c.textSecondary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: c.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat card ──

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.c,
  });

  final String label;
  final String value;
  final Color color;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pie chart card ──

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({
    required this.result,
    required this.c,
    required this.s,
  });

  final PortfolioResult result;
  final AppColors c;
  final AppStrings s;

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
        children: [
          Text(
            s.allocation,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: result.positions.map((p) {
                  return PieChartSectionData(
                    value: p.weight * 100,
                    color: Color(p.color),
                    radius: 50,
                    title: '${(p.weight * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...result.positions.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(p.color),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.ticker,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${(p.weight * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Positions table ──

class _PositionsCard extends StatelessWidget {
  const _PositionsCard({
    required this.result,
    required this.totalAmount,
    required this.c,
    required this.s,
  });

  final PortfolioResult result;
  final double totalAmount;
  final AppColors c;
  final AppStrings s;

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
          // Header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(s.ticker, style: _headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(s.sector, style: _headerStyle, textAlign: TextAlign.left),
              ),
              Expanded(
                child: Text(s.weight, style: _headerStyle, textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: Text(s.amount, style: _headerStyle, textAlign: TextAlign.right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 8),
          // Rows
          ...result.positions.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(p.color),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.ticker,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.sector,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(p.weight * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '\$${p.amount(totalAmount).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: c.textSecondary,
      );
}

// ── AI analysis card ──

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis, required this.c});

  final String analysis;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: MarkdownBody(
        data: analysis,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet(
          h2: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
          h3: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
          p: TextStyle(
            fontSize: 14,
            color: c.textPrimary,
            height: 1.7,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
          listBullet: TextStyle(color: c.textSecondary),
          listBulletPadding: const EdgeInsets.only(right: 8),
          blockSpacing: 12,
        ),
      ),
    );
  }
}
