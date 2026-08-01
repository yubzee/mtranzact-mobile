/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: text_button
*/

import 'package:salepro/constants/spacing.dart';
import 'package:flutter/material.dart';
import 'package:salepro/themes/button_styles.dart';

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: appButtonBorderRadius(context),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(
            AppSpacing.kDefaultSpacing(context) * 0.5,
          ),
          child: child,
        ),
      ),
    );
  }
}
