import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/presentation/pages/result_page.dart';
import 'package:ai_stock_analyzer/presentation/widgets/mode_chips.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AnalysisCubit>();
    final t = AppThemeScope.of(context);
    final c = t.colors;

    return BlocListener<AnalysisCubit, AnalysisState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.isLoaded && curr.result != null,
      listener: (context, state) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: ResultPage(analysis: state.result!),
            ),
          ),
        );
      },
      child: Scaffold(
        body: BlocBuilder<AnalysisCubit, AnalysisState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(c, t.onToggle),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 64),
                            _buildHero(c),
                            const SizedBox(height: 40),
                            _buildSearchSection(cubit, state, c),
                            const SizedBox(height: 20),
                            ModeChips(
                              selected: state.selectedMode,
                              onSelected: cubit.setMode,
                            ),
                            const SizedBox(height: 24),
                            _buildButton(cubit, state, c),
                            if (state.isError) ...[
                              const SizedBox(height: 16),
                              _buildError(state, c),
                            ],
                            if (state.history.isNotEmpty) ...[
                              const SizedBox(height: 48),
                              _buildHistory(context, cubit, state, c),
                            ],
                            const SizedBox(height: 64),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(AppColors c, VoidCallback onToggle) {
    return SliverAppBar(
      floating: true,
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Icon(Icons.auto_awesome, size: 20, color: c.textPrimary),
          const SizedBox(width: 8),
          Text(
            'AI Stock Analyzer',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: c.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: c.green.withOpacity(0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Live',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(width: 16),
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

  Widget _buildHero(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Анализ акций\nс помощью AI',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '9 методологий от ведущих инвестиционных банков мира',
          style: TextStyle(fontSize: 16, color: c.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSearchSection(
    AnalysisCubit cubit,
    AnalysisState state,
    AppColors c,
  ) {
    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.characters,
      onChanged: cubit.setTicker,
      style: TextStyle(fontSize: 16, color: c.textPrimary),
      onSubmitted: (_) {
        if (!state.isLoading && state.ticker.trim().isNotEmpty) {
          cubit.analyze();
        }
      },
      decoration: InputDecoration(
        hintText: 'Введите тикер — AAPL, TSLA, MSFT...',
        suffixIcon: Icon(Icons.search, color: c.textSecondary),
      ),
    );
  }

  Widget _buildButton(AnalysisCubit cubit, AnalysisState state, AppColors c) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isLoading || state.ticker.trim().isEmpty
            ? null
            : cubit.analyze,
        child: state.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.isDark ? Colors.black : Colors.white,
                ),
              )
            : const Text('Анализировать'),
      ),
    );
  }

  Widget _buildError(AnalysisState state, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: c.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error ?? 'Ошибка',
              style: TextStyle(fontSize: 14, color: c.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(
    BuildContext context,
    AnalysisCubit cubit,
    AnalysisState state,
    AppColors c,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Недавние анализы',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...state.history.map((item) {
          final color = c.scoreColor(item.score);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: ResultPage(analysis: item),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${item.score}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.ticker,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            item.modeDescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
