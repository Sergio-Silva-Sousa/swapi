/// Centralized cache lifetimes.
abstract final class CacheTtl {
  static const lists = Duration(hours: 24);
  static const details = Duration(days: 7);
  static const resolvedImages = Duration(days: 30);
  static const missingImage = Duration(hours: 1);
}
