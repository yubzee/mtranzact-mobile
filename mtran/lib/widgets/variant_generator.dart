/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: variant_generator
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/widgets/input.dart';
import 'package:salepro/widgets/tags_input.dart';

class AppVariantGenerator extends StatefulWidget {
  final Map<String, dynamic> field;
  final Function(
      List<String> variantOptions,
      List<String> variantValues,
      List<String> variantNames,
      List<String> itemCodes,
      List<String> additionalCosts,
      List<String> additionalPrices)? onChange;
  final String? productCode;
  final bool gradient;
  final bool glass;

  const AppVariantGenerator({
    super.key,
    required this.field,
    this.onChange,
    this.productCode,
    this.gradient = false,
    this.glass = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AppVariantGeneratorState createState() => _AppVariantGeneratorState();
}

class _AppVariantGeneratorState extends State<AppVariantGenerator> {
  List<VariantOption> variantOptionsList = [];
  List<String> combinations = [];

  Map<String, TextEditingController> itemCodeControllers = {};
  Map<String, TextEditingController> additionalCostControllers = {};
  Map<String, TextEditingController> additionalPriceControllers = {};

  @override
  void initState() {
    super.initState();
    variantOptionsList.add(VariantOption());
  }

  @override
  void dispose() {
    for (var c in itemCodeControllers.values) {
      c.dispose();
    }
    for (var c in additionalCostControllers.values) {
      c.dispose();
    }
    for (var c in additionalPriceControllers.values) {
      c.dispose();
    }
    for (var option in variantOptionsList) {
      option.nameController.dispose();
    }
    super.dispose();
  }

  void _generateCombinations() {
    List<List<String>> validOptions = variantOptionsList
        .where((opt) => opt.values.isNotEmpty)
        .map((opt) => opt.values)
        .toList();

    if (validOptions.isEmpty) {
      combinations = [];
      _initializeControllers();
      _notifyParent();
      return;
    }

    List<String> result = validOptions[0];
    for (int i = 1; i < validOptions.length; i++) {
      List<String> newCombinations = [];
      for (String existing in result) {
        for (String newValue in validOptions[i]) {
          newCombinations.add('$existing/$newValue');
        }
      }
      result = newCombinations;
    }

    combinations = result;
    _initializeControllers();
    _notifyParent();
  }

  void _initializeControllers() {
    Map<String, String> oldItemCodes = {};
    Map<String, String> oldAdditionalCosts = {};
    Map<String, String> oldAdditionalPrices = {};

    itemCodeControllers.forEach((key, controller) {
      oldItemCodes[key] = controller.text;
    });
    additionalCostControllers.forEach((key, controller) {
      oldAdditionalCosts[key] = controller.text;
    });
    additionalPriceControllers.forEach((key, controller) {
      oldAdditionalPrices[key] = controller.text;
    });

    for (var c in itemCodeControllers.values) {
      c.dispose();
    }
    for (var c in additionalCostControllers.values) {
      c.dispose();
    }
    for (var c in additionalPriceControllers.values) {
      c.dispose();
    }

    itemCodeControllers.clear();
    additionalCostControllers.clear();
    additionalPriceControllers.clear();

    for (String combination in combinations) {
      String itemCode = oldItemCodes[combination] ??
          (widget.productCode != null && widget.productCode!.isNotEmpty
              ? '$combination-${widget.productCode}'
              : combination);
      itemCodeControllers[combination] = TextEditingController(text: itemCode);
      additionalCostControllers[combination] =
          TextEditingController(text: oldAdditionalCosts[combination] ?? '0');
      additionalPriceControllers[combination] =
          TextEditingController(text: oldAdditionalPrices[combination] ?? '0');
    }
  }

  void _notifyParent() {
    if (widget.onChange == null) return;

    List<String> variantOptions = variantOptionsList
        .where((opt) => opt.nameController.text.isNotEmpty)
        .map((opt) => opt.nameController.text)
        .toList();

    List<String> variantValues = [];
    for (var option in variantOptionsList) {
      if (option.values.isNotEmpty) {
        variantValues.addAll(option.values);
      }
    }

    List<String> variantNames = [];
    List<String> itemCodes = [];
    List<String> additionalCosts = [];
    List<String> additionalPrices = [];

    for (String combination in combinations) {
      variantNames.add(combination);
      itemCodes.add(itemCodeControllers[combination]?.text ?? '');
      additionalCosts.add(additionalCostControllers[combination]?.text ?? '0');
      additionalPrices
          .add(additionalPriceControllers[combination]?.text ?? '0');
    }

    widget.onChange!(
      variantOptions,
      variantValues,
      variantNames,
      itemCodes,
      additionalCosts,
      additionalPrices,
    );
  }

  void _addVariantField() {
    setState(() {
      variantOptionsList.add(VariantOption());
    });
  }

  void _removeVariantField(int index) {
    if (variantOptionsList.length > 1) {
      setState(() {
        variantOptionsList[index].nameController.dispose();
        variantOptionsList.removeAt(index);
        _generateCombinations();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(variantOptionsList.length, (index) {
          final option = variantOptionsList[index];
          return Container(
            margin: EdgeInsets.only(
              bottom: AppSpacing.kDefaultSpacing(context) * 1.5,
            ),
            padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
            decoration: BoxDecoration(
              color: useThemeMode(
                context,
                light: Colors.white.withValues(alpha: 0.4),
                dark: Colors.white.withValues(alpha: 0.1),
              ),
              border: Border.all(
                color: useThemeMode(
                  context,
                  light: Colors.white.withValues(alpha: 0.4),
                  dark: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              borderRadius: BorderRadius.circular(
                getThemeBorderRadius(context, intensity: 'medium'),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Variant Option ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppSpacing.kDefaultSpacing(context) * 0.95,
                        color: useThemeMode(
                          context,
                          light: getThemeColor(context)?.shade800,
                          dark: getThemeColor(context)?.shade200,
                        ),
                      ),
                    ),
                    if (variantOptionsList.length > 1)
                      IconButton(
                        icon: IconMapper.icon(
                          'delete',
                          iconPack: context
                              .watch<CommonDataProvider>()
                              .currentThemeSetting!
                              .iconPack,
                          color: Colors.red.shade400,
                          size: AppSpacing.kDefaultSpacing(context) * 1.5,
                        ),
                        onPressed: () => _removeVariantField(index),
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.8),
                AppInput(
                  hintText: 'Option Name',
                  placeholder: index == 0 ? 'Size' : 'Color',
                  controller: option.nameController,
                  gradient: widget.gradient,
                  glass: widget.glass,
                  onChanged: (value) {
                    _notifyParent();
                  },
                ),
                SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                AppTagsInput(
                  hintText: 'Option Values',
                  placeholder: index == 0 ? 'S, M, L, XL' : 'Red, Blue, Green',
                  initialTags: option.values,
                  gradient: widget.gradient,
                  glass: widget.glass,
                  onChanged: (tags) {
                    setState(() {
                      option.values = tags;
                      _generateCombinations();
                    });
                  },
                  info: "Use commas to separate multiple values.",
                  showInfoIcon: false,
                ),
              ],
            ),
          );
        }),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.kDefaultSpacing(context) * 0.5,
          ),
          child: AppButton(
            width: double.infinity,
            onPressed: _addVariantField,
            title: 'Add More Variant Option',
            icon: IconMapper.icon(
              'plus',
              iconPack: context
                  .watch<CommonDataProvider>()
                  .currentThemeSetting
                  ?.iconPack,
              size: AppSpacing.kDefaultSpacing(context) * 1.2,
            ),
          ),
        ),
        if (combinations.isNotEmpty) ...[
          SizedBox(height: AppSpacing.kDefaultSpacing(context)),
          Container(
            padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 0.5),
            decoration: BoxDecoration(
              color: useThemeMode(
                context,
                light: Colors.white.withValues(alpha: 0.6),
                dark: Colors.white.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(
                getThemeBorderRadius(context, intensity: 'low'),
              ),
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
                      color: useThemeMode(
                        context,
                        light: getThemeColor(context)?.shade300,
                        dark: getThemeColor(context)?.shade700,
                      ),
                    ),
            ),
            child: Text(
              'Generated Variants: ${combinations.length}',
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 0.9,
                fontWeight: FontWeight.w600,
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade800,
                  dark: getThemeColor(context)?.shade200,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.kDefaultSpacing(context)),
          _buildVariantTable(),
        ],
      ],
    );
  }

  Widget _buildVariantTable() {
    return Column(
      children: combinations.map((combination) {
        Widget container = Container(
          margin: EdgeInsets.only(bottom: AppSpacing.kDefaultSpacing(context)),
          padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
          decoration: BoxDecoration(
            color: widget.glass
                ? useThemeMode(
                    context,
                    light: Colors.white.withValues(alpha: 0.6),
                    dark: Colors.white.withValues(alpha: 0.1),
                  )
                : useThemeMode(
                    context,
                    light:
                        getThemeColor(context)?.shade100.withValues(alpha: 0.3),
                    dark:
                        getThemeColor(context)?.shade900.withValues(alpha: 0.3),
                  ),
            border: widget.glass
                ? Border.all(
                    width: 0.5,
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)
                          ?.shade100
                          .withValues(alpha: 0.2),
                      dark: getThemeColor(context)
                          ?.shade100
                          .withValues(alpha: 0.2),
                    ),
                  )
                : Border.all(
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade300,
                      dark: getThemeColor(context)?.shade700,
                    ),
                  ),
            borderRadius: BorderRadius.circular(
              getThemeBorderRadius(context, intensity: 'low'),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Variant Name Header
              Container(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.kDefaultSpacing(context) * 0.5,
                ),
                child: Text(
                  combination,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSpacing.kDefaultSpacing(context) * 1.1,
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade900,
                      dark: getThemeColor(context)?.shade100,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),

              // Item Code Input
              AppInput(
                hintText: 'Item Code',
                placeholder: 'Enter item code',
                controller: itemCodeControllers[combination],
                gradient: widget.gradient,
                glass: widget.glass,
                onChanged: (_) => _notifyParent(),
              ),
              SizedBox(height: AppSpacing.kDefaultSpacing(context)),

              // Additional Cost Input
              AppInput(
                hintText: 'Additional Cost',
                placeholder: 'Enter additional cost',
                controller: additionalCostControllers[combination],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                gradient: widget.gradient,
                glass: widget.glass,
                onChanged: (_) => _notifyParent(),
              ),
              SizedBox(height: AppSpacing.kDefaultSpacing(context)),

              // Additional Price Input
              AppInput(
                hintText: 'Additional Price',
                placeholder: 'Enter additional price',
                controller: additionalPriceControllers[combination],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                gradient: widget.gradient,
                glass: widget.glass,
                onChanged: (_) => _notifyParent(),
              ),
            ],
          ),
        );
        return container;
      }).toList(),
    );
  }
}

class VariantOption {
  final TextEditingController nameController = TextEditingController();
  List<String> values = [];
}
