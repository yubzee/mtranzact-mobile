/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: theme_appearence
*/

// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:salepro/api/client.dart';

const THEME_APPEARANCE = '${defaultAppShortCode}_theme_appearance';
const THEME = '${defaultAppShortCode}_theme';

final Map<String, ThemeMode> themeApperance = {
  'light': ThemeMode.light,
  'dark': ThemeMode.dark,
  'system': ThemeMode.system,
};
