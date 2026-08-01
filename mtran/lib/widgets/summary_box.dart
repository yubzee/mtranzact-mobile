/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: summary_box
*/

import 'package:flutter/material.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/form.dart';

class SummaryBox extends StatelessWidget {
  const SummaryBox({
    super.key,
    required this.children,
    this.title = "Summary",
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.kDefaultSpacing(context) * 0.5,
        vertical: AppSpacing.kDefaultSpacing(context) * 0.75,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          AppSpacing.kDefaultSpacing(context) * 1.2,
        ),
        decoration: BoxDecoration(
          color: useThemeMode(
            context,
            light: getThemeColor(context)?.shade50,
            dark: getThemeColor(context)?.shade800.withValues(
                  alpha: 0.7,
                ),
          ),
          borderRadius: getThemeBorderRadiusCircular(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: generateInputGroups(
            [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppSpacing.kDefaultSpacing(context) * 1.3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(),
              ...children,
            ],
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.kDefaultSpacing(context) * 0.15,
            ),
          ),
        ),
      ),
    );
  }
}

class SummaryItem extends StatelessWidget {
  const SummaryItem({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: "$title - ",
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
        style: TextStyle(
          color: useThemeMode(
            context,
            light: AppColors.slateSwatch,
            dark: AppColors.white,
          ),
          fontWeight: FontWeight.bold,
          fontFamily: getThemeFont(context),
        ),
      ),
    );
  }
}
