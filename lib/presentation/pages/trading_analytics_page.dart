import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:excel/excel.dart' as xl;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:ai_stock_analyzer/data/ai/ai_cubit.dart';
import 'package:ai_stock_analyzer/data/analytics_service.dart';
import 'package:ai_stock_analyzer/data/lead_service.dart';
import 'package:ai_stock_analyzer/data/trading/strategy_entity.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_cubit.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_entity.dart';
import 'package:ai_stock_analyzer/data/trading/trading_position_dto.dart';
import 'package:ai_stock_analyzer/data/trading/trading_order_dto.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

// =============================================================================
// PAGE
// =============================================================================

class TradingAnalyticsPage extends StatefulWidget {
  const TradingAnalyticsPage({this.embedded = false, super.key});
  final bool embedded;
  @override
  State<TradingAnalyticsPage> createState() => _TradingAnalyticsPageState();
}

class _TradingAnalyticsPageState extends State<TradingAnalyticsPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedPeriod = 'All';

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final cubit = context.read<TradingAnalyticsCubit>();
    await cubit.loadSavedCredentials();
    final s = cubit.state;
    if (s.savedEmail != null) _emailCtrl.text = s.savedEmail!;
    if (s.savedPassword != null) _passwordCtrl.text = s.savedPassword!;
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeScope.of(context).colors;
    Widget content = BlocBuilder<TradingAnalyticsCubit, TradingAnalyticsState>(
        builder: (context, state) {
          if (!state.isAuthenticated && !state.isLoading) return _LoginForm(emailCtrl: _emailCtrl, passwordCtrl: _passwordCtrl);
          if (state.isLoading) return _Skeleton(c: c);
          if (state.status == TradingAnalyticsStatus.error) return _ErrorView(message: state.errorMessage ?? 'Error');
          if (state.analytics == null) return const SizedBox.shrink();
          final wide = MediaQuery.of(context).size.width > 900;
          Widget body;
          switch (state.activePage) {
            case TradingPage.portfolio:
              body = _PortfolioPage(c: c, state: state);
            case TradingPage.strategies:
              body = _StrategiesPage(c: c, state: state);
            case TradingPage.orders:
              body = _OrdersPage(c: c, state: state);
            case TradingPage.ai:
              body = const SizedBox.shrink();
            case TradingPage.journal:
              body = const SizedBox.shrink();
            case TradingPage.dashboard:
              body = _Grid(a: state.analytics!, c: c, wide: wide, orders: state.allOrders);
          }
          return Row(children: [
            if (wide) _Sidebar(c: c, email: state.savedEmail, activePage: state.activePage),
            Expanded(child: Column(children: [
              _Header(c: c, period: _selectedPeriod, activePage: state.activePage, isDemo: state.isDemo, onPeriod: (p, f, t) { setState(() => _selectedPeriod = p); context.read<TradingAnalyticsCubit>().filterByDateRange(f, t); }),
              Expanded(child: body),
              if (state.isDemo) CtaBanner(c: c),
              _StatusBar(c: c, trades: state.analytics!.totalTrades),
            ])),
          ]);
        },
    );
    if (widget.embedded) return content;
    return Scaffold(backgroundColor: c.bg, body: content);
  }
}

// =============================================================================
// SIDEBAR — matches design
// =============================================================================

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.c, this.email, required this.activePage});
  final AppColors c; final String? email; final TradingPage activePage;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TradingAnalyticsCubit>();
    return Container(
      width: 200, color: c.isDark ? const Color(0xFF0A0A0A) : c.surface,
      child: Column(children: [
        const SizedBox(height: 24),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
          SvgPicture.asset('assets/svg/ic_app_logo.svg', height: 22),
        ),
        const SizedBox(height: 20),
        if (email != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email!.split('@').first.toUpperCase(), style: TextStyle(color: c.green, fontSize: 11, fontWeight: FontWeight.w700)),
          Text(_T.of(context).navStaging, style: TextStyle(color: c.textSecondary, fontSize: 9, letterSpacing: 0.5)),
        ]))),
        const SizedBox(height: 24),
        _navBtn(Icons.dashboard_rounded, _T.of(context).navDashboard, TradingPage.dashboard, cubit),
        _navBtn(Icons.account_balance_wallet_outlined, _T.of(context).navPortfolio, TradingPage.portfolio, cubit),
        _navBtn(Icons.pie_chart_rounded, _T.of(context).navStrategies, TradingPage.strategies, cubit),
        _navBtn(Icons.receipt_long_rounded, _T.of(context).navOrders, TradingPage.orders, cubit),
        const Spacer(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), child:
          GestureDetector(onTap: () => cubit.logout(), child: _nav(Icons.logout_rounded, _T.of(context).navLogout, false, c)),
        ),
      ]),
    );
  }
  Widget _navBtn(IconData ic, String l, TradingPage page, TradingAnalyticsCubit cubit) {
    final on = activePage == page;
    return GestureDetector(
      onTap: () => cubit.setPage(page),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: _nav(ic, l, on, c)),
    );
  }
  static Widget _nav(IconData ic, String l, bool on, AppColors c) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: on ? c.accent.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8),
      border: on ? Border(left: BorderSide(color: c.accent, width: 3)) : null),
    child: Row(children: [
      Icon(ic, size: 16, color: on ? c.textPrimary : c.textSecondary),
      const SizedBox(width: 10),
      Text(l, style: TextStyle(color: on ? c.textPrimary : c.textSecondary, fontSize: 11, fontWeight: on ? FontWeight.w700 : FontWeight.w500, letterSpacing: 0.5)),
    ]),
  );
}

// =============================================================================
// HEADER
// =============================================================================

class _Header extends StatelessWidget {
  const _Header({required this.c, required this.period, required this.activePage, this.isDemo = false, required this.onPeriod});
  final AppColors c; final String period; final TradingPage activePage; final bool isDemo; final void Function(String, DateTime?, DateTime?) onPeriod;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
    child: Row(children: [
      if (activePage == TradingPage.dashboard)
        ...['1W','1M','3M','6M','1Y','All'].map((p) { final on = p == period;
          return Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
            onTap: () { final now = DateTime.now(); DateTime? f; switch(p) { case '1W': f=now.subtract(const Duration(days:7)); case '1M': f=DateTime(now.year,now.month-1,now.day); case '3M': f=DateTime(now.year,now.month-3,now.day); case '6M': f=DateTime(now.year,now.month-6,now.day); case '1Y': f=DateTime(now.year-1,now.month,now.day); default: onPeriod(p,null,null); return; } onPeriod(p,f,now); },
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: on ? c.green : Colors.transparent, borderRadius: BorderRadius.circular(20)),
              child: Text(p, style: TextStyle(color: on ? c.bg : c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)))),
          ));
        })
      else
        Builder(builder: (ctx) { final t = _T.of(ctx); return Text(
          switch (activePage) { TradingPage.portfolio => t.headerPortfolio, TradingPage.strategies => t.headerStrategies, TradingPage.orders => t.headerOrderHistory, _ => '' },
          style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1),
        ); }),
      const Spacer(),
      if (isDemo) Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: c.yellow.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.yellow.withOpacity(0.3))),
        child: Text('DEMO', style: TextStyle(color: c.yellow, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
      GestureDetector(
        onTap: () {
          final cubit = context.read<TradingAnalyticsCubit>();
          if (activePage == TradingPage.portfolio) cubit.loadPositions();
          else if (activePage == TradingPage.orders) cubit.loadOrders();
          else cubit.refresh();
        },
        child: MouseRegion(cursor: SystemMouseCursors.click, child: Icon(Icons.refresh, size: 18, color: c.textSecondary)),
      ),
    ]),
  );
}

// =============================================================================
// STATUS BAR
// =============================================================================

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.c, required this.trades});
  final AppColors c; final int trades;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
    child: Row(children: [
      const Spacer(),
      Container(width: 6, height: 6, decoration: BoxDecoration(color: c.green, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Builder(builder: (ctx) => Text(_T.of(ctx).statusLive, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
      const SizedBox(width: 16),
      Builder(builder: (ctx) => Text('$trades ${_T.of(ctx).trades}', style: TextStyle(color: c.textSecondary, fontSize: 9))),
    ]),
  );
}

// =============================================================================
// GRID — fixed layout matching design exactly
// =============================================================================

class _Grid extends StatelessWidget {
  const _Grid({required this.a, required this.c, required this.wide, required this.orders});
  final TradingAnalyticsEntity a; final AppColors c; final bool wide;
  final List<TradingOrderDto> orders;

  @override
  Widget build(BuildContext context) {
    if (!wide) return _mobile();
    const g = 12.0;
    return ListView(padding: const EdgeInsets.all(20), children: [
      SizedBox(height: 240, child: _row(g, [_f(2, _Metrics(a: a, c: c)), _f(1, _EquityCurve(a: a, c: c))])),
      SizedBox(height: g),
      SizedBox(height: 260, child: _row(g, [_f(1, _WinRate(a: a, c: c)), _f(1, _Streaks(a: a, c: c)), _f(1, _TopTickers(a: a, c: c))])),
      SizedBox(height: g),
      SizedBox(height: 220, child: _row(g, [_f(1, _SideAnalysis(a: a, c: c)), _f(1, _WeekdayChart(a: a, c: c)), _f(1, _HourlyHeatmap(a: a, c: c))])),
      SizedBox(height: g),
      SizedBox(height: 320, child: _row(g, [_f(1, _Calendar(a: a, c: c, orders: orders)), _f(1, _MonthlyTable(a: a, c: c)), _f(1, _HoldTime(a: a, c: c))])),
      SizedBox(height: g),
      SizedBox(height: 260, child: _row(g, [_f(1, _TradeSize(a: a, c: c)), _f(1, _RrDist(a: a, c: c))])),
      const SizedBox(height: 32),
    ]);
  }

  Widget _mobile() => ListView(padding: const EdgeInsets.all(16), children: [
    _card(_Metrics(a: a, c: c)), const SizedBox(height: 12),
    _card(_EquityCurve(a: a, c: c)), const SizedBox(height: 12),
    _card(_WinRate(a: a, c: c)), const SizedBox(height: 12),
    _card(_Streaks(a: a, c: c)), const SizedBox(height: 12),
    _card(_TopTickers(a: a, c: c)), const SizedBox(height: 12),
    _card(_SideAnalysis(a: a, c: c)), const SizedBox(height: 12),
    _card(_WeekdayChart(a: a, c: c)), const SizedBox(height: 12),
    _card(_HourlyHeatmap(a: a, c: c)), const SizedBox(height: 12),
    _card(_Calendar(a: a, c: c, orders: orders)), const SizedBox(height: 12),
    _card(_MonthlyTable(a: a, c: c)), const SizedBox(height: 12),
    _card(_HoldTime(a: a, c: c)), const SizedBox(height: 12),
    _card(_TradeSize(a: a, c: c)), const SizedBox(height: 12),
    _card(_RrDist(a: a, c: c)), const SizedBox(height: 32),
  ]);

  Widget _row(double gap, List<Widget> children) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children.expand((w) sync* { if (w != children.first) yield SizedBox(width: gap); yield w; }).toList());
  Widget _f(int flex, Widget child) => Expanded(flex: flex, child: _card(child));
  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
    child: child,
  );
}

// =============================================================================
// KEY METRICS
// =============================================================================

class _Metrics extends StatefulWidget {
  const _Metrics({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  State<_Metrics> createState() => _MetricsState();
}

class _MetricsState extends State<_Metrics> {
  bool _plInPct = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.a; final c = widget.c;
    // Cost basis approximation: totalPl / (profitFactor-like ratio) — use avgPl as reference.
    // P/L % = totalPl / (totalPl - totalPl + avgWin*winCount) ≈ show as avg P/L per trade %.
    // Best available: totalPl relative to total commissions+losses as cost.
    final totalLoss = a.averageLoss * a.lossCount;
    final totalInvested = totalLoss + (a.averageWin * a.winCount);
    final plPct = totalInvested > 0 ? (a.totalPl / totalInvested * 100) : 0.0;
    final plLabel = _plInPct
        ? '${a.totalPl >= 0 ? '+' : ''}${plPct.toStringAsFixed(1)}%'
        : _fmtD(a.totalPl);

    final row1 = [
      ('TOTAL P/L', plLabel, _plC(a.totalPl, c)),
      ('WIN RATE %', '${a.winRate.toStringAsFixed(1)}%', a.winRate >= 50 ? c.green : c.red),
      ('PROFIT FACTOR', a.profitFactor.toStringAsFixed(2), c.textPrimary),
      ('TOTAL TRADES', '${a.totalTrades}', c.textPrimary),
    ];
    final row2 = [
      ('AVG WIN', '+\$${a.averageWin.toStringAsFixed(0)}', c.green),
      ('AVG LOSS', '-\$${a.averageLoss.toStringAsFixed(0)}', c.red),
      ('R/R RATIO', a.riskRewardRatio.toStringAsFixed(2), c.textPrimary),
      ('COMMISSION', '-\$${a.totalCommission.toStringAsFixed(2)}', c.textSecondary),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_T.of(context).keyMetrics, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _plInPct = !_plInPct),
          child: Container(
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _tab('\$', !_plInPct, c),
              _tab('%', _plInPct, c),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      _metricRow(row1, c),
      Divider(color: c.border, height: 24),
      _metricRow(row2, c),
    ]);
  }

  Widget _tab(String label, bool active, AppColors c) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: active ? c.textPrimary : Colors.transparent, borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: TextStyle(color: active ? c.bg : c.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _metricRow(List<(String, String, Color)> items, AppColors c) {
    return Row(children: items.expand((m) sync* {
      if (m != items.first) yield Container(width: 1, height: 48, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 12));
      yield Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(m.$1, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(width: 4),
          _hint(m.$1, c),
        ]),
        const SizedBox(height: 6),
        Text(m.$2, style: TextStyle(color: m.$3, fontSize: 28, fontWeight: FontWeight.w800)),
      ]));
    }).toList());
  }
}

// =============================================================================
// EQUITY CURVE
// =============================================================================

class _EquityCurve extends StatefulWidget {
  const _EquityCurve({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  State<_EquityCurve> createState() => _EquityCurveState();
}

class _EquityCurveState extends State<_EquityCurve> {
  bool _showPct = false;

  List<CumulativePlPoint> _pctPts(List<CumulativePlPoint> raw) {
    if (raw.isEmpty) return raw;
    // Find first non-zero as base; fallback to raw[0].value
    double base = 0;
    for (final p in raw) { if (p.value != 0) { base = p.value; break; } }
    if (base == 0) return raw;
    return raw.map((p) => CumulativePlPoint(date: p.date, value: ((p.value - base) / base.abs()) * 100)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a; final c = widget.c;
    if (a.cumulativePl.length < 2) return const SizedBox.shrink();
    final sourcePts = _showPct ? _pctPts(a.cumulativePl) : a.cumulativePl;
    final last = sourcePts.last.value; final lc = last >= 0 ? c.green : c.red;
    final pts = _ds(sourcePts, 150);
    final valueLabel = _showPct ? '${last >= 0 ? '+' : ''}${last.toStringAsFixed(2)}%' : _fmtD(last);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_T.of(context).equityCurve, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const Spacer(),
        // Toggle $ / %
        GestureDetector(
          onTap: () => setState(() => _showPct = !_showPct),
          child: Container(
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _toggleBtn('\$', !_showPct, c),
              _toggleBtn('%', _showPct, c),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_T.of(context).currentValue, style: TextStyle(color: c.textSecondary, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(valueLabel, style: TextStyle(color: lc, fontSize: 24, fontWeight: FontWeight.w800)),
        ]),
      ]),
      const Spacer(),
      RepaintBoundary(child: SizedBox(height: 100, width: double.infinity, child: CustomPaint(painter: _EqP(pts: pts, lc: lc, fc: lc.withOpacity(0.1), gc: c.border)))),
    ]);
  }

