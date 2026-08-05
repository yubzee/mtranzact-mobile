/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: auth
*/

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a custom HTTP client that ignores SSL errors for development
class _HttpClient {
  static http.Client _createClient() {
    if (kDebugMode) {
      // For development, create a client that ignores SSL errors
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return http.IOClient(httpClient);
    }
    return http.Client();
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final client = _createClient();
    try {
      return await client.post(url, headers: headers, body: body, encoding: encoding);
    } finally {
      client.close();
    }
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final client = _createClient();
    try {
      return await client.get(url, headers: headers);
    } finally {
      client.close();
    }
  }
}

String getPlatform() {
  if (Platform.isAndroid) {
    return "android";
  } else if (Platform.isIOS) {
    return "ios";
  } else if (Platform.isLinux) {
    return "linux";
  } else if (Platform.isMacOS) {
    return "macos";
  } else if (Platform.isWindows) {
    return "windows";
  } else if (kIsWeb) {
    return "web";
  } else {
    return "unknown";
  }
}

Future<Message> setup(Map<String, dynamic> config) async {
  try {
    if (!config.containsKey('install_url') || config['install_url'] == null) {
      return Message.fromJson({
        'success': false,
        'message': "Installation URL is required",
      });
    }

    final response = await _HttpClient.post(
      Uri.parse("${config['install_url']}/api/check"),
      body: {...config, 'platform': getPlatform()},
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body);
        Message message = Message.fromJson(body);

        if (message.data != null && message.data!['token'] != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString(
              AppKeys.saleproInstallURL, "${config['install_url']}/api");
          prefs.setString(AppKeys.saleproSetupToken, message.data!['token']);
          return message;
        } else {
          return message;
        }
      } catch (e) {
        return Message.fromJson(
          {
            'success': false,
            'message': "Invalid Installation URL...",
          },
        );
      }
    } else {
      try {
        final body = jsonDecode(response.body);
        return Message.fromJson(body);
      } catch (e) {
        return Message.fromJson(
          {
            'success': false,
            'message': "Invalid Installation URL...",
          },
        );
      }
    }
  } on SocketException catch (_) {
    return Message.fromJson({
      'success': false,
      'message': "No internet connection. Please check your network.",
    });
  } on HandshakeException catch (e) {
    return Message.fromJson({
      'success': false,
      'message': "SSL/TLS handshake failed. Please check your server certificate.",
      'error': e.toString(),
    });
  } catch (e) {
    return Message.fromJson({
      'success': false,
      'message': "Something went wrong: ${e.toString()}",
    });
  }
}

Future<Message> register(Map<String, dynamic> userData) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String apiUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";

    final response = await _HttpClient.post(
      Uri.parse("$apiUrl/register?token=$spToken"),
      body: userData,
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      Message message = Message.fromJson(body);

      if (message.data != null && message.data!['token'] != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(AppKeys.loginKey, message.data!['token']);
        return message;
      } else {
        return message;
      }
    } else {
      final body = jsonDecode(response.body);
      if (body['invalid_token'] != null && body['invalid_token']) {
        prefs.clear();
      }
      return Message.fromJson(body);
    }
  } on HandshakeException catch (e) {
    return Message.fromJson({
      'success': false,
      'message': "SSL/TLS handshake failed. Please check your server certificate.",
      'error': e.toString(),
    });
  } catch (e) {
    return Message.fromJson({
      'success': false,
      'message': "Registration failed: ${e.toString()}",
    });
  }
}

Future<Message> login(Map<String, dynamic> userData) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String apiUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";

    final response = await _HttpClient.post(
      Uri.parse("$apiUrl/login?token=$spToken"),
      body: userData,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      Message message = Message.fromJson(body);

      if (message.data != null && message.data!['token'] != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(AppKeys.loginKey, message.data!['token']);
        return message;
      } else {
        return message;
      }
    } else {
      final body = jsonDecode(response.body);
      if (body['invalid_token'] != null && body['invalid_token']) {
        prefs.clear();
      }
      return Message.fromJson(body);
    }
  } on HandshakeException catch (e) {
    return Message.fromJson({
      'success': false,
      'message': "SSL/TLS handshake failed. Please check your server certificate.",
      'error': e.toString(),
    });
  } catch (e) {
    return Message.fromJson({
      'success': false,
      'message': "Login failed: ${e.toString()}",
    });
  }
}

Future<Map<String, dynamic>> verifyToken(String token) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String apiUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
  String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
  final dataKey = "/get-user";

  try {
    final response = await _HttpClient.get(
      Uri.parse("$apiUrl/get-user?token=$spToken"),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      prefs.setString(dataKey, response.body);
      final data = jsonDecode(response.body);
      return {...data, 'success': true};
    } else if (prefs.getString(dataKey) != null) {
      final data = jsonDecode(prefs.getString(dataKey)!);
      return {...data, 'success': true};
    } else {
      final data = jsonDecode(response.body);
      if (data['invalid_token'] != null && data['invalid_token']) {
        prefs.clear();
      }
      return {...data, 'success': false};
    }
  } on SocketException catch (_) {
    if (prefs.getString(dataKey) != null) {
      final data = jsonDecode(prefs.getString(dataKey)!);
      return {...data, 'success': true};
    } else {
      return {'success': false, 'message': 'No internet connection'};
    }
  } on HandshakeException catch (e) {
    return {'success': false, 'message': 'SSL/TLS handshake failed: $e'};
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}