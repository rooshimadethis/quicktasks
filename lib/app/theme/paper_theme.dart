import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaperTheme {
  static const Color background = Color(0xFFFAF9F5);
  static const Color ink = Color(0xFF1A1C19);
  static const Color surfaceDim = Color(0xFFDADAD5);
  static const Color slateGrey = Color(0xFF444748);
  static const Color cardBg = Colors.transparent;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ink,
        onPrimary: background,
        secondary: slateGrey,
        onSecondary: background,
        error: ink,
        onError: background,
        surface: background,
        onSurface: ink,
        surfaceContainer: surfaceDim,
        onSurfaceVariant: slateGrey,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.newsreader(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.newsreader(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.inter(
          color: ink,
          fontSize: 18,
        ),
        bodyMedium: GoogleFonts.inter(
          color: ink,
          fontSize: 16,
        ),
        bodySmall: GoogleFonts.inter(
          color: ink,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.inter(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        labelMedium: GoogleFonts.inter(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        labelSmall: GoogleFonts.inter(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: ink, width: 2.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ink, width: 1.0),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ink, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: ink, width: 2.0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
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
          side: BorderSide(color: ink, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(4)),
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
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: ink, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
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
          borderSide: BorderSide(color: ink, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ink, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ink, width: 2.5),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        labelStyle: TextStyle(color: ink),
        hintStyle: TextStyle(color: slateGrey),
      ),
      dividerTheme: const DividerThemeData(
        color: ink,
        thickness: 1.0,
        space: 1.0,
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
          borderRadius: BorderRadius.all(Radius.circular(2)),
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
