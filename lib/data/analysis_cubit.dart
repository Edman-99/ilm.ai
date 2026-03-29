import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import 'package:ai_stock_analyzer/data/analysis_repository.dart';
import 'package:ai_stock_analyzer/data/stock_analysis_dto.dart';

// ── State ──

enum AnalysisStatus { idle, loading, loaded, error }

/// Error keys — UI translates via AppStrings.
class AnalysisErrorKey {
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
  });

  final AnalysisStatus status;
  final String selectedMode;
  final String ticker;
  final StockAnalysisDto? result;
  final String? errorKey;
  final List<StockAnalysisDto> history;

  bool get isLoading => status == AnalysisStatus.loading;
  bool get isLoaded => status == AnalysisStatus.loaded;
  bool get isError => status == AnalysisStatus.error;

  AnalysisState copyWith({
    AnalysisStatus? status,
    String? selectedMode,
    String? ticker,
    StockAnalysisDto? result,
    String? errorKey,
    List<StockAnalysisDto>? history,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      selectedMode: selectedMode ?? this.selectedMode,
      ticker: ticker ?? this.ticker,
      result: result ?? this.result,
      errorKey: errorKey ?? this.errorKey,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props =>
      [status, selectedMode, ticker, result, errorKey, history];
}

// ── Cubit ──

class AnalysisCubit extends Cubit<AnalysisState> {
  AnalysisCubit({required AnalysisRepository repository})
      : _repo = repository,
        super(const AnalysisState());

  final AnalysisRepository _repo;

  AnalysisRepository get repository => _repo;

  void setTicker(String v) => emit(state.copyWith(ticker: v.toUpperCase()));
  void setMode(String v) => emit(state.copyWith(selectedMode: v));

  /// Reset state.
  void reset() => emit(const AnalysisState());

  Future<void> analyze() async {
    final ticker = state.ticker.trim();
    if (ticker.isEmpty) return;

    if (state.selectedMode.isEmpty) {
      emit(state.copyWith(selectedMode: 'full'));
    }

    emit(state.copyWith(status: AnalysisStatus.loading, errorKey: null));

    try {
      final result = await _repo.analyze(ticker, mode: state.selectedMode);
      emit(
        state.copyWith(
          status: AnalysisStatus.loaded,
          result: result,
          history: [result, ...state.history],
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
