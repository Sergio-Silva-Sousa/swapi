import '../cache/ttl.dart';
import 'api_client.dart';

/// Resolves relation URLs only when a detail view asks for them.
class SwapiRelationResolver {
  SwapiRelationResolver(this._client);
  final ApiClient _client;

  Future<List<String>> resolveNames(List<String> urls) async {
    final output = List<String?>.filled(urls.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < urls.length) {
        final index = next++;
        final body = (await _client.getJson(Uri.parse(urls[index]), ttl: CacheTtl.details)).body;
        output[index] = (body['name'] ?? body['title'] ?? 'Desconhecido') as String;
      }
    }
    await Future.wait(List.generate(urls.length < 4 ? urls.length : 4, (_) => worker()));
    return output.cast<String>();
  }
}
