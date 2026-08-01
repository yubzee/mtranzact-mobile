import 'package:flutter/foundation.dart';

class ApiLog {
  final String id;
  final String method;
  final String url;
  final Map<String, String>? headers;
  final String? requestBody;
  final int? statusCode;
  final String? responseBody;
  final DateTime timestamp;
  final Duration? duration;
  final String? error;

  ApiLog({
    required this.id,
    required this.method,
    required this.url,
    this.headers,
    this.requestBody,
    this.statusCode,
    this.responseBody,
    required this.timestamp,
    this.duration,
    this.error,
  });

  String get status {
    if (error != null) return 'Error';
    if (statusCode == null) return 'Pending';
    if (statusCode! >= 200 && statusCode! < 300) return 'Success';
    if (statusCode! >= 400) return 'Failed';
    return 'Unknown';
  }

  String get displayUrl {
    try {
      final uri = Uri.parse(url);
      return uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
    } catch (e) {
      return url;
    }
  }
}

class DebugProvider with ChangeNotifier {
  final List<ApiLog> _apiLogs = [];
  int _requestCounter = 0;

  List<ApiLog> get apiLogs => List.unmodifiable(_apiLogs);

  String _generateId() {
    _requestCounter++;
    return 'req_$_requestCounter';
  }

  /// Log a new API request
  String logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? requestBody,
  }) {
    final id = _generateId();
    final log = ApiLog(
      id: id,
      method: method,
      url: url,
      headers: headers,
      requestBody: requestBody,
      timestamp: DateTime.now(),
    );

    _apiLogs.insert(0, log); // Add to beginning
    notifyListeners();
    return id;
  }

  /// Update an existing log with response data
  void logResponse({
    required String id,
    int? statusCode,
    String? responseBody,
    Duration? duration,
    String? error,
  }) {
    final index = _apiLogs.indexWhere((log) => log.id == id);
    if (index == -1) return;

    final oldLog = _apiLogs[index];
    _apiLogs[index] = ApiLog(
      id: oldLog.id,
      method: oldLog.method,
      url: oldLog.url,
      headers: oldLog.headers,
      requestBody: oldLog.requestBody,
      statusCode: statusCode,
      responseBody: responseBody,
      timestamp: oldLog.timestamp,
      duration: duration,
      error: error,
    );

    notifyListeners();
  }

  /// Clear all logs
  void clearLogs() {
    _apiLogs.clear();
    _requestCounter = 0;
    notifyListeners();
  }

  /// Remove logs older than specified duration
  void clearOldLogs({Duration maxAge = const Duration(hours: 1)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    _apiLogs.removeWhere((log) => log.timestamp.isBefore(cutoff));
    notifyListeners();
  }
}
