import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../mock/mock_agent_responses.dart';

class LlmCallResult {
  final Map<String, dynamic> json;
  final bool usedMockFallback;
  final String? rawText;

  const LlmCallResult({
    required this.json,
    required this.usedMockFallback,
    this.rawText,
  });
}

class LlmClient {
  LlmClient({Dio? dio, MockAgentResponses? mocks})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30))),
        _mocks = mocks ?? const MockAgentResponses();

  final Dio _dio;
  final MockAgentResponses _mocks;

  String get _apiKey => dotenv.maybeGet('LLM_API_KEY') ?? '';
  String get _model => dotenv.maybeGet('LLM_MODEL') ?? 'claude-sonnet-4-5-20251022';
  bool get _demoMode => (dotenv.maybeGet('DEMO_MODE') ?? 'true').toLowerCase() == 'true';

  Future<LlmCallResult> complete({
    required String systemPrompt,
    required Map<String, dynamic> input,
    int maxTokens = 1024,
  }) async {
    if (_demoMode || _apiKey.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return LlmCallResult(
        json: _routeMock(systemPrompt, input),
        usedMockFallback: true,
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'x-api-key': _apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': _model,
          'max_tokens': maxTokens,
          'system': systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': jsonEncode(input),
            },
          ],
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        return _fallback(systemPrompt, input);
      }

      final content = response.data!['content'] as List?;
      if (content == null) return _fallback(systemPrompt, input);

      final text = content
          .where((c) => (c as Map)['type'] == 'text')
          .map((c) => (c as Map)['text'] as String)
          .join('\n');

      final cleaned = _stripFences(text);
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return LlmCallResult(json: parsed, usedMockFallback: false, rawText: text);
    } catch (_) {
      return _fallback(systemPrompt, input);
    }
  }

  LlmCallResult _fallback(String systemPrompt, Map<String, dynamic> input) {
    return LlmCallResult(
      json: _routeMock(systemPrompt, input),
      usedMockFallback: true,
    );
  }

  Map<String, dynamic> _routeMock(String systemPrompt, Map<String, dynamic> input) {
    final lower = systemPrompt.toLowerCase();
    final rawText = (input['raw_text'] ?? input['rawText'] ?? '').toString();
    final sector = (input['sector'] ?? 'G-10 Markaz').toString();
    final crisisType = (input['crisis_type'] ?? input['crisisType'] ?? 'flood').toString();
    final crisisHint = (input['crisis_hint'] ?? crisisType).toString();

    if (lower.contains('signal agent')) {
      return _mocks.signalResponse(rawText);
    }
    if (lower.contains('detection agent')) {
      return _mocks.detectionResponse(crisisHint);
    }
    if (lower.contains('severity agent')) {
      return _mocks.severityResponse(crisisType);
    }
    if (lower.contains('action agent')) {
      return _mocks.actionResponse(sector, crisisType);
    }
    return _mocks.signalResponse(rawText);
  }

  String _stripFences(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      final firstNewline = t.indexOf('\n');
      if (firstNewline != -1) t = t.substring(firstNewline + 1);
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    return t.trim();
  }
}
