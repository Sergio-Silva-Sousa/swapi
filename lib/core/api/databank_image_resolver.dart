import 'package:dio/dio.dart';

import '../cache/ttl.dart';
import 'api_client.dart';

/// Resolves Databank images, trying the required person endpoint order.
class DatabankImageResolver {
  DatabankImageResolver(this._client);

  static const _base = 'https://starwars-databank-server.onrender.com/api/v1';

  /// The Render free tier can take ~18 s to wake up (see docs/apis.md).
  static const _timeout = Duration(seconds: 45);

  final ApiClient _client;
  final Map<String, String> _workingEndpoint = <String, String>{};
  final Map<String, String?> _memo = <String, String?>{};

  Future<String?> personImage(String name) => _resolve(
        'person:$name',
        name,
        const ['characters', 'creatures', 'droids'],
      );

  Future<String?> planetImage(String name) => _resolve(
        'planet:$name',
        name,
        const ['locations'],
      );

  Future<String?> _resolve(
    String key,
    String name,
    List<String> endpoints,
  ) async {
    if (_memo.containsKey(key)) return _memo[key];

    final preferred = _workingEndpoint[key];
    final ordered = preferred == null
        ? endpoints
        : <String>[
            preferred,
            ...endpoints.where((endpoint) => endpoint != preferred),
          ];

    for (final endpoint in ordered) {
      final uri = Uri.parse(
        '$_base/$endpoint/name/${Uri.encodeComponent(name)}',
      );
      try {
        final response = await _client.getJson(
          uri,
          ttl: CacheTtl.resolvedImages,
          timeout: _timeout,
        );
        if (response.isMiss) continue;

        final image = _findImage(response.body);
        if (image != null) {
          _workingEndpoint[key] = endpoint;
          return _memo[key] = image;
        }
        // An empty list is a negative lookup: cache it briefly so scrolling
        // does not repeat the same request on every rebuild.
        await _client.recordMiss(uri);
      } on DioException {
        // Images are optional; try the next endpoint without caching failures.
      }
    }
    return _memo[key] = null;
  }

  String? _findImage(Map<String, dynamic> body) {
    final items = body['_items'];
    final firstItem = items is List && items.isNotEmpty ? items.first : null;
    final candidates = <Object?>[
      if (firstItem is Map) firstItem['image'],
      body['image'],
      body['imageUrl'],
      body['image_url'],
      if (body['data'] is Map) (body['data'] as Map)['image'],
      if (body['data'] is Map) (body['data'] as Map)['imageUrl'],
    ];
    for (final value in candidates) {
      if (value is String && value.startsWith('http')) return value;
    }
    return null;
  }
}
