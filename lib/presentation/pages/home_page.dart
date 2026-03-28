import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/data/analytics_service.dart';
import 'package:ai_stock_analyzer/data/auth_cubit.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_cubit.dart';
import 'package:ai_stock_analyzer/data/user_plan.dart';
import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/presentation/pages/auth_page.dart';
import 'package:ai_stock_analyzer/presentation/pages/portfolio_page.dart';
import 'package:ai_stock_analyzer/presentation/pages/pricing_page.dart';
import 'package:ai_stock_analyzer/presentation/pages/trading_analytics_page.dart';
import 'package:ai_stock_analyzer/presentation/pages/result_page.dart';
import 'package:ai_stock_analyzer/presentation/widgets/analysis_skeleton.dart';
import 'package:ai_stock_analyzer/presentation/widgets/hero_section.dart';
import 'package:ai_stock_analyzer/presentation/widgets/mode_chips.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

String _translateAnalysisError(String? key, AppStrings s) {
  if (key == null) return s.errorGeneric;
  if (key.startsWith('${AnalysisErrorKey.server}:')) {
    final code = key.split(':').last;
    return s.errorServerWithCode(int.tryParse(code) ?? 0);
  }
  switch (key) {
    case AnalysisErrorKey.modeUnavailable:
      return s.errorModeUnavailable;
    case AnalysisErrorKey.limitReached:
      return s.errorLimitReached;
    case AnalysisErrorKey.noConnection:
      return s.errorNoConnection;
    default:
      return s.errorGeneric;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tickerController = TextEditingController();

  // 0 = mode selection, 1 = ticker input, 2 = analyze
  int _step = 0;

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  Future<void> _onModeSelected(String mode) async {
    AnalyticsService.instance.modeSelected(mode);
    context.read<AnalysisCubit>().setMode(mode);

    final auth = context.read<AuthCubit>().state;
    if (!auth.isAuthenticated) {
      final ok = await showAuthDialog(context);
      if (!ok || !mounted) return;
    }

    setState(() => _step = 1);
  }

  void _openPricing() {
    AnalyticsService.instance.pricingViewed();
    final cubit = context.read<AnalysisCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const PricingPage(),
        ),
      ),
    );
  }

  void _goBack() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else if (_step == 2) {
      setState(() => _step = 1);
    }
  }

  void _onTickerSubmit() {
    final ticker = _tickerController.text.trim();
    if (ticker.isNotEmpty) {
      AnalyticsService.instance.tickerEntered(ticker);
      context.read<AnalysisCubit>().setTicker(ticker);
      setState(() => _step = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AnalysisCubit>();
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;

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
            Navigator.of(context)
                .push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: ResultPage(analysis: state.result!),
                ),
              ),
            )
                .then((_) {
              if (mounted) {
                setState(() => _step = 0);
                _tickerController.clear();
              }
            });
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.isAuthenticated && state.user != null) {
              AnalyticsService.instance.identify(state.user!.email);
              AnalyticsService.instance.login(state.user!.email);
              cubit.setPlan(state.user!.plan);
            } else if (!state.isAuthenticated) {
              AnalyticsService.instance.logout();
              AnalyticsService.instance.reset();
              cubit.reset();
              _tickerController.clear();
              setState(() => _step = 0);
            }
          },
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            BlocBuilder<AnalysisCubit, AnalysisState>(
              builder: (context, state) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: state.isLoading
                      ? AnalysisSkeleton(
                          ticker: state.ticker,
                          mode: s.modes[state.selectedMode]?.label ?? state.selectedMode,
                        )
                      : _step == 0
                          ? _buildStep0(cubit, c, s)
                          : _step == 1
                              ? _buildStep1(cubit, c, s)
                              : _buildStep2(cubit, c, s),
                );
              },
            ),

            // Top-left: credits
            Positioned(
              top: 16,
              left: 16,
              child: BlocBuilder<AnalysisCubit, AnalysisState>(
                builder: (context, state) =>
                    _buildCreditsBadge(state, c, s),
              ),
            ),

            // Top-right buttons
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTradingAnalyticsButton(c),
                  const SizedBox(width: 8),
                  _buildPortfolioButton(c, s),
                  const SizedBox(width: 8),
                  _buildAuthButton(c),
                  const SizedBox(width: 8),
                  _buildPricingButton(c),
                  const SizedBox(width: 8),
                  _buildLocaleToggle(c, t),
                  const SizedBox(width: 8),
                  _buildThemeToggle(c, t.onToggle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Hero + mode selection ──
  Widget _buildStep0(AnalysisCubit cubit, AppColors c, AppStrings s) {
    return BlocBuilder<AnalysisCubit, AnalysisState>(
      key: const ValueKey(0),
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const HeroSection(),
              const SizedBox(height: 16),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ModeChips(
                      selected: state.selectedMode,
                      onSelected: _onModeSelected,
                      isModeLocked: (mode) => !state.isModeAvailable(mode),
                      onLockedTap: _openPricing,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // History
              if (state.history.isNotEmpty)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildHistory(context, cubit, state, c, s),
                    ),
                  ),
                ),

              const SizedBox(height: 64),
            ],
          ),
        );
      },
    );
  }

  // ── Step 1: Ticker input ──
  Widget _buildStep1(AnalysisCubit cubit, AppColors c, AppStrings s) {
    return BlocBuilder<AnalysisCubit, AnalysisState>(
      key: const ValueKey(1),
      builder: (context, state) {
        final modeLabel = s.modes[state.selectedMode]?.label ?? state.selectedMode;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (modeLabel.isNotEmpty) ...[
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        modeLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    s.enterTicker,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.tickerHint,
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  TextField(
                    controller: _tickerController,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      letterSpacing: 2,
                    ),
                    onChanged: (v) => cubit.setTicker(v),
                    onSubmitted: (_) => _onTickerSubmit(),
                    decoration: InputDecoration(
                      hintText: 'AAPL',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: c.textSecondary.withOpacity(0.3),
                        letterSpacing: 2,
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
                          horizontal: 24, vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _tickerController.text.trim().isEmpty
                          ? null
                          : _onTickerSubmit,
                      child: Text(s.next),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildBackButton(c, s),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Step 2: Analyze ──
  Widget _buildStep2(AnalysisCubit cubit, AppColors c, AppStrings s) {
    return BlocBuilder<AnalysisCubit, AnalysisState>(
      key: const ValueKey(2),
      builder: (context, state) {
        final modeLabel = s.modes[state.selectedMode]?.label ?? state.selectedMode;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badges: mode + ticker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (modeLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            modeLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          state.ticker.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    s.startAnalysis,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (s.modes[state.selectedMode]?.bank case final bank?) bank,
                      state.ticker.toUpperCase(),
                    ].join(' · '),
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              AnalyticsService.instance.analysisStarted(
                                state.ticker,
                                state.selectedMode,
                              );
                              cubit.analyze();
                            },
                      child: state.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : Text(s.analyze),
                    ),
                  ),

                  if (state.isError) ...[
                    const SizedBox(height: 16),
                    _buildError(state, c, s),
                  ],

                  const SizedBox(height: 16),
                  _buildBackButton(c, s),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(AppColors c, AppStrings s) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: _goBack,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.border),
          ),
        ),
        icon: Icon(Icons.arrow_back_rounded, size: 18, color: c.textSecondary),
        label: Text(
          s.back,
          style: TextStyle(fontSize: 15, color: c.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCreditsBadge(AnalysisState state, AppColors c, AppStrings s) {
    final planInfo = plans[state.userPlan]!;
    final label = state.isUnlimited
        ? '${planInfo.name} · ${s.unlimited}'
        : '${planInfo.name} · ${state.remaining}/${state.dailyLimit}';

    return GestureDetector(
      onTap: _openPricing,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: state.hasCredits ? c.border : c.red.withOpacity(0.4),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 16,
                color: state.hasCredits ? c.textSecondary : c.red,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: state.hasCredits ? c.textSecondary : c.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(AppColors c) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isLoggedIn = authState.isAuthenticated;
        return IconButton(
          onPressed: isLoggedIn
              ? () => context.read<AuthCubit>().logout()
              : () => showAuthDialog(context),
          style: IconButton.styleFrom(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: c.border),
            ),
          ),
          icon: Icon(
            isLoggedIn ? Icons.logout_rounded : Icons.person_outline_rounded,
            size: 18,
            color: c.textSecondary,
          ),
        );
      },
    );
  }

  Widget _buildTradingAnalyticsButton(AppColors c) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<TradingAnalyticsCubit>(),
              child: const TradingAnalyticsPage(),
            ),
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: c.green.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
            color: c.green.withOpacity(0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 16, color: c.green),
              const SizedBox(width: 6),
              Text(
                'Trading Analytics',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioButton(AppColors c, AppStrings s) {
    return GestureDetector(
      onTap: () {
        AnalyticsService.instance.track('portfolio_opened');
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PortfolioPage(),
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: c.accent.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
            color: c.accent.withOpacity(0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_rounded, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                s.buildPortfolio,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingButton(AppColors c) {
    return IconButton(
      onPressed: _openPricing,
      style: IconButton.styleFrom(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.border),
        ),
      ),
      icon: Icon(
        Icons.workspace_premium_rounded,
        size: 18,
        color: c.textSecondary,
      ),
    );
  }

  Widget _buildLocaleToggle(AppColors c, AppThemeScope t) {
    return IconButton(
      onPressed: () {
        t.onToggleLocale();
        AnalyticsService.instance.localeToggled(t.locale == 'ru' ? 'en' : 'ru');
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

  Widget _buildError(AnalysisState state, AppColors c, AppStrings s) {
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
              _translateAnalysisError(state.errorKey, s),
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
    AppStrings s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.recentAnalyses,
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
