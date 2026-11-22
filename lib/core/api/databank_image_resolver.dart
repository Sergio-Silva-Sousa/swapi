import 'package:dio/dio.dart';

import '../cache/ttl.dart';
import 'api_client.dart';

/// Resolves Databank images, trying the required person endpoint order.
class DatabankImageResolver {
  DatabankImageResolver(this._client);
  final ApiClient _client;
  static const _base = 'https://starwars-databank-server.onrender.com/api/v1';

  Future<String?> personImage(String name) => _resolve(name, const ['characters', 'creatures', 'droids']);
  Future<String?> planetImage(String name) => _resolve(name, const ['locations']);

  Future<String?> _resolve(String name, List<String> endpoints) async {
    for (final endpoint in endpoints) {
      final uri = Uri.parse('$_base/$endpoint/name/${Uri.encodeComponent(name)}');
      try {
        final body = (await _client.getJson(uri, ttl: CacheTtl.resolvedImages)).body;
        final image = _findImage(body);
        if (image != null) return image;
      } on DioException catch (error) {
        if (error.response?.statusCode != 404) continue;
      }
    }
    return null;
  }

  String? _findImage(Map<String, dynamic> body) {
    final items = body['_items'];
    final firstItem = items is List && items.isNotEmpty ? items.first : null;
    final candidates = <Object?>[
      if (firstItem is Map) firstItem['image'],
      body['image'], body['imageUrl'], body['image_url'],
      if (body['data'] is Map) (body['data'] as Map)['image'],
      if (body['data'] is Map) (body['data'] as Map)['imageUrl'],
    ];
    for (final value in candidates) {
      if (value is String && value.startsWith('http')) return value;
    }
    return null;
  }
}
