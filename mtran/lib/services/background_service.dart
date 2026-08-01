import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/api/client.dart';

const String fetchRoutesTask = "fetchRoutesTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchRoutesTask) {
      await BackgroundService().syncData();
    }
    return Future.value(true);
  });
}

class BackgroundService {
  Future<void> syncData() async {
    debugPrint("Syncing data in background...");
    final prefs = await SharedPreferences.getInstance();
    final String? spToken = prefs.getString(AppKeys.saleproSetupToken);
    final String? token = prefs.getString(AppKeys.loginKey);
    final String baseUrl =
        prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;

    if (token == null) return;

    // Assuming the endpoint is /api/offline-api-map
    // We need to construct the full URL for the map.
    // baseUrl usually ends with /api.

    String mapUrl = "$baseUrl/offline-api-map?token=$spToken";

    try {
      final response = await http.get(
        Uri.parse(mapUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      debugPrint("Sync response data: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('routes')) {
          final List<dynamic> routes = data['routes'];

          for (var route in routes) {
            if (route is String) {
              await _fetchAndSaveRoute(baseUrl, route, token, prefs);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error during sync: $e");
    }
  }

  Future<void> syncDataContext(
      void Function(int total, int progress) onUpdate) async {
    debugPrint("Syncing data in background...");
    final prefs = await SharedPreferences.getInstance();
    final String? spToken = prefs.getString(AppKeys.saleproSetupToken);
    final String? token = prefs.getString(AppKeys.loginKey);
    final String baseUrl =
        prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;

    if (token == null) return;

    // Assuming the endpoint is /api/offline-api-map
    // We need to construct the full URL for the map.
    // baseUrl usually ends with /api.

    String mapUrl = "$baseUrl/offline-api-map?token=$spToken";

    try {
      final response = await http.get(
        Uri.parse(mapUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      debugPrint("Sync response data: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('routes')) {
          final List<dynamic> routes = data['routes'];

          for (var route in routes) {
            if (route is String) {
              onUpdate(
                routes.length,
                routes.indexOf(route),
              );
              await _fetchAndSaveRoute(baseUrl, route, token, prefs);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error during sync: $e");
    }
  }

  Future<void> _fetchAndSaveRoute(String baseUrl, String route, String token,
      SharedPreferences prefs) async {
    String url;
    // Construct the full URL
    // If route starts with http, use it as is.
    if (route.startsWith("http")) {
      url = route;
    } else {
      String rootUrl = baseUrl;
      // Remove trailing slash from baseUrl if present
      if (rootUrl.endsWith("/")) {
        rootUrl = rootUrl.substring(0, rootUrl.length - 1);
      }

      // Now check for /api suffix
      if (rootUrl.endsWith("/api")) {
        rootUrl = rootUrl.substring(0, rootUrl.length - 4);
      }

      // Remove trailing slash again if present
      if (rootUrl.endsWith("/")) {
        rootUrl = rootUrl.substring(0, rootUrl.length - 1);
      }

      if (route.startsWith("/")) {
        url = "$rootUrl$route";
      } else {
        url = "$rootUrl/$route";
      }
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        // Generate key for SharedPreferences
        // Route: /api/dashboard -> basePath: /dashboard
        // Route: /api/user -> basePath: /user

        String basePath = route;
        if (basePath.startsWith("/api/")) {
          basePath = basePath.substring(5);
        } else if (basePath.startsWith("api/")) {
          basePath = basePath.substring(4);
        }

        // Remove leading slash if any
        if (basePath.startsWith("/")) {
          basePath = basePath.substring(1);
        }

        await prefs.setString('/$basePath', response.body);
      }
    } catch (e) {
      debugPrint("Failed to fetch $route: $e");
    }
  }
}
