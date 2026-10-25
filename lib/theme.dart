import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'store.dart';

class AppColors {
  static const navy = Color(0xFF1B3358);
  static const sky = Color(0xFF4FA8D8);
  static const skyLight = Color(0xFFDDF0FA);
  static const green = Color(0xFF6CC070);
  static const greenLight = Color(0xFFE3F5E4);
  static const orange = Color(0xFFF2A14A);
  static const orangeLight = Color(0xFFFFF0DF);
  static const red = Color(0xFFE5616F);
  static const redLight = Color(0xFFFDE7EA);
  static const bg = Color(0xFFF4F8FC);
  static const card = Colors.white;
  static const muted = Color(0xFF7D8BA1);
  static const line = Color(0xFFE6ECF3);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      primary: AppColors.navy,
      secondary: AppColors.sky,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  final text = GoogleFonts.cairoTextTheme(base.textTheme).apply(
    bodyColor: AppColors.navy,
    displayColor: AppColors.navy,
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.navy,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.sky, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: GoogleFonts.cairo(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// Makes the [AppStore] available to the whole tree and rebuilds on change.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

BoxDecoration cardDeco({Color color = Colors.white, double radius = 22}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1B3358).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
