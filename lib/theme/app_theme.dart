import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Palette ──────────────────────────────────────────────
  static const Color bgDeep     = Color(0xFF0A0A0C); // near-black base
  static const Color bgSurface  = Color(0xFF13111A); // slightly lifted surface
  static const Color cardBg     = Color(0xFF1C1825); // card background
  static const Color cardBorder = Color(0xFF2A2435); // subtle border

  // Maroon / crimson accent family
  static const Color maroon     = Color(0xFF8B1A2E); // deep maroon
  static const Color crimson    = Color(0xFFBF2340); // bright crimson
  static const Color roseGlow   = Color(0xFFE8445A); // rose highlight

  // Neutral text
  static const Color textPrimary   = Color(0xFFF0EDF5);
  static const Color textSecondary = Color(0xFF9E97B0);
  static const Color textMuted     = Color(0xFF5A5370);

  // ── Gradients ─────────────────────────────────────────────────
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [maroon, crimson, roseGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get subtleGradient => const LinearGradient(
    colors: [Color(0xFF1C1825), Color(0xFF231C2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get overlayGradient => LinearGradient(
    colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // ── Theme ─────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: ColorScheme.dark(
        surface:   cardBg,
        primary:   crimson,
        secondary: roseGlow,
        onSurface: textPrimary,
        outline:   cardBorder,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontSize: 15,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: textSecondary,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: textMuted,
          fontSize: 13,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimson,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        hintStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: crimson, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardBg,
        contentTextStyle: GoogleFonts.dmSans(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dialogTheme: DialogThemeData(
        backgroundColor: bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.dmSans(color: textSecondary, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardBg,
        selectedColor: crimson.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.dmSans(color: textSecondary, fontSize: 13),
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: crimson,
      ),
    );
  }
}
