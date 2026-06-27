/// Holiday or event traffic prediction.
enum UaeHolidayType {
  ramadan,
  eidAlFitr,
  eidAlAdha,
  nationalDay,
  airport,
  stadium,
  publicEvent,
}

class UaeHolidayTraffic {
  const UaeHolidayTraffic({
    required this.type,
    required this.title,
    required this.description,
    required this.trafficMultiplier,
    this.activeUntil,
  });

  final UaeHolidayType type;
  final String title;
  final String description;
  final double trafficMultiplier;
  final DateTime? activeUntil;

  bool get isActive =>
      activeUntil == null || activeUntil!.isAfter(DateTime.now());
}
