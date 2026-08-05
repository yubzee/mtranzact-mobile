/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: biller
*/

import 'package:salepro/api/client.dart';
import 'package:salepro/models/mappable.dart';

class GeneralSetting implements Mappable {
  final int id;
  final String? siteTitle;
  final String? siteLogo;
  final bool? isRTL;
  final bool? disableSignUp;
  final bool? disableForgotPassword;
  final String? oneSignalAppId;

  GeneralSetting(
      {required this.id,
      this.siteTitle,
      this.siteLogo,
      this.isRTL,
      this.disableSignUp,
      this.disableForgotPassword,
      this.oneSignalAppId});

  factory GeneralSetting.fromJson(Map json) {
    return GeneralSetting(
      id: int.tryParse(json['id'].toString()) ?? 0,
      siteTitle: json['site_title'] ?? defaultAppName,
      siteLogo: json['site_logo'],
      isRTL: json['is_rtl'].toString() == '1' ||
          json['is_rtl'].toString() == 'true',
      disableSignUp: json['disable_sign_up'].toString() == '1' ||
          json['disable_sign_up'].toString() == 'true',
      disableForgotPassword:
          json['disable_forgot_password'].toString() == '1' ||
              json['disable_forgot_password'].toString() == 'true',
      oneSignalAppId: json['onesignal_api_key'],
    );
  }

  @override
  Mappable fromJson(Map<String, dynamic> json) => GeneralSetting.fromJson(json);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_title': siteTitle,
      'site_logo': siteLogo,
      'is_rtl': isRTL,
      'disable_sign_up': disableSignUp,
      'disable_forgot_password': disableForgotPassword,
      'onesignal_api_key': oneSignalAppId,
    };
  }

  @override
  Map<String, dynamic> toFormData() {
    return {
      'id': id,
      'site_title': siteTitle,
      'site_logo': siteLogo,
      'is_rtl': isRTL,
      'disable_sign_up': disableSignUp,
      'disable_forgot_password': disableForgotPassword,
      'onesignal_api_key': oneSignalAppId,
    };
  }
}
