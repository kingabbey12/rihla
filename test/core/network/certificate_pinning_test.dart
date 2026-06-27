import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/network/certificate_pinning.dart';

void main() {
  group('CertificatePinning', () {
    final der = Uint8List.fromList(List.generate(64, (i) => i));
    final fingerprint = base64.encode(sha256.convert(der).bytes);

    test('fingerprintOfDer is stable base64 SHA-256', () {
      expect(CertificatePinning.fingerprintOfDer(der), fingerprint);
    });

    test('matchesPin returns true when no pins configured', () {
      expect(CertificatePinning.matchesPin(der, const []), isTrue);
    });

    test('matchesPin matches the correct pin', () {
      expect(CertificatePinning.matchesPin(der, [fingerprint]), isTrue);
    });

    test('matchesPin rejects an unknown certificate', () {
      expect(
        CertificatePinning.matchesPin(der, const ['not-a-real-pin']),
        isFalse,
      );
    });

    test('buildClient returns a usable client without pins', () {
      final client = const CertificatePinning().buildClient();
      expect(client, isNotNull);
      client.close();
    });

    test('buildClient returns a pinned client when pins provided', () {
      final client =
          const CertificatePinning().buildClient(pins: [fingerprint]);
      expect(client, isNotNull);
      client.close();
    });
  });
}