  Widget _toggleBtn(String label, bool active, AppColors c) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: active ? c.textPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(label, style: TextStyle(
      color: active ? c.bg : c.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    )),
  );
}

class _EqP extends CustomPainter {
  _EqP({required this.pts, required this.lc, required this.fc, required this.gc});
  final List<CumulativePlPoint> pts; final Color lc, fc, gc;
  @override void paint(Canvas canvas, Size s) {
    if (pts.length < 2) return;
    final vs = pts.map((p) => p.value).toList(); final mn = vs.reduce(math.min), mx = vs.reduce(math.max); final r = mx - mn; if (r == 0) return;
    if (mn < 0 && mx > 0) { final zy = s.height - ((0 - mn) / r) * s.height; canvas.drawLine(Offset(0, zy), Offset(s.width, zy), Paint()..color = gc..strokeWidth = 0.5); }
    final path = Path(), fill = Path();
    for (var i = 0; i < pts.length; i++) { final x = (i / (pts.length - 1)) * s.width, y = s.height - ((pts[i].value - mn) / r) * s.height;
      if (i == 0) { path.moveTo(x, y); fill..moveTo(x, s.height)..lineTo(x, y); } else { path.lineTo(x, y); fill.lineTo(x, y); } }
    fill..lineTo(s.width, s.height)..close();
    canvas..drawPath(fill, Paint()..color = fc..style = PaintingStyle.fill)..drawPath(path, Paint()..color = lc..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round);
  }
  @override bool shouldRepaint(covariant _EqP o) => pts.length != o.pts.length;
}
List<CumulativePlPoint> _ds(List<CumulativePlPoint> p, int m) { if (p.length <= m) return p; final s = p.length / m; return List.generate(m, (i) => p[(i * s).floor()]); }

// =============================================================================
// WIN RATE
// =============================================================================

class _WinRate extends StatelessWidget {
  const _WinRate({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(_T.of(context).winRate, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
    const Spacer(),
    Center(child: SizedBox(width: 130, height: 130, child: Stack(alignment: Alignment.center, children: [
      SizedBox.expand(child: CircularProgressIndicator(value: a.winRate / 100, strokeWidth: 10, backgroundColor: c.border, color: c.green)),
      Text('${a.winRate.toStringAsFixed(0)}%', style: TextStyle(color: c.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
    ]))),
    const Spacer(),
    Builder(builder: (ctx) { final t = _T.of(ctx); return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _leg(c.green, '${a.winCount} ${t.wins}'), const SizedBox(width: 20), _leg(c.red, '${a.lossCount} ${t.losses}'),
    ]); }),
  ]);
  Widget _leg(Color cl, String t) => Row(children: [
    Container(width: 20, height: 3, decoration: BoxDecoration(color: cl, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 6),
    Text(t, style: TextStyle(color: c.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
  ]);
}

// =============================================================================
// STREAKS
// =============================================================================

class _Streaks extends StatelessWidget {
  const _Streaks({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(_T.of(context).streaks, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
    const SizedBox(height: 16),
    Builder(builder: (ctx) { final t = _T.of(ctx); return Row(children: [
      Expanded(child: _box(t.winStreak, '${a.maxWinStreak}', c.green, Icons.trending_up)),
      const SizedBox(width: 10),
      Expanded(child: _box(t.lossStreak, '${a.maxLossStreak}', c.red, Icons.trending_down)),
    ]); }),
    const Spacer(),
    Builder(builder: (ctx) { final t = _T.of(ctx); return Column(children: [
      if (a.bestDay != null) _day('${t.bestDay}: ${DateFormat('MMM dd').format(a.bestDay!.date).toUpperCase()}', a.bestDay!, c.green),
      if (a.worstDay != null) _day('${t.worstDay}: ${DateFormat('MMM dd').format(a.worstDay!.date).toUpperCase()}', a.worstDay!, c.red),
    ]); }),
  ]);
  Widget _box(String l, String v, Color cl, IconData ic) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: cl.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: cl.withOpacity(0.12))),
    child: Row(children: [
      Icon(ic, color: cl, size: 20), const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(v, style: TextStyle(color: cl, fontSize: 26, fontWeight: FontWeight.w800)),
      ]),
    ]),
  );
  Widget _day(String l, DayPl d, Color cl) { final sign = d.totalPl >= 0 ? '+' : '';
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
      Text(l, style: TextStyle(color: c.textSecondary, fontSize: 11)),
      const Spacer(),
      Text('$sign\$${d.totalPl.toStringAsFixed(2)}', style: TextStyle(color: cl, fontSize: 13, fontWeight: FontWeight.w700)),
    ])); }
}

// =============================================================================
// TOP TICKERS
// =============================================================================

class _TopTickers extends StatefulWidget {
  const _TopTickers({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  State<_TopTickers> createState() => _TopTickersState();
}

class _TopTickersState extends State<_TopTickers> {
  bool _showPct = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.a; final c = widget.c;
    final sorted = a.tickerPl.entries.toList()..sort((x, y) => y.value.totalPl.compareTo(x.value.totalPl));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_T.of(context).topTickers, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _showPct = !_showPct),
          child: Container(
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _tab('\$', !_showPct, c),
              _tab('%', _showPct, c),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Expanded(child: ListView.separated(
        itemCount: sorted.length,
        separatorBuilder: (_, __) => Divider(color: c.border, height: 16),
        itemBuilder: (_, i) {
          final e = sorted[i];
          final stats = e.value;
          final value = _showPct ? (stats.tradeCount > 0 ? stats.totalPl / stats.tradeCount : 0.0) : stats.totalPl;
          final cl = value >= 0 ? c.green : c.red;
          final sign = value >= 0 ? '+' : '';
          final label = _showPct ? '$sign\$${_fmt(value)}${_T.of(context).perTrade}' : '$sign\$${_fmt(value)}';
          return Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: c.border.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(e.key.length > 4 ? e.key.substring(0, 4) : e.key, style: TextStyle(color: c.textPrimary, fontSize: 10, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.key, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${stats.tradeCount} ${_T.of(context).trades.toUpperCase()}', style: TextStyle(color: c.textSecondary, fontSize: 9, letterSpacing: 0.3)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(label, style: TextStyle(color: cl, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${stats.winRate.toStringAsFixed(0)}% ${_T.of(context).wins}', style: TextStyle(color: c.green, fontSize: 10)),
            ]),
          ]);
        },
      )),
    ]);
  }

  Widget _tab(String label, bool active, AppColors c) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: active ? c.textPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(label, style: TextStyle(color: active ? c.bg : c.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

// =============================================================================
// LONG VS SHORT
// =============================================================================

class _SideAnalysis extends StatelessWidget {
  const _SideAnalysis({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) {
    if (a.sidePl.isEmpty) return const SizedBox.shrink();
    final total = a.sidePl.values.fold<int>(0, (s, v) => s + v.tradeCount);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_T.of(context).longVsShort, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const Spacer(),
      ...a.sidePl.entries.map((e) { final isL = e.key == 'Long'; final cl = isL ? c.green : c.red; final s = e.value; final pct = total > 0 ? (s.tradeCount / total * 100).toStringAsFixed(0) : '0'; final sign = s.totalPl >= 0 ? '+' : '';
        return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isL ? Icons.trending_up : Icons.trending_down, color: cl, size: 16), const SizedBox(width: 8),
            Text('${e.key.toUpperCase()} ${_T.of(context).positions}', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$sign\$${_fmt(s.totalPl)} ($pct%)', style: TextStyle(color: cl, fontSize: 13, fontWeight: FontWeight.w700)),
              Builder(builder: (ctx) { final avgSign = s.averagePl >= 0 ? '+' : ''; final t = _T.of(ctx); return Text('${t.avg} $avgSign\$${_fmt(s.averagePl)}${t.perTrade}', style: TextStyle(color: cl.withValues(alpha: 0.7), fontSize: 10)); }),
            ]),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: total > 0 ? s.tradeCount / total : 0, minHeight: 6, backgroundColor: c.border, color: cl)),
        ]));
      }),
    ]);
  }
}

// =============================================================================
// WEEKDAY
// =============================================================================

class _WeekdayChart extends StatefulWidget {
  const _WeekdayChart({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  State<_WeekdayChart> createState() => _WeekdayChartState();
}

class _WeekdayChartState extends State<_WeekdayChart> {
  bool _showPct = false;
  static const _l = {1:'MON',2:'TUE',3:'WED',4:'THU',5:'FRI'};

  Widget _tab(String label, bool active, AppColors c) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: active ? c.textPrimary : Colors.transparent, borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: TextStyle(color: active ? c.bg : c.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  @override
  Widget build(BuildContext context) {
    final a = widget.a; final c = widget.c;
    final wd = a.weekdayPl; if (wd.isEmpty) return const SizedBox.shrink();
    final maxA = wd.values.map((s) => (_showPct ? s.averagePl.abs() : s.totalPl.abs())).fold<double>(0, math.max);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_T.of(context).plByWeekday, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _showPct = !_showPct),
          child: Container(
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _tab('\$', !_showPct, c),
              _tab('%', _showPct, c),
            ]),
          ),
        ),
      ]),
      const Spacer(),
      SizedBox(height: 140, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _l.entries.map((e) {
        final s = wd[e.key];
        final pl = _showPct ? (s?.averagePl ?? 0) : (s?.totalPl ?? 0);
        final ratio = maxA > 0 ? (pl.abs() / maxA).clamp(0.08, 1.0) : 0.08; final cl = pl >= 0 ? c.green : c.red;
        return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Builder(builder: (ctx) { final label = _showPct ? '${_fmtK(pl)}${_T.of(ctx).perTrade}' : _fmtK(pl); return Text(label, style: TextStyle(color: cl, fontSize: 11, fontWeight: FontWeight.w700)); }),
          const SizedBox(height: 5),
          Container(height: 95 * ratio, decoration: BoxDecoration(color: cl.withOpacity(0.25), borderRadius: BorderRadius.circular(5))),
          const SizedBox(height: 8),
          Text(e.value, style: TextStyle(color: c.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ])));
      }).toList())),
    ]);
  }
}

// =============================================================================
// HOURLY HEATMAP
// =============================================================================

class _HourlyHeatmap extends StatelessWidget {
  const _HourlyHeatmap({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) {
    final h = a.hourlyPl; if (h.isEmpty) return const SizedBox.shrink();
    final maxA = h.values.map((v) => v.abs()).fold<double>(0, math.max);
    final hours = h.keys.toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_T.of(context).plByHour, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 14),
      Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: hours.map((hr) {
        final pl = h[hr] ?? 0; final intensity = maxA > 0 ? (pl.abs() / maxA).clamp(0.1, 1.0) : 0.1; final bc = pl >= 0 ? c.green : c.red;
        return Container(width: 64, height: 44, decoration: BoxDecoration(color: bc.withOpacity(intensity * 0.2), borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${hr.toString().padLeft(2, '0')}:00', style: TextStyle(color: c.textSecondary, fontSize: 9)),
            Text(_fmtK(pl), style: TextStyle(color: bc, fontSize: 10, fontWeight: FontWeight.w700)),
          ]));
      }).toList())),
      const SizedBox(height: 6),
      Builder(builder: (ctx) => Text(_T.of(ctx).afterHoursRestricted, style: TextStyle(color: c.textSecondary.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.w500, letterSpacing: 0.5))),
    ]);
  }
}

// =============================================================================
// CALENDAR
// =============================================================================

class _Calendar extends StatefulWidget {
  const _Calendar({required this.a, required this.c, required this.orders});
  final TradingAnalyticsEntity a; final AppColors c;
  final List<TradingOrderDto> orders;
  @override State<_Calendar> createState() => _CalendarS();
}

class _CalendarS extends State<_Calendar> {
  late DateTime _m;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final cal = widget.a.calendarPl;
    _m = cal.isNotEmpty
        ? (() { final l = cal.keys.reduce((a, b) => a.isAfter(b) ? a : b); return DateTime(l.year, l.month); })()
        : DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  void didUpdateWidget(covariant _Calendar o) {
    super.didUpdateWidget(o);
    if (widget.a.calendarPl.isNotEmpty && widget.a.calendarPl != o.a.calendarPl) {
      final l = widget.a.calendarPl.keys.reduce((a, b) => a.isAfter(b) ? a : b);
      final nm = DateTime(l.year, l.month);
      if (_m.year != nm.year || _m.month != nm.month) setState(() => _m = nm);
    }
  }

  List<TradingOrderDto> _ordersForDay(DateTime date) {
    return widget.orders.where((o) {
      final raw = o.filledAt.isNotEmpty ? o.filledAt : o.createdAt;
      final dt = DateTime.tryParse(raw);
      if (dt == null) return false;
      return dt.year == date.year && dt.month == date.month && dt.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c; final y = _m.year, mo = _m.month;

    // If day selected — show drill-down
    if (_selectedDay != null) {
      final dayOrders = _ordersForDay(_selectedDay!);
      return _DayDrillDown(
        date: _selectedDay!,
        orders: dayOrders,
        pl: widget.a.calendarPl[DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)],
        c: c,
        onBack: () => setState(() => _selectedDay = null),
      );
    }

    final days = DateUtils.getDaysInMonth(y, mo);
    final offset = DateTime(y, mo).weekday % 7;
    final prevDays = DateUtils.getDaysInMonth(mo == 1 ? y - 1 : y, mo == 1 ? 12 : mo - 1);
    final cells = <(int, bool)>[];
    for (var i = offset - 1; i >= 0; i--) cells.add((prevDays - i, false));
    for (var d = 1; d <= days; d++) cells.add((d, true));
    while (cells.length % 7 != 0) cells.add((cells.length - offset - days + 1, false));
    final weeks = <List<(int, bool)>>[];
    for (var i = 0; i < cells.length; i += 7) weeks.add(cells.sublist(i, i + 7));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(DateFormat('MMMM yyyy').format(_m).toUpperCase(), style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const Spacer(),
        GestureDetector(onTap: () => setState(() => _m = DateTime(y, mo - 1)), child: MouseRegion(cursor: SystemMouseCursors.click, child: Icon(Icons.chevron_left, size: 18, color: c.textSecondary))),
        const SizedBox(width: 4),
        GestureDetector(onTap: () => setState(() => _m = DateTime(y, mo + 1)), child: MouseRegion(cursor: SystemMouseCursors.click, child: Icon(Icons.chevron_right, size: 18, color: c.textSecondary))),
      ]),
      const SizedBox(height: 12),
      Row(children: ['SU','MO','TU','WE','TH','FR','SA'].map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: c.textSecondary.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w600))))).toList()),
      const SizedBox(height: 6),
      Expanded(child: Column(children: weeks.map((week) => Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: week.map((cell) {
        final day = cell.$1; final cur = cell.$2;
        if (!cur) {
          return Expanded(child: Container(margin: const EdgeInsets.all(1),
            child: Align(alignment: Alignment.topCenter, child: Padding(padding: const EdgeInsets.only(top: 4),
              child: Text('$day', style: TextStyle(color: c.textSecondary.withValues(alpha: 0.2), fontSize: 10))))));
        }
        final date = DateTime.utc(y, mo, day);
        final pl = widget.a.calendarPl[date];
        final hasPl = pl != null;
        final hasOrders = _ordersForDay(DateTime(y, mo, day)).isNotEmpty;
        Color? bg; Color? border;
        if (hasPl) {
          bg = pl > 0 ? c.green.withValues(alpha: 0.12) : c.red.withValues(alpha: 0.12);
          border = pl > 0 ? c.green.withValues(alpha: 0.25) : c.red.withValues(alpha: 0.25);
        }
        return Expanded(child: GestureDetector(
          onTap: hasOrders ? () => setState(() => _selectedDay = DateTime(y, mo, day)) : null,
          child: MouseRegion(
            cursor: hasOrders ? SystemMouseCursors.click : MouseCursor.defer,
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: border != null ? Border.all(color: border, width: 0.5) : null,
              ),
              child: Column(children: [
                const SizedBox(height: 4),
                Text('$day', style: TextStyle(color: hasPl ? c.textPrimary : c.textSecondary.withValues(alpha: 0.3), fontSize: hasPl ? 14 : 10, fontWeight: hasPl ? FontWeight.w700 : FontWeight.normal)),
                if (hasPl) ...[
                  const Spacer(),
                  Text(_fmtK(pl), style: TextStyle(color: pl >= 0 ? c.green : c.red, fontSize: 9, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                ],
              ]),
            ),
          ),
        ));
      }).toList()))).toList())),
    ]);
  }
}

