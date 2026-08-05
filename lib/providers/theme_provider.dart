/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: theme_provider
*/

import 'package:flutter/foundation.dart';
import 'package:salepro/themes/theme_appearence.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  String _themeAppearence = 'system';
  bool _debugBar = false;

  String get themeAppearence => _themeAppearence;
  bool get debugBar => _debugBar;

  void changeDebugBar(bool value) {
    _debugBar = value;
    notifyListeners();
  }

  Future<void> changeThemeAppearence(String newAppearence) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(THEME_APPEARANCE, newAppearence);

    _themeAppearence = newAppearence;
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('themeAppearence', themeAppearence),
    );
  }
}
