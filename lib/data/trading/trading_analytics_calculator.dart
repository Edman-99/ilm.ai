import 'trading_analytics_entity.dart';
import 'trading_order_dto.dart';

/// Расчёт торговой аналитики из списка filled orders.
class TradingAnalyticsCalculator {
  const TradingAnalyticsCalculator._();

  static TradingAnalyticsEntity calculate(List<TradingOrderDto> orders) {
    if (orders.isEmpty) {
      return TradingAnalyticsEntity.empty();
    }

    final closing = orders.where((o) => o.profitCash != null && o.profitCash != 0).toList();
    if (closing.isEmpty) {
      return TradingAnalyticsEntity.empty();
    }

    final wins = closing.where((o) => o.profitCash! > 0).toList();
    final losses = closing.where((o) => o.profitCash! < 0).toList();

    final totalTrades = closing.length;
    final winCount = wins.length;
    final lossCount = losses.length;
    final winRate = winCount / totalTrades * 100;

    final totalPl = _sumPl(closing);
    final averagePl = totalPl / totalTrades;
    final totalWins = _sumPl(wins);
    final totalLosses = _sumPl(losses).abs();

    final averageWin = winCount > 0 ? totalWins / winCount : 0.0;
    final averageLoss = lossCount > 0 ? totalLosses / lossCount : 0.0;
    final riskRewardRatio = averageLoss > 0 ? averageWin / averageLoss : 0.0;
    final profitFactor = totalLosses > 0 ? totalWins / totalLosses : 0.0;
    final totalCommission = closing.fold<double>(0, (s, o) => s + o.commission);

    final streaks = _streaks(closing);
    final calendarPl = _calendarPl(closing);
    final bestDay = _bestDay(calendarPl);
    final worstDay = _worstDay(calendarPl);

    return TradingAnalyticsEntity(
      totalTrades: totalTrades,
      winCount: winCount,
      lossCount: lossCount,
      winRate: winRate,
      totalPl: totalPl,
      averagePl: averagePl,
      averageWin: averageWin,
      averageLoss: averageLoss,
      riskRewardRatio: riskRewardRatio,
      profitFactor: profitFactor,
      totalCommission: totalCommission,
      maxWinStreak: streaks.$1,
      maxLossStreak: streaks.$2,
      currentStreak: streaks.$3,
      currentStreakIsWin: streaks.$4,
      bestDay: bestDay,
      worstDay: worstDay,
      calendarPl: calendarPl,
      weekdayPl: _weekdayPl(closing),
      hourlyPl: _hourlyPl(closing),
      tickerPl: _tickerPl(closing),
      cumulativePl: _cumulativePl(closing),
      avgHoldTimeMinutes: _avgHold(closing),
      avgHoldTimeWinMinutes: _avgHold(wins),
      avgHoldTimeLossMinutes: _avgHold(losses),
      sidePl: _sidePl(closing),
      monthlySummary: _monthly(closing),
      rrDistribution: _rrDist(closing, averageLoss),
      tradeSizeBuckets: _sizeBuckets(closing),
    );
  }

  static double _sumPl(List<TradingOrderDto> o) =>
      o.fold<double>(0, (s, e) => s + (e.profitCash ?? 0));

  static DateTime? _parse(String raw) => raw.isEmpty ? null : DateTime.tryParse(raw);
  static DateTime _dayOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  // Streaks → (maxWin, maxLoss, current, currentIsWin)
  static (int, int, int, bool) _streaks(List<TradingOrderDto> orders) {
    final sorted = List.of(orders)
      ..sort((a, b) {
        final da = _parse(a.filledAt);
        final db = _parse(b.filledAt);
        if (da == null || db == null) {
          return 0;
        }
        return da.compareTo(db);
      });
    var maxW = 0, maxL = 0, run = 0;
    var isWin = true;
    for (final o in sorted) {
      final w = (o.profitCash ?? 0) > 0;
      if (run == 0) {
        isWin = w;
        run = 1;
      } else if (w == isWin) {
        run++;
      } else {
        if (isWin) {
          if (run > maxW) {
            maxW = run;
          }
        } else {
          if (run > maxL) {
            maxL = run;
          }
        }
        isWin = w;
        run = 1;
      }
    }
    if (isWin) {
      if (run > maxW) {
        maxW = run;
      }
    } else {
      if (run > maxL) {
        maxL = run;
      }
    }
    return (maxW, maxL, run, isWin);
  }

