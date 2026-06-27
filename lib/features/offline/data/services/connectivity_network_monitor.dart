import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rihla/features/offline/domain/services/network_monitor.dart';

/// Production connectivity monitor using connectivity_plus.
class ConnectivityNetworkMonitor implements NetworkMonitor {
  ConnectivityNetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> checkConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  @override
  void start() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_isConnected(results));
    });
    unawaited(checkConnected().then(_controller.add));
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

/// Test double for network monitoring.
class FakeNetworkMonitor implements NetworkMonitor {
  FakeNetworkMonitor({bool connected = true}) : _connected = connected;

  final _controller = StreamController<bool>.broadcast();
  bool _connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> checkConnected() async => _connected;

  void setConnected(bool value) {
    _connected = value;
    _controller.add(value);
  }

  @override
  void start() => _controller.add(_connected);

  @override
  void dispose() => _controller.close();
}
