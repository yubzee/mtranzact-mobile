import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';

String getThemeInputDesign(BuildContext context) {
  return context.watch<CommonDataProvider>().currentThemeSetting?.inputDesign ??
      'filled';
}

bool isOutlinedThemeInput(BuildContext context) {
  return getThemeInputDesign(context) == 'outlined';
}
