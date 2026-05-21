import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// AppTheme — defines the full light and dark ThemeData for the app.
///
/// Every widget that uses Theme.of(context) will automatically adapt
/// to the current theme mode — no per-screen changes needed for
/// standard Material widgets (Scaffold, Card, TextField, AppBar, etc.).
class AppTheme {
  // ── Shared constants ──────────────────────────────────────────────────────
  static const _fontFamily = 'Roboto';
  static const _borderRadius12 = BorderRadius.all(Radius.circular(12));
  static const _borderRadius16 = BorderRadius.all(Radius.circular(16));

  // =========================================================================
  //  LIGHT THEME
  // =========================================================================
  static ThemeData get lightTheme {
    const cs = ColorScheme.light(
      primary:           AppColors.brandGreen,
      onPrimary:         Colors.white,
      primaryContainer:  Color(0xFFD7F0E2),
      onPrimaryContainer:AppColors.brandGreen,
      secondary:         AppColors.brandGold,
      onSecondary:       AppColors.textPrimaryLight,
      surface:           AppColors.cardLight,
      onSurface:         AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.inputFillLight,
      onSurfaceVariant:  AppColors.textSecondaryLight,
      outline:           AppColors.borderLight,
      error:             AppColors.semanticError,
      onError:           Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      primaryColor: AppColors.brandGreen,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:   AppColors.cardLight,
        foregroundColor:   AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.shadowLight,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: _fontFamily,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: _borderRadius16),
        margin: EdgeInsets.zero,
      ),

      // ── Input Fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textHintLight, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
        prefixIconColor: AppColors.textSecondaryLight,
        suffixIconColor: AppColors.textSecondaryLight,
        border: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.semanticError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.semanticError, width: 1.5),
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandGreen,
          side: const BorderSide(color: AppColors.brandGreen),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:   AppColors.inputFillLight,
        selectedColor:     AppColors.brandGreen,
        secondarySelectedColor: AppColors.brandGreen,
        labelStyle: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        disabledColor: AppColors.borderLight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        side: const BorderSide(color: AppColors.borderLight),
        checkmarkColor: Colors.white,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:       AppColors.navBgLight,
        selectedItemColor:     AppColors.navSelectedLight,
        unselectedItemColor:   AppColors.navUnselectedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // ── NavigationBar (Material 3) ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBgLight,
        indicatorColor: AppColors.brandGreen.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navSelectedLight);
          }
          return const IconThemeData(color: AppColors.navUnselectedLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.navSelectedLight, fontWeight: FontWeight.w600, fontSize: 11);
          }
          return const TextStyle(color: AppColors.navUnselectedLight, fontSize: 11);
        }),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ──────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textSecondaryLight, size: 24),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondaryLight,
        textColor: AppColors.textPrimaryLight,
        subtitleTextStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: _borderRadius12),
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.sheetLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius16),
        titleTextStyle: TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
      ),

      // ── Text Theme ────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700),
        displaySmall:  TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium:   TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall:    TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge:     TextStyle(color: AppColors.textPrimaryLight, fontSize: 16),
        bodyMedium:    TextStyle(color: AppColors.textPrimaryLight, fontSize: 14),
        bodySmall:     TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
        labelLarge:    TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
        labelSmall:    TextStyle(color: AppColors.textHintLight, fontSize: 11),
      ),
    );
  }

  // =========================================================================
  //  DARK THEME
  // =========================================================================
  static ThemeData get darkTheme {
    const cs = ColorScheme.dark(
      primary:           AppColors.brandGreenLight,
      onPrimary:         Colors.white,
      primaryContainer:  Color(0xFF1A3D2B),
      onPrimaryContainer:AppColors.brandGreenLight,
      secondary:         AppColors.brandGold,
      onSecondary:       AppColors.textPrimaryDark,
      surface:           AppColors.cardDark,
      onSurface:         AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.inputFillDark,
      onSurfaceVariant:  AppColors.textSecondaryDark,
      outline:           AppColors.borderDark,
      error:             AppColors.semanticError,
      onError:           Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      primaryColor: AppColors.brandGreenLight,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  AppColors.cardDark,
        foregroundColor:  AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.shadowDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: _fontFamily,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: _borderRadius16),
        margin: EdgeInsets.zero,
      ),

      // ── Input Fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textHintDark, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        prefixIconColor: AppColors.textSecondaryDark,
        suffixIconColor: AppColors.textSecondaryDark,
        border: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.brandGreenLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.semanticError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadius12,
          borderSide: const BorderSide(color: AppColors.semanticError, width: 1.5),
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreenLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandGreenLight,
          side: const BorderSide(color: AppColors.brandGreenLight),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandGreenLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:   AppColors.inputFillDark,
        selectedColor:     AppColors.brandGreenLight,
        secondarySelectedColor: AppColors.brandGreenLight,
        labelStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        disabledColor: AppColors.borderDark,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        side: const BorderSide(color: AppColors.borderDark),
        checkmarkColor: Colors.white,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     AppColors.navBgDark,
        selectedItemColor:   AppColors.navSelectedDark,
        unselectedItemColor: AppColors.navUnselectedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // ── NavigationBar (Material 3) ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBgDark,
        indicatorColor: AppColors.brandGreenLight.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navSelectedDark);
          }
          return const IconThemeData(color: AppColors.navUnselectedDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.navSelectedDark, fontWeight: FontWeight.w600, fontSize: 11);
          }
          return const TextStyle(color: AppColors.navUnselectedDark, fontSize: 11);
        }),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ──────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textSecondaryDark, size: 24),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondaryDark,
        textColor: AppColors.textPrimaryDark,
        subtitleTextStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardSubtleDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: _borderRadius12),
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.sheetDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius16),
        titleTextStyle: TextStyle(color: AppColors.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
      ),

      // ── Text Theme ────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700),
        displaySmall:  TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium:   TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall:    TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge:     TextStyle(color: AppColors.textPrimaryDark, fontSize: 16),
        bodyMedium:    TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
        bodySmall:     TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
        labelLarge:    TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
        labelSmall:    TextStyle(color: AppColors.textHintDark, fontSize: 11),
      ),
    );
  }
}
