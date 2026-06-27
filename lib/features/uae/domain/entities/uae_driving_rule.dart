/// Local UAE driving rule or reminder.
class UaeDrivingRule {
  const UaeDrivingRule({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.conditions = const [],
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> conditions;
}
