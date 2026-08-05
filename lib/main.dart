/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: main
*/

import 'package:flutter/foundation.dart' show kDebugMode;
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
  
  // Set up error handling for better debugging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kDebugMode) {
      debugPrint('========== FLUTTER ERROR ==========');
      debugPrint('Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
      debugPrint('===================================');
    }
  };

  try {
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
  } catch (e) {
    debugPrint('Main initialization error: $e');
  }

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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await fetchTheme(context);
      await initializeOnesignal();
    } catch (e, stack) {
      debugPrint('App initialization error: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> fetchTheme(BuildContext context) async {
    try {
      await context.read<CommonDataProvider>().getData();

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final themeAppearanceSetting = context
          .read<CommonDataProvider>()
          .currentThemeSetting
          ?.themeAppearance;

      String themeAppearance;
      if (themeAppearanceSetting == 'system_both') {
        themeAppearance = prefs.getString(THEME_APPEARANCE) ?? 'system';
      } else if (themeAppearanceSetting == 'both') {
        themeAppearance = prefs.getString(THEME_APPEARANCE) == 'system'
            ? 'light'
            : prefs.getString(THEME_APPEARANCE) ?? 'light';
      } else {
        themeAppearance = themeAppearanceSetting ?? 'system';
      }
      
      context.read<ThemeProvider>().changeThemeAppearence(themeAppearance);
    } catch (e) {
      debugPrint('Error in fetchTheme: $e');
      rethrow;
    }
  }

  Future<void> initializeOnesignal() async {
    try {
      final generalSetting = context.read<CommonDataProvider>().generalSetting;
      if (generalSetting != null && generalSetting.oneSignalAppId != null) {
        OneSignal.initialize(generalSetting.oneSignalAppId!);
        await OneSignal.Notifications.requestPermission(true);
      }
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = context.read<CommonDataProvider>().generalSetting?.isRTL ?? false;
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return MaterialApp(
      localizationsDelegates: [
        FlutterQuillLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: context.watch<CommonDataProvider>().generalSetting?.siteTitle ??
          defaultAppName,
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox(),
        );
      },
      home: const WelcomeScreen(),
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