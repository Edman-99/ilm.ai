import 'package:flutter/material.dart';

import 'strategy_entity.dart';
import 'trading_order_dto.dart';
import 'trading_position_dto.dart';

/// Demo orders for Trading Analytics preview.
/// Realistic filled orders across popular tickers, spread over ~3 months.
final demoOrders = <TradingOrderDto>[
  // AAPL — profitable
  const TradingOrderDto(id: 'd1', symbol: 'AAPL', side: 'buy', status: 'filled', filledQty: 10, filledAvgPrice: 172.50, avgEntryPrice: 172.50, filledAt: '2026-01-15T14:30:00Z', createdAt: '2026-01-15T14:30:00Z', profitCash: 185.0, profitPerc: 10.7, commission: 0.02),
  const TradingOrderDto(id: 'd2', symbol: 'AAPL', side: 'sell', status: 'filled', filledQty: 10, filledAvgPrice: 191.00, avgEntryPrice: 172.50, filledAt: '2026-02-03T15:45:00Z', createdAt: '2026-02-03T15:45:00Z', profitCash: 185.0, profitPerc: 10.7, commission: 0.02),

  // TSLA — loss
  const TradingOrderDto(id: 'd3', symbol: 'TSLA', side: 'buy', status: 'filled', filledQty: 5, filledAvgPrice: 248.20, avgEntryPrice: 248.20, filledAt: '2026-01-22T10:15:00Z', createdAt: '2026-01-22T10:15:00Z', profitCash: -156.0, profitPerc: -12.6, commission: 0.01),
  const TradingOrderDto(id: 'd4', symbol: 'TSLA', side: 'sell', status: 'filled', filledQty: 5, filledAvgPrice: 217.00, avgEntryPrice: 248.20, filledAt: '2026-02-10T11:30:00Z', createdAt: '2026-02-10T11:30:00Z', profitCash: -156.0, profitPerc: -12.6, commission: 0.01),

  // NVDA — big win
  const TradingOrderDto(id: 'd5', symbol: 'NVDA', side: 'buy', status: 'filled', filledQty: 8, filledAvgPrice: 680.00, avgEntryPrice: 680.00, filledAt: '2026-01-28T09:35:00Z', createdAt: '2026-01-28T09:35:00Z', profitCash: 720.0, profitPerc: 13.2, commission: 0.05),
  const TradingOrderDto(id: 'd6', symbol: 'NVDA', side: 'sell', status: 'filled', filledQty: 8, filledAvgPrice: 770.00, avgEntryPrice: 680.00, filledAt: '2026-02-18T14:20:00Z', createdAt: '2026-02-18T14:20:00Z', profitCash: 720.0, profitPerc: 13.2, commission: 0.05),

  // MSFT — small win
  const TradingOrderDto(id: 'd7', symbol: 'MSFT', side: 'buy', status: 'filled', filledQty: 12, filledAvgPrice: 415.30, avgEntryPrice: 415.30, filledAt: '2026-02-05T10:00:00Z', createdAt: '2026-02-05T10:00:00Z', profitCash: 93.6, profitPerc: 1.9, commission: 0.03),
  const TradingOrderDto(id: 'd8', symbol: 'MSFT', side: 'sell', status: 'filled', filledQty: 12, filledAvgPrice: 423.10, avgEntryPrice: 415.30, filledAt: '2026-02-20T15:10:00Z', createdAt: '2026-02-20T15:10:00Z', profitCash: 93.6, profitPerc: 1.9, commission: 0.03),

  // AMZN — loss
  const TradingOrderDto(id: 'd9', symbol: 'AMZN', side: 'buy', status: 'filled', filledQty: 15, filledAvgPrice: 186.40, avgEntryPrice: 186.40, filledAt: '2026-02-12T09:45:00Z', createdAt: '2026-02-12T09:45:00Z', profitCash: -118.5, profitPerc: -4.2, commission: 0.02),
  const TradingOrderDto(id: 'd10', symbol: 'AMZN', side: 'sell', status: 'filled', filledQty: 15, filledAvgPrice: 178.50, avgEntryPrice: 186.40, filledAt: '2026-02-28T13:00:00Z', createdAt: '2026-02-28T13:00:00Z', profitCash: -118.5, profitPerc: -4.2, commission: 0.02),

  // GOOGL — win
  const TradingOrderDto(id: 'd11', symbol: 'GOOGL', side: 'buy', status: 'filled', filledQty: 20, filledAvgPrice: 155.80, avgEntryPrice: 155.80, filledAt: '2026-02-25T10:30:00Z', createdAt: '2026-02-25T10:30:00Z', profitCash: 246.0, profitPerc: 7.9, commission: 0.02),
  const TradingOrderDto(id: 'd12', symbol: 'GOOGL', side: 'sell', status: 'filled', filledQty: 20, filledAvgPrice: 168.10, avgEntryPrice: 155.80, filledAt: '2026-03-12T14:45:00Z', createdAt: '2026-03-12T14:45:00Z', profitCash: 246.0, profitPerc: 7.9, commission: 0.02),

  // META — small loss
  const TradingOrderDto(id: 'd13', symbol: 'META', side: 'buy', status: 'filled', filledQty: 6, filledAvgPrice: 510.20, avgEntryPrice: 510.20, filledAt: '2026-03-03T11:15:00Z', createdAt: '2026-03-03T11:15:00Z', profitCash: -45.0, profitPerc: -1.5, commission: 0.03),
  const TradingOrderDto(id: 'd14', symbol: 'META', side: 'sell', status: 'filled', filledQty: 6, filledAvgPrice: 502.70, avgEntryPrice: 510.20, filledAt: '2026-03-15T15:30:00Z', createdAt: '2026-03-15T15:30:00Z', profitCash: -45.0, profitPerc: -1.5, commission: 0.03),

  // AMD — win
  const TradingOrderDto(id: 'd15', symbol: 'AMD', side: 'buy', status: 'filled', filledQty: 25, filledAvgPrice: 162.40, avgEntryPrice: 162.40, filledAt: '2026-03-07T09:50:00Z', createdAt: '2026-03-07T09:50:00Z', profitCash: 340.0, profitPerc: 8.4, commission: 0.02),
  const TradingOrderDto(id: 'd16', symbol: 'AMD', side: 'sell', status: 'filled', filledQty: 25, filledAvgPrice: 176.00, avgEntryPrice: 162.40, filledAt: '2026-03-20T14:10:00Z', createdAt: '2026-03-20T14:10:00Z', profitCash: 340.0, profitPerc: 8.4, commission: 0.02),

  // SPY — short, loss
  const TradingOrderDto(id: 'd17', symbol: 'SPY', side: 'sell', status: 'filled', filledQty: 10, filledAvgPrice: 520.00, avgEntryPrice: 520.00, filledAt: '2026-03-10T10:00:00Z', createdAt: '2026-03-10T10:00:00Z', profitCash: -85.0, profitPerc: -1.6, commission: 0.01),
  const TradingOrderDto(id: 'd18', symbol: 'SPY', side: 'buy', status: 'filled', filledQty: 10, filledAvgPrice: 528.50, avgEntryPrice: 520.00, filledAt: '2026-03-18T11:20:00Z', createdAt: '2026-03-18T11:20:00Z', profitCash: -85.0, profitPerc: -1.6, commission: 0.01),
];

