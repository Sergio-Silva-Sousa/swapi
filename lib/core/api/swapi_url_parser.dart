/// Utilities for canonical URLs returned by SWAPI relation fields.
abstract final class SwapiUrlParser {
  /// Extracts the final numeric resource identifier from a SWAPI URL.
  ///
  /// Example: `https://swapi.dev/api/people/1/` becomes `1`.
  static int extractId(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      throw FormatException('Invalid SWAPI URL: $value');
    }

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    final id = segments.isEmpty ? null : segments.last;
    final parsedId = id == null ? null : int.tryParse(id);
    if (parsedId == null || parsedId < 1) {
      throw FormatException('SWAPI URL has no positive numeric identifier: $value');
    }
    return parsedId;
  }
}
