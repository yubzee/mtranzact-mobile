/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: form_screen
*/

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/screens/debug_screen.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/app_loader.dart';
import 'package:salepro/widgets/drawer.dart';
import 'package:salepro/widgets/form.dart';

class FormScreen extends StatelessWidget {
  const FormScreen({
    super.key,
    required this.title,
    required this.buttonTitle,
    required this.onSubmit,
    required this.children,
    required this.serverUrl,
    this.scaffoldKey,
    this.padding,
    this.onRefresh,
    this.debugBar = false,
    this.actions,
    this.hideButton = false,
    this.showAppBar = true,
    this.background,
    this.centerItems = false,
    this.childrenAfterButton,
    this.apiUrl,
  });

  final String title;
  final String buttonTitle;
  final VoidCallback onSubmit;
  final List<Widget> children;
  final List<Widget>? childrenAfterButton;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final EdgeInsetsGeometry? padding;
  final Future<void> Function()? onRefresh;
  final bool debugBar;
  final List<Widget>? actions;
  final bool hideButton;
  final bool showAppBar;
  final Map<String, dynamic>? background;
  final String serverUrl;
  final bool centerItems;
  final String? apiUrl;

  @override
  Widget build(BuildContext context) {
    var container = Container(
      decoration: BoxDecoration(
        gradient: background != null && background!['gradient'] != null
            ? LinearGradient(
                colors: useThemeMode(
                  context,
                  light: ((background!['gradient']['light'] is Map
                              ? background!['gradient']['light']['colors']
                              : null) ??
                          background!['gradient']['colors'])
                      .map<Color>((colorString) => Color(int.parse(
                          colorString.toString().replaceFirst('#', '0xff'))))
                      .toList(),
                  dark: ((background!['gradient']['dark'] is Map
                              ? background!['gradient']['dark']['colors']
                              : null) ??
                          background!['gradient']['colors'])
                      .map<Color>((colorString) => Color(int.parse(
                          colorString.toString().replaceFirst('#', '0xff'))))
                      .toList(),
                ),
                begin: Alignment(
                  -1.0 *
                      cos(double.parse(
                              background!['gradient']['deg'].toString()) /
                          90.0),
                  -1.0 *
                      sin(double.parse(
                              background!['gradient']['deg'].toString()) /
                          90.0),
                ),
                end: Alignment(
                  1.0 *
                      cos(double.parse(
                              background!['gradient']['deg'].toString()) /
                          90.0),
                  1.0 *
                      sin(double.parse(
                              background!['gradient']['deg'].toString()) /
                          90.0),
                ),
              )
            : null,
        color: background != null &&
                background!['light'] != null &&
                background!['dark'] != null
            ? useThemeMode(
                context,
                light: Color(
                  int.parse(
                    background!['light']!.toString().replaceFirst('#', '0xff'),
                  ),
                ),
                dark: Color(
                  int.parse(
                    background!['dark']!.toString().replaceFirst('#', '0xff'),
                  ),
                ),
              )
            : null,
        image: background != null && background!['image'] != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  useThemeMode(context,
                      light: "$serverUrl${background!['image']['light']}",
                      dark: "$serverUrl${background!['image']['dark']}"),
                ),
                opacity: useThemeMode(
                  context,
                  light: 0.2,
                  dark: 0.5,
                ),
                fit: BoxFit.cover,
              )
            : null,
      ),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment:
            centerItems ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (!showAppBar)
            SafeArea(
              child: SizedBox(
                height: AppSpacing.kDefaultSpacing(context),
              ),
            ),
          if (background != null && showAppBar)
            AppBar(
              title: Text(title),
              actions: [
                if (actions != null) ...actions!,
                if (debugBar)
                  IconButton(
                    icon: IconMapper.icon(
                      'bug',
                      iconPack: context
                          .watch<CommonDataProvider>()
                          .currentThemeSetting!
                          .iconPack,
                    ),
                    tooltip: 'Debug Console',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugScreen(),
                        ),
                      );
                    },
                  ),
              ],
              backgroundColor: Colors.transparent,
            ),
          AppBanner(
            title:
                "Backing Up Data from the Server (${(context.watch<CommonDataProvider>().progressCount / context.watch<CommonDataProvider>().totalCount * 100).toStringAsFixed(0)}%)",
            show: context.watch<CommonDataProvider>().isSyncing,
            right: SizedBox(
              width: AppSpacing.kDefaultSpacing(context),
              height: AppSpacing.kDefaultSpacing(context),
              child: CircularProgressIndicator(
                color: AppColors.white,
              ),
            ),
          ),
          Expanded(
            child: LiquidPullToRefresh(
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade400.withValues(alpha: 0.2),
                dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
              ),
              backgroundColor: useThemeMode(
                context,
                light: getThemeColor(context),
                dark: getThemeColor(context)?.shade100,
              ),
              onRefresh: () async {
                if (onRefresh != null) {
                  await onRefresh!();
                }
              },
              child: Stack(
                children: [
                  Align(
                    alignment:
                        centerItems ? Alignment.center : Alignment.topCenter,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: AppForm(
                        buttonTitle: buttonTitle,
                        onSubmit: onSubmit,
                        padding: padding,
                        hideButton: hideButton,
                        childrenAfterButton: childrenAfterButton,
                        children: children,
                      ),
                    ),
                  ),
                  if (debugBar && !showAppBar)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(
                          AppSpacing.kDefaultSpacing(context),
                        ),
                        child: IconButton(
                          icon: IconMapper.icon(
                            'bug',
                            iconPack: context
                                .watch<CommonDataProvider>()
                                .currentThemeSetting!
                                .iconPack,
                          ),
                          tooltip: 'Debug Console',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DebugScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: Duration(
                        milliseconds: 500,
                      ),
                      color: context.watch<CommonDataProvider>().noInternet
                          ? AppColors.roseSwatch
                          : Colors.transparent,
                      padding: EdgeInsets.only(
                        bottom: AppSpacing.kDefaultSpacing(context) * 2,
                      ),
                      child: AppBanner(
                        title: "It seems like you are currently in Offline...",
                        color: AppColors.roseSwatch,
                        show: context.watch<CommonDataProvider>().noInternet,
                        right: SizedBox(
                          height: AppSpacing.kDefaultSpacing(context),
                          child: IconMapper.icon(
                            'warning',
                            iconPack: context
                                .watch<CommonDataProvider>()
                                .currentThemeSetting
                                ?.iconPack,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return AppLoader(
      child: Scaffold(
        key: scaffoldKey,
        appBar: !showAppBar || background != null
            ? null
            : AppBar(
                title: Text(title),
                actions: [
                  if (actions != null) ...actions!,
                  if (debugBar)
                    IconButton(
                      icon: IconMapper.icon(
                        'bug',
                        iconPack: context
                            .watch<CommonDataProvider>()
                            .currentThemeSetting!
                            .iconPack,
                      ),
                      tooltip: 'Debug Console',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DebugScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
        drawer: showAppBar
            ? AppDrawer(
                activeLink: apiUrl,
              )
            : null,
        backgroundColor: background != null &&
                background!['light'] != null &&
                background!['dark'] != null
            ? useThemeMode(
                context,
                light: Color(
                  int.parse(
                    background!['light']!.toString().replaceFirst('#', '0xff'),
                  ),
                ),
                dark: Color(
                  int.parse(
                    background!['dark']!.toString().replaceFirst('#', '0xff'),
                  ),
                ),
              )
            : null,
        body: centerItems
            ? Center(
                child: container.animate().fade(
                      duration: Duration(
                        seconds: 1,
                      ),
                      curve: Curves.easeInOutExpo,
                    ),
              )
            : container.animate().fade(
                  duration: Duration(
                    seconds: 1,
                  ),
                  curve: Curves.easeInOutExpo,
                ),
      ),
    );
  }
}
