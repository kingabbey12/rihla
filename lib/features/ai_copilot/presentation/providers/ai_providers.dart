import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/ai_copilot/data/repositories/ai_repository_impl.dart';
import 'package:rihla/features/ai_copilot/data/services/ai_context_builder_impl.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_ai_service.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_llm_provider.dart';
import 'package:rihla/features/ai_copilot/data/services/openai_llm_provider.dart';
import 'package:rihla/features/ai_copilot/data/services/prompt_builder_impl.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/domain/repositories/ai_repository.dart';
import 'package:rihla/features/ai_copilot/domain/services/ai_context_builder.dart';
import 'package:rihla/features/ai_copilot/domain/services/ai_service.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';
import 'package:rihla/features/ai_copilot/domain/services/prompt_builder.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Swap to [OpenAiLlmProvider] when API keys are approved.
final llmProviderProvider = Provider<LLMProvider>(
  (ref) => MockLlmProvider(),
);

final openAiLlmProvider = Provider<OpenAiLlmProvider>(
  (ref) => OpenAiLlmProvider(),
);

final promptBuilderProvider = Provider<PromptBuilder>(
  (ref) => PromptBuilderImpl(),
);

final aiContextBuilderProvider = Provider<AiContextBuilder>(
  (ref) => AiContextBuilderImpl(),
);

final aiServiceProvider = Provider<AiService>(
  (ref) => MockAiService(
    promptBuilder: ref.watch(promptBuilderProvider),
    llmProvider: ref.watch(llmProviderProvider),
  ),
);

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepositoryImpl(),
);

/// Central AI copilot controller.
final aiControllerProvider =
    NotifierProvider<AiController, AiCopilotState>(AiController.new);

class AiController extends Notifier<AiCopilotState> {
  DateTime? _lastCopilotRefresh;
  String? _lastReviewSessionId;

  @override
  AiCopilotState build() {
    ref.listen(navigationSessionControllerProvider, (previous, next) {
      if (next is NavigationSessionInactive) {
        ref.read(aiRepositoryProvider).clear();
      }
    });
    return const AiCopilotInactive();
  }

  LocationPosition? _currentLocation() {
    final loc = ref.read(locationControllerProvider);
    return switch (loc) {
      LocationActive(:final position) => position,
      _ => null,
    };
  }

  RouteSummary? _selectedRoute() {
    final routeState = ref.read(routeControllerProvider);
    return switch (routeState) {
      RouteSelected(:final selected) => selected,
      RouteConfirmed(:final selected) => selected,
      _ => null,
    };
  }

  Future<void> loadJourneyAdvisor(JourneySummary journey) async {
    state = const AiCopilotLoading(AiCopilotMode.journeyAdvisor);
    try {
      final context = ref.read(aiContextBuilderProvider).buildJourneyAdvisor(
            journey: journey,
            route: _selectedRoute(),
            location: _currentLocation(),
          );
      final existing = ref.read(aiRepositoryProvider).current;
      final response = await ref.read(aiServiceProvider).adviseJourney(
            context,
            conversation: existing?.mode == AiCopilotMode.journeyAdvisor
                ? existing
                : null,
          );
      final conversation = await _persistConversation(
        mode: AiCopilotMode.journeyAdvisor,
        context: context,
        response: response,
        previous: existing,
      );
      state = AiCopilotAdvisorReady(
        response: response,
        conversation: conversation,
      );
    } catch (e) {
      state = AiCopilotError(e.toString());
    }
  }

  Future<void> refreshDrivingCopilot(NavigationSession session) async {
    final now = DateTime.now();
    if (_lastCopilotRefresh != null &&
        now.difference(_lastCopilotRefresh!) < const Duration(seconds: 2)) {
      return;
    }
    _lastCopilotRefresh = now;

    final liveState = ref.read(liveJourneyControllerProvider);
    final metrics =
        liveState is LiveJourneyActive ? liveState.metrics : null;

    if (state is! AiCopilotDrivingReady) {
      state = const AiCopilotLoading(AiCopilotMode.drivingCopilot);
    }

    try {
      final context = ref.read(aiContextBuilderProvider).buildDrivingCopilot(
            session: session,
            liveMetrics: metrics,
            location: _currentLocation(),
          );
      final existing = ref.read(aiRepositoryProvider).current;
      final response = await ref.read(aiServiceProvider).copilotUpdate(
            context,
            conversation: existing?.mode == AiCopilotMode.drivingCopilot
                ? existing
                : null,
          );
      final conversation = await _persistConversation(
        mode: AiCopilotMode.drivingCopilot,
        context: context,
        response: response,
        previous: existing?.mode == AiCopilotMode.drivingCopilot
            ? existing
            : null,
      );
      state = AiCopilotDrivingReady(
        response: response,
        conversation: conversation,
      );
    } catch (e) {
      state = AiCopilotError(e.toString());
    }
  }

