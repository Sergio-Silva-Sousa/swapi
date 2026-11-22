import 'package:flutter_test/flutter_test.dart';
import 'package:swapo/features/films/data/film.dart';

void main() {
  test('parses a SWAPI film including empty relation lists', () {
    final film = Film.fromJson({
      'title': 'A New Hope',
      'episode_id': 4,
      'opening_crawl': 'A long time ago',
      'director': 'George Lucas',
      'release_date': '1977-05-25',
      'characters': <String>[],
      'planets': <String>[],
      'url': 'https://swapi.dev/api/films/1/',
    });

    expect(film.id, 1);
    expect(film.releaseDate.year, 1977);
    expect(film.characterUrls, isEmpty);
  });
}
