/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: create_model_from_map
*/

import 'package:salepro/models/mappable.dart';

List<T> createModelFromMap<T extends Mappable>(
  List data,
  T Function(Map<String, dynamic>) fromJson,
) {
  return data.map((item) => fromJson(item)).toList();
}

List<Map<String, dynamic>> createMapFromModel<T extends Mappable>(
  List<T> data,
) {
  return data.map((item) => item.toMap()).toList();
}