// =============================================================================
// DAY DRILL-DOWN
// =============================================================================

class _DayDrillDown extends StatelessWidget {
  const _DayDrillDown({required this.date, required this.orders, required this.pl, required this.c, required this.onBack});
  final DateTime date;
  final List<TradingOrderDto> orders;
  final double? pl;
  final AppColors c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final totalPl = orders.fold<double>(0, (s, o) => s + (o.profitCash ?? 0));
    final wins = orders.where((o) => (o.profitCash ?? 0) > 0).length;
    final losses = orders.where((o) => (o.profitCash ?? 0) < 0).length;
    final plC = totalPl >= 0 ? c.green : c.red;
    final sign = totalPl >= 0 ? '+' : '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header with back button
      Row(children: [
        GestureDetector(
          onTap: onBack,
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Row(children: [
            Icon(Icons.chevron_left, size: 16, color: c.textSecondary),
            Text(_T.of(context).back, style: TextStyle(color: c.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          ])),
        ),
        const SizedBox(width: 12),
        Text(DateFormat('EEE, MMM d yyyy').format(date).toUpperCase(), style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
      const SizedBox(height: 12),
      // Day summary strip
      Row(children: [
        _statChip('P/L', '$sign\$${_fmt(totalPl)}', plC),
        const SizedBox(width: 8),
        _statChip('TRADES', '${orders.length}', c.textPrimary),
        const SizedBox(width: 8),
        _statChip('WINS', '$wins', c.green),
        const SizedBox(width: 8),
        _statChip('LOSSES', '$losses', c.red),
      ]),
      const SizedBox(height: 10),
      Divider(color: c.border, height: 1),
      const SizedBox(height: 8),
      // Orders list
      Expanded(child: orders.isEmpty
        ? Center(child: Text(_T.of(context).noTradesThisDay, style: TextStyle(color: c.textSecondary, fontSize: 12)))
        : ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => Divider(color: c.border, height: 1),
            itemBuilder: (_, i) {
              final o = orders[i];
              final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
              final time = dt != null ? DateFormat('HH:mm:ss').format(dt) : '-';
              final isBuy = o.side.toLowerCase() == 'buy';
              final sideC = isBuy ? c.green : c.red;
              final hasPl = o.profitCash != null;
              final oPlC = hasPl ? (o.profitCash! >= 0 ? c.green : c.red) : c.textSecondary;
              final oSign = hasPl && o.profitCash! >= 0 ? '+' : '';
              return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
                // Time
                SizedBox(width: 52, child: Text(time, style: TextStyle(color: c.textSecondary, fontSize: 10))),
                // Symbol + side badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: sideC.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(o.side.toUpperCase(), style: TextStyle(color: sideC, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text(o.symbol, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text('×${o.filledQty.toStringAsFixed(0)}', style: TextStyle(color: c.textSecondary, fontSize: 10)),
                const Spacer(),
                // Price
                Text('\$${o.filledAvgPrice.toStringAsFixed(2)}', style: TextStyle(color: c.textSecondary, fontSize: 10)),
                const SizedBox(width: 10),
                // P/L
                if (hasPl) ...[
                  Text('$oSign\$${_fmt(o.profitCash!)}', style: TextStyle(color: oPlC, fontSize: 12, fontWeight: FontWeight.w700)),
                  if (o.profitPerc != null) ...[
                    const SizedBox(width: 4),
                    Text('${o.profitPerc! >= 0 ? '+' : ''}${o.profitPerc!.toStringAsFixed(1)}%', style: TextStyle(color: oPlC.withValues(alpha: 0.7), fontSize: 10)),
                  ],
                ] else
                  Text('-', style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ]));
            },
          ),
      ),
    ]);
  }

  Widget _statChip(String label, String value, Color vc) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(color: vc.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
    child: Column(children: [
      Text(label, style: TextStyle(color: c.textSecondary, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: vc, fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
  ));
}

// =============================================================================
// MONTHLY SUMMARY
// =============================================================================

class _MonthlyTable extends StatelessWidget {
  const _MonthlyTable({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) {
    final m = a.monthlySummary; if (m.isEmpty) return const SizedBox.shrink();
    final hdr = TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_T.of(context).monthlySummary, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 14),
      Builder(builder: (ctx) { final t = _T.of(ctx); return Row(children: [
        SizedBox(width: 60, child: Text(t.month, style: hdr)),
        Expanded(child: Text(t.plDollar, style: hdr)),
        SizedBox(width: 64, child: Text(t.avgPerTrade, style: hdr, textAlign: TextAlign.right)),
        SizedBox(width: 36, child: Text(t.winPct, style: hdr, textAlign: TextAlign.right)),
        SizedBox(width: 28, child: Text('#', style: hdr, textAlign: TextAlign.right)),
      ]); }),
      Divider(color: c.border, height: 16),
      ...m.entries.take(6).map((e) {
        final s = e.value;
        final cl = s.totalPl >= 0 ? c.green : c.red;
        final sign = s.totalPl >= 0 ? '+' : '';
        final avg = s.tradeCount > 0 ? s.totalPl / s.tradeCount : 0.0;
        final avgCl = avg >= 0 ? c.green : c.red;
        final avgSign = avg >= 0 ? '+' : '';
        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          SizedBox(width: 60, child: Text(e.key, style: TextStyle(color: c.textPrimary, fontSize: 11))),
          Expanded(child: Text('$sign\$${_fmt(s.totalPl)}', style: TextStyle(color: cl, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 64, child: Text('$avgSign\$${_fmt(avg)}', style: TextStyle(color: avgCl, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          SizedBox(width: 36, child: Text('${s.winRate.toStringAsFixed(0)}%', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 28, child: Text('${s.tradeCount}', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
        ]));
      }),
    ]);
  }
}

// =============================================================================
// AVG HOLD TIME
// =============================================================================

class _HoldTime extends StatelessWidget {
  const _HoldTime({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.timer_outlined, size: 14, color: c.textSecondary),
        const SizedBox(width: 6),
        Text(t.avgHoldTime, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ]),
      const SizedBox(height: 4),
      Text(t.avgHoldTimeDesc, style: TextStyle(color: c.textSecondary.withValues(alpha: 0.5), fontSize: 10)),
      const SizedBox(height: 20),
      _row(t.overall, a.avgHoldTimeMinutes, c.textPrimary),
      const SizedBox(height: 16),
      _row(t.winsOnly, a.avgHoldTimeWinMinutes, c.green),
      const SizedBox(height: 16),
      _row(t.lossesOnly, a.avgHoldTimeLossMinutes, c.red),
    ]);
  }
  Widget _row(String l, double m, Color cl) => Row(children: [
    Expanded(child: Text(l, style: TextStyle(color: c.textSecondary, fontSize: 11, letterSpacing: 0.3))),
    Text(_fmtH(m), style: TextStyle(color: cl, fontSize: 24, fontWeight: FontWeight.w800)),
  ]);
  String _fmtH(double m) { if (m <= 0) return '-'; if (m < 60) return '${m.toStringAsFixed(0)}m'; final h = m / 60; if (h < 24) return '${h.toStringAsFixed(1)}h'; return '${(h / 24).toStringAsFixed(1)}d'; }
}

// =============================================================================
// POSITION SIZE
// =============================================================================

class _TradeSize extends StatelessWidget {
  const _TradeSize({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  static const _order = ['1', '2-5', '6-10', '11-50', '51-100', '100+'];
  @override
  Widget build(BuildContext context) {
    final b = a.tradeSizeBuckets; if (b.isEmpty) return const SizedBox.shrink();
    final hdr = TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_T.of(context).plByPositionSize, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 14),
      Builder(builder: (ctx) { final t = _T.of(ctx); return Row(children: [
        SizedBox(width: 80, child: Text(t.sizeRange, style: hdr)),
        Expanded(child: Text(t.plDollar, style: hdr)),
        SizedBox(width: 72, child: Text(t.avgPerTrade, style: hdr, textAlign: TextAlign.right)),
        SizedBox(width: 40, child: Text(t.winPct, style: hdr, textAlign: TextAlign.right)),
        SizedBox(width: 44, child: Text(t.trades.toUpperCase(), style: hdr, textAlign: TextAlign.right)),
      ]); }),
      Divider(color: c.border, height: 16),
      ..._order.where(b.containsKey).map((l) {
        final s = b[l]!;
        final cl = s.totalPl >= 0 ? c.green : c.red;
        final sign = s.totalPl >= 0 ? '+' : '';
        final avg = s.averagePl;
        final avgCl = avg >= 0 ? c.green : c.red;
        final avgSign = avg >= 0 ? '+' : '';
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          SizedBox(width: 80, child: Text(l, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(child: Text('$sign\$${_fmt(s.totalPl)}', style: TextStyle(color: cl, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 72, child: Text('$avgSign\$${_fmt(avg)}', style: TextStyle(color: avgCl, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          SizedBox(width: 40, child: Text('${s.winRate.toStringAsFixed(0)}%', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 44, child: Text('${s.tradeCount}', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
        ]));
      }),
    ]);
  }
}

// =============================================================================
// R/R DISTRIBUTION
// =============================================================================

class _RrDist extends StatelessWidget {
  const _RrDist({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  static const _order = ['Loss', '<0.5R', '0.5-1R', '1-2R', '2-3R', '3R+'];
  @override
  Widget build(BuildContext context) {
    final rr = a.rrDistribution; if (rr.isEmpty) return const SizedBox.shrink();
    final maxC = rr.values.fold<int>(0, math.max);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_T.of(context).rrDistribution, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 14),
      ..._order.map((l) { final cnt = rr[l] ?? 0; final ratio = maxC > 0 ? (cnt / maxC).clamp(0.02, 1.0) : 0.02; final isLoss = l == 'Loss'; final bc = isLoss ? c.red : c.green;
        return Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [
          SizedBox(width: 42, child: Text(l, style: TextStyle(color: c.textSecondary, fontSize: 10))),
          const SizedBox(width: 8),
          Expanded(child: LayoutBuilder(builder: (_, box) => Align(alignment: Alignment.centerLeft, child: Container(height: 18, width: box.maxWidth * ratio, decoration: BoxDecoration(color: bc.withOpacity(0.15), borderRadius: BorderRadius.circular(4)))))),
          const SizedBox(width: 8),
          SizedBox(width: 28, child: Text('$cnt', style: TextStyle(color: bc, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ]));
      }),
    ]);
  }
}

// =============================================================================
// LOGIN
// =============================================================================

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.emailCtrl, required this.passwordCtrl});
  final TextEditingController emailCtrl, passwordCtrl;
  @override State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _showLogin = false;
  bool _obscurePassword = true;

  Future<void> _onDemo() async {
    // Collect lead before demo.
    final hasLead = await LeadService.hasLead();
    if (!hasLead && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _TradingLeadDialog(),
      );
      if (ok != true || !mounted) return;
    }
    if (mounted) context.read<TradingAnalyticsCubit>().loadDemo();
  }

  void _onLogin() {
    final e = widget.emailCtrl.text.trim();
    final p = widget.passwordCtrl.text.trim();
    if (e.isEmpty || p.isEmpty) return;
    context.read<TradingAnalyticsCubit>().loginAndLoad(e, p);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;

    return BlocBuilder<TradingAnalyticsCubit, TradingAnalyticsState>(
      builder: (context, state) => Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/svg/ic_logo.svg', height: 40),
                  const SizedBox(height: 16),
                  Text(_T.of(context).tradingAnalytics, style: TextStyle(color: c.textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 32),

                  // Demo button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _onDemo,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(s.tradingDemoButton, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: c.border)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(s.tradingOrDivider, style: TextStyle(color: c.textSecondary, fontSize: 13))),
                    Expanded(child: Divider(color: c.border)),
                  ]),
                  const SizedBox(height: 24),

                  if (!_showLogin) ...[
                    // Already client
                    Text(s.tradingAlreadyClient, style: TextStyle(color: c.textSecondary, fontSize: 14)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showLogin = true),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(s.tradingSignIn, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else ...[
                    // Login fields
                    TextField(controller: widget.emailCtrl, decoration: InputDecoration(hintText: s.leadEmail, prefixIcon: Icon(Icons.email_outlined, color: c.textSecondary, size: 18))),
                    const SizedBox(height: 12),
                    TextField(controller: widget.passwordCtrl, obscureText: _obscurePassword, onSubmitted: (_) => _onLogin(), decoration: InputDecoration(hintText: s.tradingPassword, prefixIcon: Icon(Icons.lock_outlined, color: c.textSecondary, size: 18), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: c.textSecondary, size: 18), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: _onLogin, child: Text(state.hasSavedCredentials ? _T.of(context).quickSignIn : s.tradingSignIn))),
                    if (state.hasSavedCredentials) ...[const SizedBox(height: 8), Text('${_T.of(context).saved}: ${state.savedEmail}', style: TextStyle(color: c.textSecondary, fontSize: 12))],
                  ],

                  const SizedBox(height: 32),

                  // Open account CTA
                  Text(s.tradingNoAccount, style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openUrl(AppThemeScope.of(context).strings.investlinkUrl),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.green.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: c.green.withOpacity(0.06),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.open_in_new_rounded, size: 16, color: c.green),
                          const SizedBox(width: 8),
                          Text(s.tradingOpenAccount, style: TextStyle(color: c.green, fontSize: 14, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ERROR
// =============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override Widget build(BuildContext context) { final c = AppThemeScope.of(context).colors;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, size: 48, color: c.red), const SizedBox(height: 16),
      Text(_T.of(context).errorTitle, style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      Text(message, style: TextStyle(color: c.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 24),
      ElevatedButton(onPressed: () => context.read<TradingAnalyticsCubit>().logout(), child: Text(_T.of(context).errorBack)),
    ]));
  }
}

// =============================================================================
// PORTFOLIO PAGE
// =============================================================================

class _PortfolioPage extends StatefulWidget {
  const _PortfolioPage({required this.c, required this.state});
  final AppColors c; final TradingAnalyticsState state;
  @override
  State<_PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<_PortfolioPage> {
  bool _plInPct = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final state = widget.state;
    if (state.positionsLoading) return Center(child: CircularProgressIndicator(color: c.green));
    final pos = state.positions;
    if (pos.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.account_balance_wallet_outlined, size: 48, color: c.textSecondary), const SizedBox(height: 12),
      Text(_T.of(context).noOpenPositions, style: TextStyle(color: c.textSecondary, fontSize: 16)),
      const SizedBox(height: 8),
      GestureDetector(onTap: () => context.read<TradingAnalyticsCubit>().loadPositions(),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: Text(_T.of(context).refresh, style: TextStyle(color: c.green, fontSize: 13)))),
    ]));

    final totalValue = pos.fold<double>(0, (s, p) => s + p.marketValue);
    final totalPl = pos.fold<double>(0, (s, p) => s + p.profitCash);
    // Cost basis = marketValue - unrealizedPl per position.
    final totalCost = pos.fold<double>(0, (s, p) => s + (p.marketValue - p.profitCash));
    final totalPlPct = totalCost != 0 ? (totalPl / totalCost.abs()) * 100 : 0.0;
    final sparks = state.sparklines;

    final plColor = totalPl >= 0 ? c.green : c.red;
    final plSign = totalPl >= 0 ? '+' : '';
    final plLabel = _plInPct
        ? '$plSign${totalPlPct.toStringAsFixed(2)}%'
        : _fmtD(totalPl);

    return ListView(padding: const EdgeInsets.all(20), children: [
      // Summary row.
      Row(children: [
        _summaryCard(_T.of(context).totalValue, '\$${_fmt(totalValue)}', c.textPrimary, null, c),
        const SizedBox(width: 12),
        _summaryCard('TOTAL P/L', plLabel, plColor, _plInPct, c),
        const SizedBox(width: 12),
        _summaryCard(_T.of(context).positions, '${pos.length}', c.textPrimary, null, c),
        const SizedBox(width: 12),
        // Export button.
        GestureDetector(
          onTap: () => _exportCsv(pos),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.download_rounded, size: 16, color: c.green),
              const SizedBox(width: 8),
              Text(_T.of(context).exportExcel, style: TextStyle(color: c.green, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ]),
          )),
        ),
      ]),
      const SizedBox(height: 20),
      // Table.
      Container(
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
        child: Column(children: [
          // Header.
          Builder(builder: (ctx) { final t = _T.of(ctx); return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
            SizedBox(width: 90, child: Text(t.symbol, style: _hdr)),
            SizedBox(width: 70, child: Text(t.chart30d, style: _hdr)),
            Expanded(child: Text(t.qty, style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text(t.avgPrice, style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text(t.current, style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text(t.mktValue, style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text(t.plDollar, style: _hdr, textAlign: TextAlign.right)),
            SizedBox(width: 60, child: Text(t.plPercent, style: _hdr, textAlign: TextAlign.right)),
          ])); }),
          Divider(color: c.border, height: 1),
          // Rows.
          ...pos.map((p) { final plC = p.profitCash >= 0 ? c.green : c.red; final sign = p.profitCash >= 0 ? '+' : '';
            final spark = sparks[p.symbol];
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Row(children: [
              SizedBox(width: 90, child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: c.border.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text(p.symbol.length > 3 ? p.symbol.substring(0, 3) : p.symbol, style: TextStyle(color: c.textPrimary, fontSize: 8, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 8),
                Expanded(child: Text(p.symbol, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ])),
              // Sparkline.
              SizedBox(width: 70, height: 28, child: spark != null && spark.length >= 2
                ? CustomPaint(painter: _SparkPainter(data: spark, color: p.profitCash >= 0 ? c.green : c.red))
                : Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.textSecondary.withOpacity(0.3))))),
              Expanded(child: Text('${p.qty.toStringAsFixed(p.qty == p.qty.roundToDouble() ? 0 : 2)}', style: TextStyle(color: c.textPrimary, fontSize: 12), textAlign: TextAlign.right)),
              Expanded(child: Text('\$${p.avgEntryPrice.toStringAsFixed(2)}', style: TextStyle(color: c.textSecondary, fontSize: 12), textAlign: TextAlign.right)),
              Expanded(child: Text('\$${p.currentPrice.toStringAsFixed(2)}', style: TextStyle(color: c.textPrimary, fontSize: 12), textAlign: TextAlign.right)),
              Expanded(child: Text('\$${_fmt(p.marketValue)}', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(child: Text('$sign\$${_fmt(p.profitCash)}', style: TextStyle(color: plC, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              SizedBox(width: 60, child: Text('$sign${p.profitPercent.toStringAsFixed(1)}%', style: TextStyle(color: plC, fontSize: 11), textAlign: TextAlign.right)),
            ]));
          }),
        ]),
      ),
    ]);
  }

  // bool? togglePl — если не null, карточка P/L с переключателем $ / %
  Widget _summaryCard(String label, String value, Color vc, bool? togglePl, AppColors c) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        if (togglePl != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _plInPct = !_plInPct),
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _plToggleBtn('\$', !_plInPct, c),
                _plToggleBtn('%', _plInPct, c),
              ]),
            )),
          ),
        ],
      ]),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: vc, fontSize: 22, fontWeight: FontWeight.w800)),
    ]),
  ));

  Widget _plToggleBtn(String label, bool active, AppColors c) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: active ? c.textPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(
      color: active ? c.bg : c.textSecondary,
      fontSize: 9,
      fontWeight: FontWeight.w700,
    )),
  );

  static void _exportCsv(List<TradingPositionDto> pos) {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Portfolio'];
    excel.delete('Sheet1');

    // ── Styles ──
    final headerStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#0A0A0A'),
      horizontalAlign: xl.HorizontalAlign.Center,
    );
    final totalStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString('#0A0A0A'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#F0F0F0'),
    );
    xl.CellStyle plStyle(double v) => xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString(v >= 0 ? '#00A878' : '#E63946'),
    );

    // ── Title ──
    sheet.merge(xl.CellIndex.indexByString('A1'), xl.CellIndex.indexByString('G1'));
    final title = sheet.cell(xl.CellIndex.indexByString('A1'));
    title.value = xl.TextCellValue('Portfolio — ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}');
    title.cellStyle = xl.CellStyle(bold: true, fontSize: 13, fontColorHex: xl.ExcelColor.fromHexString('#0A0A0A'));
    sheet.setRowHeight(0, 28);

    // ── Headers ──
    const headers = ['Symbol', 'Qty', 'Avg Price', 'Current Price', 'Mkt Value', 'P/L \$', 'P/L %'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = xl.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 22);

    // ── Data rows ──
    double totalMktValue = 0, totalPl = 0;
    for (var r = 0; r < pos.length; r++) {
      final p = pos[r];
      totalMktValue += p.marketValue;
      totalPl += p.profitCash;
      final row = r + 2;
      final rowBg = xl.CellStyle(backgroundColorHex: xl.ExcelColor.fromHexString(r.isEven ? '#FAFAFA' : '#FFFFFF'));
      void setCell(int col, xl.CellValue val, [xl.CellStyle? style]) {
        final c = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        c.value = val;
        c.cellStyle = style ?? rowBg;
      }
      setCell(0, xl.TextCellValue(p.symbol), xl.CellStyle(bold: true, backgroundColorHex: xl.ExcelColor.fromHexString(r.isEven ? '#FAFAFA' : '#FFFFFF')));
      setCell(1, xl.DoubleCellValue(p.qty));
      setCell(2, xl.DoubleCellValue(p.avgEntryPrice));
      setCell(3, xl.DoubleCellValue(p.currentPrice));
      setCell(4, xl.DoubleCellValue(p.marketValue));
      setCell(5, xl.DoubleCellValue(p.profitCash), plStyle(p.profitCash));
      setCell(6, xl.TextCellValue('${p.profitPercent >= 0 ? '+' : ''}${p.profitPercent.toStringAsFixed(2)}%'), plStyle(p.profitPercent));
      sheet.setRowHeight(row, 20);
    }

    // ── Total row ──
    final totalRow = pos.length + 2;
    sheet.merge(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow), xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRow));
    final totalLabel = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow));
    totalLabel.value = xl.TextCellValue('TOTAL (${pos.length} positions)');
    totalLabel.cellStyle = totalStyle;
    final mktCell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow));
    mktCell.value = xl.DoubleCellValue(totalMktValue);
    mktCell.cellStyle = totalStyle;
    final plCell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow));
    plCell.value = xl.DoubleCellValue(totalPl);
    plCell.cellStyle = xl.CellStyle(bold: true, fontColorHex: xl.ExcelColor.fromHexString(totalPl >= 0 ? '#00A878' : '#E63946'), backgroundColorHex: xl.ExcelColor.fromHexString('#F0F0F0'));
    sheet.setRowHeight(totalRow, 22);

    // ── Column widths ──
    sheet.setColumnWidth(0, 12); sheet.setColumnWidth(1, 8); sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 14); sheet.setColumnWidth(4, 14); sheet.setColumnWidth(5, 12); sheet.setColumnWidth(6, 10);

    final bytes = excel.encode()!;
    _downloadXlsx('portfolio_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx', bytes);
  }

  TextStyle get _hdr => TextStyle(color: widget.c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3);
}

