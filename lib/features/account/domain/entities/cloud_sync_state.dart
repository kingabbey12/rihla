/// Cloud synchronization status.
enum CloudSyncStatus {
  idle,
  syncing,
  error,
  conflict,
  offline,
}

/// Current cloud sync state for the signed-in account.
class CloudSyncState {
  const CloudSyncState({
    this.status = CloudSyncStatus.idle,
    this.lastSyncAt,
    this.lastError,
    this.pendingWrites = 0,
    this.conflictCount = 0,
    this.storageUsedBytes = 0,
    this.isSignedIn = false,
  });

  final CloudSyncStatus status;
  final DateTime? lastSyncAt;
  final String? lastError;
  final int pendingWrites;
  final int conflictCount;
  final int storageUsedBytes;
  final bool isSignedIn;

  CloudSyncState copyWith({
    CloudSyncStatus? status,
    DateTime? lastSyncAt,
    String? lastError,
    int? pendingWrites,
    int? conflictCount,
    int? storageUsedBytes,
    bool? isSignedIn,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      pendingWrites: pendingWrites ?? this.pendingWrites,
      conflictCount: conflictCount ?? this.conflictCount,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      isSignedIn: isSignedIn ?? this.isSignedIn,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'lastError': lastError,
        'pendingWrites': pendingWrites,
        'conflictCount': conflictCount,
        'storageUsedBytes': storageUsedBytes,
        'isSignedIn': isSignedIn,
      };

  factory CloudSyncState.fromJson(Map<String, dynamic> json) {
    return CloudSyncState(
      status: CloudSyncStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CloudSyncStatus.idle,
      ),
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.tryParse(json['lastSyncAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
      pendingWrites: json['pendingWrites'] as int? ?? 0,
      conflictCount: json['conflictCount'] as int? ?? 0,
      storageUsedBytes: json['storageUsedBytes'] as int? ?? 0,
      isSignedIn: json['isSignedIn'] as bool? ?? false,
    );
  }

  static const initial = CloudSyncState();
}
