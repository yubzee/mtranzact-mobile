/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: checkbox
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
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/text_button.dart';

class AppCheckBox extends StatelessWidget {
  const AppCheckBox({
    super.key,
    required this.hintText,
    this.info,
    this.showInfoIcon = true,
    this.value = false,
    required this.onChanged,
    this.errorLine,
    this.glass = false,
  });

  final String hintText;
  final String? info;
  final bool showInfoIcon;
  final bool value;
  final void Function(bool?)? onChanged;
  final List? errorLine;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    if (glass) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.kDefaultSpacing(context) * 0.8,
          vertical: AppSpacing.kDefaultSpacing(context) * 0.3,
        ),
        margin: EdgeInsets.only(
          bottom: AppSpacing.kDefaultSpacing(context) * 0.5,
        ),
        decoration: BoxDecoration(
          borderRadius: getThemeBorderRadiusCircular(context),
          border: Border.all(
            width: 0.5,
            color: useThemeMode(
              context,
              light: getThemeColor(context)?.shade100.withValues(alpha: 0.2),
              dark: getThemeColor(context)?.shade100.withValues(alpha: 0.2),
            ),
          ),
          color: useThemeMode(
            context,
            light: Colors.white.withValues(alpha: 0.6),
            dark: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              activeColor: getThemeColor(context),
              value: value,
              onChanged: onChanged,
              side: BorderSide(
                color: getThemeColor(context)!,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    getThemeBorderRadiusCircular(context, intensity: 'low'),
              ),
            ),
            Expanded(
              child: AppTextButton(
                onTap: () {
                  onChanged!(!value);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hintText,
                      style: TextStyle(
                        fontSize: AppSpacing.kDefaultSpacing(context),
                        fontFamily: getThemeFont(context),
                        fontWeight: FontWeight.w700,
                        color: useThemeMode(
                          context,
                          light: AppColors.slateSwatch,
                          dark: AppColors.white,
                        ),
                      ),
                    ),
                    if (info != null && !showInfoIcon)
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppSpacing.kDefaultSpacing(context) * 0.15,
                        ),
                        child: Text(
                          info!,
                          textAlign: TextAlign.start,
                          maxLines: 5,
                          style: TextStyle(
                            color: useThemeMode(
                              context,
                              light: AppColors.slateSwatch.shade900,
                              dark: AppColors.slateSwatch.shade100,
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
                                    fontSize:
                                        AppSpacing.kDefaultSpacing(context) *
                                            0.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: AppSpacing.kDefaultSpacing(context) * 0.05,
            ),
            infoIcon(context)
          ],
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: info != null && !showInfoIcon
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: [
        Checkbox(
          activeColor: getThemeColor(context),
          value: value,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(
            borderRadius:
                getThemeBorderRadiusCircular(context, intensity: 'low'),
          ),
        ),
        Expanded(
          child: AppTextButton(
            onTap: () {
              onChanged!(!value);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hintText,
                  style: TextStyle(
                    fontSize: AppSpacing.kDefaultSpacing(context),
                    fontFamily: getThemeFont(context),
                    fontWeight: FontWeight.w700,
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade900,
                      dark: getThemeColor(context)?.shade100,
                    ),
                  ),
                ),
                if (info != null && !showInfoIcon)
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.kDefaultSpacing(context) * 0.15,
                    ),
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
                                fontSize:
                                    AppSpacing.kDefaultSpacing(context) * 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: AppSpacing.kDefaultSpacing(context) * 0.05,
        ),
        infoIcon(context)
      ],
    );
  }

  Widget infoIcon(BuildContext context) {
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
                            info!,
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
