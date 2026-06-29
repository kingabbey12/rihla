import 'package:url_launcher/url_launcher.dart';

/// Opens the device dialer with [number] (UAE emergency numbers, etc.).
abstract final class PhoneLauncher {
  static Future<bool> dial(String number) async {
    final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
