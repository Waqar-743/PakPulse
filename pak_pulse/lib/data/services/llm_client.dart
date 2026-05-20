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

/// Hybrid LLM client for the PAK·PULSE agent pipeline.
///
/// Provider resolution order:
///  1. If [DEMO_MODE] is `true` → always use bundled mock responses (offline).
///  2. If a Gemini key is configured → call Google Gemini (free tier).
///  3. If an Anthropic key is configured → call Claude.
///  4. On ANY network / parse / quota error → silently fall back to the
///     mock response so the demo never breaks. This is the "hybrid mode":
///     real AI when the key works, deterministic mock when it does not.
class LlmClient {
  LlmClient({Dio? dio, MockAgentResponses? mocks, bool? forceDemo})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _mocks = mocks ?? const MockAgentResponses(),
        _forceDemo = forceDemo;

  final Dio _dio;
  final MockAgentResponses _mocks;

  /// When set, overrides the `.env` DEMO_MODE flag — lets the Settings
  /// "Demo Mode" toggle switch the pipeline between live and mock at runtime.
  final bool? _forceDemo;

  // ── Config ─────────────────────────────────────────────────────────────────

  bool get _demoMode =>
      _forceDemo ??
      (dotenv.maybeGet('DEMO_MODE') ?? 'true').toLowerCase() == 'true';

  String get _geminiKey => (dotenv.maybeGet('GEMINI_API_KEY') ?? '').trim();
  String get _geminiModel =>
      (dotenv.maybeGet('GEMINI_MODEL') ?? 'gemini-2.5-flash').trim();

  String get _anthropicKey => (dotenv.maybeGet('LLM_API_KEY') ?? '').trim();
  String get _anthropicModel =>
      dotenv.maybeGet('LLM_MODEL') ?? 'claude-sonnet-4-5-20251022';

  /// Which provider this client will attempt for live calls. Exposed so the
  /// Settings screen can show an accurate status line.
  String get activeProvider {
    if (_demoMode) return 'mock';
    if (_geminiKey.isNotEmpty) return 'gemini';
    if (_anthropicKey.isNotEmpty) return 'anthropic';
    return 'mock';
  }

