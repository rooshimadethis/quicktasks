import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaperTheme {
  static const Color background = Color(0xFFF5F5F0);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color cardBg = Colors.transparent;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ink,
        onPrimary: background,
        secondary: ink,
        onSecondary: background,
        error: ink,
        onError: background,
        surface: background,
        onSurface: ink,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.inter(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.inter(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(
          color: ink,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: ink,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: ink, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ink, width: 1.5),
          borderRadius: BorderRadius.circular(0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ink, width: 1.5),
          borderRadius: BorderRadius.circular(0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black26,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: ink, width: 1.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        disabledElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: ink, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: ink,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: const BorderSide(color: ink, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: ink, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: ink, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ink, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ink, width: 2.0),
          borderRadius: BorderRadius.zero,
        ),
        labelStyle: TextStyle(color: ink),
        hintStyle: TextStyle(color: Colors.grey),
      ),
      dividerTheme: const DividerThemeData(
        color: ink,
        thickness: 1.5,
        space: 1.5,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return ink;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(background),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        side: const BorderSide(color: ink, width: 1.5),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: InstantPageTransitionsBuilder(),
          TargetPlatform.iOS: InstantPageTransitionsBuilder(),
          TargetPlatform.macOS: InstantPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
