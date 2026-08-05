/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: input
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

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.hintText,
    this.prefix,
    this.iconKey,
    this.password = false,
    this.showPasswordShowIcon = true,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.readOnly = false,
    this.info,
    this.showInfoIcon = true,
    this.actionIcon = 'plus-circle',
    this.onAction,
    this.screenToOpenOnSuffixTap,
    this.gradient = false,
    this.glass = false,
    this.multiline = false,
    this.placeholder,
    this.errorLine,
    this.action = TextInputAction.next,
    this.onChanged,
  });

  final String hintText;
  final Widget? prefix;
  final String? iconKey;
  final bool password;
  final bool showPasswordShowIcon;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool readOnly;
  final String? info;
  final bool showInfoIcon;
  final String actionIcon;
  final VoidCallback? onAction;
  final Widget? screenToOpenOnSuffixTap;
  final bool gradient;
  final bool glass;
  final bool multiline;
  final String? placeholder;
  final List? errorLine;
  final TextInputAction action;
  final void Function(String)? onChanged;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool obscureText = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool outlinedInput = isOutlinedThemeInput(context);

    return Column(
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
                light: widget.errorLine != null
                    ? AppColors.roseSwatch
                    : (outlinedInput && _focusNode.hasFocus)
                        ? (getThemeColor(context)?.shade600 ??
                            AppColors.indigoSwatch.shade600)
                        : (widget.glass
                            ? Colors.white
                                .withValues(alpha: outlinedInput ? 0.35 : 0.6)
                            : getThemeColor(context)
                                ?.shade500
                                .withValues(alpha: outlinedInput ? 0.65 : 0.5)),
                dark: widget.errorLine != null
                    ? AppColors.roseSwatch.shade400
                    : (outlinedInput && _focusNode.hasFocus)
                        ? (getThemeColor(context)?.shade300 ??
                            AppColors.indigoSwatch.shade300)
                        : (widget.glass
                            ? Colors.white
                                .withValues(alpha: outlinedInput ? 0.15 : 0.1)
                            : getThemeColor(context)
                                ?.shade100
                                .withValues(alpha: outlinedInput ? 0.65 : 0.5)),
              ),
            ),
            color: outlinedInput
                ? (widget.glass
                    ? useThemeMode(
                        context,
                        light: Colors.white.withValues(alpha: 0.2),
                        dark: Colors.white.withValues(alpha: 0.08),
                      )
                    : Colors.transparent)
                : (widget.glass
                    ? useThemeMode(
                        context,
                        light: Colors.white.withValues(alpha: 0.5),
                        dark: Colors.white.withValues(alpha: 0.1),
                      )
                    : useThemeMode(
                        context,
                        light: widget.gradient
                            ? getThemeColor(context)
                                ?.shade100
                                .withValues(alpha: 0.9)
                            : getThemeColor(context)
                                ?.shade50
                                .withValues(alpha: 0.5),
                        dark: widget.gradient
                            ? getThemeColor(context)
                                ?.shade900
                                .withValues(alpha: 0.9)
                            : getThemeColor(context)
                                ?.shade50
                                .withValues(alpha: 0.1),
                      )),
            borderRadius: widget.multiline &&
                    getThemeBorderRadius(context) >
                        AppSpacing.kDefaultSpacing(context) * 5
                ? getThemeBorderRadiusCircular(context) * 0.15
                : getThemeBorderRadiusCircular(context),
            boxShadow: (!outlinedInput && widget.gradient)
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
          child: TextField(
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            minLines: widget.multiline ? 5 : 1,
            maxLines: widget.multiline ? 10 : 1,
            readOnly: widget.readOnly,
            enabled: !widget.readOnly,
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.password ? obscureText : false,
            textInputAction: widget.action,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
                horizontal: AppSpacing.kDefaultSpacing(context),
              ),
              labelText: widget.hintText,
              labelStyle: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context),
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: widget.errorLine != null
                      ? AppColors.roseSwatch
                      : widget.glass
                          ? AppColors.slateSwatch.shade600
                          : getThemeColor(context)?.shade900,
                  dark: widget.errorLine != null
                      ? AppColors.roseSwatch.shade400
                      : widget.glass
                          ? AppColors.white
                          : getThemeColor(context)?.shade100,
                ),
              ),
              hintText: widget.placeholder ?? "Enter ${widget.hintText}",
              hintStyle: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context),
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: widget.errorLine != null
                      ? AppColors.roseSwatch
                      : widget.glass
                          ? AppColors.slateSwatch.withValues(alpha: 0.6)
                          : getThemeColor(context)
                              ?.shade900
                              .withValues(alpha: 0.6),
                  dark: widget.errorLine != null
                      ? AppColors.roseSwatch.shade400
                      : widget.glass
                          ? AppColors.white.withValues(alpha: 0.6)
                          : getThemeColor(context)
                              ?.shade100
                              .withValues(alpha: 0.6),
                ),
              ),
              prefixIconColor: useThemeMode(
                context,
                light: widget.errorLine != null
                    ? AppColors.roseSwatch
                    : getThemeColor(context)?.shade800.withValues(alpha: 0.6),
                dark: widget.errorLine != null
                    ? AppColors.roseSwatch.shade400
                    : getThemeColor(context)?.shade200.withValues(alpha: 0.6),
              ),
              prefixIcon: widget.iconKey == null && widget.prefix == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(
                        right: widget.iconKey == null && widget.prefix == null
                            ? 0
                            : AppSpacing.kDefaultSpacing(context) * 0.5,
                      ),
                      child: widget.prefix == null
                          ? (widget.iconKey != null
                              ? IconMapper.icon(
                                  widget.iconKey!,
                                  iconPack: context
                                      .watch<CommonDataProvider>()
                                      .currentThemeSetting
                                      ?.iconPack,
                                  size:
                                      AppSpacing.kDefaultSpacing(context) * 1.6,
                                )
                              : const SizedBox(width: 0))
                          : widget.prefix!,
                    ),
              suffixIconColor: useThemeMode(
                context,
                light: widget.errorLine != null
                    ? AppColors.roseSwatch
                    : getThemeColor(context)?.shade800.withValues(alpha: 0.7),
                dark: widget.errorLine != null
                    ? AppColors.roseSwatch.shade400
                    : getThemeColor(context)?.shade200.withValues(alpha: 0.7),
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.kDefaultSpacing(context) * 0.5,
                ),
                child: widget.onAction != null ||
                        widget.screenToOpenOnSuffixTap != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          inputIcons(context),
                          SizedBox(
                            width: AppSpacing.kDefaultSpacing(context) * 0.5,
                          ),
                          IconButton(
                            onPressed: () {
                              if (widget.onAction != null &&
                                  widget.screenToOpenOnSuffixTap != null) {
                                widget.onAction!();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        widget.screenToOpenOnSuffixTap!,
                                  ),
                                );
                              } else if (widget.onAction != null &&
                                  widget.screenToOpenOnSuffixTap == null) {
                                widget.onAction!();
                              } else if (widget.onAction == null &&
                                  widget.screenToOpenOnSuffixTap != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        widget.screenToOpenOnSuffixTap!,
                                  ),
                                );
                              }
                            },
                            iconSize: AppSpacing.kDefaultSpacing(context) * 1.5,
                            icon: IconMapper.icon(
                              widget.actionIcon,
                              iconPack: context
                                  .watch<CommonDataProvider>()
                                  .currentThemeSetting
                                  ?.iconPack,
                              color: useThemeMode(
                                context,
                                light: getThemeColor(context)
                                    ?.shade800
                                    .withValues(alpha: 0.7),
                                dark: getThemeColor(context)
                                    ?.shade200
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      )
                    : inputIcons(context),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (widget.info != null && !widget.showInfoIcon)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 1.5,
              right: AppSpacing.kDefaultSpacing(context) * 1.5,
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: double.infinity,
            child: Text(
              widget.info!,
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
        if (widget.errorLine != null)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 1.5,
              right: AppSpacing.kDefaultSpacing(context) * 1.5,
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.errorLine!
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
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return widget.password && widget.showPasswordShowIcon
        ? IconButton(
            onPressed: () {
              setState(() {
                obscureText = !obscureText;
              });
            },
            icon: IconMapper.icon(
              obscureText ? 'view' : 'view-off',
              iconPack: iconPack,
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade800.withValues(alpha: 0.7),
                dark: getThemeColor(context)?.shade200.withValues(alpha: 0.7),
              ),
              size: AppSpacing.kDefaultSpacing(context) * 1.5,
            ),
          )
        : widget.info != null && widget.showInfoIcon
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
                        height: widget.info!.length < 100
                            ? getScreenSize(context) * 0.2
                            : getScreenSize(context) * 0.4,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.kDefaultSpacing(context,
                              useWatch: false),
                          vertical: AppSpacing.kDefaultSpacing(context,
                              useWatch: false),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconMapper.icon(
                                'info',
                                iconPack: iconPack,
                                size: AppSpacing.kDefaultSpacing(context,
                                        useWatch: false) *
                                    3,
                                color: useThemeMode(
                                  context,
                                  light: getThemeColor(context)?.shade900,
                                  dark: getThemeColor(context)?.shade100,
                                ),
                              ),
                              SizedBox(
                                height: AppSpacing.kDefaultSpacing(context,
                                        useWatch: false) *
                                    0.5,
                              ),
                              Text(
                                widget.info!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: useThemeMode(
                                    context,
                                    light: getThemeColor(context)?.shade900,
                                    dark: getThemeColor(context)?.shade100,
                                  ),
                                  fontSize: AppSpacing.kDefaultSpacing(context,
                                          useWatch: false) *
                                      1.2,
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
                    light:
                        getThemeColor(context)?.shade800.withValues(alpha: 0.7),
                    dark:
                        getThemeColor(context)?.shade200.withValues(alpha: 0.7),
                  ),
                  size: AppSpacing.kDefaultSpacing(context) * 1.2,
                ),
              )
            : const SizedBox(
                width: 0,
                height: 0,
              );
  }
}
