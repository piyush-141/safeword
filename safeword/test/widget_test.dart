import 'package:flutter_test/flutter_test.dart';
import 'package:safeword/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    test('deriveKey produces consistent results for same inputs', () {
      const password = 'MyStrongMasterPassword123!';
      const salt = 'testSalt123';
      final key1 = EncryptionService.deriveKey(password, salt);
      final key2 = EncryptionService.deriveKey(password, salt);
      expect(key1, equals(key2));
    });

    test('deriveKey produces different keys for different salts', () {
      const password = 'MyStrongMasterPassword123!';
      final key1 = EncryptionService.deriveKey(password, 'salt1');
      final key2 = EncryptionService.deriveKey(password, 'salt2');
      expect(key1, isNot(equals(key2)));
    });

    test('encrypt/decrypt round-trip', () {
      const password = 'SecretPassword!@#123';
      const salt = 'uniqueRandomSalt';
      const plaintext = 'my-secret-password-value';

      final key = EncryptionService.deriveKey(password, salt);
      final result = EncryptionService.encrypt(plaintext, key);

      expect(result['encrypted'], isNotEmpty);
      expect(result['iv'], isNotEmpty);

      final decrypted = EncryptionService.decrypt(
        result['encrypted']!,
        key,
        result['iv']!,
      );
      expect(decrypted, equals(plaintext));
    });

    test('encrypt produces unique IVs each call', () {
      const password = 'MasterPass123!@#ABC';
      const salt = 'someSalt';
      final key = EncryptionService.deriveKey(password, salt);

      final r1 = EncryptionService.encrypt('hello', key);
      final r2 = EncryptionService.encrypt('hello', key);

      // Same plaintext should produce different ciphertext + IVs
      expect(r1['iv'], isNot(equals(r2['iv'])));
    });

    test('generateSalt returns non-empty base64 string', () {
      final salt = EncryptionService.generateSalt();
      expect(salt.length, greaterThan(0));
    });

    test('generatePassword respects length', () {
      final pwd = EncryptionService.generatePassword(length: 24);
      expect(pwd.length, equals(24));
    });

    test('passwordStrength returns correct levels', () {
      expect(EncryptionService.passwordStrength(''), equals(0));
      expect(EncryptionService.passwordStrength('short'), equals(0));
      expect(EncryptionService.passwordStrength('LongEnoughPass1!@'), greaterThan(2));
    });
  });
}
