/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: main
*/

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/themes/theme_appearence.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/providers/offline_submission_provider.dart';
import 'package:salepro/providers/theme_provider.dart';
import 'package:salepro/screens/auth/welcome.dart';
import 'package:salepro/themes/dark_theme.dart';
import 'package:salepro/themes/light_theme.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:salepro/services/background_service.dart';
import 'package:salepro/constants/keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
  );

  final prefs = await SharedPreferences.getInstance();
  final int interval = prefs.getInt(AppKeys.syncIntervalKey) ?? 1440;

  Workmanager().registerPeriodicTask(
    "$defaultAppShortCode-sync-task",
    fetchRoutesTask,
    frequency: Duration(minutes: interval),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    backoffPolicy: BackoffPolicy.exponential,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CommonDataProvider()),
        ChangeNotifierProvider(create: (_) => DebugProvider()),
        ChangeNotifierProvider(create: (_) => OfflineSubmissionProvider()),
      ],
      child: const SaleProApp(),
    ),
  );
}

class SaleProApp extends StatefulWidget {
  const SaleProApp({super.key});

  @override
  State<SaleProApp> createState() => _SaleProAppState();
}

class _SaleProAppState extends State<SaleProApp> {
  @override
  void initState() {
    super.initState();

    fetchTheme(context);
    initializeOnesignal();
  }

  Future<void> fetchTheme(BuildContext context) async {
    await context.read<CommonDataProvider>().getData();

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (context
            .read<CommonDataProvider>()
            .currentThemeSetting
            ?.themeAppearance ==
        'system_both') {
      final String themeAppearance =
          prefs.getString(THEME_APPEARANCE) ?? 'system';
      context.read<ThemeProvider>().changeThemeAppearence(themeAppearance);
    } else if (context
            .read<CommonDataProvider>()
            .currentThemeSetting
            ?.themeAppearance ==
        'both') {
      final String themeAppearance =
          prefs.getString(THEME_APPEARANCE) == 'system'
              ? 'light'
              : prefs.getString(THEME_APPEARANCE) ?? 'light';
      context.read<ThemeProvider>().changeThemeAppearence(themeAppearance);
    } else {
      final String themeAppearance = context
              .read<CommonDataProvider>()
              .currentThemeSetting
              ?.themeAppearance ??
          'system';
      context.read<ThemeProvider>().changeThemeAppearence(themeAppearance);
    }
  }

  Future<void> initializeOnesignal() async {
    if (context.read<CommonDataProvider>().generalSetting != null ||
        context.read<CommonDataProvider>().generalSetting?.oneSignalAppId !=
            null) {
      OneSignal.initialize(
          context.read<CommonDataProvider>().generalSetting!.oneSignalAppId!);
      await OneSignal.Notifications.requestPermission(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get text direction from general settings
    final isRTL =
        context.read<CommonDataProvider>().generalSetting?.isRTL ?? false;
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return MaterialApp(
      localizationsDelegates: [
        FlutterQuillLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: context.watch<CommonDataProvider>().generalSetting?.siteTitle ??
          defaultAppName,
      // Apply RTL to the entire app using builder
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox(),
        );
      },
      home: WelcomeScreen(),
      theme: lightTheme(
        context,
        color: getThemeColor(context),
        font: getThemeFont(context),
      ),
      darkTheme: darkTheme(
        context,
        color: getThemeColor(context),
        font: getThemeFont(context),
      ),
      themeMode: themeApperance[context.watch<ThemeProvider>().themeAppearence],
    );
  }
}
