import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:ai_stock_analyzer/data/analytics_service.dart';
import 'package:ai_stock_analyzer/data/stock_analysis_dto.dart';
import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({required this.analysis, super.key});

  final StockAnalysisDto analysis;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 960;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ResultAppBar(analysis: analysis, c: c, s: s, onToggle: t.onToggle),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  child: Column(
                    children: [
                      _PlanCards(analysis: analysis, isWide: isWide, c: c, s: s),
                      const SizedBox(height: 32),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AiAnalysisCard(analysis: analysis, c: c, s: s),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 340,
                              child: _SwotCompact(c: c, s: s),
                            ),
                          ],
                        )
                      else ...[
                        _AiAnalysisCard(analysis: analysis, c: c, s: s),
                        const SizedBox(height: 20),
                        _SwotCompact(c: c, s: s),
                      ],
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          s.disclaimer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Bar ──

class _ResultAppBar extends StatelessWidget {
  const _ResultAppBar({
    required this.analysis,
    required this.c,
    required this.s,
    required this.onToggle,
  });

  final StockAnalysisDto analysis;
  final AppColors c;
  final AppStrings s;
  final VoidCallback onToggle;

  void _share(BuildContext context) {
    final changePrefix = analysis.change1m >= 0 ? '+' : '';
    final signalText = s.signal(analysis.score);

    final text = '''${analysis.ticker} · \$${analysis.price.toStringAsFixed(2)} · $changePrefix${analysis.change1m.toStringAsFixed(1)}%
${s.score}: ${analysis.score}/100 — $signalText
${s.trend}: ${analysis.trend}
RSI: ${analysis.rsi.toStringAsFixed(1)} · MACD: ${analysis.macd.toStringAsFixed(4)}
${analysis.modeDescription}

— ILM AI Stock Analyzer''';

    Clipboard.setData(ClipboardData(text: text));
    AnalyticsService.instance.track('analysis_shared', {
      'ticker': analysis.ticker,
      'mode': analysis.mode,
      'score': analysis.score,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.copied),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 200,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final changePrefix = analysis.change1m >= 0 ? '+' : '';
    final scoreColor = c.scoreColor(analysis.score);
    final signalText = s.signal(analysis.score);

    return SliverAppBar(
      pinned: true,
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Text(
            analysis.ticker,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '\$${analysis.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          _badge(
            '$changePrefix${analysis.change1m.toStringAsFixed(1)}%',
            c.textSecondary,
          ),
          const SizedBox(width: 8),
          _badge(analysis.trend, c.textSecondary),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scoreColor.withOpacity(0.2)),
            ),
            child: Text(
              '${analysis.score} $signalText',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _share(context),
            tooltip: s.share,
            icon: Icon(
              Icons.share_rounded,
              size: 18,
              color: c.textSecondary,
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              c.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 18,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: c.border),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ── 3 cards ──

class _PlanCards extends StatelessWidget {
  const _PlanCards({
    required this.analysis,
    required this.isWide,
    required this.c,
    required this.s,
  });

  final StockAnalysisDto analysis;
  final bool isWide;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final signalText = s.signal(analysis.score);
    final cards = [
      _PlanData(
        title: s.overview,
        subtitle: s.quickVerdict,
        features: [
          '${s.score}: ${analysis.score}/100 — $signalText',
          '${s.trend}: ${analysis.trend}',
          '${s.price}: \$${analysis.price.toStringAsFixed(2)}',
          '${s.change}: ${analysis.change1m >= 0 ? '+' : ''}${analysis.change1m.toStringAsFixed(1)}%',
        ],
      ),
      _PlanData(
        title: s.indicators,
        subtitle: s.technicalAnalysis,
        features: [
          'RSI: ${analysis.rsi.toStringAsFixed(1)}',
          'SMA 20 / 50: ${analysis.sma20.toStringAsFixed(2)} / ${analysis.sma50.toStringAsFixed(2)}',
          'MACD: ${analysis.macd.toStringAsFixed(4)}',
          'Signal: ${analysis.macdSignal.toStringAsFixed(4)}',
          'Bollinger: ${analysis.bbLower.toStringAsFixed(0)}–${analysis.bbUpper.toStringAsFixed(0)}',
          'ATR: ${analysis.atr.toStringAsFixed(2)}',
        ],
      ),
      _PlanData(
        title: s.aiAnalysis,
        subtitle: analysis.modeDescription,
        features: [
          s.fullAiReport,
          s.fundamentalAnalysis,
          s.riskAssessment,
          s.recommendations,
          s.swotAnalysis,
        ],
      ),
    ];

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: _PlanCard(data: cards[i], c: c)),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _PlanCard(data: cards[i], c: c),
        ],
      ],
    );
  }
}

class _PlanData {
  const _PlanData({
    required this.title,
    required this.subtitle,
    required this.features,
  });

  final String title;
  final String subtitle;
  final List<String> features;
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({required this.data, required this.c});
  final _PlanData data;
  final AppColors c;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final data = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered
              ? (c.isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5))
              : c.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? (c.isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC))
                : c.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            Divider(color: c.border, height: 1),
            const SizedBox(height: 14),
            ...data.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(fontSize: 14, color: c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Analysis ──

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({required this.analysis, required this.c, required this.s});
  final StockAnalysisDto analysis;
  final AppColors c;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(analysis.analysis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.aiAnalysis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                analysis.modeDescription,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...sections.map((sec) => _SectionCard(section: sec, c: c)),
      ],
    );
  }

  List<_Section> _parseSections(String md) {
    final lines = md.split('\n');
    final sections = <_Section>[];
    String? currentTitle;
    final currentBody = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('## ') || line.startsWith('### ')) {
        if (currentTitle != null) {
          sections.add(_Section(
            title: currentTitle,
            body: currentBody.toString().trim(),
          ));
          currentBody.clear();
        }
        currentTitle =
            line.replaceFirst(RegExp(r'^#{2,3}\s*'), '').trim();
      } else if (currentTitle != null) {
        currentBody.writeln(line);
      } else if (line.trim().isNotEmpty) {
        if (sections.isEmpty && currentTitle == null) {
          currentTitle = s.summary;
        }
        currentBody.writeln(line);
      }
    }

    if (currentTitle != null && currentBody.toString().trim().isNotEmpty) {
      sections.add(_Section(
        title: currentTitle,
        body: currentBody.toString().trim(),
      ));
    }

    return sections;
  }
}

class _Section {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.section, required this.c});
  final _Section section;
  final AppColors c;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final section = widget.section;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered
                ? (c.isDark
                    ? const Color(0xFF111111)
                    : const Color(0xFFF5F5F5))
                : c.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? (c.isDark
                      ? const Color(0xFF555555)
                      : const Color(0xFFCCCCCC))
                  : c.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: section.body,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
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
                  blockSpacing: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SWOT ──

class _SwotCompact extends StatelessWidget {
  const _SwotCompact({required this.c, required this.s});
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
          Text(
            'SWOT',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _SwotQ(title: s.strengths, items: s.swotStrengthItems, c: c),
          const SizedBox(height: 10),
          _SwotQ(title: s.weaknesses, items: s.swotWeaknessItems, c: c),
          const SizedBox(height: 10),
          _SwotQ(title: s.opportunities, items: s.swotOpportunityItems, c: c),
          const SizedBox(height: 10),
          _SwotQ(title: s.threats, items: s.swotThreatItems, c: c),
        ],
      ),
    );
  }
}

class _SwotQ extends StatelessWidget {
  const _SwotQ({
    required this.title,
    required this.items,
    required this.c,
  });

  final String title;
  final List<String> items;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· $item',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
