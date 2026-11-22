import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class PasswordHash {
  const PasswordHash({required this.value, required this.salt});

  final String value;
  final String salt;
}

/// Password hashing based on PBKDF2-HMAC-SHA256 with a unique random salt.
class PasswordHasher {
  PasswordHasher({Cryptography? cryptography})
      : _random = Random.secure(),
        _algorithm = (cryptography ?? Cryptography.instance).pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: _iterations,
          bits: _keyBits,
        );

  static const _iterations = 100000;
  static const _keyBits = 256;
  static const _saltLength = 16;

  final Random _random;
  final Pbkdf2 _algorithm;

  Future<PasswordHash> hash(String password) async {
    final salt = List<int>.generate(
      _saltLength,
      (_) => _random.nextInt(256),
      growable: false,
    );
    final hash = await _derive(password, salt);
    return PasswordHash(
      value: base64Encode(hash),
      salt: base64Encode(salt),
    );
  }

  Future<bool> verify({
    required String password,
    required String value,
    required String salt,
  }) async {
    final derived = await _derive(password, base64Decode(salt));
    final expected = base64Decode(value);
    return _constantTimeEquals(derived, expected);
  }

  Future<List<int>> _derive(String password, List<int> salt) async {
    final secretKey = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return secretKey.extractBytes();
  }

  bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }
}
