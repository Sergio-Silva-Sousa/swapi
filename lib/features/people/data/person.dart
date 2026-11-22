import '../../../core/api/swapi_url_parser.dart';

class Person {
  const Person({required this.id, required this.name, required this.gender, required this.birthYear, required this.homeworldUrl, required this.filmUrls, required this.speciesUrls});
  final int id; final String name; final String gender; final String birthYear; final String homeworldUrl; final List<String> filmUrls; final List<String> speciesUrls;
  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: SwapiUrlParser.extractId(json['url'] as String), name: json['name'] as String,
    gender: json['gender'] as String? ?? 'unknown', birthYear: json['birth_year'] as String? ?? 'unknown',
    homeworldUrl: json['homeworld'] as String? ?? '', filmUrls: List<String>.from(json['films'] as List? ?? const []), speciesUrls: List<String>.from(json['species'] as List? ?? const []),
  );
}
