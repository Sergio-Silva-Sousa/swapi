import '../cache/ttl.dart';
import 'api_client.dart';

/// Resolves film posters from the IMDb suggestion endpoint.
class ImdbImageResolver {
  ImdbImageResolver(this._client);

  final ApiClient _client;
  final Map<String, String?> _memo = <String, String?>{};

  Future<String?> imageFor({required String title, required int year}) async {
    final key = '$title:$year';
    if (_memo.containsKey(key)) return _memo[key];
    if (title.isEmpty) return _memo[key] = null;

    final slug = title.toLowerCase();
    // Uri.https encodes the spaces; encoding the component first would double
    // encode them ('%2520').
    final uri = Uri.https(
      'v2.sg.media-imdb.com',
      '/suggestion/${slug[0]}/$slug.json',
    );

    try {
      final response = await _client.getJson(uri, ttl: CacheTtl.resolvedImages);
      if (response.isMiss) return _memo[key] = null;

      final results = response.body['d'];
      if (results is! List) {
        await _client.recordMiss(uri);
        return _memo[key] = null;
      }

      final wanted = _normalize(title);
      final matches = <(int rank, String url)>[];
      for (final item in results) {
        if (item is! Map || item['qid'] != 'movie') continue;
        final label = item['l'];
        final itemYear = item['y'];
        if (label is! String ||
            itemYear == null ||
            !_normalize(label).contains(wanted) ||
            int.tryParse('$itemYear') != year) {
          continue;
        }
        final image = item['i'];
        if (image is Map && image['imageUrl'] is String) {
          matches.add((
            item['q'] == 'feature' ? 0 : 1,
            image['imageUrl'] as String,
          ));
        }
      }
      matches.sort((first, second) => first.$1.compareTo(second.$1));
      final imageUrl = matches.isEmpty ? null : matches.first.$2;
      if (imageUrl == null) await _client.recordMiss(uri);
      return _memo[key] = imageUrl;
    } catch (_) {
      // Images are optional; transport errors are not memoized as misses.
      return null;
    }
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}
