/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: nav_links
*/

import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/screens/auth/welcome.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/widgets/custom_view_screen.dart';
import 'package:salepro/widgets/dynamic_form_screen.dart';
import 'package:salepro/widgets/sync_interval_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Action map for special screens
final Map<String, Widget?> customScreens = {};

// Action map for methods
final Map<String, Future<void> Function(BuildContext, Map?)> customActions = {
  "register": (BuildContext context, Map? params) async {
    if (params?['token'] == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const DynamicFormScreen(
            title: 'Login',
            apiUrl: '/login',
          ),
        ),
      );
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(AppKeys.loginKey, params?['token']);

      await context.read<CommonDataProvider>().getData();

      // Check for sync interval
      if (prefs.getInt(AppKeys.syncIntervalKey) == null) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => SyncIntervalModal(
            onSaved: (bool backupNow) async {
              Navigator.pop(context);

              if (backupNow) {
                context
                    .read<CommonDataProvider>()
                    .syncAllDataWithContext(context);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => const CustomViewScreen(
                      apiUrl: '/dashboard',
                      title: 'Dashboard',
                    ),
                  ),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => const CustomViewScreen(
                      apiUrl: '/dashboard',
                      title: 'Dashboard',
                    ),
                  ),
                );
              }
            },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => const CustomViewScreen(
              apiUrl: '/dashboard',
              title: 'Dashboard',
            ),
          ),
        );
      }
    }
  },
  "login": (BuildContext context, Map? params) async {
    final prefs = await SharedPreferences.getInstance();
    if (params != null) {
      prefs.setString(AppKeys.loginKey, params['token']);

      if (params.containsKey('user_id')) {
        if (context.read<CommonDataProvider>().generalSetting != null &&
            context.read<CommonDataProvider>().generalSetting?.oneSignalAppId !=
                null) {
          OneSignal.initialize(context
              .read<CommonDataProvider>()
              .generalSetting!
              .oneSignalAppId!);
          await OneSignal.Notifications.requestPermission(true);
          await OneSignal.login(params['user_id'].toString());
        }
      }
      await context.read<CommonDataProvider>().getData();

      // Check for sync interval
      if (prefs.getInt(AppKeys.syncIntervalKey) == null) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => SyncIntervalModal(
            params: params,
            onSaved: (bool backupNow) async {
              Navigator.pop(context);

              if (backupNow) {
                context
                    .read<CommonDataProvider>()
                    .syncAllDataWithContext(context);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => const CustomViewScreen(
                      apiUrl: '/dashboard',
                      title: 'Dashboard',
                    ),
                  ),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => const CustomViewScreen(
                      apiUrl: '/dashboard',
                      title: 'Dashboard',
                    ),
                  ),
                );
              }
            },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => const CustomViewScreen(
              apiUrl: '/dashboard',
              title: 'Dashboard',
            ),
          ),
        );
      }
    }
  },
  "logout": (BuildContext context, Map? params) async {
    await showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(params?['title'] ?? "Log Out"),
          content: Text(params?['description'] ??
              "Do you want to log out or clear all app data as well?"),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(AppKeys.loginKey);
                await context.read<CommonDataProvider>().logout();
                Navigator.of(context).pop();
              },
              child: Text(
                params?['logoutText'] ?? "Log Out",
                style: TextStyle(
                  color: getThemeColor(context),
                  fontFamily: getThemeFont(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await context.read<CommonDataProvider>().clearData();
                Navigator.of(context).pop();
              },
              child: Text(
                params?['clearDataText'] ?? "Clear All Data",
                style: TextStyle(
                  color: AppColors.roseSwatch,
                  fontFamily: getThemeFont(context),
                ),
              ),
            ),
          ],
        );
      },
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  },
};
