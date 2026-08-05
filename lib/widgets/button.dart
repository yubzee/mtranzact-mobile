/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: button
*/

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/is_dark.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.onPressed,
    this.title,
    this.textColor,
    this.bgColor,
    this.icon,
    this.padding,
    this.radius,
    this.fontSize,
    this.fontWeight,
    this.child,
    this.width,
    this.height,
    this.variant,
    this.preferredWidth,
    this.forceFitWidth = false,
  });

  final void Function()? onPressed;
  final double? width;
  final double? height;
  final String? title;
  final Widget? child;
  final Color? textColor;
  final Color? bgColor;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? variant;
  final String? preferredWidth;
  final bool forceFitWidth;

  List<Color> _resolveGradientColors(BuildContext context) {
    final themeSetting = context.read<CommonDataProvider>().currentThemeSetting;

    if (bgColor == null) {
      if (themeSetting?.buttonColors != null &&
          (themeSetting?.buttonColors.length ?? 0) >= 2 &&
          themeSetting?.buttonDarkColors != null &&
          (themeSetting?.buttonDarkColors.length ?? 0) >= 2) {
        return useThemeMode(
          context,
          light: List<Color>.from(themeSetting?.buttonColors ?? []),
          dark: List<Color>.from(themeSetting?.buttonDarkColors ?? []),
        );
      } else if (themeSetting?.buttonColors != null &&
          (themeSetting?.buttonColors.length ?? 0) >= 2) {
        return List<Color>.from(themeSetting!.buttonColors);
      }
    }

    final primary = bgColor ??
        getThemeColor(context)?.shade600 ??
        Theme.of(context).colorScheme.primary;

    final a = isDark(context)
        ? primary.withValues(alpha: 0.9)
        : primary.withValues(alpha: 0.95);
    final b = isDark(context)
        ? primary.withValues(alpha: 0.7)
        : primary.withValues(alpha: 0.85);

    return <Color>[a, b];
  }

  BorderRadius _resolveBorderRadius(BuildContext context) {
    return radius == null
        ? getThemeBorderRadiusCircular(context)
        : BorderRadius.circular(radius!);
  }

  Widget _buildLabel(
    BuildContext context, {
    required Color effectiveTextColor,
    required bool isOutlined,
  }) {
    return child ??
        Text(
          title ?? '',
          style: TextStyle(
            fontFamily: getThemeFont(context),
            fontSize: fontSize ?? AppSpacing.kDefaultSpacing(context),
            fontWeight: fontWeight ?? FontWeight.w600,
            color: isOutlined
                ? (bgColor ?? effectiveTextColor)
                : effectiveTextColor,
          ),
        );
  }

  Widget _buildSurfaceContent(
    BuildContext context, {
    required Color effectiveTextColor,
  }) {
    final label = _buildLabel(
      context,
      effectiveTextColor: effectiveTextColor,
      isOutlined: false,
    );

    if (icon == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme(
          data: IconThemeData(
            color: effectiveTextColor,
          ),
          child: icon!,
        ),
        const SizedBox(width: AppSpacing.kDefaultPadding * 0.5),
        Flexible(child: label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final themeSetting =
            context.watch<CommonDataProvider>().currentThemeSetting;

        final styleKey =
            (variant ?? themeSetting?.buttonStyle ?? 'filled').trim();

        final bool isGradient = styleKey == 'gradient';
        final bool isGlassed = styleKey == 'glassed';
        final bool isOutlined = styleKey == 'outlined';

        final Color? tintFromButtonColors = (isGlassed &&
                bgColor == null &&
                (themeSetting?.buttonColors.isNotEmpty ?? false))
            ? themeSetting!.buttonColors.first
            : null;

        final Color primary = bgColor ??
            tintFromButtonColors ??
            getThemeColor(context)?.shade600 ??
            Theme.of(context).colorScheme.primary;

        final Color effectiveTextColor =
            textColor ?? (isOutlined ? primary : AppColors.white);
        final BorderRadius borderRadius = _resolveBorderRadius(context);
        final EdgeInsetsGeometry effectivePadding = padding ??
            EdgeInsets.symmetric(
              horizontal: AppSpacing.kDefaultPadding * 1.5,
              vertical: AppSpacing.kDefaultSpacing(context),
            );

        final String preferredWidthKey =
            (preferredWidth ?? themeSetting?.buttonPreferredWidth ?? 'fit')
                .trim()
                .toLowerCase();

        final bool wantsFullWidth =
            !forceFitWidth && preferredWidthKey == 'full';

        final double? resolvedWidth = width ??
            (wantsFullWidth && constraints.hasBoundedWidth
                ? constraints.maxWidth
                : null);

        final double? rawHeight = height ?? themeSetting?.buttonHeight;
        final double? resolvedHeight =
            (rawHeight != null && rawHeight > 0.0) ? rawHeight : null;

        if (!isGradient && !isGlassed) {
          final backgroundColor = isOutlined
              ? useThemeMode(
                  context,
                  light: AppColors.white,
                  dark: Colors.black,
                )
              : primary;

          final side = isOutlined
              ? BorderSide(
                  width: 2,
                  color: primary,
                )
              : null;

          final button = icon == null
              ? ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: effectiveTextColor,
                    shadowColor: isOutlined ? Colors.transparent : null,
                    elevation: isOutlined ? 0 : null,
                    side: side,
                    padding: effectivePadding,
                    minimumSize:
                        resolvedHeight != null ? Size(0, resolvedHeight) : null,
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  ),
                  child: _buildLabel(
                    context,
                    effectiveTextColor: effectiveTextColor,
                    isOutlined: isOutlined,
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: effectiveTextColor,
                    shadowColor: isOutlined ? Colors.transparent : null,
                    elevation: isOutlined ? 0 : null,
                    side: side,
                    padding: effectivePadding,
                    minimumSize:
                        resolvedHeight != null ? Size(0, resolvedHeight) : null,
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  ),
                  icon: icon!,
                  label: _buildLabel(
                    context,
                    effectiveTextColor: effectiveTextColor,
                    isOutlined: isOutlined,
                  ),
                );

          return SizedBox(
            width: resolvedWidth,
            height: resolvedHeight,
            child: button,
          );
        }

        // Gradient / Glassed: use a custom Ink surface (no ElevatedButton).
        final bool enabled = onPressed != null;

        final BoxDecoration decoration = isGradient
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? _resolveGradientColors(context)
                      : <Color>[Colors.grey.shade500, Colors.grey.shade700],
                ),
                borderRadius: borderRadius,
              )
            : BoxDecoration(
                color: useThemeMode(
                  context,
                  light: primary.withValues(alpha: 0.16),
                  dark: primary.withValues(alpha: 0.18),
                ),
                border: Border.all(
                  width: 1.0,
                  color: useThemeMode(
                    context,
                    light: primary.withValues(alpha: 0.25),
                    dark: primary.withValues(alpha: 0.30),
                  ),
                ),
                borderRadius: borderRadius,
              );

        Widget surface = Ink(
          decoration: decoration,
          child: Container(
            padding: effectivePadding,
            alignment: resolvedWidth != null ? Alignment.center : null,
            constraints: resolvedHeight != null
                ? BoxConstraints(minHeight: resolvedHeight)
                : null,
            child: _buildSurfaceContent(
              context,
              effectiveTextColor: enabled
                  ? effectiveTextColor
                  : useThemeMode(
                      context,
                      light: Colors.black.withValues(alpha: 0.35),
                      dark: Colors.white.withValues(alpha: 0.35),
                    ),
            ),
          ),
        );

        if (isGlassed) {
          surface = ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: surface,
            ),
          );
        } else {
          surface = ClipRRect(borderRadius: borderRadius, child: surface);
        }

        return SizedBox(
          width: resolvedWidth,
          height: resolvedHeight,
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: surface,
            ),
          ),
        );
      },
    );
  }
}
