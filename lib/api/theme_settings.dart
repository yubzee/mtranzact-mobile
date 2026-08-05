import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Message> changeActiveThemeSetting(int themeId) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String apiUrl =
        prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    final String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? '';
    final String token = prefs.getString(AppKeys.loginKey) ?? '';

    if (spToken.trim().isEmpty) {
      return Message.fromJson({
        'success': false,
        'message': 'Setup token missing. Please reinstall or set up again.',
        'invalid_license_token': true,
      });
    }

    final Uri uri = Uri.parse('$apiUrl/change-active-theme/$themeId').replace(
      queryParameters: <String, String>{
        'token': spToken,
      },
    );

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (body == null) {
      return Message.fromJson({
        'success': false,
        'message': 'Request failed (HTTP ${response.statusCode}).',
      });
    }

    final dynamic rawErrors = body['errors'];
    if ((body['message'] == null ||
            body['message'].toString().trim().isEmpty) &&
        rawErrors is List &&
        rawErrors.isNotEmpty) {
      body = <String, dynamic>{
        ...body,
        'message': rawErrors.first.toString(),
      };
    }

    if (!body.containsKey('success')) {
      final inferredSuccess =
          response.statusCode >= 200 && response.statusCode < 300;
      body = <String, dynamic>{
        ...body,
        'success': inferredSuccess,
        'message': (body['message']?.toString().trim().isNotEmpty ?? false)
            ? body['message']
            : (inferredSuccess
                ? 'Theme updated.'
                : 'Request failed (HTTP ${response.statusCode}).'),
      };
    }

    if ((body['message'] == null ||
            body['message'].toString().trim().isEmpty) &&
        (body['success'] == false ||
            response.statusCode < 200 ||
            response.statusCode >= 300)) {
      body = <String, dynamic>{
        ...body,
        'message': 'Request failed (HTTP ${response.statusCode}).',
      };
    }

    final message = Message.fromJson(body);

    if (body['invalid_token'] == true || message.invalidToken) {
      await prefs.remove(AppKeys.loginKey);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return Message.fromJson({
        ...body,
        'success': false,
        'message': (body['message']?.toString().isNotEmpty ?? false)
            ? body['message']
            : 'Request failed (HTTP ${response.statusCode}).',
      });
    }

    return message;
  } on SocketException catch (_) {
    return Message.fromJson({
      'success': false,
      'message': 'No internet connection.',
    });
  } catch (e) {
    return Message.fromJson({
      'success': false,
      'message': 'Error: ${e.toString()}',
    });
  }
}