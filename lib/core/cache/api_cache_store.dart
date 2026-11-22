import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/drift_executor_opener.dart';

/// The sentinel used in the JSON body to mark a known missing resource.
const String _missSentinel = '__swapo_miss__';

/// A cache row exposed independently from its persistence mechanism.
class CachedJson {
  const CachedJson({
    required this.body,
    required this.fetchedAt,
    required this.expiresAt,
    this.isMiss = false,
  });

  final Map<String, dynamic> body;
  final DateTime fetchedAt;
  final DateTime expiresAt;

  /// True when the stored value is a negative lookup (404 or empty result).
  final bool isMiss;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());
}

abstract interface class ApiCacheStore {
  Future<CachedJson?> read(String url);

  Future<void> write({
    required String url,
    required Map<String, dynamic> body,
    required Duration ttl,
  });

  /// Stores a short-lived negative lookup so the same miss is not repeated.
  Future<void> writeMiss({required String url, required Duration ttl});
}

/// Drift-backed implementation of the `api_cache` table.
///
/// A [QueryExecutor] lets application bootstrap choose the appropriate SQLite
/// database for each platform while keeping cache access testable.
class DriftApiCacheStore implements ApiCacheStore {
  DriftApiCacheStore(this._executor);

  final QueryExecutor _executor;
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await ensureDriftExecutorOpen(_executor);
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS api_cache (
        url TEXT PRIMARY KEY NOT NULL,
        body TEXT NOT NULL,
        fetched_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');
    _initialized = true;
  }

  @override
  Future<CachedJson?> read(String url) async {
    await initialize();
    final rows = await _executor.runSelect(
      'SELECT body, fetched_at, expires_at FROM api_cache WHERE url = ?',
      <Object?>[url],
    );
    if (rows.isEmpty) return null;

    final row = rows.single;
    final body = jsonDecode(row['body']! as String);
    if (body is! Map) {
      throw FormatException('Cached response for $url is not a JSON object.');
    }
    final decoded = Map<String, dynamic>.from(body);
    final isMiss = decoded[_missSentinel] == true;
    if (isMiss) decoded.clear();
    return CachedJson(
      body: decoded,
      fetchedAt: _dateFromMillis(row['fetched_at']),
      expiresAt: _dateFromMillis(row['expires_at']),
      isMiss: isMiss,
    );
  }

  @override
  Future<void> write({
    required String url,
    required Map<String, dynamic> body,
    required Duration ttl,
  }) {
    return _write(
      url: url,
      body: jsonEncode(body),
      ttl: ttl,
    );
  }

  @override
  Future<void> writeMiss({required String url, required Duration ttl}) {
    return _write(
      url: url,
      body: jsonEncode(<String, dynamic>{_missSentinel: true}),
      ttl: ttl,
    );
  }

  Future<void> _write({
    required String url,
    required String body,
    required Duration ttl,
  }) async {
    await initialize();
    final fetchedAt = DateTime.now().toUtc();
    final expiresAt = fetchedAt.add(ttl);
    await _executor.runUpdate(
      '''INSERT INTO api_cache(url, body, fetched_at, expires_at)
         VALUES (?, ?, ?, ?)
         ON CONFLICT(url) DO UPDATE SET
           body = excluded.body,
           fetched_at = excluded.fetched_at,
           expires_at = excluded.expires_at''',
      <Object?>[
        url,
        body,
        fetchedAt.millisecondsSinceEpoch,
        expiresAt.millisecondsSinceEpoch,
      ],
    );
  }

  DateTime _dateFromMillis(Object? value) {
    if (value is! int) throw FormatException('Invalid cache timestamp: $value');
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
}
