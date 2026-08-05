/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: drawer
*/

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/models/nav_link.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_app_logo.dart';
import 'package:salepro/utils/get_nav_link.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/utils/icon_mapper.dart';

Color? _parseHexColor(dynamic value) {
  if (value == null) return null;

  String hex = value.toString().trim();
  if (hex.isEmpty) return null;

  // Accept: "#RRGGBB", "RRGGBB", "#AARRGGBB", "AARRGGBB", "0xAARRGGBB".
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.startsWith('#')) hex = hex.substring(1);

  if (hex.length == 6) {
    hex = 'FF$hex';
  }

  if (hex.length != 8) return null;

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

String? _normalizeLinkExact(String? link) {
  if (link == null) return null;
  String value = link.trim();
  if (value.isEmpty) return null;

  // If a full URL is provided, only use its path.
  if (value.contains('://')) {
    final uri = Uri.tryParse(value);
    if (uri != null) {
      value = uri.path;
    }
  }

  // Drop query/hash.
  value = value.split('?').first.split('#').first;

  // Normalize slashes.
  if (!value.startsWith('/')) value = '/$value';
  while (value.length > 1 && value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }

  // Normalize API prefix (drawer items can be non-api URLs).
  if (value.startsWith('/api/')) {
    value = value.substring(4);
  }

  return value;
}

String? _normalizeLinkBase(String? link) {
  final exact = _normalizeLinkExact(link);
  if (exact == null) return null;

  String value = exact;

  // Normalize common CRUD suffixes.
  final crudSuffixes = <String>['/create', '/edit', '/update'];
  for (final suffix in crudSuffixes) {
    if (value.endsWith(suffix)) {
      value = value.substring(0, value.length - suffix.length);
      break;
    }
  }

  // Normalize "/{id}/edit" and "/{id}" patterns.
  final segments = value.split('/')..removeWhere((s) => s.isEmpty);
  if (segments.isEmpty) return '/';

  if (segments.length >= 2 && segments.last == 'edit') {
    final maybeId = segments[segments.length - 2];
    if (int.tryParse(maybeId) != null) {
      segments.removeLast(); // edit
      segments.removeLast(); // id
    }
  } else if (int.tryParse(segments.last) != null) {
    segments.removeLast();
  }

  if (segments.isEmpty) return '/';
  return '/${segments.join('/')}';
}

Set<String> _collectExactSidebarLinks(List<NavLink> navLinks) {
  final Set<String> links = <String>{};

  void visit(NavLink link) {
    final path = _normalizeLinkExact(link.path);
    final apiUrl = _normalizeLinkExact(link.apiUrl);
    if (path != null) links.add(path);
    if (apiUrl != null) links.add(apiUrl);

    if (link.group == true && link.links != null && link.links!.isNotEmpty) {
      for (final child in link.links!) {
        visit(child);
      }
    }
  }

  for (final link in navLinks) {
    visit(link);
  }

  return links;
}

bool _navLinkMatchesActive(
  String? activeLink,
  NavLink navLink,
  Set<String> availableExactSidebarLinks,
) {
  final String? activeExact = _normalizeLinkExact(activeLink);
  if (activeExact == null) return false;
  final String activeBase = _normalizeLinkBase(activeLink) ?? activeExact;
  final bool hasExactSidebarItemForActive =
      availableExactSidebarLinks.contains(activeExact);

  final candidates = <String?>[
    navLink.path,
    navLink.apiUrl,
  ];

  for (final candidate in candidates) {
    final String? candidateExact = _normalizeLinkExact(candidate);
    if (candidateExact == null) continue;

    // 1) Exact match: highlight exact route (so /demo doesn't highlight /demo/create).
    if (candidateExact == activeExact) return true;

    // 2) Base match: allow create/edit/id pages to highlight their parent list route.
    //    Only apply this for "base" sidebar items (not for /create links).
    final String candidateBase =
        _normalizeLinkBase(candidate) ?? candidateExact;
    final bool isBaseSidebarLink = candidateExact == candidateBase;
    // If the exact active route exists in the sidebar (e.g. /demo/create),
    // do not also highlight its parent (/demo).
    if (hasExactSidebarItemForActive) continue;

    if (isBaseSidebarLink && candidateBase == activeBase) return true;
  }

  return false;
}

