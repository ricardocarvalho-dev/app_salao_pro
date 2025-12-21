import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'horario_theme.dart';

const Color corHeader = Color(0xFF66D1D3);
const Color corBotaoAtivo = Color(0xFFF38A53);
const Color corTexto = Color(0xFF6D4C41);
const Color corFundo = Colors.white;

/*
ThemeData get temaSalaoPro {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    scaffoldBackgroundColor: corFundo,
    primaryColor: corBotaoAtivo,
    colorScheme: const ColorScheme.light(
      primary: corBotaoAtivo,
      background: corFundo,
      surface: corFundo,
      onPrimary: Colors.white,
      onSurface: corTexto,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: corTexto,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: corTexto,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: corHeader,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: corBotaoAtivo, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      floatingLabelStyle: const TextStyle(
        color: corBotaoAtivo,
        fontWeight: FontWeight.w600,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: GoogleFonts.poppins(color: corTexto),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.white),
        foregroundColor: MaterialStateProperty.all(corTexto),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 18),
        ),
        textStyle: MaterialStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: corTexto, // usa a cor marrom do tema
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
  );
}
*/
ThemeData get temaSalaoPro {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    scaffoldBackgroundColor: corFundo,
    primaryColor: corBotaoAtivo,
    colorScheme: const ColorScheme.light(
      primary: corBotaoAtivo,
      background: corFundo,
      surface: corFundo,
      onPrimary: Colors.white,
      onSurface: corTexto,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: corTexto,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: corTexto,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: corHeader,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: corBotaoAtivo, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      floatingLabelStyle: const TextStyle(
        color: corBotaoAtivo,
        fontWeight: FontWeight.w600,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: GoogleFonts.poppins(color: corTexto),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.white),
        foregroundColor: MaterialStateProperty.all(corTexto),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 18),
        ),
        textStyle: MaterialStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: corTexto,
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),

    // ⭐ ADICIONADO: EXTENSÃO DE TEMA PARA HORÁRIOS
    extensions: const [
      HorarioTheme(
        livreBackground: Color(0xFFF3F3F3),
        livreText: corTexto,
        ocupadoBackground: Color(0xFFE53935),
        ocupadoText: Colors.white,
        passadoBackground: Color(0xFFB0B0B0),
        passadoText: Colors.white,
        selecionadoBackground: corBotaoAtivo,
        selecionadoText: Colors.white,
      ),
    ],
  );
}

/*
ThemeData get temaSalaoProDark {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: corBotaoAtivo,
    colorScheme: const ColorScheme.dark(
      primary: corBotaoAtivo,
      background: Colors.black,
      surface: Color(0xFF121212),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: corHeader,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: corBotaoAtivo, width: 2),
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
    /*
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF1E1E1E)),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 18),
        ),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
      ),
    ),
    */
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF1E1E1E)),
        foregroundColor: MaterialStateProperty.all(Colors.white),
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
      color: const Color(0xFF1E1E1E),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.4),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
  );
}
*/
ThemeData get temaSalaoProDark {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: corBotaoAtivo,
    colorScheme: const ColorScheme.dark(
      primary: corBotaoAtivo,
      background: Colors.black,
      surface: Color(0xFF121212),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: corHeader,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: corBotaoAtivo, width: 2),
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
        backgroundColor: MaterialStateProperty.all(const Color(0xFF1E1E1E)),
        foregroundColor: MaterialStateProperty.all(Colors.white),
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
      color: const Color(0xFF1E1E1E),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.4),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),

    // ⭐ ADICIONADO: EXTENSÃO DARK
    extensions: const [
      HorarioTheme(
        livreBackground: Color(0xFF2A2A2A),
        livreText: Colors.white,
        ocupadoBackground: Color(0xFFE53935),
        ocupadoText: Colors.white,
        passadoBackground: Color(0xFF555555),
        passadoText: Colors.white,
        selecionadoBackground: corBotaoAtivo,
        selecionadoText: Colors.white,
      ),
    ],
  );
}

