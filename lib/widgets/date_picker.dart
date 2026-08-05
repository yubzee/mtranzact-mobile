/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: date_picker
*/

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'package:salepro/widgets/button.dart';

class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    super.key,
    required this.hintText,
    this.prefix,
    this.icon,
    this.controller,
    this.info,
    this.showInfoIcon = true,
    this.onChanged,
    this.gradient = false,
    this.glass = false,
    this.value,
    this.startingDate,
    this.endingDate,
    this.errorLine,
    this.formatSpecifier,
  });

  final String hintText;
  final Widget? prefix;

  /// Prefer passing an IconMapper key (String). Non-string values will fall back.
  final dynamic icon;
  final TextEditingController? controller;
  final String? info;
  final bool showInfoIcon;
  final DateTime? value;
  final DateTime? startingDate;
  final DateTime? endingDate;
  final void Function(DateTime)? onChanged;
  final bool gradient;
  final bool glass;
  final List? errorLine;
  final String? formatSpecifier;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  bool isLoading = false;
  DateTime changedDateIOS = DateTime.now();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      selectedDate = widget.value;
      widget.controller?.text =
          DateFormat(widget.formatSpecifier ?? 'dd MMMM, yyyy')
              .format(widget.value!);
      setState(() {
        changedDateIOS = widget.value!;
      });
    } else if (widget.controller?.text.trim() != "" &&
        widget.controller?.text != "Select a Date") {
      // Try to parse existing date from controller
      final parsed = DateTime.tryParse(widget.controller!.text);
      if (parsed != null) {
        selectedDate = parsed;
        changedDateIOS = parsed;
      }
    }

    // Always show placeholder if no date selected
    if (selectedDate == null) {
      widget.controller?.text = "Select a Date";
    }
  }

  Future<void> pickDate() async {
    widget.controller?.text = "Loading...";
    setState(() {
      isLoading = true;
    });

    if (!kIsWeb) {
      if (Platform.isIOS) {
        await showModalBottomSheet(
          context: context,
          showDragHandle: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            Widget content = Container(
              decoration: BoxDecoration(
                color: widget.glass
                    ? useThemeMode(
                        context,
                        light: Colors.white.withValues(alpha: 0.6),
                        dark: Colors.white.withValues(alpha: 0.1),
                      )
                    : useThemeMode(
                        context,
                        light: getThemeColor(context)?.shade50,
                        dark: getThemeColor(context)?.shade900,
                      ),
                borderRadius: BorderRadius.vertical(
                  top: getThemeRadius(context, intensity: 'low'),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height:
                        AppSpacing.kDefaultSpacing(context, useWatch: false) *
                            20,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: changedDateIOS,
                      minimumDate: widget.startingDate ?? DateTime(1970),
                      maximumDate: widget.endingDate ?? DateTime(2100),
                      onDateTimeChanged: (DateTime newDateTime) {
                        widget.controller?.text = DateFormat(
                                widget.formatSpecifier ?? 'dd MMMM, yyyy')
                            .format(newDateTime);
                        setState(() {
                          changedDateIOS = newDateTime;
                          selectedDate = newDateTime;
                        });
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          AppSpacing.kDefaultSpacing(context, useWatch: false),
                      vertical:
                          AppSpacing.kDefaultSpacing(context, useWatch: false),
                    ),
                    width: double.infinity,
                    child: AppButton(
                      title: "Done",
                      onPressed: () {
                        widget.controller?.text = DateFormat(
                                widget.formatSpecifier ?? 'dd MMMM, yyyy')
                            .format(changedDateIOS);
                        setState(() {
                          selectedDate = changedDateIOS;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  )
                ],
              ),
            );

            return content;
          },
        );
        widget.controller?.text =
            DateFormat(widget.formatSpecifier ?? 'dd MMMM, yyyy')
                .format(changedDateIOS);
        setState(() {
          isLoading = false;
          selectedDate = changedDateIOS;
        });

        if (widget.onChanged != null) {
          widget.onChanged!(changedDateIOS);
        }
      } else if (Platform.isAndroid) {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: widget.value,
          firstDate: widget.startingDate ?? DateTime(1970),
          lastDate: widget.endingDate ?? DateTime(2100),
        );
        if (picked != null) {
          widget.controller?.text =
              DateFormat(widget.formatSpecifier ?? 'dd MMMM, yyyy')
                  .format(picked);
          setState(() {
            isLoading = false;
            selectedDate = picked;
          });
          if (widget.onChanged != null) {
            widget.onChanged!(picked);
          }
        } else {
          widget.controller?.text = "Select a Date";
          setState(() {
            isLoading = false;
            selectedDate = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool outlinedInput = isOutlinedThemeInput(context);
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    Widget inputContainer = Container(
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
                : (widget.glass
                    ? getThemeColor(context)?.shade100.withValues(
                          alpha: outlinedInput ? 0.35 : 0.2,
                        )
                    : getThemeColor(context)?.shade500.withValues(
                          alpha: outlinedInput ? 0.65 : 0.5,
                        )),
            dark: widget.errorLine != null
                ? AppColors.roseSwatch.shade400
                : getThemeColor(context)?.shade100.withValues(
                      alpha: outlinedInput ? 0.65 : 0.5,
                    ),
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
                    light: Colors.white.withValues(alpha: 0.6),
                    dark: Colors.white.withValues(alpha: 0.1),
                  )
                : useThemeMode(
                    context,
                    light: widget.gradient
                        ? getThemeColor(context)?.shade100.withValues(
                              alpha: 0.9,
                            )
                        : getThemeColor(context)?.shade50.withValues(
                              alpha: 0.5,
                            ),
                    dark: widget.gradient
                        ? getThemeColor(context)?.shade900.withValues(
                              alpha: 0.9,
                            )
                        : getThemeColor(context)?.shade50.withValues(
                              alpha: 0.1,
                            ),
                  )),
        borderRadius: getThemeBorderRadiusCircular(context),
        boxShadow: (!outlinedInput && widget.gradient)
            ? [
                BoxShadow(
                  color: useThemeMode(
                    context,
                    light: getThemeColor(context)
                        ?.shade100
                        .withValues(alpha: 0.25),
                    dark:
                        getThemeColor(context)?.shade900.withValues(alpha: 0.5),
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
            child: GestureDetector(
              onTap: () async {
                if (!isLoading) {
                  await pickDate();
                }
              },
              child: TextField(
                readOnly: true,
                enabled: false,
                controller: widget.controller,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: widget.gradient
                        ? AppSpacing.kDefaultSpacing(context)
                        : AppSpacing.kDefaultSpacing(context) * 0.5,
                    horizontal: AppSpacing.kDefaultSpacing(context),
                  ),
                  label: widget.gradient ? null : Text(widget.hintText),
                  hintText: "Select Date",
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
                    light:
                        getThemeColor(context)?.shade800.withValues(alpha: 0.6),
                    dark:
                        getThemeColor(context)?.shade200.withValues(alpha: 0.6),
                  ),
                  prefixIcon: widget.icon == null &&
                          widget.prefix == null &&
                          !isLoading
                      ? null
                      : isLoading
                          ? SizedBox(
                              width: AppSpacing.kDefaultSpacing(context) * 0.5,
                              height: AppSpacing.kDefaultSpacing(context) * 0.5,
                              child: CircularProgressIndicator.adaptive(),
                            )
                          : Padding(
                              padding: EdgeInsets.only(
                                right: widget.icon == null &&
                                        widget.prefix == null &&
                                        !isLoading
                                    ? 0
                                    : AppSpacing.kDefaultSpacing(context) * 0.5,
                              ),
                              child: widget.prefix == null
                                  ? widget.icon != null
                                      ? IconMapper.icon(
                                          widget.icon is String
                                              ? widget.icon as String
                                              : 'help',
                                          iconPack: iconPack,
                                          size: AppSpacing.kDefaultSpacing(
                                                context,
                                              ) *
                                              1.6,
                                        )
                                      : const SizedBox(
                                          width: 0,
                                        )
                                  : widget.prefix!,
                            ),
                  suffixIconColor: useThemeMode(
                    context,
                    light:
                        getThemeColor(context)?.shade800.withValues(alpha: 0.7),
                    dark:
                        getThemeColor(context)?.shade200.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            child: inputIcons(context),
          ),
        ],
      ),
    );

    return Column(
      children: [
        inputContainer,
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
        context.read<CommonDataProvider>().currentThemeSetting?.iconPack;

    return widget.info != null && widget.showInfoIcon
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
                      horizontal:
                          AppSpacing.kDefaultSpacing(context, useWatch: false),
                      vertical:
                          AppSpacing.kDefaultSpacing(context, useWatch: false),
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
                light: getThemeColor(context)?.shade800.withValues(alpha: 0.7),
                dark: getThemeColor(context)?.shade200.withValues(alpha: 0.7),
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
