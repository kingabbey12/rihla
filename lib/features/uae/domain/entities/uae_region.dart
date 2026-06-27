/// UAE emirates supported by the intelligence platform.
enum UaeRegion {
  abuDhabi,
  dubai,
  sharjah,
  ajman,
  ummAlQuwain,
  rasAlKhaimah,
  fujairah,
}

extension UaeRegionX on UaeRegion {
  String get displayName => switch (this) {
        UaeRegion.abuDhabi => 'Abu Dhabi',
        UaeRegion.dubai => 'Dubai',
        UaeRegion.sharjah => 'Sharjah',
        UaeRegion.ajman => 'Ajman',
        UaeRegion.ummAlQuwain => 'Umm Al Quwain',
        UaeRegion.rasAlKhaimah => 'Ras Al Khaimah',
        UaeRegion.fujairah => 'Fujairah',
      };

  String get emergencyPolice => switch (this) {
        UaeRegion.abuDhabi => '999',
        UaeRegion.dubai => '999',
        _ => '999',
      };
}
