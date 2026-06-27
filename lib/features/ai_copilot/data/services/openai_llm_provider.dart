import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/rate_limiter.dart';
import 'package:rihla/core/network/retry_policy.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message_role.dart';
import 'package:rihla/features/ai_copilot/domain/entities/llm_token_usage.dart';
import 'package:rihla/features/ai_copilot/domain/errors/ai_failure.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';

/// Production OpenAI adapter behind [LLMProvider].
///
/// Supports chat completions, streaming, retries, rate limiting, cancellation,
/// and token usage reporting. API keys come from [ApiConfig] dart-defines only.
class OpenAiLlmProvider implements LLMProvider {
  OpenAiLlmProvider({
    String? apiKey,
    String? baseUrl,
    String? model,
    Duration? timeout,
    http.Client? httpClient,
    RateLimiter? rateLimiter,
    RetryPolicy? retryPolicy,
  })  : _apiKey = apiKey ?? ApiConfig.openAiApiKey,
        _baseUrl = baseUrl ?? ApiConfig.openAiBaseUrl,
        _model = model ?? ApiConfig.openAiModel,
        _timeout = timeout ?? ApiConfig.openAiTimeout,
        _client = httpClient ?? http.Client(),
        _rateLimiter = rateLimiter ?? RateLimiter(),
        _retryPolicy = retryPolicy ?? const RetryPolicy();

  final String? _apiKey;
  final String _baseUrl;
  final String _model;
  final Duration _timeout;
  final http.Client _client;
  final RateLimiter _rateLimiter;
  final RetryPolicy _retryPolicy;

  bool _cancelled = false;
  LlmTokenUsage? _lastTokenUsage;

  @override
  bool get isEnabled {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    final hasProxy = ApiConfig.openAiProxyUrl != null;
    if (!hasKey && !hasProxy) return false;
    if (hasKey && _apiKey != ApiConfig.openAiApiKey) {
      return true;
    }
    return ApiConfig.aiEnabled;
  }

  @override
  LlmTokenUsage? get lastTokenUsage => _lastTokenUsage;

  @override
  void cancel() => _cancelled = true;

  @override
  Future<LlmCompletion> complete(LlmRequest request) async {
    _ensureEnabled();
    _cancelled = false;

    final uri = Uri.parse('$_baseUrl/chat/completions');
    final body = _buildBody(request, stream: false);

    Object? lastError;
    for (var attempt = 0; attempt <= _retryPolicy.maxAttempts; attempt++) {
      if (_cancelled) throw const AiCancelledFailure();
      try {
        await _rateLimiter.acquire(uri.host);
        final response = await _client
            .post(
              uri,
              headers: _headers(),
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (response.statusCode == 429) {
          throw const AiRateLimitFailure();
        }
        if (response.statusCode >= 400) {
          throw AiGenerationFailure(
            'OpenAI error ${response.statusCode}: ${response.body}',
          );
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final text = _extractText(decoded);
        _lastTokenUsage = _extractUsage(decoded);
        return LlmCompletion(
          text: text,
          fromMock: false,
          tokenUsage: _lastTokenUsage ?? LlmTokenUsage.zero,
        );
      } catch (e) {
        lastError = e;
        if (e is AiFailure) rethrow;
        if (e is TimeoutException) throw const AiTimeoutFailure();
        if (!_retryPolicy.shouldRetry(e, attempt)) {
          throw AiGenerationFailure(e.toString());
        }
        await Future<void>.delayed(_retryPolicy.delayForAttempt(attempt));
      }
    }
    throw AiGenerationFailure(lastError.toString());
  }

  @override
  Stream<String> stream(LlmRequest request) async* {
    _ensureEnabled();
    _cancelled = false;

    final uri = Uri.parse('$_baseUrl/chat/completions');
    final body = _buildBody(request, stream: true);

    await _rateLimiter.acquire(uri.host);
    final request_ = http.Request('POST', uri)
      ..headers.addAll(_headers())
      ..body = jsonEncode(body);

    final response = await _client.send(request_).timeout(_timeout);
    if (response.statusCode == 429) throw const AiRateLimitFailure();
    if (response.statusCode >= 400) {
      final errorBody = await response.stream.bytesToString();
      throw AiGenerationFailure(
        'OpenAI stream error ${response.statusCode}: $errorBody',
      );
    }

    final buffer = StringBuffer();
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      if (_cancelled) throw const AiCancelledFailure();
      for (final line in chunk.split('\n')) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') return;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) {
            buffer.write(delta);
            yield delta;
          }
          final usage = json['usage'];
          if (usage is Map<String, dynamic>) {
            _lastTokenUsage = LlmTokenUsage(
              promptTokens: usage['prompt_tokens'] as int? ?? 0,
              completionTokens: usage['completion_tokens'] as int? ?? 0,
              totalTokens: usage['total_tokens'] as int? ?? 0,
            );
          }
        } catch (_) {}
      }
    }
  }

  void _ensureEnabled() {
    if (!isEnabled) throw const AiProviderDisabledFailure();
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_apiKey != null) {
      headers['Authorization'] = 'Bearer $_apiKey';
    }
    return headers;
  }

  Map<String, dynamic> _buildBody(LlmRequest request, {required bool stream}) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': request.systemPrompt},
      ...request.messages.map(_mapMessage),
    ];

    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'temperature': request.temperature,
      'stream': stream,
    };

    if (request.requestJson) {
      body['response_format'] = {'type': 'json_object'};
    }

    return body;
  }

  Map<String, String> _mapMessage(AiMessage message) {
    final role = switch (message.role) {
      AiMessageRole.system => 'system',
      AiMessageRole.user => 'user',
      AiMessageRole.assistant => 'assistant',
      AiMessageRole.tool => 'user',
    };
    final content = message.role == AiMessageRole.tool
        ? '[tool:${message.toolName}] ${message.content}'
        : message.content;
    return {'role': role, 'content': content};
  }

  String _extractText(Map<String, dynamic> decoded) {
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const AiGenerationFailure('OpenAI returned no choices');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content'] as String? ?? '';
  }

  LlmTokenUsage _extractUsage(Map<String, dynamic> decoded) {
    final usage = decoded['usage'] as Map<String, dynamic>?;
    if (usage == null) return LlmTokenUsage.zero;
    return LlmTokenUsage(
      promptTokens: usage['prompt_tokens'] as int? ?? 0,
      completionTokens: usage['completion_tokens'] as int? ?? 0,
      totalTokens: usage['total_tokens'] as int? ?? 0,
    );
  }

  void dispose() => _client.close();
}
