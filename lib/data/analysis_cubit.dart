import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import 'package:ai_stock_analyzer/data/analysis_repository.dart';
import 'package:ai_stock_analyzer/data/stock_analysis_dto.dart';
import 'package:ai_stock_analyzer/data/user_plan.dart';

// ── State ──

enum AnalysisStatus { idle, loading, loaded, error }

/// Error keys — UI translates via AppStrings.
class AnalysisErrorKey {
  static const modeUnavailable = 'modeUnavailable';
  static const limitReached = 'limitReached';
  static const server = 'server'; // suffix: ":code"
  static const noConnection = 'noConnection';
  static const generic = 'generic';
}

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.selectedMode = 'full',
    this.ticker = '',
    this.result,
    this.errorKey,
    this.history = const [],
    this.userPlan = UserPlan.free,
    this.dailyUsage = 0,
  });

  final AnalysisStatus status;
  final String selectedMode;
  final String ticker;
  final StockAnalysisDto? result;
  final String? errorKey;
  final List<StockAnalysisDto> history;
  final UserPlan userPlan;
  final int dailyUsage;

  bool get isLoading => status == AnalysisStatus.loading;
  bool get isLoaded => status == AnalysisStatus.loaded;
  bool get isError => status == AnalysisStatus.error;

  int get dailyLimit => plans[userPlan]!.dailyLimit;
  bool get isUnlimited => dailyLimit < 0;
  int get remaining => isUnlimited ? -1 : (dailyLimit - dailyUsage).clamp(0, dailyLimit);
  bool get hasCredits => isUnlimited || remaining > 0;

  bool isModeAvailable(String mode) {
    if (userPlan == UserPlan.free) return freeModes.contains(mode);
    return true;
  }

  AnalysisState copyWith({
    AnalysisStatus? status,
    String? selectedMode,
    String? ticker,
    StockAnalysisDto? result,
    String? errorKey,
    List<StockAnalysisDto>? history,
    UserPlan? userPlan,
    int? dailyUsage,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      selectedMode: selectedMode ?? this.selectedMode,
      ticker: ticker ?? this.ticker,
      result: result ?? this.result,
      errorKey: errorKey ?? this.errorKey,
      history: history ?? this.history,
      userPlan: userPlan ?? this.userPlan,
      dailyUsage: dailyUsage ?? this.dailyUsage,
    );
  }

  @override
  List<Object?> get props =>
      [status, selectedMode, ticker, result, errorKey, history, userPlan, dailyUsage];
}

// ── Cubit ──

class AnalysisCubit extends Cubit<AnalysisState> {
  AnalysisCubit({required AnalysisRepository repository})
      : _repo = repository,
        super(const AnalysisState());

  final AnalysisRepository _repo;

  void setTicker(String v) => emit(state.copyWith(ticker: v.toUpperCase()));
  void setMode(String v) => emit(state.copyWith(selectedMode: v));
  void setPlan(UserPlan v) => emit(state.copyWith(userPlan: v, dailyUsage: 0));

  /// Reset state (on logout).
  void reset() => emit(const AnalysisState());

  Future<void> analyze() async {
    final ticker = state.ticker.trim();
    if (ticker.isEmpty) return;

    // Default to 'full' if no mode selected
    if (state.selectedMode.isEmpty) {
      emit(state.copyWith(selectedMode: 'full'));
    }

    if (!state.isModeAvailable(state.selectedMode)) {
      emit(state.copyWith(
        status: AnalysisStatus.error,
        errorKey: AnalysisErrorKey.modeUnavailable,
      ));
      return;
    }

    if (!state.hasCredits) {
      emit(state.copyWith(
        status: AnalysisStatus.error,
        errorKey: AnalysisErrorKey.limitReached,
      ));
      return;
    }

    emit(state.copyWith(status: AnalysisStatus.loading, errorKey: null));

    try {
      final result = await _repo.analyze(ticker, mode: state.selectedMode);
      emit(
        state.copyWith(
          status: AnalysisStatus.loaded,
          result: result,
          history: [result, ...state.history],
          dailyUsage: state.dailyUsage + 1,
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      emit(
        state.copyWith(
          status: AnalysisStatus.error,
          errorKey: code != null
              ? '${AnalysisErrorKey.server}:$code'
              : AnalysisErrorKey.noConnection,
        ),
      );
    } on Exception {
      emit(
        state.copyWith(
          status: AnalysisStatus.error,
          errorKey: AnalysisErrorKey.generic,
        ),
      );
    }
  }
}
