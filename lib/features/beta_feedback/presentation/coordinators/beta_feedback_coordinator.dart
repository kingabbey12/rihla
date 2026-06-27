import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/beta_feedback/presentation/providers/beta_feedback_providers.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

/// Syncs pending beta feedback when connectivity returns.
final betaFeedbackCoordinatorProvider = Provider<BetaFeedbackCoordinator>((ref) {
  final coordinator = BetaFeedbackCoordinator(ref);
  coordinator.attach();
  ref.onDispose(coordinator.detach);
  return coordinator;
});

class BetaFeedbackCoordinator {
  BetaFeedbackCoordinator(this._ref);

  final Ref _ref;
  StreamSubscription<bool>? _subscription;

  void attach() {
    _subscription = _ref.read(networkMonitorProvider).onConnectivityChanged.listen(
      (connected) {
        if (connected) unawaited(_sync());
      },
    );
  }

  void detach() => _subscription?.cancel();

  Future<void> _sync() async {
    await _ref.read(betaFeedbackServiceProvider).syncPending();
  }
}

/// Attaches the beta feedback coordinator at app bootstrap.
class BetaFeedbackBootstrap extends ConsumerStatefulWidget {
  const BetaFeedbackBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BetaFeedbackBootstrap> createState() =>
      _BetaFeedbackBootstrapState();
}

class _BetaFeedbackBootstrapState extends ConsumerState<BetaFeedbackBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(betaFeedbackCoordinatorProvider);
      ref.read(betaMetricsServiceProvider).recordSession();
      ref.read(betaMetricsServiceProvider).recordCrashFreeSession();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
