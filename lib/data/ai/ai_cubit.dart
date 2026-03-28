import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:ai_stock_analyzer/data/trading/trading_analytics_entity.dart';
import 'package:ai_stock_analyzer/data/trading/trading_order_dto.dart';
import 'package:ai_stock_analyzer/data/trading/trading_position_dto.dart';

import 'claude_service.dart';

// ── State ──

enum AiModule { tradeReview, portfolioAdvisor, patternDetection, riskScore }

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
      AiModule.tradeReview => 'lib/data/ai/prompts/trade_review.md',
      AiModule.portfolioAdvisor => 'lib/data/ai/prompts/portfolio_advisor.md',
      AiModule.patternDetection => 'lib/data/ai/prompts/pattern_detection.md',
      AiModule.riskScore => 'lib/data/ai/prompts/risk_score.md',
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
    AiModule.tradeReview => 'You are a trading coach. Review trades and give feedback in Russian. Be specific with numbers.',
    AiModule.portfolioAdvisor => 'You are a portfolio advisor. Analyze positions and give diversification advice in Russian.',
    AiModule.patternDetection => 'You are a quant analyst. Find behavioral trading patterns in Russian. Use actual data.',
    AiModule.riskScore => 'You are a risk manager. Calculate risk score 0-100 with components. Respond in Russian.',
  };
}