// Mini sparkline painter.
class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.data, required this.color});
  final List<double> data; final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final mn = data.reduce(math.min), mx = data.reduce(math.max);
    final r = mx - mn; if (r == 0) return;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - mn) / r) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant _SparkPainter o) => data.length != o.data.length;
}

// =============================================================================
// ORDERS PAGE
// =============================================================================

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.c, required this.state});
  final AppColors c; final TradingAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    if (state.ordersLoading) return Center(child: CircularProgressIndicator(color: c.green));
    final orders = state.recentOrders;
    if (orders.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_rounded, size: 48, color: c.textSecondary), const SizedBox(height: 12),
      Text(_T.of(context).noOrdersFound, style: TextStyle(color: c.textSecondary, fontSize: 16)),
      const SizedBox(height: 8),
      GestureDetector(onTap: () => context.read<TradingAnalyticsCubit>().loadOrders(),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: Text(_T.of(context).refresh, style: TextStyle(color: c.green, fontSize: 13)))),
    ]));

    final hdr = TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3);

    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(children: [
        Text('${orders.length} ${_T.of(context).orders}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
        const Spacer(),
        GestureDetector(
          onTap: () => _exportCsv(orders),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.download_rounded, size: 14, color: c.green),
              const SizedBox(width: 6),
              Text(_T.of(context).exportExcel, style: TextStyle(color: c.green, fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          )),
        ),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Container(
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
        child: Column(children: [
          Builder(builder: (ctx) { final t = _T.of(ctx); return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
            SizedBox(width: 140, child: Text(t.date, style: hdr)),
            SizedBox(width: 70, child: Text(t.symbol, style: hdr)),
            SizedBox(width: 50, child: Text(t.side, style: hdr)),
            Expanded(child: Text(t.qty, style: hdr, textAlign: TextAlign.right)),
            Expanded(child: Text(t.price, style: hdr, textAlign: TextAlign.right)),
            SizedBox(width: 70, child: Text(t.status, style: hdr, textAlign: TextAlign.center)),
            Expanded(child: Text(t.plDollar, style: hdr, textAlign: TextAlign.right)),
            SizedBox(width: 70, child: Text(t.plPercent, style: hdr, textAlign: TextAlign.right)),
          ])); }),
          Divider(color: c.border, height: 1),
          Expanded(child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
              final dateStr = dt != null ? DateFormat('MMM dd, yyyy  HH:mm').format(dt) : '-';
              final sideC = o.side.toLowerCase() == 'buy' ? c.green : c.red;
              final statusC = _statusColor(o.status, c);
              final hasPl = o.profitCash != null;
              final hasPct = o.profitPerc != null;
              final plC = hasPl ? (o.profitCash! >= 0 ? c.green : c.red) : c.textSecondary;
              final pctC = hasPct ? (o.profitPerc! >= 0 ? c.green : c.red) : c.textSecondary;
              final plSign = hasPl && o.profitCash! >= 0 ? '+' : '';
              final pctSign = hasPct && o.profitPerc! >= 0 ? '+' : '';

              return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Row(children: [
                SizedBox(width: 140, child: Text(dateStr, style: TextStyle(color: c.textSecondary, fontSize: 11))),
                SizedBox(width: 70, child: Text(o.symbol, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(width: 50, child: Text(o.side.toUpperCase(), style: TextStyle(color: sideC, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(child: Text(o.filledQty > 0 ? o.filledQty.toStringAsFixed(0) : '-', style: TextStyle(color: c.textPrimary, fontSize: 11), textAlign: TextAlign.right)),
                Expanded(child: Text(o.filledAvgPrice > 0 ? '\$${o.filledAvgPrice.toStringAsFixed(2)}' : '-', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
                SizedBox(width: 70, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusC.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(o.status.toUpperCase(), style: TextStyle(color: statusC, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ))),
                Expanded(child: Text(hasPl ? '$plSign\$${_fmt(o.profitCash!)}' : '-', style: TextStyle(color: plC, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                SizedBox(width: 70, child: Text(hasPct ? '$pctSign${o.profitPerc!.toStringAsFixed(2)}%' : '-', style: TextStyle(color: pctC, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ]));
            },
          )),
        ]),
      )),
    ]));
  }

  static void _exportCsv(List<TradingOrderDto> orders) {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Orders'];
    excel.delete('Sheet1');

    // ── Styles ──
    final headerStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#0A0A0A'),
      horizontalAlign: xl.HorizontalAlign.Center,
    );
    xl.CellStyle plStyle(double v) => xl.CellStyle(bold: true, fontColorHex: xl.ExcelColor.fromHexString(v >= 0 ? '#00A878' : '#E63946'));
    xl.CellStyle sideStyle(String side) => xl.CellStyle(bold: true, fontColorHex: xl.ExcelColor.fromHexString(side.toLowerCase() == 'buy' ? '#00A878' : '#E63946'));

    // ── Title ──
    sheet.merge(xl.CellIndex.indexByString('A1'), xl.CellIndex.indexByString('H1'));
    final title = sheet.cell(xl.CellIndex.indexByString('A1'));
    title.value = xl.TextCellValue('Order History — ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} (${orders.length} orders)');
    title.cellStyle = xl.CellStyle(bold: true, fontSize: 13, fontColorHex: xl.ExcelColor.fromHexString('#0A0A0A'));
    sheet.setRowHeight(0, 28);

    // ── Headers ──
    const headers = ['Date', 'Symbol', 'Side', 'Qty', 'Price', 'Status', 'P/L \$', 'P/L %'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = xl.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 22);

    // ── Summary stats ──
    final filled = orders.where((o) => o.profitCash != null);
    final totalPl = filled.fold<double>(0, (s, o) => s + o.profitCash!);
    final wins = filled.where((o) => o.profitCash! > 0).length;
    final total = filled.length;

    // ── Data rows ──
    for (var r = 0; r < orders.length; r++) {
      final o = orders[r];
      final row = r + 2;
      final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
      final dateStr = dt != null ? DateFormat('yyyy-MM-dd HH:mm').format(dt) : '';
      final rowBg = xl.CellStyle(backgroundColorHex: xl.ExcelColor.fromHexString(r.isEven ? '#FAFAFA' : '#FFFFFF'));

      void setCell(int col, xl.CellValue val, [xl.CellStyle? style]) {
        final c = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        c.value = val; c.cellStyle = style ?? rowBg;
      }

      setCell(0, xl.TextCellValue(dateStr));
      setCell(1, xl.TextCellValue(o.symbol), xl.CellStyle(bold: true, backgroundColorHex: xl.ExcelColor.fromHexString(r.isEven ? '#FAFAFA' : '#FFFFFF')));
      setCell(2, xl.TextCellValue(o.side.toUpperCase()), sideStyle(o.side));
      setCell(3, xl.DoubleCellValue(o.filledQty));
      setCell(4, xl.DoubleCellValue(o.filledAvgPrice));
      setCell(5, xl.TextCellValue(o.status.toUpperCase()));
      if (o.profitCash != null) setCell(6, xl.DoubleCellValue(o.profitCash!), plStyle(o.profitCash!));
      if (o.profitPerc != null) setCell(7, xl.TextCellValue('${o.profitPerc! >= 0 ? '+' : ''}${o.profitPerc!.toStringAsFixed(2)}%'), plStyle(o.profitPerc!));
      sheet.setRowHeight(row, 20);
    }

    // ── Summary row ──
    final sumRow = orders.length + 2;
    sheet.merge(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow), xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sumRow));
    final sumLabel = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow));
    sumLabel.value = xl.TextCellValue('TOTAL: $total trades · Win Rate ${total > 0 ? (wins / total * 100).toStringAsFixed(1) : 0}%');
    sumLabel.cellStyle = xl.CellStyle(bold: true, backgroundColorHex: xl.ExcelColor.fromHexString('#F0F0F0'));
    final sumPl = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: sumRow));
    sumPl.value = xl.DoubleCellValue(totalPl);
    sumPl.cellStyle = xl.CellStyle(bold: true, fontColorHex: xl.ExcelColor.fromHexString(totalPl >= 0 ? '#00A878' : '#E63946'), backgroundColorHex: xl.ExcelColor.fromHexString('#F0F0F0'));
    sheet.setRowHeight(sumRow, 22);

    // ── Column widths ──
    sheet.setColumnWidth(0, 18); sheet.setColumnWidth(1, 10); sheet.setColumnWidth(2, 8);
    sheet.setColumnWidth(3, 8);  sheet.setColumnWidth(4, 10); sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 12); sheet.setColumnWidth(7, 10);

    final bytes = excel.encode()!;
    _downloadXlsx('orders_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx', bytes);
  }

  static Color _statusColor(String status, AppColors c) {
    switch (status.toLowerCase()) {
      case 'filled': return c.green;
      case 'canceled': case 'cancelled': return c.red;
      case 'partially_filled': return c.yellow;
      case 'new': case 'accepted': return c.yellow;
      default: return c.textSecondary;
    }
  }
}

