/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: delayed_expandable_fab
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/hero_tags.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/widgets/app_fab.dart';

class DelayedExpandableFab extends StatefulWidget {
  const DelayedExpandableFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.iconKey = 'plus',
    this.icon,
    this.delay = const Duration(seconds: 2),
    this.expandDuration = const Duration(milliseconds: 260),
  });

  final String label;
  final VoidCallback? onPressed;
  final String iconKey;

  @Deprecated('Use iconKey instead of icon')
  final IconData? icon;
  final Duration delay;
  final Duration expandDuration;

  @override
  State<DelayedExpandableFab> createState() => _DelayedExpandableFabState();
}

class _DelayedExpandableFabState extends State<DelayedExpandableFab>
    with TickerProviderStateMixin {
  Timer? _timer;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() => _expanded = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String label = widget.label.trim();
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;
    // ignore: deprecated_member_use_from_same_package
    final IconData? legacyIcon = widget.icon;
    final iconWidget = legacyIcon != null && widget.iconKey.isEmpty
        ? Icon(legacyIcon)
        : IconMapper.icon(widget.iconKey, iconPack: iconPack);

    return Hero(
      tag: AppHeroTags.appAdd,
      child: AnimatedSize(
        duration: widget.expandDuration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerRight,
        child: AppFab(
          heroTag: null,
          onPressed: widget.onPressed,
          icon: iconWidget,
          label: _expanded ? label : null,
        ),
      ),
    );
  }
}
