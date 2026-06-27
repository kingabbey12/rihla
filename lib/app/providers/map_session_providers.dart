import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the map driving session UI is currently mounted and visible.
final mapSessionActiveProvider =
    NotifierProvider<MapSessionActiveNotifier, bool>(
  MapSessionActiveNotifier.new,
);

class MapSessionActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setActive(bool active) => state = active;
}
