import 'package:flutter/material.dart';

/// Tema Oficial do Centro Automotivo Silva (Identidade Automotiva Profissional)
class AppTheme {
  // Paleta de Cores
  static const Color primaryDark = Color(0xFF081220); // Fundo Principal
  static const Color surfaceDark = Color(0xFF102138); // Cards e Superfícies
  static const Color surfaceLight = Color(0xFF183152); // Inputs e Destaques
  static const Color surfaceSelected = Color(0xFF22426D);

  static const Color silvaGold = Color(0xFFFFB703); // Dourado Âmbar Silva
  static const Color silvaOrange = Color(0xFFFB8500); // Laranja Ação
  static const Color silvaBlue = Color(0xFF219EBC); // Azul Automotivo
  static const Color silvaCyan = Color(0xFF8ECAE6); // Ciano Suave

  static const Color successGreen = Color(0xFF00E676); // Confirmada
  static const Color warningAmber = Color(0xFFFFAB00); // Necessita Revisão
  static const Color errorRed = Color(0xFFFF3D00); // Não Confirmada
  static const Color muteGray = Color(0xFF94A3B8);
  static const Color dividerColor = Color(0xFF1E3A5F);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: silvaGold,
      colorScheme: const ColorScheme.dark(
        primary: silvaGold,
        secondary: silvaBlue,
        surface: surfaceDark,
        error: errorRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 3,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: silvaGold,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: silvaCyan, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: silvaGold, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed),
        ),
        prefixIconColor: silvaGold,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: silvaGold,
        secondarySelectedColor: silvaGold,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: dividerColor),
        ),
      ),
    );
  }
}
