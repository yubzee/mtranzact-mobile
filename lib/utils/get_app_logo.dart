/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: get_app_logo
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/is_dark.dart';

String? getAppLogo(BuildContext context, {useNetworkLogo = true}) {
  return useThemeMode(
    context,
    light: useNetworkLogo && hasNetworkLogo(context)
        ? '${context.watch<CommonDataProvider>().apiUrl.replaceFirst('/api', '')}/logo/${context.watch<CommonDataProvider>().generalSetting!.siteLogo}'
        : 'assets/images/logo.png',
    dark: useNetworkLogo && hasNetworkLogo(context)
        ? '${context.watch<CommonDataProvider>().apiUrl.replaceFirst('/api', '')}/logo/${context.watch<CommonDataProvider>().generalSetting!.siteLogo}'
        : 'assets/images/logo.png',
  );
}

bool hasNetworkLogo(BuildContext context) {
  return context.watch<CommonDataProvider>().generalSetting != null &&
      context.watch<CommonDataProvider>().generalSetting?.siteLogo != null &&
      context.watch<CommonDataProvider>().generalSetting!.siteLogo != '' &&
      !defaultServerUrl.contains('salepropos.com');
}
