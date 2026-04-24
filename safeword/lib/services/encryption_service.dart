import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

import '../config.dart';

/// Zero-knowledge encryption service.
/// The master password NEVER leaves this device.
/// All encryption/decryption happens entirely on the client.
class EncryptionService {
  // ─── Key Derivation ───────────────────────────────────────────────────────

  /// Derives a 256-bit encryption key from [masterPassword] and [salt]
  /// using PBKDF2-SHA256 with 100,000 iterations.
  static String deriveKey(String masterPassword, String salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final params = Pbkdf2Parameters(
      Uint8List.fromList(utf8.encode(salt)),
      AppConfig.pbkdf2Iterations,
      AppConfig.derivedKeyLength,
    );
    pbkdf2.init(params);

    final key = pbkdf2.process(Uint8List.fromList(utf8.encode(masterPassword)));
    return base64.encode(key);
  }

  /// Generates a cryptographically secure random salt (32 bytes, base64-encoded).
  static String generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64.encode(bytes);
  }

  // ─── Encryption ───────────────────────────────────────────────────────────

  /// Encrypts [plaintext] using AES-256-CBC.
  /// Returns a map with 'encrypted' (base64) and 'iv' (base64).
  static Map<String, String> encrypt(String plaintext, String derivedKeyBase64) {
    final key = enc.Key.fromBase64(derivedKeyBase64);
    final iv = enc.IV.fromSecureRandom(16); // unique per credential

    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'encrypted': encrypted.base64,
      'iv': iv.base64,
    };
  }

  // ─── Decryption ───────────────────────────────────────────────────────────

  /// Decrypts [encryptedBase64] using AES-256-CBC.
  static String decrypt(
    String encryptedBase64,
    String derivedKeyBase64,
    String ivBase64,
  ) {
    final key = enc.Key.fromBase64(derivedKeyBase64);
    final iv = enc.IV.fromBase64(ivBase64);

    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc),
    );

    return encrypter.decrypt64(encryptedBase64, iv: iv);
  }

  // ─── Password Generator ───────────────────────────────────────────────────

  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generates a cryptographically secure random password.
  static String generatePassword({
    int length = 20,
    bool includeUppercase = true,
    bool includeDigits = true,
    bool includeSymbols = true,
  }) {
    final rng = Random.secure();
    String charset = _lowercase;
    if (includeUppercase) charset += _uppercase;
    if (includeDigits) charset += _digits;
    if (includeSymbols) charset += _symbols;

    return List.generate(length, (_) => charset[rng.nextInt(charset.length)])
        .join();
  }

  // ─── Password Strength ────────────────────────────────────────────────────

  /// Returns a score 0–4 (weak → very strong).
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) score++;

    return score.clamp(0, 4);
  }
}
