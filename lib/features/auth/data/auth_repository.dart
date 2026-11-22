import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_local_store.dart';
import 'auth_user.dart';
import 'password_hasher.dart';
import 'session_store.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Future<AuthUser?> restoreSession();
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required AuthLocalStore store,
    required SessionStore sessionStore,
    required PasswordHasher passwordHasher,
  })  : _store = store,
        _sessionStore = sessionStore,
        _passwordHasher = passwordHasher;

  static Future<LocalAuthRepository> open(QueryExecutor executor) async {
    final store = AuthLocalStore(executor);
    await store.initialize();
    return LocalAuthRepository(
      store: store,
      sessionStore: SessionStore(const FlutterSecureStorage()),
      passwordHasher: PasswordHasher(),
    );
  }

  final AuthLocalStore _store;
  final SessionStore _sessionStore;
  final PasswordHasher _passwordHasher;

  @override
  Future<AuthUser?> restoreSession() async {
    final userId = await _sessionStore.readActiveUserId();
    if (userId == null) return null;
    final user = await _store.findById(userId);
    if (user == null) await _sessionStore.clear();
    return user;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _store.findByEmail(_normalizeEmail(email));
    if (user == null ||
        !await _passwordHasher.verify(
          password: password,
          value: user.passwordHash,
          salt: user.passwordSalt,
        )) {
      throw const AuthException('E-mail ou senha incorretos.');
    }
    await _sessionStore.writeActiveUserId(user.id);
    return AuthUser(id: user.id, name: user.name, email: user.email);
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedName.isEmpty) throw const AuthException('Informe seu nome.');
    if (!normalizedEmail.contains('@')) {
      throw const AuthException('Informe um e-mail válido.');
    }
    if (password.length < 8) {
      throw const AuthException('A senha deve ter pelo menos 8 caracteres.');
    }
    if (await _store.findByEmail(normalizedEmail) != null) {
      throw const AuthException('Já existe uma conta com este e-mail.');
    }

    final passwordHash = await _passwordHasher.hash(password);
    final user = await _store.insert(
      name: normalizedName,
      email: normalizedEmail,
      passwordHash: passwordHash.value,
      passwordSalt: passwordHash.salt,
    );
    await _sessionStore.writeActiveUserId(user.id);
    return user;
  }

  @override
  Future<void> signOut() => _sessionStore.clear();

  String _normalizeEmail(String value) => value.trim().toLowerCase();
}
