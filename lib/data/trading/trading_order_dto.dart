/// Минимальная модель filled order из Investlink API.
class TradingOrderDto {
  const TradingOrderDto({
    required this.id,
    required this.symbol,
    required this.side,
    required this.status,
    required this.filledQty,
    required this.filledAvgPrice,
    required this.filledAt,
    required this.createdAt,
    required this.profitCash,
    required this.profitPerc,
    required this.avgEntryPrice,
    required this.commission,
  });

  factory TradingOrderDto.fromJson(Map<String, dynamic> json) {
    return TradingOrderDto(
      id: json['id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      side: json['side'] as String? ?? '',
      status: json['status'] as String? ?? '',
      filledQty: _toDouble(json['filled_qty']),
      filledAvgPrice: _toDouble(json['filled_avg_price']),
      filledAt: json['filled_at'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      profitCash: _toNullableDouble(json['profit_cash']),
      profitPerc: _toNullableDouble(json['profit_percent']),
      avgEntryPrice: _toDouble(json['avg_entry_price']),
      commission: _toDouble(json['commission']),
    );
  }

  final String id;
  final String symbol;
  final String side;
  final String status;
  final double filledQty;
  final double filledAvgPrice;
  final String filledAt;
  final String createdAt;
  final double? profitCash;
  final double? profitPerc;
  final double avgEntryPrice;
  final double commission;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
