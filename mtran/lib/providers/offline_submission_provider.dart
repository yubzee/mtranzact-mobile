import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:salepro/models/offline_submission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:salepro/services/submission_service.dart';

class OfflineSubmissionProvider with ChangeNotifier {
  List<OfflineSubmission> _submissions = [];
  List<OfflineSubmission> get submissions => _submissions;
  final Set<String> _syncingIds = {};

  static const String _storageKey = 'offline_submissions';

  OfflineSubmissionProvider() {
    loadSubmissions();
    _initConnectivity();
  }

  bool isSyncing(String id) => _syncingIds.contains(id);

  void _initConnectivity() async {
    // Check initial status
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      syncSubmissions();
    }

    // Listen for changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        syncSubmissions();
      }
    });
  }

  Future<void> syncSubmissions([BuildContext? context]) async {
    if (_submissions.isEmpty) return;

    // Sync oldest first
    final List<OfflineSubmission> toSync = List.from(_submissions);
    toSync.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final sub in toSync) {
      if (_syncingIds.contains(sub.id)) continue;

      _syncingIds.add(sub.id);
      notifyListeners();

      try {
        final success = await SubmissionService.submit(
          urlPath: sub.url,
          method: sub.method,
          rawData: sub.data,
          files: sub.files,
          formSchema: sub.formSchema,
          context: context,
        );

        if (success) {
          await removeSubmission(sub.id);
        } else {}
      } catch (e) {
        debugPrint("Error in sync loop for ${sub.id}: $e");
      } finally {
        _syncingIds.remove(sub.id);
        notifyListeners();
      }
    }
  }

  Future<void> loadSubmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _submissions =
          jsonList.map((e) => OfflineSubmission.fromJson(e)).toList();
      // Sort by timestamp descending (newest first)
      _submissions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> addSubmission(OfflineSubmission submission) async {
    _submissions.insert(0, submission);
    await _saveSubmissions();
    notifyListeners();
  }

  Future<void> removeSubmission(String id) async {
    _submissions.removeWhere((element) => element.id == id);
    await _saveSubmissions();
    notifyListeners();
  }

  Future<void> _saveSubmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
        jsonEncode(_submissions.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
