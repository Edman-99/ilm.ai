/// Результат расчёта торговой аналитики (web version).
class TradingAnalyticsEntity {
  const TradingAnalyticsEntity({
    required this.totalTrades,
    required this.winRate,
    required this.totalPl,
    required this.averagePl,
    required this.averageWin,
    required this.averageLoss,
    required this.riskRewardRatio,
    required this.profitFactor,
    required this.maxWinStreak,
    required this.maxLossStreak,
    required this.currentStreak,
    required this.currentStreakIsWin,
    required this.bestDay,
    required this.worstDay,
    required this.calendarPl,
    required this.weekdayPl,
    required this.hourlyPl,
    required this.tickerPl,
    required this.winCount,
    required this.lossCount,
    required this.totalCommission,
    required this.cumulativePl,
    required this.avgHoldTimeMinutes,
    required this.avgHoldTimeWinMinutes,
    required this.avgHoldTimeLossMinutes,
    required this.sidePl,
    required this.monthlySummary,
    required this.rrDistribution,
    required this.tradeSizeBuckets,
  });

  factory TradingAnalyticsEntity.empty() => const TradingAnalyticsEntity(
        totalTrades: 0, winRate: 0, totalPl: 0, averagePl: 0,
        averageWin: 0, averageLoss: 0, riskRewardRatio: 0, profitFactor: 0,
        maxWinStreak: 0, maxLossStreak: 0, currentStreak: 0,
        currentStreakIsWin: true, bestDay: null, worstDay: null,
        calendarPl: {}, weekdayPl: {}, hourlyPl: {}, tickerPl: {},
        winCount: 0, lossCount: 0, totalCommission: 0, cumulativePl: [],
        avgHoldTimeMinutes: 0, avgHoldTimeWinMinutes: 0,
        avgHoldTimeLossMinutes: 0, sidePl: {}, monthlySummary: {},
        rrDistribution: {}, tradeSizeBuckets: {},
      );

  final int totalTrades, winCount, lossCount;
  final double winRate, totalPl, averagePl, averageWin, averageLoss;
  final double riskRewardRatio, profitFactor, totalCommission;
  final int maxWinStreak, maxLossStreak, currentStreak;
  final bool currentStreakIsWin;
  final DayPl? bestDay, worstDay;
  final Map<DateTime, double> calendarPl;
  final Map<int, WeekdayStats> weekdayPl;
  final Map<int, double> hourlyPl;
  final Map<String, TickerStats> tickerPl;
  final List<CumulativePlPoint> cumulativePl;
  final double avgHoldTimeMinutes, avgHoldTimeWinMinutes, avgHoldTimeLossMinutes;
  final Map<String, SideStats> sidePl;
  final Map<String, MonthlySummary> monthlySummary;
  final Map<String, int> rrDistribution;
  final Map<String, TradeSizeStats> tradeSizeBuckets;
}

class WeekdayStats {
  const WeekdayStats({required this.totalPl, required this.tradeCount});
  final double totalPl;
  final int tradeCount;
  double get averagePl => tradeCount > 0 ? totalPl / tradeCount : 0;
}

class TickerStats {
  const TickerStats({required this.totalPl, required this.tradeCount, required this.winCount});
  final double totalPl;
  final int tradeCount;
  final int winCount;
  double get winRate => tradeCount > 0 ? winCount / tradeCount * 100 : 0;
}

class DayPl {
  const DayPl({required this.date, required this.totalPl});
  final DateTime date;
  final double totalPl;
}

class CumulativePlPoint {
  const CumulativePlPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class SideStats {
  const SideStats({required this.totalPl, required this.tradeCount, required this.winCount, required this.averagePl, required this.profitFactor});
  final double totalPl;
  final int tradeCount;
  final int winCount;
  final double averagePl, profitFactor;
  double get winRate => tradeCount > 0 ? winCount / tradeCount * 100 : 0;
}

class MonthlySummary {
  const MonthlySummary({required this.totalPl, required this.tradeCount, required this.winCount, required this.bestDayPl, required this.worstDayPl});
  final double totalPl;
  final int tradeCount, winCount;
  final double bestDayPl, worstDayPl;
  double get winRate => tradeCount > 0 ? winCount / tradeCount * 100 : 0;
}

class TradeSizeStats {
  const TradeSizeStats({required this.totalPl, required this.tradeCount, required this.winCount});
  final double totalPl;
  final int tradeCount, winCount;
  double get winRate => tradeCount > 0 ? winCount / tradeCount * 100 : 0;
  double get averagePl => tradeCount > 0 ? totalPl / tradeCount : 0;
}
