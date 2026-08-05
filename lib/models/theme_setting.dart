import 'package:flutter/material.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/models/mappable.dart';

String _colorToHex(Color color, {bool includeAlpha = false}) {
  final int value = color.toARGB32();
  final int rgb = value & 0x00FFFFFF;
  final int argb = value & 0xFFFFFFFF;

  final String hex = (includeAlpha ? argb : rgb)
      .toRadixString(16)
      .padLeft(includeAlpha ? 8 : 6, '0')
      .toUpperCase();

  return '#$hex';
}

String _materialColorToHex(MaterialColor color) {
  return _colorToHex(color.shade500);
}

Color? _parseColor(dynamic value) {
  if (value == null) return null;
  if (value is Color) return value;

  if (value is int) {
    final int intValue = value;
    if (intValue <= 0xFFFFFF) {
      return Color(0xFF000000 | intValue);
    }
    return Color(intValue);
  }

  final String raw = value.toString().trim();
  if (raw.isEmpty) return null;

  try {
    if (raw.startsWith('0x') || raw.startsWith('0X')) {
      return Color(int.parse(raw));
    }

    final String hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    }
    if (hex.length == 8) {
      return Color(int.parse('0x$hex'));
    }
  } catch (_) {
    return null;
  }

  return null;
}

List<Color> _parseColorList(dynamic value) {
  if (value is! List) return <Color>[];
  return value.map(_parseColor).whereType<Color>().toList();
}

class ThemeSetting implements Mappable {
  final int id;
  final String name;
  final String themeAppearance;
  final MaterialColor themeColor;
  final String fontFamily;
  final String iconPack;
  final int itemSize;
  final String inputDesign;
  final String buttonStyle;
  final String borderRadius;
  final List<Color> buttonColors;
  final List<Color> buttonDarkColors;
  final String buttonPreferredWidth;
  final double? buttonHeight;

  ThemeSetting({
    required this.id,
    required this.name,
    required this.themeAppearance,
    required this.themeColor,
    required this.fontFamily,
    required this.iconPack,
    required this.itemSize,
    required this.inputDesign,
    required this.buttonStyle,
    required this.borderRadius,
    this.buttonColors = const <Color>[],
    this.buttonDarkColors = const <Color>[],
    this.buttonPreferredWidth = 'fit',
    this.buttonHeight,
  });

  static List<ThemeSetting> defaultThemeSettings() {
    return [
      ThemeSetting(
        id: -1,
        name: 'Indigo (Default)',
        themeAppearance: 'system_both',
        themeColor: AppColors.indigoSwatch,
        fontFamily: 'Jost',
        iconPack: 'solar',
        itemSize: 16,
        inputDesign: 'filled',
        buttonStyle: 'filled',
        borderRadius: 'rounded-lg',
      ),
      ThemeSetting(
        id: -2,
        name: 'Blue',
        themeAppearance: 'system_both',
        themeColor: AppColors.blueSwatch,
        fontFamily: 'Poppins',
        iconPack: 'fontawesome',
        itemSize: 16,
        inputDesign: 'outlined',
        buttonStyle: 'outlined',
        borderRadius: 'rounded',
      ),
      ThemeSetting(
        id: -3,
        name: 'Purple',
        themeAppearance: 'system_both',
        themeColor: AppColors.purpleSwatch,
        fontFamily: 'Raleway',
        iconPack: 'material',
        itemSize: 16,
        inputDesign: 'filled',
        buttonStyle: 'gradient',
        buttonColors: [
          AppColors.purpleSwatch.shade400,
          AppColors.purpleSwatch.shade800,
        ],
        borderRadius: 'rounded-lg',
      ),
      ThemeSetting(
        id: -4,
        name: 'Green',
        themeAppearance: 'system_both',
        themeColor: AppColors.emeraldSwatch,
        fontFamily: 'Josefin Sans',
        iconPack: 'heroicons',
        itemSize: 16,
        inputDesign: 'filled',
        buttonStyle: 'outlined',
        borderRadius: 'rounded-none',
      ),
      ThemeSetting(
        id: -5,
        name: 'Rose',
        themeAppearance: 'system_both',
        themeColor: AppColors.roseSwatch,
        fontFamily: 'Nunito',
        iconPack: 'bootstrap',
        itemSize: 16,
        inputDesign: 'outlined',
        buttonStyle: 'filled',
        borderRadius: 'rounded-full',
      ),
    ];
  }

