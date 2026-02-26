import '../platform/native_bridge.dart';

class AppResolverService {
  List<Map<String, String>> _installedApps = [];
  DateTime? _lastRefresh;

  static const _aliasMap = {
    'insta': 'instagram',
    'ig': 'instagram',
    'yt': 'youtube',
    'wp': 'whatsapp',
    'fb': 'facebook',
    'tg': 'telegram',
    'gm': 'gmail',
    'chrome': 'chrome',
    'maps': 'maps',
    'spotify': 'spotify',
    'twitter': 'twitter',
    'x': 'twitter',
    'snap': 'snapchat',
    'tiktok': 'tiktok',
    'reddit': 'reddit',
    'discord': 'discord',
    'slack': 'slack',
    'zoom': 'zoom',
    'teams': 'teams',
    'outlook': 'outlook',
    'netflix': 'netflix',
    'amazon': 'amazon',
    'uber': 'uber',
    'lyft': 'lyft',
    'camera': 'camera',
    'gallery': 'gallery',
    'photos': 'photos',
    'settings': 'settings',
    'calculator': 'calculator',
    'calendar': 'calendar',
    'clock': 'clock',
    'notes': 'notes',
    'files': 'files',
    'phone': 'phone',
    'contacts': 'contacts',
    'messages': 'messages',
  };

  Future<void> refresh() async {
    _installedApps = await NativeBridge.getInstalledApps();
    _lastRefresh = DateTime.now();
  }

  bool get needsRefresh {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!).inMinutes > 5;
  }

  Future<void> ensureInitialized() async {
    if (needsRefresh) {
      await refresh();
    }
  }

  List<Map<String, String>> get installedApps => _installedApps;

  String get appNamesForPrompt {
    return _installedApps.map((app) => app['name'] ?? '').join(', ');
  }

  String? resolveAppName(String spokenName) {
    final lower = spokenName.toLowerCase().trim();

    // Check alias map first
    final aliasTarget = _aliasMap[lower];
    if (aliasTarget != null) {
      return _findPackageByName(aliasTarget);
    }

    // Direct match
    return _findPackageByName(lower);
  }

  String? _findPackageByName(String searchName) {
    final lower = searchName.toLowerCase();

    // Exact match on name
    for (final app in _installedApps) {
      final name = (app['name'] ?? '').toLowerCase();
      if (name == lower) {
        return app['packageName'];
      }
    }

    // Name starts with search
    for (final app in _installedApps) {
      final name = (app['name'] ?? '').toLowerCase();
      if (name.startsWith(lower)) {
        return app['packageName'];
      }
    }

    // Name contains search
    for (final app in _installedApps) {
      final name = (app['name'] ?? '').toLowerCase();
      if (name.contains(lower)) {
        return app['packageName'];
      }
    }

    // Package name contains search
    for (final app in _installedApps) {
      final packageName = (app['packageName'] ?? '').toLowerCase();
      if (packageName.contains(lower)) {
        return app['packageName'];
      }
    }

    return null;
  }
}
