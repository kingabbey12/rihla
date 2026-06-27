sealed class FuelFailure implements Exception {
  const FuelFailure(this.message);
  final String message;
}

final class FuelServiceFailure extends FuelFailure {
  const FuelServiceFailure(super.message);
}