  factory ThemeSetting.fromJson(Map json) {
    final Map<int, Color> colorMap = <int, Color>{};

    final dynamic rawThemeColor = json['theme_colors'];
    if (rawThemeColor is Map) {
      final Map<String, dynamic> colors =
          Map<String, dynamic>.from(rawThemeColor);
      colors.forEach((key, value) {
        final int intKey = int.tryParse(key.toString()) ?? 500;
        final String? hex = value?.toString();
        if (hex == null) return;
        colorMap[intKey] = Color(int.parse(hex.replaceFirst('#', '0xff')));
      });
    } else if (rawThemeColor != null) {
      final String hex = rawThemeColor.toString();
      final Color color = Color(int.parse(hex.replaceFirst('#', '0xff')));
      colorMap[500] = color;
    }

    final int primaryValue = (colorMap[500]?.toARGB32()) ??
        (colorMap.values.isNotEmpty
            ? colorMap.values.first.toARGB32()
            : 0xff6366f1);

    final String rawPreferredWidth = (json['button_preferred_width'] ??
            json['buttonPreferredWidth'] ??
            'fit')
        .toString()
        .trim()
        .toLowerCase();

    final String resolvedPreferredWidth =
        rawPreferredWidth == 'full' ? 'full' : 'fit';

    final dynamic rawButtonHeight =
        json['button_height'] ?? json['buttonHeight'];
    final double? resolvedButtonHeight = rawButtonHeight == null
        ? null
        : double.tryParse(rawButtonHeight.toString());

    return ThemeSetting(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Default',
      themeAppearance: json['theme_appearance']?.toString() ?? 'system_both',
      themeColor: json['theme_colors'] != null
          ? MaterialColor(
              primaryValue,
              colorMap,
            )
          : AppColors.indigoSwatch,
      fontFamily: json['font_family']?.toString() ?? 'Jost',
      iconPack: json['icon_pack']?.toString() ?? 'solar',
      itemSize: int.tryParse(json['item_size'].toString()) ?? 16,
      inputDesign: json['input_design']?.toString() ?? 'outlined',
      buttonStyle: json['button_style']?.toString() ?? 'filled',
      buttonColors: _parseColorList(json['button_colors']),
      buttonDarkColors: _parseColorList(json['button_dark_colors']),
      borderRadius: json['border_radius']?.toString() ?? 'rounded',
      buttonPreferredWidth: resolvedPreferredWidth,
      buttonHeight: (resolvedButtonHeight != null && resolvedButtonHeight > 0.0)
          ? resolvedButtonHeight
          : null,
    );
  }

  @override
  Mappable fromJson(Map<String, dynamic> json) => ThemeSetting.fromJson(json);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'theme_appearance': themeAppearance,
      'theme_color': _materialColorToHex(themeColor),
      'theme_colors': {
        '50': _colorToHex(themeColor.shade50),
        '100': _colorToHex(themeColor.shade100),
        '200': _colorToHex(themeColor.shade200),
        '300': _colorToHex(themeColor.shade300),
        '400': _colorToHex(themeColor.shade400),
        '500': _colorToHex(themeColor.shade500),
        '600': _colorToHex(themeColor.shade600),
        '700': _colorToHex(themeColor.shade700),
        '800': _colorToHex(themeColor.shade800),
        '900': _colorToHex(themeColor.shade900),
      },
      'font_family': fontFamily,
      'icon_pack': iconPack,
      'item_size': itemSize,
      'input_design': inputDesign,
      'button_style': buttonStyle,
      'button_colors': buttonColors.map((c) => _colorToHex(c)).toList(),
      'button_dark_colors':
          buttonDarkColors.map((c) => _colorToHex(c)).toList(),
      'border_radius': borderRadius,
      'button_preferred_width': buttonPreferredWidth,
      'button_height': buttonHeight,
    };
  }

  @override
  Map<String, dynamic> toFormData() {
    return {
      'id': id,
      'name': name,
      'theme_appearance': themeAppearance,
      'theme_color': _materialColorToHex(themeColor),
      'theme_colors': {
        '50': _colorToHex(themeColor.shade50),
        '100': _colorToHex(themeColor.shade100),
        '200': _colorToHex(themeColor.shade200),
        '300': _colorToHex(themeColor.shade300),
        '400': _colorToHex(themeColor.shade400),
        '500': _colorToHex(themeColor.shade500),
        '600': _colorToHex(themeColor.shade600),
        '700': _colorToHex(themeColor.shade700),
        '800': _colorToHex(themeColor.shade800),
        '900': _colorToHex(themeColor.shade900),
      },
      'font_family': fontFamily,
      'icon_pack': iconPack,
      'item_size': itemSize,
      'input_design': inputDesign,
      'button_style': buttonStyle,
      'border_radius': borderRadius,
      'button_colors': buttonColors.map((c) => _colorToHex(c)).toList(),
      'button_dark_colors':
          buttonDarkColors.map((c) => _colorToHex(c)).toList(),
      'button_preferred_width': buttonPreferredWidth,
      'button_height': buttonHeight,
    };
  }
}