  static Map<DateTime, double> _calendarPl(List<TradingOrderDto> o) {
    final m = <DateTime, double>{};
    for (final e in o) {
      final d = _parse(e.filledAt);
      if (d == null) {
        continue;
      }
      final k = _dayOnly(d);
      m[k] = (m[k] ?? 0) + (e.profitCash ?? 0);
    }
    return m;
  }

  static DayPl? _bestDay(Map<DateTime, double> m) {
    if (m.isEmpty) {
      return null;
    }
    final e = m.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return DayPl(date: e.key, totalPl: e.value);
  }

  static DayPl? _worstDay(Map<DateTime, double> m) {
    if (m.isEmpty) {
      return null;
    }
    final e = m.entries.reduce((a, b) => a.value <= b.value ? a : b);
    return DayPl(date: e.key, totalPl: e.value);
  }

  static Map<int, WeekdayStats> _weekdayPl(List<TradingOrderDto> o) {
    final pl = <int, double>{};
    final cnt = <int, int>{};
    for (final e in o) {
      final d = _parse(e.filledAt);
      if (d == null) {
        continue;
      }
      pl[d.weekday] = (pl[d.weekday] ?? 0) + (e.profitCash ?? 0);
      cnt[d.weekday] = (cnt[d.weekday] ?? 0) + 1;
    }
    return {
      for (final k in pl.keys) k: WeekdayStats(totalPl: pl[k]!, tradeCount: cnt[k]!),
    };
  }

  static Map<int, double> _hourlyPl(List<TradingOrderDto> o) {
    final m = <int, double>{};
    for (final e in o) {
      final d = _parse(e.filledAt);
      if (d == null) {
        continue;
      }
      m[d.hour] = (m[d.hour] ?? 0) + (e.profitCash ?? 0);
    }
    return m;
  }

  static Map<String, TickerStats> _tickerPl(List<TradingOrderDto> o) {
    final pl = <String, double>{};
    final cnt = <String, int>{};
    final w = <String, int>{};
    for (final e in o) {
      if (e.symbol.isEmpty) {
        continue;
      }
      final p = e.profitCash ?? 0;
      pl[e.symbol] = (pl[e.symbol] ?? 0) + p;
      cnt[e.symbol] = (cnt[e.symbol] ?? 0) + 1;
      if (p > 0) {
        w[e.symbol] = (w[e.symbol] ?? 0) + 1;
      }
    }
    return {
      for (final k in pl.keys)
        k: TickerStats(totalPl: pl[k]!, tradeCount: cnt[k]!, winCount: w[k] ?? 0),
    };
  }

  static List<CumulativePlPoint> _cumulativePl(List<TradingOrderDto> o) {
    final sorted = List.of(o)
      ..sort((a, b) {
        final da = _parse(a.filledAt);
        final db = _parse(b.filledAt);
        if (da == null || db == null) {
          return 0;
        }
        return da.compareTo(db);
      });
    final pts = <CumulativePlPoint>[];
    var cum = 0.0;
    for (final e in sorted) {
      final d = _parse(e.filledAt);
      if (d == null) {
        continue;
      }
      cum += e.profitCash ?? 0;
      pts.add(CumulativePlPoint(date: d, value: cum));
    }
    return pts;
  }

  static double _avgHold(List<TradingOrderDto> o) {
    final mins = <double>[];
    for (final e in o) {
      final c = _parse(e.createdAt);
      final f = _parse(e.filledAt);
      if (c == null || f == null) {
        continue;
      }
      final m = f.difference(c).inMinutes.toDouble();
      if (m > 0) {
        mins.add(m);
      }
    }
    return mins.isEmpty ? 0 : mins.reduce((a, b) => a + b) / mins.length;
  }

