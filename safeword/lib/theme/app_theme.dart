import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Mastercard Color Palette ──────────────────────────────────────────────
  // Canvas & Surfaces
  static const Color canvas = Color(0xFFF3F0EE);       // Warm putty canvas
  static const Color lifted = Color(0xFFFCFBFA);        // Lifted cream
  static const Color white = Color(0xFFFFFFFF);

  // Ink & Text
  static const Color ink = Color(0xFF141413);           // Warm near-black
  static const Color charcoal = Color(0xFF262627);
  static const Color slate = Color(0xFF696969);         // Muted secondary
  static const Color dust = Color(0xFFD1CDC7);          // Whisper / placeholder

  // Accents
  static const Color signalOrange = Color(0xFFCF4500);  // Consent only
  static const Color arcOrange = Color(0xFFF37338);     // Decorative arcs
  static const Color linkBlue = Color(0xFF3860BE);

  // Semantic
  static const Color danger = Color(0xFFCC2936);        // Error / delete

  // ─── Aliases for backward-compat with existing screens ────────────────────
  static const Color primary = ink;
  static const Color primaryDark = charcoal;
  static const Color primaryLight = slate;
  static const Color surface = lifted;
  static const Color surfaceCard = white;
  static const Color surfaceElevated = canvas;
  static const Color background = canvas;
  static const Color accent = arcOrange;
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentOrange = signalOrange;
  static const Color textPrimary = ink;
  static const Color textSecondary = slate;
  static const Color textMuted = dust;
  static const Color divider = Color(0xFFE2DDD9);

  // ─── Shadow Tokens ─────────────────────────────────────────────────────────
  static const List<BoxShadow> navShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 48, offset: Offset(0, 24)),
  ];

  // ─── Gradients — Mastercard uses NO programmatic gradients, only solid surfaces
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [ink, charcoal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [canvas, lifted],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [white, lifted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme Data ───────────────────────────────────────────────────────────
  static ThemeData get theme {
    // Sofia Sans is in Mastercard's own fallback stack — closest open-source match
    final base = ThemeData.light();
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.light(
        primary: ink,
        secondary: arcOrange,
        surface: white,
        error: danger,
        onPrimary: canvas,
        onSecondary: white,
        onSurface: ink,
        onError: white,
      ),
      textTheme: GoogleFonts.sofiaSansTextTheme(base.textTheme).copyWith(
        // H1 — hero
        displayLarge: GoogleFonts.sofiaSans(
          color: ink, fontSize: 40, fontWeight: FontWeight.w500,
          letterSpacing: -0.8, height: 1.0,
        ),
        // H2 — section
        displayMedium: GoogleFonts.sofiaSans(
          color: ink, fontSize: 32, fontWeight: FontWeight.w500,
          letterSpacing: -0.64, height: 1.2,
        ),
        // H3 — card title
        displaySmall: GoogleFonts.sofiaSans(
          color: ink, fontSize: 24, fontWeight: FontWeight.w500,
          letterSpacing: -0.48, height: 1.2,
        ),
        headlineMedium: GoogleFonts.sofiaSans(
          color: ink, fontSize: 22, fontWeight: FontWeight.w500,
          letterSpacing: -0.44, height: 1.25,
        ),
        titleLarge: GoogleFonts.sofiaSans(
          color: ink, fontSize: 18, fontWeight: FontWeight.w500,
          letterSpacing: -0.36,
        ),
        titleMedium: GoogleFonts.sofiaSans(
          color: ink, fontSize: 16, fontWeight: FontWeight.w500,
          letterSpacing: -0.32,
        ),
        // Body — weight 400 approximating 450
        bodyLarge: GoogleFonts.sofiaSans(color: ink, fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),
        bodyMedium: GoogleFonts.sofiaSans(color: slate, fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
        // Eyebrow — uppercase, tracked
        labelLarge: GoogleFonts.sofiaSans(
          color: ink, fontSize: 16, fontWeight: FontWeight.w500,
          letterSpacing: -0.48,
        ),
        labelMedium: GoogleFonts.sofiaSans(
          color: slate, fontSize: 12, fontWeight: FontWeight.w700,
          letterSpacing: 0.56,
        ),
        labelSmall: GoogleFonts.sofiaSans(color: dust, fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.sofiaSans(
          color: ink, fontSize: 20, fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0x66141413), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0x33141413), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        labelStyle: GoogleFonts.sofiaSans(color: slate, fontSize: 14),
        hintStyle: GoogleFonts.sofiaSans(color: dust, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        prefixIconColor: slate,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: canvas,
          minimumSize: const Size(double.infinity, 52),
          // Ink Pill — 20px radius, the Mastercard signature button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.sofiaSans(
            fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.32,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: ink, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.sofiaSans(
            fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.32,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: GoogleFonts.sofiaSans(
            fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.28,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2DDD9)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2DDD9), thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.sofiaSans(color: canvas, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: canvas,
        elevation: 0,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.sofiaSans(
          color: ink, fontSize: 20, fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.sofiaSans(color: slate, fontSize: 15),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ink : Colors.transparent,
        ),
        side: const BorderSide(color: slate, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ink),
    );
  }

  // Keep darkTheme as an alias so nothing breaks
  static ThemeData get darkTheme => theme;
}