// =============================================================================
// SKELETON
// =============================================================================

class _Skeleton extends StatefulWidget {
  const _Skeleton({required this.c});
  final AppColors c;
  @override State<_Skeleton> createState() => _SkeletonS();
}
class _SkeletonS extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  @override void initState() { super.initState(); _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(); }
  @override void dispose() { _ac.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final c = widget.c;
    return AnimatedBuilder(animation: _ac, builder: (_, __) { final t = (_ac.value * 2 - 1).abs(); final cl = Color.lerp(c.card, c.border, t * 0.3)!;
      return ListView(padding: const EdgeInsets.all(32), physics: const NeverScrollableScrollPhysics(), children: [
        Center(child: Column(children: [
          Builder(builder: (ctx) => Text(_T.of(ctx).loadingData, style: TextStyle(color: c.textSecondary, fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12), SizedBox(width: 180, child: LinearProgressIndicator(backgroundColor: c.border, color: c.green.withOpacity(0.4), minHeight: 2)),
        ])),
        const SizedBox(height: 24),
        _b(cl, 100, c), const SizedBox(height: 12), _b(cl, 180, c), const SizedBox(height: 12),
        Row(children: [Expanded(child: _b(cl, 140, c)), const SizedBox(width: 12), Expanded(child: _b(cl, 140, c)), const SizedBox(width: 12), Expanded(child: _b(cl, 140, c))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _b(cl, 160, c)), const SizedBox(width: 12), Expanded(child: _b(cl, 160, c)), const SizedBox(width: 12), Expanded(child: _b(cl, 160, c))]),
      ]); });
  }
  Widget _b(Color cl, double h, AppColors c) => Container(height: h, decoration: BoxDecoration(color: cl, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)));
}

// =============================================================================
// AI INSIGHTS PAGE
// =============================================================================

// Period filter for AI session analysis.
enum _AiPeriod { day, week, month, all }

extension _AiPeriodExt on _AiPeriod {
  String get label => switch (this) {
    _AiPeriod.day   => 'ДЕНЬ',
    _AiPeriod.week  => 'НЕДЕЛЯ',
    _AiPeriod.month => 'МЕСЯЦ',
    _AiPeriod.all   => 'ВСЁ ВРЕМЯ',
  };

  DateTime? get cutoff {
    final now = DateTime.now();
    return switch (this) {
      _AiPeriod.day   => DateTime(now.year, now.month, now.day),
      _AiPeriod.week  => now.subtract(const Duration(days: 7)),
      _AiPeriod.month => DateTime(now.year, now.month, 1),
      _AiPeriod.all   => null,
    };
  }
}

class _AiPage extends StatefulWidget {
  const _AiPage({required this.c, required this.state});
  final AppColors c; final TradingAnalyticsState state;
  @override
  State<_AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<_AiPage> {
  _AiPeriod _period = _AiPeriod.all;

  List<TradingOrderDto> get _filteredOrders {
    final cutoff = _period.cutoff;
    if (cutoff == null) return widget.state.allOrders;
    return widget.state.allOrders.where((o) {
      final raw = o.filledAt.isNotEmpty ? o.filledAt : o.createdAt;
      final dt = DateTime.tryParse(raw);
      return dt != null && dt.isAfter(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return BlocBuilder<AiCubit, AiState>(builder: (context, aiState) {
      final modules = [
        (AiModule.tradeReview, 'TRADE REVIEW', Icons.rate_review_rounded, 'AI анализ сделок за период: качество входов/выходов, ошибки, рекомендации'),
        (AiModule.portfolioAdvisor, 'PORTFOLIO ADVISOR', Icons.pie_chart_rounded, 'Анализ портфеля: диверсификация, риски, рекомендации по ребалансировке'),
        (AiModule.patternDetection, 'PATTERN DETECTION', Icons.psychology_rounded, 'Поиск скрытых паттернов: лучшие часы/дни, поведенческие привычки'),
        (AiModule.riskScore, 'RISK SCORE', Icons.shield_rounded, 'Комплексный скор риска 0-100 с разбивкой по компонентам'),
      ];
      final filtered = _filteredOrders;

      return ListView(padding: const EdgeInsets.all(20), children: [
        // Period selector + Run All button.
        Row(children: [
          // Period tabs.
          Container(
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: _AiPeriod.values.map((p) {
              final active = p == _period;
              return GestureDetector(
                onTap: () => setState(() => _period = p),
                child: MouseRegion(cursor: SystemMouseCursors.click, child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? c.textPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(p.label, style: TextStyle(
                    color: active ? c.bg : c.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  )),
                )),
              );
            }).toList()),
          ),
          const SizedBox(width: 8),
          // Trade count badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(7), border: Border.all(color: c.border)),
            child: Builder(builder: (ctx) => Text('${filtered.length} ${_T.of(ctx).sdelek}', style: TextStyle(color: c.textSecondary, fontSize: 10, fontWeight: FontWeight.w600))),
          ),
          const Spacer(),
          // Run All button.
          GestureDetector(
            onTap: () => _runAll(context, filtered),
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(color: c.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.green.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: c.green),
                const SizedBox(width: 6),
                Builder(builder: (ctx) => Text(_T.of(ctx).runAll, style: TextStyle(color: c.green, fontSize: 11, fontWeight: FontWeight.w700))),
              ]),
            )),
          ),
          if (aiState.loading.isNotEmpty) ...[
            const SizedBox(width: 12),
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.green)),
          ],
        ]),
        const SizedBox(height: 20),
        // Module cards in 2x2 grid.
        for (var i = 0; i < modules.length; i += 2) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _moduleCard(context, aiState, modules[i].$1, modules[i].$2, modules[i].$3, modules[i].$4, filtered)),
            const SizedBox(width: 12),
            if (i + 1 < modules.length)
              Expanded(child: _moduleCard(context, aiState, modules[i + 1].$1, modules[i + 1].$2, modules[i + 1].$3, modules[i + 1].$4, filtered))
            else
              const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 12),
        ],
      ]);
    });
  }

  Widget _moduleCard(BuildContext ctx, AiState aiState, AiModule module, String title, IconData icon, String desc, List<TradingOrderDto> filtered) {
    final c = widget.c;
    final loading = aiState.isLoading(module);
    final result = aiState.result(module);
    // Modules that use orders: show period badge.
    final usesPeriod = module == AiModule.tradeReview || module == AiModule.patternDetection;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: c.green),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const Spacer(),
          if (usesPeriod) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(4)),
              child: Text(_period.label, style: TextStyle(color: c.textSecondary, fontSize: 8, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          if (loading)
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.green))
          else
            GestureDetector(
              onTap: () => _runModule(ctx, module, filtered),
              child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Builder(builder: (ctx) { final t = _T.of(ctx); return Text(result != null ? t.rerun : t.run, style: TextStyle(color: c.green, fontSize: 9, fontWeight: FontWeight.w700)); }),
              )),
            ),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        if (result != null) ...[
          Divider(color: c.border, height: 20),
          Builder(builder: (ctx) => Text('${_T.of(ctx).updated}: ${DateFormat('HH:mm:ss').format(result.timestamp)}', style: TextStyle(color: c.textSecondary.withOpacity(0.5), fontSize: 9))),
          const SizedBox(height: 8),
          SelectableText(result.content, style: TextStyle(color: c.textPrimary, fontSize: 12, height: 1.6)),
        ] else if (!loading) ...[
          const SizedBox(height: 16),
          Builder(builder: (ctx) => Center(child: Text(_T.of(ctx).clickRunToStart, style: TextStyle(color: c.textSecondary.withOpacity(0.4), fontSize: 11)))),
        ],
      ]),
    );
  }

  void _runModule(BuildContext ctx, AiModule module, List<TradingOrderDto> filtered) {
    final ai = ctx.read<AiCubit>();
    final s = widget.state;
    switch (module) {
      case AiModule.tradeReview:
        ai.runTradeReview(filtered);
      case AiModule.portfolioAdvisor:
        ai.runPortfolioAdvisor(s.positions);
      case AiModule.patternDetection:
        if (s.analytics != null) ai.runPatternDetection(s.analytics!);
      case AiModule.riskScore:
        if (s.analytics != null) ai.runRiskScore(analytics: s.analytics!, positions: s.positions);
      case AiModule.journalDaily:
        ai.runJournalDaily(s.allOrders);
      case AiModule.journalWeekly:
        ai.runJournalWeekly(s.allOrders);
      case AiModule.journalAllTime:
        if (s.analytics != null) ai.runJournalAllTime(s.analytics!);
      case AiModule.strategyAnalysis:
        if (s.strategies.isNotEmpty) ai.runStrategyAnalysis(s.strategies.first, s.positions);
      case AiModule.strategyComparison:
        ai.runStrategyComparison(s.strategies, s.positions);
    }
  }

  void _runAll(BuildContext ctx, List<TradingOrderDto> filtered) {
    final ai = ctx.read<AiCubit>();
    final s = widget.state;
    ai.runTradeReview(filtered);
    if (s.positions.isNotEmpty) ai.runPortfolioAdvisor(s.positions);
    if (s.analytics != null) {
      ai.runPatternDetection(s.analytics!);
      ai.runRiskScore(analytics: s.analytics!, positions: s.positions);
    }
  }
}

// =============================================================================
// STRATEGIES PAGE
// =============================================================================

class _StrategiesPage extends StatelessWidget {
  const _StrategiesPage({required this.c, required this.state});
  final AppColors c; final TradingAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final strategies = state.strategies;
    final positions = state.positions;
    final totalPortfolioValue = positions.fold<double>(0, (s, p) => s + p.marketValue);
    final cubit = context.read<TradingAnalyticsCubit>();

    // Assigned qty per symbol across all strategies
    final assignedSymbols = strategies.expand((s) => s.symbols).toSet();
    final unassigned = positions.where((p) => !assignedSymbols.contains(p.symbol)).toList();

    return ListView(padding: const EdgeInsets.all(20), children: [
      // ── Top bar: header + create button ──
      Row(children: [
        Text('STRATEGIES', style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const Spacer(),
        _StratCreateBtn(c: c, positions: positions, onCreated: (s) => cubit.createStrategy(s)),
      ]),
      const SizedBox(height: 20),

      if (strategies.isEmpty) ...[
        _StratEmptyState(c: c, positions: positions, onCreated: (s) => cubit.createStrategy(s)),
      ] else ...[
        // ── Overview row: pie chart + summary cards ──
        _OverviewSection(c: c, strategies: strategies, positions: positions, totalValue: totalPortfolioValue),
        const SizedBox(height: 20),

        // ── Strategy cards ──
        for (final strategy in strategies) ...[
          _StrategyCard(
            c: c, strategy: strategy,
            positions: positions, totalValue: totalPortfolioValue,
            allPositions: positions,
            onEdit: (updated) => cubit.updateStrategy(updated),
            onDelete: () => cubit.deleteStrategy(strategy.id),
          ),
          const SizedBox(height: 12),
        ],

        // ── Unassigned positions ──
        if (unassigned.isNotEmpty) ...[
          const SizedBox(height: 8),
          _UnassignedCard(c: c, positions: unassigned, totalValue: totalPortfolioValue),
        ],

        // ── AI Analysis ──
        const SizedBox(height: 20),
        _StrategyAiSection(c: c, state: state),
      ],

      const SizedBox(height: 32),
    ]);
  }
}

