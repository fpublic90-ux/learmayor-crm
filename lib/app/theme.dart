import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Modern Studio Palette (Deep Obsidian & Indigo) ---
  
  static const Color primary = Color(0xFF0F172A); // Deep Obsidian
  static const Color primaryLight = Color(0xFF1E293B); 
  static const Color primarySubtle = Color(0xFFF1F5F9); 
  
  static const Color accent = Color(0xFF6366F1); // Vibrant Indigo
  static const Color accentLight = Color(0xFF818CF8); 
  static const Color accentSubtle = Color(0xFFEEF2FF); 
  
  // Alias for backward compatibility
  static const Color secondary = accent;
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981); 
  static const Color successSubtle = Color(0xFFECFDF5); 
  
  static const Color warning = Color(0xFFF59E0B); // Amber
  
  static const Color error = Color(0xFFEF4444); 
  static const Color errorSubtle = Color(0xFFFEF2F2); 
  
  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Porcelain
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0); 
  static const Color divider = Color(0xFFF1F5F9); 
  
  // Text Colors
  static const Color textDark = Color(0xFF0F172A); 
  static const Color textMid = Color(0xFF475569); 
  static const Color textLight = Color(0xFF94A3B8); 

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: accent.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      
      // Modern Studio Typography
      textTheme: GoogleFonts.outfitTextTheme(const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textDark,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -1.0,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textMid,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textMid,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: textLight,
          letterSpacing: 1.5,
        ),
      )),

      appBarTheme: AppBarTheme(
        backgroundColor: background.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textDark, size: 20),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: textMid, fontWeight: FontWeight.bold),
      ),
    );
  }
}
