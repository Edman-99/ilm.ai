import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:ai_stock_analyzer/data/trading/trading_analytics_entity.dart';
import 'package:ai_stock_analyzer/data/trading/trading_order_dto.dart';
import 'package:ai_stock_analyzer/data/trading/trading_position_dto.dart';
import 'package:ai_stock_analyzer/data/trading/strategy_entity.dart';

import 'claude_service.dart';

// ── State ──

enum AiModule {
  tradeReview, portfolioAdvisor, patternDetection, riskScore,
  journalDaily, journalWeekly, journalAllTime,
  strategyAnalysis, strategyComparison,
}

class AiAnalysis {
  const AiAnalysis({required this.module, required this.content, required this.timestamp});
  final AiModule module;
  final String content;
  final DateTime timestamp;
}

class AiState extends Equatable {
  const AiState({
    this.results = const {},
    this.loading = const {},
    this.error,
  });

  final Map<AiModule, AiAnalysis> results;
  final Set<AiModule> loading;
  final String? error;

  bool isLoading(AiModule m) => loading.contains(m);
  AiAnalysis? result(AiModule m) => results[m];

  AiState copyWith({
    Map<AiModule, AiAnalysis>? results,
    Set<AiModule>? loading,
    String? error,
  }) => AiState(
    results: results ?? this.results,
    loading: loading ?? this.loading,
    error: error,
  );

  @override
  List<Object?> get props => [results.length, loading.length, error];
}

// ── Cubit ──

class AiCubit extends Cubit<AiState> {
  AiCubit() : _claude = ClaudeService(), super(const AiState());

  final ClaudeService _claude;

  // Cached prompts.
  final _prompts = <AiModule, String>{};

  Future<String> _loadPrompt(AiModule module) async {
    if (_prompts.containsKey(module)) return _prompts[module]!;
    final path = switch (module) {
      AiModule.tradeReview        => 'lib/data/ai/prompts/trade_review.md',
      AiModule.portfolioAdvisor   => 'lib/data/ai/prompts/portfolio_advisor.md',
      AiModule.patternDetection   => 'lib/data/ai/prompts/pattern_detection.md',
      AiModule.riskScore          => 'lib/data/ai/prompts/risk_score.md',
      AiModule.journalDaily       => 'lib/data/ai/prompts/journal_daily.md',
      AiModule.journalWeekly      => 'lib/data/ai/prompts/journal_weekly.md',
      AiModule.journalAllTime     => 'lib/data/ai/prompts/journal_alltime.md',
      AiModule.strategyAnalysis   => 'lib/data/ai/prompts/strategy_analysis.md',
      AiModule.strategyComparison => 'lib/data/ai/prompts/strategy_comparison.md',
    };
    try {
      final content = await rootBundle.loadString(path);
      _prompts[module] = content;
      return content;
    } catch (_) {
      // Fallback: hardcoded short prompts.
      return _fallbackPrompt(module);
    }
  }

