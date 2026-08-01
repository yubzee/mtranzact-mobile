import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:countup/countup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/models/message.dart';
import 'package:salepro/models/nav_link.dart';
import 'package:salepro/models/offline_submission.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/providers/offline_submission_provider.dart';
import 'package:salepro/screens/auth/welcome.dart';
import 'package:salepro/screens/debug_screen.dart';
import 'package:salepro/utils/control_loading.dart';
import 'package:salepro/utils/get_nav_link.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';
import 'package:salepro/utils/formula_evaluator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../utils/get_screensize.dart';
import '../utils/get_theme_color.dart';
import '../utils/get_theme_border_radius.dart';
import '../utils/is_dark.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_table_scroller.dart';
import '../widgets/checkbox.dart';
import 'dynamic_form_screen.dart';
import '../widgets/drawer.dart';
import '../widgets/sortable_table.dart';
import '../widgets/text_button.dart';
import '../widgets/draft_button.dart';
import '../widgets/delayed_expandable_fab.dart';

class DataTableScreen extends StatefulWidget {
  final String apiUrl;
  final String title;
  final Map? params;

  const DataTableScreen({
    super.key,
    required this.apiUrl,
    required this.title,
    this.params,
  });

  @override
  State<DataTableScreen> createState() => _DataTableScreenState();
}

class _DataTableScreenState extends State<DataTableScreen> {
  Map<String, dynamic>? jsonData;
  List<bool>? enabledColumns;
  bool isLoading = true;
  String? serverUrl;

  Map<String, dynamic>? _getBackground() {
    final bg = jsonData?['background'];
    if (bg is Map<String, dynamic>) return bg;
    if (bg is Map) return Map<String, dynamic>.from(bg);
    return null;
  }

  bool get _hasBackground => _getBackground() != null;

  BoxDecoration? _buildBackgroundDecoration(Map<String, dynamic>? background) {
    if (background == null) return null;

    final resolvedServerUrl =
        (serverUrl ?? defaultApiURL).replaceFirst('/api', '');
    final gradient = background['gradient'];
    final image = background['image'];

    Color? solidColor;
    if (background['light'] != null && background['dark'] != null) {
      solidColor = useThemeMode(
        context,
        light: Color(int.parse(
          background['light']!.toString().replaceFirst('#', '0xff'),
        )),
        dark: Color(int.parse(
          background['dark']!.toString().replaceFirst('#', '0xff'),
        )),
      );
    }

    List<Color> gradientColors = <Color>[];
    double gradientDeg = 0;
    if (gradient is Map) {
      final dynamic rawColors = useThemeMode(
        context,
        light:
            (gradient['light'] is Map ? gradient['light']['colors'] : null) ??
                gradient['colors'],
        dark: (gradient['dark'] is Map ? gradient['dark']['colors'] : null) ??
            gradient['colors'],
      );

      if (rawColors is List) {
        gradientColors = rawColors
            .map<Color>((colorString) => Color(
                int.parse(colorString.toString().replaceFirst('#', '0xff'))))
            .toList();
      }

      gradientDeg = double.tryParse(gradient['deg']?.toString() ?? '') ?? 0;
    }

    return BoxDecoration(
      gradient: gradientColors.isNotEmpty
          ? LinearGradient(
              colors: gradientColors,
              begin: Alignment(
                -1.0 * cos(gradientDeg / 90.0),
                -1.0 * sin(gradientDeg / 90.0),
              ),
              end: Alignment(
                1.0 * cos(gradientDeg / 90.0),
                1.0 * sin(gradientDeg / 90.0),
              ),
            )
          : null,
      color: gradientColors.isEmpty ? solidColor : null,
      image: image != null
          ? DecorationImage(
              image: CachedNetworkImageProvider(
                useThemeMode(
                  context,
                  light: "$resolvedServerUrl${image['light'] ?? image['dark']}",
                  dark: "$resolvedServerUrl${image['dark'] ?? image['light']}",
                ),
              ),
              opacity: useThemeMode(
                context,
                light: 0.2,
                dark: 0.5,
              ),
              fit: BoxFit.cover,
            )
          : null,
    );
  }