Color _sidebarTextColor(
  BuildContext context, {
  required bool isActive,
  required bool isSubItem,
}) {
  final sidebar = context.read<CommonDataProvider>().sidebar;

  final String lightKey = isSubItem
      ? (isActive
          ? 'sidebar_subitem_active_color'
          : 'sidebar_subitem_inactive_color')
      : (isActive
          ? 'sidebar_item_active_color'
          : 'sidebar_item_inactive_color');

  final String darkKey = isSubItem
      ? (isActive
          ? 'sidebar_subitem_active_dark_color'
          : 'sidebar_subitem_inactive_dark_color')
      : (isActive
          ? 'sidebar_item_active_dark_color'
          : 'sidebar_item_inactive_dark_color');

  final Color? lightOverride = _parseHexColor(sidebar[lightKey]);
  final Color? darkOverride = _parseHexColor(sidebar[darkKey]);

  final Color fallbackLight = isSubItem
      ? (isActive
          ? getThemeColor(context)!.shade500
          : getThemeColor(context)!.shade900.withValues(alpha: 0.7))
      : (isActive
          ? getThemeColor(context)!.shade700
          : getThemeColor(context)!.shade900);

  final Color fallbackDark = isSubItem
      ? (isActive
          ? getThemeColor(context)!.shade300
          : getThemeColor(context)!.shade100.withValues(alpha: 0.7))
      : (isActive
          ? getThemeColor(context)!.shade300
          : getThemeColor(context)!.shade100);

  return useThemeMode(
    context,
    light: lightOverride ?? fallbackLight,
    dark: darkOverride ?? fallbackDark,
  );
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.activeLink});

  final String? activeLink;

  @override
  Widget build(BuildContext context) {
    final rawDrawer =
        (context.watch<CommonDataProvider>().sidebar['drawer'] as List?) ??
            const [];

    final List<NavLink> navLinks = rawDrawer
        .whereType<Map>()
        .map<NavLink>((d) => NavLink.fromJson(d))
        .toList();

    final availableExactSidebarLinks = _collectExactSidebarLinks(navLinks);

    return Drawer(
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.7,
      shape: RoundedRectangleBorder(
        borderRadius: context
                        .watch<CommonDataProvider>()
                        .sidebar['sidebar_corner'] !=
                    null &&
                context.watch<CommonDataProvider>().sidebar['sidebar_corner'] ==
                    'rounded'
            ? BorderRadius.only(
                topRight: getThemeBorderRadius(context) >
                        AppSpacing.kDefaultSpacing(context) * 5
                    ? getThemeRadius(context, intensity: 'medium') * 0.125
                    : getThemeRadius(context, intensity: 'high'),
                bottomRight: getThemeBorderRadius(context) >
                        AppSpacing.kDefaultSpacing(context) * 5
                    ? getThemeRadius(context, intensity: 'medium') * 0.125
                    : getThemeRadius(context, intensity: 'high'),
              )
            : BorderRadius.zero,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: useThemeMode(
            context,
            light: AppColors.white.withValues(
              alpha: 0.95,
            ),
            dark: Colors.black.withValues(
              alpha: 0.95,
            ),
          ),
          borderRadius:
              context.watch<CommonDataProvider>().sidebar['sidebar_corner'] !=
                          null &&
                      context
                              .watch<CommonDataProvider>()
                              .sidebar['sidebar_corner'] ==
                          'rounded'
                  ? BorderRadius.only(
                      topRight: getThemeBorderRadius(context) >
                              AppSpacing.kDefaultSpacing(context) * 5
                          ? getThemeRadius(context, intensity: 'medium') * 0.125
                          : getThemeRadius(context, intensity: 'high'),
                      bottomRight: getThemeBorderRadius(context) >
                              AppSpacing.kDefaultSpacing(context) * 5
                          ? getThemeRadius(context, intensity: 'medium') * 0.125
                          : getThemeRadius(context, intensity: 'high'),
                    )
                  : null,
          boxShadow: [
            BoxShadow(
              color: isDark(context)
                  ? Colors.black.withValues(alpha: 0.4)
                  : AppColors.slateSwatch.withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          top: AppSpacing.kDefaultSpacing(context),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: AppSpacing.kDefaultSpacing(context) * 4.5,
                padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
                child: hasNetworkLogo(context)
                    ? CachedNetworkImage(
                        imageUrl: getAppLogo(context)!,
                        height: AppSpacing.kDefaultSpacing(context) * 3,
                        errorWidget: (context, error, stackTrace) =>
                            Image.asset(
                          getAppLogo(context, useNetworkLogo: false)!,
                          height: AppSpacing.kDefaultSpacing(context) * 3,
                        ),
                      ).animate().fadeIn(
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        )
                    : Image.asset(
                        getAppLogo(context, useNetworkLogo: false)!,
                        height: AppSpacing.kDefaultSpacing(context) * 3,
                      ).animate().fadeIn(
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: navLinks.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == navLinks.length - 1) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: AppSpacing.kDefaultSpacing(context) * 2,
                        ),
                        child: DrawerCard(
                          navLink: navLinks[index],
                          type: "navlink",
                          activeLink: activeLink,
                          availableExactSidebarLinks:
                              availableExactSidebarLinks,
                        ),
                      );
                    } else {
                      return DrawerCard(
                        navLink: navLinks[index],
                        type: "navlink",
                        activeLink: activeLink,
                        availableExactSidebarLinks: availableExactSidebarLinks,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerCard extends StatelessWidget {
  const DrawerCard(
      {super.key,
      required this.navLink,
      required this.type,
      required this.availableExactSidebarLinks,
      this.activeLink});

  final NavLink navLink;
  final String type;
  final String? activeLink;
  final Set<String> availableExactSidebarLinks;

  @override
  Widget build(BuildContext context) {
    final bool isSubItem = type == "sublink" || type == "subsublink";
    final bool isActive =
        _navLinkMatchesActive(activeLink, navLink, availableExactSidebarLinks);
    final bool isGroupActive = navLink.group == true &&
        activeLink != null &&
        (navLink.links?.any((link) => _navLinkMatchesActive(
                activeLink, link, availableExactSidebarLinks)) ??
            false);

    switch (navLink.group) {
      case true:
        final Color groupColor = _sidebarTextColor(
          context,
          isActive: isGroupActive,
          isSubItem: isSubItem,
        );

        return ExpansionTile(
          initiallyExpanded: isGroupActive,
          visualDensity: type == "sublink" || type == "subsublink"
              ? const VisualDensity(vertical: VisualDensity.minimumDensity)
              : VisualDensity.compact,
          title: Text(
            navLink.title,
            style: TextStyle(
              fontSize: type == "sublink" || type == "subsublink"
                  ? AppSpacing.kDefaultSpacing(context) * 0.9
                  : AppSpacing.kDefaultSpacing(context),
              fontWeight: isGroupActive ? FontWeight.w900 : FontWeight.w600,
              color: groupColor,
            ),
          ),
          leading: type == "sublink" || type == "subsublink"
              ? Padding(
                  padding: type == "subsublink"
                      ? EdgeInsets.all(AppSpacing.kDefaultSpacing(context))
                      : EdgeInsets.zero,
                )
              : DrawerIcon(
                  icon: navLink.iconKey,
                  color: groupColor,
                ),
          backgroundColor: isGroupActive
              ? useThemeMode(
                  context,
                  light: groupColor.withValues(alpha: 0.06),
                  dark: groupColor.withValues(alpha: 0.10),
                )
              : null,
          collapsedBackgroundColor: null,
          children: navLink.links!
              .map(
                (link) => DrawerCard(
                  navLink: link,
                  type: type == "sublink" || type == "subsublink"
                      ? "subsublink"
                      : "sublink",
                  activeLink: activeLink,
                  availableExactSidebarLinks: availableExactSidebarLinks,
                ),
              )
              .toList(),
        );
      default:
        final Color itemColor = _sidebarTextColor(
          context,
          isActive: isActive,
          isSubItem: isSubItem,
        );

        final Color? activeBackground = isActive
            ? useThemeMode(
                context,
                light: itemColor.withValues(alpha: 0.06),
                dark: itemColor.withValues(alpha: 0.12),
              )
            : null;

        return ListTile(
          visualDensity: type == "sublink" || type == "subsublink"
              ? const VisualDensity(vertical: VisualDensity.minimumDensity)
              : VisualDensity.compact,
          selected: isActive,
          tileColor: activeBackground,
          onTap: navLink.onTap != null
              ? () {
                  navLink.onTap!(context);
                }
              : () {
                  if (navLink.path != null && navLink.screen == null) {
                    if (navLink.replaceScreen == false) {
                      Navigator.of(context).pushNamed(navLink.path!);
                    } else {
                      Navigator.of(context).pushReplacementNamed(navLink.path!);
                    }
                  } else if (navLink.path == null && navLink.screen != null) {
                    if (navLink.replaceScreen == false) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => navLink.screen!),
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (ctx) => navLink.screen!),
                      );
                    }
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => getNavScreen(context, navLink),
                      ),
                    );
                  }
                },
          title: Text(
            navLink.title,
            style: TextStyle(
              fontSize: type == "sublink" || type == "subsublink"
                  ? AppSpacing.kDefaultSpacing(context) * 0.9
                  : AppSpacing.kDefaultSpacing(context),
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              color: itemColor,
            ),
          ),
          leading: type == "sublink" || type == "subsublink"
              ? Padding(
                  padding: type == "subsublink"
                      ? EdgeInsets.all(
                          AppSpacing.kDefaultSpacing(context) * 2,
                        )
                      : EdgeInsets.zero,
                )
              : DrawerIcon(
                  icon: navLink.iconKey,
                  color: itemColor,
                ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 0,
            horizontal: AppSpacing.kDefaultSpacing(context),
          ),
        );
    }
  }
}

class DrawerIcon extends StatelessWidget {
  const DrawerIcon({super.key, this.icon, required this.color});
  final dynamic icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return IconMapper.icon(
      icon,
      iconPack: iconPack,
      color: color,
      size: AppSpacing.kDefaultSpacing(context) * 1.9,
    );
  }
}

class AppDrawerIcon extends StatelessWidget {
  const AppDrawerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: IconMapper.icon(
        'drawer',
        iconPack:
            context.watch<CommonDataProvider>().currentThemeSetting?.iconPack,
      ),
      onPressed: () => Scaffold.of(context).openDrawer(),
    );
  }
}
