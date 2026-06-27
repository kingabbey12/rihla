import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation_type.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';
import 'package:rihla/features/ai_copilot/domain/services/ai_service.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';
import 'package:rihla/features/ai_copilot/domain/services/prompt_builder.dart';

/// AI service that routes all generation through [PromptBuilder] + [LLMProvider].
class MockAiService implements AiService {
  MockAiService({
    required this.promptBuilder,
    required this.llmProvider,
  });

  final PromptBuilder promptBuilder;
  final LLMProvider llmProvider;

  @override
  Future<AiResponse> adviseJourney(
    AiContext context, {
    AiConversation? conversation,
  }) =>
      _generate(context, conversation);

  @override
  Future<AiResponse> copilotUpdate(
    AiContext context, {
    AiConversation? conversation,
  }) =>
      _generate(context, conversation);

  @override
  Future<AiResponse> reviewJourney(
    AiContext context, {
    AiConversation? conversation,
  }) =>
      _generate(context, conversation);

  Future<AiResponse> _generate(
    AiContext context,
    AiConversation? conversation,
  ) async {
    final package = promptBuilder.build(context, conversation: conversation);
    final messages = <AiMessage>[
      ...?conversation?.messages,
      AiMessage.user(package.userPrompt),
    ];

    for (final tool in package.toolOutputs) {
      messages.add(
        AiMessage.tool(
          name: 'engine_output',
          content: tool,
          outputId: 'tool_${messages.length}',
        ),
      );
    }

    final completion = await llmProvider.complete(
      LlmRequest(
        mode: context.mode,
        systemPrompt: package.systemPrompt,
        messages: messages,
      ),
    );

    return _parseCompletion(completion);
  }

  AiResponse _parseCompletion(LlmCompletion completion) {
    final lines = completion.text.split('\n');
    final highlights = <String>[];
    final recommendations = <AiRecommendation>[];
    final summaryBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('SUMMARY:')) {
        summaryBuffer.writeln(trimmed.substring(8).trim());
      } else if (trimmed.startsWith('HIGHLIGHT:')) {
        highlights.add(trimmed.substring(10).trim());
      } else if (trimmed.startsWith('REC:')) {
        final rec = _parseRecommendation(trimmed);
        if (rec != null) recommendations.add(rec);
      }
    }

    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    return AiResponse(
      summary: summaryBuffer.toString().trim(),
      recommendations: recommendations,
      highlights: highlights,
      generatedAt: DateTime.now(),
      fromMock: completion.fromMock,
    );
  }

  AiRecommendation? _parseRecommendation(String line) {
    // REC:type|title|body|priority|actionable
    final payload = line.substring(4);
    final parts = payload.split('|');
    if (parts.length < 3) return null;

    final type = _typeFrom(parts[0]);
    final priority = parts.length > 3 ? int.tryParse(parts[3]) ?? 3 : 3;
    final actionable =
        parts.length > 4 && parts[4].toLowerCase() == 'true';

    return AiRecommendation(
      id: 'rec_${type.name}_${parts[1].hashCode}',
      type: type,
      title: parts[1],
      body: parts[2],
      priority: priority,
      actionable: actionable,
    );
  }

  AiRecommendationType _typeFrom(String raw) {
    return AiRecommendationType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => AiRecommendationType.general,
    );
  }
}
