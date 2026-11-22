import 'dart:async';

import 'package:dio/dio.dart';

import '../cache/api_cache_store.dart';
import '../cache/ttl.dart';
import '../network/network_status.dart';

/// The source of a JSON response returned by [ApiClient].
enum ApiResponseSource { cache, network, staleCache, miss }

/// A cached JSON response together with the state the UI needs to represent it.
class ApiResponse {
  const ApiResponse({required this.body, required this.source});

  final Map<String, dynamic> body;
  final ApiResponseSource source;

  bool get isStale => source == ApiResponseSource.staleCache;
  bool get isMiss => source == ApiResponseSource.miss;
}

/// Thrown when a request cannot be made and no locally cached response exists.
class OfflineCacheMissException implements Exception {
  const OfflineCacheMissException(this.url);

  final Uri url;

  @override
  String toString() => 'No cached response available while offline: $url';
}

/// Central access point for remote JSON APIs.
///
/// It returns fresh cache immediately, keeps expired records available while
/// offline, retries transient transport failures at most twice, and caches
/// negative lookups (404) with a short TTL.
class ApiClient {
  ApiClient({
    required Dio dio,
    required ApiCacheStore cache,
    required NetworkStatus networkStatus,
    Duration timeout = const Duration(seconds: 10),
  })  : _dio = dio,
        _cache = cache,
        _networkStatus = networkStatus,
        _defaultTimeout = timeout {
    _dio.options = _dio.options.copyWith(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
    );
  }

  final Dio _dio;
  final ApiCacheStore _cache;
  final NetworkStatus _networkStatus;
  final Duration _defaultTimeout;

  Future<ApiResponse> getJson(
    Uri url, {
    required Duration ttl,
    Duration? timeout,
    Duration? missTtl,
  }) async {
    final cached = await _cache.read(url.toString());
    if (cached != null && !cached.isExpired) {
      return cached.isMiss
          ? const ApiResponse(body: <String, dynamic>{}, source: ApiResponseSource.miss)
          : ApiResponse(body: cached.body, source: ApiResponseSource.cache);
    }

    if (!await _networkStatus.isOnline()) {
      if (cached != null) {
        return _cachedResponse(cached);
      }
      throw OfflineCacheMissException(url);
    }

    try {
      final response = await _getWithRetry(url, timeout: timeout);
      final body = _asJsonObject(response.data, url);
      await _cache.write(url: url.toString(), body: body, ttl: ttl);
      return ApiResponse(body: body, source: ApiResponseSource.network);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        await recordMiss(url, ttl: missTtl ?? CacheTtl.missingImage);
        return const ApiResponse(body: <String, dynamic>{}, source: ApiResponseSource.miss);
      }
      // A connection can disappear after the online check. Preserve the
      // offline-first contract when a previously fetched value is available.
      if (cached != null) {
        return _cachedResponse(cached);
      }
      rethrow;
    }
  }

  /// Records a negative lookup returned as an empty list by an API.
  Future<void> recordMiss(Uri url, {Duration ttl = CacheTtl.missingImage}) {
    return _cache.writeMiss(url: url.toString(), ttl: ttl);
  }

  ApiResponse _cachedResponse(CachedJson cached) {
    return cached.isMiss
        ? const ApiResponse(body: <String, dynamic>{}, source: ApiResponseSource.miss)
        : ApiResponse(body: cached.body, source: ApiResponseSource.staleCache);
  }

  Future<Response<dynamic>> _getWithRetry(
    Uri url, {
    Duration? timeout,
  }) async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
    ];
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final options = Options(
      connectTimeout: effectiveTimeout,
      sendTimeout: effectiveTimeout,
      receiveTimeout: effectiveTimeout,
    );

    for (var attempt = 0; ; attempt++) {
      try {
        return await _dio.getUri<dynamic>(url, options: options);
      } on DioException catch (error) {
        if (attempt >= retryDelays.length || !_isTransient(error)) rethrow;
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
  }

  /// 4xx responses (except 429) are deterministic: retrying them only wastes
  /// requests. Transport failures and 5xx/429 are worth a second attempt.
  static bool _isTransient(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return true;
    return statusCode == 429 || statusCode >= 500;
  }

  Map<String, dynamic> _asJsonObject(Object? data, Uri url) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return <String, dynamic>{'_items': data};
    throw FormatException('Expected a JSON object from $url.');
  }
}
