/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: get_theme_color
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';

MaterialColor? getThemeColor(BuildContext context, {readProvider = false}) {
  return readProvider
      ? context.read<CommonDataProvider>().currentThemeSetting?.themeColor
      : context.watch<CommonDataProvider>().currentThemeSetting?.themeColor;
}

String getThemeColorKey(BuildContext context, {readProvider = false}) {
  return readProvider
      ? context
              .read<CommonDataProvider>()
              .currentThemeSetting
              ?.themeColor
              .shade500
              .toARGB32()
              .toString() ??
          'indigo'
      : context
              .watch<CommonDataProvider>()
              .currentThemeSetting
              ?.themeColor
              .shade500
              .toARGB32()
              .toString() ??
          'indigo';
}
