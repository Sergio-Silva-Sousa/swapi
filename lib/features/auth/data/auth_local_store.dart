import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/drift_executor_opener.dart';
import 'auth_user.dart';

class StoredUser extends AuthUser {
  const StoredUser({
    required super.id,
    required super.name,
    required super.email,
    required this.passwordHash,
    required this.passwordSalt,
  });

  final String passwordHash;
  final String passwordSalt;
}

/// Drift storage for local application accounts.
class AuthLocalStore {
  AuthLocalStore(this._executor);

  final QueryExecutor _executor;
  var _initialized = false;

  static Future<AuthLocalStore> open() async {
    final directory = await getApplicationSupportDirectory();
    final database = File('${directory.path}${Platform.pathSeparator}swapo.sqlite');
    final store = AuthLocalStore(NativeDatabase(database));
    await store.initialize();
    return store;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await ensureDriftExecutorOpen(_executor);
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL
      )
    ''');
    _initialized = true;
  }

  Future<StoredUser?> findByEmail(String email) async {
    await initialize();
    final rows = await _executor.runSelect(
      '''SELECT id, name, email, password_hash, password_salt
         FROM users WHERE email = ?''',
      <Object?>[email],
    );
    return rows.isEmpty ? null : _storedUserFromRow(rows.single);
  }

  Future<AuthUser?> findById(int id) async {
    await initialize();
    final rows = await _executor.runSelect(
      'SELECT id, name, email FROM users WHERE id = ?',
      <Object?>[id],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return AuthUser(
      id: row['id']! as int,
      name: row['name']! as String,
      email: row['email']! as String,
    );
  }

  Future<AuthUser> insert({
    required String name,
    required String email,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    await initialize();
    final id = await _executor.runInsert(
      '''INSERT INTO users(name, email, password_hash, password_salt)
         VALUES (?, ?, ?, ?)''',
      <Object?>[name, email, passwordHash, passwordSalt],
    );
    return AuthUser(id: id, name: name, email: email);
  }

  Future<void> close() => _executor.close();

  StoredUser _storedUserFromRow(Map<String, Object?> row) {
    return StoredUser(
      id: row['id']! as int,
      name: row['name']! as String,
      email: row['email']! as String,
      passwordHash: row['password_hash']! as String,
      passwordSalt: row['password_salt']! as String,
    );
  }
}