// ── Overview with pie chart ──
class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.c, required this.strategies, required this.positions, required this.totalValue});
  final AppColors c; final List<StrategyEntity> strategies; final List<TradingPositionDto> positions; final double totalValue;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Pie chart
      Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
        child: Column(children: [
          Text(_T.of(context).allocation, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 16),
          SizedBox(
            width: 140, height: 140,
            child: CustomPaint(painter: _PieChartPainter(
              segments: strategies.map((s) {
                final val = s.totalValue(positions);
                return _PieSegment(value: val, color: s.color);
              }).toList(),
              trackColor: c.border,
            )),
          ),
          const SizedBox(height: 16),
          // Legend
          ...strategies.map((s) {
            final pct = totalValue > 0 ? (s.totalValue(positions) / totalValue * 100) : 0.0;
            return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Expanded(child: Text(s.name, style: TextStyle(color: c.textPrimary, fontSize: 12))),
              Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]));
          }),
        ]),
      ),
      const SizedBox(width: 12),

      // Summary cards
      Expanded(child: Column(children: [
        Row(children: [
          _summaryTile(_T.of(context).totalValue, '\$${_fmt(totalValue)}', c.textPrimary, c),
          const SizedBox(width: 12),
          _summaryTile(_T.of(context).navStrategies, '${strategies.length}', c.textPrimary, c),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          ...strategies.map((s) {
            final pl = s.totalPl(positions);
            final plColor = pl >= 0 ? c.green : c.red;
            final sign = pl >= 0 ? '+' : '';
            return Expanded(child: Container(
              margin: EdgeInsets.only(right: s != strategies.last ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(s.name.toUpperCase(), style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 8),
                Text('$sign\$${_fmt(pl)}', style: TextStyle(color: plColor, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${s.avgPlPercent(positions).toStringAsFixed(1)}%', style: TextStyle(color: plColor, fontSize: 12)),
              ]),
            ));
          }),
        ]),
      ])),
    ]);
  }

  Widget _summaryTile(String label, String value, Color vc, AppColors c) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: vc, fontSize: 22, fontWeight: FontWeight.w800)),
    ]),
  ));
}

// ── Create button ──
class _StratCreateBtn extends StatelessWidget {
  const _StratCreateBtn({required this.c, required this.positions, required this.onCreated});
  final AppColors c;
  final List<TradingPositionDto> positions;
  final void Function(StrategyEntity) onCreated;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final result = await showDialog<StrategyEntity>(
        context: context,
        builder: (_) => _StrategyDialog(c: c, positions: positions),
      );
      if (result != null) onCreated(result);
    },
    child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.green.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_rounded, size: 16, color: c.green),
        const SizedBox(width: 6),
        Text('NEW STRATEGY', style: TextStyle(color: c.green, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    )),
  );
}

// ── Empty state ──
class _StratEmptyState extends StatelessWidget {
  const _StratEmptyState({required this.c, required this.positions, required this.onCreated});
  final AppColors c;
  final List<TradingPositionDto> positions;
  final void Function(StrategyEntity) onCreated;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
    child: Column(children: [
      Icon(Icons.pie_chart_outline_rounded, size: 48, color: c.textSecondary.withValues(alpha: 0.3)),
      const SizedBox(height: 16),
      Text('No strategies yet', style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Create a strategy to group your positions and track performance separately', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () async {
          final result = await showDialog<StrategyEntity>(
            context: context,
            builder: (_) => _StrategyDialog(c: c, positions: positions),
          );
          if (result != null) onCreated(result);
        },
        child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(10)),
          child: Text('Create first strategy', style: TextStyle(color: c.isDark ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        )),
      ),
    ]),
  );
}

// ── Strategy card with positions table ──
class _StrategyCard extends StatelessWidget {
  const _StrategyCard({
    required this.c, required this.strategy,
    required this.positions, required this.totalValue,
    required this.allPositions,
    required this.onEdit, required this.onDelete,
  });
  final AppColors c;
  final StrategyEntity strategy;
  final List<TradingPositionDto> positions;
  final List<TradingPositionDto> allPositions;
  final double totalValue;
  final void Function(StrategyEntity) onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strategyPositions = strategy.filterPositions(positions);
    final stratValue = strategy.totalValue(positions);
    final stratPl = strategy.totalPl(positions);
    final plColor = stratPl >= 0 ? c.green : c.red;
    final plSign = stratPl >= 0 ? '+' : '';
    final allocationPct = totalValue > 0 ? (stratValue / totalValue * 100) : 0.0;
    final deviation = strategy.allocationDeviation(positions, totalValue);
    final hasTarget = strategy.targetPct > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: strategy.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(strategy.icon, size: 18, color: strategy.color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(strategy.name, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            if (strategy.description.isNotEmpty)
              Text(strategy.description, style: TextStyle(color: c.textSecondary, fontSize: 11)),
          ])),
          // Stats
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${_fmt(stratValue)}', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            Row(children: [
              Text('$plSign\$${_fmt(stratPl)}', style: TextStyle(color: plColor, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              // Allocation badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: strategy.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text('${allocationPct.toStringAsFixed(0)}%', style: TextStyle(color: strategy.color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              // Deviation badge (if target set)
              if (hasTarget) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (deviation.abs() > 5 ? c.red : c.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(0)}% vs ${strategy.targetPct.toStringAsFixed(0)}% target',
                    style: TextStyle(color: deviation.abs() > 5 ? c.red : c.green, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ]),
          ]),
          const SizedBox(width: 12),
          // Edit / Delete menu
          _StratCardMenu(c: c, strategy: strategy, allPositions: allPositions, onEdit: onEdit, onDelete: onDelete),
        ]),

        // ── Notes ──
        if (strategy.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.notes_rounded, size: 13, color: c.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(strategy.notes, style: TextStyle(color: c.textSecondary, fontSize: 11, height: 1.5))),
            ]),
          ),
        ],

        // ── Positions table ──
        if (strategyPositions.isNotEmpty) ...[
          Divider(color: c.border, height: 24),
          ...strategyPositions.map((p) {
            final posPlColor = p.profitCash >= 0 ? c.green : c.red;
            final posSign = p.profitCash >= 0 ? '+' : '';
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: c.border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(p.symbol.length > 4 ? p.symbol.substring(0, 4) : p.symbol, style: TextStyle(color: c.textPrimary, fontSize: 9, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.symbol, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${p.qty % 1 == 0 ? p.qty.toInt() : p.qty.toStringAsFixed(2)} shares · \$${p.avgEntryPrice.toStringAsFixed(2)}', style: TextStyle(color: c.textSecondary, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${_fmt(p.marketValue)}', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$posSign\$${_fmt(p.profitCash)} (${p.profitPercent.toStringAsFixed(1)}%)', style: TextStyle(color: posPlColor, fontSize: 11)),
              ]),
            ]));
          }),
        ] else
          Padding(padding: const EdgeInsets.only(top: 10), child: Text('No matching positions in portfolio', style: TextStyle(color: c.textSecondary, fontSize: 12))),
      ]),
    );
  }
}

// ── Card context menu (edit/delete) ──
class _StratCardMenu extends StatelessWidget {
  const _StratCardMenu({required this.c, required this.strategy, required this.allPositions, required this.onEdit, required this.onDelete});
  final AppColors c;
  final StrategyEntity strategy;
  final List<TradingPositionDto> allPositions;
  final void Function(StrategyEntity) onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    color: c.card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.border)),
    icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textSecondary),
    onSelected: (v) async {
      if (v == 'edit') {
        final result = await showDialog<StrategyEntity>(
          context: context,
          builder: (_) => _StrategyDialog(c: c, positions: allPositions, existing: strategy),
        );
        if (result != null) onEdit(result);
      } else if (v == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => _ConfirmDeleteDialog(c: c, name: strategy.name),
        );
        if (ok == true) onDelete();
      }
    },
    itemBuilder: (_) => [
      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 15, color: c.textPrimary), const SizedBox(width: 8), Text('Edit', style: TextStyle(color: c.textPrimary, fontSize: 13))])),
      PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 15, color: c.red), const SizedBox(width: 8), Text('Delete', style: TextStyle(color: c.red, fontSize: 13))])),
    ],
  );
}

// ── Confirm delete dialog ──
class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.c, required this.name});
  final AppColors c; final String name;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: c.card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.border)),
    child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.delete_outline_rounded, size: 40, color: c.red),
      const SizedBox(height: 16),
      Text('Delete "$name"?', style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('This action cannot be undone.', style: TextStyle(color: c.textSecondary, fontSize: 13)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('Cancel', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          )),
        )),
        const SizedBox(width: 12),
        Expanded(child: GestureDetector(
          onTap: () => Navigator.of(context).pop(true),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: c.red, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          )),
        )),
      ]),
    ])),
  );
}

// ── Create/Edit strategy dialog ──
class _StrategyDialog extends StatefulWidget {
  const _StrategyDialog({required this.c, required this.positions, this.existing});
  final AppColors c;
  final List<TradingPositionDto> positions;
  final StrategyEntity? existing;
  @override State<_StrategyDialog> createState() => _StrategyDialogState();
}

class _StrategyDialogState extends State<_StrategyDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  Color _color = const Color(0xFF6366F1);
  IconData _icon = Icons.pie_chart_rounded;
  // symbol → qty controller
  final Map<String, TextEditingController> _qtyCtrl = {};

  static const _colors = [
    Color(0xFF6366F1), Color(0xFF22C55E), Color(0xFF3B82F6),
    Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6),
    Color(0xFF06B6D4), Color(0xFFEC4899),
  ];

  static const _icons = <String, IconData>{
    'pie_chart': Icons.pie_chart_rounded,
    'trending_up': Icons.trending_up_rounded,
    'shield': Icons.shield_rounded,
    'star': Icons.star_rounded,
    'bolt': Icons.bolt_rounded,
    'verified': Icons.verified_rounded,
    'bar_chart': Icons.bar_chart_rounded,
    'savings': Icons.savings_rounded,
    'public': Icons.public_rounded,
    'rocket': Icons.rocket_launch_rounded,
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description;
      _notesCtrl.text = e.notes;
      _targetCtrl.text = e.targetPct > 0 ? e.targetPct.toStringAsFixed(0) : '';
      _color = e.color;
      _icon = e.icon;
      for (final entry in e.entries) {
        _qtyCtrl[entry.symbol] = TextEditingController(text: entry.qty % 1 == 0 ? entry.qty.toInt().toString() : entry.qty.toStringAsFixed(2));
      }
    }
    // Pre-fill qty controllers for all available positions
    for (final p in widget.positions) {
      _qtyCtrl.putIfAbsent(p.symbol, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _notesCtrl.dispose(); _targetCtrl.dispose();
    for (final c in _qtyCtrl.values) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final entries = <StrategyPositionEntry>[];
    var idCounter = 0;
    for (final p in widget.positions) {
      final raw = _qtyCtrl[p.symbol]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final qty = double.tryParse(raw) ?? 0;
      if (qty <= 0) continue;
      entries.add(StrategyPositionEntry(id: idCounter++, symbol: p.symbol, qty: qty.clamp(0.0, p.qty)));
    }
    final strategy = (widget.existing ?? StrategyEntity(id: '', name: '', icon: _icon, color: _color))
        .copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          icon: _icon,
          color: _color,
          targetPct: double.tryParse(_targetCtrl.text.trim()) ?? 0.0,
          entries: entries,
        );
    Navigator.of(context).pop(strategy);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: c.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.border)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700), child: Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), child: Row(children: [
          Text(isEdit ? 'Edit Strategy' : 'New Strategy', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.of(context).pop(), child: Icon(Icons.close_rounded, color: c.textSecondary, size: 20)),
        ])),
        Divider(color: c.border, height: 24),
        // Scrollable body
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Name
          _label(c, 'NAME'),
          _field(c, _nameCtrl, 'e.g. Growth Tech'),
          const SizedBox(height: 16),

          // Description
          _label(c, 'DESCRIPTION'),
          _field(c, _descCtrl, 'Short description (optional)'),
          const SizedBox(height: 16),

          // Target allocation
          _label(c, 'TARGET ALLOCATION %'),
          _field(c, _targetCtrl, '0', keyboardType: TextInputType.number),
          const SizedBox(height: 16),

          // Color picker
          _label(c, 'COLOR'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _colors.map((col) => GestureDetector(
            onTap: () => setState(() => _color = col),
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: col,
                shape: BoxShape.circle,
                border: _color == col ? Border.all(color: c.textPrimary, width: 2) : null,
              ),
            )),
          )).toList()),
          const SizedBox(height: 16),

          // Icon picker
          _label(c, 'ICON'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _icons.entries.map((e) => GestureDetector(
            onTap: () => setState(() => _icon = e.value),
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _icon == e.value ? _color.withValues(alpha: 0.15) : c.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: _icon == e.value ? Border.all(color: _color) : null,
              ),
              child: Icon(e.value, size: 18, color: _icon == e.value ? _color : c.textSecondary),
            )),
          )).toList()),
          const SizedBox(height: 20),

          // Positions
          if (widget.positions.isNotEmpty) ...[
            _label(c, 'ASSIGN POSITIONS (enter qty per ticker)'),
            const SizedBox(height: 10),
            ...widget.positions.map((p) {
              final ctrl = _qtyCtrl[p.symbol]!;
              return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: c.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(p.symbol.length > 4 ? p.symbol.substring(0,4) : p.symbol, style: TextStyle(color: c.textPrimary, fontSize: 9, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.symbol, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('max ${p.qty % 1 == 0 ? p.qty.toInt() : p.qty.toStringAsFixed(2)} shares', style: TextStyle(color: c.textSecondary, fontSize: 10)),
                ])),
                SizedBox(width: 80, child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: c.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _color)),
                  ),
                )),
              ]));
            }),
            const SizedBox(height: 16),
          ],

          // Notes
          _label(c, 'NOTES'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: TextStyle(color: c.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Your rules, thesis, reminders...',
              hintStyle: TextStyle(color: c.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _color)),
            ),
          ),
          const SizedBox(height: 24),
        ]))),

        // Footer buttons
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('Cancel', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            )),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: _submit,
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(isEdit ? 'Save' : 'Create', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
            )),
          )),
        ])),
      ])),
    );
  }

  static Widget _label(AppColors c, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
  );

  static Widget _field(AppColors c, TextEditingController ctrl, String hint, {TextInputType? keyboardType}) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: TextStyle(color: c.textPrimary, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.textSecondary),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
    ),
  );
}

// ── Unassigned positions card ──
class _UnassignedCard extends StatelessWidget {
  const _UnassignedCard({required this.c, required this.positions, required this.totalValue});
  final AppColors c; final List<TradingPositionDto> positions; final double totalValue;

