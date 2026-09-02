import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static VersionService? _instance;
  static VersionService get instance => _instance ??= VersionService._();

  static const String _unknowVersionName = "Unknown";

  VersionService._();

  String? _version;
  String? _buildNumber;

  bool get isLoaded => _version != null;

  Future<void> loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    _version = info.version;
    _buildNumber = info.buildNumber;
  }

  String get fullVersion {
    if (_version == null) return _unknowVersionName;
    if (_buildNumber != null && _buildNumber!.isNotEmpty) {
      return '$_version ($_buildNumber)';
    }
    return _version!;
  }

  String get version => _version ?? _unknowVersionName;
}