import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/search/data/datasources/uae_search_places_catalog.dart';
import 'package:rihla/features/uae/data/catalog/uae_catalog.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';

void main() {
  group('UAE search catalog', () {
    test('finds required landmark examples', () {
      for (final query in [
        'Dubai Mall',
        'Burj Khalifa',
        'Palm Jumeirah',
        'Mall of the Emirates',
        'Dubai Marina',
        'Business Bay',
        'Downtown Dubai',
        'JVC',
        'Al Barsha',
        'Expo City',
        'Global Village',
        'Yas Island',
        'Al Ain',
        'Khalifa City',
        'Sharjah City Centre',
        'Abu Dhabi Corniche',
      ]) {
        final results = UaeSearchPlacesCatalog.search(query);
        expect(results, isNotEmpty, reason: 'No result for "$query"');
        final q = query.toLowerCase();
        final matched = results.any(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.address.toLowerCase().contains(q) ||
              q.split(' ').every(
                    (word) =>
                        p.name.toLowerCase().contains(word) ||
                        p.address.toLowerCase().contains(word),
                  ),
        );
        expect(matched, isTrue, reason: 'No match for "$query" in ${results.map((p) => p.name).join(", ")}');
      }
    });

    test('covers all seven emirates', () {
      final names = UaeSearchPlacesCatalog.all.map((p) => p.address).join(' ');
      for (final emirate in [
        'Dubai',
        'Abu Dhabi',
        'Sharjah',
        'Ajman',
        'Ras Al Khaimah',
        'Fujairah',
        'Umm Al Quwain',
      ]) {
        expect(names, contains(emirate));
      }
    });
  });

  group('UAE emergency directory', () {
    test('includes core UAE emergency numbers', () {
      final contacts = UaeCatalog.emergencyDirectory(UaeRegion.dubai);
      final numbers = contacts.map((c) => c.number).toSet();
      expect(numbers, contains('999'));
      expect(numbers, contains('998'));
      expect(numbers, contains('997'));
      expect(numbers, contains('800 4357'));
      expect(numbers, contains('800 424'));
    });

    test('Salik gates use real Dubai coordinates', () {
      expect(UaeCatalog.salikGates.length, greaterThanOrEqualTo(8));
      for (final gate in UaeCatalog.salikGates) {
        expect(gate.latitude, greaterThan(24.9));
        expect(gate.latitude, lessThan(25.4));
        expect(gate.longitude, greaterThan(55.0));
        expect(gate.longitude, lessThan(55.4));
      }
    });
  });
}
