/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: create_select_input_data
*/

import 'package:salepro/models/data.dart';
import 'package:salepro/models/mappable.dart';

List<Map<String, dynamic>> selectData<T extends Mappable>(List<T> data,
    {String labelField = "name",
    String valueField = "id",
    Future<Data<Mappable>> Function()? fetchMethod}) {
  if (data.isEmpty && fetchMethod != null) {
    fetchMethod();
  }
  return data.map((item) {
    final map = item.toMap();
    if (map.containsKey(labelField) && map.containsKey(valueField)) {
      return {
        'label': map[labelField].toString(),
        'value': map[valueField].toString(),
      };
    } else {
      throw ArgumentError(
          'Fields "$labelField" and "$valueField" do not exist in the object. ${item.toMap()}');
    }
  }).toList();
}

List<Map<String, dynamic>> selectDataFromBody(
  List data, {
  String labelField = "label",
  String valueField = "value",
  String? logicField,
}) {
  return data.map((map) {
    if (map.containsKey(labelField) && map.containsKey(valueField)) {
      return {
        'label': map[labelField].toString(),
        'value': map[valueField].toString(),
        'logic': logicField != null ? map[logicField].toString() : null,
      };
    } else {
      throw ArgumentError(
          'Fields "$labelField" and "$valueField" do not exist in the object.');
    }
  }).toList();
}