  /// Run Trade Review analysis.
  Future<void> runTradeReview(List<TradingOrderDto> orders) async {
    const m = AiModule.tradeReview;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final recent = orders.take(30).toList();
      final data = recent.map((o) => {
        'symbol': o.symbol, 'side': o.side, 'qty': o.filledQty,
        'price': o.filledAvgPrice, 'entryPrice': o.avgEntryPrice,
        'pl': o.profitCash, 'plPct': o.profitPerc,
        'filledAt': o.filledAt, 'createdAt': o.createdAt,
        'commission': o.commission,
      }).toList();

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Проанализируй последние ${recent.length} сделок:\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  /// Run Portfolio Advisor analysis.
  Future<void> runPortfolioAdvisor(List<TradingPositionDto> positions) async {
    const m = AiModule.portfolioAdvisor;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final totalValue = positions.fold<double>(0, (s, p) => s + p.marketValue);
      final data = {
        'totalValue': totalValue,
        'positions': positions.map((p) => {
          'symbol': p.symbol, 'qty': p.qty, 'avgEntryPrice': p.avgEntryPrice,
          'currentPrice': p.currentPrice, 'marketValue': p.marketValue,
          'pl': p.profitCash, 'plPct': p.profitPercent, 'side': p.side,
          'portfolioPct': totalValue > 0 ? (p.marketValue / totalValue * 100).toStringAsFixed(1) : '0',
        }).toList(),
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Проанализируй портфель:\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  /// Run Pattern Detection analysis.
  Future<void> runPatternDetection(TradingAnalyticsEntity analytics) async {
    const m = AiModule.patternDetection;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final data = {
        'totalTrades': analytics.totalTrades, 'winRate': analytics.winRate,
        'profitFactor': analytics.profitFactor, 'totalPl': analytics.totalPl,
        'avgWin': analytics.averageWin, 'avgLoss': analytics.averageLoss,
        'riskRewardRatio': analytics.riskRewardRatio,
        'maxWinStreak': analytics.maxWinStreak, 'maxLossStreak': analytics.maxLossStreak,
        'avgHoldTimeMin': analytics.avgHoldTimeMinutes,
        'avgHoldWinMin': analytics.avgHoldTimeWinMinutes,
        'avgHoldLossMin': analytics.avgHoldTimeLossMinutes,
        'weekdayPl': analytics.weekdayPl.map((k, v) => MapEntry(k.toString(), {'pl': v.totalPl, 'trades': v.tradeCount, 'avgPl': v.averagePl})),
        'hourlyPl': analytics.hourlyPl.map((k, v) => MapEntry(k.toString(), v)),
        'tickerPl': analytics.tickerPl.map((k, v) => MapEntry(k, {'pl': v.totalPl, 'trades': v.tradeCount, 'winRate': v.winRate})),
        'tradeSizeBuckets': analytics.tradeSizeBuckets.map((k, v) => MapEntry(k, {'pl': v.totalPl, 'trades': v.tradeCount, 'winRate': v.winRate})),
        'sidePl': analytics.sidePl.map((k, v) => MapEntry(k, {'pl': v.totalPl, 'trades': v.tradeCount, 'winRate': v.winRate})),
        'monthlySummary': analytics.monthlySummary.map((k, v) => MapEntry(k, {'pl': v.totalPl, 'trades': v.tradeCount, 'winRate': v.winRate})),
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Найди паттерны в торговле:\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  /// Run Risk Score analysis.
  Future<void> runRiskScore({
    required TradingAnalyticsEntity analytics,
    required List<TradingPositionDto> positions,
  }) async {
    const m = AiModule.riskScore;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final totalValue = positions.fold<double>(0, (s, p) => s + p.marketValue);
      final data = {
        'analytics': {
          'totalTrades': analytics.totalTrades, 'winRate': analytics.winRate,
          'profitFactor': analytics.profitFactor, 'totalPl': analytics.totalPl,
          'riskRewardRatio': analytics.riskRewardRatio,
          'maxWinStreak': analytics.maxWinStreak, 'maxLossStreak': analytics.maxLossStreak,
          'monthlySummary': analytics.monthlySummary.map((k, v) => MapEntry(k, {'pl': v.totalPl, 'trades': v.tradeCount})),
        },
        'portfolio': {
          'totalValue': totalValue,
          'positionCount': positions.length,
          'positions': positions.map((p) => {
            'symbol': p.symbol, 'marketValue': p.marketValue,
            'pct': totalValue > 0 ? (p.marketValue / totalValue * 100) : 0,
            'pl': p.profitCash,
          }).toList(),
        },
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Рассчитай Risk Score:\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  // ── Journal ──

  Future<void> runJournalDaily(List<TradingOrderDto> orders) async {
    const m = AiModule.journalDaily;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayOrders = orders.where((o) {
        final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
        return dt != null && !dt.isBefore(today);
      }).toList();

      final trades = todayOrders.map((o) => {
        'symbol': o.symbol, 'side': o.side, 'qty': o.filledQty,
        'price': o.filledAvgPrice, 'pl': o.profitCash, 'plPct': o.profitPerc,
        'time': o.filledAt,
      }).toList();

      final totalPl = todayOrders.fold<double>(0, (s, o) => s + (o.profitCash ?? 0));
      final wins = todayOrders.where((o) => (o.profitCash ?? 0) > 0).toList();
      final losses = todayOrders.where((o) => (o.profitCash ?? 0) < 0).toList();
      final best = todayOrders.isEmpty ? null : todayOrders.reduce((a, b) => (a.profitCash ?? 0) > (b.profitCash ?? 0) ? a : b);
      final worst = todayOrders.isEmpty ? null : todayOrders.reduce((a, b) => (a.profitCash ?? 0) < (b.profitCash ?? 0) ? a : b);

      final data = {
        'trades': trades,
        'summary': {
          'totalPl': totalPl,
          'tradeCount': todayOrders.length,
          'wins': wins.length,
          'losses': losses.length,
          'bestTrade': best == null ? null : {'symbol': best.symbol, 'pl': best.profitCash},
          'worstTrade': worst == null ? null : {'symbol': worst.symbol, 'pl': worst.profitCash},
        },
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Напиши дневник за сегодня (${_fmtDate(today)}):\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  Future<void> runJournalWeekly(List<TradingOrderDto> orders) async {
    const m = AiModule.journalWeekly;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final from = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final weekOrders = orders.where((o) {
        final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
        return dt != null && !dt.isBefore(from);
      }).toList();

      final totalPl = weekOrders.fold<double>(0, (s, o) => s + (o.profitCash ?? 0));
      final wins = weekOrders.where((o) => (o.profitCash ?? 0) > 0).length;
      final winRate = weekOrders.isEmpty ? 0.0 : wins / weekOrders.length * 100;
      final avgWin = wins > 0 ? weekOrders.where((o) => (o.profitCash ?? 0) > 0).fold<double>(0, (s, o) => s + (o.profitCash ?? 0)) / wins : 0.0;
      final lossCount = weekOrders.where((o) => (o.profitCash ?? 0) < 0).length;
      final avgLoss = lossCount > 0 ? weekOrders.where((o) => (o.profitCash ?? 0) < 0).fold<double>(0, (s, o) => s + (o.profitCash ?? 0)).abs() / lossCount : 0.0;

      // Daily breakdown
      final dailyPl = <String, Map<String, dynamic>>{};
      for (final o in weekOrders) {
        final dt = DateTime.tryParse(o.filledAt.isNotEmpty ? o.filledAt : o.createdAt);
        if (dt == null) continue;
        final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
        dailyPl[key] = {
          'pl': ((dailyPl[key]?['pl'] as num? ?? 0) + (o.profitCash ?? 0)),
          'tradeCount': ((dailyPl[key]?['tradeCount'] as num? ?? 0) + 1),
        };
      }

      // Top symbols
      final symPl = <String, double>{};
      final symCnt = <String, int>{};
      for (final o in weekOrders) {
        symPl[o.symbol] = (symPl[o.symbol] ?? 0) + (o.profitCash ?? 0);
        symCnt[o.symbol] = (symCnt[o.symbol] ?? 0) + 1;
      }
      final topSymbols = symPl.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final bestDay = dailyPl.isEmpty ? null : dailyPl.entries.reduce((a, b) => (a.value['pl'] as double) > (b.value['pl'] as double) ? a : b);
      final worstDay = dailyPl.isEmpty ? null : dailyPl.entries.reduce((a, b) => (a.value['pl'] as double) < (b.value['pl'] as double) ? a : b);

      final data = {
        'trades': weekOrders.map((o) => {
          'symbol': o.symbol, 'side': o.side, 'qty': o.filledQty,
          'price': o.filledAvgPrice, 'pl': o.profitCash, 'plPct': o.profitPerc,
          'filledAt': o.filledAt,
        }).toList(),
        'summary': {
          'totalPl': totalPl, 'tradeCount': weekOrders.length,
          'winRate': winRate, 'avgWin': avgWin, 'avgLoss': avgLoss,
          'bestDay': bestDay == null ? null : {'date': bestDay.key, 'pl': bestDay.value['pl']},
          'worstDay': worstDay == null ? null : {'date': worstDay.key, 'pl': worstDay.value['pl']},
          'rr': avgLoss > 0 ? avgWin / avgLoss : 0,
        },
        'dailyBreakdown': dailyPl,
        'topSymbols': topSymbols.take(5).map((e) => {
          'symbol': e.key, 'pl': e.value, 'trades': symCnt[e.key],
        }).toList(),
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Напиши недельный обзор (с ${_fmtDate(from)}):\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  Future<void> runJournalAllTime(TradingAnalyticsEntity analytics) async {
    const m = AiModule.journalAllTime;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final data = {
        'summary': {
          'totalTrades': analytics.totalTrades, 'winRate': analytics.winRate,
          'profitFactor': analytics.profitFactor, 'totalPl': analytics.totalPl,
          'rr': analytics.riskRewardRatio, 'avgWin': analytics.averageWin,
          'avgLoss': analytics.averageLoss, 'maxWinStreak': analytics.maxWinStreak,
          'maxLossStreak': analytics.maxLossStreak,
        },
        'monthlyBreakdown': analytics.monthlySummary.map((k, v) => MapEntry(k, {
          'pl': v.totalPl, 'trades': v.tradeCount, 'winRate': v.winRate,
        })),
        'hourlyPerformance': analytics.hourlyPl.map((k, v) => MapEntry(k.toString(), v)),
        'tickerPerformance': analytics.tickerPl.entries.map((e) => {
          'symbol': e.key, 'pl': e.value.totalPl,
          'trades': e.value.tradeCount, 'winRate': e.value.winRate,
        }).toList(),
        'sidePerformance': analytics.sidePl.map((k, v) => MapEntry(k, {
          'pl': v.totalPl, 'trades': v.tradeCount, 'winRate': v.winRate,
        })),
        'holdTimeStats': {
          'avgMinutes': analytics.avgHoldTimeMinutes,
          'winAvgMinutes': analytics.avgHoldTimeWinMinutes,
          'lossAvgMinutes': analytics.avgHoldTimeLossMinutes,
        },
        'tradeSizePerformance': analytics.tradeSizeBuckets.entries.map((e) => {
          'sizeRange': e.key, 'pl': e.value.totalPl,
          'trades': e.value.tradeCount, 'winRate': e.value.winRate,
        }).toList(),
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Напиши полный анализ торговой истории:\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  // ── Strategy AI ──

  Future<void> runStrategyAnalysis(
    StrategyEntity strategy,
    List<TradingPositionDto> allPositions,
  ) async {
    const m = AiModule.strategyAnalysis;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final positions = strategy.filterPositions(allPositions);
      final totalValue = strategy.totalValue(allPositions);
      final totalPl = strategy.totalPl(allPositions);

      final data = {
        'strategy': {
          'name': strategy.name,
          'description': strategy.description,
          'positionCount': positions.length,
        },
        'positions': positions.map((p) => {
          'symbol': p.symbol, 'qty': p.qty,
          'avgEntry': p.avgEntryPrice, 'currentPrice': p.currentPrice,
          'marketValue': p.marketValue, 'pl': p.profitCash, 'plPct': p.profitPercent,
          'portfolioPct': totalValue > 0 ? (p.marketValue / totalValue * 100).toStringAsFixed(1) : '0',
        }).toList(),
        'totals': {
          'totalValue': totalValue, 'totalPl': totalPl,
          'avgPlPct': strategy.avgPlPercent(allPositions),
          'largestPosition': positions.isEmpty ? null : positions.reduce((a, b) => a.marketValue > b.marketValue ? a : b).symbol,
        },
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Проанализируй стратегию "${strategy.name}":\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  Future<void> runStrategyComparison(
    List<StrategyEntity> strategies,
    List<TradingPositionDto> allPositions,
  ) async {
    const m = AiModule.strategyComparison;
    emit(state.copyWith(loading: {...state.loading, m}));
    try {
      final prompt = await _loadPrompt(m);
      final totalPortfolioValue = allPositions.fold<double>(0, (s, p) => s + p.marketValue);
      final assignedSymbols = strategies.expand((s) => s.symbols).toSet();
      final unassigned = allPositions.where((p) => !assignedSymbols.contains(p.symbol)).toList();

      final data = {
        'totalPortfolioValue': totalPortfolioValue,
        'strategies': strategies.map((s) {
          final positions = s.filterPositions(allPositions);
          final val = s.totalValue(allPositions);
          return {
            'name': s.name, 'positionCount': positions.length,
            'totalValue': val, 'totalPl': s.totalPl(allPositions),
            'avgPlPct': s.avgPlPercent(allPositions),
            'allocationPct': totalPortfolioValue > 0 ? (val / totalPortfolioValue * 100).toStringAsFixed(1) : '0',
            'positions': positions.map((p) => {
              'symbol': p.symbol, 'marketValue': p.marketValue,
              'pl': p.profitCash, 'plPct': p.profitPercent,
            }).toList(),
          };
        }).toList(),
        'unassigned': {
          'positionCount': unassigned.length,
          'totalValue': unassigned.fold<double>(0, (s, p) => s + p.marketValue),
          'allocationPct': totalPortfolioValue > 0
            ? (unassigned.fold<double>(0, (s, p) => s + p.marketValue) / totalPortfolioValue * 100).toStringAsFixed(1)
            : '0',
        },
      };

      final response = await _claude.analyze(
        systemPrompt: prompt,
        userMessage: 'Сравни ${strategies.length} стратегии и дай рекомендации:\n${jsonEncode(data)}',
      );
      _emitResult(m, response);
    } catch (e) {
      _emitError(m, e);
    }
  }

  static String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  void _emitResult(AiModule m, String content) {
    final newLoading = Set<AiModule>.from(state.loading)..remove(m);
    final newResults = Map<AiModule, AiAnalysis>.from(state.results)
      ..[m] = AiAnalysis(module: m, content: content, timestamp: DateTime.now());
    emit(state.copyWith(results: newResults, loading: newLoading));
  }

  void _emitError(AiModule m, Object e) {
    final newLoading = Set<AiModule>.from(state.loading)..remove(m);
    emit(state.copyWith(loading: newLoading, error: e.toString()));
  }

  static String _fallbackPrompt(AiModule m) => switch (m) {
    AiModule.tradeReview        => 'You are a trading coach. Review trades and give feedback in Russian. Be specific with numbers.',
    AiModule.portfolioAdvisor   => 'You are a portfolio advisor. Analyze positions and give diversification advice in Russian.',
    AiModule.patternDetection   => 'You are a quant analyst. Find behavioral trading patterns in Russian. Use actual data.',
    AiModule.riskScore          => 'You are a risk manager. Calculate risk score 0-100 with components. Respond in Russian.',
    AiModule.journalDaily       => 'Ты торговый коуч. Напиши дневник за сегодня от второго лица. Конкретно, с числами.',
    AiModule.journalWeekly      => 'Ты торговый ментор. Напиши недельный обзор торговли. Найди паттерны и дай выводы.',
    AiModule.journalAllTime     => 'Ты торговый психолог. Проанализируй всю историю торговли. Найди сильные и слабые стороны.',
    AiModule.strategyAnalysis   => 'Ты портфельный стратег. Оцени эффективность стратегии. Дай конкретные рекомендации.',
    AiModule.strategyComparison => 'Ты CIO. Сравни стратегии портфеля и дай рекомендации по аллокации капитала.',
  };
}
