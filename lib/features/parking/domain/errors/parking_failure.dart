sealed class ParkingFailure implements Exception {
  const ParkingFailure(this.message);
  final String message;
}

final class ParkingServiceFailure extends ParkingFailure {
  const ParkingServiceFailure(super.message);
}
