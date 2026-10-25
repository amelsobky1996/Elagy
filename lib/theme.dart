import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'store.dart';

/// Brand colors. The neutral ones change with the active theme, so they are
/// getters (never use them inside `const`).
class AppColors {
  static bool dark = false;

  // Brand (same in both themes)
  static const navy = Color(0xFF1B3358);
  static const sky = Color(0xFF4FA8D8);
  static const green = Color(0xFF6CC070);
  static const orange = Color(0xFFF2A14A);
  static const red = Color(0xFFE5616F);

  // Theme-dependent
  static Color get ink => dark ? const Color(0xFFE8EEF6) : navy;
  static Color get muted =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF7D8BA1);
  static Color get bg =>
      dark ? const Color(0xFF0E1726) : const Color(0xFFF4F8FC);
  static Color get card => dark ? const Color(0xFF17243A) : Colors.white;
  static Color get line =>
      dark ? const Color(0xFF26364F) : const Color(0xFFE6ECF3);
  static Color get primary => dark ? sky : navy;
  static Color get skyLight =>
      dark ? const Color(0xFF1C3A55) : const Color(0xFFDDF0FA);
  static Color get greenLight =>
      dark ? const Color(0xFF1D3A2A) : const Color(0xFFE3F5E4);
  static Color get orangeLight =>
      dark ? const Color(0xFF3E2E1A) : const Color(0xFFFFF0DF);
  static Color get redLight =>
      dark ? const Color(0xFF41222A) : const Color(0xFFFDE7EA);
}

ThemeData buildTheme({required bool dark, required bool arabic}) {
  AppColors.dark = dark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.sky,
      surface: AppColors.card,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  final raw = arabic
      ? GoogleFonts.cairoTextTheme(base.textTheme)
      : GoogleFonts.poppinsTextTheme(base.textTheme);
  final text = raw.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  final font = arabic ? GoogleFonts.cairo : GoogleFonts.poppins;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.sky, 1.6),
      hintStyle: TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: font(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: AppColors.card),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.card),
    popupMenuTheme: PopupMenuThemeData(color: AppColors.card),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.skyLight,
      labelTextStyle: WidgetStatePropertyAll(
        font(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: font(color: Colors.white),
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

BoxDecoration cardDeco({Color? color, double radius = 22}) => BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: AppColors.dark ? Border.all(color: AppColors.line) : null,
      boxShadow: AppColors.dark
          ? null
          : [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
    );
