/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: form
*/

import 'package:flutter/material.dart';
import 'package:salepro/constants/hero_tags.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/widgets/button.dart';

class AppForm extends StatelessWidget {
  const AppForm({
    super.key,
    required this.children,
    required this.buttonTitle,
    required this.onSubmit,
    this.padding,
    this.hideButton = false,
    this.childrenAfterButton,
  });

  final String buttonTitle;
  final List<Widget> children;
  final List<Widget>? childrenAfterButton;
  final VoidCallback onSubmit;
  final EdgeInsetsGeometry? padding;
  final bool hideButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSpacing.kDefaultSpacing(context),
        ),
        if (children.isNotEmpty)
          ...generateInputGroups(
            children,
            padding: padding,
          ),
        if (children.isEmpty)
          Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        SizedBox(
          height: AppSpacing.kDefaultSpacing(context) * 2,
        ),
        if (children.isNotEmpty && !hideButton)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.kDefaultSpacing(context),
            ),
            child: Hero(
              tag: AppHeroTags.appAdd,
              child: AppButton(
                title: buttonTitle,
                onPressed: onSubmit,
              ),
            ),
          ),
        if (childrenAfterButton != null && childrenAfterButton!.isNotEmpty) ...[
          SizedBox(
            height: AppSpacing.kDefaultSpacing(context) * 2,
          ),
          ...generateInputGroups(
            childrenAfterButton!,
            padding: padding,
          ),
        ],
        SizedBox(
          height: AppSpacing.kDefaultSpacing(context) * 8,
        ),
      ],
    );
  }
}

List<Widget> generateInputGroups(List<Widget> children,
    {EdgeInsetsGeometry? padding}) {
  return children.map(
    (child) {
      if (child.runtimeType == AnimatedCrossFade) {
        return Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: AppSpacing.kDefaultSpacing(null) * 0.7,
              ),
          child: child,
        );
      } else {
        return Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: AppSpacing.kDefaultSpacing(null) * 0.5,
                vertical: AppSpacing.kDefaultSpacing(null) * 0.5,
              ),
          child: child,
        );
      }
    },
  ).toList();
}
