import 'package:dio/dio.dart';

import 'trading_order_dto.dart';
import 'trading_position_dto.dart';

/// Репозиторий: авторизация на Investlink staging + загрузка orders.
class TradingRepository {
  TradingRepository({required Dio httpClient}) : _http = httpClient;

  final Dio _http;

  String? _accessToken;
  // TODO: use for token refresh when access token expires
  // ignore: unused_field
  String? _refreshToken;

  bool get isAuthenticated => _accessToken != null;

  /// Login → Investlink staging.
  /// POST /auth_db/login/  { email, password }
  /// Response: { tokens: { access, refresh } }
  Future<void> login(String email, String password) async {
    final resp = await _http.post<Map<String, dynamic>>(
      '/auth_db/login/',
      data: {'email': email, 'password': password},
    );

    final data = resp.data!;
    final tokens = data['tokens'] as Map<String, dynamic>?;
    if (tokens != null) {
      _accessToken = tokens['access'] as String?;
      _refreshToken = tokens['refresh'] as String?;
    }
  }

  /// Загрузить все filled orders (автопагинация).
  Future<List<TradingOrderDto>> getAllFilledOrders() async {
    final allOrders = <TradingOrderDto>[];
    var page = 1;
    var hasNext = true;

    while (hasNext) {
      final resp = await _http.get<Map<String, dynamic>>(
        '/orders/order_history/',
        queryParameters: {
          'status': 'filled',
          'page_size': 500,
          'page': page,
        },
        options: Options(
          headers: {
            if (_accessToken != null)
              'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      final data = resp.data!;
      final results = data['results'] as List<dynamic>? ??
          data['orders'] as List<dynamic>? ??
          [];

      for (final item in results) {
        if (item is Map<String, dynamic>) {
          allOrders.add(TradingOrderDto.fromJson(item));
        }
      }

      final next = data['next'];
      hasNext = next != null && next.toString().isNotEmpty;
      page++;
    }

    return allOrders;
  }

  /// Загрузить все открытые позиции.
  Future<List<TradingPositionDto>> getPositions() async {
    final resp = await _http.get<dynamic>(
      '/alpaca/get_all_positions/',
      options: Options(
        headers: {
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      ),
    );

    final data = resp.data;
    // Response может быть List или Map с ключом positions/results
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items = data['positions'] as List<dynamic>? ??
          data['results'] as List<dynamic>? ??
          [];
    } else {
      items = [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(TradingPositionDto.fromJson)
        .toList();
  }

  /// Загрузить ордера с фильтрами (все статусы, пагинация).
  Future<List<TradingOrderDto>> getOrders({
    String? status,
    int pageSize = 100,
    int page = 1,
  }) async {
    final resp = await _http.get<Map<String, dynamic>>(
      '/orders/order_history/',
      queryParameters: {
        if (status != null) 'status': status,
        'page_size': pageSize,
        'page': page,
      },
      options: Options(
        headers: {
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      ),
    );

    final data = resp.data!;
    final results = data['results'] as List<dynamic>? ??
        data['orders'] as List<dynamic>? ??
        [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(TradingOrderDto.fromJson)
        .toList();
  }

  /// Загрузить sparkline (close prices за 30 дней) для тикера.
  Future<List<double>> getSparkline(String symbol) async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final fmtD = (DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final resp = await _http.get<Map<String, dynamic>>(
      '/proxy_api/v1/polygon/ticker_history',
      queryParameters: {
        'ticker': symbol,
        'adjusted': true,
        'sort': 'asc',
        'timePeriod': '1/day/${fmtD(from)}/${fmtD(now)}',
        'limit': 30,
      },
      options: Options(
        headers: {
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      ),
    );

    final results = resp.data?['results'] as List<dynamic>? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((e) => (e['c'] as num?)?.toDouble() ?? 0)
        .where((v) => v > 0)
        .toList();
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
  }
}
