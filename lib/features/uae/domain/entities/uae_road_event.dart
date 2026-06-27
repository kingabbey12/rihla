/// Road event affecting UAE traffic.
class UaeRoadEvent {
  const UaeRoadEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.region,
    this.activeUntil,
  });

  final String id;
  final String title;
  final String description;
  final String region;
  final DateTime? activeUntil;
}
