import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import 'package:ai_stock_analyzer/data/analysis_repository.dart';
import 'package:ai_stock_analyzer/data/stock_analysis_dto.dart';

// ── State ──

enum AnalysisStatus { idle, loading, loaded, error }

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.selectedMode = 'full',
    this.ticker = '',
    this.result,
    this.error,
    this.history = const [],
  });

  final AnalysisStatus status;
  final String selectedMode;
  final String ticker;
  final StockAnalysisDto? result;
  final String? error;
  final List<StockAnalysisDto> history;

  bool get isLoading => status == AnalysisStatus.loading;
  bool get isLoaded => status == AnalysisStatus.loaded;
  bool get isError => status == AnalysisStatus.error;

  AnalysisState copyWith({
    AnalysisStatus? status,
    String? selectedMode,
    String? ticker,
    StockAnalysisDto? result,
    String? error,
    List<StockAnalysisDto>? history,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      selectedMode: selectedMode ?? this.selectedMode,
      ticker: ticker ?? this.ticker,
      result: result ?? this.result,
      error: error ?? this.error,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props =>
      [status, selectedMode, ticker, result, error, history];
}

// ── Cubit ──

class AnalysisCubit extends Cubit<AnalysisState> {
  AnalysisCubit({required AnalysisRepository repository})
      : _repo = repository,
        super(const AnalysisState());

  final AnalysisRepository _repo;

  void setTicker(String v) => emit(state.copyWith(ticker: v.toUpperCase()));
  void setMode(String v) => emit(state.copyWith(selectedMode: v));

  Future<void> analyze() async {
    final ticker = state.ticker.trim();
    if (ticker.isEmpty) return;

    emit(state.copyWith(status: AnalysisStatus.loading, error: null));

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
      emit(
        state.copyWith(
          status: AnalysisStatus.error,
          error: e.response?.statusCode != null
              ? 'Ошибка сервера (${e.response!.statusCode})'
              : 'Нет подключения к серверу',
        ),
      );
    } on Exception {
      emit(
        state.copyWith(
          status: AnalysisStatus.error,
          error: 'Произошла ошибка',
        ),
      );
    }
  }
}
