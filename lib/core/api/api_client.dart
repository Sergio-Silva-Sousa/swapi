import 'dart:async';

import 'package:dio/dio.dart';

import '../cache/api_cache_store.dart';
import '../network/network_status.dart';

/// The source of a JSON response returned by [ApiClient].
enum ApiResponseSource { cache, network, staleCache }

/// A cached JSON response together with the state the UI needs to represent it.
class ApiResponse {
  const ApiResponse({required this.body, required this.source});

  final Map<String, dynamic> body;
  final ApiResponseSource source;

  bool get isStale => source == ApiResponseSource.staleCache;
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
/// offline, and retries transient transport failures at most twice.
class ApiClient {
  ApiClient({
    required Dio dio,
    required ApiCacheStore cache,
    required NetworkStatus networkStatus,
    Duration timeout = const Duration(seconds: 10),
  })  : _dio = dio,
        _cache = cache,
        _networkStatus = networkStatus {
    _dio.options = _dio.options.copyWith(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
    );
  }

  final Dio _dio;
  final ApiCacheStore _cache;
  final NetworkStatus _networkStatus;

  Future<ApiResponse> getJson(
    Uri url, {
    required Duration ttl,
  }) async {
    final cached = await _cache.read(url.toString());
    if (cached != null && !cached.isExpired) {
      return ApiResponse(body: cached.body, source: ApiResponseSource.cache);
    }

    if (!await _networkStatus.isOnline()) {
      if (cached != null) {
        return ApiResponse(body: cached.body, source: ApiResponseSource.staleCache);
      }
      throw OfflineCacheMissException(url);
    }

    try {
      final response = await _getWithRetry(url);
      final body = _asJsonObject(response.data, url);
      await _cache.write(url: url.toString(), body: body, ttl: ttl);
      return ApiResponse(body: body, source: ApiResponseSource.network);
    } on DioException {
      // A connection can disappear after the online check. Preserve the
      // offline-first contract when a previously fetched value is available.
      if (cached != null) {
        return ApiResponse(body: cached.body, source: ApiResponseSource.staleCache);
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _getWithRetry(Uri url) async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
    ];

    for (var attempt = 0; ; attempt++) {
      try {
        return await _dio.getUri<dynamic>(url);
      } on DioException {
        if (attempt >= retryDelays.length) rethrow;
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
  }

  Map<String, dynamic> _asJsonObject(Object? data, Uri url) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return <String, dynamic>{'_items': data};
    throw FormatException('Expected a JSON object from $url.');
  }
}
