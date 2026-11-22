/// Allows the API layer to apply its offline-first policy without depending on
/// a particular connectivity plugin.
abstract interface class NetworkStatus {
  Future<bool> isOnline();
}
