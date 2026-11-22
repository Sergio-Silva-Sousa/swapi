import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  SessionStore(this._storage);

  static const _activeUserIdKey = 'active_user_id';

  final FlutterSecureStorage _storage;

  Future<int?> readActiveUserId() async {
    final value = await _storage.read(key: _activeUserIdKey);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> writeActiveUserId(int userId) {
    return _storage.write(key: _activeUserIdKey, value: '$userId');
  }

  Future<void> clear() => _storage.delete(key: _activeUserIdKey);
}
