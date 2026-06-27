/// Result of an offline sync operation when connectivity is restored.
class OfflineSyncResult {
  const OfflineSyncResult({
    required this.success,
    required this.syncedAt,
    this.favoritesSynced = 0,
    this.recentsSynced = 0,
    this.regionsUpdated = 0,
    this.searchIndexUpdated = false,
    this.conflictsResolved = 0,
    this.errorMessage,
  });

  final bool success;
  final DateTime syncedAt;
  final int favoritesSynced;
  final int recentsSynced;
  final int regionsUpdated;
  final bool searchIndexUpdated;
  final int conflictsResolved;
  final String? errorMessage;
}
