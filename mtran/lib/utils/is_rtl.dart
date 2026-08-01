/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: is_rtl
*/

import 'package:flutter/material.dart';

/// Helper function to check if the current text direction is RTL
bool isRTL(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl;
}

/// Helper function to get the text direction from context
TextDirection getTextDirection(BuildContext context) {
  return Directionality.of(context);
}

/// Helper function to reverse alignment for RTL
/// Use this for alignments that need to flip in RTL mode
Alignment getAlignment(
  BuildContext context, {
  Alignment ltr = Alignment.centerLeft,
  Alignment rtl = Alignment.centerRight,
}) {
  return isRTL(context) ? rtl : ltr;
}

/// Helper function to get EdgeInsets that respect RTL
/// Example: getEdgeInsets(context, left: 10, right: 20)
/// In LTR: EdgeInsets.only(left: 10, right: 20)
/// In RTL: EdgeInsets.only(left: 20, right: 10)
EdgeInsets getEdgeInsets(
  BuildContext context, {
  double left = 0,
  double top = 0,
  double right = 0,
  double bottom = 0,
}) {
  if (isRTL(context)) {
    return EdgeInsets.only(
      left: right,
      top: top,
      right: left,
      bottom: bottom,
    );
  }
  return EdgeInsets.only(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}

/// Helper function to get MainAxisAlignment that respects RTL
MainAxisAlignment getMainAxisAlignment(
  BuildContext context, {
  MainAxisAlignment ltr = MainAxisAlignment.start,
  MainAxisAlignment rtl = MainAxisAlignment.end,
}) {
  return isRTL(context) ? rtl : ltr;
}

/// Helper function to get CrossAxisAlignment that respects RTL
CrossAxisAlignment getCrossAxisAlignment(
  BuildContext context, {
  CrossAxisAlignment ltr = CrossAxisAlignment.start,
  CrossAxisAlignment rtl = CrossAxisAlignment.end,
}) {
  return isRTL(context) ? rtl : ltr;
}

/// Helper function to get TextAlign that respects RTL
TextAlign getTextAlign(
  BuildContext context, {
  TextAlign ltr = TextAlign.left,
  TextAlign rtl = TextAlign.right,
}) {
  return isRTL(context) ? rtl : ltr;
}
