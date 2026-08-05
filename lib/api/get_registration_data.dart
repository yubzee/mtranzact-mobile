/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: get_registration_data
*/

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> getRegistrationFormData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String apiUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
  final dataKey = "/get-registration-form-data";
  String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
  String token = prefs.getString(AppKeys.loginKey) ?? "";

  try {
    final response = await http.get(
      Uri.parse("$apiUrl/get-registration-form-data?token=$spToken"),
      headers: {
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      prefs.setString(dataKey, response.body);
      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } else if (prefs.getString(dataKey) != null) {
      final Map<String, dynamic> body = jsonDecode(prefs.getString(dataKey)!);
      return body;
    } else {
      return {
        'general_settings': {},
        'current_theme_setting': null,
      };
    }
  } on SocketException catch (_) {
    if (prefs.getString(dataKey) != null) {
      final Map<String, dynamic> body = jsonDecode(prefs.getString(dataKey)!);
      return body;
    } else {
      return {
        'general_settings': {},
        'current_theme_setting': null,
      };
    }
  } catch (e) {
    return {
      'general_settings': {},
      'current_theme_setting': null,
      'error': e.toString(),
    };
  }
}