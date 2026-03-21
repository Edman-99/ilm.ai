import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:ai_stock_analyzer/data/stock_analysis_dto.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({required this.analysis, super.key});

  final StockAnalysisDto analysis;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 960;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ResultAppBar(analysis: analysis, c: c, onToggle: t.onToggle),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  child: Column(
                    children: [
                      _PlanCards(analysis: analysis, isWide: isWide, c: c),
                      const SizedBox(height: 32),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AiAnalysisCard(analysis: analysis, c: c),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 340,
                              child: _SwotCompact(c: c),
                            ),
                          ],
                        )
                      else ...[
                        _AiAnalysisCard(analysis: analysis, c: c),
                        const SizedBox(height: 20),
                        _SwotCompact(c: c),
                      ],
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
    required this.onToggle,
  });

  final StockAnalysisDto analysis;
  final AppColors c;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final changeColor = analysis.change1m >= 0 ? c.green : c.red;
    final trendColor = analysis.isBullish ? c.green : c.red;
    final scoreColor = c.scoreColor(analysis.score);

    return SliverAppBar(
      pinned: true,
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Тикер
          Text(
            analysis.ticker,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          // Цена
          Text(
            '\$${analysis.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Изменение
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${analysis.change1m >= 0 ? '+' : ''}${analysis.change1m.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: changeColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Тренд
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: trendColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  analysis.trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${analysis.score}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  analysis.signal,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Theme toggle
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
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
}

// ── 3 карточки-плана ──

class _PlanCards extends StatelessWidget {
  const _PlanCards({
    required this.analysis,
    required this.isWide,
    required this.c,
  });

  final StockAnalysisDto analysis;
  final bool isWide;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PlanData(
        title: 'Обзор',
        subtitle: 'Быстрый вердикт',
        icon: Icons.flash_on_rounded,
        features: [
          'Скор: ${analysis.score}/100 — ${analysis.signal}',
          'Тренд: ${analysis.trend}',
          'Цена: \$${analysis.price.toStringAsFixed(2)}',
          'Изменение: ${analysis.change1m >= 0 ? '+' : ''}${analysis.change1m.toStringAsFixed(1)}%',
        ],
        accentColor: c.green,
      ),
      _PlanData(
        title: 'Индикаторы',
        subtitle: 'Технический анализ',
        icon: Icons.bar_chart_rounded,
        isHighlighted: true,
        features: [
          'RSI: ${analysis.rsi.toStringAsFixed(1)}',
          'SMA 20 / 50: ${analysis.sma20.toStringAsFixed(2)} / ${analysis.sma50.toStringAsFixed(2)}',
          'MACD: ${analysis.macd.toStringAsFixed(4)}',
          'Signal: ${analysis.macdSignal.toStringAsFixed(4)}',
          'Bollinger: ${analysis.bbLower.toStringAsFixed(0)}–${analysis.bbUpper.toStringAsFixed(0)}',
          'ATR: ${analysis.atr.toStringAsFixed(2)}',
        ],
        accentColor: const Color(0xFF636AFF),
      ),
      _PlanData(
        title: 'AI Анализ',
        subtitle: analysis.modeDescription,
        icon: Icons.auto_awesome,
        features: [
          'Полный AI отчёт',
          'Фундаментальный анализ',
          'Оценка рисков',
          'Рекомендации',
          'SWOT анализ',
        ],
        accentColor: const Color(0xFF818CF8),
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
    required this.icon,
    required this.features,
    required this.accentColor,
    this.isHighlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> features;
  final Color accentColor;
  final bool isHighlighted;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.data, required this.c});
  final _PlanData data;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.isHighlighted
              ? data.accentColor.withOpacity(0.4)
              : c.border,
          width: data.isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 20, color: data.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      data.subtitle,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (data.isHighlighted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ключевые',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 16),
          ...data.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: data.accentColor.withOpacity(0.6),
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
    );
  }
}

// ── AI Анализ — красивые секции ──

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({required this.analysis, required this.c});
  final StockAnalysisDto analysis;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(analysis.analysis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF636AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 22,
                  color: Color(0xFF636AFF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Анализ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      analysis.modeDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Секции
        ...sections.map((s) => _SectionCard(section: s, c: c)),
      ],
    );
  }

  static const _sectionIcons = <String, IconData>{
    'техническ': Icons.bar_chart_rounded,
    'позици': Icons.show_chart,
    'индикатор': Icons.analytics_outlined,
    'момент': Icons.speed,
    'волатильност': Icons.swap_vert,
    'объём': Icons.stacked_bar_chart,
    'outlook': Icons.remove_red_eye_outlined,
    'рекоменда': Icons.thumb_up_outlined,
    'недостающ': Icons.warning_amber,
    'данн': Icons.storage,
    'вердикт': Icons.flash_on_rounded,
    'фундамент': Icons.account_balance,
    'риск': Icons.shield_outlined,
    'превью': Icons.description_outlined,
    'портфел': Icons.pie_chart_outline,
    'диверсиф': Icons.donut_large,
    'сектор': Icons.grid_view,
    'прибыл': Icons.trending_up,
    'убыточ': Icons.trending_down,
  };

  static const _sectionColors = <String, Color>{
    'техническ': Color(0xFF636AFF),
    'позици': Color(0xFF636AFF),
    'индикатор': Color(0xFF2196F3),
    'момент': Color(0xFF00BCD4),
    'волатильност': Color(0xFFFF9800),
    'объём': Color(0xFF9C27B0),
    'outlook': Color(0xFF4CAF50),
    'рекоменда': Color(0xFF4CAF50),
    'недостающ': Color(0xFFFF9800),
    'вердикт': Color(0xFF22C55E),
    'фундамент': Color(0xFF2196F3),
    'риск': Color(0xFFEF4444),
    'превью': Color(0xFF636AFF),
    'портфел': Color(0xFF636AFF),
    'диверсиф': Color(0xFFFF9800),
    'сектор': Color(0xFF9C27B0),
    'прибыл': Color(0xFF22C55E),
    'убыточ': Color(0xFFEF4444),
  };

  IconData _iconForTitle(String title) {
    final lower = title.toLowerCase();
    for (final e in _sectionIcons.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return Icons.article_outlined;
  }

  Color _colorForTitle(String title) {
    final lower = title.toLowerCase();
    for (final e in _sectionColors.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return const Color(0xFF636AFF);
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
            icon: _iconForTitle(currentTitle),
            color: _colorForTitle(currentTitle),
          ));
          currentBody.clear();
        }
        currentTitle =
            line.replaceFirst(RegExp(r'^#{2,3}\s*'), '').trim();
      } else if (currentTitle != null) {
        currentBody.writeln(line);
      } else if (line.trim().isNotEmpty) {
        // Текст до первого заголовка
        if (sections.isEmpty && currentTitle == null) {
          currentTitle = 'Сводка';
        }
        currentBody.writeln(line);
      }
    }

    if (currentTitle != null && currentBody.toString().trim().isNotEmpty) {
      sections.add(_Section(
        title: currentTitle,
        body: currentBody.toString().trim(),
        icon: _iconForTitle(currentTitle),
        color: _colorForTitle(currentTitle),
      ));
    }

    return sections;
  }
}

