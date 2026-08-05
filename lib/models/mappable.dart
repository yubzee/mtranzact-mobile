/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: mappable
*/

abstract class Mappable {
  Mappable fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toMap();
  Map<String, dynamic> toFormData();
}
