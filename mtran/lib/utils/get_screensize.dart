/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: get_screensize
*/

import 'package:flutter/material.dart';

double getScreenSize(BuildContext context, {String type = "height"}) {
  if (type == "height") {
    return MediaQuery.of(context).size.height;
  } else {
    return MediaQuery.of(context).size.width;
  }
}
