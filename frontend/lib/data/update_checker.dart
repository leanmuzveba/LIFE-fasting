import 'dart:convert';
import 'dart:io';

/// This build's number and where releases are published, both set by
/// tool/release.py (--dart-define). Empty/0 in development and tests.
const appBuild = int.fromEnvironment('BUILD_NUMBER');
const updateUrl = String.fromEnvironment('UPDATE_URL');
const appVersion = String.fromEnvironment('VERSION_NAME', defaultValue: 'dev');

class AppRelease {
  const AppRelease({required this.build, required this.apkUrl, this.version = '', this.notes = ''});
  final int build;
  final String version; // e.g. 1.2.002
  final String apkUrl;
  final String notes;
}

/// Reads `version.json` from the release page.
class UpdateChecker {
  /// The newest published release, or null when offline/unconfigured.
  Future<AppRelease?> latest() async {
    if (updateUrl.isEmpty) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse('$updateUrl/version.json'));
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      return AppRelease(
        build: j['build'] as int,
        apkUrl: '$updateUrl/${j['apk']}',
        version: (j['version'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
