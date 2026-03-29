import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'demo_data.dart';
import 'local_storage_service.dart';
import 'trading_analytics_calculator.dart';
import 'trading_analytics_entity.dart';
import 'strategy_entity.dart';
import 'trading_order_dto.dart';
import 'trading_position_dto.dart';
import 'trading_repository.dart';

// ── State ──

enum TradingAnalyticsStatus { unauthenticated, loading, loaded, error }
enum TradingPage { dashboard, portfolio, strategies, orders, ai }

class TradingAnalyticsState extends Equatable {
  const TradingAnalyticsState({
    this.status = TradingAnalyticsStatus.unauthenticated,
    this.activePage = TradingPage.dashboard,
    this.analytics,
    this.allOrders = const [],
    this.positions = const [],
    this.recentOrders = const [],
    this.sparklines = const {},
    this.strategies = const [],
    this.positionsLoading = false,
    this.ordersLoading = false,
    this.errorMessage,
    this.filterFrom,
    this.filterTo,
    this.savedEmail,
    this.savedPassword,
    this.isDemo = false,
  });

  final TradingAnalyticsStatus status;
  final TradingPage activePage;
  final TradingAnalyticsEntity? analytics;
  final List<TradingOrderDto> allOrders;
  final List<TradingPositionDto> positions;
  final List<TradingOrderDto> recentOrders;
  final Map<String, List<double>> sparklines;
  final List<StrategyEntity> strategies;
  final bool positionsLoading;
  final bool ordersLoading;
  final String? errorMessage;
  final DateTime? filterFrom;
  final DateTime? filterTo;
  final String? savedEmail;
  final String? savedPassword;
  final bool isDemo;

  bool get isLoading => status == TradingAnalyticsStatus.loading;
  bool get isLoaded => status == TradingAnalyticsStatus.loaded;
  bool get isAuthenticated => status != TradingAnalyticsStatus.unauthenticated;
  bool get hasSavedCredentials => savedEmail != null && savedPassword != null;

  TradingAnalyticsState copyWith({
    TradingAnalyticsStatus? status,
    TradingPage? activePage,
    TradingAnalyticsEntity? analytics,
    List<TradingOrderDto>? allOrders,
    List<TradingPositionDto>? positions,
    List<TradingOrderDto>? recentOrders,
    Map<String, List<double>>? sparklines,
    List<StrategyEntity>? strategies,
    bool? positionsLoading,
    bool? ordersLoading,
    String? errorMessage,
    DateTime? filterFrom,
    DateTime? filterTo,
    String? savedEmail,
    String? savedPassword,
    bool? isDemo,
    bool clearFilter = false,
    bool clearCredentials = false,
  }) {
    return TradingAnalyticsState(
      status: status ?? this.status,
      activePage: activePage ?? this.activePage,
      analytics: analytics ?? this.analytics,
      allOrders: allOrders ?? this.allOrders,
      positions: positions ?? this.positions,
      recentOrders: recentOrders ?? this.recentOrders,
      sparklines: sparklines ?? this.sparklines,
      strategies: strategies ?? this.strategies,
      positionsLoading: positionsLoading ?? this.positionsLoading,
      ordersLoading: ordersLoading ?? this.ordersLoading,
      errorMessage: errorMessage,
      filterFrom: clearFilter ? null : (filterFrom ?? this.filterFrom),
      filterTo: clearFilter ? null : (filterTo ?? this.filterTo),
      savedEmail: clearCredentials ? null : (savedEmail ?? this.savedEmail),
      savedPassword: clearCredentials ? null : (savedPassword ?? this.savedPassword),
      isDemo: isDemo ?? this.isDemo,
    );
  }

  @override
  List<Object?> get props => [
        status, activePage, analytics?.totalTrades, allOrders.length,
        positions.length, recentOrders.length, sparklines.length, strategies.length,
        positionsLoading, ordersLoading,
        errorMessage, filterFrom, filterTo,
        savedEmail, savedPassword, isDemo,
      ];
}

// ── Cubit ──

class TradingAnalyticsCubit extends Cubit<TradingAnalyticsState> {
  TradingAnalyticsCubit({required TradingRepository repository})
      : _repo = repository,
        super(const TradingAnalyticsState());

  final TradingRepository _repo;

  /// Navigate between pages.
  void setPage(TradingPage page) {
    emit(state.copyWith(activePage: page));
    // Lazy-load data for the page.
    if (page == TradingPage.portfolio && state.positions.isEmpty) {
      loadPositions();
    } else if (page == TradingPage.strategies && state.positions.isEmpty) {
      loadPositions();
    } else if (page == TradingPage.orders && state.recentOrders.isEmpty) {
      loadOrders();
    }
  }

