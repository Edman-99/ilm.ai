/// Позиция из Investlink API: GET /alpaca/get_all_positions/
class TradingPositionDto {
  const TradingPositionDto({
    required this.symbol,
    required this.qty,
    required this.avgEntryPrice,
    required this.currentPrice,
    required this.marketValue,
    required this.profitCash,
    required this.profitPercent,
    required this.side,
  });

  factory TradingPositionDto.fromJson(Map<String, dynamic> json) {
    return TradingPositionDto(
      symbol: json['symbol'] as String? ?? '',
      qty: _d(json['qty']),
      avgEntryPrice: _d(json['avg_entry_price']),
      currentPrice: _d(json['current_price']),
      marketValue: _d(json['market_value'] ?? json['value']),
      profitCash: _d(json['unrealized_pl'] ?? json['profit_cash']),
      profitPercent: _d(json['unrealized_plpc'] ?? json['profit_percent']),
      side: json['side'] as String? ?? 'long',
    );
  }

  final String symbol;
  final double qty;
  final double avgEntryPrice;
  final double currentPrice;
  final double marketValue;
  final double profitCash;
  final double profitPercent;
  final String side;

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
