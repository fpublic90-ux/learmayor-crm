import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool isDarkMode = false;

  // --- Light Palette ---
  static const Color _lightPrimary = Color(0xFF0F172A); // Deep Obsidian
  static const Color _lightPrimaryLight = Color(0xFF1E293B); 
  static const Color _lightPrimarySubtle = Color(0xFFF1F5F9); 
  
  static const Color _lightAccent = Color(0xFF6366F1); // Vibrant Indigo
  static const Color _lightAccentLight = Color(0xFF818CF8); 
  static const Color _lightAccentSubtle = Color(0xFFEEF2FF); 
  
  static const Color _lightBackground = Color(0xFFF8FAFC); // Porcelain
  static const Color _lightSurface = Colors.white;
  static const Color _lightBorder = Color(0xFFE2E8F0); 
  static const Color _lightDivider = Color(0xFFF1F5F9); 
  
  static const Color _lightTextDark = Color(0xFF0F172A); 
  static const Color _lightTextMid = Color(0xFF475569); 
  static const Color _lightTextLight = Color(0xFF94A3B8); 

  // --- Dark Palette ---
  static const Color _darkPrimary = Color(0xFFF8FAFC); 
  static const Color _darkPrimaryLight = Color(0xFFE2E8F0); 
  static const Color _darkPrimarySubtle = Color(0xFF1E293B); 
  
  static const Color _darkAccent = Color(0xFF818CF8); 
  static const Color _darkAccentLight = Color(0xFFA5B4FC); 
  static const Color _darkAccentSubtle = Color(0xFF312E81); 
  
  static const Color _darkBackground = Color(0xFF0F172A); 
  static const Color _darkSurface = Color(0xFF1E293B); 
  static const Color _darkBorder = Color(0xFF334155); 
  static const Color _darkDivider = Color(0xFF1E293B); 
  
  static const Color _darkTextDark = Color(0xFFF8FAFC); 
  static const Color _darkTextMid = Color(0xFFCBD5E1); 
  static const Color _darkTextLight = Color(0xFF64748B); 

  // --- Getters ---
  static Color get primary => isDarkMode ? _darkPrimary : _lightPrimary;
  static Color get primaryLight => isDarkMode ? _darkPrimaryLight : _lightPrimaryLight;
  static Color get primarySubtle => isDarkMode ? _darkPrimarySubtle : _lightPrimarySubtle;
  
  static Color get accent => isDarkMode ? _darkAccent : _lightAccent;
  static Color get accentLight => isDarkMode ? _darkAccentLight : _lightAccentLight;
  static Color get accentSubtle => isDarkMode ? _darkAccentSubtle : _lightAccentSubtle;
  
  static Color get secondary => accent;
  
  static Color get background => isDarkMode ? _darkBackground : _lightBackground;
  static Color get surface => isDarkMode ? _darkSurface : _lightSurface;
  static Color get border => isDarkMode ? _darkBorder : _lightBorder;
  static Color get divider => isDarkMode ? _darkDivider : _lightDivider;
  
  static Color get textDark => isDarkMode ? _darkTextDark : _lightTextDark;
  static Color get textMid => isDarkMode ? _darkTextMid : _lightTextMid;
  static Color get textLight => isDarkMode ? _darkTextLight : _lightTextLight;

  // Semantic Colors (Shared)
  static const Color success = Color(0xFF10B981); 
  static const Color successSubtle = Color(0xFFECFDF5); 
  static const Color warning = Color(0xFFF59E0B); 
  static const Color error = Color(0xFFEF4444); 
  static const Color errorSubtle = Color(0xFFFEF2F2); 

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
      textTheme: GoogleFonts.outfitTextTheme(TextTheme(
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
        iconTheme: IconThemeData(color: textDark, size: 20),
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
          side: BorderSide(color: border, width: 1),
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
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: textMid, fontWeight: FontWeight.bold),
      ),
    );
  }
}
