import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:salepro/api/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salepro/constants/keys.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/debug_provider.dart';

class SubmissionService {
  static Map<String, dynamic> prepareFormData(Map<String, dynamic> data,
      Map<String, dynamic>? formSchema, Map<String, List<String>> files) {
    final Map<String, dynamic> result = {};
    final Map<String, String> fieldTypeMap = {};

    void extractFieldTypes(List<dynamic> fields, {String prefix = ''}) {
      for (final field in fields) {
        if (field is Map<String, dynamic>) {
          final String? type = field['type'];
          final String? name = field['name'];

          if (type != null && name != null) {
            final fullName = prefix.isEmpty ? name : '$prefix.$name';
            fieldTypeMap[fullName] = type;

            final baseName = fullName.replaceAll(RegExp(r'\[\d*\]$'), '');
            if (baseName != fullName) {
              fieldTypeMap[baseName] = type;
            }
          }

          if (type == 'group' && field['items'] is List) {
            extractFieldTypes(field['items'] as List<dynamic>, prefix: prefix);
          }
        }
      }
    }

    if (formSchema != null && formSchema['fields'] is List) {
      extractFieldTypes(formSchema['fields'] as List<dynamic>);
    }

    data.forEach((key, value) {
      if (files.containsKey(key)) {
        return;
      }

      dynamic processedValue = value;
      if (value is bool) {
        processedValue = value ? 1 : 0;
      }

      if (processedValue is String && processedValue.isEmpty) {
        final fieldType = fieldTypeMap[key];
        const nullableTypes = [
          'select',
          'date',
          'datetime',
          'datepicker',
          'daterangepicker',
          'time',
          'timepicker',
          'file',
          'number',
          'datagenerator',
        ];

        if (fieldType != null && nullableTypes.contains(fieldType)) {
          processedValue = null;
        }
      }

      final arrayMatch = RegExp(r"^([^\[]+)\[(\d+)\]$").firstMatch(key);
      if (arrayMatch != null) {
        final baseKey = arrayMatch.group(1)!;
        if (!result.containsKey(baseKey)) {
          result[baseKey] = [];
        }
        if (processedValue != null &&
            processedValue.toString().trim().isNotEmpty) {
          result[baseKey].add(processedValue);
        }
      } else {
        if (processedValue is List) {
          if (processedValue.isNotEmpty) {
            result[key] = processedValue;
          }
        } else {
          final shouldInclude = processedValue != null ||
              (processedValue == null && fieldTypeMap.containsKey(key));
          if (shouldInclude) {
            result[key] = processedValue;
          }
        }
      }
    });

    return result;
  }

  static Future<http.Response> uploadFiles({
    required Uri url,
    required Map<String, String> data,
    required Map<String, List<String>> fileData,
    required String method,
    String? token,
  }) async {
    var request = http.MultipartRequest("POST", url); // Always POST for files

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    request.fields.addAll(data);

    if (method.toUpperCase() == 'PUT' || method.toUpperCase() == 'PATCH') {
      request.fields['_method'] = method.toUpperCase();
    }

    for (var entry in fileData.entries) {
      final key = entry.key;
      final paths = entry.value;

      for (var path in paths) {
        var file = File(path);
        if (await file.exists()) {
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();
          var multipartFile = http.MultipartFile(
            key,
            stream,
            length,
            filename: path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }
    }

    var streamedResponse = await request.send();
    var responseBody = await streamedResponse.stream.bytesToString();
    return http.Response(responseBody, streamedResponse.statusCode);
  }

  static bool _hasFileFields(Map<String, dynamic>? formSchema) {
    if (formSchema == null) return false;
    final fields = formSchema['fields'];
    if (fields is! List) return false;

    bool found = false;
    void check(List<dynamic> list) {
      for (var f in list) {
        if (f is Map<String, dynamic>) {
          if (f['type'] == 'file') {
            found = true;
            return;
          }
          if (f['type'] == 'group' && f['items'] is List) {
            check(f['items']);
            if (found) return;
          }
        }
      }
    }

    check(fields);
    return found;
  }

  static Future<bool> submit({
    required String urlPath,
    required String method,
    required Map<String, dynamic> rawData,
    required Map<String, List<String>> files,
    Map<String, dynamic>? formSchema,
    BuildContext? context,
  }) async {
    final startTime = DateTime.now();
    String? requestId;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String serverUrl =
          prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
      String token = prefs.getString(AppKeys.loginKey) ?? "";

      final url = Uri.parse("$serverUrl$urlPath?token=$spToken");

      final data = prepareFormData(rawData, formSchema, files);

      bool isMultipart = files.isNotEmpty || _hasFileFields(formSchema);

      http.Response response;

      if (isMultipart) {
        // Filter data for multipart (convert to string, remove nulls)
        final Map<String, String> stringData = {};
        data.forEach((key, value) {
          if (value != null) {
            if (value is List || value is Map) {
              stringData[key] = jsonEncode(value);
            } else {
              stringData[key] = value.toString();
            }
          }
        });

        if (context != null) {
          requestId = context.read<DebugProvider>().logRequest(
                method: method,
                url: url.toString(),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Accept': 'application/json',
                },
                requestBody: jsonEncode(stringData),
              );
        }

        response = await uploadFiles(
          url: url,
          data: stringData,
          fileData: files,
          method: method,
          token: token,
        );
      } else {
        final headers = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        };

        final body = jsonEncode(data);

        if (context != null) {
          requestId = context.read<DebugProvider>().logRequest(
                method: method,
                url: url.toString(),
                headers: headers,
                requestBody: body,
              );
        }

        if (method.toUpperCase() == 'DELETE') {
          response = await http.delete(
            url,
            headers: headers,
          );
        } else if (method.toUpperCase() == 'PUT') {
          response = await http.put(
            url,
            headers: headers,
            body: body,
          );
        } else {
          // Default to POST
          response = await http.post(
            url,
            headers: headers,
            body: body,
          );
        }
      }

      if (context != null && requestId != null) {
        context.read<DebugProvider>().logResponse(
              id: requestId,
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseJson = jsonDecode(response.body);
        if (responseJson['success'] == true) {
          return true;
        }
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint("Submission Error: $e");
      debugPrint("Stack Trace: $stackTrace");
      if (context != null) {
        if (requestId != null) {
          context.read<DebugProvider>().logResponse(
                id: requestId,
                error: e.toString(),
                duration: DateTime.now().difference(startTime),
              );
        } else {
          // Log generic error if request wasn't even started/logged
          // We can't easily log a request here without more info, but we can try
        }
      }
      return false;
    }
  }
}
