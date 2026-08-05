import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/models/invoice_data.dart';
import 'package:flutter/cupertino.dart';

class InvoiceService {
  Future<InvoiceData?> fetchInvoiceData(int saleId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String apiUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? '';
    String? token = prefs.getString(AppKeys.loginKey);

    if (token == null) {
      debugPrint("Token not found");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/pos/invoice-data/$saleId?token=$spToken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return InvoiceData.fromJson(jsonDecode(response.body));
      } else {
        debugPrint("Failed to fetch invoice data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching invoice data: $e");
      return null;
    }
  }
}
