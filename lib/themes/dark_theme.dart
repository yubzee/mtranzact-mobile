/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: dark_theme
*/

import 'package:flutter/material.dart';
import 'package:salepro/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/themes/button_styles.dart';

ThemeData darkTheme(
  BuildContext context, {
  MaterialColor? color = AppColors.indigoSwatch,
  String? font,
}) {
  final swatch = color ?? AppColors.indigoSwatch;
  final primary = swatch.shade300;
  final onPrimary = swatch.shade900;

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primarySwatch: color,
    primaryColor: color,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: appElevatedButtonStyle(
        context,
        primary: primary,
        onPrimary: onPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: appOutlinedButtonStyle(
        context: context,
        primary: primary,
        onPrimary: onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: appTextButtonStyle(context, primary),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(appButtonShape(context)),
      ),
    ),
    floatingActionButtonTheme: appFabTheme(
      context: context,
      primary: primary,
      onPrimary: onPrimary,
      isDark: true,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      foregroundColor: color?.shade100,
      backgroundColor: Colors.black,
      titleTextStyle: TextStyle(
        color: color?.shade100,
        fontWeight: FontWeight.w700,
        fontSize: AppSpacing.kDefaultSpacing(context) * 1.2,
        fontFamily: font,
      ),
      centerTitle: false,
    ),
    fontFamily: font ?? GoogleFonts.jost().fontFamily,
    useMaterial3: false,
  );
}
