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

  String apiUrl =
      prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;

  final String dataKey = "/get-registration-form-data";

  String spToken =
      prefs.getString(AppKeys.saleproSetupToken) ?? "";

  String loginToken =
      prefs.getString(AppKeys.loginKey) ?? "";

  final String url =
      "$apiUrl/get-registration-form-data?token=$spToken";

  try {
    debugPrint("");
    debugPrint("==============================================");
    debugPrint("🚀 GET REGISTRATION DATA");
    debugPrint("==============================================");
    debugPrint("URL:");
    debugPrint(url);
    debugPrint("");
    debugPrint("Setup Token:");
    debugPrint(spToken.isEmpty ? "(EMPTY)" : spToken);
    debugPrint("");
    debugPrint("Login Token Exists:");
    debugPrint(loginToken.isNotEmpty ? "YES" : "NO");
    debugPrint("==============================================");

    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            if (loginToken.isNotEmpty)
              'Authorization': 'Bearer $loginToken',
          },
        )
        .timeout(const Duration(seconds: 30));

    debugPrint("");
    debugPrint("==============================================");
    debugPrint("🌐 SERVER RESPONSE");
    debugPrint("==============================================");
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("");
    debugPrint("Body:");
    debugPrint(response.body);
    debugPrint("==============================================");

    if (response.statusCode == 200) {
      await prefs.setString(dataKey, response.body);

      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      debugPrint("❌ Unauthorized (401)");
    }

    if (response.statusCode == 404) {
      debugPrint("❌ Route Not Found (404)");
    }

    if (response.statusCode == 405) {
      debugPrint("❌ Method Not Allowed (405)");
    }

    if (response.statusCode >= 500) {
      debugPrint("❌ Server Error (${response.statusCode})");
    }

    if (prefs.containsKey(dataKey)) {
      debugPrint("⚠ Using cached registration data.");

      return jsonDecode(prefs.getString(dataKey)!);
    }

    throw Exception(
      "Registration API failed.\n"
      "Status Code: ${response.statusCode}\n"
      "Response: ${response.body}",
    );
  } on SocketException catch (e, stack) {
    debugPrint("");
    debugPrint("==============================================");
    debugPrint("❌ SOCKET EXCEPTION");
    debugPrint("==============================================");
    debugPrint(e.toString());
    debugPrint(stack.toString());

    if (prefs.containsKey(dataKey)) {
      debugPrint("⚠ Offline. Using cached data.");

      return jsonDecode(prefs.getString(dataKey)!);
    }

    rethrow;
  } on HttpException catch (e, stack) {
    debugPrint("");
    debugPrint("==============================================");
    debugPrint("❌ HTTP EXCEPTION");
    debugPrint("==============================================");
    debugPrint(e.toString());
    debugPrint(stack.toString());

    rethrow;
  } on FormatException catch (e, stack) {
    debugPrint("");
    debugPrint("==============================================");
    debugPrint("❌ INVALID JSON");
    debugPrint("==============================================");
    debugPrint(e.toString());
    debugPrint(stack.toString());

    rethrow;
  } catch (e, stack) {
    debugPrint("");
    debugPrint("==============================================");
    debugPrint("❌ UNKNOWN ERROR");
    debugPrint("==============================================");
    debugPrint(e.toString());
    debugPrint(stack.toString());

    rethrow;
  }
}