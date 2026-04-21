import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateService {
  static const _releasesUrl =
      'https://api.github.com/repos/suadatbiniqbal/harmbermovies/releases/latest';
  static const currentVersion = '1.0.4';

  static bool _isNewer(String remote, String current) {
    final r = remote.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

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
        if (tagName.isNotEmpty && _isNewer(tagName, currentVersion)) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  static String? getApkUrl(Map<String, dynamic> release) {
    final assets = release['assets'] as List? ?? [];
    for (final asset in assets) {
      final name = (asset['name'] as String?) ?? '';
      if (name.endsWith('.apk')) {
        return asset['browser_download_url'] as String?;
      }
    }
    return release['html_url'] as String?;
  }
}
