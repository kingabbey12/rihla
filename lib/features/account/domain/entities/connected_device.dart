/// A device registered to the user's account.
class ConnectedDevice {
  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.lastSeenAt,
    this.isCurrent = false,
  });

  final String id;
  final String name;
  final String platform;
  final DateTime? lastSeenAt;
  final bool isCurrent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'isCurrent': isCurrent,
      };

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'] as String)
          : null,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}
