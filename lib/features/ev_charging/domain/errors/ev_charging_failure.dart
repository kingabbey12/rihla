sealed class EvChargingFailure implements Exception {
  const EvChargingFailure(this.message);
  final String message;
}

final class EvChargingServiceFailure extends EvChargingFailure {
  const EvChargingServiceFailure(super.message);
}
