import 'package:dio/dio.dart';

import 'package:ai_stock_analyzer/data/portfolio_result_dto.dart';
import 'package:ai_stock_analyzer/data/stock_analysis_dto.dart';

class AnalysisRepository {
  AnalysisRepository({required Dio httpClient}) : _http = httpClient;

  final Dio _http;

  Future<StockAnalysisDto> analyze(
    String ticker, {
    String mode = 'full',
    Map<String, dynamic>? extraParams,
  }) async {
    final resp = await _http.get<Map<String, dynamic>>(
      '/analyze/$ticker',
      queryParameters: {
        'mode': mode,
        if (extraParams != null) ...extraParams,
      },
    );
    return StockAnalysisDto.fromJson(resp.data!);
  }

  Future<PortfolioResultDto> buildPortfolio({
    required double amount,
    required String riskStrategy,
  }) async {
    final resp = await _http.post<Map<String, dynamic>>(
      '/analyze/portfolio-builder',
      data: {
        'amount': amount,
        'risk_strategy': riskStrategy,
      },
    );
    return PortfolioResultDto.fromJson(resp.data!);
  }
}
