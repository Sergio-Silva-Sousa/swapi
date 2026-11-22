import '../../../core/api/api_client.dart';
import '../../../core/cache/ttl.dart';
import 'film.dart';

class FilmsResult {
  const FilmsResult({required this.films, required this.isStale});

  final List<Film> films;
  final bool isStale;
}

class FilmsRepository {
  FilmsRepository(this._client);

  static final _filmsUri = Uri.parse('https://swapi.dev/api/films/');
  final ApiClient _client;

  Future<FilmsResult> list() async {
    final response = await _client.getJson(_filmsUri, ttl: CacheTtl.lists);
    final results = response.body['results'];
    if (results is! List) throw const FormatException('SWAPI films has no results list.');
    final films = results
        .map((item) => Film.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList()
      ..sort((first, second) => first.episodeId.compareTo(second.episodeId));
    return FilmsResult(films: films, isStale: response.isStale);
  }
}
