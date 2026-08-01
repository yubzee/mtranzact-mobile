/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: common_data_provider
*/

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:salepro/api/auth.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/models/general_setting.dart';
import 'package:salepro/api/get_registration_data.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/models/theme_setting.dart';
import 'package:salepro/services/background_service.dart';
import 'package:salepro/themes/theme_appearence.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonDataProvider with ChangeNotifier, DiagnosticableTreeMixin {
  Map _sidebar = {'drawer': []};
  bool _noInternet = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isCaching = false;
  bool _usingDemo = false;
  String? _token;
  String _apiUrl = defaultApiURL;
  GeneralSetting? _generalSetting;
  ThemeSetting _currentThemeSetting = ThemeSetting.defaultThemeSettings().first;
  int? _selectedThemeId;
  int _totalCount = 0;
  int _progressCount = 0;

  Map get sidebar => _sidebar;
  bool get noInternet => _noInternet;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get usingDemo => _usingDemo;
  bool get isCaching => _isCaching;
  String? get token => _token;
  String get apiUrl => _apiUrl;
  GeneralSetting? get generalSetting => _generalSetting;
  ThemeSetting? get currentThemeSetting => _currentThemeSetting;
  int? get selectedThemeId => _selectedThemeId;
  int get totalCount => _totalCount;
  int get progressCount => _progressCount;

  void setDemo() {
    _usingDemo = true;
    notifyListeners();
  }

  Future<void> setCurrentThemeSetting(ThemeSetting themeSetting) async {
    _currentThemeSetting = themeSetting;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(THEME, jsonEncode(themeSetting.toMap()));
    notifyListeners();
  }

  Future<void> setLoading(bool value) async {
    _isLoading = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(AppKeys.noInternetKey) != null) {
      if (prefs.getString(AppKeys.noInternetKey) == "true") {
        _noInternet = true;
      } else {
        _noInternet = false;
      }
    }
    notifyListeners();
  }

  Future<void> checkInternet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(AppKeys.noInternetKey) != null) {
      if (prefs.getString(AppKeys.noInternetKey) == "true") {
        _noInternet = true;
      } else {
        _noInternet = false;
      }

      notifyListeners();
    }
  }

  Future<void> getData({bool isCaching = false}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _apiUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      _currentThemeSetting = prefs.getString(THEME) != null
          ? ThemeSetting.fromJson(jsonDecode(prefs.getString(THEME)!))
          : ThemeSetting.defaultThemeSettings().first;
      if (isCaching) {
        _isLoading = false;
        _isCaching = true;
      }
      notifyListeners();

      final Map<String, dynamic> data = await getRegistrationFormData();
      _generalSetting = GeneralSetting.fromJson(data['general_settings']);
      final Map<String, dynamic>? currentThemeJson =
          data['current_theme_setting'] is Map
              ? Map<String, dynamic>.from(data['current_theme_setting'] as Map)
              : null;

      if (currentThemeJson != null) {
        _currentThemeSetting = ThemeSetting.fromJson(currentThemeJson);
      }

      _selectedThemeId = _currentThemeSetting.id;
      if (_selectedThemeId != null) {
        await prefs.setString(THEME, jsonEncode(_currentThemeSetting.toMap()));
      }

      final String? token = prefs.getString(AppKeys.loginKey);
      String apiUrl =
          prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;

      if (apiUrl != defaultApiURL) {
        _usingDemo = false;
      }

      if (token != null) {
        _token = token;
        final Map<String, dynamic> data = await verifyToken(token);
        if (data['success']) {
          _sidebar = data['drawer'];
          final Map<String, dynamic>? currentThemeJson =
              data['current_theme_setting'] is Map
                  ? Map<String, dynamic>.from(
                      data['current_theme_setting'] as Map)
                  : null;

          if (currentThemeJson != null) {
            _currentThemeSetting = ThemeSetting.fromJson(currentThemeJson);
          }
        }
      } else {
        _token = null;
        prefs.remove(AppKeys.loginKey);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> syncAllData() async {
    _isSyncing = true;
    notifyListeners();
    await BackgroundService().syncData();
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> syncAllDataWithContext(BuildContext context) async {
    _isSyncing = true;
    notifyListeners();
    await BackgroundService().syncDataContext(
      (total, progress) {
        _totalCount = total;
        _progressCount = progress;
        notifyListeners();
      },
    );
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> clearData() async {
    _sidebar = {'drawer': []};
    _noInternet = false;
    _isLoading = false;
    _isSyncing = false;
    _isCaching = false;
    _usingDemo = false;
    _token = null;
    _generalSetting = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _noInternet = false;
    _isLoading = false;
    _isSyncing = false;
    _isCaching = false;
    _token = null;
    notifyListeners();
  }
}
