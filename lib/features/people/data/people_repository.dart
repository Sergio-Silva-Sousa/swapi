import '../../../core/api/api_client.dart';
import '../../../core/cache/ttl.dart';
import 'person.dart';
class PeoplePage { const PeoplePage({required this.people, required this.hasNext, required this.isStale}); final List<Person> people; final bool hasNext; final bool isStale; }
class PeopleRepository { PeopleRepository(this._client); final ApiClient _client;
  Future<PeoplePage> page({int page = 1, String query = ''}) async { final uri = Uri.https('swapi.dev', '/api/people/', {if (page > 1) 'page': '$page', if (query.isNotEmpty) 'search': query}); final response = await _client.getJson(uri, ttl: CacheTtl.lists); final results = response.body['results'] as List; return PeoplePage(people: results.map((x) => Person.fromJson(Map<String, dynamic>.from(x as Map))).toList(), hasNext: response.body['next'] != null, isStale: response.isStale); }
}