  @override
  Widget build(BuildContext context) {
    final unValue = positions.fold<double>(0, (s, p) => s + p.marketValue);
    final pct = totalValue > 0 ? (unValue / totalValue * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border, width: 1), ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.help_outline_rounded, size: 18, color: c.textSecondary),
          const SizedBox(width: 10),
          Builder(builder: (ctx) => Text(_T.of(ctx).unassigned, style: TextStyle(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
          const Spacer(),
          Text('${pct.toStringAsFixed(0)}% · \$${_fmt(unValue)}', style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ]),
        Divider(color: c.border, height: 20),
        ...positions.map((p) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          Text(p.symbol, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('\$${_fmt(p.marketValue)}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ]))),
      ]),
    );
  }
}

// ── Pie chart painter ──
class _PieSegment {
  const _PieSegment({required this.value, required this.color});
  final double value; final Color color;
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.segments, required this.trackColor});
  final List<_PieSegment> segments; final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    const strokeWidth = 20.0;
    const gap = 0.04; // gap between segments in radians

    // Track
    canvas.drawCircle(center, r, Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth);

    final total = segments.fold<double>(0, (s, seg) => s + seg.value);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * (2 * math.pi) - gap;
      if (sweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          startAngle,
          sweep,
          false,
          Paint()..color = seg.color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
        );
      }
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) => segments.length != old.segments.length;
}

// =============================================================================
// CSV DOWNLOAD (web)
// =============================================================================

void _downloadXlsx(String filename, List<int> bytes) {
  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

// =============================================================================
// OPEN URL (web)
// =============================================================================

void _openUrl(String url) {
  html.window.open(url, '_blank');
}

// =============================================================================
// TRADING LEAD DIALOG (reuses LeadService)
// =============================================================================

class _TradingLeadDialog extends StatefulWidget {
  const _TradingLeadDialog();
  @override State<_TradingLeadDialog> createState() => _TradingLeadDialogState();
}

class _TradingLeadDialogState extends State<_TradingLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _firstCtrl.dispose(); _lastCtrl.dispose(); _emailCtrl.dispose(); _whatsappCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final lead = LeadData(firstName: _firstCtrl.text.trim(), lastName: _lastCtrl.text.trim(), email: _emailCtrl.text.trim(), whatsapp: _whatsappCtrl.text.trim(), source: 'trading_demo');
    await LeadService.save(lead);
    AnalyticsService.instance.track('lead_submitted', {'email': lead.email, 'source': 'trading_demo'});
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;
    return Dialog(
      backgroundColor: c.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.border)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Padding(padding: const EdgeInsets.all(32), child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset('assets/svg/ic_logo.svg', height: 36),
        const SizedBox(height: 20),
        Text(s.leadTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.textPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(s.leadSubtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.textSecondary)),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: TextFormField(controller: _firstCtrl, textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: s.leadFirstName, prefixIcon: Icon(Icons.person_outline, color: c.textSecondary, size: 18)),
            validator: (v) => v == null || v.trim().isEmpty ? s.leadFirstNameRequired : null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _lastCtrl, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: s.leadLastName))),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: s.leadEmail, prefixIcon: Icon(Icons.email_outlined, color: c.textSecondary, size: 18)),
          validator: (v) { if (v == null || v.trim().isEmpty) return s.leadEmailRequired; if (!v.contains('@') || !v.contains('.')) return s.leadEmailInvalid; return null; }),
        const SizedBox(height: 12),
        TextFormField(controller: _whatsappCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: s.leadWhatsapp, prefixIcon: Icon(Icons.phone_outlined, color: c.textSecondary, size: 18))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.isDark ? Colors.black : Colors.white)) : Text(s.leadSubmit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_outline, size: 14, color: c.textSecondary), const SizedBox(width: 6),
          Text(s.leadPrivacy, style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ]),
      ])))),
    );
  }
}

// =============================================================================
// CTA BANNER
// =============================================================================

class CtaBanner extends StatelessWidget {
  const CtaBanner({required this.c, super.key});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final s = AppThemeScope.of(context).strings;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.gold.withOpacity(0.25)),
        gradient: LinearGradient(
          colors: [c.gold.withOpacity(0.06), c.gold.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        SvgPicture.asset('assets/svg/ic_logo.svg', height: 28),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.tradingCtaTitle, style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(s.tradingCtaSubtitle, style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ])),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => _openUrl(AppThemeScope.of(context).strings.investlinkUrl),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(10)),
            child: Text(s.tradingCtaButton, style: const TextStyle(color: Color(0xFF212129), fontSize: 13, fontWeight: FontWeight.w600)),
          )),
        ),
      ]),
    );
  }
}

// =============================================================================
// JOURNAL PAGE
// =============================================================================

enum _JournalTab { daily, weekly, allTime }

class _JournalPage extends StatefulWidget {
  const _JournalPage({required this.c, required this.state});
  final AppColors c;
  final TradingAnalyticsState state;
  @override
  State<_JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<_JournalPage> {
  _JournalTab _tab = _JournalTab.allTime;

  AiModule get _module => switch (_tab) {
    _JournalTab.daily   => AiModule.journalDaily,
    _JournalTab.weekly  => AiModule.journalWeekly,
    _JournalTab.allTime => AiModule.journalAllTime,
  };

  void _run(BuildContext ctx) {
    final ai = ctx.read<AiCubit>();
    final s = widget.state;
    switch (_tab) {
      case _JournalTab.daily:
        ai.runJournalDaily(s.allOrders);
      case _JournalTab.weekly:
        ai.runJournalWeekly(s.allOrders);
      case _JournalTab.allTime:
        if (s.analytics != null) ai.runJournalAllTime(s.analytics!);
    }
  }

  /// Auto-run allTime on first open if no result yet.
  void _autoRunIfNeeded(BuildContext ctx, AiState aiState) {
    if (_tab == _JournalTab.allTime &&
        !aiState.isLoading(AiModule.journalAllTime) &&
        aiState.result(AiModule.journalAllTime) == null) {
      _run(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final t = _T.of(context);

    return BlocBuilder<AiCubit, AiState>(builder: (ctx, aiState) {
      final loading = aiState.isLoading(_module);
      final result = aiState.result(_module);

      // Auto-generate allTime on first open
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoRunIfNeeded(ctx, aiState));

      return ListView(padding: const EdgeInsets.all(24), children: [
        // Header
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.journalTitle, style: TextStyle(color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(t.journalSubtitle, style: TextStyle(color: c.textSecondary, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 24),

        // Tab + Generate button row
        Row(children: [
          // Tabs
          Container(
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: _JournalTab.values.map((tab) {
              final active = tab == _tab;
              final label = switch (tab) {
                _JournalTab.daily   => t.journalDaily,
                _JournalTab.weekly  => t.journalWeekly,
                _JournalTab.allTime => t.journalAllTime,
              };
              return GestureDetector(
                onTap: () {
                  setState(() => _tab = tab);
                  // Auto-run allTime if switching to it and no result
                  if (tab == _JournalTab.allTime) {
                    final aiState = ctx.read<AiCubit>().state;
                    _autoRunIfNeeded(ctx, aiState);
                  }
                },
                child: MouseRegion(cursor: SystemMouseCursors.click, child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? c.textPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(label, style: TextStyle(
                    color: active ? c.bg : c.textSecondary,
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                  )),
                )),
              );
            }).toList()),
          ),
          const SizedBox(width: 12),
          // Generate button
          GestureDetector(
            onTap: loading ? null : () => _run(ctx),
            child: MouseRegion(cursor: loading ? MouseCursor.defer : SystemMouseCursors.click, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: c.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.green.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (loading)
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.green))
                else
                  Icon(Icons.auto_awesome_rounded, size: 14, color: c.green),
                const SizedBox(width: 8),
                Text(_tab == _JournalTab.allTime
                  ? t.journalRegenerate
                  : (result != null ? t.journalRegenerate : t.journalGenerate),
                  style: TextStyle(color: c.green, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            )),
          ),
        ]),
        const SizedBox(height: 20),

        // Description card (shown when no result)
        if (result == null && !loading)
          _JournalEmptyCard(tab: _tab, c: c, t: t)
        else if (loading)
          _JournalLoadingCard(c: c)
        else
          _JournalResultCard(result: result!, c: c, t: t),
      ]);
    });
  }
}

class _JournalEmptyCard extends StatelessWidget {
  const _JournalEmptyCard({required this.tab, required this.c, required this.t});
  final _JournalTab tab; final AppColors c; final _T t;

  @override
  Widget build(BuildContext context) {
    final desc = switch (tab) {
      _JournalTab.daily   => t.journalDailyDesc,
      _JournalTab.weekly  => t.journalWeeklyDesc,
      _JournalTab.allTime => t.journalAllTimeDesc,
    };
    final icon = switch (tab) {
      _JournalTab.daily   => Icons.today_rounded,
      _JournalTab.weekly  => Icons.date_range_rounded,
      _JournalTab.allTime => Icons.history_edu_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(children: [
        Icon(icon, size: 48, color: c.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(desc, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.5)),
        const SizedBox(height: 20),
        Text(t.journalNoData, style: TextStyle(color: c.textSecondary.withValues(alpha: 0.5), fontSize: 12)),
      ]),
    );
  }
}

class _JournalLoadingCard extends StatelessWidget {
  const _JournalLoadingCard({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
    child: Column(children: [
      SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.green)),
      const SizedBox(height: 16),
      Text('AI пишет дневник...', style: TextStyle(color: c.textSecondary, fontSize: 13)),
    ]),
  );
}

class _JournalResultCard extends StatelessWidget {
  const _JournalResultCard({required this.result, required this.c, required this.t});
  final AiAnalysis result; final AppColors c; final _T t;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.auto_awesome_rounded, size: 14, color: c.green),
        const SizedBox(width: 6),
        Text('${t.journalUpdated}: ${DateFormat('dd MMM, HH:mm').format(result.timestamp)}',
          style: TextStyle(color: c.textSecondary.withValues(alpha: 0.6), fontSize: 10)),
      ]),
      Divider(color: c.border, height: 20),
      SelectableText(result.content,
        style: TextStyle(color: c.textPrimary, fontSize: 13, height: 1.7, letterSpacing: 0.1)),
    ]),
  );
}

// =============================================================================
// STRATEGY AI SECTION (added to _StrategiesPage)
// =============================================================================

class _StrategyAiSection extends StatelessWidget {
  const _StrategyAiSection({required this.c, required this.state});
  final AppColors c;
  final TradingAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    if (state.strategies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
        child: Row(children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: c.textSecondary),
          const SizedBox(width: 10),
          Text(t.strategyAiNoStrategies, style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ]),
      );
    }

    return BlocBuilder<AiCubit, AiState>(builder: (ctx, aiState) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Row: Analysis card + Comparison card
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Strategy Analysis
          Expanded(child: _aiCard(
            ctx: ctx, aiState: aiState,
            module: AiModule.strategyAnalysis,
            title: t.strategyAiAnalysis,
            desc: t.strategyAiAnalysisDesc,
            icon: Icons.analytics_rounded,
            onRun: () => ctx.read<AiCubit>().runStrategyAnalysis(
              state.strategies.first, state.positions,
            ),
            onRerun: () => ctx.read<AiCubit>().runStrategyAnalysis(
              state.strategies.first, state.positions,
            ),
            t: t,
          )),
          const SizedBox(width: 12),
          // Strategy Comparison
          Expanded(child: _aiCard(
            ctx: ctx, aiState: aiState,
            module: AiModule.strategyComparison,
            title: t.strategyAiComparison,
            desc: t.strategyAiComparisonDesc,
            icon: Icons.compare_arrows_rounded,
            onRun: () => ctx.read<AiCubit>().runStrategyComparison(
              state.strategies, state.positions,
            ),
            onRerun: () => ctx.read<AiCubit>().runStrategyComparison(
              state.strategies, state.positions,
            ),
            t: t,
          )),
        ]),
      ]);
    });
  }

  Widget _aiCard({
    required BuildContext ctx,
    required AiState aiState,
    required AiModule module,
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onRun,
    required VoidCallback onRerun,
    required _T t,
  }) {
    final loading = aiState.isLoading(module);
    final result = aiState.result(module);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: c.green),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3))),
          if (loading)
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.green))
          else
            GestureDetector(
              onTap: result != null ? onRerun : onRun,
              child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(result != null ? t.strategyAiRerun : t.strategyAiRun,
                  style: TextStyle(color: c.green, fontSize: 9, fontWeight: FontWeight.w700)),
              )),
            ),
        ]),
        const SizedBox(height: 6),
        Text(desc, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        if (result != null) ...[
          Divider(color: c.border, height: 20),
          Text('${t.journalUpdated}: ${DateFormat('HH:mm').format(result.timestamp)}',
            style: TextStyle(color: c.textSecondary.withValues(alpha: 0.5), fontSize: 9)),
          const SizedBox(height: 8),
          SelectableText(result.content,
            style: TextStyle(color: c.textPrimary, fontSize: 12, height: 1.6)),
        ] else if (!loading) ...[
          const SizedBox(height: 12),
          Center(child: Text(t.strategyAiClickRun,
            style: TextStyle(color: c.textSecondary.withValues(alpha: 0.4), fontSize: 11))),
        ],
      ]),
    );
  }
}

// =============================================================================
// TRANSLATIONS — Trading Analytics module
// =============================================================================

class _T {
  const _T._({
    required this.navDashboard,
    required this.navPortfolio,
    required this.navStrategies,
    required this.navOrders,
    required this.navAiInsights,
    required this.navLogout,
    required this.navStaging,
    required this.headerPortfolio,
    required this.headerStrategies,
    required this.headerOrderHistory,
    required this.headerAiInsights,
    required this.statusLive,
    required this.trades,
    required this.orders,
    required this.keyMetrics,
    required this.equityCurve,
    required this.currentValue,
    required this.winRate,
    required this.wins,
    required this.losses,
    required this.streaks,
    required this.winStreak,
    required this.lossStreak,
    required this.bestDay,
    required this.worstDay,
    required this.topTickers,
    required this.longVsShort,
    required this.positions,
    required this.avg,
    required this.perTrade,
    required this.plByWeekday,
    required this.plByHour,
    required this.afterHoursRestricted,
    required this.back,
    required this.noTradesThisDay,
    required this.monthlySummary,
    required this.month,
    required this.avgPerTrade,
    required this.winPct,
    required this.avgHoldTime,
    required this.avgHoldTimeDesc,
    required this.overall,
    required this.winsOnly,
    required this.lossesOnly,
    required this.plByPositionSize,
    required this.sizeRange,
    required this.rrDistribution,
    required this.tradingAnalytics,
    required this.noOpenPositions,
    required this.refresh,
    required this.exportExcel,
    required this.symbol,
    required this.chart30d,
    required this.qty,
    required this.avgPrice,
    required this.current,
    required this.mktValue,
    required this.plDollar,
    required this.plPercent,
    required this.totalValue,
    required this.noOrdersFound,
    required this.date,
    required this.side,
    required this.price,
    required this.status,
    required this.loadingData,
    required this.sdelek,
    required this.runAll,
    required this.clickRunToStart,
    required this.updated,
    required this.rerun,
    required this.run,
    required this.noStrategies,
    required this.createFirstStrategy,
    required this.allocation,
    required this.noPositionsAssigned,
    required this.unassigned,
    required this.errorTitle,
    required this.errorBack,
    required this.quickSignIn,
    required this.saved,
    required this.totalPositions,
    // Journal
    required this.navJournal,
    required this.headerJournal,
    required this.journalTitle,
    required this.journalSubtitle,
    required this.journalDaily,
    required this.journalWeekly,
    required this.journalAllTime,
    required this.journalDailyDesc,
    required this.journalWeeklyDesc,
    required this.journalAllTimeDesc,
    required this.journalGenerate,
    required this.journalRegenerate,
    required this.journalNoData,
    required this.journalUpdated,
    // Strategy AI
    required this.strategyAiAnalysis,
    required this.strategyAiComparison,
    required this.strategyAiAnalysisDesc,
    required this.strategyAiComparisonDesc,
    required this.strategyAiRun,
    required this.strategyAiRerun,
    required this.strategyAiRunAll,
    required this.strategyAiClickRun,
    required this.strategyAiNoStrategies,
  });

