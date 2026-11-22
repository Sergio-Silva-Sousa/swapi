import 'package:flutter_test/flutter_test.dart';
import 'package:swapo/features/auth/data/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('verifies the password that generated the hash', () async {
      final hasher = PasswordHasher();
      final hash = await hasher.hash('senha-segura');

      expect(
        await hasher.verify(
          password: 'senha-segura',
          value: hash.value,
          salt: hash.salt,
        ),
        isTrue,
      );
    });

    test('does not verify a different password', () async {
      final hasher = PasswordHasher();
      final hash = await hasher.hash('senha-segura');

      expect(
        await hasher.verify(
          password: 'senha-incorreta',
          value: hash.value,
          salt: hash.salt,
        ),
        isFalse,
      );
    });

    test('uses a different salt for each password hash', () async {
      final hasher = PasswordHasher();

      final first = await hasher.hash('senha-segura');
      final second = await hasher.hash('senha-segura');

      expect(first.salt, isNot(second.salt));
      expect(first.value, isNot(second.value));
    });
  });
}
