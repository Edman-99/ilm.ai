import 'package:flutter/material.dart';

import 'trading_position_dto.dart';

/// A user-defined portfolio strategy grouping positions.
class StrategyEntity {
  StrategyEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.description = '',
    this.symbols = const [],
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> symbols; // tickers assigned to this strategy

  /// Filter positions that belong to this strategy.
  List<TradingPositionDto> filterPositions(List<TradingPositionDto> all) =>
      all.where((p) => symbols.contains(p.symbol)).toList();

  /// Total market value of positions in this strategy.
  double totalValue(List<TradingPositionDto> all) =>
      filterPositions(all).fold(0, (s, p) => s + p.marketValue);

  /// Total P/L of positions in this strategy.
  double totalPl(List<TradingPositionDto> all) =>
      filterPositions(all).fold(0, (s, p) => s + p.profitCash);

  /// Weighted average P/L % for this strategy.
  double avgPlPercent(List<TradingPositionDto> all) {
    final positions = filterPositions(all);
    if (positions.isEmpty) return 0;
    final totalCost = positions.fold<double>(
        0, (s, p) => s + (p.avgEntryPrice * p.qty));
    if (totalCost == 0) return 0;
    return (totalPl(all) / totalCost) * 100;
  }

  /// Number of positions in this strategy.
  int positionCount(List<TradingPositionDto> all) =>
      filterPositions(all).length;

  StrategyEntity copyWith({
    String? name,
    IconData? icon,
    Color? color,
    String? description,
    List<String>? symbols,
  }) =>
      StrategyEntity(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        description: description ?? this.description,
        symbols: symbols ?? this.symbols,
      );
}
