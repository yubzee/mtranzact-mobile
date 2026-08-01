import 'package:flutter/material.dart';
import 'package:salepro/constants/nav_links.dart';
import 'package:salepro/models/nav_link.dart';
import 'package:salepro/widgets/action_screen.dart';
import 'package:salepro/widgets/dynamic_form_screen.dart';
import 'package:salepro/widgets/data_table.dart';
import 'package:salepro/widgets/tabbed_data_table.dart';
import 'package:salepro/widgets/custom_view_screen.dart';
import 'package:salepro/widgets/under_development.dart';
import 'package:salepro/widgets/webview_screen.dart';

Widget getNavScreen(BuildContext context, NavLink nav) {
  // Case 1: If it's a custom action (logout etc.)
  if (nav.action != null && customActions.containsKey(nav.action)) {
    return ActionScreen(
      action: customActions[nav.action]!,
      params: nav.params,
    );
  }

  // Case 2: If it's a custom screen
  if (nav.action != null && customScreens.containsKey(nav.action)) {
    return customScreens[nav.action]!;
  }

  // Case 3: Form
  if (nav.apiUrl != null && nav.type.toString().toLowerCase() == "form") {
    return DynamicFormScreen(
      title: nav.title,
      apiUrl: nav.apiUrl ?? "",
      params: nav.params,
    );
  }

  // Case 4: Dynamic List
  if (nav.apiUrl != null && nav.type.toString().toLowerCase() == "datatable") {
    return DataTableScreen(
      apiUrl: nav.apiUrl!,
      title: nav.title,
      params: nav.params,
    );
  }

  // Case 5: Custom View (for reports, charts, balance sheets, etc.)
  if (nav.apiUrl != null && nav.type.toString().toLowerCase() == "custom") {
    return CustomViewScreen(
      apiUrl: nav.apiUrl!,
      title: nav.title,
      params: nav.params,
    );
  }

  // Case 6: Webview Screen
  if (nav.apiUrl != null && nav.type.toString().toLowerCase() == "webview") {
    return WebviewScreen(
      url: nav.apiUrl!,
      title: nav.title,
      params: nav.params,
    );
  }

  // Case 7: Dynamic Tabbed List
  if (nav.apiUrl != null &&
      nav.type.toString().toLowerCase() == "tabbeddatatable") {
    return TabbedDataTableScreen(
      apiUrl: nav.apiUrl!,
      title: nav.title,
      params: nav.params,
    );
  }

  return UnderDevelopmentScreen(params: nav.params);
}