class _Section {
  const _Section({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.c});
  final _Section section;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(section.icon, size: 16, color: section.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
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
    );
  }
}

// ── SWOT ──

class _SwotCompact extends StatelessWidget {
  const _SwotCompact({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SWOT',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _SwotQ(
            title: 'Сильные стороны',
            items: const ['Стабильный рост выручки', 'Сильный бренд'],
            color: c.green,
            icon: Icons.trending_up,
            c: c,
          ),
          const SizedBox(height: 10),
          _SwotQ(
            title: 'Слабые стороны',
            items: const ['Высокий P/E', 'Зависимость от рынка'],
            color: c.red,
            icon: Icons.trending_down,
            c: c,
          ),
          const SizedBox(height: 10),
          _SwotQ(
            title: 'Возможности',
            items: const ['AI сегмент', 'Новые рынки'],
            color: const Color(0xFF636AFF),
            icon: Icons.lightbulb_outline,
            c: c,
          ),
          const SizedBox(height: 10),
          _SwotQ(
            title: 'Угрозы',
            items: const ['Конкуренция', 'Регуляторные риски'],
            color: c.yellow,
            icon: Icons.warning_amber,
            c: c,
          ),
        ],
      ),
    );
  }
}

class _SwotQ extends StatelessWidget {
  const _SwotQ({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
    required this.c,
  });

  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $item',
                style: TextStyle(fontSize: 12, color: c.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
