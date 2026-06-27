import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/widgets/search_empty_view.dart';
import 'package:rihla/features/search/presentation/widgets/search_error_view.dart';
import 'package:rihla/features/search/presentation/widgets/search_loading_view.dart';
import 'package:rihla/features/search/presentation/widgets/search_result_tile.dart';
import 'package:rihla/features/search/presentation/widgets/search_section_header.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  const place = SearchPlace(
    id: 'p1',
    name: 'Kingdom Centre',
    address: 'King Fahd Road, Riyadh',
    latitude: 24.7,
    longitude: 46.6,
    category: 'landmark',
  );

  testWidgets('SearchResultTile shows name and address', (tester) async {
    await tester.pumpWidget(
      _wrap(SearchResultTile(place: place, onTap: () {})),
    );
    expect(find.text('Kingdom Centre'), findsOneWidget);
    expect(find.text('King Fahd Road, Riyadh'), findsOneWidget);
  });

  testWidgets('SearchResultTile onTap fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(SearchResultTile(place: place, onTap: () => tapped = true)),
    );
    await tester.tap(find.text('Kingdom Centre'));
    expect(tapped, isTrue);
  });

  testWidgets('SearchLoadingView shows spinner', (tester) async {
    await tester.pumpWidget(_wrap(const SearchLoadingView()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SearchEmptyView renders title', (tester) async {
    await tester.pumpWidget(_wrap(const SearchEmptyView()));
    expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
  });

  testWidgets('SearchErrorView retry fires', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(SearchErrorView(onRetry: () => retried = true)),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('SearchSectionHeader action fires', (tester) async {
    var cleared = false;
    await tester.pumpWidget(
      _wrap(
        SearchSectionHeader(
          title: 'Recent',
          actionLabel: 'Clear',
          onAction: () => cleared = true,
        ),
      ),
    );
    await tester.tap(find.text('Clear'));
    expect(cleared, isTrue);
  });
}
