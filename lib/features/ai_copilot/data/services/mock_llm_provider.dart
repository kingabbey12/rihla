import 'package:rihla/features/ai_copilot/domain/entities/ai_message_role.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';

/// Deterministic mock LLM — returns templated text from [LlmRequest.mode].
class MockLlmProvider implements LLMProvider {
  MockLlmProvider({this.simulatedDelay = const Duration(milliseconds: 250)});

  final Duration simulatedDelay;

  @override
  bool get isEnabled => true;

  @override
  Future<LlmCompletion> complete(LlmRequest request) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final context = request.messages
            .where((m) => m.role == AiMessageRole.user)
            .map((m) => m.content)
            .lastOrNull ??
        '';

    final text = switch (request.mode) {
      AiCopilotMode.journeyAdvisor => _advisorText(context),
      AiCopilotMode.drivingCopilot => _copilotText(context),
      AiCopilotMode.journeyReview => _reviewText(context),
    };

    return LlmCompletion(text: text, fromMock: true);
  }

  String _advisorText(String context) {
    final destination = _extract(context, 'destination') ?? 'your destination';
    final journeyScore = _extract(context, 'journey_score') ?? '80';
    final safetyScore = _extract(context, 'safety_score') ?? '82';
    final traffic = _extract(context, 'traffic') ?? 'moderate';
    final weather = _extract(context, 'weather') ?? 'clear';
    final fuel = _extract(context, 'fuel_l') ?? '0.6';
    final battery = _extract(context, 'battery_pct') ?? '10';
    final profile = _extract(context, 'profile') ?? 'fast';

    return '''
SUMMARY: Your trip to $destination looks solid with a journey score of $journeyScore and safety score of $safetyScore. Weather is $weather with $traffic traffic.

HIGHLIGHT: Leave within the suggested window to avoid peak congestion.
HIGHLIGHT: $profile route balances time and fuel (~$fuel L, ~$battery% battery).
HIGHLIGHT: Monitor weather if conditions shift before departure.

REC:departure|Recommended departure|Depart in the next 15 minutes for the smoothest flow.|5|true
REC:route|Recommended route|Prefer the $profile profile based on current scores.|4|true
REC:safety|Safety outlook|Safety score $safetyScore — stay alert in mixed traffic.|3|false
REC:fuel|Fuel estimate|Plan ~$fuel L for this trip.|2|false
REC:battery|Battery usage|Expect ~$battery% battery draw if driving an EV.|2|false
''';
  }

  String _copilotText(String context) {
    final road = _extract(context, 'road') ?? 'current road';
    final alert = _extract(context, 'primary_alert');
    final offRoute = _extract(context, 'off_route') == 'true';
    final safety = _extract(context, 'overall') ?? '80';
    final trafficRisk = _extract(context, 'traffic_risk') ?? '25';

    final alertLine = alert != null
        ? 'Primary alert: $alert — reduce speed and stay vigilant.'
        : 'No critical hazards ahead on $road.';

    final reroute = offRoute || (int.tryParse(trafficRisk) ?? 0) > 50;

    return '''
SUMMARY: Driving on $road. Safety score $safety. $alertLine

HIGHLIGHT: Journey scores update from live engines — not AI estimates.
HIGHLIGHT: ${reroute ? 'Consider rerouting to avoid delays ahead.' : 'Current route remains optimal.'}

REC:safety|Safety alert|${alert ?? 'Conditions are stable — maintain safe following distance.'}|5|false
REC:traffic|Traffic update|Traffic risk at $trafficRisk/100.${reroute ? ' Reroute may save time.' : ''}|4|${reroute.toString()}
REC:driving|Copilot tip|Keep both hands on the wheel and check mirrors before lane changes.|2|false
''';
  }

  String _reviewText(String context) {
    final duration = _extract(context, 'duration_min') ?? '18';
    final distance = _extract(context, 'distance_km') ?? '8.5';
    final avgSpeed = _extract(context, 'average_speed_kmh') ?? '45';
    final driverScore = _extract(context, 'driver_score') ?? '85';
    final safetyTrend = _extract(context, 'safety_trend') ?? 'stable';
    final fuel = _extract(context, 'fuel_l') ?? '0.6';
    final battery = _extract(context, 'battery_pct') ?? '10';

    return '''
SUMMARY: Journey complete in $duration min over $distance km. Average speed $avgSpeed km/h. Driver score $driverScore.

HIGHLIGHT: Safety trend was $safetyTrend throughout the trip.
HIGHLIGHT: Fuel estimate ~$fuel L, battery ~$battery%.
HIGHLIGHT: Traffic varied — review peak segments for next time.

REC:improvement|Smooth acceleration|Gentler starts can improve fuel efficiency on your next trip.|4|false
REC:improvement|Lane discipline|Earlier lane positioning reduces last-minute merges.|3|false
REC:driving|Driver score|Score $driverScore — strong overall awareness.|3|false
''';
  }

  String? _extract(String context, String key) {
    final pattern = RegExp('^$key: (.+)\$', multiLine: true);
    return pattern.firstMatch(context)?.group(1)?.trim();
  }
}
