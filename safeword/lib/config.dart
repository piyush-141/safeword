class AppConfig {
  // ─── Supabase ─────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://coocdkwwllcoorvgiyix.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvb2Nka3d3bGxjb29ydmdpeWl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NTg1NjQsImV4cCI6MjA5MjUzNDU2NH0.jBqIQ2mEgh19urMP7A2Sn_KcXk7JZk5-3EHpVnbeTNk';

  // ─── Backend API ──────────────────────────────────────────────────────────
  // 10.0.2.2 = Android emulator -> host machine localhost
  static const String apiBaseUrl = 'https://safeword-backend.onrender.com';

  // ─── Security Settings ────────────────────────────────────────────────────
  /// Auto-lock after this many seconds of inactivity
  static const int autoLockSeconds = 5 * 60; // 5 minutes

  /// Clipboard auto-clears after this many seconds
  static const int clipboardClearSeconds = 30;

  /// Auto-hide revealed password after this many seconds
  static const int passwordHideSeconds = 30;

  /// PBKDF2 iterations (higher = more secure, but slower)
  static const int pbkdf2Iterations = 100000;

  /// Derived key length in bytes (256-bit)
  static const int derivedKeyLength = 32;

  /// Minimum master password length
  static const int minMasterPasswordLength = 12;

  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'SafeWord';
  static const String appVersion = '1.0.0';
}