  /// Load saved credentials on init.
  Future<void> loadSavedCredentials() async {
    final creds = await LocalStorageService.loadCredentials();
    if (creds != null) {
      emit(state.copyWith(savedEmail: creds.email, savedPassword: creds.password));
    }
  }

  /// Auto-login with saved credentials.
  Future<void> autoLogin() async {
    final creds = await LocalStorageService.loadCredentials();
    if (creds != null) {
      await loginAndLoad(creds.email, creds.password);
    }
  }

  /// Load demo data (no API calls).
  void loadDemo() {
    final orders = demoOrders;
    final analytics = TradingAnalyticsCalculator.calculate(orders);
    emit(state.copyWith(
      status: TradingAnalyticsStatus.loaded,
      analytics: analytics,
      allOrders: orders,
      positions: demoPositions,
      recentOrders: orders,
      strategies: demoStrategies,
      isDemo: true,
      savedEmail: 'demo@investlink.io',
      clearFilter: true,
    ));
  }

  /// Login → save credentials → load orders → calculate.
  Future<void> loginAndLoad(String email, String password) async {
    emit(state.copyWith(status: TradingAnalyticsStatus.loading));
    try {
      await _repo.login(email, password);
      await LocalStorageService.saveCredentials(email, password);
      final orders = await _repo.getAllFilledOrders();
      final analytics = TradingAnalyticsCalculator.calculate(orders);
      emit(state.copyWith(
        status: TradingAnalyticsStatus.loaded,
        analytics: analytics,
        allOrders: orders,
        savedEmail: email,
        savedPassword: password,
        clearFilter: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TradingAnalyticsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Refresh dashboard data.
  Future<void> refresh() async {
    if (!_repo.isAuthenticated) return;
    emit(state.copyWith(status: TradingAnalyticsStatus.loading));
    try {
      final orders = await _repo.getAllFilledOrders();
      final analytics = TradingAnalyticsCalculator.calculate(orders);
      emit(state.copyWith(
        status: TradingAnalyticsStatus.loaded,
        analytics: analytics,
        allOrders: orders,
        clearFilter: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TradingAnalyticsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load positions + sparklines.
  Future<void> loadPositions() async {
    if (!_repo.isAuthenticated) return;
    emit(state.copyWith(positionsLoading: true));
    try {
      final positions = await _repo.getPositions();
      emit(state.copyWith(positions: positions, positionsLoading: false));
      // Load sparklines in background for each position.
      _loadSparklines(positions.map((p) => p.symbol).toList());
    } catch (e) {
      emit(state.copyWith(positionsLoading: false, errorMessage: e.toString()));
    }
  }

  /// Load sparklines for symbols (non-blocking, emits incrementally).
  Future<void> _loadSparklines(List<String> symbols) async {
    final map = Map<String, List<double>>.from(state.sparklines);
    for (final sym in symbols) {
      if (map.containsKey(sym)) continue;
      try {
        final data = await _repo.getSparkline(sym);
        if (data.isNotEmpty) {
          map[sym] = data;
          emit(state.copyWith(sparklines: Map.from(map)));
        }
      } catch (_) {
        // Silently skip failed sparklines.
      }
    }
  }

  /// Load recent orders (all statuses).
  Future<void> loadOrders() async {
    if (!_repo.isAuthenticated) return;
    emit(state.copyWith(ordersLoading: true));
    try {
      final orders = await _repo.getOrders(pageSize: 200);
      emit(state.copyWith(recentOrders: orders, ordersLoading: false));
    } catch (e) {
      emit(state.copyWith(ordersLoading: false, errorMessage: e.toString()));
    }
  }

  /// Filter by date range (client-side).
  void filterByDateRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) {
      final analytics = TradingAnalyticsCalculator.calculate(state.allOrders);
      emit(state.copyWith(analytics: analytics, clearFilter: true));
      return;
    }
    final filtered = state.allOrders.where((o) {
      final dt = DateTime.tryParse(o.filledAt);
      if (dt == null) return false;
      return !dt.isBefore(from) && !dt.isAfter(to);
    }).toList();
    final analytics = TradingAnalyticsCalculator.calculate(filtered);
    emit(state.copyWith(analytics: analytics, filterFrom: from, filterTo: to));
  }

  Future<void> logout() async {
    _repo.logout();
    await LocalStorageService.clearCredentials();
    emit(const TradingAnalyticsState());
  }
}
