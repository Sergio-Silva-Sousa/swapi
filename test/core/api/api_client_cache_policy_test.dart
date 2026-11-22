import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swapo/core/api/api_client.dart';
import 'package:swapo/core/cache/api_cache_store.dart';
import 'package:swapo/core/network/network_status.dart';

void main() {
  const url = 'https://swapi.dev/api/people/1/';

  group('ApiClient cache policy', () {
    test('returns fresh cache without requiring network access', () async {
      final cache = _FakeCacheStore(
        CachedJson(
          body: const {'name': 'Luke Skywalker'},
          fetchedAt: DateTime.now().toUtc(),
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );
      final client = _client(cache: cache, isOnline: false);

      final response = await client.getJson(Uri.parse(url), ttl: Duration.zero);

      expect(response.body, {'name': 'Luke Skywalker'});
      expect(response.source, ApiResponseSource.cache);
      expect(response.isStale, isFalse);
      expect(cache.writeCalls, isZero);
    });

    test('returns expired cache marked stale while offline', () async {
      final cache = _FakeCacheStore(
        CachedJson(
          body: const {'name': 'Luke Skywalker'},
          fetchedAt: DateTime.utc(2020),
          expiresAt: DateTime.utc(2020, 1, 2),
        ),
      );
      final client = _client(cache: cache, isOnline: false);

      final response = await client.getJson(Uri.parse(url), ttl: Duration.zero);

      expect(response.source, ApiResponseSource.staleCache);
      expect(response.isStale, isTrue);
      expect(cache.writeCalls, isZero);
    });

    test('throws when offline without a cached response', () async {
      final client = _client(cache: _FakeCacheStore(null), isOnline: false);

      await expectLater(
        client.getJson(Uri.parse(url), ttl: Duration.zero),
        throwsA(isA<OfflineCacheMissException>()),
      );
    });
  });
}

ApiClient _client({required ApiCacheStore cache, required bool isOnline}) {
  return ApiClient(
    dio: Dio(),
    cache: cache,
    networkStatus: _FakeNetworkStatus(isOnline),
  );
}

class _FakeNetworkStatus implements NetworkStatus {
  const _FakeNetworkStatus(this._isOnline);

  final bool _isOnline;

  @override
  Future<bool> isOnline() async => _isOnline;
}

class _FakeCacheStore implements ApiCacheStore {
  _FakeCacheStore(this._value);

  CachedJson? _value;
  var writeCalls = 0;

  @override
  Future<CachedJson?> read(String url) async => _value;

  @override
  Future<void> write({
    required String url,
    required Map<String, dynamic> body,
    required Duration ttl,
  }) async {
    writeCalls++;
    final fetchedAt = DateTime.now().toUtc();
    _value = CachedJson(
      body: body,
      fetchedAt: fetchedAt,
      expiresAt: fetchedAt.add(ttl),
    );
  }
}
