import 'dart:convert';
import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:ai_stock_analyzer/data/ai/ai_cubit.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_cubit.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_entity.dart';
import 'package:ai_stock_analyzer/data/trading/trading_position_dto.dart';
import 'package:ai_stock_analyzer/data/trading/trading_order_dto.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

// =============================================================================
// PAGE
// =============================================================================

class TradingAnalyticsPage extends StatefulWidget {
  const TradingAnalyticsPage({super.key});
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
    return Scaffold(
      backgroundColor: c.bg,
      body: BlocBuilder<TradingAnalyticsCubit, TradingAnalyticsState>(
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
            case TradingPage.orders:
              body = _OrdersPage(c: c, state: state);
            case TradingPage.ai:
              body = _AiPage(c: c, state: state);
            case TradingPage.dashboard:
              body = _Grid(a: state.analytics!, c: c, wide: wide);
          }
          return Row(children: [
            if (wide) _Sidebar(c: c, email: state.savedEmail, activePage: state.activePage),
            Expanded(child: Column(children: [
              _Header(c: c, period: _selectedPeriod, activePage: state.activePage, onPeriod: (p, f, t) { setState(() => _selectedPeriod = p); context.read<TradingAnalyticsCubit>().filterByDateRange(f, t); }),
              Expanded(child: body),
              _StatusBar(c: c, trades: state.analytics!.totalTrades),
            ])),
          ]);
        },
      ),
    );
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
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          Icon(Icons.show_chart, color: c.green, size: 20), const SizedBox(width: 8),
          Text('INVESTLINK', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ])),
        const SizedBox(height: 20),
        if (email != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email!.split('@').first.toUpperCase(), style: TextStyle(color: c.green, fontSize: 11, fontWeight: FontWeight.w700)),
          Text('STAGING', style: TextStyle(color: c.textSecondary, fontSize: 9, letterSpacing: 0.5)),
        ]))),
        const SizedBox(height: 24),
        _navBtn(Icons.dashboard_rounded, 'DASHBOARD', TradingPage.dashboard, cubit),
        _navBtn(Icons.account_balance_wallet_outlined, 'PORTFOLIO', TradingPage.portfolio, cubit),
        _navBtn(Icons.receipt_long_rounded, 'ORDERS', TradingPage.orders, cubit),
        _navBtn(Icons.auto_awesome_rounded, 'AI INSIGHTS', TradingPage.ai, cubit),
        const Spacer(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), child:
          GestureDetector(onTap: () => cubit.logout(), child: _nav(Icons.logout_rounded, 'LOGOUT', false, c)),
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
  const _Header({required this.c, required this.period, required this.activePage, required this.onPeriod});
  final AppColors c; final String period; final TradingPage activePage; final void Function(String, DateTime?, DateTime?) onPeriod;
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
              child: Text(p, style: TextStyle(color: on ? Colors.black : c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)))),
          ));
        })
      else
        Text(
          switch (activePage) { TradingPage.portfolio => 'PORTFOLIO', TradingPage.orders => 'ORDER HISTORY', TradingPage.ai => 'AI INSIGHTS', _ => '' },
          style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      const Spacer(),
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
      Text('LIVE MARKET CONNECTED', style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(width: 16),
      Text('$trades trades', style: TextStyle(color: c.textSecondary, fontSize: 9)),
    ]),
  );
}

// =============================================================================
// GRID — fixed layout matching design exactly
// =============================================================================

