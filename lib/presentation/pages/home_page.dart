import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/data/analytics_service.dart';
import 'package:ai_stock_analyzer/data/lead_service.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_cubit.dart';
import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/presentation/pages/result_page.dart';
import 'package:ai_stock_analyzer/presentation/pages/trading_analytics_page.dart';
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
  int _tabIndex = 0; // 0 = AI Analysis, 1 = Trading Analytics

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  void _onModeSelected(String mode) {
    AnalyticsService.instance.modeSelected(mode);
    context.read<AnalysisCubit>().setMode(mode);
  }

  Future<void> _onAnalyze() async {
    final cubit = context.read<AnalysisCubit>();
    final ticker = _tickerController.text.trim();
    if (ticker.isEmpty) return;

    cubit.setTicker(ticker);

    // Show lead form if not yet collected.
    final hasLead = await LeadService.hasLead();
    if (!hasLead && mounted) {
      final ok = await _showLeadForm();
      if (!ok || !mounted) return;
    }

    AnalyticsService.instance.analysisStarted(ticker, cubit.state.selectedMode);
    cubit.analyze();
  }

  Future<bool> _showLeadForm() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _LeadFormDialog(),
        ) ??
        false;
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
                _buildHeader(c, s, t),

                // ── Content ──
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _tabIndex == 0
                        ? _buildAiAnalysisTab(cubit, c, s)
                        : _buildTradingTab(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(AppColors c, AppStrings s, AppThemeScope t) {
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
          const SizedBox(width: 32),

          // Tabs
          _buildTab(s.tabAiAnalysis, 0, c),
          const SizedBox(width: 4),
          _buildTab(s.tabTradingAnalytics, 1, c),

          const Spacer(),

          // Controls
          _buildLocaleToggle(c, t),
          const SizedBox(width: 8),
          _buildThemeToggle(c, t.onToggle),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, AppColors c) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? c.cardActive : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? c.textPrimary : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── AI Analysis Tab (Variant A) ──
  Widget _buildAiAnalysisTab(AnalysisCubit cubit, AppColors c, AppStrings s) {
    return BlocBuilder<AnalysisCubit, AnalysisState>(
      key: const ValueKey('ai'),
      builder: (context, state) {
        if (state.isLoading) {
          return AnalysisSkeleton(
            ticker: state.ticker,
            mode: s.modes[state.selectedMode]?.label ?? state.selectedMode,
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const HeroSection(),

              // ── Ticker input + Analyze button ──
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tickerController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textAlign: TextAlign.center,
                                onChanged: (v) => cubit.setTicker(v),
                                onSubmitted: (_) => _onAnalyze(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                  letterSpacing: 2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'AAPL',
                                  hintStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: c.textSecondary.withOpacity(0.5),
                                    letterSpacing: 2,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: c.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: c.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: c.accent, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ListenableBuilder(
                              listenable: _tickerController,
                              builder: (context, _) {
                                final empty = _tickerController.text.trim().isEmpty;
                                return SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: empty ? null : _onAnalyze,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 28),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(s.analyze),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.tickerHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),

                        if (state.isError) ...[
                          const SizedBox(height: 12),
                          _buildError(state, c, s),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Mode chips ──
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ModeChips(
                      selected: state.selectedMode,
                      onSelected: _onModeSelected,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── History ──
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: state.history.isNotEmpty
                        ? _buildHistory(context, cubit, state, c, s)
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 16, color: c.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  s.emptyHistory,
                                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
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

  // ── Trading Analytics Tab ──
  Widget _buildTradingTab() {
    return BlocProvider.value(
      key: const ValueKey('trading'),
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

// ═══════════════════════════════════════════════════════════════════
// Lead Form Dialog
// ═══════════════════════════════════════════════════════════════════

class _LeadFormDialog extends StatefulWidget {
  const _LeadFormDialog();

  @override
  State<_LeadFormDialog> createState() => _LeadFormDialogState();
}

class _LeadFormDialogState extends State<_LeadFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final lead = LeadData(
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim(),
    );

    await LeadService.save(lead);

    AnalyticsService.instance.track('lead_submitted', {
      'email': lead.email,
      'has_whatsapp': lead.whatsapp.isNotEmpty,
    });

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;

    return Dialog(
      backgroundColor: c.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: c.green,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  s.leadTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.leadSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
                const SizedBox(height: 28),

                // Name row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: s.leadFirstName,
                          prefixIcon: Icon(Icons.person_outline,
                              color: c.textSecondary, size: 18),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? s.leadFirstNameRequired : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: s.leadLastName,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: s.leadEmail,
                    prefixIcon: Icon(Icons.email_outlined,
                        color: c.textSecondary, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return s.leadEmailRequired;
                    if (!v.contains('@') || !v.contains('.')) return s.leadEmailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // WhatsApp
                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: s.leadWhatsapp,
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: c.textSecondary, size: 18),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.isDark ? Colors.black : Colors.white,
                            ),
                          )
                        : Text(
                            s.leadSubmit,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Privacy
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: c.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      s.leadPrivacy,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
