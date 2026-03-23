/// Результат AI-анализа акции.
class StockAnalysisDto {
  const StockAnalysisDto({
    required this.ticker,
    required this.mode,
    required this.modeDescription,
    required this.price,
    required this.change1m,
    required this.rsi,
    required this.sma20,
    required this.sma50,
    required this.macd,
    required this.macdSignal,
    required this.bbUpper,
    required this.bbLower,
    required this.atr,
    required this.trend,
    required this.score,
    required this.analysis,
  });

  factory StockAnalysisDto.fromJson(Map<String, dynamic> json) {
    return StockAnalysisDto(
      ticker: json['ticker'] as String? ?? '',
      mode: json['mode'] as String? ?? 'full',
      modeDescription: json['mode_description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      change1m: (json['change_1m'] as num?)?.toDouble() ?? 0,
      rsi: (json['rsi'] as num?)?.toDouble() ?? 0,
      sma20: (json['sma20'] as num?)?.toDouble() ?? 0,
      sma50: (json['sma50'] as num?)?.toDouble() ?? 0,
      macd: (json['macd'] as num?)?.toDouble() ?? 0,
      macdSignal: (json['macd_signal'] as num?)?.toDouble() ?? 0,
      bbUpper: (json['bb_upper'] as num?)?.toDouble() ?? 0,
      bbLower: (json['bb_lower'] as num?)?.toDouble() ?? 0,
      atr: (json['atr'] as num?)?.toDouble() ?? 0,
      trend: json['trend'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      analysis: json['analysis'] as String? ?? '',
    );
  }

  final String ticker;
  final String mode;
  final String modeDescription;
  final double price;
  final double change1m;
  final double rsi;
  final double sma20;
  final double sma50;
  final double macd;
  final double macdSignal;
  final double bbUpper;
  final double bbLower;
  final double atr;
  final String trend;
  final int score;
  final String analysis;

  bool get isBullish => trend.toLowerCase().contains('бычий');
}
