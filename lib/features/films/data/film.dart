import '../../../core/api/swapi_url_parser.dart';

class Film {
  const Film({
    required this.id,
    required this.title,
    required this.episodeId,
    required this.openingCrawl,
    required this.director,
    required this.releaseDate,
    required this.characterUrls,
    required this.planetUrls,
  });

  final int id;
  final String title;
  final int episodeId;
  final String openingCrawl;
  final String director;
  final DateTime releaseDate;
  final List<String> characterUrls;
  final List<String> planetUrls;

  factory Film.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    return Film(
      id: SwapiUrlParser.extractId(url),
      title: json['title'] as String,
      episodeId: json['episode_id'] as int,
      openingCrawl: json['opening_crawl'] as String,
      director: json['director'] as String,
      releaseDate: DateTime.parse(json['release_date'] as String),
      characterUrls: List<String>.from(json['characters'] as List),
      planetUrls: List<String>.from(json['planets'] as List),
    );
  }
}
