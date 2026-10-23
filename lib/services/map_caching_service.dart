import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class MapCachingService {
  static const String cacheKey = "osmcache";

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore(cacheKey).manage.create();
  }
}