import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/analysis_cubit.dart';
import 'package:ai_stock_analyzer/data/analysis_repository.dart';
import 'package:ai_stock_analyzer/data/auth_cubit.dart';
import 'package:ai_stock_analyzer/presentation/pages/home_page.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

void main() {
  runApp(const AiStockAnalyzerApp());
}

class AiStockAnalyzerApp extends StatefulWidget {
  const AiStockAnalyzerApp({super.key});

  static const _baseUrl = 'https://6df8-31-171-168-220.ngrok-free.app';

  @override
  State<AiStockAnalyzerApp> createState() => _AiStockAnalyzerAppState();
}

class _AiStockAnalyzerAppState extends State<AiStockAnalyzerApp> {
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

  @override
  void dispose() {
    _themeNotifier.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(httpClient: _dio),
        ),
        BlocProvider(
          create: (_) => AnalysisCubit(
            repository: AnalysisRepository(httpClient: _dio),
          ),
        ),
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
