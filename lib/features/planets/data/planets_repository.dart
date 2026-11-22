import '../../../core/api/api_client.dart';
import '../../../core/cache/ttl.dart';
import 'planet.dart';

class PlanetsPage {
  const PlanetsPage({
    required this.items,
    required this.hasNext,
    required this.isStale,
  });

  final List<Planet> items;
  final bool hasNext;
  final bool isStale;
}

class PlanetsRepository {
  PlanetsRepository(this._client);

  final ApiClient _client;

  Future<PlanetsPage> list({String search = '', int page = 1}) async {
    final response = await _client.getJson(
      Uri.https(
        'swapi.dev',
        '/api/planets/',
        <String, String>{
          if (search.isNotEmpty) 'search': search,
          if (page > 1) 'page': '$page',
        },
      ),
      ttl: CacheTtl.lists,
    );
    final results = response.body['results'] as List;
    return PlanetsPage(
      items: results
          .map((item) => Planet.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      hasNext: response.body['next'] != null,
      isStale: response.isStale,
    );
  }
}
