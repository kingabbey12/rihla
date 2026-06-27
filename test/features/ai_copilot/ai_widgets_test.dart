import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation_type.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_insight_card.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_recommendation_list.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

AiResponse _response() => AiResponse(
      summary: 'Your trip looks good.',
      recommendations: const [
        AiRecommendation(
          id: 'rec_1',
          type: AiRecommendationType.route,
          title: 'Recommended route',
          body: 'Take the fast profile.',
        ),
      ],
      highlights: const ['Leave within 15 minutes'],
      generatedAt: DateTime.now(),
    );

void main() {
  testWidgets('AiInsightCard shows summary', (tester) async {
    await tester.pumpWidget(
      _wrap(AiInsightCard(title: 'Journey Advisor', response: _response())),
    );
    expect(find.text('Your trip looks good.'), findsOneWidget);
    expect(find.text('Leave within 15 minutes'), findsOneWidget);
  });

  testWidgets('AiRecommendationList renders items', (tester) async {
    await tester.pumpWidget(
      _wrap(AiRecommendationList(recommendations: _response().recommendations)),
    );
    expect(find.text('Recommended route'), findsOneWidget);
  });
}
