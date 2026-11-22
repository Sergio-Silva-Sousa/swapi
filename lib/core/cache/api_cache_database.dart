import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'api_cache_store.dart';

/// Opens the SQLite database that owns the API response cache.
abstract final class ApiCacheDatabase {
  static Future<DriftApiCacheStore> open() async {
    final directory = await getApplicationSupportDirectory();
    final databaseFile = File(
      '${directory.path}${Platform.pathSeparator}swapo.sqlite',
    );
    final cache = DriftApiCacheStore(
      NativeDatabase.createInBackground(databaseFile),
    );
    await cache.initialize();
    return cache;
  }
}
