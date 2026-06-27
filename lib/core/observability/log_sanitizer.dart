/// Removes personally identifiable and sensitive information from any text
/// before it reaches logs, breadcrumbs, analytics, or crash reports.
///
/// This is the single chokepoint for crash-data sanitization. All observability
/// sinks must pass user-derived strings through [LogSanitizer.scrub].
class LogSanitizer {
  const LogSanitizer();

  static final _email = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  );

  // Bearer / access tokens, Supabase keys, OpenAI keys, JWT-like blobs.
  static final _token = RegExp(
    r'(sk-[A-Za-z0-9]{8,})|(eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{4,})|(Bearer\s+[A-Za-z0-9._\-]{8,})',
  );

  // Long digit runs: phone numbers, plate-ish numbers, card-like sequences.
  static final _longDigits = RegExp(r'\b\d{7,}\b');

  // Decimal GPS coordinates (lat,lng) — protect exact location history.
  static final _coordinate = RegExp(
    r'-?\d{1,3}\.\d{4,},\s*-?\d{1,3}\.\d{4,}',
  );

  /// Keys whose values must always be redacted regardless of content.
  static const sensitiveKeys = {
    'password',
    'token',
    'access_token',
    'refresh_token',
    'api_key',
    'apikey',
    'authorization',
    'medical',
    'blood_type',
    'allergies',
    'conditions',
    'medications',
    'email',
    'phone',
  };

  String scrub(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(_token, '[redacted-token]')
        .replaceAll(_coordinate, '[redacted-coords]')
        .replaceAll(_email, '[redacted-email]')
        .replaceAll(_longDigits, '[redacted-number]');
  }

  /// Sanitizes a structured map, redacting sensitive keys and scrubbing values.
  Map<String, String> scrubMap(Map<String, String> input) {
    final result = <String, String>{};
    input.forEach((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        result[key] = '[redacted]';
      } else {
        result[key] = scrub(value);
      }
    });
    return result;
  }
}
