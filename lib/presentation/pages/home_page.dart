import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/data/analytics_service.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_cubit.dart';
import 'package:ai_stock_analyzer/presentation/pages/result_page.dart';
import 'package:ai_stock_analyzer/presentation/pages/trading_analytics_page.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AnalysisCubit>();
    final t = AppThemeScope.of(context);
    final c = t.colors;

    return MultiBlocListener(
      listeners: [
        BlocListener<AnalysisCubit, AnalysisState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status && curr.isError,
          listener: (context, state) {
            AnalyticsService.instance.analysisError(
              state.ticker,
              state.selectedMode,
              state.errorKey ?? 'unknown',
            );
          },
        ),
        BlocListener<AnalysisCubit, AnalysisState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.isLoaded &&
              curr.result != null,
          listener: (context, state) {
            AnalyticsService.instance.analysisCompleted(
              state.result!.ticker,
              state.result!.mode,
              state.result!.score,
            );
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: ResultPage(analysis: state.result!),
                ),
              ),
            );
          },
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                // ── Header: Logo + Tabs + Controls ──
                _buildHeader(c, t),

                // ── Content ──
                Expanded(
                  child: _buildAiAnalysisTab(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(AppColors c, AppThemeScope t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Logo
          Text(
            'ILM',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              letterSpacing: -0.5,
            ),
          ),

          const Spacer(),

          // Controls
          _buildLocaleToggle(c, t),
          const SizedBox(width: 8),
          _buildThemeToggle(c, t.onToggle),
        ],
      ),
    );
  }

  // ── Analysis Tab ──
  Widget _buildAiAnalysisTab() {
    return BlocProvider.value(
      value: context.read<TradingAnalyticsCubit>(),
      child: const TradingAnalyticsPage(embedded: true),
    );
  }

  Widget _buildLocaleToggle(AppColors c, AppThemeScope t) {
    return IconButton(
      onPressed: () {
        t.onToggleLocale();
        AnalyticsService.instance
            .localeToggled(t.locale == 'ru' ? 'en' : 'ru');
      },
      style: IconButton.styleFrom(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.border),
        ),
      ),
      icon: Text(
        t.locale == 'ru' ? 'RU' : 'EN',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c.textSecondary,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(AppColors c, VoidCallback onToggle) {
    return IconButton(
      onPressed: () {
        onToggle();
        AnalyticsService.instance.themeToggled(!c.isDark);
      },
      style: IconButton.styleFrom(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.border),
        ),
      ),
      icon: Icon(
        c.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        size: 18,
        color: c.textSecondary,
      ),
    );
  }
}