  final String navDashboard, navPortfolio, navStrategies, navOrders, navAiInsights, navLogout, navStaging;
  final String headerPortfolio, headerStrategies, headerOrderHistory, headerAiInsights;
  final String statusLive, trades, orders;
  final String keyMetrics, equityCurve, currentValue;
  final String winRate, wins, losses;
  final String streaks, winStreak, lossStreak, bestDay, worstDay;
  final String topTickers;
  final String longVsShort, positions, avg, perTrade;
  final String plByWeekday, plByHour, afterHoursRestricted;
  final String back, noTradesThisDay;
  final String monthlySummary, month, avgPerTrade, winPct;
  final String avgHoldTime, avgHoldTimeDesc, overall, winsOnly, lossesOnly;
  final String plByPositionSize, sizeRange;
  final String rrDistribution;
  final String tradingAnalytics;
  final String noOpenPositions, refresh, exportExcel;
  final String symbol, chart30d, qty, avgPrice, current, mktValue, plDollar, plPercent;
  final String totalValue;
  final String noOrdersFound, date, side, price, status;
  final String loadingData, sdelek, runAll, clickRunToStart, updated, rerun, run;
  final String noStrategies, createFirstStrategy, allocation, noPositionsAssigned, unassigned;
  final String errorTitle, errorBack;
  final String quickSignIn, saved;
  final String totalPositions;
  // Journal
  final String navJournal, headerJournal, journalTitle, journalSubtitle;
  final String journalDaily, journalWeekly, journalAllTime;
  final String journalDailyDesc, journalWeeklyDesc, journalAllTimeDesc;
  final String journalGenerate, journalRegenerate, journalNoData, journalUpdated;
  // Strategy AI
  final String strategyAiAnalysis, strategyAiComparison;
  final String strategyAiAnalysisDesc, strategyAiComparisonDesc;
  final String strategyAiRun, strategyAiRerun, strategyAiRunAll, strategyAiClickRun, strategyAiNoStrategies;

  static _T of(BuildContext context) {
    final locale = AppThemeScope.of(context).locale;
    return locale == 'ru' ? _ru : _en;
  }

  static const _ru = _T._(
    navDashboard: 'ДАШБОРД',
    navPortfolio: 'ПОРТФЕЛЬ',
    navStrategies: 'СТРАТЕГИИ',
    navOrders: 'ОРДЕРА',
    navAiInsights: 'AI ИНСАЙТЫ',
    navLogout: 'ВЫХОД',
    navStaging: 'STAGING',
    headerPortfolio: 'ПОРТФЕЛЬ',
    headerStrategies: 'СТРАТЕГИИ',
    headerOrderHistory: 'ИСТОРИЯ ОРДЕРОВ',
    headerAiInsights: 'AI ИНСАЙТЫ',
    statusLive: 'РЫНОК ПОДКЛЮЧЁН',
    trades: 'сделок',
    orders: 'ордеров',
    keyMetrics: 'КЛЮЧЕВЫЕ МЕТРИКИ',
    equityCurve: 'КРИВАЯ КАПИТАЛА',
    currentValue: 'ТЕКУЩЕЕ ЗНАЧЕНИЕ',
    winRate: 'ПРОЦЕНТ ПОБЕД',
    wins: 'ПОБЕД',
    losses: 'УБЫТКОВ',
    streaks: 'СЕРИИ',
    winStreak: 'СЕРИЯ ПОБЕД',
    lossStreak: 'СЕРИЯ УБЫТКОВ',
    bestDay: 'ЛУЧШИЙ ДЕНЬ',
    worstDay: 'ХУДШИЙ ДЕНЬ',
    topTickers: 'ТОП ТИКЕРЫ',
    longVsShort: 'ЛОНГ vs ШОРТ',
    positions: 'ПОЗИЦИЙ',
    avg: 'avg',
    perTrade: '/сд',
    plByWeekday: 'P/L ПО ДНЯМ НЕДЕЛИ',
    plByHour: 'P/L ПО ЧАСАМ (РЫНОК)',
    afterHoursRestricted: 'ВНЕТОРГОВЫЕ ДАННЫЕ ОГРАНИЧЕНЫ',
    back: 'НАЗАД',
    noTradesThisDay: 'Сделок в этот день нет',
    monthlySummary: 'ПОМЕСЯЧНАЯ СВОДКА',
    month: 'МЕСЯЦ',
    avgPerTrade: 'СРЕД/СД',
    winPct: 'WIN%',
    avgHoldTime: 'СРЕДНЕЕ ВРЕМЯ УДЕРЖАНИЯ',
    avgHoldTimeDesc: 'Сколько в среднем держите позицию',
    overall: 'В ЦЕЛОМ',
    winsOnly: 'ТОЛЬКО ПРИБЫЛЬНЫЕ',
    lossesOnly: 'ТОЛЬКО УБЫТОЧНЫЕ',
    plByPositionSize: 'P/L ПО РАЗМЕРУ ПОЗИЦИИ (акций)',
    sizeRange: 'РАЗМЕР',
    rrDistribution: 'РАСПРЕДЕЛЕНИЕ R/R',
    tradingAnalytics: 'Торговая аналитика',
    noOpenPositions: 'Нет открытых позиций',
    refresh: 'Обновить',
    exportExcel: 'ЭКСПОРТ',
    symbol: 'ТИКЕР',
    chart30d: 'ГРАФИК 30Д',
    qty: 'КОЛ-ВО',
    avgPrice: 'СРЕД ЦЕНА',
    current: 'ТЕКУЩАЯ',
    mktValue: 'СТОИМОСТЬ',
    plDollar: 'P/L \$',
    plPercent: 'P/L %',
    totalValue: 'ОБЩАЯ СТОИМОСТЬ',
    noOrdersFound: 'Ордера не найдены',
    date: 'ДАТА',
    side: 'НАПРАВЛЕНИЕ',
    price: 'ЦЕНА',
    status: 'СТАТУС',
    loadingData: 'Загрузка данных...',
    sdelek: 'сделок',
    runAll: 'ЗАПУСТИТЬ ВСЁ',
    clickRunToStart: 'Нажмите RUN для запуска анализа',
    updated: 'Обновлено',
    rerun: 'ПЕРЕЗАПУСК',
    run: 'ЗАПУСК',
    noStrategies: 'Нет стратегий',
    createFirstStrategy: 'Создайте первую стратегию для организации позиций',
    allocation: 'АЛЛОКАЦИЯ',
    noPositionsAssigned: 'Нет назначенных позиций',
    unassigned: 'НЕ НАЗНАЧЕНО',
    errorTitle: 'Ошибка',
    errorBack: 'Назад',
    quickSignIn: 'Быстрый вход',
    saved: 'Сохранено',
    totalPositions: 'ИТОГО',
    navJournal: 'ДНЕВНИК',
    headerJournal: 'ТОРГОВЫЙ ДНЕВНИК',
    journalTitle: 'Торговый дневник',
    journalSubtitle: 'AI анализирует твою торговлю и пишет персональный дневник',
    journalDaily: 'СЕГОДНЯ',
    journalWeekly: 'НЕДЕЛЯ',
    journalAllTime: 'ВСЁ ВРЕМЯ',
    journalDailyDesc: 'Что ты торговал сегодня, что пошло хорошо и плохо, один вывод на завтра',
    journalWeeklyDesc: 'Паттерны недели, лучший/худший день, фокус на следующую неделю',
    journalAllTimeDesc: 'Твой торговый профиль, системные слабости, путь к стабильной прибыли',
    journalGenerate: 'СГЕНЕРИРОВАТЬ',
    journalRegenerate: 'ОБНОВИТЬ',
    journalNoData: 'Нажми кнопку выше чтобы сгенерировать запись',
    journalUpdated: 'Обновлено',
    strategyAiAnalysis: 'АНАЛИЗ СТРАТЕГИИ',
    strategyAiComparison: 'СРАВНЕНИЕ СТРАТЕГИЙ',
    strategyAiAnalysisDesc: 'AI оценит эффективность выбранной стратегии и даст рекомендации',
    strategyAiComparisonDesc: 'Сравни все стратегии и получи рекомендации по перераспределению капитала',
    strategyAiRun: 'ЗАПУСК',
    strategyAiRerun: 'ОБНОВИТЬ',
    strategyAiRunAll: 'АНАЛИЗ ВСЕХ',
    strategyAiClickRun: 'Нажми ЗАПУСК для анализа',
    strategyAiNoStrategies: 'Создайте стратегии чтобы запустить AI сравнение',
  );

  static const _en = _T._(
    navDashboard: 'DASHBOARD',
    navPortfolio: 'PORTFOLIO',
    navStrategies: 'STRATEGIES',
    navOrders: 'ORDERS',
    navAiInsights: 'AI INSIGHTS',
    navLogout: 'LOGOUT',
    navStaging: 'STAGING',
    headerPortfolio: 'PORTFOLIO',
    headerStrategies: 'STRATEGIES',
    headerOrderHistory: 'ORDER HISTORY',
    headerAiInsights: 'AI INSIGHTS',
    statusLive: 'LIVE MARKET CONNECTED',
    trades: 'trades',
    orders: 'orders',
    keyMetrics: 'KEY METRICS',
    equityCurve: 'EQUITY CURVE',
    currentValue: 'CURRENT VALUE',
    winRate: 'WIN RATE',
    wins: 'WINS',
    losses: 'LOSSES',
    streaks: 'STREAKS',
    winStreak: 'WIN STREAK',
    lossStreak: 'LOSS STREAK',
    bestDay: 'BEST DAY',
    worstDay: 'WORST DAY',
    topTickers: 'TOP TICKERS',
    longVsShort: 'LONG VS SHORT',
    positions: 'POSITIONS',
    avg: 'avg',
    perTrade: '/tr',
    plByWeekday: 'P/L BY WEEKDAY',
    plByHour: 'P/L BY HOUR (MARKET)',
    afterHoursRestricted: 'AFTER-HOURS DATA RESTRICTED',
    back: 'BACK',
    noTradesThisDay: 'No trades this day',
    monthlySummary: 'MONTHLY SUMMARY',
    month: 'MONTH',
    avgPerTrade: 'AVG/TRADE',
    winPct: 'WIN%',
    avgHoldTime: 'AVG HOLD TIME',
    avgHoldTimeDesc: 'How long you hold a position on average',
    overall: 'OVERALL',
    winsOnly: 'WINS ONLY',
    lossesOnly: 'LOSSES ONLY',
    plByPositionSize: 'P/L BY POSITION SIZE (SHARES)',
    sizeRange: 'SIZE RANGE',
    rrDistribution: 'R/R DISTRIBUTION',
    tradingAnalytics: 'Trading Analytics',
    noOpenPositions: 'No open positions',
    refresh: 'Refresh',
    exportExcel: 'EXPORT',
    symbol: 'SYMBOL',
    chart30d: '30D CHART',
    qty: 'QTY',
    avgPrice: 'AVG PRICE',
    current: 'CURRENT',
    mktValue: 'MKT VALUE',
    plDollar: 'P/L \$',
    plPercent: 'P/L %',
    totalValue: 'TOTAL VALUE',
    noOrdersFound: 'No orders found',
    date: 'DATE',
    side: 'SIDE',
    price: 'PRICE',
    status: 'STATUS',
    loadingData: 'Loading trading data...',
    sdelek: 'trades',
    runAll: 'RUN ALL',
    clickRunToStart: 'Click RUN to start analysis',
    updated: 'Updated',
    rerun: 'RERUN',
    run: 'RUN',
    noStrategies: 'No strategies yet',
    createFirstStrategy: 'Create your first strategy to organize positions',
    allocation: 'ALLOCATION',
    noPositionsAssigned: 'No positions assigned',
    unassigned: 'UNASSIGNED',
    errorTitle: 'Error',
    errorBack: 'Back',
    quickSignIn: 'Quick Sign In',
    saved: 'Saved',
    totalPositions: 'TOTAL',
    navJournal: 'JOURNAL',
    headerJournal: 'TRADING JOURNAL',
    journalTitle: 'Trading Journal',
    journalSubtitle: 'AI analyzes your trading and writes a personal journal entry',
    journalDaily: 'TODAY',
    journalWeekly: 'THIS WEEK',
    journalAllTime: 'ALL TIME',
    journalDailyDesc: 'What you traded today, what went well and wrong, one takeaway for tomorrow',
    journalWeeklyDesc: 'Weekly patterns, best/worst day, focus for next week',
    journalAllTimeDesc: 'Your trading profile, systemic weaknesses, path to consistent profitability',
    journalGenerate: 'GENERATE',
    journalRegenerate: 'REGENERATE',
    journalNoData: 'Click the button above to generate this journal entry',
    journalUpdated: 'Updated',
    strategyAiAnalysis: 'STRATEGY ANALYSIS',
    strategyAiComparison: 'COMPARE STRATEGIES',
    strategyAiAnalysisDesc: 'AI evaluates the strategy effectiveness and gives recommendations',
    strategyAiComparisonDesc: 'Compare all strategies and get capital reallocation recommendations',
    strategyAiRun: 'RUN',
    strategyAiRerun: 'RERUN',
    strategyAiRunAll: 'ANALYZE ALL',
    strategyAiClickRun: 'Click RUN to start analysis',
    strategyAiNoStrategies: 'Create strategies to enable AI comparison',
  );
}

// =============================================================================
// HELPERS
// =============================================================================

String _fmtD(double v) { final s = v >= 0 ? '+' : ''; return '$s\$${v.toStringAsFixed(2)}'; }
String _fmt(double v) { final a = v.abs(); if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M'; if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)}k'; return v.toStringAsFixed(0); }
String _fmtK(double v) { if (v.abs() >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}k'; return '\$${v.toStringAsFixed(0)}'; }
Color _plC(double v, AppColors c) => v > 0 ? c.green : v < 0 ? c.red : c.textPrimary;

Widget _hint(String key, AppColors c) {
  const h = <String, String>{
    'TOTAL P/L': 'Суммарная прибыль/убыток', 'WIN RATE %': 'Процент прибыльных сделок',
    'PROFIT FACTOR': '>1 = прибыльная торговля', 'TOTAL TRADES': 'Количество закрытых сделок',
    'AVG WIN': 'Средняя прибыль', 'AVG LOSS': 'Средний убыток',
    'R/R RATIO': 'Risk/Reward ratio', 'COMMISSION': 'Комиссия брокера',
  };
  final tip = h[key]; if (tip == null) return const SizedBox.shrink();
  return Tooltip(message: tip, waitDuration: const Duration(milliseconds: 200),
    child: MouseRegion(cursor: SystemMouseCursors.help, child: Icon(Icons.help_outline_rounded, size: 12, color: c.textSecondary)));
}
