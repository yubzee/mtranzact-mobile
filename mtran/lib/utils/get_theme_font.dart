/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: get_theme_font
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';

String? getThemeFont(BuildContext context, {type = 'watch'}) {
  return GoogleFonts.getFont(
    getThemeFontKey(context, type: type),
  ).fontFamily;
}

String getThemeFontKey(BuildContext context, {type = 'watch'}) {
  if (type == 'watch') {
    return context
            .watch<CommonDataProvider>()
            .currentThemeSetting
            ?.fontFamily ??
        'Jost';
  } else {
    return context.read<CommonDataProvider>().currentThemeSetting?.fontFamily ??
        'Jost';
  }
}
