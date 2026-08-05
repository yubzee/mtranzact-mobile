/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: is_dark
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/theme_provider.dart';

bool isDark(BuildContext context, {bool watch = true}) {
  final themeAppearance = watch
      ? context.watch<ThemeProvider>().themeAppearence
      : context.read<ThemeProvider>().themeAppearence;

  if (themeAppearance == "system") {
    if (Theme.of(context).brightness == Brightness.dark) {
      return true;
    } else {
      return false;
    }
  } else if (themeAppearance == "dark") {
    return true;
  } else {
    return false;
  }
}

dynamic useThemeMode(
  BuildContext context, {
  required dynamic light,
  required dynamic dark,
  bool watch = true,
}) {
  if (isDark(context, watch: watch)) {
    return dark;
  } else {
    return light;
  }
}
