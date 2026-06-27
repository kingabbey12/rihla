/// Central offline engine states observed by every feature.
enum OfflineEngineState {
  online,
  offline,
  syncing,
  downloading,
  updating,
  paused,
  error,
}

/// Lifecycle of a region download.
enum OfflineDownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
  verifying,
  repairing,
}

/// Kind of downloadable map region.
enum OfflineRegionType {
  emirate,
  custom,
  drawn,
}
