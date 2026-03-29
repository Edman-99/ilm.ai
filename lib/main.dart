import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/data/analysis_repository.dart';
import 'package:ai_stock_analyzer/data/ai/ai_cubit.dart';
import 'package:ai_stock_analyzer/data/trading/trading_analytics_cubit.dart';
import 'package:ai_stock_analyzer/data/trading/trading_repository.dart';
import 'package:ai_stock_analyzer/presentation/pages/home_page.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

void main() {
  runApp(const AiStockAnalyzerApp());
}

class AiStockAnalyzerApp extends StatefulWidget {
  const AiStockAnalyzerApp({super.key});

  static const _baseUrl = 'https://b5ab-31-171-168-220.ngrok-free.app';

  @override
  State<AiStockAnalyzerApp> createState() => _AiStockAnalyzerAppState();
}

class _AiStockAnalyzerAppState extends State<AiStockAnalyzerApp> {
  // On Vercel (*.vercel.app) use proxy, locally use direct URL.
  static String get _tradingBaseUrl {
    try {
      final host = Uri.base.host;
      if (host.contains('vercel.app') || host.contains('ilmai')) return '/api/proxy';
    } catch (_) {}
    return 'https://app12-us-sw.ivlk.io';
  }

  final _themeNotifier = ThemeNotifier();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AiStockAnalyzerApp._baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  late final Dio _tradingDio = Dio(
    BaseOptions(
      baseUrl: _tradingBaseUrl,
      connectTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 4),
    ),
  );

  @override
  void dispose() {
    _themeNotifier.dispose();
    _dio.close();
    _tradingDio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AnalysisCubit(
            repository: AnalysisRepository(httpClient: _dio),
          ),
        ),
        BlocProvider(
          create: (_) => TradingAnalyticsCubit(
            repository: TradingRepository(httpClient: _tradingDio),
          ),
        ),
        BlocProvider(create: (_) => AiCubit()),
      ],
      child: ListenableBuilder(
        listenable: _themeNotifier,
        builder: (context, _) {
          return AppThemeScope(
            colors: _themeNotifier.colors,
            onToggle: _themeNotifier.toggle,
            strings: _themeNotifier.strings,
            locale: _themeNotifier.locale,
            onToggleLocale: _themeNotifier.toggleLocale,
            child: MaterialApp(
              title: 'ILM',
              debugShowCheckedModeBanner: false,
              theme: _themeNotifier.themeData,
              home: const HomePage(),
            ),
          );
        },
      ),
    );
  }
}
