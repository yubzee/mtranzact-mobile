/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: editor
*/

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/editor_screen.dart';

class Editor extends StatefulWidget {
  const Editor({
    super.key,
    required this.controller,
    required this.label,
    this.errorLine,
    this.gradient = false,
    this.glass = false,
    this.background,
    this.serverUrl,
  });

  final TextEditingController controller;
  final String label;
  final String? errorLine;
  final bool gradient;
  final bool glass;
  final Map<String, dynamic>? background;
  final String? serverUrl;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  void _openEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          title: widget.label,
          initialContent: widget.controller.text,
          background: widget.background,
          serverUrl: widget.serverUrl,
          gradient: widget.gradient,
          glass: widget.glass,
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        widget.controller.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;
    Widget inputContainer = Container(
      height: AppSpacing.kDefaultSpacing(context) * 8,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: widget.glass
            ? Border.all(
                width: 0.5,
                color: useThemeMode(
                  context,
                  light: Colors.white.withValues(alpha: 0.2),
                  dark: Colors.white.withValues(alpha: 0.2),
                ),
              )
            : Border.all(
                width: 0.5,
                color: useThemeMode(
                  context,
                  light:
                      getThemeColor(context)?.shade500.withValues(alpha: 0.5),
                  dark: getThemeColor(context)?.shade100.withValues(alpha: 0.5),
                ),
              ),
        borderRadius: getThemeBorderRadius(context) >
                AppSpacing.kDefaultSpacing(context) * 5
            ? getThemeBorderRadiusCircular(context) * 0.15
            : getThemeBorderRadiusCircular(context),
        color: widget.glass
            ? useThemeMode(
                context,
                light: Colors.white.withValues(alpha: 0.6),
                dark: Colors.white.withValues(alpha: 0.1),
              )
            : useThemeMode(
                context,
                light: widget.gradient
                    ? getThemeColor(context)?.shade100.withValues(alpha: 0.9)
                    : getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                dark: widget.gradient
                    ? getThemeColor(context)?.shade900.withValues(alpha: 0.9)
                    : getThemeColor(context)?.shade50.withValues(alpha: 0.1),
              ),
        boxShadow: widget.gradient
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
      child: widget.controller.text.isEmpty
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconMapper.icon(
                    'fullscreen',
                    iconPack: iconPack,
                    size: AppSpacing.kDefaultSpacing(context) * 1.5,
                    color: useThemeMode(
                      context,
                      light: AppColors.slateSwatch.shade400,
                      dark: AppColors.slateSwatch.shade500,
                    ),
                  ),
                  SizedBox(
                    width: AppSpacing.kDefaultSpacing(context) * 0.5,
                  ),
                  Text(
                    "Enter full screen to edit...",
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context),
                      fontWeight: FontWeight.w800,
                      fontFamily: getThemeFont(context),
                      color: useThemeMode(
                        context,
                        light: AppColors.slateSwatch.shade400,
                        dark: AppColors.slateSwatch.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Html(
                data: widget.controller.text,
                style: {
                  "body": Style(
                    fontFamily: getThemeFont(context),
                    color: useThemeMode(
                      context,
                      light: AppColors.slateSwatch.shade900,
                      dark: AppColors.slateSwatch.shade100,
                    ),
                  ),
                },
              ),
            ),
    );

    return Padding(
      padding: EdgeInsets.all(
        AppSpacing.kDefaultSpacing(context) * 0.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: AppSpacing.kDefaultSpacing(context),
                  fontFamily: getThemeFont(context),
                  fontWeight: FontWeight.bold,
                  color: useThemeMode(
                    context,
                    light: getThemeColor(context)?.shade900,
                    dark: getThemeColor(context)?.shade100,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: AppSpacing.kDefaultSpacing(context) * 0.5,
          ),
          GestureDetector(
            onTap: _openEditor,
            child: inputContainer,
          ),
          if (widget.errorLine != null)
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.kDefaultSpacing(context) * 1.5,
                right: AppSpacing.kDefaultSpacing(context) * 1.5,
                top: AppSpacing.kDefaultSpacing(context) * 0.5,
              ),
              width: double.infinity,
              child: Text(
                widget.errorLine!,
                textAlign: TextAlign.start,
                maxLines: 5,
                style: TextStyle(
                  color: AppColors.roseSwatch.shade600,
                  fontSize: AppSpacing.kDefaultSpacing(context) * 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
