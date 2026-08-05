import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/models/theme_setting.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_border_radius.dart';

/// Returns the current theme's border-radius value (in logical pixels)
/// based on `ThemeSetting.borderRadius` and intensity.
///
/// Supported keys: `rounded-none`, `rounded`, `rounded-lg`, `rounded-full`.
/// Supported intensities: `low`, `medium`, `high`.
///
/// Falls back to `rounded` + `medium` when no theme setting exists.
double getThemeBorderRadius(BuildContext context,
    {String intensity = 'medium', bool watch = false}) {
  ThemeSetting? themeSetting;
  if (watch) {
    themeSetting = context.watch<CommonDataProvider>().currentThemeSetting;
  } else {
    themeSetting = context.read<CommonDataProvider>().currentThemeSetting;
  }
  final String key = themeSetting?.borderRadius ?? 'rounded';
  return getBorderRadiusByIntensity(key, intensity);
}

BorderRadius getThemeBorderRadiusCircular(
  BuildContext context, {
  String intensity = 'medium',
}) {
  return BorderRadius.circular(
    getThemeBorderRadius(context, intensity: intensity),
  );
}

Radius getThemeRadius(
  BuildContext context, {
  String intensity = 'medium',
}) {
  return Radius.circular(
    getThemeBorderRadius(context, intensity: intensity),
  );
}
