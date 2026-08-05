import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/utils/formula_evaluator.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/get_theme_input_design.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/button.dart';

/// A dynamic table generator widget that supports:
/// - Product search with autocomplete
/// - Dynamic columns based on configuration
/// - Formula-based calculations
/// - Row editing and deletion
/// - Totals row with aggregate functions
class TableGeneratorInput extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>)? onDataChanged;
  final Map<String, dynamic>?
      formData; // To access other form fields like warehouse_id
  final bool gradient;
  final bool glass;

  const TableGeneratorInput({
    super.key,
    required this.config,
    this.onDataChanged,
    this.formData,
    this.gradient = false,
    this.glass = false,
  });

  @override
  State<TableGeneratorInput> createState() => _TableGeneratorInputState();
}

class _TableGeneratorInputState extends State<TableGeneratorInput> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _error;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer loading initial value until after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialValue();
    });
  }

  @override
  void didUpdateWidget(TableGeneratorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload initial value if config changes
    if (oldWidget.config['value'] != widget.config['value']) {
      _isInitialized = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialValue();
      });
    }
  }

  /// Load initial value from config if provided
  void _loadInitialValue() {
    if (widget.config['value'] != null && !_isInitialized) {
      _isInitialized = true;
      final value = widget.config['value'];

      if (value is List) {
        _rows.clear();
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            // Convert all values to proper types
            final Map<String, dynamic> row = {};
            item.forEach((key, val) {
              row[key] = val;
            });
            _rows.add(row);
          }
        }
        _notifyDataChanged();
        // Force rebuild to show loaded data
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get configuration values with defaults
  String get searchUrl =>
      widget.config['search_url'] ??
      (widget.config['search'] is Map
          ? widget.config['search']['api_url']
          : null) ??
      '/products/search';
  String get searchPlaceholder =>
      widget.config['search_placeholder'] ??
      (widget.config['search'] is Map
          ? widget.config['search']['placeholder']
          : null) ??
      'Search products...';
  int get searchMinChars =>
      widget.config['search_min_chars'] ??
      (widget.config['search'] is Map
          ? widget.config['search']['min_chars']
          : null) ??
      1;
  String? get searchDependsOn =>
      widget.config['search_depends_on'] ??
      (widget.config['search'] is Map
          ? widget.config['search']['depends_on']
          : null);
  List<dynamic> get columns => widget.config['columns'] ?? [];
  List<dynamic> get rowActions => widget.config['row_actions'] ?? [];
  List<dynamic> get totalsConfig =>
      widget.config['totals'] is List ? (widget.config['totals'] ?? []) : [];
  Map<String, dynamic> get validationConfig =>
      widget.config['validation'] ?? {};
  Map<String, dynamic> get duplicateHandling =>
      widget.config['duplicate_handling'] ?? {};

  /// Search for products
  Future<void> _searchProducts(String query) async {
    if (query.isEmpty || query.length < searchMinChars) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String serverUrl =
          prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
      String token = prefs.getString(AppKeys.loginKey) ?? "";

      // Build query parameters
      final queryParams = <String, String>{
        'token': spToken, // Add setup token as query parameter
      };

      // Add dependent field value if specified (e.g., warehouse_id)
      if (searchDependsOn != null && widget.formData != null) {
        if (widget.formData!.containsKey(searchDependsOn)) {
          queryParams[searchDependsOn!] =
              widget.formData![searchDependsOn].toString();
        }
      }

      // Build the URL - route is /api/products/search/{query}
      String apiUrl = searchUrl;
      final uri = Uri.parse('$serverUrl$apiUrl/$query')
          .replace(queryParameters: queryParams);
      final productsUri =
          Uri.parse('$serverUrl$apiUrl').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final productResponse = await http.get(
            productsUri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          // Cache the full product list for offline search
          prefs.setString(searchUrl, productResponse.body);

          setState(() {
            _searchResults =
                List<Map<String, dynamic>>.from(data['data'] ?? []);
            _isSearching = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Error fetching products';
            _isSearching = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch products (Status: ${response.statusCode})';
          _isSearching = false;
        });
      }
    } on SocketException catch (_) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getString(searchUrl) != null) {
        final data = json.decode(prefs.getString(searchUrl)!);

        setState(() {
          _searchResults =
              List<Map<String, dynamic>>.from(data['data'] ?? []).where(
            (d) {
              final label = d['label']?.toString().toLowerCase() ?? '';
              final name = d['name']?.toString().toLowerCase() ?? '';
              final id = d['id']?.toString().toLowerCase() ?? '';
              final qty = d['qty']?.toString().toLowerCase() ?? '';
              return label.contains(query.toLowerCase()) ||
                  name.contains(query.toLowerCase()) ||
                  id.contains(query.toLowerCase()) ||
                  qty.contains(query.toLowerCase());
            },
          ).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _error = 'No Internet and no backup of the products';
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isSearching = false;
      });
    }
  }

  /// Add a product to the table
  void _addProduct(Map<String, dynamic> product) {
    // Check for duplicate handling
    final duplicateStrategy = duplicateHandling['strategy'] ?? 'add_new';
    final identifierField = duplicateHandling['identifier_field'] ?? 'id';
    final updateFields = duplicateHandling['update_fields'] ?? ['qty'];

    // Check if product already exists
    final productIdentifier = product[identifierField];
    final existingRowIndex = _rows.indexWhere((row) {
      // Check if the product identifier matches
      if (row['product'] != null && row['product'][identifierField] != null) {
        return row['product'][identifierField] == productIdentifier;
      }
      // Fallback: check by the identifier field directly in row
      return row[identifierField] == productIdentifier;
    });

    if (existingRowIndex != -1) {
      // Product already exists in table
      if (duplicateStrategy == 'update_quantity') {
        // Update quantity by adding to existing quantity
        final qtyField = updateFields.isNotEmpty ? updateFields[0] : 'qty';
        final currentQty = _rows[existingRowIndex][qtyField] ?? 0;
        final defaultQty = _getDefaultValueForField(qtyField);

        setState(() {
          _rows[existingRowIndex][qtyField] = currentQty + defaultQty;
          _calculateRowFormulas(_rows[existingRowIndex]);
          _searchController.clear();
          _searchResults = [];
        });

        _notifyDataChanged();
        return;
      } else if (duplicateStrategy == 'prevent_duplicate') {
        // Show error and don't add
        setState(() {
          _error = duplicateHandling['error_message'] ??
              'This product is already added to the table';
          _searchController.clear();
          _searchResults = [];
        });

        // Clear error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _error = null;
            });
          }
        });
        return;
      }
      // If strategy is 'add_new' or unrecognized, continue to add as new row
    }

    // Add as new row
    final Map<String, dynamic> newRow = {'product': product};

    // Initialize row data from product and column configuration
    for (final column in columns) {
      final columnName = column['name'];
      final source = column['source'];
      final defaultValue = column['default'];
      final type = column['type'];

      if (source != null) {
        // Extract value from product using source path (e.g., "product.name" or "name")
        final sourceParts = source.split('.');
        dynamic value = product;

        // If source starts with "product.", skip the "product" prefix
        final startIndex =
            (sourceParts.isNotEmpty && sourceParts[0] == 'product') ? 1 : 0;

        for (final part in sourceParts.skip(startIndex)) {
          if (value is Map && value.containsKey(part)) {
            value = value[part];
          } else {
            value = null;
            break;
          }
        }
        newRow[columnName] = value;
      } else if (defaultValue != null) {
        newRow[columnName] = defaultValue;
      } else {
        // If no source is specified, try to get the value directly from product using column name
        if (product.containsKey(columnName)) {
          newRow[columnName] = product[columnName];
        } else {
          // Set smart defaults based on column name and type
          if (columnName == 'qty' && type == 'number') {
            newRow[columnName] = 1; // Default quantity is 1
          } else if (type == 'number') {
            newRow[columnName] = 0;
          } else {
            newRow[columnName] = null;
          }
        }
      }
    }

    // Calculate formula fields
    _calculateRowFormulas(newRow);

    setState(() {
      _rows.add(newRow);
      _searchController.clear();
      _searchResults = [];
    });

    _notifyDataChanged();
  }

  /// Get default value for a field based on column configuration
  dynamic _getDefaultValueForField(String fieldName) {
    for (final column in columns) {
      if (column['name'] == fieldName) {
        final defaultValue = column['default'];
        if (defaultValue != null) {
          return defaultValue;
        }

        final type = column['type'];
        if (fieldName == 'qty' && type == 'number') {
          return 1; // Default quantity is 1
        } else if (type == 'number') {
          return 0;
        }
        return null;
      }
    }
    return null;
  }

  /// Calculate formulas for a single row
  void _calculateRowFormulas(Map<String, dynamic> row) {
    for (final column in columns) {
      final type = column['type'];
      if ((type == 'calculated' || type == 'formula') &&
          column['formula'] != null) {
        final formula = column['formula'] as String;
        final result = FormulaEvaluator.evaluateFormula(formula, row);
        row[column['name']] = result;
      }
    }
  }

  /// Delete a row
  void _deleteRow(int index) {
    setState(() {
      _rows.removeAt(index);
    });
    _notifyDataChanged();
  }

  /// Update a field value in a row
  void _updateRowValue(int index, String fieldName, dynamic value) {
    setState(() {
      _rows[index][fieldName] = value;
      _calculateRowFormulas(_rows[index]);
    });
    _notifyDataChanged();
  }

  /// Show edit row modal
  void _showEditRowModal(int index) {
    final row = _rows[index];
    final editControllers = <String, TextEditingController>{};

    // Create controllers for editable fields
    for (final column in columns) {
      final isEditable = column['editable'] ?? false;
      final isReadonly = column['readonly'] ?? false;

      if (isEditable && !isReadonly) {
        final columnName = column['name'];
        final value = row[columnName];
        editControllers[columnName] = TextEditingController(
          text: value?.toString() ?? '',
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        Widget content = Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: widget.glass
                ? useThemeMode(
                    context,
                    light: Colors.white.withValues(alpha: 0.6),
                    dark: Colors.white.withValues(alpha: 0.1),
                  )
                : useThemeMode(
                    context,
                    light: getThemeColor(context)?.shade50,
                    dark: getThemeColor(context)?.shade900,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                getThemeBorderRadius(context, intensity: 'low'),
              ),
              topRight: Radius.circular(
                getThemeBorderRadius(context, intensity: 'low'),
              ),
            ),
            border: widget.glass
                ? Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5), width: 0.5),
                    left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5), width: 0.5),
                    right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5), width: 0.5),
                  )
                : null,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Product',
                      style: TextStyle(
                        fontSize: AppSpacing.kDefaultSpacing(context) * 1.2,
                        fontWeight: FontWeight.bold,
                        fontFamily: getThemeFont(context),
                        color: useThemeMode(
                          context,
                          light: getThemeColor(context)?.shade900,
                          dark: getThemeColor(context)?.shade100,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: IconMapper.icon(
                        'close',
                        iconPack: context
                            .read<CommonDataProvider>()
                            .currentThemeSetting!
                            .iconPack,
                        size: AppSpacing.kDefaultSpacing(context) * 1.5,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // Dispose controllers after the frame completes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          for (var controller in editControllers.values) {
                            controller.dispose();
                          }
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.kDefaultSpacing(context)),

                // Product name (readonly)
                Text(
                  row['name']?.toString() ?? 'Product',
                  style: TextStyle(
                    fontSize: AppSpacing.kDefaultSpacing(context),
                    fontWeight: FontWeight.w600,
                    fontFamily: getThemeFont(context),
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade700,
                      dark: getThemeColor(context)?.shade300,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.kDefaultSpacing(context) * 1.5),

                // Editable fields
                ...columns
                    .where((col) =>
                        (col['editable'] ?? false) &&
                        !(col['readonly'] ?? false))
                    .map((column) {
                  final columnName = column['name'];
                  final label = column['label'] ?? columnName;
                  final type = column['type'];
                  final isQtyField = columnName == 'qty';

                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: AppSpacing.kDefaultSpacing(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: AppSpacing.kDefaultSpacing(context) * 0.9,
                            fontWeight: FontWeight.w600,
                            fontFamily: getThemeFont(context),
                            color: useThemeMode(
                              context,
                              light: getThemeColor(context)?.shade800,
                              dark: getThemeColor(context)?.shade200,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: AppSpacing.kDefaultSpacing(context) * 0.5),
                        TextField(
                          controller: editControllers[columnName],
                          keyboardType: type == 'number'
                              ? (isQtyField
                                  ? TextInputType.number
                                  : const TextInputType.numberWithOptions(
                                      decimal: true))
                              : TextInputType.text,
                          style: TextStyle(
                            fontSize: AppSpacing.kDefaultSpacing(context),
                            fontFamily: getThemeFont(context),
                            color: useThemeMode(
                              context,
                              light: getThemeColor(context)?.shade900,
                              dark: getThemeColor(context)?.shade100,
                            ),
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.kDefaultSpacing(context),
                              vertical:
                                  AppSpacing.kDefaultSpacing(context) * 0.8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                getThemeBorderRadius(context, intensity: 'low'),
                              ),
                              borderSide: BorderSide(
                                color: useThemeMode(
                                  context,
                                  light: getThemeColor(context)!.shade300,
                                  dark: getThemeColor(context)!.shade600,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                getThemeBorderRadius(context, intensity: 'low'),
                              ),
                              borderSide: BorderSide(
                                color: useThemeMode(
                                  context,
                                  light: getThemeColor(context)!.shade300,
                                  dark: getThemeColor(context)!.shade600,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                getThemeBorderRadius(context, intensity: 'low'),
                              ),
                              borderSide: BorderSide(
                                color: useThemeMode(
                                  context,
                                  light: getThemeColor(context)!.shade600,
                                  dark: getThemeColor(context)!.shade400,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: AppSpacing.kDefaultSpacing(context)),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    width: double.infinity,
                    onPressed: () {
                      // Update row values
                      for (final column in columns) {
                        final isEditable = column['editable'] ?? false;
                        final isReadonly = column['readonly'] ?? false;

                        if (isEditable && !isReadonly) {
                          final columnName = column['name'];
                          final type = column['type'];
                          final newValue =
                              editControllers[columnName]?.text ?? '';
                          final decimalPlaces = column['decimal_places'] ?? 2;
                          final isQtyField = columnName == 'qty';

                          if (type == 'number') {
                            if (isQtyField) {
                              _updateRowValue(index, columnName,
                                  int.tryParse(newValue) ?? 0);
                            } else {
                              final parsed = double.tryParse(newValue) ?? 0.0;
                              _updateRowValue(
                                  index,
                                  columnName,
                                  double.parse(
                                      parsed.toStringAsFixed(decimalPlaces)));
                            }
                          } else {
                            _updateRowValue(index, columnName, newValue);
                          }
                        }
                      }

                      Navigator.pop(context);

                      // Dispose controllers after the frame completes
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        for (var controller in editControllers.values) {
                          controller.dispose();
                        }
                      });
                    },
                    title: 'Save Changes',
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.kDefaultSpacing(context),
                    ),
                    fontSize: AppSpacing.kDefaultSpacing(context),
                    fontWeight: FontWeight.bold,
                    radius: getThemeBorderRadius(context, intensity: 'low'),
                  ),
                ),
              ],
            ),
          ),
        );
        return content;
      },
    );
  }

  /// Calculate total using aggregate formula
  double _calculateTotal(String formula) {
    return FormulaEvaluator.evaluateAggregateFormula(formula, _rows);
  }

  /// Notify parent widget of data changes
  void _notifyDataChanged() {
    if (widget.onDataChanged != null) {
      widget.onDataChanged!({
        'rows': _rows,
        'totals': _calculateTotals(),
      });
    }
  }

  /// Calculate all totals
  Map<String, double> _calculateTotals() {
    final totals = <String, double>{};
    for (var config in totalsConfig) {
      if (config['formula'] != null && config['label'] != null) {
        final label = config['label'] as String;
        final formula = config['formula'] as String;
        final result = _calculateTotal(formula);
        totals[label] = result;
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    final themeColor = getThemeColor(context);
    final bool outlinedInput = isOutlinedThemeInput(context);
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    Widget searchInput = Container(
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
            light: widget.glass
                ? themeColor?.shade100.withValues(
                    alpha: outlinedInput ? 0.35 : 0.2,
                  )
                : themeColor?.shade500.withValues(
                    alpha: outlinedInput ? 0.65 : 0.5,
                  ),
            dark: themeColor?.shade100.withValues(
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
        borderRadius: BorderRadius.circular(
          getThemeBorderRadius(context, intensity: 'medium'),
        ),
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
            horizontal: AppSpacing.kDefaultSpacing(context),
          ),
          labelText: searchPlaceholder,
          labelStyle: TextStyle(
            fontSize: AppSpacing.kDefaultSpacing(context),
            fontFamily: getThemeFont(context),
            color: useThemeMode(
              context,
              light: widget.glass
                  ? AppColors.slateSwatch.shade600
                  : getThemeColor(context)?.shade900,
              dark: widget.glass
                  ? AppColors.white
                  : getThemeColor(context)?.shade100,
            ),
          ),
          prefixIconColor: useThemeMode(
            context,
            light: themeColor?.shade800.withValues(alpha: 0.6),
            dark: themeColor?.shade200.withValues(alpha: 0.6),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              right: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            child: IconMapper.icon(
              'search',
              iconPack: iconPack,
              size: AppSpacing.kDefaultSpacing(context) * 1.6,
            ),
          ),
          suffixIcon: _isSearching
              ? Padding(
                  padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
                  child: SizedBox(
                    width: AppSpacing.kDefaultSpacing(context) * 1.5,
                    height: AppSpacing.kDefaultSpacing(context) * 1.5,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        useThemeMode(
                          context,
                          light: themeColor!.shade800,
                          dark: themeColor.shade200,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
        ),
        onChanged: (value) {
          _searchProducts(value);
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        searchInput,

        // Search Results Dropdown
        if (_searchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade50,
                dark: getThemeColor(context)?.shade900.withValues(
                      alpha: 0.5,
                    ),
              ),
              borderRadius: BorderRadius.circular(
                getThemeBorderRadius(context, intensity: 'low'),
              ),
              border: Border.all(
                width: 0.5,
                color: useThemeMode(
                  context,
                  light:
                      getThemeColor(context)?.shade900.withValues(alpha: 0.5),
                  dark: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: useThemeMode(
                    context,
                    light:
                        getThemeColor(context)!.shade300.withValues(alpha: 0.3),
                    dark:
                        getThemeColor(context)!.shade900.withValues(alpha: 0.5),
                  ),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.kDefaultSpacing(context),
                    vertical: AppSpacing.kDefaultSpacing(context) * 0.3,
                  ),
                  title: Text(
                    product['label'] ?? product['name'] ?? '',
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context),
                      fontFamily: getThemeFont(context),
                      color: useThemeMode(
                        context,
                        light: getThemeColor(context)?.shade900,
                        dark: getThemeColor(context)?.shade100,
                      ),
                    ),
                  ),
                  subtitle: product['qty'] != null
                      ? Text(
                          'Available: ${product['qty']}',
                          style: TextStyle(
                            fontSize:
                                AppSpacing.kDefaultSpacing(context) * 0.85,
                            fontFamily: getThemeFont(context),
                            color: useThemeMode(
                              context,
                              light: getThemeColor(context)?.shade700,
                              dark: getThemeColor(context)?.shade300,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    _addProduct(product);
                  },
                );
              },
            ),
          ),

        // Error message
        if (_error != null)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 1.5,
              right: AppSpacing.kDefaultSpacing(context) * 1.5,
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: double.infinity,
            child: Text(
              _error!,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: AppColors.roseSwatch.shade600,
                fontSize: AppSpacing.kDefaultSpacing(context) * 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

        SizedBox(height: AppSpacing.kDefaultSpacing(context)),

        // Table
        if (_rows.isNotEmpty)
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade50.withValues(
                      alpha: 0.5,
                    ),
                dark: getThemeColor(context)?.shade900.withValues(
                      alpha: 0.5,
                    ),
              ),
              borderRadius: BorderRadius.circular(
                getThemeBorderRadius(context, intensity: 'medium'),
              ),
              border: Border.all(
                width: 0.5,
                color: useThemeMode(
                  context,
                  light:
                      getThemeColor(context)?.shade800.withValues(alpha: 0.5),
                  dark: getThemeColor(context)?.shade100.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: AppSpacing.kDefaultSpacing(context),
                horizontalMargin: AppSpacing.kDefaultSpacing(context),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppSpacing.kDefaultSpacing(context) * 0.95,
                  fontFamily: getThemeFont(context),
                  color: useThemeMode(
                    context,
                    light: getThemeColor(context)?.shade900,
                    dark: getThemeColor(context)?.shade100,
                  ),
                ),
                dataTextStyle: TextStyle(
                  fontSize: AppSpacing.kDefaultSpacing(context) * 0.9,
                  fontFamily: getThemeFont(context),
                  color: useThemeMode(
                    context,
                    light: getThemeColor(context)?.shade800,
                    dark: getThemeColor(context)?.shade200,
                  ),
                ),
                columns: [
                  // Dynamic columns from configuration
                  ...columns.map((column) {
                    return DataColumn(
                      label: Text(
                        column['label'] ?? column['name'],
                      ),
                    );
                  }),
                  // Actions column
                  const DataColumn(label: Text('Actions')),
                ],
                rows: _rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;

                  return DataRow(
                    // Make row tappable to edit
                    onSelectChanged: (_) => _showEditRowModal(index),
                    cells: [
                      // Dynamic cells from configuration
                      ...columns.map((column) {
                        final columnName = column['name'];
                        final value = row[columnName];
                        final type = column['type'];
                        final decimalPlaces = column['decimal_places'] ?? 2;
                        final isQtyField = columnName == 'qty';

                        // Check visibility condition
                        final visibleWhen = column['visible_when'];
                        if (visibleWhen != null) {
                          if (!_evaluateVisibilityCondition(visibleWhen, row)) {
                            return const DataCell(Text('-'));
                          }
                        }

                        // Display value (no inline editing)
                        String displayValue;
                        if ((type == 'number' ||
                                type == 'formula' ||
                                type == 'calculated') &&
                            value is num) {
                          displayValue = isQtyField
                              ? value.toInt().toString()
                              : value.toStringAsFixed(decimalPlaces);
                        } else {
                          displayValue = value?.toString() ?? '';
                        }

                        return DataCell(
                          Text(displayValue),
                        );
                      }),
                      // Actions cell
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: IconMapper.icon(
                                'edit',
                                iconPack: iconPack,
                                size: AppSpacing.kDefaultSpacing(context) * 1.2,
                                color: getThemeColor(context)?.shade600,
                              ),
                              onPressed: () => _showEditRowModal(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            SizedBox(
                                width:
                                    AppSpacing.kDefaultSpacing(context) * 0.5),
                            IconButton(
                              icon: IconMapper.icon(
                                'delete',
                                iconPack: iconPack,
                                size: AppSpacing.kDefaultSpacing(context) * 1.2,
                                color: AppColors.roseSwatch.shade600,
                              ),
                              onPressed: () => _deleteRow(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

        // Totals Row
        if (_rows.isNotEmpty && totalsConfig.isNotEmpty)
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: EdgeInsets.only(top: AppSpacing.kDefaultSpacing(context)),
            padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
            decoration: BoxDecoration(
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                dark: getThemeColor(context)?.shade900.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(
                getThemeBorderRadius(context, intensity: 'medium'),
              ),
              border: Border.all(
                width: 0.5,
                color: useThemeMode(
                  context,
                  light:
                      getThemeColor(context)?.shade800.withValues(alpha: 0.3),
                  dark: getThemeColor(context)?.shade100.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: totalsConfig.map<Widget>((totalConfig) {
                final label = totalConfig['label'] as String;
                final value = totals[label] ?? 0.0;
                final decimalPlaces = totalConfig['decimal_places'] ?? 2;
                final position = totalConfig['position'] ?? 'left';
                final prefix = totalConfig['prefix'];

                // Determine if this is a qty total based on formula
                final formula = totalConfig['formula'] ?? '';
                final isQtyTotal = formula.toUpperCase().contains('COUNT(') ||
                    label.toLowerCase().contains('quantity') ||
                    label.toLowerCase().contains('items');

                String displayValue;
                if (isQtyTotal) {
                  displayValue = value.toInt().toString();
                } else {
                  displayValue = value.toStringAsFixed(decimalPlaces);
                  if (prefix != null && prefix.toString().isNotEmpty) {
                    displayValue = '$prefix $displayValue';
                  }
                }

                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.kDefaultSpacing(context) * 0.3,
                  ),
                  child: Row(
                    mainAxisAlignment: position == 'right'
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$label:',
                        style: TextStyle(
                          fontSize: AppSpacing.kDefaultSpacing(context) * 0.95,
                          fontWeight: FontWeight.w600,
                          fontFamily: getThemeFont(context),
                          color: useThemeMode(
                            context,
                            light: getThemeColor(context)?.shade900,
                            dark: getThemeColor(context)?.shade100,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.kDefaultSpacing(context)),
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: AppSpacing.kDefaultSpacing(context) * 0.95,
                          fontWeight: FontWeight.bold,
                          fontFamily: getThemeFont(context),
                          color: useThemeMode(
                            context,
                            light: getThemeColor(context)?.shade900,
                            dark: getThemeColor(context)?.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Validation error
        if (_rows.isEmpty && validationConfig['min_rows'] != null)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.kDefaultSpacing(context) * 1.5,
              right: AppSpacing.kDefaultSpacing(context) * 1.5,
              top: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            width: double.infinity,
            child: Text(
              validationConfig['error_message'] ??
                  'Please add at least one item',
              textAlign: TextAlign.start,
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

  /// Simple visibility condition evaluator
  bool _evaluateVisibilityCondition(
      String condition, Map<String, dynamic> row) {
    // Example: "product.batch_enabled == true"
    // This is simplified - extend for more complex conditions
    final parts = condition.split('==');
    if (parts.length == 2) {
      final field = parts[0].trim();
      final expectedValue = parts[1].trim();

      // Navigate to nested field (e.g., product.batch_enabled)
      final fieldParts = field.split('.');
      dynamic value = row;
      for (final part in fieldParts) {
        if (value is Map && value.containsKey(part)) {
          value = value[part];
        } else {
          return false;
        }
      }

      // Compare values
      if (expectedValue == 'true') return value == true;
      if (expectedValue == 'false') return value == false;
      return value.toString() == expectedValue;
    }
    return true;
  }
}