  Map<String, dynamic>? get _pagination {
    final p = jsonData?['pagination'];
    if (p is Map<String, dynamic>) return p;
    return null;
  }

  int get _currentPage {
    final p = _pagination;
    return int.tryParse(p?['current_page']?.toString() ?? '') ?? 1;
  }

  int get _lastPage {
    final p = _pagination;
    return int.tryParse(p?['last_page']?.toString() ?? '') ?? 1;
  }

  String _apiUrlWithPage(int page) {
    final base = Uri.parse(widget.apiUrl);
    final qp = Map<String, String>.from(base.queryParameters);
    qp['page'] = page.toString();
    final updated = base.replace(queryParameters: qp);
    final query = updated.query;
    return query.isEmpty ? updated.path : '${updated.path}?$query';
  }

  void _goToPage(int page) {
    if (page < 1 || page > _lastPage) return;
    if (page == _currentPage) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DataTableScreen(
          apiUrl: _apiUrlWithPage(page),
          title: widget.title,
          params: widget.params,
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final last = _lastPage;
    final current = _currentPage;

    if (last <= 1) return const SizedBox.shrink();

    const maxNumericButtons = 8; // Prev + (up to 4 pages) + Next = max 6
    int start = current - 1;
    start = start.clamp(1, (last - maxNumericButtons + 1).clamp(1, last));
    int end = (start + maxNumericButtons - 1).clamp(1, last);
    start = (end - maxNumericButtons + 1).clamp(1, last);

    final pageNumbers = <int>[];
    for (int p = start; p <= end; p++) {
      pageNumbers.add(p);
    }

    final themeColor = getThemeColor(context)!;

    final inactiveBg = useThemeMode(
      context,
      light: themeColor.shade200,
      dark: themeColor.shade800,
    );

    final inactiveFg = useThemeMode(
      context,
      light: themeColor.shade900,
      dark: themeColor.shade100,
    );

    final activeBg = useThemeMode(
      context,
      light: themeColor.shade500,
      dark: themeColor.shade500,
    );

    const activeFg = Colors.white;

    Widget chipButton({
      required Widget child,
      required bool active,
      required bool enabled,
      required VoidCallback? onTap,
      EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10),
    }) {
      final bg = active ? activeBg : inactiveBg;
      final fg = active ? activeFg : inactiveFg;

      return Opacity(
        opacity: enabled || active ? 1 : 0.45,
        child: Material(
          color: bg,
          borderRadius: getThemeBorderRadiusCircular(
            context,
            intensity: 'low',
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: getThemeBorderRadiusCircular(
              context,
              intensity: 'low',
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 40, maxHeight: 36),
              child: Padding(
                padding: padding,
                child: Center(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: fg, size: 18),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: getScreenSize(context, type: 'width'),
      margin: EdgeInsets.only(
        left: AppSpacing.kDefaultSpacing(context),
        right: AppSpacing.kDefaultSpacing(context),
        top: AppSpacing.kDefaultSpacing(context) * 0.6,
      ),
      child: Wrap(
        spacing: AppSpacing.kDefaultSpacing(context) * 0.5,
        runSpacing: AppSpacing.kDefaultSpacing(context) * 0.5,
        alignment: WrapAlignment.center,
        children: [
          chipButton(
            active: false,
            enabled: current > 1,
            onTap: current > 1 ? () => _goToPage(current - 1) : null,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconMapper.icon(
              'chevron-left',
              iconPack: context
                  .watch<CommonDataProvider>()
                  .currentThemeSetting
                  ?.iconPack,
            ),
          ),
          ...pageNumbers.map((p) {
            final active = p == current;
            return chipButton(
              active: active,
              enabled: !active,
              onTap: () => _goToPage(p),
              child: Text(p.toString()),
            );
          }),
          chipButton(
            active: false,
            enabled: current < last,
            onTap: current < last ? () => _goToPage(current + 1) : null,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconMapper.icon(
              'chevron-right',
              iconPack: context
                  .watch<CommonDataProvider>()
                  .currentThemeSetting
                  ?.iconPack,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchData({bool repeat = false}) async {
    setState(() {
      isLoading = true;
    });

    context.read<CommonDataProvider>().getData();

    final prefs = await SharedPreferences.getInstance();
    String serverUrl =
        prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    this.serverUrl = serverUrl;
    String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
    String token = prefs.getString(AppKeys.loginKey) ?? "";

    final url =
        "$serverUrl${widget.apiUrl.split('?')[0]}?token=$spToken${widget.apiUrl.split('?').length > 1 ? "&${widget.apiUrl.split('?')[1]}" : ""}";

    String? logId;
    final startTime = DateTime.now();

    try {
      if (!repeat &&
          prefs.getString(widget.apiUrl) != null &&
          prefs.getString(widget.apiUrl)!.isNotEmpty) {
        jsonData = jsonDecode(prefs.getString(widget.apiUrl)!);
        _initEnabledColumns();
        setState(() {
          isLoading = false;
        });
      }

      // Log request
      if (mounted) {
        logId = context.read<DebugProvider>().logRequest(
          method: 'GET',
          url: url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      final duration = DateTime.now().difference(startTime);

      // Log response
      if (mounted && logId != null) {
        context.read<DebugProvider>().logResponse(
              id: logId,
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: duration,
            );
      }

      prefs.setString(AppKeys.noInternetKey, "false");
      await context.read<CommonDataProvider>().checkInternet();

      final message = Message.fromJson(jsonDecode(response.body));

      if (message.invalidToken) {
        // Token is invalid, force logout
        prefs.remove(AppKeys.loginKey);
        await context.read<CommonDataProvider>().logout();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => WelcomeScreen(),
          ),
        );
      } else if (message.invalidLicenseToken) {
        prefs.clear();
        await context.read<CommonDataProvider>().clearData();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => WelcomeScreen(),
          ),
        );
      }

      if (response.statusCode == 200) {
        prefs.setString(widget.apiUrl, response.body);
        jsonData = jsonDecode(response.body);

        _initEnabledColumns();
        setState(() {});
      } else {
        Message message = Message.fromJson(jsonDecode(response.body));
        if (mounted) {
          showSnackBar(message.message, context, type: "error");
        }
      }
    } on SocketException catch (e) {
      // Log error
      if (mounted && logId != null) {
        context.read<DebugProvider>().logResponse(
              id: logId,
              error: 'Network error: ${e.message}',
              duration: DateTime.now().difference(startTime),
            );
      }
      prefs.setString(AppKeys.noInternetKey, "true");
      await context.read<CommonDataProvider>().checkInternet();
    } catch (e) {
      // Log error
      if (mounted && logId != null) {
        context.read<DebugProvider>().logResponse(
              id: logId,
              error: e.toString(),
              duration: DateTime.now().difference(startTime),
            );
      }
      if (mounted) {
        showSnackBar("An error occurred while fetching data", context,
            type: "error");
      }
    }

    setState(() {
      isLoading = false;
    });
    await Loading.stop(context);
  }

  void _initEnabledColumns() {
    if (jsonData != null && jsonData!['columns'] != null) {
      enabledColumns = List.generate(jsonData!['columns'].length, (_) => true);
    }
  }

  /// Calculate totals using formula evaluator
  Map<String, double> _calculateTotals() {
    if (jsonData == null ||
        jsonData!['totals'] == null ||
        jsonData!['rows'] == null) {
      return {};
    }

    final totals = <String, double>{};
    final totalsList = jsonData!['totals'] as List;
    final rows = List<Map<String, dynamic>>.from((jsonData!['rows'] as List)
        .map((row) => Map<String, dynamic>.from(row)));

    for (final totalConfig in totalsList) {
      final name = totalConfig['name'];
      final formula = totalConfig['formula'];

      if (name != null && formula != null) {
        if (formula == 'COUNT(*)') {
          totals[name] = rows.length.toDouble();
        } else if (FormulaEvaluator.hasAggregateFunction(formula)) {
          totals[name] =
              FormulaEvaluator.evaluateAggregateFormula(formula, rows);
        } else {
          totals[name] = 0.0;
        }
      }
    }

    return totals;
  }

  // Helper method to get column label (supports both old and new format)
  String _getColumnLabel(dynamic col) {
    if (col is Map<String, dynamic>) {
      return col['label'] ?? '';
    }
    return col.toString();
  }

  void _showModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final spacing = AppSpacing.kDefaultSpacing(ctx, useWatch: false);
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  color:
                      const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.4),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: EdgeInsets.all(spacing),
                  padding: EdgeInsets.symmetric(
                    vertical: spacing,
                    horizontal: spacing * 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: useThemeMode(context,
                        light: AppColors.white, dark: AppColors.slateSwatch),
                    borderRadius: getThemeBorderRadiusCircular(context),
                  ),
                  child: StatefulBuilder(builder: (context, setModalState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Enable or Disable Table Columns',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppTextButton(
                              child: IconMapper.icon(
                                'close',
                                iconPack: context
                                    .read<CommonDataProvider>()
                                    .currentThemeSetting
                                    ?.iconPack,
                              ),
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing * 0.5),
                        ...jsonData!['columns'].map<Widget>((col) {
                          int index = jsonData!['columns'].indexOf(col);
                          return AppCheckBox(
                            hintText: _getColumnLabel(col),
                            value: enabledColumns?[index] ?? true,
                            onChanged: (bool? value) {
                              setModalState(
                                  () => enabledColumns?[index] = value ?? true);
                              setState(
                                  () => enabledColumns?[index] = value ?? true);
                            },
                          );
                        }),
                        SizedBox(height: spacing * 0.5),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> deleteItem(String deleteUrl) async {
    final prefs = await SharedPreferences.getInstance();
    String serverUrl =
        prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
    String token = prefs.getString(AppKeys.loginKey) ?? "";

    String? requestId;
    final startTime = DateTime.now();

    try {
      final url = "$serverUrl$deleteUrl?token=$spToken";

      // Log DELETE request
      if (mounted) {
        requestId = context.read<DebugProvider>().logRequest(
          method: 'DELETE',
          url: url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      final message = Message.fromJson(jsonDecode(response.body));

      if (message.invalidToken) {
        // Token is invalid, force logout
        prefs.remove(AppKeys.loginKey);
        await context.read<CommonDataProvider>().logout();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => WelcomeScreen(),
          ),
        );
      } else if (message.invalidLicenseToken) {
        prefs.clear();
        await context.read<CommonDataProvider>().clearData();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => WelcomeScreen(),
          ),
        );
      }

      // Log DELETE response
      if (mounted && requestId != null) {
        context.read<DebugProvider>().logResponse(
              id: requestId,
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            );
      }

      if (response.statusCode == 200) {
        Message message = Message.fromJson(jsonDecode(response.body));
        if (mounted) {
          showSnackBar(message.message, context, type: "success");
        }
        await fetchData(repeat: true);
      } else {
        Message message = Message.fromJson(jsonDecode(response.body));

        if (mounted) {
          showSnackBar(message.message, context, type: "error");
        }
      }
    } on SocketException catch (e) {
      // Log error
      if (mounted && requestId != null) {
        context.read<DebugProvider>().logResponse(
              id: requestId,
              error: 'Network error: ${e.message}',
              duration: DateTime.now().difference(startTime),
            );
      }

      // Save to drafts
      final submission = OfflineSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: deleteUrl,
        method: 'DELETE',
        data: {},
        files: {},
        timestamp: DateTime.now(),
        title: 'Delete ${jsonData?['title'] ?? 'Item'}',
        formSchema: {},
      );

      if (mounted) {
        context.read<OfflineSubmissionProvider>().addSubmission(submission);
        showSnackBar("Offline. Saved to Drafts.", context, type: "success");
      }
    } catch (e) {
      // Log error
      if (mounted && requestId != null) {
        context.read<DebugProvider>().logResponse(
              id: requestId,
              error: e.toString(),
              duration: DateTime.now().difference(startTime),
            );
      }
      if (mounted) {
        showSnackBar("An error occurred while deleting", context,
            type: "error");
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String deleteUrl) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // User confirmed deletion
      await deleteItem(deleteUrl);
    }
  }

  /// Build the totals section widget
  Widget _buildTotalsSection() {
    final totals = _calculateTotals();
    final totalsList = jsonData!['totals'] as List;
    final totalsStyle = jsonData!['totals_style'] as Map<String, dynamic>?;

    return Container(
      width: getScreenSize(context, type: "width"),
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.kDefaultSpacing(context),
        vertical: AppSpacing.kDefaultSpacing(context),
      ),
      padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.2),
      decoration: BoxDecoration(
        color: totalsStyle?['background_color'] != null
            ? Color(int.parse(totalsStyle!['background_color']
                .toString()
                .replaceFirst('#', '0xff')))
            : useThemeMode(
                context,
                light: getThemeColor(context)?.shade100,
                dark: getThemeColor(context)?.shade800,
              ),
        borderRadius: getThemeBorderRadiusCircular(context),
        border: Border.all(
          width: 1.0,
          color: useThemeMode(
            context,
            light: getThemeColor(context)!.shade300,
            dark: getThemeColor(context)!.shade600,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: AppSpacing.kDefaultSpacing(context) * 1.1,
              fontWeight: FontWeight.bold,
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade900,
                dark: getThemeColor(context)?.shade100,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.8),
          ...totalsList.map((totalConfig) {
            final name = totalConfig['name'];
            final label = totalConfig['label'];
            final value = totals[name] ?? 0.0;
            final decimalPlaces = totalConfig['decimal_places'] ?? 2;
            final style = totalConfig['style'] as Map<String, dynamic>?;

            // Determine if this is a count/qty field
            final isCountField =
                name.toString().toLowerCase().contains('count') ||
                    name.toString().toLowerCase().contains('qty') ||
                    totalConfig['formula'] == 'COUNT(*)';

            String displayValue;
            if (isCountField) {
              displayValue = value.toInt().toString();
            } else {
              displayValue = value.toStringAsFixed(decimalPlaces);
            }

            return Container(
              margin: EdgeInsets.only(
                bottom: AppSpacing.kDefaultSpacing(context) * 0.5,
              ),
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.kDefaultSpacing(context) * 0.6,
                horizontal: AppSpacing.kDefaultSpacing(context) * 0.8,
              ),
              decoration: BoxDecoration(
                color: style?['background_color'] != null
                    ? Color(int.parse(style!['background_color']
                        .toString()
                        .replaceFirst('#', '0xff')))
                    : Colors.transparent,
                borderRadius: getThemeBorderRadiusCircular(
                  context,
                  intensity: 'low',
                ),
                border: style?['border_top'] != null
                    ? Border(
                        top: BorderSide(
                          width: 2.0,
                          color: Color(int.parse(style!['border_top']
                              .toString()
                              .split(' ')
                              .last
                              .replaceFirst('#', '0xff'))),
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context) * 0.95,
                      fontWeight: style?['font_weight'] == 'bold'
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: useThemeMode(
                        context,
                        light: getThemeColor(context)?.shade800,
                        dark: getThemeColor(context)?.shade200,
                      ),
                    ),
                  ),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context) * 0.95,
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
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = _getBackground();
    final isGradient = background?['gradient'] != null;
    final isGlass = background?['image'] != null;
    final bodyPadding = _hasBackground
        ? EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          )
        : EdgeInsets.zero;

    Widget wrapTable(Widget child) {
      if (!isGradient && !isGlass) return child;

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.kDefaultSpacing(context),
        ),
        padding: EdgeInsets.all(
          AppSpacing.kDefaultSpacing(context) * 0.6,
        ),
        decoration: BoxDecoration(
          border: isGlass
              ? Border.all(
                  width: 0.5,
                  color: useThemeMode(
                    context,
                    light: Colors.white.withValues(alpha: 0.6),
                    dark: Colors.white.withValues(alpha: 0.1),
                  ),
                )
              : Border.all(
                  width: 0.5,
                  color: useThemeMode(
                    context,
                    light:
                        getThemeColor(context)?.shade500.withValues(alpha: 0.5),
                    dark:
                        getThemeColor(context)?.shade100.withValues(alpha: 0.5),
                  ),
                ),
          color: isGlass
              ? useThemeMode(
                  context,
                  light: Colors.white.withValues(alpha: 0.5),
                  dark: Colors.white.withValues(alpha: 0.1),
                )
              : useThemeMode(
                  context,
                  light: isGradient
                      ? getThemeColor(context)?.shade100.withValues(alpha: 0.9)
                      : getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                  dark: isGradient
                      ? getThemeColor(context)?.shade900.withValues(alpha: 0.9)
                      : getThemeColor(context)?.shade50.withValues(alpha: 0.1),
                ),
          borderRadius: getThemeBorderRadiusCircular(context),
          boxShadow: isGradient
              ? [
                  BoxShadow(
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)
                          ?.shade100
                          .withValues(alpha: 0.25),
                      dark: getThemeColor(context)
                          ?.shade900
                          .withValues(alpha: 0.5),
                    ),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: child,
      );
    }

    final tableContent = AppLoader(
      isSyncing: isLoading,
      isForm: false,
      child: LiquidPullToRefresh(
        color: useThemeMode(
          context,
          light: getThemeColor(context)?.shade400.withValues(alpha: 0.2),
          dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
        ),
        backgroundColor: useThemeMode(
          context,
          light: getThemeColor(context),
          dark: getThemeColor(context)?.shade100,
        ),
        onRefresh: () => fetchData(repeat: true),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: jsonData == null
              ? Center(
                  child: CircularProgressIndicator.adaptive(),
                )
              : jsonData!['rows'] == null ||
                      jsonData!['columns'] == null ||
                      (jsonData!['rows'] as List).isEmpty
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.kDefaultSpacing(context) * 5,
                      ),
                      width: getScreenSize(context),
                      height: getScreenSize(context),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/no_data.json',
                            width: AppSpacing.kDefaultSpacing(context) * 15,
                            height: AppSpacing.kDefaultSpacing(context) * 15,
                          ),
                          Text(
                            "No Data Found...",
                            style: TextStyle(
                              fontSize:
                                  AppSpacing.kDefaultSpacing(context) * 1.8,
                              fontWeight: FontWeight.bold,
                              color: useThemeMode(
                                context,
                                light: getThemeColor(context)
                                    ?.shade900
                                    .withValues(alpha: 0.7),
                                dark: getThemeColor(context)?.shade200,
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(delay: 3.seconds, duration: 1800.ms)
                          .shake(hz: 4, curve: Curves.easeInOutCubic)
                          .scaleX(begin: 1.0, end: 1.1, duration: 600.ms)
                          .then(delay: 200.ms)
                          .scaleX(begin: 1.0, end: 1 / 1.1),
                    )
                  : SizedBox(
                      width: getScreenSize(context, type: "width"),
                      height: getScreenSize(context),
                      child: AppTableScroller(
                        controller: ScrollController(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            wrapTable(
                              SortableTable(
                                rows: jsonData!['rows'],
                                columns: jsonData!['columns'],
                                enabledColumns: enabledColumns,
                                dataRowHeight:
                                    jsonData!['row_height']?.toDouble() ?? 56.0,
                                onTap: (rowId) {
                                  // First, check if jsonData has a 'view' object
                                  if (jsonData!['view'] != null &&
                                      jsonData!['view'] is Map) {
                                    final viewAction = jsonData!['view']
                                        as Map<String, dynamic>;
                                    final apiUrlValue = viewAction['api_url'];
                                    final typeValue = viewAction['type'];

                                    if (apiUrlValue != null &&
                                        typeValue != null) {
                                      // Get the row data for placeholder replacement
                                      final row = jsonData!['rows'].firstWhere(
                                        (r) => r['id'] == rowId,
                                        orElse: () => null,
                                      );

                                      if (row != null) {
                                        // Replace placeholders in URL with row data
                                        String apiUrl = apiUrlValue.toString();
                                        final regex =
                                            RegExp(r'\{([a-zA-Z0-9_]+)\}');
                                        apiUrl = apiUrl.replaceAllMapped(regex,
                                            (match) {
                                          String fieldName = match.group(1)!;
                                          return row[fieldName]?.toString() ??
                                              match.group(0)!;
                                        });

                                        // Navigate to the screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => getNavScreen(
                                              context,
                                              NavLink(
                                                title: "",
                                                group: false,
                                                apiUrl: apiUrl,
                                                type: typeValue.toString(),
                                                params: widget.params,
                                              ),
                                            ),
                                          ),
                                        ).then((_) => fetchData(repeat: true));
                                      }
                                      return;
                                    }
                                  }

                                  // If no view action, look for edit action in columns
                                  Map<String, dynamic>? editAction;
                                  for (var column in jsonData!['columns']) {
                                    if (column is Map<String, dynamic> &&
                                        column['type'] == 'row' &&
                                        column['children'] != null) {
                                      // Search for edit action in children
                                      for (var child in column['children']) {
                                        if (child is Map<String, dynamic> &&
                                            child['type'] == 'action' &&
                                            child['icon'] == 'edit' &&
                                            child['action'] != null &&
                                            child['action'] is Map) {
                                          editAction = child['action']
                                              as Map<String, dynamic>;
                                          break;
                                        }
                                      }
                                      if (editAction != null) break;
                                    }
                                  }

                                  // If found edit action, use it
                                  if (editAction != null) {
                                    final apiUrlValue = editAction['api_url'];
                                    final typeValue = editAction['type'];

                                    if (apiUrlValue != null &&
                                        typeValue != null) {
                                      // Get the row data for placeholder replacement
                                      final row = jsonData!['rows'].firstWhere(
                                        (r) => r['id'] == rowId,
                                        orElse: () => null,
                                      );

                                      if (row != null) {
                                        // Replace placeholders in URL with row data
                                        String apiUrl = apiUrlValue.toString();
                                        final regex =
                                            RegExp(r'\{([a-zA-Z0-9_]+)\}');
                                        apiUrl = apiUrl.replaceAllMapped(regex,
                                            (match) {
                                          String fieldName = match.group(1)!;
                                          return row[fieldName]?.toString() ??
                                              match.group(0)!;
                                        });

                                        // Navigate to the screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => getNavScreen(
                                              context,
                                              NavLink(
                                                title: "",
                                                group: false,
                                                apiUrl: apiUrl,
                                                type: typeValue.toString(),
                                                params: widget.params,
                                              ),
                                            ),
                                          ),
                                        ).then((_) => fetchData(repeat: true));
                                      }
                                      return;
                                    }
                                  }

                                  // If neither view nor edit action exists, do nothing
                                },
                                onDelete: (apiUrl) async {
                                  await _showDeleteDialog(context, apiUrl);
                                },
                              ),
                            ),

                            // Totals Section
                            if (jsonData!['totals'] != null &&
                                (jsonData!['totals'] as List).isNotEmpty)
                              _buildTotalsSection(),

                            if (_pagination != null) _buildPaginationBar(),
                            SizedBox(
                              height: (jsonData!['rows'] != null &&
                                      (jsonData!['rows'] as List).length > 20)
                                  ? AppSpacing.kDefaultSpacing(context) * 12
                                  : AppSpacing.kDefaultSpacing(context) * 20,
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    ).animate().fade(
          duration: Duration(
            seconds: 1,
          ),
          curve: Curves.easeInExpo,
        );

    return Scaffold(
      extendBodyBehindAppBar: _hasBackground,
      appBar: AppBar(
        backgroundColor: _hasBackground ? Colors.transparent : null,
        elevation: _hasBackground ? 0 : null,
        surfaceTintColor: _hasBackground ? Colors.transparent : null,
        title: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              jsonData?['title'] ?? widget.title,
            ).animate().slideX(
                  begin: -1.0,
                  end: 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
            if (jsonData != null && jsonData!['rows'] != null)
              IconButton(
                icon: FittedBox(
                  child: Countup(
                    begin: 0,
                    end: jsonData!['pagination'] != null
                        ? double.tryParse(
                            jsonData!['pagination']['current_page'].toString())
                        : jsonData!['rows'].length.toDouble(),
                    prefix: "(",
                    suffix: ")",
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context) * 1.2,
                    ),
                  ),
                ),
                onPressed: () {},
                tooltip: jsonData!['pagination'] != null
                    ? "Current Page: ${jsonData!['pagination']['current_page']} of ${jsonData!['pagination']['last_page']}"
                    : "Total Rows",
              ).animate().slideX(
                    begin: 1.0,
                    end: 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
          ],
        ),
        actions: [
          const DraftButton(),
          // Debug icon button
          if (jsonData?['debug_bar'] == true)
            IconButton(
              icon: IconMapper.icon(
                'bug',
                iconPack: context
                    .watch<CommonDataProvider>()
                    .currentThemeSetting!
                    .iconPack,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebugScreen()),
                );
              },
              tooltip: "Debug Console",
            ).animate().slideX(
                  begin: 1.0,
                  end: 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
          IconButton(
            icon: IconMapper.icon(
              'view',
              iconPack: context
                  .watch<CommonDataProvider>()
                  .currentThemeSetting!
                  .iconPack,
            ),
            onPressed: () {
              _showModal(context);
            },
            tooltip: "Enable or Disable Table Column",
          ).animate().slideX(
                begin: 1.0,
                end: 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
          if (jsonData?['import_url'] != null)
            IconButton(
              icon: IconMapper.icon(
                'file-import',
                iconPack: context
                    .watch<CommonDataProvider>()
                    .currentThemeSetting!
                    .iconPack,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DynamicFormScreen(
                      apiUrl: jsonData!['import_url'],
                      title: "Import",
                      params: widget.params,
                    ),
                  ),
                ).then((_) => fetchData(repeat: true));
              },
            ).animate().slideX(
                  begin: 1.0,
                  end: 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
        ],
        leading: const AppDrawerIcon(),
      ),
      drawer: AppDrawer(
        activeLink: widget.apiUrl,
      ),
      body: Stack(
        children: [
          if (_hasBackground)
            Positioned.fill(
              child: Container(
                decoration: _buildBackgroundDecoration(background),
              ),
            ),
          Padding(
            padding: bodyPadding,
            child: tableContent,
          ),
        ],
      ),
      floatingActionButton: jsonData != null && jsonData!['add_url'] != null
          ? (() {
              final String label =
                  (jsonData!['add_text']?.toString().trim().isNotEmpty ?? false)
                      ? jsonData!['add_text'].toString()
                      : '';

              return DelayedExpandableFab(
                iconKey: 'plus',
                label: label,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DynamicFormScreen(
                        apiUrl: jsonData!['add_url'],
                        title: "Add",
                        params: widget.params,
                      ),
                    ),
                  ).then((_) => fetchData(repeat: true));
                },
              ).animate().slideY(
                    begin: 1.0,
                    end: 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
            })()
          : null,
    );
  }
}