  bool get isLiveCapable => activeProvider != 'mock';

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<LlmCallResult> complete({
    required String systemPrompt,
    required Map<String, dynamic> input,
    int maxTokens = 2048,
  }) async {
    switch (activeProvider) {
      case 'gemini':
        return _callGemini(systemPrompt, input, maxTokens);
      case 'anthropic':
        return _callAnthropic(systemPrompt, input, maxTokens);
      default:
        // Demo mode — keep the small delay so the UI pipeline still animates.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return LlmCallResult(
          json: _routeMock(systemPrompt, input),
          usedMockFallback: true,
        );
    }
  }

  /// Plain-text chat completion used by the RAG chatbot. Returns a friendly
  /// fallback string when offline / in demo mode, so the chat UI never breaks.
  Future<String> chatComplete({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1024,
  }) async {
    if (activeProvider == 'mock') {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return 'Demo mode is on — I can\'t reach the live model. Turn off "Demo Mode" in Settings and ensure GEMINI_API_KEY is set in .env to chat with real data.';
    }
    if (activeProvider == 'gemini') {
      try {
        final url =
            'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';
        final response = await _dio.post<Map<String, dynamic>>(
          url,
          queryParameters: {'key': _geminiKey},
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
          data: {
            'systemInstruction': {
              'parts': [
                {'text': systemPrompt}
              ]
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': userMessage}
                ],
              }
            ],
            'generationConfig': {
              'maxOutputTokens': maxTokens,
              'temperature': 0.6,
              'thinkingConfig': {'thinkingBudget': 0},
            },
          },
        );
        final parts =
            ((response.data?['candidates'] as List?)?.first as Map?)?['content']
                as Map?;
        final text = (parts?['parts'] as List?)
                ?.map((p) => (p as Map)['text'])
                .whereType<String>()
                .join('\n') ??
            '';
        if (text.trim().isEmpty) {
          return 'Sorry — I couldn\'t generate a response. Try rephrasing.';
        }
        return text.trim();
      } catch (e) {
        return 'I hit a connection error reaching Gemini: $e';
      }
    }
    // Anthropic path — kept simple, only used if user configures LLM_API_KEY.
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'x-api-key': _anthropicKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _anthropicModel,
          'max_tokens': maxTokens,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        },
      );
      final content = response.data?['content'] as List?;
      final text = content
              ?.where((c) => (c as Map)['type'] == 'text')
              .map((c) => (c as Map)['text'] as String)
              .join('\n') ??
          '';
      return text.trim().isEmpty ? 'Empty response from model.' : text.trim();
    } catch (e) {
      return 'I hit a connection error reaching Claude: $e';
    }
  }

  // ── Gemini ─────────────────────────────────────────────────────────────────

  Future<LlmCallResult> _callGemini(
    String systemPrompt,
    Map<String, dynamic> input,
    int maxTokens,
  ) async {
    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: {'key': _geminiKey},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': jsonEncode(input)}
              ],
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'maxOutputTokens': maxTokens,
            'temperature': 0.4,
            // Disable "thinking" so the whole token budget produces JSON,
            // not internal reasoning. Keeps responses fast and parseable.
            'thinkingConfig': {'thinkingBudget': 0},
          },
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        return _fallback(systemPrompt, input);
      }

      final candidates = response.data!['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return _fallback(systemPrompt, input);
      }

      final parts =
          ((candidates.first as Map)['content'] as Map?)?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return _fallback(systemPrompt, input);
      }

      final text = parts
          .map((p) => (p as Map)['text'])
          .whereType<String>()
          .join('\n');

      if (text.trim().isEmpty) return _fallback(systemPrompt, input);

      final parsed = jsonDecode(_stripFences(text)) as Map<String, dynamic>;
      return LlmCallResult(json: parsed, usedMockFallback: false, rawText: text);
    } catch (_) {
      return _fallback(systemPrompt, input);
    }
  }

  // ── Anthropic (kept for completeness) ──────────────────────────────────────

  Future<LlmCallResult> _callAnthropic(
    String systemPrompt,
    Map<String, dynamic> input,
    int maxTokens,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'x-api-key': _anthropicKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': _anthropicModel,
          'max_tokens': maxTokens,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': jsonEncode(input)},
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

      final parsed = jsonDecode(_stripFences(text)) as Map<String, dynamic>;
      return LlmCallResult(json: parsed, usedMockFallback: false, rawText: text);
    } catch (_) {
      return _fallback(systemPrompt, input);
    }
  }

  // ── Mock fallback ──────────────────────────────────────────────────────────

  LlmCallResult _fallback(String systemPrompt, Map<String, dynamic> input) {
    return LlmCallResult(
      json: _routeMock(systemPrompt, input),
      usedMockFallback: true,
    );
  }

  Map<String, dynamic> _routeMock(
      String systemPrompt, Map<String, dynamic> input) {
    final lower = systemPrompt.toLowerCase();
    final rawText = (input['raw_text'] ?? input['rawText'] ?? '').toString();
    final sector = (input['sector'] ?? 'G-10 Markaz').toString();
    final crisisType =
        (input['crisis_type'] ?? input['crisisType'] ?? 'flood').toString();
    final crisisHint = (input['crisis_hint'] ?? crisisType).toString();

    if (lower.contains('signal agent')) {
      return _mocks.signalResponse(rawText);
    }
    if (lower.contains('detection agent')) {
      return _mocks.detectionResponse(crisisHint);
    }
    if (lower.contains('fact-check agent')) {
      final size = (input['cluster_size'] is num)
          ? (input['cluster_size'] as num).toInt()
          : 1;
      final weight = (input['cluster_weight'] is num)
          ? (input['cluster_weight'] as num).toDouble()
          : size.toDouble();
      final corroborated = input['has_official_corroboration'] == true;
      return _mocks.factCheckResponse(
        clusterSize: size,
        clusterWeight: weight,
        hasOfficialCorroboration: corroborated,
      );
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