/// Demo open positions.
final demoPositions = <TradingPositionDto>[
  const TradingPositionDto(symbol: 'AAPL', qty: 15, avgEntryPrice: 188.30, currentPrice: 192.50, marketValue: 2887.50, profitCash: 63.0, profitPercent: 2.23, side: 'long'),
  const TradingPositionDto(symbol: 'NVDA', qty: 5, avgEntryPrice: 755.00, currentPrice: 782.40, marketValue: 3912.00, profitCash: 137.0, profitPercent: 3.62, side: 'long'),
  const TradingPositionDto(symbol: 'GOOGL', qty: 10, avgEntryPrice: 165.20, currentPrice: 170.80, marketValue: 1708.00, profitCash: 56.0, profitPercent: 3.39, side: 'long'),
  const TradingPositionDto(symbol: 'MSFT', qty: 8, avgEntryPrice: 420.50, currentPrice: 415.20, marketValue: 3321.60, profitCash: -42.4, profitPercent: -1.26, side: 'long'),
  const TradingPositionDto(symbol: 'TSLA', qty: 3, avgEntryPrice: 225.00, currentPrice: 218.60, marketValue: 655.80, profitCash: -19.2, profitPercent: -2.84, side: 'long'),
];

/// Demo strategies.
final demoStrategies = <StrategyEntity>[
  StrategyEntity(
    id: 'growth',
    name: 'Growth',
    icon: Icons.trending_up_rounded,
    color: const Color(0xFF22C55E),
    description: 'High-growth tech stocks with strong momentum',
    entries: [
      const StrategyPositionEntry(id: 0, symbol: 'NVDA', qty: 5),
      const StrategyPositionEntry(id: 1, symbol: 'TSLA', qty: 3),
    ],
  ),
  StrategyEntity(
    id: 'blue_chip',
    name: 'Blue Chip',
    icon: Icons.verified_rounded,
    color: const Color(0xFF3B82F6),
    description: 'Stable large-cap companies with consistent earnings',
    entries: [
      const StrategyPositionEntry(id: 2, symbol: 'AAPL', qty: 10),
      const StrategyPositionEntry(id: 3, symbol: 'MSFT', qty: 5),
      const StrategyPositionEntry(id: 4, symbol: 'GOOGL', qty: 2),
    ],
  ),
];
