/// Speed limit for the current road segment.
class SpeedLimit {
  const SpeedLimit({
    required this.limitKmh,
    this.isPlaceholder = true,
  });

  final int limitKmh;
  final bool isPlaceholder;

  static const placeholder = SpeedLimit(limitKmh: 80, isPlaceholder: true);
}
