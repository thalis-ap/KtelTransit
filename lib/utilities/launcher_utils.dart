import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherUtils {
  static Future<void> launchPhone(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch phone app for $phoneNumber');
    }
  }

  static Future<void> launchEmail(String email) async {
    final Uri url = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch email app for $email');
    }
  }

  static Future<void> launchWebSite(String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch website $urlString');
    }
  }
}