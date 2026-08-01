/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: data
*/

import 'package:salepro/models/mappable.dart';
import 'package:salepro/utils/create_model_from_map.dart';

class Data<T extends Mappable> {
  final bool requirePagination;
  final List<T> data;
  final bool invalidToken;

  Data({
    required this.requirePagination,
    required this.data,
    required this.invalidToken,
  });

  factory Data.fromJson(Map json, T Function(Map<String, dynamic>) fromJson) {
    return Data(
      requirePagination: json['require_pagination'] ?? false,
      data: json['data'] is List
          ? createModelFromMap(
              json['data'],
              fromJson,
            )
          : [],
      invalidToken: json['invalid_token'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'require_pagination': requirePagination,
      'data': createMapFromModel(data),
      'invalid_token': invalidToken,
    };
  }
}
