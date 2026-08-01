/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: button_styles
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';

BorderRadius appButtonBorderRadius(BuildContext context) {
  return getThemeBorderRadiusCircular(context, intensity: 'medium');
}

OutlinedBorder appButtonShape(BuildContext context) {
  final themeSetting = context.read<CommonDataProvider>().currentThemeSetting;
  final String key = themeSetting?.borderRadius ?? 'rounded';

  if (key == 'rounded-full') {
    return const StadiumBorder();
  }

  return RoundedRectangleBorder(borderRadius: appButtonBorderRadius(context));
}

EdgeInsetsGeometry appButtonPadding(BuildContext context) {
  return EdgeInsets.symmetric(
    horizontal: AppSpacing.kDefaultSpacing(context) * 2.2,
    vertical: AppSpacing.kDefaultSpacing(context) * 0.9,
  );
}

ButtonStyle appElevatedButtonStyle(
  BuildContext context, {
  required Color primary,
  required Color onPrimary,
}) {
  final themeSetting = context.read<CommonDataProvider>().currentThemeSetting;

  final base = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: onPrimary,
    padding: appButtonPadding(context),
    shape: appButtonShape(context),
    textStyle: TextStyle(
      fontWeight: FontWeight.w700,
      fontFamily: getThemeFont(context),
    ),
  );

  if (themeSetting?.buttonStyle != 'outlined') {
    return base;
  }

  return base.copyWith(
    backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    foregroundColor: WidgetStatePropertyAll(primary),
    side: WidgetStateProperty.resolveWith((states) {
      final isDisabled = states.contains(WidgetState.disabled);
      return BorderSide(
        width: 1.2,
        color: isDisabled
            ? primary.withValues(alpha: 0.5)
            : primary.withValues(alpha: 0.95),
      );
    }),
  );
}

ButtonStyle appOutlinedButtonStyle({
  required BuildContext context,
  required Color primary,
  required Color onPrimary,
}) {
  final themeSetting = context.read<CommonDataProvider>().currentThemeSetting;

  if (themeSetting?.buttonStyle == 'outlined') {
    return OutlinedButton.styleFrom(
      padding: appButtonPadding(context),
      shape: appButtonShape(context),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      foregroundColor: primary,
      side: BorderSide(width: 1.2, color: primary),
    );
  }

  return OutlinedButton.styleFrom(
    padding: appButtonPadding(context),
    shape: appButtonShape(context),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
    backgroundColor: primary,
    foregroundColor: onPrimary,
    side: const BorderSide(color: Colors.transparent, width: 0),
  );
}

ButtonStyle appTextButtonStyle(BuildContext context, Color primary) {
  return TextButton.styleFrom(
    padding: appButtonPadding(context),
    shape: appButtonShape(context),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
    foregroundColor: primary,
  );
}

FloatingActionButtonThemeData appFabTheme({
  required BuildContext context,
  required Color primary,
  required Color onPrimary,
  bool isDark = false,
}) {
  final shape = appButtonShape(context);
  final themeSetting = context.read<CommonDataProvider>().currentThemeSetting;

  if (themeSetting?.buttonStyle == 'outlined') {
    return FloatingActionButtonThemeData(
      backgroundColor: isDark ? Colors.black : AppColors.white,
      foregroundColor: primary,
      elevation: 0,
      highlightElevation: 0,
      shape: shape.copyWith(
        side: BorderSide(width: 1.2, color: primary),
      ),
    );
  }

  return FloatingActionButtonThemeData(
    backgroundColor: primary,
    foregroundColor: onPrimary,
    elevation: 8,
    highlightElevation: 12,
    shape: shape,
  );
}
