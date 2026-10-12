import 'package:flutter/material.dart';

import 'team_theme.dart';

class AppColors {
  AppColors._();
  static const bgMain = Color(0xFF0A0A0A);
  static const bgCard = Color(0xFF111418);
  static const bgInput = Color(0xFF0D0D0D);
  static const bgItem = Color(0xFF1A1E24);
  static const border = Color(0xFF2A2F38);
  static const muted = Color(0xFF888888);
  static const neonCyan = Color(0xFF00E5FF);
  static const danger = Color(0xFFFF5252);
  static const warning = Color(0xFFFFC400);
}

class AppTheme {
  AppTheme._();

  /// Tema escuro (mesma identidade do app web) com a cor primária do time do usuário.
  static ThemeData forTeam(String? slug) {
    final team = TeamTheme.of(slug);
    final scheme = ColorScheme.dark(
      primary: team.primary,
      onPrimary: team.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white,
      secondary: AppColors.neonCyan,
      surface: AppColors.bgCard,
      error: AppColors.danger,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgMain,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgMain, elevation: 0, centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.bgInput,
        border: inputBorder, enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: team.primary, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.danger)),
        labelStyle: const TextStyle(color: AppColors.muted, letterSpacing: 1),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: team.primary),
          foregroundColor: team.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
