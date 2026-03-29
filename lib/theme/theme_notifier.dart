import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'horario_theme.dart';

/// Identidade visual (Landing Page) — verde-água e dark grafite.
const Color salaoProPrimary = Color(0xFF14B8A6);
const Color salaoProAccent = Color(0xFFF97316);
const Color salaoProDarkBackground = Color(0xFF121212);
const Color salaoProDarkSurface = Color(0xFF1E1E1E);

/// Texto principal no tema claro (contraste com superfícies claras).
const Color salaoProLightOnSurface = Color(0xFF1E293B);

/// Cards no tema claro — superfície leve (slate-50).
const Color salaoProCardLight = Color(0xFFF8FAFC);

enum AppThemeMode { system, light, dark }

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeNotifier() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  AppThemeMode get appThemeMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  void setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case AppThemeMode.light:
        _themeMode = ThemeMode.light;
        await prefs.setString('theme', 'light');
        break;
      case AppThemeMode.dark:
        _themeMode = ThemeMode.dark;
        await prefs.setString('theme', 'dark');
        break;
      case AppThemeMode.system:
        _themeMode = ThemeMode.system;
        await prefs.setString('theme', 'system');
        break;
    }
    notifyListeners();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme') ?? 'system';
    switch (themeStr) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }
}

ThemeData get temaSalaoPro {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: salaoProPrimary,
    brightness: Brightness.light,
  ).copyWith(
    primary: salaoProPrimary,
    onPrimary: Colors.white,
    secondary: salaoProAccent,
    onSecondary: Colors.white,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    primaryColor: salaoProPrimary,
    appBarTheme: AppBarTheme(
      backgroundColor: salaoProPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: salaoProAccent,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: salaoProLightOnSurface,
      displayColor: salaoProLightOnSurface,
    ).copyWith(
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: salaoProLightOnSurface,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: salaoProLightOnSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: salaoProPrimary, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      floatingLabelStyle: const TextStyle(
        color: salaoProPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: GoogleFonts.poppins(color: salaoProLightOnSurface),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.grey.shade400;
          }
          return salaoProAccent;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.white70;
          }
          return Colors.white;
        }),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 18),
        ),
        textStyle: MaterialStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: salaoProCardLight,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: Colors.black.withOpacity(0.04)),
      ),
    ),
    extensions: const [
      HorarioTheme(
        livreBackground: Color(0xFFF3F3F3),
        livreText: salaoProLightOnSurface,
        ocupadoBackground: Color(0xFFE53935),
        ocupadoText: Colors.white,
        passadoBackground: Color(0xFFB0B0B0),
        passadoText: Colors.white,
        selecionadoBackground: salaoProPrimary,
        selecionadoText: Colors.white,
      ),
    ],
  );
}

ThemeData get temaSalaoProDark {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: salaoProPrimary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: salaoProPrimary,
    onPrimary: Colors.white,
    secondary: salaoProAccent,
    onSecondary: Colors.white,
    surface: salaoProDarkSurface,
    onSurface: Colors.white,
    onSurfaceVariant: Colors.white70,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: salaoProDarkBackground,
    primaryColor: salaoProPrimary,
    appBarTheme: AppBarTheme(
      backgroundColor: salaoProPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: salaoProAccent,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: salaoProDarkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: salaoProPrimary, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: GoogleFonts.poppins(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.grey.shade700;
          }
          return salaoProAccent;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.white54;
          }
          return Colors.white;
        }),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 18),
        ),
        textStyle: MaterialStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: salaoProDarkSurface,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.35),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
    ),
    extensions: const [
      HorarioTheme(
        livreBackground: Color(0xFF2A2A2A),
        livreText: Colors.white,
        ocupadoBackground: Color(0xFFE53935),
        ocupadoText: Colors.white,
        passadoBackground: Color(0xFF555555),
        passadoText: Colors.white,
        selecionadoBackground: salaoProPrimary,
        selecionadoText: Colors.white,
      ),
    ],
  );
}
