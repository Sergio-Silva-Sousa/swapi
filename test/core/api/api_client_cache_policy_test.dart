import 'dart:typed_data';

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

    test('returns a fresh miss without touching the network', () async {
      final cache = _FakeCacheStore(
        CachedJson(
          body: const <String, dynamic>{},
          fetchedAt: DateTime.now().toUtc(),
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          isMiss: true,
        ),
      );
      final client = _client(cache: cache, isOnline: false);

      final response = await client.getJson(Uri.parse(url), ttl: Duration.zero);

      expect(response.source, ApiResponseSource.miss);
      expect(response.isMiss, isTrue);
      expect(response.body, isEmpty);
      expect(cache.writeCalls, isZero);
    });

    test('caches a 404 as a short-lived miss', () async {
      final cache = _FakeCacheStore(null);
      final client = _client(
        cache: cache,
        adapter: _StatusAdapter(404),
      );

      final response = await client.getJson(
        Uri.parse(url),
        ttl: const Duration(days: 7),
      );

      expect(response.isMiss, isTrue);
      expect(cache.missWrites, 1);
      expect(cache.value?.expiresAt.difference(cache.value!.fetchedAt),
          const Duration(hours: 1));
    });

    test('retries transient failures twice but not deterministic 4xx', () async {
      final transientAdapter = _StatusAdapter(500);
      final transientClient = _client(
        cache: _FakeCacheStore(null),
        adapter: transientAdapter,
      );
      await expectLater(
        transientClient.getJson(Uri.parse(url), ttl: Duration.zero),
        throwsA(isA<DioException>()),
      );
      expect(transientAdapter.calls, 3);

      final deterministicAdapter = _StatusAdapter(400);
      final deterministicClient = _client(
        cache: _FakeCacheStore(null),
        adapter: deterministicAdapter,
      );
      await expectLater(
        deterministicClient.getJson(Uri.parse(url), ttl: Duration.zero),
        throwsA(isA<DioException>()),
      );
      expect(deterministicAdapter.calls, 1);
    });
  });
}

ApiClient _client({
  required ApiCacheStore cache,
  bool isOnline = true,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio();
  if (adapter != null) dio.httpClientAdapter = adapter;
  return ApiClient(
    dio: dio,
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
  var missWrites = 0;

  CachedJson? get value => _value;

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

  @override
  Future<void> writeMiss({required String url, required Duration ttl}) async {
    missWrites++;
    final fetchedAt = DateTime.now().toUtc();
    _value = CachedJson(
      body: const <String, dynamic>{},
      fetchedAt: fetchedAt,
      expiresAt: fetchedAt.add(ttl),
      isMiss: true,
    );
  }
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;
  var calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      '',
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
