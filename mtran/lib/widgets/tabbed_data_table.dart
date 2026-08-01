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
import 'package:salepro/models/offline_submission.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/providers/offline_submission_provider.dart';
import 'package:salepro/screens/auth/welcome.dart';
import 'package:salepro/screens/debug_screen.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../constants/spacing.dart';
import '../utils/get_screensize.dart';
import '../utils/get_theme_color.dart';
import '../utils/get_theme_border_radius.dart';
import '../utils/is_dark.dart';
import '../widgets/app_loader.dart';
import 'dynamic_form_screen.dart';
import 'package:salepro/widgets/delayed_expandable_fab.dart';
import '../widgets/drawer.dart';
import '../widgets/sortable_table.dart';
import '../widgets/draft_button.dart';

class TabbedDataTableScreen extends StatefulWidget {
  final String apiUrl;
  final String title;
  final Map? params;

  const TabbedDataTableScreen({
    super.key,
    required this.apiUrl,
    required this.title,
    this.params,
  });

  @override
  State<TabbedDataTableScreen> createState() => _TabbedDataTableScreenState();
}

class _TabbedDataTableScreenState extends State<TabbedDataTableScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? jsonData;
  List<bool>? enabledColumns;
  bool isLoading = true;
  int _activeIndex = 0;
  late PageController _pageController;
  late TabController _tabController;
  String? serverUrl;

  Map<String, dynamic>? _extractBackground(dynamic data) {
    if (data is Map<String, dynamic> && data['background'] is Map) {
      return Map<String, dynamic>.from(data['background']);
    }
    if (data is Map && data['background'] is Map) {
      return Map<String, dynamic>.from(data['background']);
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Map<String, dynamic>? _getActiveBackground() {
    if (jsonData == null) return null;
    final tabs = jsonData!['tabs'];
    if (tabs is List && tabs.isNotEmpty && tabs.length > _activeIndex) {
      final tab = tabs[_activeIndex];
      final tabBg = _extractBackground(tab);
      if (tabBg != null &&
          (tabBg['gradient'] != null ||
              tabBg['image'] != null ||
              (tabBg['light'] != null && tabBg['dark'] != null))) {
        return tabBg;
      }
    }
    return _extractBackground(jsonData?['background']);
  }

  bool get _hasBackground => _getActiveBackground() != null;

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 0, vsync: this);
    fetchData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
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

    try {
      if (!repeat &&
          prefs.getString(widget.apiUrl) != null &&
          prefs.getString(widget.apiUrl)!.isNotEmpty) {
        jsonData = jsonDecode(prefs.getString(widget.apiUrl)!);
        _updateTabController();
        setState(() {
          isLoading = false;
        });
      }

      final uri = Uri.parse(
          "$serverUrl${widget.apiUrl.split('?')[0]}?token=$spToken${widget.apiUrl.split('?').length > 1 ? "&${widget.apiUrl.split('?')[1]}" : ""}");

      // Start timing for debug logging
      final startTime = DateTime.now();

      // Log the request
      String? requestId;
      if (mounted) {
        requestId = context.read<DebugProvider>().logRequest(
          method: 'GET',
          url: uri.toString(),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }

      final response = await http.get(
        uri,
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

      prefs.setString(AppKeys.noInternetKey, "false");
      await context.read<CommonDataProvider>().checkInternet();

      if (response.statusCode == 200) {
        prefs.setString(widget.apiUrl, response.body);
        jsonData = jsonDecode(response.body);
        _updateTabController();
        setState(() {});
      } else {
        Message message = Message.fromJson(jsonDecode(response.body));
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
        if (mounted) {
          showSnackBar(message.message, context, type: "error");
        }
      }
    } on SocketException catch (_) {
      prefs.setString(AppKeys.noInternetKey, "true");
      await context.read<CommonDataProvider>().checkInternet();
      if (prefs.getString(widget.apiUrl) != null &&
          prefs.getString(widget.apiUrl)!.isNotEmpty) {
        jsonData = jsonDecode(prefs.getString(widget.apiUrl)!);
        _updateTabController();
        setState(() {});
      } else {
        if (mounted) {
          showSnackBar(
              "You are in offline mode and no cached data is available for this page.",
              context,
              type: "error");
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar("An error occurred while fetching data", context,
            type: "error");
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void _updateTabController() {
    if (jsonData != null && jsonData!['tabs'] != null) {
      final tabsLength = (jsonData!['tabs'] as List).length;
      _tabController.dispose();
      _tabController = TabController(length: tabsLength, vsync: this);
    }
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
        if (mounted) {
          showSnackBar(message.message, context, type: "success");
        }
        await fetchData(repeat: true);
      } else {
        Message message = Message.fromJson(jsonDecode(response.body));
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

  @override
  Widget build(BuildContext context) {
    final background = _getActiveBackground();
    final bodyPadding = _hasBackground
        ? EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          )
        : EdgeInsets.zero;

    Widget wrapTable(
      Widget child, {
      required bool isGradient,
      required bool isGlass,
    }) {
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

    final content = AppLoader(
      isSyncing: isLoading,
      isForm: false,
      includeScrollView: false,
      child: jsonData == null
          ? Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : jsonData!['tabs'] == null ||
                  jsonData!['tabs'].isEmpty ||
                  jsonData!['tabs'].length <= _activeIndex ||
                  (jsonData!['tabs'][_activeIndex]['rows'] as List).isEmpty
              ? Expanded(
                  child: LiquidPullToRefresh(
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)
                          ?.shade400
                          .withValues(alpha: 0.2),
                      dark: getThemeColor(context)
                          ?.shade900
                          .withValues(alpha: 0.2),
                    ),
                    backgroundColor: useThemeMode(
                      context,
                      light: getThemeColor(context),
                      dark: getThemeColor(context)?.shade100,
                    ),
                    onRefresh: () => fetchData(repeat: true),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
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
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .shimmer(delay: 3.seconds, duration: 1800.ms)
                            .shake(hz: 4, curve: Curves.easeInOutCubic)
                            .scaleX(begin: 1.0, end: 1.1, duration: 600.ms)
                            .then(delay: 200.ms)
                            .scaleX(begin: 1.0, end: 1 / 1.1),
                      ),
                    ),
                  ),
                )
              : Expanded(
                  child: PageView(
                    allowImplicitScrolling: true,
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _activeIndex = index;
                        _tabController.animateTo(index);
                      });
                    },
                    children: jsonData!['tabs'].map<Widget>((tab) {
                      final tabBackground =
                          _extractBackground(tab) ?? background;
                      final tabIsGradient = tabBackground?['gradient'] != null;
                      final tabIsGlass = tabBackground?['image'] != null;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: wrapTable(
                          SortableTable(
                            rows: tab['rows'],
                            columns: tab['columns']
                                .map((c) => c.toString())
                                .toList(),
                            dataRowHeight:
                                tab['row_height']?.toDouble() ?? 56.0,
                            onDelete: (apiUrl) async {
                              await _showDeleteDialog(context, apiUrl);
                            },
                          ),
                          isGradient: tabIsGradient,
                          isGlass: tabIsGlass,
                        ),
                      );
                    }).toList(),
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
            if (jsonData != null)
              IconButton(
                icon: FittedBox(
                  child: Countup(
                    begin: 0,
                    end: jsonData!['tabs'][_activeIndex]['rows']
                        .length
                        .toDouble(),
                    prefix: "(",
                    suffix: ")",
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context) * 1.2,
                    ),
                  ),
                ),
                onPressed: () {},
                tooltip: "Total Rows",
              ).animate().slideX(
                    begin: 1.0,
                    end: 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: useThemeMode(
            context,
            light: getThemeColor(context)?.shade900,
            dark: getThemeColor(context)?.shade200,
          ),
          labelColor: useThemeMode(
            context,
            light: getThemeColor(context)?.shade900,
            dark: Colors.white,
          ),
          unselectedLabelColor: useThemeMode(
            context,
            light: getThemeColor(context)?.shade700.withValues(alpha: 0.6),
            dark: Colors.white.withValues(alpha: 0.6),
          ),
          onTap: (index) {
            setState(() {
              _activeIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          tabs: jsonData?['tabs']?.map<Widget>(
                (tab) {
                  return Tab(
                    text: tab['title']?.toString() ?? '',
                  );
                },
              ).toList() ??
              [],
        ),
        actions: [
          const DraftButton(),
          if (jsonData?['debug_bar'] == true)
            IconButton(
              icon: IconMapper.icon(
                'bug',
                iconPack: context
                    .watch<CommonDataProvider>()
                    .currentThemeSetting!
                    .iconPack,
              ),
              tooltip: 'Debug Console',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugScreen(),
                  ),
                );
              },
            ).animate().slideX(
                  begin: 1.0,
                  end: 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
          if (jsonData?['tabs'][_activeIndex]['import_url'] != null)
            IconButton(
              icon: IconMapper.icon(
                'file-import',
                iconPack: context
                    .watch<CommonDataProvider>()
                    .currentThemeSetting
                    ?.iconPack,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DynamicFormScreen(
                      apiUrl: jsonData!['tabs'][_activeIndex]['import_url'],
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
            child: content,
          ),
        ],
      ),
      floatingActionButton: jsonData != null &&
              jsonData!['tabs'] != null &&
              jsonData!['tabs'].length > _activeIndex &&
              jsonData!['tabs'][_activeIndex]['add_url'] != null
          ? (() {
              final tab = jsonData!['tabs'][_activeIndex] as Map;
              final String label =
                  (tab['add_text']?.toString().trim().isNotEmpty ?? false)
                      ? tab['add_text'].toString()
                      : "Add ${tab['title'] ?? ''}".trimRight();

              return DelayedExpandableFab(
                label: label.isEmpty ? 'Add' : label,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DynamicFormScreen(
                        apiUrl: tab['add_url'],
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