  static Map<String, SideStats> _sidePl(List<TradingOrderDto> o) {
    final sides = <String, List<TradingOrderDto>>{};
    for (final e in o) {
      final k = e.side.toLowerCase() == 'sell' ? 'Short' : 'Long';
      sides.putIfAbsent(k, () => []).add(e);
    }
    return sides.map((k, list) {
      final pl = _sumPl(list);
      final w = list.where((e) => (e.profitCash ?? 0) > 0).length;
      final tw = _sumPl(list.where((e) => (e.profitCash ?? 0) > 0).toList());
      final tl = _sumPl(list.where((e) => (e.profitCash ?? 0) < 0).toList()).abs();
      return MapEntry(
        k,
        SideStats(
          totalPl: pl,
          tradeCount: list.length,
          winCount: w,
          averagePl: list.isNotEmpty ? pl / list.length : 0,
          profitFactor: tl > 0 ? tw / tl : 0,
        ),
      );
    });
  }

  static Map<String, MonthlySummary> _monthly(List<TradingOrderDto> o) {
    final m = <String, List<TradingOrderDto>>{};
    for (final e in o) {
      final d = _parse(e.filledAt);
      if (d == null) {
        continue;
      }
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      m.putIfAbsent(k, () => []).add(e);
    }
    final sorted = m.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return {for (final e in sorted) e.key: _buildMonthly(e.value)};
  }

  static MonthlySummary _buildMonthly(List<TradingOrderDto> o) {
    final pl = _sumPl(o);
    final w = o.where((e) => (e.profitCash ?? 0) > 0).length;
    final dp = _calendarPl(o);
    final best = dp.isEmpty ? 0.0 : dp.values.reduce((a, b) => a > b ? a : b);
    final worst = dp.isEmpty ? 0.0 : dp.values.reduce((a, b) => a < b ? a : b);
    return MonthlySummary(
      totalPl: pl,
      tradeCount: o.length,
      winCount: w,
      bestDayPl: best,
      worstDayPl: worst,
    );
  }

  static Map<String, int> _rrDist(List<TradingOrderDto> o, double avgLoss) {
    if (avgLoss <= 0) {
      return {};
    }
    final b = <String, int>{
      '<0.5R': 0,
      '0.5-1R': 0,
      '1-2R': 0,
      '2-3R': 0,
      '3R+': 0,
      'Loss': 0,
    };
    for (final e in o) {
      final p = e.profitCash ?? 0;
      if (p < 0) {
        b['Loss'] = (b['Loss'] ?? 0) + 1;
        continue;
      }
      final r = p / avgLoss;
      if (r < 0.5) {
        b['<0.5R'] = (b['<0.5R'] ?? 0) + 1;
      } else if (r < 1) {
        b['0.5-1R'] = (b['0.5-1R'] ?? 0) + 1;
      } else if (r < 2) {
        b['1-2R'] = (b['1-2R'] ?? 0) + 1;
      } else if (r < 3) {
        b['2-3R'] = (b['2-3R'] ?? 0) + 1;
      } else {
        b['3R+'] = (b['3R+'] ?? 0) + 1;
      }
    }
    return b;
  }

  static Map<String, TradeSizeStats> _sizeBuckets(List<TradingOrderDto> o) {
    final b = <String, List<TradingOrderDto>>{};
    for (final e in o) {
      final q = e.filledQty;
      final l = q <= 1
          ? '1'
          : q <= 5
              ? '2-5'
              : q <= 10
                  ? '6-10'
                  : q <= 50
                      ? '11-50'
                      : q <= 100
                          ? '51-100'
                          : '100+';
      b.putIfAbsent(l, () => []).add(e);
    }
    return b.map((k, list) {
      final pl = _sumPl(list);
      final w = list.where((e) => (e.profitCash ?? 0) > 0).length;
      return MapEntry(k, TradeSizeStats(totalPl: pl, tradeCount: list.length, winCount: w));
    });
  }
}
