/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: select
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_screensize.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_input_design.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';

class AppSelect extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.hintText,
    this.prefix,
    this.icon,
    this.info,
    this.showInfoIcon = true,
    this.actionIcon = 'plus-circle',
    this.onAction,
    this.screenToOpenOnSuffixTap,
    this.enableFilter = true,
    this.enableSearch = true,
    required this.items,
    required this.onChange,
    this.value,
    this.gradient = false,
    this.glass = false,
    this.errorLine,
    this.logicBuilder,
  });

  final String hintText;
  final Widget? prefix;

  /// Prefer passing an IconMapper key (String). Non-string values will fall back.
  final String? icon;
  final String? info;
  final bool showInfoIcon;
  final String actionIcon;
  final VoidCallback? onAction;
  final Widget? screenToOpenOnSuffixTap;
  final bool enableFilter;
  final bool enableSearch;
  final List<Map<String, dynamic>> items;
  final String? value;
  final void Function(String? value) onChange;
  final Map<String, dynamic>? Function(Map<String, dynamic> value)?
      logicBuilder;
  final bool gradient;
  final bool glass;
  final List? errorLine;

  @override
  Widget build(BuildContext context) {
    final bool outlinedInput = isOutlinedThemeInput(context);
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.kDefaultSpacing(context) * 0.8,
            vertical: AppSpacing.kDefaultSpacing(context) * 0.3,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              width: outlinedInput ? 1 : 0.5,
              color: useThemeMode(
                context,
                light: errorLine != null
                    ? AppColors.roseSwatch
                    : (glass
                        ? getThemeColor(context)?.shade100.withValues(
                              alpha: outlinedInput ? 0.35 : 0.2,
                            )
                        : getThemeColor(context)?.shade500.withValues(
                              alpha: outlinedInput ? 0.65 : 0.5,
                            )),
                dark: errorLine != null
                    ? AppColors.roseSwatch.shade400
                    : getThemeColor(context)?.shade100.withValues(
                          alpha: outlinedInput ? 0.65 : 0.5,
                        ),
              ),
            ),
            color: outlinedInput
                ? (glass
                    ? useThemeMode(
                        context,
                        light: Colors.white.withValues(alpha: 0.2),
                        dark: Colors.white.withValues(alpha: 0.08),
                      )
                    : Colors.transparent)
                : (glass
                    ? useThemeMode(
                        context,
                        light: Colors.white.withValues(alpha: 0.6),
                        dark: Colors.white.withValues(alpha: 0.1),
                      )
                    : useThemeMode(
                        context,
                        light: gradient
                            ? getThemeColor(context)
                                ?.shade100
                                .withValues(alpha: 0.9)
                            : getThemeColor(context)
                                ?.shade50
                                .withValues(alpha: 0.5),
                        dark: gradient
                            ? getThemeColor(context)
                                ?.shade900
                                .withValues(alpha: 0.9)
                            : getThemeColor(context)
                                ?.shade50
                                .withValues(alpha: 0.1),
                      )),
            borderRadius: getThemeBorderRadiusCircular(context),
            boxShadow: (!outlinedInput && gradient)
                ? [
                    BoxShadow(
                      color: useThemeMode(
                        context,
                        light: getThemeColor(context)
                            ?.shade100
                            .withValues(alpha: 0.25),
                        dark: getThemeColor(context)
                            ?.shade900
                            .withValues(alpha: 0.5),
                      ),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                flex: showInfoIcon &&
                        info != null &&
                        (onAction != null || screenToOpenOnSuffixTap != null)
                    ? 3
                    : 6,
                child: DropdownMenu(
                  initialSelection: value,
                  menuHeight: getScreenSize(context) * 0.7,
                  onSelected: (data) {
                    onChange('$data');
                  },
                  enableFilter: enableFilter,
                  enableSearch: enableSearch,
                  searchCallback: enableSearch
                      ? (entries, String query) {
                          if (query.isEmpty) {
                            return null;
                          }

                          final int index = entries.indexWhere(
                            (entry) => entry.label.toLowerCase().contains(
                                  query.trim().toLowerCase(),
                                ),
                          );

                          return index != -1 ? index : null;
                        }
                      : null,
                  filterCallback: enableFilter
                      ? (entries, String filter) {
                          final String trimmedFilter =
                              filter.trim().toLowerCase();
                          if (trimmedFilter.isEmpty) {
                            return entries;
                          }
                          return entries
                              .where(
                                (entry) => entry.label
                                    .toLowerCase()
                                    .contains(trimmedFilter),
                              )
                              .toList();
                        }
                      : null,
                  width: getScreenSize(context, type: 'width') -
                      AppSpacing.kDefaultSpacing(context) * 3.5,
                  textStyle: TextStyle(
                    fontSize: AppSpacing.kDefaultSpacing(context),
                    fontFamily: getThemeFont(context),
                  ),
                  menuStyle: MenuStyle(
                    elevation: const WidgetStatePropertyAll(4),
                    visualDensity: VisualDensity.comfortable,
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: getThemeBorderRadiusCircular(
                          context,
                          intensity: 'low',
                        ),
                      ),
                    ),
                  ),
                  hintText: "Select $hintText",
                  label: gradient ? null : Text(hintText),
                  inputDecorationTheme: InputDecorationTheme(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: gradient
                          ? AppSpacing.kDefaultSpacing(context)
                          : AppSpacing.kDefaultSpacing(context) * 0.5,
                      horizontal: AppSpacing.kDefaultSpacing(context),
                    ),
                    labelStyle: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context),
                      fontFamily: getThemeFont(context),
                      color: useThemeMode(
                        context,
                        light: errorLine != null
                            ? AppColors.roseSwatch
                            : glass
                                ? AppColors.slateSwatch.shade600
                                : getThemeColor(context)?.shade900,
                        dark: errorLine != null
                            ? AppColors.roseSwatch.shade400
                            : glass
                                ? AppColors.white
                                : getThemeColor(context)?.shade100,
                      ),
                    ),
                    hintStyle: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context),
                      fontFamily: getThemeFont(context),
                      color: useThemeMode(
                        context,
                        light: errorLine != null
                            ? AppColors.roseSwatch
                            : glass
                                ? AppColors.slateSwatch.withValues(alpha: 0.6)
                                : getThemeColor(context)
                                    ?.shade900
                                    .withValues(alpha: 0.6),
                        dark: errorLine != null
                            ? AppColors.roseSwatch.shade400
                            : glass
                                ? AppColors.white.withValues(alpha: 0.6)
                                : getThemeColor(context)
                                    ?.shade100
                                    .withValues(alpha: 0.6),
                      ),
                    ),
                    prefixIconColor: useThemeMode(
                      context,
                      light: getThemeColor(context)
                          ?.shade800
                          .withValues(alpha: 0.6),
                      dark: getThemeColor(context)
                          ?.shade200
                          .withValues(alpha: 0.6),
                    ),
                    suffixIconColor: useThemeMode(
                      context,
                      light: getThemeColor(context)
                          ?.shade800
                          .withValues(alpha: 0.7),
                      dark: getThemeColor(context)
                          ?.shade200
                          .withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                  ),
                  dropdownMenuEntries: items.isNotEmpty
                      ? items
                          .map((item) =>
                              logicBuilder != null ? logicBuilder!(item) : item)
                          .whereType<Map>()
                          .map(
                            (item) => DropdownMenuEntry(
                              value: item['value']!,
                              label: item['label']!,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      AppSpacing.kDefaultSpacing(context) * 2,
                                ),
                                textStyle: TextStyle(
                                  fontSize: AppSpacing.kDefaultSpacing(context),
                                  fontFamily: getThemeFont(context),
                                ),
                              ),
                            ),
                          )
                          .toList()
                      : [
                          DropdownMenuEntry(
                            label: "No Item Selected",
                            value: "null",
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    AppSpacing.kDefaultSpacing(context) * 2,
                              ),
                              textStyle: TextStyle(
                                fontSize: AppSpacing.kDefaultSpacing(context),
                                fontFamily: getThemeFont(context),
                              ),
                            ),
                            enabled: false,
                          ),
                        ],
                  leadingIcon: icon == null && prefix == null
                      ? null
                      : Padding(
                          padding: EdgeInsets.only(
                            right: icon == null && prefix == null
                                ? 0
                                : AppSpacing.kDefaultSpacing(context) * 0.5,
                          ),
                          child: prefix == null
                              ? icon != null
                                  ? IconMapper.icon(
                                      icon ?? 'help',
                                      iconPack: iconPack,
                                      size:
                                          AppSpacing.kDefaultSpacing(context) *
                                              1.6,
                                    )
                                  : const SizedBox(
                                      width: 0,
                                    )
                              : prefix!,
                        ),
                  trailingIcon: const SizedBox(
                    width: 0,
                    height: 0,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: onAction != null || screenToOpenOnSuffixTap != null
                    ? FittedBox(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            inputIcons(context),
                            IconButton(
                              onPressed: () {
                                if (onAction != null &&
                                    screenToOpenOnSuffixTap != null) {
                                  onAction!();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) =>
                                          screenToOpenOnSuffixTap!,
                                    ),
                                  );
                                } else if (onAction != null &&
                                    screenToOpenOnSuffixTap == null) {
                                  onAction!();
                                } else if (onAction == null &&
                                    screenToOpenOnSuffixTap != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) =>
                                          screenToOpenOnSuffixTap!,
                                    ),
                                  );
                                }
                              },
                              icon: IconMapper.icon(
                                actionIcon,
                                iconPack: iconPack,
                                color: useThemeMode(
                                  context,
                                  light: getThemeColor(context)
                                      ?.shade800
                                      .withValues(alpha: 0.7),
                                  dark: getThemeColor(context)
                                      ?.shade200
                                      .withValues(alpha: 0.7),
                                ),
                                size: AppSpacing.kDefaultSpacing(context) * 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : inputIcons(context),
              ),
            ],
          ),
        ),
        if (info != null && !showInfoIcon)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 1.5,
              right: AppSpacing.kDefaultSpacing(context) * 1.5,
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: double.infinity,
            child: Text(
              info!,
              textAlign: TextAlign.start,
              maxLines: 5,
              style: TextStyle(
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade900,
                  dark: getThemeColor(context)?.shade100,
                ),
                fontSize: AppSpacing.kDefaultSpacing(context) * 0.8,
              ),
            ),
          ),
        if (errorLine != null)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 1.5,
              right: AppSpacing.kDefaultSpacing(context) * 1.5,
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errorLine!
                  .map(
                    (e) => Text(
                      e.toString(),
                      textAlign: TextAlign.start,
                      maxLines: 5,
                      style: TextStyle(
                        color: AppColors.roseSwatch.shade600,
                        fontSize: AppSpacing.kDefaultSpacing(context) * 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget inputIcons(BuildContext context) {
    final iconPack =
        context.read<CommonDataProvider>().currentThemeSetting?.iconPack;

    return info != null && showInfoIcon
        ? IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade100,
                      dark: getThemeColor(context)
                          ?.shade900
                          .withValues(alpha: 0.1),
                    ),
                    height: info!.length < 100
                        ? getScreenSize(context) * 0.2
                        : getScreenSize(context) * 0.4,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.kDefaultSpacing(context),
                      vertical: AppSpacing.kDefaultSpacing(context),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconMapper.icon(
                            'info',
                            iconPack: iconPack,
                            size: AppSpacing.kDefaultSpacing(context) * 3,
                            color: useThemeMode(
                              context,
                              light: getThemeColor(context)?.shade900,
                              dark: getThemeColor(context)?.shade100,
                            ),
                          ),
                          Text(
                            info!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: useThemeMode(
                                context,
                                light: getThemeColor(context)?.shade900,
                                dark: getThemeColor(context)?.shade100,
                              ),
                              fontSize:
                                  AppSpacing.kDefaultSpacing(context) * 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            icon: IconMapper.icon(
              'help',
              iconPack: iconPack,
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade800.withValues(alpha: 0.7),
                dark: getThemeColor(context)?.shade200.withValues(alpha: 0.7),
              ),
              size: AppSpacing.kDefaultSpacing(context) * 1.5,
            ),
          )
        : const SizedBox(
            width: 0,
            height: 0,
          );
  }
}
