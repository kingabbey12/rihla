import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/config/api_config.dart';
import 'package:rihla/features/ai_copilot/data/repositories/ai_repository_impl.dart';
import 'package:rihla/features/ai_copilot/data/services/ai_context_builder_impl.dart';
import 'package:rihla/features/ai_copilot/data/services/ai_context_enricher.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_ai_service.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_llm_provider.dart';
import 'package:rihla/features/ai_copilot/data/services/openai_llm_provider.dart';
import 'package:rihla/features/ai_copilot/data/services/prompt_builder_impl.dart';
import 'package:rihla/features/ai_copilot/data/utils/ai_context_cache.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';
import 'package:rihla/features/ai_copilot/domain/entities/llm_token_usage.dart';
import 'package:rihla/features/ai_copilot/domain/errors/ai_failure.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/domain/repositories/ai_repository.dart';
import 'package:rihla/features/ai_copilot/domain/services/ai_context_builder.dart';
import 'package:rihla/features/ai_copilot/domain/services/ai_service.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';
import 'package:rihla/features/ai_copilot/domain/services/prompt_builder.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/uae/presentation/providers/uae_providers.dart';
import 'package:rihla/features/weather/presentation/providers/weather_providers.dart';

// —— Infrastructure ————————————————————————————————————————————————————————

final openAiLlmProvider = Provider<OpenAiLlmProvider>(
  (ref) => OpenAiLlmProvider(
    apiKey: ApiConfig.openAiApiKey,
    baseUrl: ApiConfig.openAiBaseUrl,
    model: ApiConfig.openAiModel,
    timeout: ApiConfig.openAiTimeout,
  ),
);

/// Production LLM when enabled and configured; mock fallback for dev/tests.
final llmProviderProvider = Provider<LLMProvider>((ref) {
  final openAi = ref.watch(openAiLlmProvider);
  if (ApiConfig.aiEnabled && openAi.isEnabled) {
    return openAi;
  }
  return MockLlmProvider();
});

final promptBuilderProvider = Provider<PromptBuilder>(
  (ref) => PromptBuilderImpl(),
);

final aiContextBuilderProvider = Provider<AiContextBuilder>(
  (ref) => AiContextBuilderImpl(),
);

final aiContextCacheProvider = Provider<AiContextCache>((ref) => AiContextCache());

final aiMedicalSharingEnabledProvider = Provider<bool>((ref) => false);

