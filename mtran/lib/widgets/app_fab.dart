/*
  App FAB

  Provides a FloatingActionButton-like widget that follows theme_settings
  button_style variants (filled/outlined/gradient/glassed).
*/

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/is_dark.dart';

class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.heroTag,
    this.variant,
    this.bgColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String? label;
  final Object? heroTag;

  /// Overrides theme_settings button_style for this FAB.
  /// Supported: filled, outlined, gradient, glassed
  final String? variant;

  final Color? bgColor;
  final Color? foregroundColor;

  List<Color> _resolveGradientColors(BuildContext context) {
    final themeSetting = context.read<CommonDataProvider>().currentThemeSetting;

    if (themeSetting?.buttonColors != null &&
        (themeSetting?.buttonColors.length ?? 0) >= 2) {
      return List<Color>.from(themeSetting!.buttonColors);
    }

    final primary = bgColor ??
        getThemeColor(context)?.shade600 ??
        Theme.of(context).colorScheme.primary;

    final a = isDark(context)
        ? primary.withValues(alpha: 0.95)
        : primary.withValues(alpha: 0.98);
    final b = isDark(context)
        ? primary.withValues(alpha: 0.75)
        : primary.withValues(alpha: 0.88);

    return <Color>[a, b];
  }

  @override
  Widget build(BuildContext context) {
    final themeSetting =
        context.watch<CommonDataProvider>().currentThemeSetting;
    final styleKey = (variant ?? themeSetting?.buttonStyle ?? 'filled').trim();

    final bool isGradient = styleKey == 'gradient';
    final bool isGlassed = styleKey == 'glassed';

    final Color? tintFromButtonColors = (isGlassed &&
            bgColor == null &&
            (themeSetting?.buttonColors.isNotEmpty ?? false))
        ? themeSetting!.buttonColors.first
        : null;

    final Color primary = bgColor ??
        tintFromButtonColors ??
        getThemeColor(context)?.shade600 ??
        Theme.of(context).colorScheme.primary;
    final Color fg = foregroundColor ?? AppColors.white;

    final bool enabled = onPressed != null;
    final String cleanLabel = (label ?? '').trim();
    final bool isExtended = cleanLabel.isNotEmpty;

    if (!isGradient && !isGlassed) {
      if (isExtended) {
        return FloatingActionButton.extended(
          heroTag: heroTag,
          onPressed: onPressed,
          backgroundColor: primary,
          foregroundColor: fg,
          icon: IconTheme.merge(
            data: IconThemeData(color: fg),
            child: icon,
          ),
          label: Text(
            cleanLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: getThemeFont(context),
              fontWeight: FontWeight.w700,
              fontSize: AppSpacing.kDefaultSpacing(context),
              color: fg,
            ),
          ),
        );
      }

      return FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: primary,
        foregroundColor: fg,
        child: IconTheme.merge(
          data: IconThemeData(color: fg),
          child: icon,
        ),
      );
    }

    // Gradient / Glassed: custom Ink surface (no FloatingActionButton).
    final decoration = isGradient
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? _resolveGradientColors(context)
                  : <Color>[Colors.grey.shade500, Colors.grey.shade700],
            ),
            borderRadius: isExtended
                ? BorderRadius.circular(999)
                : BorderRadius.circular(999),
          )
        : BoxDecoration(
            color: useThemeMode(
              context,
              light: primary.withValues(alpha: 0.18),
              dark: primary.withValues(alpha: 0.20),
            ),
            border: Border.all(
              width: 1.0,
              color: useThemeMode(
                context,
                light: primary.withValues(alpha: 0.25),
                dark: primary.withValues(alpha: 0.32),
              ),
            ),
            borderRadius: BorderRadius.circular(999),
          );

    Widget content;
    if (isExtended) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme.merge(
            data: IconThemeData(
              color: enabled
                  ? fg
                  : useThemeMode(
                      context,
                      light: Colors.black.withValues(alpha: 0.35),
                      dark: Colors.white.withValues(alpha: 0.35),
                    ),
            ),
            child: icon,
          ),
          const SizedBox(width: AppSpacing.kDefaultPadding * 0.75),
          Flexible(
            child: Text(
              cleanLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: getThemeFont(context),
                fontWeight: FontWeight.w700,
                fontSize: AppSpacing.kDefaultSpacing(context),
                color: enabled
                    ? fg
                    : useThemeMode(
                        context,
                        light: Colors.black.withValues(alpha: 0.35),
                        dark: Colors.white.withValues(alpha: 0.35),
                      ),
              ),
            ),
          ),
        ],
      );
    } else {
      content = Center(
        child: IconTheme.merge(
          data: IconThemeData(
            color: enabled
                ? fg
                : useThemeMode(
                    context,
                    light: Colors.black.withValues(alpha: 0.35),
                    dark: Colors.white.withValues(alpha: 0.35),
                  ),
          ),
          child: icon,
        ),
      );
    }

    Widget surface = Ink(
      decoration: decoration,
      child: SizedBox(
        height: 56,
        width: isExtended ? null : 56,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExtended ? AppSpacing.kDefaultPadding * 1.5 : 0,
          ),
          child: content,
        ),
      ),
    );

    if (isGlassed) {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: surface,
        ),
      );
    } else {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: surface,
      );
    }

    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: surface,
      ),
    );
  }
}