class _Grid extends StatelessWidget {
  const _Grid({required this.a, required this.c, required this.wide});
  final TradingAnalyticsEntity a; final AppColors c; final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) return _mobile();
    const g = 12.0;
    return ListView(padding: const EdgeInsets.all(20), children: [
      // Row 1: Key Metrics (2/3) + Equity Curve (1/3)
      SizedBox(height: 240, child: _row(g, [_f(2, _Metrics(a: a, c: c)), _f(1, _EquityCurve(a: a, c: c))])),
      SizedBox(height: g),
      // Row 2: Win Rate + Streaks + Top Tickers
      SizedBox(height: 260, child: _row(g, [_f(1, _WinRate(a: a, c: c)), _f(1, _Streaks(a: a, c: c)), _f(1, _TopTickers(a: a, c: c))])),
      SizedBox(height: g),
      // Row 3: Long vs Short + Weekday + Hourly
      SizedBox(height: 220, child: _row(g, [_f(1, _SideAnalysis(a: a, c: c)), _f(1, _WeekdayChart(a: a, c: c)), _f(1, _HourlyHeatmap(a: a, c: c))])),
      SizedBox(height: g),
      // Row 4: Calendar + Monthly + Hold Time
      SizedBox(height: 320, child: _row(g, [_f(1, _Calendar(a: a, c: c)), _f(1, _MonthlyTable(a: a, c: c)), _f(1, _HoldTime(a: a, c: c))])),
      SizedBox(height: g),
      // Row 5: Position Size + R/R Distribution
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
    _card(_Calendar(a: a, c: c)), const SizedBox(height: 12),
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

class _Metrics extends StatelessWidget {
  const _Metrics({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) {
    final row1 = [
      ('TOTAL P/L', _fmtD(a.totalPl), _plC(a.totalPl, c)),
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
      // Header row.
      Row(children: [
        Text('KEY METRICS', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const Spacer(),
        Icon(Icons.grid_view_rounded, size: 16, color: c.textSecondary.withOpacity(0.4)),
      ]),
      const SizedBox(height: 20),
      // Row 1.
      _metricRow(row1),
      Divider(color: c.border, height: 24),
      // Row 2.
      _metricRow(row2),
    ]);
  }
  Widget _metricRow(List<(String, String, Color)> items) {
    return Row(children: items.expand((m) sync* {
      if (m != items.first) yield Container(width: 1, height: 48, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 12));
      yield Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(m.$1, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(width: 4),
          _hint(m.$1),
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

class _EquityCurve extends StatelessWidget {
  const _EquityCurve({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) {
    if (a.cumulativePl.length < 2) return const SizedBox.shrink();
    final last = a.cumulativePl.last.value; final lc = last >= 0 ? c.green : c.red;
    final pts = _ds(a.cumulativePl, 150);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EQUITY CURVE', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('CURRENT VALUE', style: TextStyle(color: c.textSecondary, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(_fmtD(last), style: TextStyle(color: lc, fontSize: 24, fontWeight: FontWeight.w800)),
        ]),
      ]),
      const Spacer(),
      RepaintBoundary(child: SizedBox(height: 100, width: double.infinity, child: CustomPaint(painter: _EqP(pts: pts, lc: lc, fc: lc.withOpacity(0.1), gc: c.border)))),
    ]);
  }
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
    Text('WIN RATE', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
    const Spacer(),
    Center(child: SizedBox(width: 130, height: 130, child: Stack(alignment: Alignment.center, children: [
      SizedBox.expand(child: CircularProgressIndicator(value: a.winRate / 100, strokeWidth: 10, backgroundColor: c.border, color: c.green)),
      Text('${a.winRate.toStringAsFixed(0)}%', style: TextStyle(color: c.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
    ]))),
    const Spacer(),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _leg(c.green, '${a.winCount} WINS'), const SizedBox(width: 20), _leg(c.red, '${a.lossCount} LOSSES'),
    ]),
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
    Text('STREAKS', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _box('WIN STREAK', '${a.maxWinStreak}', c.green, Icons.trending_up)),
      const SizedBox(width: 10),
      Expanded(child: _box('LOSS STREAK', '${a.maxLossStreak}', c.red, Icons.trending_down)),
    ]),
    const Spacer(),
    if (a.bestDay != null) _day('BEST DAY: ${DateFormat('MMM dd').format(a.bestDay!.date).toUpperCase()}', a.bestDay!, c.green),
    if (a.worstDay != null) _day('WORST DAY: ${DateFormat('MMM dd').format(a.worstDay!.date).toUpperCase()}', a.worstDay!, c.red),
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

class _TopTickers extends StatelessWidget {
  const _TopTickers({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override
  Widget build(BuildContext context) {
    final sorted = a.tickerPl.entries.toList()..sort((a, b) => b.value.totalPl.compareTo(a.value.totalPl));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TOP TICKERS', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 14),
      Expanded(child: ListView.separated(
        itemCount: sorted.length,
        separatorBuilder: (_, __) => Divider(color: c.border, height: 16),
        itemBuilder: (_, i) {
          final e = sorted[i]; final cl = e.value.totalPl >= 0 ? c.green : c.red; final sign = e.value.totalPl >= 0 ? '+' : '';
          return Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: c.border.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(e.key.length > 4 ? e.key.substring(0, 4) : e.key, style: TextStyle(color: c.textPrimary, fontSize: 10, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.key, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${e.value.tradeCount} TRADES', style: TextStyle(color: c.textSecondary, fontSize: 9, letterSpacing: 0.3)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$sign\$${_fmt(e.value.totalPl)}', style: TextStyle(color: cl, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${e.value.winRate.toStringAsFixed(0)}% WIN', style: TextStyle(color: c.green, fontSize: 10)),
            ]),
          ]);
        },
      )),
    ]);
  }
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
      Text('LONG VS SHORT', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const Spacer(),
      ...a.sidePl.entries.map((e) { final isL = e.key == 'Long'; final cl = isL ? c.green : c.red; final s = e.value; final pct = total > 0 ? (s.tradeCount / total * 100).toStringAsFixed(0) : '0'; final sign = s.totalPl >= 0 ? '+' : '';
        return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isL ? Icons.trending_up : Icons.trending_down, color: cl, size: 16), const SizedBox(width: 8),
            Text('${e.key.toUpperCase()} POSITIONS', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$sign\$${_fmt(s.totalPl)} ($pct%)', style: TextStyle(color: cl, fontSize: 13, fontWeight: FontWeight.w700)),
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

class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  static const _l = {1:'MON',2:'TUE',3:'WED',4:'THU',5:'FRI'};
  @override
  Widget build(BuildContext context) {
    final wd = a.weekdayPl; if (wd.isEmpty) return const SizedBox.shrink();
    final maxA = wd.values.map((s) => s.totalPl.abs()).fold<double>(0, math.max);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('P/L BY WEEKDAY', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const Spacer(),
      SizedBox(height: 140, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _l.entries.map((e) {
        final s = wd[e.key]; final pl = s?.totalPl ?? 0; final ratio = maxA > 0 ? (pl.abs() / maxA).clamp(0.08, 1.0) : 0.08; final cl = pl >= 0 ? c.green : c.red;
        return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(_fmtK(pl), style: TextStyle(color: cl, fontSize: 11, fontWeight: FontWeight.w700)),
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
      Text('P/L BY HOUR (MARKET)', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
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
      Text('AFTER-HOURS DATA RESTRICTED', style: TextStyle(color: c.textSecondary.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
    ]);
  }
}

// =============================================================================
// CALENDAR
// =============================================================================

class _Calendar extends StatefulWidget {
  const _Calendar({required this.a, required this.c});
  final TradingAnalyticsEntity a; final AppColors c;
  @override State<_Calendar> createState() => _CalendarS();
}
class _CalendarS extends State<_Calendar> {
  late DateTime _m;
  @override void initState() { super.initState(); final cal = widget.a.calendarPl;
    _m = cal.isNotEmpty ? (() { final l = cal.keys.reduce((a, b) => a.isAfter(b) ? a : b); return DateTime(l.year, l.month); })() : DateTime(DateTime.now().year, DateTime.now().month); }
  @override void didUpdateWidget(covariant _Calendar o) { super.didUpdateWidget(o); if (widget.a.calendarPl.isNotEmpty && widget.a.calendarPl != o.a.calendarPl) { final l = widget.a.calendarPl.keys.reduce((a, b) => a.isAfter(b) ? a : b); final nm = DateTime(l.year, l.month); if (_m.year != nm.year || _m.month != nm.month) setState(() => _m = nm); } }
  @override Widget build(BuildContext context) {
    final c = widget.c; final y = _m.year, mo = _m.month;
    final days = DateUtils.getDaysInMonth(y, mo);
    final firstWd = DateTime(y, mo).weekday; // 1=Mon..7=Sun
    final offset = firstWd % 7; // Sun=0,Mon=1..Sat=6

    // Previous month trailing days
    final prevDays = DateUtils.getDaysInMonth(mo == 1 ? y - 1 : y, mo == 1 ? 12 : mo - 1);

    // Build cell data: (day, isCurrentMonth, pl?)
    final cells = <(int day, bool current)>[];
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
      Row(children: ['SU','MO','TU','WE','TH','FR','SA'].map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: c.textSecondary.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w600))))).toList()),
      const SizedBox(height: 6),
      Expanded(child: Column(children: weeks.map((week) => Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: week.map((cell) {
        final day = cell.$1; final cur = cell.$2;
        if (!cur) {
          return Expanded(child: Container(margin: const EdgeInsets.all(1),
            child: Align(alignment: Alignment.topCenter, child: Padding(padding: const EdgeInsets.only(top: 4),
              child: Text('$day', style: TextStyle(color: c.textSecondary.withOpacity(0.2), fontSize: 10))))));
        }
        final date = DateTime.utc(y, mo, day); final pl = widget.a.calendarPl[date];
        final hasPl = pl != null;
        Color? bg; Color? border;
        if (hasPl) {
          bg = pl > 0 ? c.green.withOpacity(0.12) : c.red.withOpacity(0.12);
          border = pl > 0 ? c.green.withOpacity(0.25) : c.red.withOpacity(0.25);
        }
        return Expanded(child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: border != null ? Border.all(color: border, width: 0.5) : null,
          ),
          child: Column(children: [
            const SizedBox(height: 4),
            Text('$day', style: TextStyle(color: hasPl ? c.textPrimary : c.textSecondary.withOpacity(0.3), fontSize: hasPl ? 14 : 10, fontWeight: hasPl ? FontWeight.w700 : FontWeight.normal)),
            if (hasPl) ...[
              const Spacer(),
              Text(_fmtK(pl), style: TextStyle(color: pl >= 0 ? c.green : c.red, fontSize: 9, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
            ],
          ]),
        ));
      }).toList()))).toList())),
    ]);
  }
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MONTHLY SUMMARY', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 14),
      Row(children: [
        const SizedBox(width: 70, child: Text('MONTH', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600))),
        const Expanded(child: Text('P/L', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600))),
        const SizedBox(width: 40, child: Text('WIN%', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        const SizedBox(width: 30, child: Text('#', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
      ]),
      Divider(color: c.border, height: 16),
      ...m.entries.take(6).map((e) { final s = e.value; final cl = s.totalPl >= 0 ? c.green : c.red; final sign = s.totalPl >= 0 ? '+' : '';
        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          SizedBox(width: 70, child: Text(e.key, style: TextStyle(color: c.textPrimary, fontSize: 11))),
          Expanded(child: Text('$sign\$${_fmt(s.totalPl)}', style: TextStyle(color: cl, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 40, child: Text('${s.winRate.toStringAsFixed(0)}%', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 30, child: Text('${s.tradeCount}', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
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
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('AVG HOLD TIME', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
    const SizedBox(height: 20),
    _row('OVERALL', a.avgHoldTimeMinutes, c.textPrimary),
    const SizedBox(height: 16),
    _row('WINS ONLY', a.avgHoldTimeWinMinutes, c.green),
    const SizedBox(height: 16),
    _row('LOSSES ONLY', a.avgHoldTimeLossMinutes, c.red),
  ]);
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('P/L BY POSITION SIZE (SHARES)', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 14),
      Row(children: [
        SizedBox(width: 100, child: Text('SIZE RANGE', style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600))),
        Expanded(child: Text('P/L', style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600))),
        SizedBox(width: 50, child: Text('WIN%', style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        SizedBox(width: 50, child: Text('TRADES', style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
      ]),
      Divider(color: c.border, height: 16),
      ..._order.where(b.containsKey).map((l) { final s = b[l]!; final cl = s.totalPl >= 0 ? c.green : c.red; final sign = s.totalPl >= 0 ? '+' : '';
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          SizedBox(width: 100, child: Text(l, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(child: Text('$sign\$${_fmt(s.totalPl)}', style: TextStyle(color: cl, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 50, child: Text('${s.winRate.toStringAsFixed(0)}%', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 50, child: Text('${s.tradeCount}', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
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
      Text('R/R DISTRIBUTION', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
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

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.emailCtrl, required this.passwordCtrl});
  final TextEditingController emailCtrl, passwordCtrl;
  @override Widget build(BuildContext context) { final c = AppThemeScope.of(context).colors;
    return BlocBuilder<TradingAnalyticsCubit, TradingAnalyticsState>(builder: (context, state) => Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.show_chart, size: 40, color: c.green), const SizedBox(height: 20),
        Text('Investlink Analytics', style: TextStyle(color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
        Text('Sign in with staging credentials', style: TextStyle(color: c.textSecondary, fontSize: 14)), const SizedBox(height: 32),
        TextField(controller: emailCtrl, decoration: InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: c.textSecondary, size: 18))), const SizedBox(height: 12),
        TextField(controller: passwordCtrl, obscureText: true, onSubmitted: (_) => _go(context), decoration: InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock_outlined, color: c.textSecondary, size: 18))), const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: () => _go(context), child: Text(state.hasSavedCredentials ? 'Quick Sign In' : 'Sign In'))),
        if (state.hasSavedCredentials) ...[const SizedBox(height: 12), Text('Saved: ${state.savedEmail}', style: TextStyle(color: c.textSecondary, fontSize: 12))],
      ])))));
  }
  void _go(BuildContext ctx) { final e = emailCtrl.text.trim(), p = passwordCtrl.text.trim(); if (e.isEmpty || p.isEmpty) return; ctx.read<TradingAnalyticsCubit>().loginAndLoad(e, p); }
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
      Text('Error', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      Text(message, style: TextStyle(color: c.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 24),
      ElevatedButton(onPressed: () => context.read<TradingAnalyticsCubit>().logout(), child: const Text('Back')),
    ]));
  }
}

// =============================================================================
// PORTFOLIO PAGE
// =============================================================================

class _PortfolioPage extends StatelessWidget {
  const _PortfolioPage({required this.c, required this.state});
  final AppColors c; final TradingAnalyticsState state;
  @override
  Widget build(BuildContext context) {
    if (state.positionsLoading) return Center(child: CircularProgressIndicator(color: c.green));
    final pos = state.positions;
    if (pos.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.account_balance_wallet_outlined, size: 48, color: c.textSecondary), const SizedBox(height: 12),
      Text('No open positions', style: TextStyle(color: c.textSecondary, fontSize: 16)),
      const SizedBox(height: 8),
      GestureDetector(onTap: () => context.read<TradingAnalyticsCubit>().loadPositions(),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: Text('Refresh', style: TextStyle(color: c.green, fontSize: 13)))),
    ]));

    final totalValue = pos.fold<double>(0, (s, p) => s + p.marketValue);
    final totalPl = pos.fold<double>(0, (s, p) => s + p.profitCash);
    final sparks = state.sparklines;

    return ListView(padding: const EdgeInsets.all(20), children: [
      // Summary row.
      Row(children: [
        _summaryCard('TOTAL VALUE', '\$${_fmt(totalValue)}', c.textPrimary),
        const SizedBox(width: 12),
        _summaryCard('TOTAL P/L', _fmtD(totalPl), totalPl >= 0 ? c.green : c.red),
        const SizedBox(width: 12),
        _summaryCard('POSITIONS', '${pos.length}', c.textPrimary),
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
              Text('EXPORT CSV', style: TextStyle(color: c.green, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
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
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
            SizedBox(width: 90, child: Text('SYMBOL', style: _hdr)),
            SizedBox(width: 70, child: Text('30D CHART', style: _hdr)),
            Expanded(child: Text('QTY', style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text('AVG PRICE', style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text('CURRENT', style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text('MKT VALUE', style: _hdr, textAlign: TextAlign.right)),
            Expanded(child: Text('P/L', style: _hdr, textAlign: TextAlign.right)),
            SizedBox(width: 60, child: Text('P/L %', style: _hdr, textAlign: TextAlign.right)),
          ])),
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

  Widget _summaryCard(String label, String value, Color vc) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: c.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: vc, fontSize: 22, fontWeight: FontWeight.w800)),
    ]),
  ));

  static void _exportCsv(List<TradingPositionDto> pos) {
    final buf = StringBuffer('Symbol,Qty,Avg Price,Current Price,Market Value,P/L,P/L %\n');
    for (final p in pos) {
      buf.writeln('${p.symbol},${p.qty},${p.avgEntryPrice},${p.currentPrice},${p.marketValue},${p.profitCash},${p.profitPercent}');
    }
    _downloadFile('portfolio_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv', buf.toString());
  }

  static const _hdr = TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3);
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
      Text('No orders found', style: TextStyle(color: c.textSecondary, fontSize: 16)),
      const SizedBox(height: 8),
      GestureDetector(onTap: () => context.read<TradingAnalyticsCubit>().loadOrders(),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: Text('Refresh', style: TextStyle(color: c.green, fontSize: 13)))),
    ]));

    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      // Export row.
      Row(children: [
        Text('${orders.length} orders', style: TextStyle(color: c.textSecondary, fontSize: 12)),
        const Spacer(),
        GestureDetector(
          onTap: () => _exportCsv(orders),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.download_rounded, size: 14, color: c.green),
              const SizedBox(width: 6),
              Text('EXPORT CSV', style: TextStyle(color: c.green, fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          )),
        ),
      ]),
      const SizedBox(height: 12),
      // Table.
      Expanded(child: Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
          SizedBox(width: 140, child: Text('DATE', style: _hdr)),
          SizedBox(width: 70, child: Text('SYMBOL', style: _hdr)),
          SizedBox(width: 50, child: Text('SIDE', style: _hdr)),
          Expanded(child: Text('QTY', style: _hdr, textAlign: TextAlign.right)),
          Expanded(child: Text('PRICE', style: _hdr, textAlign: TextAlign.right)),
          SizedBox(width: 70, child: Text('STATUS', style: _hdr, textAlign: TextAlign.center)),
          Expanded(child: Text('P/L', style: _hdr, textAlign: TextAlign.right)),
        ])),
        Divider(color: c.border, height: 1),
        // Rows.
        Expanded(child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (_, i) {
            final o = orders[i];
            final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
            final dateStr = dt != null ? DateFormat('MMM dd, yyyy  HH:mm').format(dt) : '-';
            final isBuy = o.side.toLowerCase() == 'buy';
            final sideC = isBuy ? c.green : c.red;
            final statusC = _statusColor(o.status, c);
            final hasPl = o.profitCash != null;
            final plC = hasPl ? (o.profitCash! >= 0 ? c.green : c.red) : c.textSecondary;
            final plSign = hasPl && o.profitCash! >= 0 ? '+' : '';

            return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Row(children: [
              SizedBox(width: 140, child: Text(dateStr, style: TextStyle(color: c.textSecondary, fontSize: 11))),
              SizedBox(width: 70, child: Text(o.symbol, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 50, child: Text(o.side.toUpperCase(), style: TextStyle(color: sideC, fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(child: Text('${o.filledQty > 0 ? o.filledQty.toStringAsFixed(0) : '-'}', style: TextStyle(color: c.textPrimary, fontSize: 11), textAlign: TextAlign.right)),
              Expanded(child: Text(o.filledAvgPrice > 0 ? '\$${o.filledAvgPrice.toStringAsFixed(2)}' : '-', style: TextStyle(color: c.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
              SizedBox(width: 70, child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusC.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(o.status.toUpperCase(), style: TextStyle(color: statusC, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ))),
              Expanded(child: Text(hasPl ? '$plSign\$${_fmt(o.profitCash!)}' : '-', style: TextStyle(color: plC, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ]));
          },
        )),
      ]),
    )),
    ]));
  }

  static void _exportCsv(List<TradingOrderDto> orders) {
    final buf = StringBuffer('Date,Symbol,Side,Qty,Price,Status,P/L\n');
    for (final o in orders) {
      final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
      final dateStr = dt != null ? DateFormat('yyyy-MM-dd HH:mm').format(dt) : '';
      buf.writeln('$dateStr,${o.symbol},${o.side},${o.filledQty},${o.filledAvgPrice},${o.status},${o.profitCash ?? ''}');
    }
    _downloadFile('orders_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv', buf.toString());
  }

  static Color _statusColor(String status, AppColors c) {
    switch (status.toLowerCase()) {
      case 'filled': return c.green;
      case 'canceled': case 'cancelled': return c.red;
      case 'partially_filled': return c.yellow;
      case 'new': case 'accepted': return const Color(0xFF818CF8);
      default: return c.textSecondary;
    }
  }

  static const _hdr = TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3);
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
          Text('Loading trading data...', style: TextStyle(color: c.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
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

class _AiPage extends StatelessWidget {
  const _AiPage({required this.c, required this.state});
  final AppColors c; final TradingAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiCubit, AiState>(builder: (context, aiState) {
      final modules = [
        (AiModule.tradeReview, 'TRADE REVIEW', Icons.rate_review_rounded, 'AI анализ последних сделок: качество входов/выходов, ошибки, рекомендации'),
        (AiModule.portfolioAdvisor, 'PORTFOLIO ADVISOR', Icons.pie_chart_rounded, 'Анализ портфеля: диверсификация, риски, рекомендации по ребалансировке'),
        (AiModule.patternDetection, 'PATTERN DETECTION', Icons.psychology_rounded, 'Поиск скрытых паттернов: лучшие часы/дни, поведенческие привычки'),
        (AiModule.riskScore, 'RISK SCORE', Icons.shield_rounded, 'Комплексный скор риска 0-100 с разбивкой по компонентам'),
      ];

      return ListView(padding: const EdgeInsets.all(20), children: [
        // Run all button.
        Row(children: [
          GestureDetector(
            onTap: () => _runAll(context),
            child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: c.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.green.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: c.green),
                const SizedBox(width: 8),
                Text('RUN ALL ANALYSIS', style: TextStyle(color: c.green, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            )),
          ),
          const SizedBox(width: 12),
          if (aiState.loading.isNotEmpty)
            Row(children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.green)),
              const SizedBox(width: 8),
              Text('Analyzing...', style: TextStyle(color: c.textSecondary, fontSize: 12)),
            ]),
        ]),
        const SizedBox(height: 20),
        // Module cards in 2x2 grid.
        for (var i = 0; i < modules.length; i += 2) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _moduleCard(context, aiState, modules[i].$1, modules[i].$2, modules[i].$3, modules[i].$4)),
            const SizedBox(width: 12),
            if (i + 1 < modules.length)
              Expanded(child: _moduleCard(context, aiState, modules[i + 1].$1, modules[i + 1].$2, modules[i + 1].$3, modules[i + 1].$4))
            else
              const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 12),
        ],
      ]);
    });
  }

  Widget _moduleCard(BuildContext ctx, AiState aiState, AiModule module, String title, IconData icon, String desc) {
    final loading = aiState.isLoading(module);
    final result = aiState.result(module);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: c.green),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const Spacer(),
          if (loading)
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.green))
          else
            GestureDetector(
              onTap: () => _runModule(ctx, module),
              child: MouseRegion(cursor: SystemMouseCursors.click, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(result != null ? 'RERUN' : 'RUN', style: TextStyle(color: c.green, fontSize: 9, fontWeight: FontWeight.w700)),
              )),
            ),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        if (result != null) ...[
          Divider(color: c.border, height: 20),
          // Timestamp.
          Text('Updated: ${DateFormat('HH:mm:ss').format(result.timestamp)}', style: TextStyle(color: c.textSecondary.withOpacity(0.5), fontSize: 9)),
          const SizedBox(height: 8),
          // AI response as markdown-like text.
          SelectableText(result.content, style: TextStyle(color: c.textPrimary, fontSize: 12, height: 1.6)),
        ] else if (!loading) ...[
          const SizedBox(height: 16),
          Center(child: Text('Click RUN to start analysis', style: TextStyle(color: c.textSecondary.withOpacity(0.4), fontSize: 11))),
        ],
      ]),
    );
  }

  void _runModule(BuildContext ctx, AiModule module) {
    final ai = ctx.read<AiCubit>();
    switch (module) {
      case AiModule.tradeReview:
        ai.runTradeReview(state.allOrders);
      case AiModule.portfolioAdvisor:
        ai.runPortfolioAdvisor(state.positions);
      case AiModule.patternDetection:
        if (state.analytics != null) ai.runPatternDetection(state.analytics!);
      case AiModule.riskScore:
        if (state.analytics != null) ai.runRiskScore(analytics: state.analytics!, positions: state.positions);
    }
  }

  void _runAll(BuildContext ctx) {
    final ai = ctx.read<AiCubit>();
    ai.runTradeReview(state.allOrders);
    if (state.positions.isNotEmpty) ai.runPortfolioAdvisor(state.positions);
    if (state.analytics != null) {
      ai.runPatternDetection(state.analytics!);
      ai.runRiskScore(analytics: state.analytics!, positions: state.positions);
    }
  }
}

