import 'package:flutter_test/flutter_test.dart';
import 'package:swapo/core/api/swapi_url_parser.dart';

void main() {
  group('SwapiUrlParser.extractId', () {
    test('extracts an id from a canonical SWAPI URL', () {
      expect(
        SwapiUrlParser.extractId('https://swapi.dev/api/people/1/'),
        1,
      );
    });

    test('accepts a URL without a trailing slash', () {
      expect(
        SwapiUrlParser.extractId('https://swapi.dev/api/planets/42'),
        42,
      );
    });

    test('rejects a URL without a numeric resource id', () {
      expect(
        () => SwapiUrlParser.extractId('https://swapi.dev/api/people/'),
        throwsFormatException,
      );
    });
  });
}
