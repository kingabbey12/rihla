/// Today's driving metrics for the home dashboard card.
class HomeTodaysDrivingStats {
  const HomeTodaysDrivingStats({
    required this.trips,
    required this.distanceKm,
    required this.drivingScore,
    required this.drivingMinutes,
  });

  final int trips;
  final double distanceKm;
  final int drivingScore;
  final int drivingMinutes;
}
