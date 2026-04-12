import 'package:flutter/material.dart';

import 'trading_position_dto.dart';
import 'trading_order_dto.dart';

class StrategyPositionEntry {
  const StrategyPositionEntry({
    required this.id,
    required this.symbol,
    required this.qty,
  });

  final int id;
  final String symbol;
  final double qty;

  factory StrategyPositionEntry.fromJson(Map<String, dynamic> j) =>
      StrategyPositionEntry(
        id: j['id'] as int,
        symbol: j['symbol'] as String,
        qty: (j['qty'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'symbol': symbol, 'qty': qty};
}

/// A user-defined portfolio strategy grouping positions.
class StrategyEntity {
  StrategyEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.description = '',
    this.notes = '',
    this.targetPct = 0.0,
    this.entries = const [],
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final String notes;
  final double targetPct; // target allocation %
  final List<StrategyPositionEntry> entries; // symbol + qty pairs

  /// Symbols assigned to this strategy.
  List<String> get symbols => entries.map((e) => e.symbol).toList();

  /// Filter real Alpaca positions by symbols in this strategy.
  /// Returns virtual positions with qty capped to assigned qty.
  List<TradingPositionDto> filterPositions(List<TradingPositionDto> all) {
    final result = <TradingPositionDto>[];
    for (final entry in entries) {
      final pos = all.where((p) => p.symbol == entry.symbol).firstOrNull;
      if (pos == null) continue;
      // Cap qty to what was assigned (may be partial)
      final assignedQty = entry.qty.clamp(0.0, pos.qty);
      final ratio = pos.qty > 0 ? assignedQty / pos.qty : 0.0;
      result.add(TradingPositionDto(
        symbol: pos.symbol,
        qty: assignedQty,
        avgEntryPrice: pos.avgEntryPrice,
        currentPrice: pos.currentPrice,
        marketValue: pos.marketValue * ratio,
        profitCash: pos.profitCash * ratio,
        profitPercent: pos.profitPercent,
        side: pos.side,
      ));
    }
    return result;
  }

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
    final totalCost =
        positions.fold<double>(0, (s, p) => s + (p.avgEntryPrice * p.qty));
    if (totalCost == 0) return 0;
    return (totalPl(all) / totalCost) * 100;
  }

  /// Number of positions in this strategy.
  int positionCount(List<TradingPositionDto> all) =>
      filterPositions(all).length;

  /// P/L stats from order history for tickers in this strategy.
  ({double totalPl, int wins, int losses, double winRate}) historyStats(
      List<TradingOrderDto> orders) {
    final syms = symbols.toSet();
    final relevant = orders
        .where((o) => syms.contains(o.symbol) && o.profitCash != null)
        .toList();
    if (relevant.isEmpty) return (totalPl: 0, wins: 0, losses: 0, winRate: 0);
    final totalPl = relevant.fold<double>(0, (s, o) => s + o.profitCash!);
    final wins = relevant.where((o) => o.profitCash! > 0).length;
    final losses = relevant.where((o) => o.profitCash! < 0).length;
    final winRate = relevant.isNotEmpty ? wins / relevant.length * 100 : 0.0;
    return (totalPl: totalPl, wins: wins, losses: losses, winRate: winRate);
  }

  /// Deviation from target allocation in percentage points.
  double allocationDeviation(
      List<TradingPositionDto> all, double totalPortfolioValue) {
    if (totalPortfolioValue == 0) return 0;
    final actual = totalValue(all) / totalPortfolioValue * 100;
    return actual - targetPct;
  }

  StrategyEntity copyWith({
    String? name,
    IconData? icon,
    Color? color,
    String? description,
    String? notes,
    double? targetPct,
    List<StrategyPositionEntry>? entries,
  }) =>
      StrategyEntity(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        targetPct: targetPct ?? this.targetPct,
        entries: entries ?? this.entries,
      );

  factory StrategyEntity.fromJson(Map<String, dynamic> j) {
    final colorHex = (j['color'] as String? ?? '#6366F1').replaceAll('#', '');
    final colorVal = int.tryParse('FF$colorHex', radix: 16) ?? 0xFF6366F1;
    return StrategyEntity(
      id: j['id'] as String,
      name: j['name'] as String,
      description: j['description'] as String? ?? '',
      notes: j['notes'] as String? ?? '',
      icon: _iconFromName(j['icon'] as String? ?? 'pie_chart'),
      color: Color(colorVal),
      targetPct: (j['target_pct'] as num?)?.toDouble() ?? 0.0,
      entries: (j['positions'] as List<dynamic>? ?? [])
          .map((e) => StrategyPositionEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'icon': _iconToName(icon),
        'color':
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'target_pct': targetPct,
        'notes': notes,
        'positions': entries.map((e) => e.toJson()).toList(),
      };
}

// ── Icon helpers ──────────────────────────────────────────────────────────────

const _iconMap = <String, IconData>{
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

IconData _iconFromName(String name) =>
    _iconMap[name] ?? Icons.pie_chart_rounded;

String _iconToName(IconData icon) =>
    _iconMap.entries.firstWhere((e) => e.value == icon,
        orElse: () => const MapEntry('pie_chart', Icons.pie_chart_rounded)).key;
