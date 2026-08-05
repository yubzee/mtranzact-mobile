/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: nav_link
*/

import 'package:flutter/material.dart';
import 'package:salepro/constants/nav_links.dart';

class NavLink {
  final String title;
  final String? type;
  final String? iconKey;
  final bool group;
  final List<NavLink>? links;
  final Function(BuildContext context)? onTap;
  final String? path;
  final bool replaceScreen;
  final Widget? screen;
  final String? apiUrl;
  final String? action;
  final Map? params;

  static const String materialIcon = "materialicon";
  static const String fontAwesomeIcon = "fontawesome";
  static const String heroIcon = "heroicon";
  static const String solarIcon = "solaricon";

  NavLink({
    this.onTap,
    this.type,
    this.path,
    this.replaceScreen = false,
    required this.title,
    this.iconKey,
    required this.group,
    this.screen,
    this.links,
    this.action,
    this.apiUrl,
    this.params,
  });

  factory NavLink.fromJson(Map json) {
    final String? key = json['icon']?.toString();
    return NavLink(
      type: json['type'],
      path: json['path'],
      replaceScreen: json['replace_screen'] ?? false,
      title: json['title'],
      iconKey: key,
      group: json['group'] ?? false,
      screen: customScreens[json['screen']],
      links: (json['links'] as List?)
          ?.map((link) => NavLink.fromJson(link))
          .toList(),
      action: json['action'],
      apiUrl: json['api_url'],
      params: json['params'],
    );
  }
}
