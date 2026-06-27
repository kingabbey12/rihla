import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/presentation/services/navigation_tick_scheduler.dart';

void main() {
  test('prevents overlapping ticks', () async {
    final scheduler = NavigationTickScheduler();
    var concurrent = 0;
    var maxConcurrent = 0;

    scheduler.scheduleIfNeeded(const Duration(milliseconds: 10), () async {
      concurrent++;
      maxConcurrent = concurrent > maxConcurrent ? concurrent : maxConcurrent;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      concurrent--;
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    scheduler.cancel();
    expect(maxConcurrent, 1);
  });

  test('skips reschedule when interval unchanged', () {
    final scheduler = NavigationTickScheduler();
    var tickCount = 0;

    scheduler.scheduleIfNeeded(const Duration(seconds: 1), () async {
      tickCount++;
    });
    scheduler.scheduleIfNeeded(const Duration(seconds: 1), () async {
      tickCount++;
    });

    scheduler.cancel();
    expect(tickCount, 0);
  });
}
