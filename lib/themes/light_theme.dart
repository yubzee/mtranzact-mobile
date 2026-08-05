/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: light_theme
*/

import 'package:flutter/material.dart';
import 'package:salepro/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/themes/button_styles.dart';

ThemeData lightTheme(BuildContext context,
    {MaterialColor? color = AppColors.indigoSwatch, String? font}) {
  final swatch = color ?? AppColors.indigoSwatch;
  final primary = swatch.shade900;
  const onPrimary = Colors.white;

  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,
    primarySwatch: color,
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
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      foregroundColor: color?.shade900,
      backgroundColor: AppColors.white,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: AppSpacing.kDefaultSpacing(context) * 1.2,
        fontFamily: font,
        color: color?.shade900,
      ),
      centerTitle: false,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.transparent,
    ),
    fontFamily: font ?? GoogleFonts.jost().fontFamily,
    useMaterial3: false,
  );
}