// =============================================================================
// CSV DOWNLOAD (web)
// =============================================================================

void _downloadFile(String filename, String content) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

// =============================================================================
// HELPERS
// =============================================================================

String _fmtD(double v) { final s = v >= 0 ? '+' : ''; return '$s\$${v.toStringAsFixed(2)}'; }
String _fmt(double v) { final a = v.abs(); if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M'; if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)}k'; return v.toStringAsFixed(0); }
String _fmtK(double v) { if (v.abs() >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}k'; return '\$${v.toStringAsFixed(0)}'; }
Color _plC(double v, AppColors c) => v > 0 ? c.green : v < 0 ? c.red : c.textPrimary;

Widget _hint(String key) {
  const h = <String, String>{
    'TOTAL P/L': 'Суммарная прибыль/убыток', 'WIN RATE %': 'Процент прибыльных сделок',
    'PROFIT FACTOR': '>1 = прибыльная торговля', 'TOTAL TRADES': 'Количество закрытых сделок',
    'AVG WIN': 'Средняя прибыль', 'AVG LOSS': 'Средний убыток',
    'R/R RATIO': 'Risk/Reward ratio', 'COMMISSION': 'Комиссия брокера',
  };
  final tip = h[key]; if (tip == null) return const SizedBox.shrink();
  return Tooltip(message: tip, waitDuration: const Duration(milliseconds: 200),
    child: const MouseRegion(cursor: SystemMouseCursors.help, child: Icon(Icons.help_outline_rounded, size: 12, color: Color(0xFF64748B))));
}
