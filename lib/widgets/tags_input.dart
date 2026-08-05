import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_screensize.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_input_design.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';

class AppTagsInput extends StatefulWidget {
  final String hintText;
  final String? placeholder;
  final List<String>? initialTags;
  final String? iconKey;
  final Function(List<String>) onChanged;
  final String? errorLine;
  final String? info;
  final bool showInfoIcon;
  final bool gradient;
  final bool glass;

  const AppTagsInput({
    super.key,
    required this.hintText,
    this.placeholder,
    this.initialTags,
    required this.onChanged,
    this.errorLine,
    this.info,
    this.showInfoIcon = false,
    this.gradient = false,
    this.glass = false,
    this.iconKey,
  });

  @override
  State<AppTagsInput> createState() => _AppTagsInputState();
}

class _AppTagsInputState extends State<AppTagsInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTags != null && widget.initialTags!.isNotEmpty) {
      _tags = List<String>.from(widget.initialTags!);
    }
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      widget.onChanged(_tags);
      _controller.clear();
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
    widget.onChanged(_tags);
  }

  void _processInput(String value) {
    // Handle comma-separated values
    if (value.contains(',')) {
      final parts = value.split(',');
      for (int i = 0; i < parts.length - 1; i++) {
        _addTag(parts[i]);
      }
      _controller.text = parts.last;
      // Move cursor to end
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool outlinedInput = isOutlinedThemeInput(context);
    final themeColor = getThemeColor(context);
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    Widget inputContainer = Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.kDefaultSpacing(context) * 0.8,
        vertical: AppSpacing.kDefaultSpacing(context) * 0.3,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          width: outlinedInput ? 1 : 0.5,
          color: useThemeMode(
            context,
            light: widget.errorLine != null
                ? AppColors.roseSwatch
                : (outlinedInput && _focusNode.hasFocus)
                    ? (themeColor?.shade600 ?? AppColors.indigoSwatch.shade600)
                    : (widget.glass
                        ? themeColor?.shade100.withValues(
                            alpha: outlinedInput ? 0.35 : 0.2,
                          )
                        : themeColor?.shade500.withValues(
                            alpha: outlinedInput ? 0.65 : 0.5,
                          )),
            dark: widget.errorLine != null
                ? AppColors.roseSwatch.shade400
                : (outlinedInput && _focusNode.hasFocus)
                    ? (themeColor?.shade300 ?? AppColors.indigoSwatch.shade300)
                    : themeColor?.shade100.withValues(
                        alpha: outlinedInput ? 0.65 : 0.5,
                      ),
          ),
        ),
        color: outlinedInput
            ? (widget.glass
                ? useThemeMode(
                    context,
                    light: Colors.white.withValues(alpha: 0.2),
                    dark: Colors.white.withValues(alpha: 0.08),
                  )
                : Colors.transparent)
            : (widget.glass
                ? useThemeMode(
                    context,
                    light: Colors.white.withValues(alpha: 0.6),
                    dark: Colors.white.withValues(alpha: 0.1),
                  )
                : useThemeMode(
                    context,
                    light: widget.gradient
                        ? themeColor?.shade100.withValues(alpha: 0.9)
                        : themeColor?.shade50.withValues(alpha: 0.5),
                    dark: widget.gradient
                        ? themeColor?.shade900.withValues(alpha: 0.9)
                        : themeColor?.shade50.withValues(alpha: 0.1),
                  )),
        borderRadius: getThemeBorderRadiusCircular(context),
        boxShadow: (!outlinedInput && widget.gradient)
            ? [
                BoxShadow(
                  color: useThemeMode(
                    context,
                    light: themeColor?.shade100.withValues(alpha: 0.25),
                    dark: themeColor?.shade900.withValues(alpha: 0.5),
                  ),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display existing tags
          if (_tags.isNotEmpty)
            Wrap(
              spacing: AppSpacing.kDefaultSpacing(context) * 0.5,
              runSpacing: AppSpacing.kDefaultSpacing(context) * 0.5,
              children: _tags.asMap().entries.map((entry) {
                final index = entry.key;
                final tag = entry.value;
                return Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context) * 0.9,
                      fontFamily: getThemeFont(context),
                      color: useThemeMode(
                        context,
                        light: themeColor?.shade900,
                        dark: themeColor?.shade100,
                      ),
                    ),
                  ),
                  deleteIcon: IconMapper.icon(
                    'close',
                    iconPack: iconPack,
                    size: AppSpacing.kDefaultSpacing(context) * 1.2,
                    color: useThemeMode(
                      context,
                      light: themeColor?.shade900,
                      dark: themeColor?.shade100,
                    ),
                  ),
                  onDeleted: () => _removeTag(index),
                  backgroundColor: useThemeMode(
                    context,
                    light: widget.glass
                        ? themeColor?.shade300.withValues(alpha: 0.8)
                        : themeColor?.shade300,
                    dark: widget.glass
                        ? themeColor?.shade700.withValues(alpha: 0.3)
                        : themeColor?.shade700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        getThemeBorderRadiusCircular(context, intensity: 'low'),
                  ),
                );
              }).toList(),
            ),
          if (_tags.isNotEmpty)
            SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),

          // Input field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: TextStyle(
              fontSize: AppSpacing.kDefaultSpacing(context),
              fontFamily: getThemeFont(context),
              color: useThemeMode(
                context,
                light: themeColor?.shade900,
                dark: themeColor?.shade100,
              ),
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
                horizontal: AppSpacing.kDefaultSpacing(context),
              ),
              labelText: widget.hintText,
              labelStyle: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context),
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: widget.errorLine != null
                      ? AppColors.roseSwatch
                      : widget.glass
                          ? AppColors.slateSwatch.shade600
                          : getThemeColor(context)?.shade900,
                  dark: widget.errorLine != null
                      ? AppColors.roseSwatch.shade400
                      : widget.glass
                          ? AppColors.white
                          : getThemeColor(context)?.shade100,
                ),
              ),
              hintText: widget.placeholder ?? 'Type and press Enter or comma',
              hintStyle: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context),
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: widget.errorLine != null
                      ? AppColors.roseSwatch
                      : widget.glass
                          ? AppColors.slateSwatch.withValues(alpha: 0.6)
                          : getThemeColor(context)
                              ?.shade900
                              .withValues(alpha: 0.6),
                  dark: widget.errorLine != null
                      ? AppColors.roseSwatch.shade400
                      : widget.glass
                          ? AppColors.white.withValues(alpha: 0.6)
                          : getThemeColor(context)
                              ?.shade100
                              .withValues(alpha: 0.6),
                ),
              ),
              prefixIconColor: useThemeMode(
                context,
                light: widget.errorLine != null
                    ? AppColors.roseSwatch
                    : getThemeColor(context)?.shade800.withValues(alpha: 0.6),
                dark: widget.errorLine != null
                    ? AppColors.roseSwatch.shade400
                    : getThemeColor(context)?.shade200.withValues(alpha: 0.6),
              ),
              prefixIcon: widget.iconKey == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(
                        right: widget.iconKey == null
                            ? 0
                            : AppSpacing.kDefaultSpacing(context) * 0.5,
                      ),
                      child: (widget.iconKey != null)
                          ? IconMapper.icon(
                              widget.iconKey!,
                              iconPack: context
                                  .watch<CommonDataProvider>()
                                  .currentThemeSetting
                                  ?.iconPack,
                              size: AppSpacing.kDefaultSpacing(context) * 1.6,
                            )
                          : const SizedBox(
                              width: 0,
                            ),
                    ),
              suffixIcon: widget.info != null && widget.showInfoIcon
                  ? IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              color: useThemeMode(
                                context,
                                light: themeColor?.shade100,
                                dark:
                                    themeColor?.shade900.withValues(alpha: 0.1),
                              ),
                              height: widget.info!.length < 100
                                  ? getScreenSize(context) * 0.2
                                  : getScreenSize(context) * 0.4,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.kDefaultSpacing(context),
                                vertical: AppSpacing.kDefaultSpacing(context),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IconMapper.icon(
                                      'info',
                                      iconPack: iconPack,
                                      size:
                                          AppSpacing.kDefaultSpacing(context) *
                                              3,
                                      color: useThemeMode(
                                        context,
                                        light: themeColor?.shade900,
                                        dark: themeColor?.shade100,
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          AppSpacing.kDefaultSpacing(context) *
                                              0.5,
                                    ),
                                    Text(
                                      widget.info!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: useThemeMode(
                                          context,
                                          light: themeColor?.shade900,
                                          dark: themeColor?.shade100,
                                        ),
                                        fontSize: AppSpacing.kDefaultSpacing(
                                                context) *
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
                        'info',
                        iconPack: iconPack,
                        color: useThemeMode(
                          context,
                          light: themeColor?.shade800.withValues(alpha: 0.7),
                          dark: themeColor?.shade200.withValues(alpha: 0.7),
                        ),
                        size: AppSpacing.kDefaultSpacing(context) * 1.5,
                      ),
                    )
                  : null,
              border: InputBorder.none,
            ),
            onChanged: (value) {
              _processInput(value);
            },
            onSubmitted: (value) {
              _addTag(value);
            },
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );

    return Column(
      children: [
        inputContainer,
        // Info text without icon
        if (widget.info != null && !widget.showInfoIcon)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 1.5,
              right: AppSpacing.kDefaultSpacing(context) * 1.5,
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: double.infinity,
            child: Text(
              widget.info!,
              textAlign: TextAlign.start,
              maxLines: 5,
              style: TextStyle(
                color: useThemeMode(
                  context,
                  light: themeColor?.shade900,
                  dark: themeColor?.shade100,
                ),
                fontSize: AppSpacing.kDefaultSpacing(context) * 0.8,
              ),
            ),
          ),

        // Error message
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
