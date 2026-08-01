/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: control_loading
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';

class Loading {
  static Future<void> start(BuildContext context) async {
    await context.read<CommonDataProvider>().setLoading(true);
  }

  static Future<void> stop(BuildContext context) async {
    await context.read<CommonDataProvider>().setLoading(false);
  }
}
