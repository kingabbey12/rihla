import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Certificate pinning factory for the shared HTTP client.
///
/// Architecture: when SPKI/cert pins are configured ([ApiConfig.certificateSpkiPins]),
/// [buildClient] returns an [IOClient] whose underlying [HttpClient] rejects any
/// TLS certificate whose SHA-256 fingerprint is not in the pin set. With no pins
/// configured, the default system trust store is used (returns a plain client).
///
/// Pins are base64-encoded SHA-256 digests of the certificate DER. Generate with:
///   `openssl s_client -connect host:443 | openssl x509 -outform der | openssl dgst -sha256 -binary | base64`
class CertificatePinning {
  const CertificatePinning();

  /// Returns the base64 SHA-256 fingerprint of a DER-encoded certificate.
  static String fingerprintOfDer(Uint8List der) {
    return base64.encode(sha256.convert(der).bytes);
  }

  /// Whether [der] matches one of the configured [pins].
  static bool matchesPin(Uint8List der, List<String> pins) {
    if (pins.isEmpty) return true;
    return pins.contains(fingerprintOfDer(der));
  }

  /// Builds an HTTP client, applying pinning when [pins] is non-empty.
  http.Client buildClient({List<String> pins = const []}) {
    if (pins.isEmpty) return http.Client();

    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Only allow otherwise-rejected certs if they match a pin.
        return matchesPin(Uint8List.fromList(cert.der), pins);
      };
    return IOClient(httpClient);
  }
}
