import 'dart:convert';
import 'package:dio/dio.dart';

/// Claude API service for AI trading analysis.
/// API key passed via --dart-define=CLAUDE_API_KEY=sk-ant-...
class ClaudeService {
  ClaudeService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: 'https://api.anthropic.com',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        )),
        _apiKey = apiKey ?? const String.fromEnvironment('CLAUDE_API_KEY');

  final Dio _dio;
  final String _apiKey;
  static const _model = 'claude-sonnet-4-20250514';

  /// Send a message to Claude and get a response.
  Future<String> analyze({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/v1/messages',
      options: Options(headers: {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
        'anthropic-dangerous-direct-browser-access': 'true',
      }),
      data: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    final content = resp.data?['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) return 'No response from AI.';
    return (content.first as Map<String, dynamic>)['text'] as String? ?? '';
  }
}