final aiContextEnricherProvider = Provider<AiContextEnricher>(
  (ref) => AiContextEnricher(
    emergencyRepository: ref.watch(emergencyRepositoryProvider),
    exploreRepository: ref.watch(exploreRepositoryProvider),
    isOffline: () => ref.read(isOfflineModeProvider),
    uaeService: ref.watch(uaeServiceProvider),
    uaePreferences: ref.watch(uaePreferencesProvider),
    weatherSnapshot: ref.watch(weatherSnapshotProvider),
    medicalSharingEnabled: ref.watch(aiMedicalSharingEnabledProvider),
  ),
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

final aiIsLiveProvider = Provider<bool>((ref) {
  final llm = ref.watch(llmProviderProvider);
  return ApiConfig.aiEnabled && llm is OpenAiLlmProvider && llm.isEnabled;
});

final aiLastTokenUsageProvider = Provider<LlmTokenUsage?>((ref) {
  return ref.watch(llmProviderProvider).lastTokenUsage;
});

// —— Controller ———————————————————————————————————————————————————————————————

final aiControllerProvider =
    NotifierProvider<AiController, AiCopilotState>(AiController.new);

class AiController extends Notifier<AiCopilotState> {
  DateTime? _lastCopilotRefresh;
  String? _lastReviewSessionId;
  String? _lastAdvisorKey;
  DateTime? _lastSessionTick;

  @override
  AiCopilotState build() {
    ref.listen(navigationSessionControllerProvider, (previous, next) {
      if (next is NavigationSessionInactive) {
        ref.read(aiRepositoryProvider).clear();
        ref.read(aiContextCacheProvider).clear();
        _lastSessionTick = null;
        _lastReviewSessionId = null;
        return;
      }
      if (next is! NavigationSessionActive) return;
      final session = next.session;
      if (session.hasArrived) {
        loadJourneyReview(session);
        return;
      }
      final tick = session.lastUpdatedAt;
      if (_lastSessionTick == tick) return;
      _lastSessionTick = tick;
      refreshDrivingCopilot(session);
    });

    ref.listen(journeyControllerProvider, (previous, next) {
      final summary = switch (next) {
        JourneyPreview(:final summary) => summary,
        _ => null,
      };
      if (summary == null) return;
      final routeState = ref.read(routeControllerProvider);
      final routeId = switch (routeState) {
        RouteSelected(:final selected) => selected.id,
        RouteReady(:final result) => result.primary?.id ?? 'preview',
        _ => 'preview',
      };
      final key = '${summary.destination.id}_$routeId';
      if (_lastAdvisorKey == key) return;
      _lastAdvisorKey = key;
      loadJourneyAdvisor(summary);
    });

    return const AiCopilotInactive();
  }

  bool get _isOffline => ref.read(isOfflineModeProvider);

  Future<AiContext> _prepareContext(AiContext base) async {
    final cache = ref.read(aiContextCacheProvider);
    final cached = cache.get(base.cacheKey);
    if (cached != null) return cached;
    final enriched = await ref.read(aiContextEnricherProvider).enrich(base);
    cache.put(enriched);
    return enriched;
  }

  void _guardOffline() {
    if (_isOffline) throw const AiOfflineFailure();
  }

  String _failureMessage(Object error) {
    if (error is AiFailure) return error.message;
    return 'AI unavailable. Please try again.';
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
    if (_isOffline) {
      state = const AiCopilotOffline();
      return;
    }
    state = const AiCopilotLoading(AiCopilotMode.journeyAdvisor);
    try {
      _guardOffline();
      final base = ref.read(aiContextBuilderProvider).buildJourneyAdvisor(
            journey: journey,
            route: _selectedRoute(),
            location: _currentLocation(),
          );
      final context = await _prepareContext(base);
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
        toolOutputs: _toolOutputs(context),
      );
      state = AiCopilotAdvisorReady(
        response: response,
        conversation: conversation,
      );
    } catch (e) {
      state = e is AiOfflineFailure
          ? const AiCopilotOffline()
          : AiCopilotError(_failureMessage(e));
    }
  }

  Future<void> refreshDrivingCopilot(NavigationSession session) async {
    if (_isOffline) {
      state = const AiCopilotOffline();
      return;
    }

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
      _guardOffline();
      final base = ref.read(aiContextBuilderProvider).buildDrivingCopilot(
            session: session,
            liveMetrics: metrics,
            location: _currentLocation(),
          );
      final context = await _prepareContext(base);
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
        toolOutputs: _toolOutputs(context),
      );
      state = AiCopilotDrivingReady(
        response: response,
        conversation: conversation,
      );
    } catch (e) {
      state = e is AiOfflineFailure
          ? const AiCopilotOffline()
          : AiCopilotError(_failureMessage(e));
    }
  }

  Future<void> loadJourneyReview(NavigationSession session) async {
    if (_isOffline) {
      state = const AiCopilotOffline();
      return;
    }
    if (_lastReviewSessionId == session.sessionId &&
        state is AiCopilotReviewReady) {
      return;
    }
    _lastReviewSessionId = session.sessionId;
    state = const AiCopilotLoading(AiCopilotMode.journeyReview);

    try {
      _guardOffline();
      final liveState = ref.read(liveJourneyControllerProvider);
      final metrics =
          liveState is LiveJourneyActive ? liveState.metrics : null;
      final elapsed = DateTime.now().difference(session.startedAt);
      final avgSpeed = elapsed.inMinutes > 0
          ? session.distanceTraveledKm / (elapsed.inMinutes / 60)
          : session.speedKmh;
      final driverScore = session.safety.assessment.driverAlertness;
      final safetyTrend = _safetyTrend(session);

      final base = ref.read(aiContextBuilderProvider).buildJourneyReview(
            session: session,
            liveMetrics: metrics,
            averageSpeedKmh: avgSpeed,
            driverScore: driverScore,
            safetyScoreTrend: safetyTrend,
          );
      final context = await _prepareContext(base);
      final response = await ref.read(aiServiceProvider).reviewJourney(context);
      final conversation = await _persistConversation(
        mode: AiCopilotMode.journeyReview,
        context: context,
        response: response,
        previous: null,
        toolOutputs: _toolOutputs(context),
      );
      state = AiCopilotReviewReady(
        response: response,
        conversation: conversation,
      );
    } catch (e) {
      state = e is AiOfflineFailure
          ? const AiCopilotOffline()
          : AiCopilotError(_failureMessage(e));
    }
  }

  void reset() {
    _lastCopilotRefresh = null;
    _lastReviewSessionId = null;
    _lastAdvisorKey = null;
    _lastSessionTick = null;
    ref.read(llmProviderProvider).cancel();
    ref.read(aiRepositoryProvider).clear();
    ref.read(aiContextCacheProvider).clear();
    state = const AiCopilotInactive();
  }

  void clearConversation() {
    ref.read(aiRepositoryProvider).clear();
    ref.read(aiContextCacheProvider).clear();
    state = const AiCopilotInactive();
  }

  String? exportConversation() {
    final conversation = ref.read(aiRepositoryProvider).current;
    if (conversation == null) return null;
    return ref.read(aiRepositoryProvider).exportConversation(conversation);
  }

  void dismissReview() {
    if (state is AiCopilotReviewReady) {
      state = const AiCopilotInactive();
    }
  }

  void cancelGeneration() {
    ref.read(llmProviderProvider).cancel();
  }

  String _safetyTrend(NavigationSession session) {
    final score = session.safety.assessment.overallSafetyScore;
    if (score >= 80) return 'improving';
    if (score >= 60) return 'stable';
    return 'declining';
  }

  List<String> _toolOutputs(AiContext context) {
    return [
      if (context.safety != null)
        'safety_engine: ${context.safety!.assessment.overallSafetyScore}',
      if (context.route != null) 'route_engine: ${context.route!.id}',
      if (context.isOffline) 'offline_state: active',
    ];
  }

  Future<AiConversation> _persistConversation({
    required AiCopilotMode mode,
    required AiContext context,
    required AiResponse response,
    AiConversation? previous,
    List<String> toolOutputs = const [],
  }) async {
    var conversation = previous ??
        AiConversation(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          mode: mode,
          messages: const [],
        );

    conversation = conversation
        .appendMessage(AiMessage.assistant(response.summary))
        .copyWith(
          lastContext: context,
          toolOutputs: toolOutputs,
          memory: {
            ...conversation.memory,
            'last_mode': mode.name,
            'generated_at': response.generatedAt.toIso8601String(),
          },
        );

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

final aiOfflineProvider = Provider<bool>((ref) {
  return ref.watch(aiControllerProvider) is AiCopilotOffline;
});
