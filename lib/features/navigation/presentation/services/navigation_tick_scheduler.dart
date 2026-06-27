import 'dart:async';

/// Manages periodic navigation ticks with re-entrancy protection.
class NavigationTickScheduler {
  Timer? _timer;
  bool _tickInProgress = false;
  Duration? _scheduledInterval;

  bool get isTickInProgress => _tickInProgress;

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _scheduledInterval = null;
    _tickInProgress = false;
  }

  void cancel() => dispose();

  /// Schedules [onTick] at [interval]. Skips reschedule when interval unchanged.
  void scheduleIfNeeded(
    Duration interval,
    Future<void> Function() onTick,
  ) {
    if (_scheduledInterval == interval && _timer != null) return;
    _timer?.cancel();
    _scheduledInterval = interval;
    _timer = Timer.periodic(interval, (_) => _runTick(onTick));
  }

  Future<void> _runTick(Future<void> Function() onTick) async {
    if (_tickInProgress) return;
    _tickInProgress = true;
    try {
      await onTick();
    } finally {
      _tickInProgress = false;
    }
  }

  /// Runs a single tick immediately (e.g. simulate deviation).
  Future<void> runOnce(Future<void> Function() onTick) => _runTick(onTick);
}
