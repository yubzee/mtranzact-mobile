/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: message
*/

class Message {
  final bool success;
  final String message;
  final Map<String, dynamic>? errors;
  final dynamic data;
  final String? action;
  final bool invalidToken;
  final bool invalidLicenseToken;
  final String? navigateUrl;
  final String? navigateType;
  final Map? navigateParams;
  final bool debugBar;
  final String? invoiceDataUrl;
  final String? invoiceUrl;
  final Map<String, dynamic>? invoiceData;

  Message({
    required this.success,
    required this.message,
    required this.invalidToken,
    required this.invalidLicenseToken,
    this.errors,
    this.data,
    this.action,
    this.navigateUrl,
    this.navigateType,
    this.navigateParams,
    this.debugBar = false,
    this.invoiceDataUrl,
    this.invoiceUrl,
    this.invoiceData,
  });

  factory Message.fromJson(Map json) {
    return Message(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      errors: json['errors'],
      data: json['data'],
      invalidToken: json['invalid_token'] ??
          json['message']
              .toString()
              .toLowerCase()
              .contains('unauthenticated') ??
          false,
      invalidLicenseToken: json['invalid_license_token'] ?? false,
      navigateUrl: json['navigate_url'],
      action: json['action'],
      navigateType: json['navigate_type'],
      navigateParams: json['navigate_params'],
      debugBar: json['debug_bar'] ?? false,
      invoiceDataUrl: json['invoice_data_url'],
      invoiceUrl: json['invoice_url'],
      invoiceData: json['invoice_data'],
    );
  }
}
