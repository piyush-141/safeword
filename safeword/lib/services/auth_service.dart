import 'package:supabase_flutter/supabase_flutter.dart';

import 'encryption_service.dart';


/// Handles all Supabase Auth operations.
/// The master password is kept in memory only during an active session.
class AuthService {
  // In-memory derived key – cleared on lock
  static String? _derivedKey;

  static SupabaseClient get _supabase => Supabase.instance.client;

  // ─── Session ──────────────────────────────────────────────────────────────

  static User? get currentUser => _supabase.auth.currentUser;
  static Session? get currentSession => _supabase.auth.currentSession;
  static bool get isLoggedIn => currentUser != null;

  /// The in-memory derived encryption key. Null when locked.
  static String? get derivedKey => _derivedKey;

  /// Whether the vault is unlocked (master password in memory).
  static bool get isUnlocked => _derivedKey != null;

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  /// Creates account + generates per-user salt stored in user metadata.
  /// Returns the generated salt so callers can pass it to [unlockWithSalt]
  /// immediately after OTP verification without waiting for metadata fetch.
  static Future<({AuthResponse response, String salt})> signUp({
    required String email,
    required String password,
    required String masterPassword,
  }) async {
    final salt = EncryptionService.generateSalt();

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'salt': salt,
        'app': 'safeword',
      },
    );

    if (response.user != null) {
      _setMasterPassword(masterPassword, salt);
    }

    return (response: response, salt: salt);
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
    required String masterPassword,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      final salt = response.user!.userMetadata?['salt'] as String?;
      if (salt == null) {
        throw Exception('User salt not found. Account may be corrupted.');
      }
      _setMasterPassword(masterPassword, salt);
    }

    return response;
  }

  // ─── OTP Verification ─────────────────────────────────────────────────────

  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    lock();
    await _supabase.auth.signOut();
  }

  // ─── Lock / Unlock ────────────────────────────────────────────────────────

  /// Locks the vault – clears derived key from memory.
  static void lock() {
    _derivedKey = null;
  }

  /// Unlocks the vault after OTP verification by using the salt that was
  /// generated at signup time (bypasses metadata fetch timing issues).
  static void unlockWithSalt(String masterPassword, String salt) {
    _setMasterPassword(masterPassword, salt);
  }

  /// Unlocks the vault by re-deriving the key from the entered master password.
  /// Reads salt from user metadata — use [unlockWithSalt] if you already have it.
  static bool unlock(String masterPassword) {
    final user = currentUser;
    if (user == null) return false;

    final salt = user.userMetadata?['salt'] as String?;
    if (salt == null) return false;

    _setMasterPassword(masterPassword, salt);
    return true;
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  static void _setMasterPassword(String masterPassword, String salt) {
    _derivedKey = EncryptionService.deriveKey(masterPassword, salt);
  }

  // ─── Access Token ─────────────────────────────────────────────────────────

  static String? get accessToken => currentSession?.accessToken;
}
