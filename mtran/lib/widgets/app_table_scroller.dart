/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: app_table_scroller
*/

import 'package:flutter/material.dart';

class AppTableScroller extends StatelessWidget {
  final Widget child;
  final ScrollController controller;
  final ScrollController? horizontalScrollController;
  final ScrollPhysics? physics;

  const AppTableScroller({
    super.key,
    required this.child,
    required this.controller,
    this.physics,
    this.horizontalScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      controller: horizontalScrollController ?? ScrollController(),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: controller,
        physics: physics ?? AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: child,
      ),
    );
  }
}
