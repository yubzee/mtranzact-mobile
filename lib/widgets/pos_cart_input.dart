import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_input_design.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/widgets/input.dart';
import 'package:salepro/widgets/select.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';

class PosCartInput extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic>? formData;
  final Future<void> Function(String type)? onSubmit;

  const PosCartInput({
    super.key,
    required this.config,
    required this.onDataChanged,
    this.formData,
    this.onSubmit,
  });

  @override
  State<PosCartInput> createState() => _PosCartInputState();
}

class _PosCartInputState extends State<PosCartInput> {
  List<dynamic> recentItems = [];
  final List<Map<String, dynamic>> _cartItems = [];
  final Map<String, dynamic> _summaryValues = {};
  final Map<String, TextEditingController> _summaryControllers = {};
  bool _isLoadingCatalog = false;
  List<dynamic> _catalogProducts = [];
  List<dynamic> _filteredProducts = [];
  String _selectedCategory = 'all';
  String _selectedBrand = 'all';
  bool _isFeatured = false;
  String _searchQuery = '';
  Timer? _debounce;

  final Map<String, dynamic> _paymentMethodStyles = {
    'cash': {'label': 'Cash', 'color': Color(0xFF00CEC9), 'iconKey': 'money'},
    'card': {
      'label': 'Card',
      'color': Color(0xFF0984E3),
      'iconKey': 'credit-card'
    },
    'cheque': {
      'label': 'Cheque',
      'color': Color(0xFFFD7272),
      'iconKey': 'receipt'
    },
    'gift_card': {
      'label': 'Gift Card',
      'color': Color(0xFF5F27CD),
      'iconKey': 'gift-card'
    },
    'deposit': {
      'label': 'Deposit',
      'color': Color(0xFFB33771),
      'iconKey': 'account-balance'
    },
    'points': {
      'label': 'Points',
      'color': Color(0xFF319398),
      'iconKey': 'star'
    },
    'paypal': {
      'label': 'Paypal',
      'color': Color(0xFF003087),
      'iconKey': 'paypal'
    },
    'pesapal': {
      'label': 'Pesapal',
      'color': Color(0xFF2C3E50),
      'iconKey': 'payment'
    },
    'razorpay': {
      'label': 'Razorpay',
      'color': Color(0xFF3399CC),
      'iconKey': 'payment'
    },
    'credit': {
      'label': 'Credit Sale',
      'color': Color(0xFFE67E22),
      'iconKey': 'credit-score'
    },
    'installment': {
      'label': 'Installment',
      'color': Color(0xFF8E44AD),
      'iconKey': 'calendar'
    },
    'stripe': {
      'label': 'Stripe',
      'color': Color(0xFF6772E5),
      'iconKey': 'credit-card'
    },
    'sslcommerz': {
      'label': 'SslCommerz',
      'color': Color(0xFFF1C40F),
      'iconKey': 'payment'
    },
    'paystack': {
      'label': 'Paystack',
      'color': Color(0xFF00C3F5),
      'iconKey': 'payment'
    },
    'pagseguro': {
      'label': 'Pagseguro',
      'color': Color(0xFF95D31D),
      'iconKey': 'payment'
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
    _cacheCatalogOptions();
  }

  Future<void> _cacheCatalogOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (widget.config.containsKey('catalog_options')) {
        // Cache the options provided in the widget config
        await prefs.setString('pos_catalog_options',
            jsonEncode(widget.config['catalog_options']));
      } else {
        // Try to load from cache if not provided (offline scenario where config might be partial)
        if (prefs.containsKey('pos_catalog_options')) {
          // Here we might want to update widget.config['catalog_options'] if it was null,
          // but widget.config is final. However, in this widget, the options are likely used
          // directly from widget.config in the build method.
          // Since we can't modify widget.config, we rely on the fact that if this widget is built,
          // the parent has likely provided the config.
          // If the whole screen is built from cache, then widget.config includes the options already.
          // So this method mainly serves to PERSIST them for future offline runs of the generator that builds this widget.
        }
      }
    } catch (e) {
      debugPrint("Error caching catalog options: $e");
    }
  }

  @override
  void dispose() {
    for (var controller in _summaryControllers.values) {
      controller.dispose();
    }
    _debounce?.cancel();
    super.dispose();
  }

  void _initializeData() {
    // Load cart items if exist
    if (widget.formData != null &&
        widget.formData!.containsKey(widget.config['name'])) {
      final items = widget.formData![widget.config['name']];
      if (items is List) {
        for (var item in items) {
          if (item is Map) {
            _cartItems.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    final summaryFields = widget.config['summary_fields'] as List? ?? [];
    for (var field in summaryFields) {
      var val = field['default'] ?? 0;

      // Check if value exists in formData
      if (widget.formData != null &&
          widget.formData!.containsKey(field['name'])) {
        val = widget.formData![field['name']];
      }

      _summaryValues[field['name']] = val;
      if (field['type'] != 'select') {
        _summaryControllers[field['name']] =
            TextEditingController(text: val.toString());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyDataChanged();
    });
  }

  void _notifyDataChanged() {
    // Calculate totals
    double subtotal = 0;
    double totalQty = 0;
    int totalItems = _cartItems.length;

    for (var item in _cartItems) {
      double qty = double.tryParse(item['qty'].toString()) ?? 0;
      double price = double.tryParse(item['price'].toString()) ?? 0;
      double discount = double.tryParse(item['discount'].toString()) ?? 0;
      double tax = double.tryParse(item['tax'].toString()) ?? 0;

      // Formula: (qty * price) - discount + tax
      double itemSubtotal = (qty * price) - discount + tax;
      item['subtotal'] = itemSubtotal;

      subtotal += itemSubtotal;
      totalQty += qty;
    }

    // Calculate Grand Total
    double orderTaxRate =
        double.tryParse(_summaryValues['order_tax_rate'].toString()) ?? 0;
    double orderDiscount =
        double.tryParse(_summaryValues['order_discount'].toString()) ?? 0;
    double shippingCost =
        double.tryParse(_summaryValues['shipping_cost'].toString()) ?? 0;

    double orderTax = subtotal * (orderTaxRate / 100);
    double grandTotal = subtotal + orderTax - orderDiscount + shippingCost;

    // Prepare data to send back
    final data = <String, dynamic>{
      widget.config['name'].toString(): _cartItems, // The cart items list
      ..._summaryValues, // The summary fields (order_tax, discount, etc.)
      'grand_total': grandTotal,
      'total_qty': totalQty,
      'total_items': totalItems,
      'order_tax': orderTax,
    };

    widget.onDataChanged(data);
  }

  Future<void> _fetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    String warehouseId = widget.formData?['warehouse_id']?.toString() ?? '';

    // Construct cache key based on filters to store/retrieve specific results
    String cacheKey =
        "pos_catalog_${warehouseId}_${_selectedCategory}_${_selectedBrand}_${_isFeatured ? '1' : '0'}_$_searchQuery";

    bool hasCache = false;

    // Try load from cache first
    if (prefs.containsKey(cacheKey)) {
      try {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          setState(() {
            _catalogProducts = jsonDecode(cachedData);
            _filteredProducts = _catalogProducts;
            hasCache = true;
          });
        }
      } catch (e) {
        debugPrint("Error loading cached products: $e");
      }
    }

    setState(() {
      _isLoadingCatalog = !hasCache;
    });

    try {
      String serverUrl =
          prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
      String token = prefs.getString(AppKeys.loginKey) ?? "";

      String searchUrl = widget.config['search_url'] ?? '/pos/product-search';

      final uri = Uri.parse(
          "$serverUrl$searchUrl?token=$spToken&query=$_searchQuery&category_id=${_selectedCategory == 'all' ? '' : _selectedCategory}&brand_id=${_selectedBrand == 'all' ? '' : _selectedBrand}&is_featured=${_isFeatured ? '1' : '0'}&warehouse_id=$warehouseId");

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Save to cache
        prefs.setString(cacheKey, response.body);

        setState(() {
          _catalogProducts = jsonDecode(response.body);
          _filteredProducts = _catalogProducts;
          _isLoadingCatalog = false;
        });
      } else {
        if (!hasCache) {
          setState(() {
            _isLoadingCatalog = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
      if (!hasCache) {
        setState(() {
          _isLoadingCatalog = false;
        });
      }
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    // Check if product already exists
    int existingIndex = _cartItems.indexWhere((item) =>
        item['id'] == product['id'] &&
        item['variant_id'] == product['variant_id']);

    if (existingIndex != -1) {
      setState(() {
        double currentQty =
            double.tryParse(_cartItems[existingIndex]['qty'].toString()) ?? 0;
        _cartItems[existingIndex]['qty'] = currentQty + 1;
      });
    } else {
      setState(() {
        _cartItems.add({
          ...product,
          'qty': 1,
          'discount': 0,
          'tax': 0,
        });
      });
    }
    _notifyDataChanged();
    Navigator.pop(context);
    if (mounted) {
      showSnackBar("${product['name']} added to cart", context,
          type: "success");
    }
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    _notifyDataChanged();
  }

  void _updateCartItem(int index, String field, dynamic value) {
    setState(() {
      _cartItems[index][field] = value;
    });
    _notifyDataChanged();
  }

  Future<void> _showCatalogDrawer() async {
    _selectedCategory = 'all';
    _selectedBrand = 'all';
    _searchQuery = '';
    _isFeatured = true;
    String? activeFilter; // 'category', 'brand', or null

    await _fetchProducts();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Catalog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: useThemeMode(
                  context,
                  light: Colors.white,
                  dark: const Color(0xFF1A1A1A),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  )
                ],
              ),
              child: StatefulBuilder(builder: (context, setDrawerState) {
                Future<void> refreshProducts() async {
                  await _fetchProducts();
                  setDrawerState(() {});
                }

                final iconPack = context
                    .read<CommonDataProvider>()
                    .currentThemeSetting
                    ?.iconPack;

                return SafeArea(
                  child: Column(
                    children: [
                      // Header & Search
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.1))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Search products...",
                                      prefixIcon: IconMapper.icon(
                                        'search',
                                        iconPack: iconPack,
                                      ),
                                      filled: !isOutlinedThemeInput(context),
                                      fillColor: !isOutlinedThemeInput(context)
                                          ? Colors.grey.withValues(alpha: 0.1)
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          getThemeBorderRadius(context,
                                              intensity: 'low'),
                                        ),
                                        borderSide: isOutlinedThemeInput(
                                                context)
                                            ? BorderSide(
                                                color: useThemeMode(
                                                  context,
                                                  light: getThemeColor(context)
                                                          ?.shade400
                                                          .withValues(
                                                              alpha: 0.6) ??
                                                      Colors.grey.withValues(
                                                          alpha: 0.4),
                                                  dark: getThemeColor(context)
                                                          ?.shade200
                                                          .withValues(
                                                              alpha: 0.6) ??
                                                      Colors.grey.withValues(
                                                          alpha: 0.4),
                                                ),
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 0, horizontal: 10),
                                    ),
                                    onChanged: (val) {
                                      if (_debounce?.isActive ?? false) {
                                        _debounce!.cancel();
                                      }
                                      _debounce = Timer(
                                          const Duration(milliseconds: 500),
                                          () {
                                        _searchQuery = val;
                                        refreshProducts();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: IconMapper.icon(
                                    'close',
                                    iconPack: iconPack,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Filter Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    onPressed: () {
                                      setDrawerState(() {
                                        activeFilter = 'category';
                                        _isFeatured = false;
                                      });
                                    },
                                    title: 'Category',
                                    width: double.infinity,
                                    variant: 'filled',
                                    bgColor: activeFilter == 'category'
                                        ? getThemeColor(context)
                                        : useThemeMode(
                                            context,
                                            light: Colors.grey[200]!,
                                            dark: Colors.grey[800]!,
                                          ),
                                    textColor: activeFilter == 'category'
                                        ? Colors.white
                                        : useThemeMode(
                                            context,
                                            light: Colors.black,
                                            dark: Colors.white,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: AppButton(
                                    onPressed: () {
                                      setDrawerState(() {
                                        activeFilter = 'brand';
                                        _isFeatured = false;
                                      });
                                    },
                                    title: 'Brand',
                                    width: double.infinity,
                                    variant: 'filled',
                                    bgColor: activeFilter == 'brand'
                                        ? getThemeColor(context)
                                        : useThemeMode(
                                            context,
                                            light: Colors.grey[200]!,
                                            dark: Colors.grey[800]!,
                                          ),
                                    textColor: activeFilter == 'brand'
                                        ? Colors.white
                                        : useThemeMode(
                                            context,
                                            light: Colors.black,
                                            dark: Colors.white,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: AppButton(
                                    onPressed: () {
                                      setDrawerState(() {
                                        _isFeatured = true;
                                        activeFilter = null;
                                        refreshProducts();
                                      });
                                    },
                                    title: 'Featured',
                                    width: double.infinity,
                                    variant: 'filled',
                                    bgColor: _isFeatured
                                        ? getThemeColor(context)
                                        : useThemeMode(
                                            context,
                                            light: Colors.grey[200]!,
                                            dark: Colors.grey[800]!,
                                          ),
                                    textColor: _isFeatured
                                        ? Colors.white
                                        : useThemeMode(
                                            context,
                                            light: Colors.black,
                                            dark: Colors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Filter Content (Category/Brand Grid)
                      if (activeFilter == 'category')
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(10),
                            itemCount: (widget.config['catalog_options']
                                        ?['categories'] as List? ??
                                    [])
                                .length,
                            separatorBuilder: (ctx, i) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final cat = widget.config['catalog_options']
                                  ['categories'][index];
                              final isSelected =
                                  _selectedCategory == cat['id'].toString();
                              return ListTile(
                                tileColor: isSelected
                                    ? getThemeColor(context)
                                        ?.withValues(alpha: 0.1)
                                    : null,
                                onTap: () {
                                  _selectedCategory = cat['id'].toString();
                                  activeFilter = null;
                                  refreshProducts();
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    getThemeBorderRadius(context,
                                        intensity: 'low'),
                                  ),
                                  side: isSelected
                                      ? BorderSide(
                                          color: getThemeColor(context)!)
                                      : BorderSide.none,
                                ),
                                leading: cat['image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: cat['image'],
                                        height: 40,
                                        width: 40,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            IconMapper.icon(
                                          'store',
                                          iconPack: iconPack,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : IconMapper.icon(
                                        'category',
                                        iconPack: iconPack,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                title: Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? getThemeColor(context)
                                        : useThemeMode(context,
                                            light: Colors.black,
                                            dark: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      if (activeFilter == 'brand')
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(10),
                            itemCount: (widget.config['catalog_options']
                                        ?['brands'] as List? ??
                                    [])
                                .length,
                            separatorBuilder: (ctx, i) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final brand = widget.config['catalog_options']
                                  ['brands'][index];
                              final isSelected =
                                  _selectedBrand == brand['id'].toString();
                              return ListTile(
                                tileColor: isSelected
                                    ? getThemeColor(context)
                                        ?.withValues(alpha: 0.1)
                                    : null,
                                onTap: () {
                                  _selectedBrand = brand['id'].toString();
                                  activeFilter = null;
                                  refreshProducts();
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    getThemeBorderRadius(context,
                                        intensity: 'low'),
                                  ),
                                  side: isSelected
                                      ? BorderSide(
                                          color: getThemeColor(context)!)
                                      : BorderSide.none,
                                ),
                                leading: brand['image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: brand['image'],
                                        height: 40,
                                        width: 40,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            IconMapper.icon(
                                          'store',
                                          iconPack: iconPack,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : IconMapper.icon(
                                        'store',
                                        iconPack: iconPack,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                title: Text(
                                  brand['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? getThemeColor(context)
                                        : useThemeMode(context,
                                            light: Colors.black,
                                            dark: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Product List
                      if (activeFilter == null)
                        Expanded(
                          child: _isLoadingCatalog
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.separated(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: _filteredProducts.length,
                                  separatorBuilder: (ctx, i) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 5),
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: useThemeMode(context,
                                              light: Colors.grey[200]!,
                                              dark: Colors.grey[800]!),
                                          borderRadius: BorderRadius.circular(
                                            getThemeBorderRadius(context,
                                                intensity: 'low'),
                                          ),
                                        ),
                                        child: product['image'] != null
                                            ? CachedNetworkImage(
                                                imageUrl: product['image'],
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        IconMapper.icon(
                                                  'image',
                                                  iconPack: iconPack,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : IconMapper.icon(
                                                'image',
                                                iconPack: iconPack,
                                                color: Colors.grey,
                                              ),
                                      ),
                                      title: Text(
                                        product['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        product['code'] ?? '',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "${product['price']}",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: getThemeColor(context)),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            icon: IconMapper.icon(
                                              'plus-circle',
                                              iconPack: iconPack,
                                              color: getThemeColor(context),
                                            ),
                                            onPressed: () {
                                              _addToCart(product);
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () => _addToCart(product),
                                    );
                                  },
                                ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  void _showEditItemModal(int index) {
    final item = _cartItems[index];
    final columns = widget.config['columns'] as List? ?? [];
    final inputs = <Widget>[];

    for (var col in columns) {
      if (col['editable'] == true) {
        inputs.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppInput(
            hintText: col['label'],
            keyboardType: TextInputType.number,
            controller:
                TextEditingController(text: item[col['name']].toString()),
            onChanged: (val) {
              _updateCartItem(index, col['name'], val);
            },
          ),
        ));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: useThemeMode(
        context,
        light: Colors.white,
        dark: const Color(0xFF1A1A1A),
        watch: false,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(
          getThemeBorderRadius(context, intensity: 'low'),
        )),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit ${item['name']}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...inputs,
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  title: "Done",
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSummaryEditModal() {
    final summaryFields = widget.config['summary_fields'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: useThemeMode(
        context,
        light: Colors.white,
        dark: const Color(0xFF1A1A1A),
        watch: false,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            getThemeBorderRadius(context, intensity: 'low'),
          ),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Order Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...summaryFields.map((field) {
                  if (field['type'] == 'select') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSelect(
                        hintText: field['label'],
                        items:
                            List<Map<String, dynamic>>.from(field['options']),
                        value: _summaryValues[field['name']]?.toString(),
                        onChange: (val) {
                          _summaryValues[field['name']] = val;
                          _notifyDataChanged();
                        },
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppInput(
                        hintText: field['label'],
                        keyboardType: TextInputType.number,
                        controller: _summaryControllers[field['name']],
                        onChanged: (val) {
                          _summaryValues[field['name']] = val;
                          _notifyDataChanged();
                        },
                      ),
                    );
                  }
                }),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    title: "Done",
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitDraft() {
    setState(() {
      _summaryValues['draft'] = 1;
      _summaryValues['sale_status'] = 1;
    });
    _notifyDataChanged();
    if (widget.onSubmit != null) {
      widget.onSubmit!('draft');
    }
  }

  void _submitPayment(String paymentMethod) {
    setState(() {
      _summaryValues['draft'] = 0;
      _summaryValues['sale_status'] = 1;
      _summaryValues['payment_status'] = 4; // Paid
      _summaryValues['paid_by_id'] = paymentMethod;
    });
    _notifyDataChanged();
    if (widget.onSubmit != null) {
      widget.onSubmit!('payment');
    }
  }

  void _showPaymentOptions() {
    List<dynamic> paymentOptions = widget.config['payment_options'] ??
        ['cash', 'card', 'cheque', 'gift_card', 'deposit', 'points'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: useThemeMode(
        context,
        light: Colors.white,
        dark: const Color(0xFF1A1A1A),
        watch: false,
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Payment Method",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemCount: paymentOptions.length,
                  itemBuilder: (context, index) {
                    String key = paymentOptions[index].toString().toLowerCase();
                    var style = _paymentMethodStyles[key] ??
                        {
                          'label': key.replaceAll('_', ' ').toUpperCase(),
                          'color': Colors.grey,
                          'iconKey': 'payment'
                        };
                    return _buildPaymentListTile(
                      style['label'],
                      style['color'],
                      style['iconKey'],
                      key,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentListTile(
      String label, Color color, String iconKey, String value) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: IconMapper.icon(
          iconKey,
          iconPack: iconPack,
          color: color,
        ),
      ),
      title: Text(label),
      trailing: IconMapper.icon(
        'chevron-right',
        iconPack: iconPack,
        size: 16,
      ),
      onTap: () {
        Navigator.pop(context);
        _submitPayment(value);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          getThemeBorderRadius(context, intensity: 'medium'),
        ),
        side: BorderSide(
          color: useThemeMode(
            context,
            light: Colors.grey.shade200,
            dark: Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  void _showRecentTransactions() async {
    await _showRecentList('sale');
  }

  void _showRecentDrafts() async {
    await _showRecentList('draft');
  }

  Future<void> _showRecentList(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'pos_recent_$type';

    if (prefs.containsKey(cacheKey)) {
      try {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          setState(() {
            recentItems = jsonDecode(cachedData);
          });
        } else {
          setState(() {
            recentItems = [];
          });
        }
      } catch (e) {
        debugPrint("Error loading cached recent list: $e");
      }
    } else {
      setState(() {
        recentItems = [];
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: useThemeMode(
        context,
        light: Colors.white,
        dark: const Color(0xFF1A1A1A),
        watch: false,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            getThemeBorderRadius(context, intensity: 'low'),
          ),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return FutureBuilder<List<dynamic>>(
                future: _fetchRecentList(type),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  final list = snapshot.data ?? recentItems;
                  if (list.isEmpty) {
                    return const Center(child: Text("No records found"));
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          type == 'sale' ? "Recent Sales" : "Recent Drafts",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: list.length,
                          separatorBuilder: (ctx, i) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return ListTile(
                              title: Text(item['reference_no'] ?? 'No Ref'),
                              subtitle: Text(
                                "${item['name']} • ${item['created_at']}",
                                style: TextStyle(
                                  color: useThemeMode(
                                    context,
                                    light: Colors.grey[600],
                                    dark: Colors.grey[400],
                                  ),
                                ),
                              ),
                              trailing: Text(
                                "${item['grand_total']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: getThemeColor(context),
                                ),
                              ),
                              onTap: () {
                                _loadSale(item['id']);
                                Navigator.pop(context); // Close modal
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            });
      },
    );
  }

  Future<List<dynamic>> _fetchRecentList(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'pos_recent_$type';

    // 1. Try to load from cache
    if (prefs.containsKey(cacheKey)) {
      try {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          setState(() {
            recentItems = jsonDecode(cachedData);
          });
        } else {
          setState(() {
            recentItems = [];
          });
        }
      } catch (e) {
        debugPrint("Error loading cached recent list: $e");
      }
    } else {
      setState(() {
        recentItems = [];
      });
    }

    try {
      String serverUrl =
          prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      String token = prefs.getString(AppKeys.loginKey) ?? "";
      String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";

      // Start timing for debug logging
      final startTime = DateTime.now();

      // Log the request
      String? requestId;

      final endpoint =
          type == 'sale' ? '/pos/recent-sale' : '/pos/recent-draft';

      if (mounted) {
        requestId = context.read<DebugProvider>().logRequest(
          method: 'GET',
          url: Uri.parse("$serverUrl$endpoint?token=$spToken").toString(),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
      final response = await http.get(
        Uri.parse("$serverUrl$endpoint?token=$spToken"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      // Calculate duration
      final duration = DateTime.now().difference(startTime);

      // Log the response
      if (mounted && requestId != null) {
        context.read<DebugProvider>().logResponse(
              id: requestId,
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: duration,
            );
      }

      if (response.statusCode == 200) {
        // Cache the new result
        await prefs.setString(cacheKey, response.body);
        setState(() {
          recentItems = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching recent list: $e");
    }

    return recentItems;
  }

  Future<void> _loadSale(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String serverUrl =
          prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
      String token = prefs.getString(AppKeys.loginKey) ?? "";

      // Start timing for debug logging
      final startTime = DateTime.now();

      // Log the request
      String? requestId;
      if (mounted) {
        requestId = context.read<DebugProvider>().logRequest(
          method: 'GET',
          url: Uri.parse("$serverUrl/pos/sale/$id?token=$spToken").toString(),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }

      final response = await http.get(
        Uri.parse("$serverUrl/pos/sale/$id?token=$spToken"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      // Calculate duration
      final duration = DateTime.now().difference(startTime);

      // Log the response
      if (mounted && requestId != null) {
        context.read<DebugProvider>().logResponse(
              id: requestId,
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: duration,
            );
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sale = data['sale'];
        final cart = data['cart'] as List;

        setState(() {
          _cartItems.clear();
          for (var item in cart) {
            _cartItems.add(Map<String, dynamic>.from(item));
          }

          _summaryValues['sale_id'] = sale['id'];
          _summaryValues['customer_id'] = sale['customer_id'];
          _summaryValues['warehouse_id'] = sale['warehouse_id'];
          _summaryValues['biller_id'] = sale['biller_id'];
          _summaryValues['order_tax_rate'] = sale['order_tax_rate'];
          _summaryValues['order_discount'] = sale['order_discount'];
          _summaryValues['shipping_cost'] = sale['shipping_cost'];
          _summaryValues['sale_status'] = sale['sale_status'];
          _summaryValues['payment_status'] = sale['payment_status'];

          if (_summaryControllers['order_tax_rate'] != null) {
            _summaryControllers['order_tax_rate']!.text =
                (sale['order_tax_rate'] ?? 0).toString();
          }
          if (_summaryControllers['order_discount'] != null) {
            _summaryControllers['order_discount']!.text =
                (sale['order_discount'] ?? 0).toString();
          }
          if (_summaryControllers['shipping_cost'] != null) {
            _summaryControllers['shipping_cost']!.text =
                (sale['shipping_cost'] ?? 0).toString();
          }
        });
        _notifyDataChanged();
      }
    } catch (e) {
      debugPrint("Error loading sale: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.config['columns'] as List? ?? [];
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.kDefaultSpacing(context) * 0.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!context.watch<CommonDataProvider>().noInternet)
            // Recent & Drafts Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      onPressed: _showRecentTransactions,
                      icon: IconMapper.icon(
                        'history',
                        iconPack: iconPack,
                      ),
                      title: "Recent Sales",
                      bgColor: AppColors.greenSwatch,
                      textColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      onPressed: _showRecentDrafts,
                      icon: IconMapper.icon(
                        'drafts',
                        iconPack: iconPack,
                      ),
                      title: "Recent Drafts",
                      bgColor: AppColors.orangeSwatch,
                      textColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          // Cart Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(
                getThemeBorderRadius(context, intensity: 'low'),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(8),
                    // Ensure minimum width of row if needed, or let content define it
                    color: Colors.grey.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        ...columns.map((col) => SizedBox(
                              width: (col['width'] as int? ?? 100).toDouble(),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: (col['padding'] as num? ?? 0)
                                        .toDouble()),
                                child: Text(
                                  col['label'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                        const SizedBox(width: 80), // Action column space
                      ],
                    ),
                  ),
                  // Table Body
                  if (_cartItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Cart is empty"),
                    )
                  else
                    ..._cartItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.1))),
                        ),
                        child: InkWell(
                          onTap: () => _showEditItemModal(index),
                          child: Row(
                            children: [
                              ...columns.map((col) {
                                final val = item[col['name']];
                                return SizedBox(
                                  width:
                                      (col['width'] as int? ?? 100).toDouble(),
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: (col['padding'] as num? ?? 0)
                                            .toDouble()),
                                    child: Text(val.toString()),
                                  ),
                                );
                              }),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: IconMapper.icon(
                                      'edit',
                                      iconPack: iconPack,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => _showEditItemModal(index),
                                  ),
                                  IconButton(
                                    icon: IconMapper.icon(
                                      'delete',
                                      iconPack: context
                                          .watch<CommonDataProvider>()
                                          .currentThemeSetting!
                                          .iconPack,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeFromCart(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              width: double.infinity,
              onPressed: _showCatalogDrawer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              icon: IconMapper.icon(
                'plus',
                iconPack: iconPack,
                color: Colors.white,
              ),
              title: 'Add Product',
            ),
          ),

          const SizedBox(height: 30),

          // Summary Fields
          const SizedBox(height: 30),
          InkWell(
            onTap: _showSummaryEditModal,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(
                  getThemeBorderRadius(context, intensity: 'low'),
                ),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Order Summary",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        onPressed: _showSummaryEditModal,
                        icon: IconMapper.icon(
                          'edit',
                          iconPack: iconPack,
                          size: 20,
                          color: Colors.blue,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildSummaryRow("Total Items",
                      "${_cartItems.length} (${_cartItems.fold<int>(0, (p, e) => p + (int.tryParse(e['qty'].toString()) ?? 0))})"),
                  _buildSummaryRow(
                      "Total Tax", "${_summaryValues['order_tax_rate'] ?? 0}%"),
                  _buildSummaryRow("Total Discount",
                      "${_summaryValues['order_discount'] ?? 0}"),
                  _buildSummaryRow(
                      "Coupon", "${_summaryValues['coupon_id'] ?? ''}"),
                  _buildSummaryRow("Shipping Cost",
                      "${_summaryValues['shipping_cost'] ?? 0}"),
                  const Divider(),
                  _buildSummaryRow(
                      "Grand Total", calculateGrandTotal().toStringAsFixed(2),
                      isTotal: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _cartItems.isNotEmpty
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.kDefaultSpacing(context),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      width: double.infinity,
                      onPressed: _submitDraft,
                      icon: IconMapper.icon(
                        'edit-document',
                        iconPack: iconPack,
                        color: Colors.white,
                      ),
                      title: 'Draft',
                      variant: 'filled',
                      bgColor: const Color(0xFFE28D02),
                      textColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      width: double.infinity,
                      onPressed: _showPaymentOptions,
                      icon: IconMapper.icon(
                        'payment',
                        iconPack: iconPack,
                        color: Colors.white,
                      ),
                      title: 'Pay',
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      width: double.infinity,
                      onPressed: () {
                        setState(() {
                          _cartItems.clear();
                          _summaryValues.clear();
                          for (var controller in _summaryControllers.values) {
                            controller.text = '';
                          }
                        });
                        _notifyDataChanged();
                      },
                      icon: IconMapper.icon(
                        'cancel',
                        iconPack: iconPack,
                        color: Colors.white,
                      ),
                      title: 'Cancel',
                      variant: 'filled',
                      bgColor: const Color(0xFFD63031),
                      textColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14)),
        ],
      ),
    );
  }

  double calculateGrandTotal() {
    double subtotal = 0;
    for (var item in _cartItems) {
      double qty = double.tryParse(item['qty'].toString()) ?? 0;
      double price = double.tryParse(item['price'].toString()) ?? 0;
      double discount = double.tryParse(item['discount'].toString()) ?? 0;
      double tax = double.tryParse(item['tax'].toString()) ?? 0;
      subtotal += (qty * price) - discount + tax;
    }

    double orderTaxRate =
        double.tryParse(_summaryValues['order_tax_rate'].toString()) ?? 0;
    double orderDiscount =
        double.tryParse(_summaryValues['order_discount'].toString()) ?? 0;
    double shippingCost =
        double.tryParse(_summaryValues['shipping_cost'].toString()) ?? 0;

    double orderTax = subtotal * (orderTaxRate / 100);
    return subtotal + orderTax - orderDiscount + shippingCost;
  }
}
