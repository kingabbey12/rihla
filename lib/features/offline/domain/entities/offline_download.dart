import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';

/// Tracks a single region download job.
class OfflineDownload {
  const OfflineDownload({
    required this.id,
    required this.regionId,
    required this.regionName,
    required this.status,
    required this.progressPercent,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.version,
    required this.createdAt,
    this.updatedAt,
    this.errorMessage,
    this.retryCount = 0,
  });

  final String id;
  final String regionId;
  final String regionName;
  final OfflineDownloadStatus status;
  final double progressPercent;
  final int bytesDownloaded;
  final int totalBytes;
  final String version;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? errorMessage;
  final int retryCount;

  bool get isActive =>
      status == OfflineDownloadStatus.downloading ||
      status == OfflineDownloadStatus.queued ||
      status == OfflineDownloadStatus.verifying;

  OfflineDownload copyWith({
    OfflineDownloadStatus? status,
    double? progressPercent,
    int? bytesDownloaded,
    int? totalBytes,
    DateTime? updatedAt,
    String? errorMessage,
    int? retryCount,
  }) =>
      OfflineDownload(
        id: id,
        regionId: regionId,
        regionName: regionName,
        status: status ?? this.status,
        progressPercent: progressPercent ?? this.progressPercent,
        bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
        totalBytes: totalBytes ?? this.totalBytes,
        version: version,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        errorMessage: errorMessage ?? this.errorMessage,
        retryCount: retryCount ?? this.retryCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'regionId': regionId,
        'regionName': regionName,
        'status': status.name,
        'progressPercent': progressPercent,
        'bytesDownloaded': bytesDownloaded,
        'totalBytes': totalBytes,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'errorMessage': errorMessage,
        'retryCount': retryCount,
      };

  factory OfflineDownload.fromJson(Map<String, dynamic> json) =>
      OfflineDownload(
        id: json['id'] as String,
        regionId: json['regionId'] as String,
        regionName: json['regionName'] as String,
        status: OfflineDownloadStatus.values.byName(json['status'] as String),
        progressPercent: (json['progressPercent'] as num).toDouble(),
        bytesDownloaded: json['bytesDownloaded'] as int,
        totalBytes: json['totalBytes'] as int,
        version: json['version'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        errorMessage: json['errorMessage'] as String?,
        retryCount: json['retryCount'] as int? ?? 0,
      );
}
