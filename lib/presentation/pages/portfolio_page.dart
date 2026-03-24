import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/data/analytics_service.dart';
import 'package:ai_stock_analyzer/data/portfolio_result_dto.dart';
import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

enum PortfolioStrategy { conservative, moderate, aggressive }

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _amountController = TextEditingController(text: '10000');
  PortfolioStrategy? _strategy;
  bool _loading = false;
  String? _error;
  PortfolioResultDto? _result;

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

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cubit = context.read<AnalysisCubit>();
      final result = await cubit.repository.buildPortfolio(
        amount: _amount,
        riskStrategy: _strategy!.name,
      );

      if (!mounted) return;

      AnalyticsService.instance.track('portfolio_build_completed', {
        'amount': _amount,
        'strategy': _strategy!.name,
        'positions_count': result.allocations.length,
      });

      setState(() {
        _loading = false;
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
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
          onPressed: () {
            if (_result != null) {
              _reset();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _result != null ? s.yourPortfolio : s.buildPortfolio,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        actions: [
          if (_result != null)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
              onPressed: _reset,
              tooltip: s.back,
            ),
        ],
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
        child: _result != null
            ? _PortfolioResult(key: const ValueKey(2), result: _result!, c: c, s: s)
            : _loading
                ? _buildLoading(c, s)
                : _buildInput(c, s),
      ),
    );
  }

  // ── Input ──

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

                // Error
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.red.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      s.errorGeneric,
                      style: TextStyle(fontSize: 14, color: c.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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

  // ── Loading ──

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
}

// ══════════════════════════════════════════════
// ── Portfolio Result ──
// ══════════════════════════════════════════════

class _PortfolioResult extends StatelessWidget {
  const _PortfolioResult({
    super.key,
    required this.result,
    required this.c,
    required this.s,
  });

  final PortfolioResultDto result;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 960;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metric cards
                _MetricCards(result: result, isWide: isWide, c: c, s: s),
                const SizedBox(height: 32),

                // Pie chart + Allocation table
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _AllocationTable(
                          allocations: result.allocations,
                          c: c,
                          s: s,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _PieChartCard(
                          allocations: result.allocations,
                          c: c,
                          s: s,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _PieChartCard(
                    allocations: result.allocations,
                    c: c,
                    s: s,
                  ),
                  const SizedBox(height: 24),
                  _AllocationTable(
                    allocations: result.allocations,
                    c: c,
                    s: s,
                  ),
                ],

                const SizedBox(height: 32),

                // AI Analysis (markdown)
                if (result.analysis.isNotEmpty)
                  _AnalysisCard(analysis: result.analysis, c: c, s: s),

                const SizedBox(height: 24),

                // Disclaimer
                Text(
                  s.disclaimer,
                  style: TextStyle(fontSize: 12, color: c.textSecondary.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Metric Cards ──

class _MetricCards extends StatelessWidget {
  const _MetricCards({
    required this.result,
    required this.isWide,
    required this.c,
    required this.s,
  });

  final PortfolioResultDto result;
  final bool isWide;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricItem(
        label: s.expectedReturn,
        value: '${result.expectedReturnMin.toStringAsFixed(0)}–${result.expectedReturnMax.toStringAsFixed(0)}%',
        icon: Icons.trending_up_rounded,
        color: c.green,
      ),
      _MetricItem(
        label: s.maxDrawdown,
        value: '−${result.maxDrawdown.toStringAsFixed(0)}%',
        icon: Icons.trending_down_rounded,
        color: c.red,
      ),
      _MetricItem(
        label: s.rebalancing,
        value: s.rebalancingLabel(result.rebalancingFrequency),
        icon: Icons.sync_rounded,
        color: c.accent,
      ),
      _MetricItem(
        label: s.amount,
        value: '\$${_formatNumber(result.totalAmount)}',
        icon: Icons.account_balance_wallet_rounded,
        color: c.textPrimary,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: _buildCard(cards[i])),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCard(cards[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(cards[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCard(cards[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(cards[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(_MetricItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(height: 12),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

// ── Pie Chart ──

const _chartColors = [
  Color(0xFF3B82F6), // blue
  Color(0xFF10B981), // green
  Color(0xFFF59E0B), // amber
  Color(0xFFEF4444), // red
  Color(0xFF8B5CF6), // purple
  Color(0xFF06B6D4), // cyan
  Color(0xFFF97316), // orange
  Color(0xFFEC4899), // pink
  Color(0xFF14B8A6), // teal
  Color(0xFF6366F1), // indigo
  Color(0xFF84CC16), // lime
  Color(0xFFD946EF), // fuchsia
  Color(0xFF78716C), // stone
  Color(0xFF0EA5E9), // sky
  Color(0xFFE11D48), // rose
];

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({
    required this.allocations,
    required this.c,
    required this.s,
  });

  final List<PortfolioAllocation> allocations;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
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
                sections: [
                  for (var i = 0; i < allocations.length; i++)
                    PieChartSectionData(
                      value: allocations[i].percentage,
                      color: _chartColors[i % _chartColors.length],
                      radius: 50,
                      title: '${allocations[i].percentage.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.6,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (var i = 0; i < allocations.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartColors[i % _chartColors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      allocations[i].ticker,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Allocation Table ──

class _AllocationTable extends StatelessWidget {
  const _AllocationTable({
    required this.allocations,
    required this.c,
    required this.s,
  });

  final List<PortfolioAllocation> allocations;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    s.ticker,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    s.assetClass,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    s.weight,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    s.amount,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    s.shares,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rows
          for (var i = 0; i < allocations.length; i++)
            _AllocationRow(
              allocation: allocations[i],
              color: _chartColors[i % _chartColors.length],
              isLast: i == allocations.length - 1,
              c: c,
            ),
        ],
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    required this.allocation,
    required this.color,
    required this.isLast,
    required this.c,
  });

  final PortfolioAllocation allocation;
  final Color color;
  final bool isLast;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Ticker + Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allocation.ticker,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        allocation.name,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Asset class
          Expanded(
            flex: 2,
            child: Text(
              allocation.assetClass,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Weight
          SizedBox(
            width: 60,
            child: Text(
              '${allocation.percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          // Amount
          SizedBox(
            width: 80,
            child: Text(
              '\$${_formatNumber(allocation.amount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
          // Shares
          SizedBox(
            width: 70,
            child: Text(
              allocation.shares.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Analysis Card ──

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.c,
    required this.s,
  });

  final String analysis;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: c.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                s.portfolioAnalysis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: analysis,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.6),
              h2: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
              h3: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
              listBullet: TextStyle(fontSize: 14, color: c.textPrimary),
              strong: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary),
              em: TextStyle(fontStyle: FontStyle.italic, color: c.textSecondary),
              blockquoteDecoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.05),
                border: Border(left: BorderSide(color: c.accent, width: 3)),
              ),
              code: TextStyle(
                fontSize: 13,
                color: c.accent,
                backgroundColor: c.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Strategy Card ──

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

// ── Helpers ──

String _formatNumber(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final str = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
  return value.toStringAsFixed(2);
}
