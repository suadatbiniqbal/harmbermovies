import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateService {
  static const _releasesUrl =
      'https://api.github.com/repos/suadatbiniqbal/harmbermovies/releases/latest';
  static const currentVersion = '1.0.0';

  /// Returns release info map or null if no update / error
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_releasesUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName =
            (data['tag_name'] as String?)?.replaceAll('v', '') ?? '';
        if (tagName.isNotEmpty && tagName != currentVersion) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get download URL for APK from latest release
  static String? getApkUrl(Map<String, dynamic> release) {
    final assets = release['assets'] as List? ?? [];
    for (final asset in assets) {
      final name = (asset['name'] as String?) ?? '';
      if (name.endsWith('.apk')) {
        return asset['browser_download_url'] as String?;
      }
    }
    // Fallback to the release page
    return release['html_url'] as String?;
  }
}
