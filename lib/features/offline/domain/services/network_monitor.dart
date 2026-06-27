/// Monitors device network connectivity.
abstract class NetworkMonitor {
  Stream<bool> get onConnectivityChanged;
  Future<bool> checkConnected();
  void start();
  void dispose();
}