  Future<void> loadJourneyReview(NavigationSession session) async {
    if (_lastReviewSessionId == session.sessionId &&
        state is AiCopilotReviewReady) {
      return;
    }
    _lastReviewSessionId = session.sessionId;
    state = const AiCopilotLoading(AiCopilotMode.journeyReview);

    try {
      final liveState = ref.read(liveJourneyControllerProvider);
      final metrics =
          liveState is LiveJourneyActive ? liveState.metrics : null;
      final elapsed = DateTime.now().difference(session.startedAt);
      final avgSpeed = elapsed.inMinutes > 0
          ? session.distanceTraveledKm / (elapsed.inMinutes / 60)
          : session.speedKmh;
      final driverScore = session.safety.assessment.driverAlertness;
      final safetyTrend = _safetyTrend(session);

      final context = ref.read(aiContextBuilderProvider).buildJourneyReview(
            session: session,
            liveMetrics: metrics,
            averageSpeedKmh: avgSpeed,
            driverScore: driverScore,
            safetyScoreTrend: safetyTrend,
          );
      final response = await ref.read(aiServiceProvider).reviewJourney(context);
      final conversation = await _persistConversation(
        mode: AiCopilotMode.journeyReview,
        context: context,
        response: response,
        previous: null,
      );
      state = AiCopilotReviewReady(
        response: response,
        conversation: conversation,
      );
    } catch (e) {
      state = AiCopilotError(e.toString());
    }
  }

  void reset() {
    _lastCopilotRefresh = null;
    _lastReviewSessionId = null;
    ref.read(aiRepositoryProvider).clear();
    state = const AiCopilotInactive();
  }

  void dismissReview() {
    if (state is AiCopilotReviewReady) {
      state = const AiCopilotInactive();
    }
  }

  String _safetyTrend(NavigationSession session) {
    final score = session.safety.assessment.overallSafetyScore;
    if (score >= 80) return 'improving';
    if (score >= 60) return 'stable';
    return 'declining';
  }

  Future<AiConversation> _persistConversation({
    required AiCopilotMode mode,
    required AiContext context,
    required AiResponse response,
    AiConversation? previous,
  }) async {
    var conversation = previous ??
        AiConversation(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          mode: mode,
          messages: const [],
        );

    conversation = conversation
        .appendMessage(AiMessage.assistant(response.summary))
        .copyWith(lastContext: context);

    await ref.read(aiRepositoryProvider).save(conversation);
    return conversation;
  }
}

final aiResponseProvider = Provider<AiResponse?>((ref) {
  return switch (ref.watch(aiControllerProvider)) {
    AiCopilotAdvisorReady(:final response) => response,
    AiCopilotDrivingReady(:final response) => response,
    AiCopilotReviewReady(:final response) => response,
    _ => null,
  };
});

final aiRecommendationsProvider = Provider<List<AiRecommendation>>((ref) {
  return ref.watch(aiResponseProvider)?.recommendations ?? const [];
});

final aiHighlightsProvider = Provider<List<String>>((ref) {
  return ref.watch(aiResponseProvider)?.highlights ?? const [];
});

final aiIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(aiControllerProvider) is AiCopilotLoading;
});

final aiAdvisorActiveProvider = Provider<bool>((ref) {
  return ref.watch(aiControllerProvider) is AiCopilotAdvisorReady;
});

final aiCopilotActiveProvider = Provider<bool>((ref) {
  return ref.watch(aiControllerProvider) is AiCopilotDrivingReady;
});

final aiReviewActiveProvider = Provider<bool>((ref) {
  return ref.watch(aiControllerProvider) is AiCopilotReviewReady;
});
