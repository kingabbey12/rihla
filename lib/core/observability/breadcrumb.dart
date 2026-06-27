/// Severity of a logged breadcrumb / event.
enum ObservabilityLevel { debug, info, warning, error, fatal }

/// Domain that produced an observability signal.
enum ObservabilityCategory {
  app,
  navigation,
  ai,
  emergency,
  offline,
  cloud,
  network,
  uae,
}

/// A lightweight trail entry attached to crash reports for context.
class Breadcrumb {
  Breadcrumb({
    required this.message,
    this.category = ObservabilityCategory.app,
    this.level = ObservabilityLevel.info,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String message;
  final ObservabilityCategory category;
  final ObservabilityLevel level;
  final Map<String, String> data;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'message': message,
        'category': category.name,
        'level': level.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      '[${level.name}/${category.name}] $message ${data.isEmpty ? '' : data}';
}
