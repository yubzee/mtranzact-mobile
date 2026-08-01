/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: spacing
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';

class AppSpacing {
  static const double kDefaultPadding = 16.0;

  static double kDefaultSpacing(BuildContext? context, {bool useWatch = true}) {
    if (context == null) return kDefaultPadding;

    if (useWatch) {
      return context
              .watch<CommonDataProvider>()
              .currentThemeSetting
              ?.itemSize
              .toDouble() ??
          kDefaultPadding;
    } else {
      return context
              .read<CommonDataProvider>()
              .currentThemeSetting
              ?.itemSize
              .toDouble() ??
          kDefaultPadding;
    }
  }
}
