/// Allocation item from portfolio-builder API.
class PortfolioAllocation {
  const PortfolioAllocation({
    required this.ticker,
    required this.name,
    required this.assetClass,
    required this.percentage,
    required this.amount,
    required this.shares,
    required this.price,
  });

  factory PortfolioAllocation.fromJson(Map<String, dynamic> json) {
    return PortfolioAllocation(
      ticker: json['ticker'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assetClass: json['asset_class'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      shares: (json['shares'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  final String ticker;
  final String name;
  final String assetClass;
  final double percentage;
  final double amount;
  final double shares;
  final double price;
}

/// Response from POST /analyze/portfolio-builder.
class PortfolioResultDto {
  const PortfolioResultDto({
    required this.strategy,
    required this.totalAmount,
    required this.expectedReturnMin,
    required this.expectedReturnMax,
    required this.maxDrawdown,
    required this.rebalancingFrequency,
    required this.allocations,
    required this.analysis,
  });

  factory PortfolioResultDto.fromJson(Map<String, dynamic> json) {
    final rawAllocations = json['allocations'] as List<dynamic>? ?? [];
    return PortfolioResultDto(
      strategy: json['strategy'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      expectedReturnMin:
          (json['expected_return_min'] as num?)?.toDouble() ?? 0,
      expectedReturnMax:
          (json['expected_return_max'] as num?)?.toDouble() ?? 0,
      maxDrawdown: (json['max_drawdown'] as num?)?.toDouble() ?? 0,
      rebalancingFrequency:
          json['rebalancing_frequency'] as String? ?? 'quarterly',
      allocations: rawAllocations
          .map((e) => PortfolioAllocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      analysis: json['analysis'] as String? ?? '',
    );
  }

  final String strategy;
  final double totalAmount;
  final double expectedReturnMin;
  final double expectedReturnMax;
  final double maxDrawdown;
  final String rebalancingFrequency;
  final List<PortfolioAllocation> allocations;
  final String analysis;
}
