import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:countup/countup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/models/message.dart';
import 'package:salepro/models/theme_setting.dart';
import 'package:salepro/api/theme_settings.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/screens/auth/welcome.dart';
import 'package:salepro/screens/debug_screen.dart';
import 'package:salepro/providers/theme_provider.dart';
import 'package:salepro/utils/get_border_radius.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';
import 'package:salepro/widgets/app_loader.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/widgets/drawer.dart';
import 'package:salepro/widgets/summary_box.dart' as sb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:salepro/widgets/draft_button.dart';

class CustomViewScreen extends StatefulWidget {
  final String apiUrl;
  final String title;
  final Map? params;

  const CustomViewScreen({
    super.key,
    required this.apiUrl,
    required this.title,
    this.params,
  });

  @override
  State<CustomViewScreen> createState() => _CustomViewScreenState();
}

class _CustomViewScreenState extends State<CustomViewScreen> {
  bool isLoading = true;
  Map<String, dynamic>? viewData;
  String? errorMessage;
  final Map<String, Set<String>> _hiddenLegendItems = {};
  final Map<String, int> _touchedPieSections = {};
  String? serverUrl;

  Map<String, dynamic>? _getBackground() {
    final bg = viewData?['background'];
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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData({bool repeat = false}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
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

    // Load cached data first if available (unless it's a refresh)
    if (!repeat) {
      if (prefs.getString(widget.apiUrl) != null &&
          prefs.getString(widget.apiUrl)!.isNotEmpty) {
        try {
          final cachedData = jsonDecode(prefs.getString(widget.apiUrl)!);
          setState(() {
            viewData = cachedData;
            isLoading = false;
          });
        } catch (e) {
          // Invalid cached data, continue to fetch from network
        }
      }
    }

    String? logId;
    final startTime = DateTime.now();

    try {
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final message = Message.fromJson(responseData);

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

        // Cache the response for offline access
        prefs.setString(widget.apiUrl, response.body);

        // Handle success response wrapper if present
        if (responseData['success'] == true) {
          viewData = responseData;
        } else if (responseData['success'] == false) {
          // Backend returned error with success: false
          setState(() {
            errorMessage =
                responseData['message'] ?? 'Unknown error from server';
            isLoading = false;
          });
          return;
        } else {
          viewData = responseData;
        }

        setState(() {
          isLoading = false;
        });
      } else {
        if (prefs.getString(widget.apiUrl) != null &&
            prefs.getString(widget.apiUrl)!.isNotEmpty) {
          try {
            final cachedData = jsonDecode(prefs.getString(widget.apiUrl)!);
            setState(() {
              viewData = cachedData;
              isLoading = false;
            });
            await context.read<CommonDataProvider>().checkInternet();
          } catch (e) {
            // Failed to parse cached data
            prefs.setString(AppKeys.noInternetKey, "true");
            await context.read<CommonDataProvider>().checkInternet();
            setState(() {
              errorMessage = "No internet connection";
              isLoading = false;
            });
          }
        } else {
          Message message = Message.fromJson(jsonDecode(response.body));
          setState(() {
            errorMessage = message.message;
            isLoading = false;
          });
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

      // Try to load cached data on network error
      if (prefs.getString(widget.apiUrl) != null &&
          prefs.getString(widget.apiUrl)!.isNotEmpty) {
        try {
          final cachedData = jsonDecode(prefs.getString(widget.apiUrl)!);
          setState(() {
            viewData = cachedData;
            isLoading = false;
          });
          prefs.setString(AppKeys.noInternetKey, "true");
          await context.read<CommonDataProvider>().checkInternet();
        } catch (e) {
          // Failed to parse cached data
          prefs.setString(AppKeys.noInternetKey, "true");
          await context.read<CommonDataProvider>().checkInternet();
          setState(() {
            errorMessage = "No internet connection";
            isLoading = false;
          });
        }
      } else {
        // No cached data available
        prefs.setString(AppKeys.noInternetKey, "true");
        await context.read<CommonDataProvider>().checkInternet();
        setState(() {
          errorMessage =
              "You are currently in offline mode and this page is not available in offline mode...";
          isLoading = false;
        });
      }
    } catch (e) {
      // Log error
      if (mounted && logId != null) {
        context.read<DebugProvider>().logResponse(
              id: logId,
              error: e.toString(),
              duration: DateTime.now().difference(startTime),
            );
      }
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = _getBackground();
    final bodyPadding = _hasBackground
        ? EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          )
        : EdgeInsets.zero;

    return Scaffold(
      extendBodyBehindAppBar: _hasBackground,
      appBar: AppBar(
        backgroundColor: _hasBackground ? Colors.transparent : null,
        elevation: _hasBackground ? 0 : null,
        surfaceTintColor: _hasBackground ? Colors.transparent : null,
        title: Text(viewData?['title'] ?? widget.title),
        actions: [
          const DraftButton(),
          // Debug icon button
          if (viewData?['debug_bar'] == true)
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
            child: Column(
              children: [
                AppBanner(
                  title:
                      "Backing Up Data from the Server (${(context.watch<CommonDataProvider>().progressCount / context.watch<CommonDataProvider>().totalCount * 100).toStringAsFixed(0)}%)",
                  show: context.watch<CommonDataProvider>().isSyncing,
                  right: SizedBox(
                    width: AppSpacing.kDefaultSpacing(context),
                    height: AppSpacing.kDefaultSpacing(context),
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: AppSpacing.kDefaultSpacing(context) * 2,
                    ),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (errorMessage != null) {
      final iconPack =
          context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconMapper.icon(
              'error-outline',
              iconPack: iconPack,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(errorMessage ?? 'Unknown error'),
            const SizedBox(height: 16),
            AppButton(
              onPressed: fetchData,
              title: 'Retry',
            ),
          ],
        ),
      );
    }

    if (viewData == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Detect view type from response
    final viewType = viewData!['view_type'] ?? 'default';

    switch (viewType) {
      case 'statistics':
        return _buildStatisticsView();
      case 'balance_sheet':
        return _buildBalanceSheet();
      case 'chart':
        return _buildChartView();
      case 'calendar':
        return _buildCalendarView();
      case 'report':
        return _buildReportView();
      case 'summary':
        return _buildSummaryView();
      case 'theme_settings':
        return _buildThemeSettingsView();
      default:
        return _buildDefaultView();
    }
  }

  List<String> _themeAppearanceSupportIcons(String raw) {
    switch (raw) {
      case 'system_both':
        return const [
          'appearance-system',
          'appearance-light',
          'appearance-dark'
        ];
      case 'system':
        return const ['appearance-system'];
      case 'both':
        return const ['appearance-light', 'appearance-dark'];
      case 'light':
        return const ['appearance-light'];
      case 'dark':
        return const ['appearance-dark'];
      default:
        return const ['appearance-system'];
    }
  }

  Future<void> _onSelectThemeSetting(ThemeSetting theme) async {
    final commonData = context.read<CommonDataProvider>();
    final previousTheme = commonData.currentThemeSetting;

    // Optimistic update: apply immediately so UI/theme changes instantly.
    await commonData.setCurrentThemeSetting(theme);

    final message = await changeActiveThemeSetting(theme.id);
    if (!mounted) return;

    if (message.success) {
      // Re-sync to match backend's canonical `current_theme_setting`.
      await commonData.getData();
      if (!mounted) return;

      showSnackBar(
        message.message.isNotEmpty ? message.message : 'Theme updated.',
        context,
        type: 'success',
      );
      return;
    }

    // Rollback optimistic update on failure.
    if (previousTheme != null) {
      await commonData.setCurrentThemeSetting(previousTheme);
    }
    if (!mounted) return;

    showSnackBar(
      message.message.isNotEmpty ? message.message : 'Failed to update theme.',
      context,
      type: 'error',
    );
  }

  Widget _buildThemeSettingsView() {
    final rawThemes = viewData?['themes'] ??
        viewData?['theme_settings'] ??
        viewData?['themeSettings'];
    final List<Map<String, dynamic>> themesJson = rawThemes is List
        ? rawThemes
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final themes = themesJson.map(ThemeSetting.fromJson).toList();
    final int? selectedId =
        context.watch<CommonDataProvider>().currentThemeSetting?.id;

    final String themeAppearance = context
            .watch<CommonDataProvider>()
            .currentThemeSetting
            ?.themeAppearance ??
        'system_both';
    final appearanceIcons = _themeAppearanceSupportIcons(themeAppearance);

    return RefreshIndicator(
      onRefresh: () => fetchData(repeat: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            SizedBox(
              height: AppSpacing.kDefaultSpacing(context) * 4,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (appearanceIcons.contains('appearance-system'))
                    _AppearanceBox(
                      iconKey: 'appearance-system',
                      color: getThemeColor(context) ?? AppColors.indigoSwatch,
                      iconColor:
                          (getThemeColor(context) ?? AppColors.indigoSwatch)
                              .shade50,
                      isSelected:
                          context.watch<ThemeProvider>().themeAppearence ==
                              'system',
                      onTap: () => context
                          .read<ThemeProvider>()
                          .changeThemeAppearence('system'),
                    ),
                  if (appearanceIcons.contains('appearance-light'))
                    _AppearanceBox(
                      iconKey: 'appearance-light',
                      color: Colors.white,
                      iconColor: AppColors.orangeSwatch,
                      isSelected:
                          Theme.of(context).brightness == Brightness.light,
                      onTap: () => context
                          .read<ThemeProvider>()
                          .changeThemeAppearence('light'),
                    ),
                  if (appearanceIcons.contains('appearance-dark'))
                    _AppearanceBox(
                      iconKey: 'appearance-dark',
                      color: AppColors.slateSwatch,
                      iconColor: AppColors.white,
                      isSelected:
                          Theme.of(context).brightness == Brightness.dark,
                      onTap: () => context
                          .read<ThemeProvider>()
                          .changeThemeAppearence('dark'),
                    ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.kDefaultSpacing(context) * 2),
            Text(
              'Select Your Preferred Theme',
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            if (themes.isEmpty)
              Text(
                'No themes available.',
                style: const TextStyle(),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: themes.length,
                separatorBuilder: (context, __) =>
                    SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                itemBuilder: (context, index) {
                  final t = themes[index];
                  return SizedBox(
                    height: 165,
                    child: _ThemePresetCard(
                      themeSetting: t,
                      isSelected: selectedId == t.id,
                      onTap: () => _onSelectThemeSetting(t),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSheet() {
    final data = viewData!['data'] as Map<String, dynamic>?;

    if (data == null) {
      return const Center(child: Text('No balance sheet data available'));
    }

    return RefreshIndicator(
      onRefresh: () => fetchData(repeat: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assets Section
            if (data['assets'] != null) ...[
              _buildSectionHeader('Assets'),
              SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),
              _buildBalanceSheetSection(data['assets'] as Map<String, dynamic>),
              SizedBox(height: AppSpacing.kDefaultSpacing(context) * 1.5),
            ],

            // Liabilities Section
            if (data['liabilities'] != null) ...[
              _buildSectionHeader('Liabilities'),
              SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),
              _buildBalanceSheetSection(
                  data['liabilities'] as Map<String, dynamic>),
              SizedBox(height: AppSpacing.kDefaultSpacing(context) * 1.5),
            ],

            // Equity Section
            if (data['equity'] != null) ...[
              _buildSectionHeader('Equity'),
              SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),
              _buildBalanceSheetSection(data['equity'] as Map<String, dynamic>),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSheetSection(Map<String, dynamic> section) {
    return Container(
      decoration: BoxDecoration(
        color: useThemeMode(
          context,
          light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
          dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(
          getThemeBorderRadius(context, intensity: 'medium'),
        ),
      ),
      padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.2),
      child: Column(
        children: section.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: getThemeFont(context),
                    color: useThemeMode(
                      context,
                      light: AppColors.slateColor[700],
                      dark: AppColors.slateColor[200],
                    ),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: getThemeFont(context),
                    color: useThemeMode(
                      context,
                      light: AppColors.slateColor[900],
                      dark: AppColors.slateColor[50],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartView() {
    final chartData = viewData!['chart_data'] as Map<String, dynamic>?;
    final chartType = viewData!['chart_type'] ?? 'bar';
    final subtitle = viewData!['subtitle'];

    if (chartData == null) {
      return const Center(child: Text('No chart data available'));
    }

    return RefreshIndicator(
      onRefresh: () => fetchData(repeat: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: getThemeFont(context),
                    color: useThemeMode(
                      context,
                      light: AppColors.slateColor[600],
                      dark: AppColors.slateColor[300],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              decoration: BoxDecoration(
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                  dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(
                  getThemeBorderRadius(context, intensity: 'medium'),
                ),
              ),
              padding:
                  EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.2),
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: chartType == 'bar'
                        ? _buildBarChart(chartData, "main_chart")
                        : chartType == 'pie'
                            ? _buildPieChart(chartData, "main_chart")
                            : chartType == 'line'
                                ? _buildLineChart(chartData, "main_chart")
                                : Center(
                                    child: Text(
                                      'Unsupported chart type: $chartType',
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView() {
    final reportData = viewData!['report_data'] as List<dynamic>?;
    final columns = viewData!['columns'] as List<dynamic>?;

    if (reportData == null || columns == null) {
      return const Center(child: Text('No report data available'));
    }

    return RefreshIndicator(
      onRefresh: () => fetchData(repeat: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
        child: Column(
          children: [
            // Summary cards if available
            if (viewData!['summary'] != null) ...[
              _buildSummaryCards(viewData!['summary'] as Map<String, dynamic>),
              SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            ],

            // Report table
            Container(
              decoration: BoxDecoration(
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                  dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(
                  getThemeBorderRadius(context, intensity: 'medium'),
                ),
              ),
              padding:
                  EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: getThemeFont(context),
                    fontSize: 14,
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context),
                      dark: getThemeColor(context)?.shade200,
                    ),
                  ),
                  dataTextStyle: TextStyle(
                    fontFamily: getThemeFont(context),
                    fontSize: 13,
                    color: useThemeMode(
                      context,
                      light: AppColors.slateColor[700],
                      dark: AppColors.slateColor[200],
                    ),
                  ),
                  columns: columns.map((col) {
                    return DataColumn(
                      label: Text(
                        col['label'] ?? col.toString(),
                      ),
                    );
                  }).toList(),
                  rows: reportData.map((row) {
                    return DataRow(
                      cells: columns.map((col) {
                        final field = col['field'] ?? '';
                        return DataCell(Text(row[field]?.toString() ?? ''));
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    // Check if we have summary_boxes array (new format)
    if (viewData!['summary_boxes'] != null) {
      final summaryBoxes = viewData!['summary_boxes'] as List<dynamic>;

      return RefreshIndicator(
        onRefresh: () => fetchData(repeat: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewData!['subtitle'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                  child: Text(
                    viewData!['subtitle'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: getThemeFont(context),
                      color: useThemeMode(
                        context,
                        light: AppColors.slateColor[600],
                        dark: AppColors.slateColor[300],
                      ),
                    ),
                  ),
                ),
              ...summaryBoxes.map((box) {
                final boxMap = box as Map<String, dynamic>;
                final title = boxMap['title'] ?? '';
                final items = boxMap['items'] as List<dynamic>? ?? [];

                return sb.SummaryBox(
                  title: title,
                  children: items.map<Widget>((item) {
                    final label = item['label'] ?? '';
                    final value = item['value'] ?? '';
                    return sb.SummaryItem(
                      title: label,
                      value: value.toString(),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      );
    }

    // Fallback to old format with summary map
    final summaryData = viewData!['summary'] as Map<String, dynamic>?;

    if (summaryData == null) {
      return const Center(child: Text('No summary data available'));
    }

    return RefreshIndicator(
      onRefresh: () => fetchData(repeat: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildSummaryCards(summaryData),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.kDefaultSpacing(context),
        mainAxisSpacing: AppSpacing.kDefaultSpacing(context),
        childAspectRatio: 1.5,
      ),
      itemCount: summary.length,
      itemBuilder: (context, index) {
        final entry = summary.entries.elementAt(index);
        return Container(
          decoration: BoxDecoration(
            color: useThemeMode(
              context,
              light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
              dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(
              getThemeBorderRadius(context, intensity: 'medium'),
            ),
          ),
          padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: getThemeFont(context),
                  color: useThemeMode(
                    context,
                    light: AppColors.slateColor[600],
                    dark: AppColors.slateColor[400],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),
              Text(
                entry.value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: getThemeFont(context),
                  color: useThemeMode(
                    context,
                    light: getThemeColor(context),
                    dark: getThemeColor(context)?.shade200,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsView() {
    final widgets = viewData!['widgets'] as List<dynamic>? ?? [];

    if (widgets.isEmpty) {
      final iconPack =
          context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconMapper.icon(
              'info',
              iconPack: iconPack,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text('No statistics data available'),
            const SizedBox(height: 8),
            Text('Keys in response: ${viewData?.keys.join(", ")}'),
            const SizedBox(height: 16),
            AppButton(
              onPressed: fetchData,
              title: 'Retry',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchData(repeat: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets.asMap().entries.map((entry) {
            final index = entry.key;
            final widget = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: AppSpacing.kDefaultSpacing(context) * 0.5,
              ),
              child: _buildStatisticsWidget(widget, index),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatisticsWidget(Map<String, dynamic> widget, int index) {
    final type = widget['type'] as String?;
    final chartKey = 'chart_$index';

    try {
      switch (type) {
        case 'stat_cards':
          return _buildStatCards(widget);
        case 'line_chart':
          final chartData = widget['data'] as Map<String, dynamic>? ?? {};
          final title = widget['title'] as String? ?? '';
          return _buildLineChart(chartData, chartKey, title: title);
        case 'bar_chart':
          final chartData = widget['data'] as Map<String, dynamic>? ?? {};
          final title = widget['title'] as String? ?? '';
          return _buildBarChart(chartData, chartKey, title: title);
        case 'pie_chart':
          final chartData = widget['data'] as Map<String, dynamic>? ?? {};
          final title = widget['title'] as String? ?? '';
          return _buildPieChart(chartData, chartKey, title: title);
        case 'tabbed_table':
          return _buildTabbedTable(widget);
        case 'table':
          return _buildTable(widget);
        default:
          return const SizedBox.shrink();
      }
    } catch (e) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error rendering $type widget',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatCards(Map<String, dynamic> data) {
    final cards = data['cards'] as List<dynamic>? ?? [];
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return Column(
      children: cards.map((card) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: AppSpacing.kDefaultSpacing(context) * 0.5,
          ),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
            decoration: BoxDecoration(
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(
                  getThemeBorderRadius(context, intensity: 'low')),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    AppSpacing.kDefaultSpacing(context) * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        card['color'].toString().replaceAll('#', '0xFF'),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(
                        getThemeBorderRadius(context, intensity: 'medium')),
                  ),
                  child: IconMapper.icon(
                    _getIconKey(card['icon']),
                    iconPack: iconPack,
                    color: Colors.white,
                    size: AppSpacing.kDefaultSpacing(context) * 2.5,
                  ),
                ),
                SizedBox(width: AppSpacing.kDefaultSpacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card['title'] ?? '',
                        style: TextStyle(
                          fontSize: AppSpacing.kDefaultSpacing(context) * 1.2,
                          fontFamily: getThemeFont(context),
                          color: useThemeMode(
                            context,
                            light: getThemeColor(context)?.shade600,
                            dark: getThemeColor(context)?.shade300,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: AppSpacing.kDefaultSpacing(context) * 0.3,
                      ),
                      Countup(
                        begin: 0,
                        end: double.tryParse(
                                card['value'].replaceAll(',', '')) ??
                            0,
                        precision: 2,
                        separator: ',',
                        duration: const Duration(seconds: 1),
                        style: TextStyle(
                          fontSize: AppSpacing.kDefaultSpacing(context) * 1.6,
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
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabbedTable(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? '';
    final tabs = data['tabs'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: useThemeMode(
          context,
          light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
          dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(
          getThemeBorderRadius(context, intensity: 'low'),
        ),
      ),
      margin: EdgeInsets.only(
        top: AppSpacing.kDefaultSpacing(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 1.4,
                fontWeight: FontWeight.bold,
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade900,
                  dark: getThemeColor(context)?.shade100,
                ),
              ),
            ),
          ),
          SizedBox(
            height: AppSpacing.kDefaultSpacing(context) * 35,
            child: DefaultTabController(
              length: tabs.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    labelColor: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade500,
                      dark: getThemeColor(context)?.shade300,
                    ),
                    unselectedLabelColor: useThemeMode(
                      context,
                      light: AppColors.slateSwatch.shade600,
                      dark: AppColors.slateSwatch.shade400,
                    ),
                    indicatorColor: getThemeColor(context),
                    tabs: tabs
                        .map((tab) => Tab(text: tab['title'] as String? ?? ''))
                        .toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: tabs.map((tab) {
                        return _buildSimpleTable(tab);
                      }).toList(),
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

  Widget _buildTable(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: useThemeMode(
          context,
          light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
          dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(
          getThemeBorderRadius(context, intensity: 'low'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 1.4,
                fontWeight: FontWeight.bold,
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade900,
                  dark: getThemeColor(context)?.shade100,
                ),
              ),
            ),
          ),
          _buildSimpleTable(data),
        ],
      ),
    );
  }

  Widget _buildSimpleTable(Map<String, dynamic> data) {
    final columns = data['columns'] as List<dynamic>? ?? [];
    final rows = data['rows'] as List<dynamic>? ?? [];

    if (rows.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontFamily: getThemeFont(context),
              color: useThemeMode(
                context,
                light: getThemeColor(context)?.shade500,
                dark: getThemeColor(context)?.shade400,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 0.5),
      child: DataTable(
        headingRowHeight: AppSpacing.kDefaultSpacing(context) * 4,
        columns: columns.map((col) {
          return DataColumn(
            label: Text(
              col['label'] as String? ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade900,
                  dark: getThemeColor(context)?.shade100,
                ),
              ),
            ),
          );
        }).toList(),
        rows: rows.map((row) {
          final rowData = row as Map<String, dynamic>;
          return DataRow(
            cells: columns.map((col) {
              final field = col['field'] as String;
              final value = rowData[field]?.toString() ?? '';
              return DataCell(
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: getThemeFont(context),
                    color: useThemeMode(
                      context,
                      light: AppColors.slateSwatch.shade700,
                      dark: AppColors.slateSwatch.shade300,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  String _getIconKey(String? iconName) {
    switch (iconName) {
      case 'chartBar':
        return 'chart-square';
      case 'trophy':
        return 'trophy';
      case 'backward':
        return 'double-arrow-right';
      case 'forward':
        return 'double-arrow-left';
      default:
        return 'help';
    }
  }

  Widget _buildDefaultView() {
    return RefreshIndicator(
      onRefresh: () => fetchData(repeat: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                  dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(
                  getThemeBorderRadius(context, intensity: 'medium'),
                ),
              ),
              padding:
                  EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: viewData!.entries.map((entry) {
                  if (entry.key == 'debug_bar' || entry.key == 'view_type') {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatKey(entry.key),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: getThemeFont(context),
                            fontWeight: FontWeight.w500,
                            color: useThemeMode(
                              context,
                              light: AppColors.slateColor[600],
                              dark: AppColors.slateColor[400],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: AppSpacing.kDefaultSpacing(context) * 0.25,
                        ),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: getThemeFont(context),
                            color: useThemeMode(
                              context,
                              light: AppColors.slateColor[900],
                              dark: AppColors.slateColor[50],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.kDefaultSpacing(context) * 0.5,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppSpacing.kDefaultSpacing(context) * 1.3,
          fontWeight: FontWeight.bold,
          fontFamily: getThemeFont(context),
          color: useThemeMode(
            context,
            light: getThemeColor(context),
            dark: getThemeColor(context)?.shade200,
          ),
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Chart rendering methods
  Widget _buildLegend(
    List<Map<String, dynamic>> legendItems, {
    required Function(String) onToggle,
    required Set<String> hiddenItems,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: legendItems.map((item) {
        final label = item['label'] as String;
        final isHidden = hiddenItems.contains(label);
        final color = item['color'] as Color;

        return InkWell(
          onTap: () => onToggle(label),
          borderRadius: BorderRadius.circular(
            getThemeBorderRadius(context, intensity: 'low'),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isHidden ? Colors.grey.withAlpha(100) : color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: getThemeFont(context),
                    color: isHidden
                        ? Colors.grey
                        : useThemeMode(
                            context,
                            light: AppColors.slateSwatch.shade600,
                            dark: AppColors.slateSwatch.shade400,
                          ),
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> chartData, String chartKey,
      {String title = ''}) {
    final labels = (chartData['labels'] as List?)?.cast<String>() ?? [];
    final datasets =
        (chartData['datasets'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (datasets.isEmpty || labels.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    final hiddenItems = _hiddenLegendItems[chartKey] ?? {};

    final palette = [
      AppColors.greenSwatch,
      AppColors.roseSwatch,
      getThemeColor(context) ?? Colors.blue,
      Colors.orange,
      Colors.purple,
    ];

    double overallMaxY = 0;
    List<Map<String, dynamic>> processedDatasets = [];

    for (int i = 0; i < datasets.length; i++) {
      final dataset = datasets[i];
      final rawData = dataset['data'] as List?;
      List<double> dataValues = [];

      if (rawData != null) {
        dataValues = rawData.map((e) {
          if (e is num) return e.toDouble();
          if (e is String) return double.tryParse(e.replaceAll(',', '')) ?? 0.0;
          return 0.0;
        }).toList();
      }

      if (dataValues.isNotEmpty) {
        final max = dataValues.reduce((a, b) => a > b ? a : b);
        if (max > overallMaxY) overallMaxY = max;
      }

      Color color = palette[i % palette.length];
      String? hexString = dataset['backgroundColor']?.toString() ??
          dataset['borderColor']?.toString();

      if (hexString != null) {
        try {
          String hex = hexString.replaceAll('#', '');
          if (hex.length == 6) {
            color = Color(int.parse("0xFF$hex"));
          } else if (hex.length == 8) {
            color = Color(int.parse("0x$hex"));
          }
        } catch (_) {}
      }

      processedDatasets.add({
        'data': dataValues,
        'color': color,
        'label': dataset['label'] ?? '',
      });
    }

    final visibleDatasets = processedDatasets
        .where((d) => !hiddenItems.contains(d['label']))
        .toList();

    // Calculate max value, ensure it's not zero to avoid infinity
    final maxY = (overallMaxY > 0 ? overallMaxY : 100).toDouble() * 1.2;

    final labelStyle = TextStyle(
      fontSize: 10,
      fontFamily: getThemeFont(context),
      color: useThemeMode(
        context,
        light: AppColors.slateSwatch.shade600,
        dark: AppColors.slateSwatch.shade400,
      ),
    );

    final tooltipBgColor = useThemeMode(
      context,
      light: Colors.white,
      dark: Colors.black,
    ) as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              bottom: AppSpacing.kDefaultSpacing(context),
              top: AppSpacing.kDefaultSpacing(context) * 2,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 1.3,
                fontWeight: FontWeight.bold,
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: AppColors.slateSwatch.shade800,
                  dark: AppColors.slateSwatch.shade200,
                ),
              ),
            ),
          ),
        if (visibleDatasets.isNotEmpty)
          SizedBox(
            height: 250, // Fixed height to prevent infinite size
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => tooltipBgColor,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toString(),
                          TextStyle(
                            color: rod.color ?? Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: labelStyle.fontFamily,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()],
                                style: labelStyle,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: labelStyle,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    labels.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: visibleDatasets.map((dataset) {
                        final dataList = dataset['data'] as List<double>;
                        final val =
                            index < dataList.length ? dataList[index] : 0.0;
                        return BarChartRodData(
                          toY: val,
                          color: dataset['color'] as Color,
                          width: visibleDatasets.length > 1 ? 12 : 20,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                              getThemeBorderRadius(context, intensity: 'low'),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: Center(
              child: Text(
                'All data hidden',
                style: labelStyle,
              ),
            ),
          ),
        if (processedDatasets.isNotEmpty) ...[
          _buildLegend(
            processedDatasets,
            hiddenItems: hiddenItems,
            onToggle: (label) {
              setState(() {
                if (_hiddenLegendItems[chartKey]?.contains(label) ?? false) {
                  _hiddenLegendItems[chartKey]?.remove(label);
                } else {
                  (_hiddenLegendItems[chartKey] ??= {}).add(label);
                }
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPieChart(Map<String, dynamic> chartData, String chartKey,
      {String title = ''}) {
    final labels = (chartData['labels'] as List?)?.cast<String>() ?? [];
    final datasets =
        (chartData['datasets'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (datasets.isEmpty || labels.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    final dataList = datasets[0]['data'] as List?;
    if (dataList == null || dataList.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    final hiddenItems = _hiddenLegendItems[chartKey] ?? {};

    // Safely parse data - backend may send strings from number_format()
    final data = dataList.map((e) {
      if (e is num) return e;
      if (e is String) return num.tryParse(e.replaceAll(',', '')) ?? 0;
      return 0;
    }).toList();

    if (data.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    List<Color> colors = [
      getThemeColor(context) ?? Colors.blue,
      const Color(0xFF2ecc71),
      const Color(0xFF3498db),
      const Color(0xFFe74c3c),
      const Color(0xFFf39c12),
    ];

    if (datasets.isNotEmpty) {
      final dataset = datasets[0];
      final bgColors = dataset['backgroundColor'];
      if (bgColors is List && bgColors.isNotEmpty) {
        colors = bgColors
            .map((c) {
              if (c == null) return Colors.grey;
              try {
                String hex = c.toString().replaceAll('#', '');
                if (hex.length == 6) return Color(int.parse("0xFF$hex"));
                if (hex.length == 8) return Color(int.parse("0x$hex"));
              } catch (_) {}
              return Colors.grey;
            })
            .toList()
            .cast<Color>();
      }
    }

    List<Map<String, dynamic>> legendItems =
        List.generate(data.length, (index) {
      return {
        'color': colors[index % colors.length],
        'label': labels.length > index ? labels[index] : '',
      };
    });

    int visibleIndexCounter = 0;
    final currentlyTouchedIndex = _touchedPieSections[chartKey] ?? -1;

    final visibleSections = List.generate(data.length, (index) {
      final label = labels.length > index ? labels[index] : '';
      if (hiddenItems.contains(label)) return null;

      final isTouched = visibleIndexCounter == currentlyTouchedIndex;
      visibleIndexCounter++;

      final value = data[index].toDouble();
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 80.0 : 70.0;

      return PieChartSectionData(
        value: value,
        title: '$value',
        showTitle: isTouched, // Only show title when touched
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
        color: colors[index % colors.length],
        radius: radius,
      );
    }).whereType<PieChartSectionData>().toList();

    final labelStyle = TextStyle(
      fontSize: 10,
      fontFamily: getThemeFont(context),
      color: useThemeMode(
        context,
        light: AppColors.slateSwatch.shade600,
        dark: AppColors.slateSwatch.shade400,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              bottom: AppSpacing.kDefaultSpacing(context),
              top: AppSpacing.kDefaultSpacing(context) * 2,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 1.3,
                fontWeight: FontWeight.bold,
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: AppColors.slateSwatch.shade800,
                  dark: AppColors.slateSwatch.shade200,
                ),
              ),
            ),
          ),
        if (visibleSections.isNotEmpty)
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieSections[chartKey] = -1;
                        return;
                      }
                      _touchedPieSections[chartKey] =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 60,
                sections: visibleSections,
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: Center(
              child: Text(
                'All data hidden',
                style: labelStyle,
              ),
            ),
          ),
        if (data.isNotEmpty) ...[
          SizedBox(height: AppSpacing.kDefaultSpacing(context) * 2),
          _buildLegend(
            legendItems,
            hiddenItems: hiddenItems,
            onToggle: (label) {
              setState(() {
                if (_hiddenLegendItems[chartKey]?.contains(label) ?? false) {
                  _hiddenLegendItems[chartKey]?.remove(label);
                } else {
                  (_hiddenLegendItems[chartKey] ??= {}).add(label);
                }
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLineChart(Map<String, dynamic> chartData, String chartKey,
      {String title = ''}) {
    final labels = (chartData['labels'] as List?)?.cast<String>() ?? [];
    final datasets =
        (chartData['datasets'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (datasets.isEmpty || labels.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    final hiddenItems = _hiddenLegendItems[chartKey] ?? {};

    final List<Color> palette = [
      AppColors.greenSwatch,
      AppColors.roseSwatch,
      getThemeColor(context) ?? Colors.blue,
      Colors.orange,
      Colors.purple,
    ];

    List<LineChartBarData> lineBarsData = [];
    List<Map<String, dynamic>> legendItems = [];
    double overallMaxY = 0;
    double overallMinY = 0;
    bool hasData = false;

    for (int i = 0; i < datasets.length; i++) {
      final dataset = datasets[i];
      final label = dataset['label'] ?? '';

      Color lineColor = palette[i % palette.length];
      String? hexString = dataset['borderColor']?.toString() ??
          dataset['backgroundColor']?.toString();

      if (hexString != null) {
        try {
          String hex = hexString.replaceAll('#', '');
          if (hex.length == 6) {
            lineColor = Color(int.parse("0xFF$hex"));
          } else if (hex.length == 8) {
            lineColor = Color(int.parse("0x$hex"));
          }
        } catch (_) {}
      }

      legendItems.add({
        'color': lineColor,
        'label': label,
      });

      if (hiddenItems.contains(label)) continue;

      final dataList = dataset['data'] as List?;
      if (dataList == null) continue;

      // Safely parse data - backend may send strings from number_format()
      final data = dataList.map((e) {
        if (e is num) return e.toDouble();
        if (e is String) return double.tryParse(e.replaceAll(',', '')) ?? 0.0;
        return 0.0;
      }).toList();

      if (data.isEmpty) continue;
      hasData = true;

      double maxY = data.reduce((a, b) => a > b ? a : b);
      double minY = data.reduce((a, b) => a < b ? a : b);

      if (lineBarsData.isEmpty) {
        overallMaxY = maxY;
        overallMinY = minY;
      } else {
        if (maxY > overallMaxY) overallMaxY = maxY;
        if (minY < overallMinY) overallMinY = minY;
      }

      lineBarsData.add(
        LineChartBarData(
          spots: List.generate(
            data.length,
            (index) => FlSpot(index.toDouble(), data[index]),
          ),
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    if (!hasData && legendItems.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    final double maxY = (overallMaxY > 0 ? overallMaxY : 100).toDouble() * 1.2;
    final double minY = (overallMinY < 0 ? overallMinY : 0).toDouble();

    final labelStyle = TextStyle(
      fontSize: 10,
      fontFamily: getThemeFont(context),
      color: useThemeMode(
        context,
        light: AppColors.slateSwatch.shade600,
        dark: AppColors.slateSwatch.shade400,
      ),
    );

    final borderColor = useThemeMode(
      context,
      light: Colors.grey.shade300,
      dark: Colors.grey.shade700,
    ) as Color;

    final gridColor = useThemeMode(
      context,
      light: Colors.grey.shade200,
      dark: Colors.grey.shade800,
    ) as Color;

    final tooltipBgColor = useThemeMode(
      context,
      light: Colors.white,
      dark: Colors.black,
    ) as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              bottom: AppSpacing.kDefaultSpacing(context),
              top: AppSpacing.kDefaultSpacing(context) * 2,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context) * 1.3,
                fontWeight: FontWeight.bold,
                fontFamily: getThemeFont(context),
                color: useThemeMode(
                  context,
                  light: AppColors.slateSwatch.shade800,
                  dark: AppColors.slateSwatch.shade200,
                ),
              ),
            ),
          ),
        if (lineBarsData.isNotEmpty)
          SizedBox(
            height: 250, // Fixed height to prevent infinite size
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => tooltipBgColor,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            spot.y.toString(),
                            TextStyle(
                              color: spot.bar.color ?? Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: labelStyle.fontFamily,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  maxY: maxY,
                  minY: minY,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1, // Fix overlap/duplication
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[index],
                                style: labelStyle,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: labelStyle,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: gridColor,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: gridColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  lineBarsData: lineBarsData,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: Center(
              child: Text(
                'All data hidden',
                style: labelStyle,
              ),
            ),
          ),
        if (legendItems.isNotEmpty) ...[
          _buildLegend(
            legendItems,
            hiddenItems: hiddenItems,
            onToggle: (label) {
              setState(() {
                if (_hiddenLegendItems[chartKey]?.contains(label) ?? false) {
                  _hiddenLegendItems[chartKey]?.remove(label);
                } else {
                  (_hiddenLegendItems[chartKey] ??= {}).add(label);
                }
              });
            },
          ),
        ],
      ],
    );
  }

  // Calendar view for daily reports
  Widget _buildCalendarView() {
    final calendarData = viewData!['calendar_data'] as Map<String, dynamic>?;
    final subtitle = viewData!['subtitle'];

    if (calendarData == null) {
      return const Center(child: Text('No calendar data available'));
    }

    // Convert days List to Map indexed by day number
    final daysList = calendarData['days'] as List<dynamic>? ?? [];
    final Map<String, dynamic> days = {};
    for (var dayData in daysList) {
      if (dayData is Map<String, dynamic> && dayData['day'] != null) {
        days[dayData['day'].toString()] = dayData;
      }
    }

    final numberOfDays =
        int.tryParse(calendarData['number_of_days'].toString()) ?? 30;
    final startDay = int.tryParse(calendarData['start_day'].toString()) ?? 1;
    final monthName = calendarData['month_name'] ?? '';
    final year = calendarData['year'];
    final prevYear = calendarData['prev_year'];
    final prevMonth = calendarData['prev_month'];
    final nextYear = calendarData['next_year'];
    final nextMonth = calendarData['next_month'];

    return _CalendarViewContent(
      days: days,
      numberOfDays: numberOfDays,
      startDay: startDay,
      monthName: monthName,
      year: year,
      subtitle: subtitle,
      prevYear: prevYear,
      prevMonth: prevMonth,
      nextYear: nextYear,
      nextMonth: nextMonth,
      apiUrl: widget.apiUrl,
      title: widget.title,
      onRefresh: () => fetchData(repeat: true),
      params: widget.params,
    );
  }
}

class _AppearanceBox extends StatelessWidget {
  const _AppearanceBox({
    required this.iconKey,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  final String iconKey;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        margin: EdgeInsets.only(right: AppSpacing.kDefaultSpacing(context)),
        width: AppSpacing.kDefaultSpacing(context) * 4,
        height: AppSpacing.kDefaultSpacing(context) * 4,
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(
              width: isSelected ? 3 : 0,
              color: Theme.of(context).primaryColor,
            ),
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(
              isSelected
                  ? AppSpacing.kDefaultSpacing(context)
                  : AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
          ),
          color: color,
        ),
        child: AnimatedOpacity(
          opacity: isSelected ? 1 : 0.5,
          duration: const Duration(milliseconds: 800),
          child: IconMapper.icon(
            iconKey,
            iconPack: context
                .watch<CommonDataProvider>()
                .currentThemeSetting
                ?.iconPack,
            color: iconColor,
            size: AppSpacing.kDefaultSpacing(context) * 2,
          ),
        ),
      ),
    );
  }
}

class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.themeSetting,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeSetting themeSetting;
  final bool isSelected;
  final VoidCallback onTap;

  List<String> _appearanceSupportIconKeys(String raw) {
    switch (raw) {
      case 'system_both':
        return const [
          'appearance-system',
          'appearance-light',
          'appearance-dark'
        ];
      case 'system':
        return const ['appearance-system'];
      case 'both':
        return const ['appearance-light', 'appearance-dark'];
      case 'light':
        return const ['appearance-light'];
      case 'dark':
        return const ['appearance-dark'];
      default:
        return const ['appearance-system'];
    }
  }

  List<Widget> _iconPackPreview(String raw, {required Color color}) {
    final pack = IconMapper.normalizePack(raw);
    return [
      IconMapper.icon('dashboard',
          iconPack: pack, size: AppSpacing.kDefaultSpacing(null), color: color),
      IconMapper.icon('settings',
          iconPack: pack, size: AppSpacing.kDefaultSpacing(null), color: color),
      IconMapper.icon('people',
          iconPack: pack, size: AppSpacing.kDefaultSpacing(null), color: color),
    ];
  }

  Widget _miniBadge({required List<Widget> children}) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  TextStyle _tryFont(String name, TextStyle fallback) {
    try {
      return GoogleFonts.getFont(
        name,
        textStyle: fallback,
      );
    } catch (_) {
      return fallback.copyWith(fontFamily: name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = themeSetting.themeColor;
    final bool isGradient = themeSetting.buttonColors.length >= 2;
    final List<Color> buttonColors = themeSetting.buttonColors.isNotEmpty
        ? themeSetting.buttonColors
        : <Color>[primary.shade500];

    final double highRadius =
        getBorderRadiusByIntensity(themeSetting.borderRadius, 'high');
    final double radius = isSelected
        ? (highRadius > AppSpacing.kDefaultSpacing(context) * 5
            ? highRadius * 0.15
            : highRadius)
        : AppSpacing.kDefaultSpacing(context) * 1.25;

    final Color fg = Colors.white;
    final bool outlinedButton = themeSetting.buttonStyle == 'outlined';
    final bool outlinedInput = themeSetting.inputDesign == 'outlined';
    final Color borderColor = fg.withValues(alpha: 0.65);

    final appearanceIcons =
        _appearanceSupportIconKeys(themeSetting.themeAppearance)
            .map(
              (iconKey) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconMapper.icon(
                  iconKey,
                  iconPack: themeSetting.iconPack,
                  size: 14,
                  color: fg.withValues(alpha: 0.95),
                ),
              ),
            )
            .toList();

    final packIcons = _iconPackPreview(
      themeSetting.iconPack,
      color: fg.withValues(alpha: 0.95),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            width: isSelected ? 3 : 1,
            color: isSelected
                ? (getThemeColor(context)?.shade200 ?? Colors.white)
                    .withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.18),
          ),
          gradient: isGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: buttonColors,
                )
              : null,
          color: isGradient ? null : buttonColors.first,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.kDefaultSpacing(context),
                top: AppSpacing.kDefaultSpacing(context),
                child: Container(
                  width: 110,
                  height: 22,
                  decoration: BoxDecoration(
                    color: outlinedInput
                        ? Colors.transparent
                        : fg.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(
                      getThemeBorderRadius(context, intensity: 'low'),
                    ),
                    border: outlinedInput
                        ? Border.all(color: borderColor, width: 1)
                        : null,
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.kDefaultSpacing(context) * 0.8,
                right: AppSpacing.kDefaultSpacing(context),
                child: _miniBadge(
                  children: [
                    ...packIcons.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: w,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: AppSpacing.kDefaultSpacing(context),
                bottom: AppSpacing.kDefaultSpacing(context),
                right: AppSpacing.kDefaultSpacing(context) * 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (context) {
                        final name = themeSetting.name;
                        final first = name.isNotEmpty
                            ? name.substring(0, 1).toUpperCase()
                            : '';
                        final second = name.length >= 2
                            ? name.substring(1, 2).toLowerCase()
                            : '';

                        return RichText(
                          text: TextSpan(
                            text: first,
                            children: second.isNotEmpty
                                ? [
                                    TextSpan(
                                      text: second,
                                      style: _tryFont(
                                        themeSetting.fontFamily,
                                        TextStyle(
                                          fontSize: AppSpacing.kDefaultSpacing(
                                                  context) *
                                              3.5,
                                          fontWeight: FontWeight.w800,
                                          color: fg,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ]
                                : const <TextSpan>[],
                            style: _tryFont(
                              themeSetting.fontFamily,
                              TextStyle(
                                fontSize:
                                    AppSpacing.kDefaultSpacing(context) * 4,
                                fontWeight: FontWeight.w800,
                                color: fg,
                                height: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      themeSetting.fontFamily,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _tryFont(
                        themeSetting.fontFamily,
                        TextStyle(
                          fontSize: AppSpacing.kDefaultSpacing(context),
                          fontWeight: FontWeight.w700,
                          color: fg.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -26,
                bottom: -14,
                child: Container(
                  width: 150,
                  height: 52,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.kDefaultSpacing(context),
                    vertical: AppSpacing.kDefaultSpacing(context) / 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      getThemeBorderRadius(context, intensity: 'medium'),
                    ),
                    color: outlinedButton
                        ? Colors.transparent
                        : (isGradient
                            ? null
                            : primary.shade900.withValues(alpha: 0.35)),
                    gradient: !outlinedButton && isGradient
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: buttonColors,
                          )
                        : null,
                    border: outlinedButton
                        ? Border.all(color: fg.withValues(alpha: 0.9), width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _miniBadge(children: appearanceIcons),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarViewContent extends StatefulWidget {
  final Map<String, dynamic> days;
  final int numberOfDays;
  final int startDay;
  final String monthName;
  final String year;
  final String? subtitle;
  final String prevYear;
  final String prevMonth;
  final String nextYear;
  final String nextMonth;
  final String apiUrl;
  final String title;
  final Future<void> Function() onRefresh;
  final Map? params;

  const _CalendarViewContent({
    required this.days,
    required this.numberOfDays,
    required this.startDay,
    required this.monthName,
    required this.year,
    this.subtitle,
    required this.prevYear,
    required this.prevMonth,
    required this.nextYear,
    required this.nextMonth,
    required this.apiUrl,
    required this.title,
    required this.onRefresh,
    this.params,
  });

  @override
  State<_CalendarViewContent> createState() => _CalendarViewContentState();
}

class _CalendarViewContentState extends State<_CalendarViewContent> {
  int? selectedDay;

  @override
  void initState() {
    super.initState();
    // Find today's date and select it by default
    for (var entry in widget.days.entries) {
      if (entry.value['is_today'] == true) {
        selectedDay = int.tryParse(entry.key);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;
    final selectedDayData = selectedDay != null
        ? widget.days[selectedDay.toString()] as Map<String, dynamic>?
        : null;
    final data =
        (selectedDayData?['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Navigate to previous month
                    // Extract the base URL and construct new URL with prevYear/prevMonth
                    final parts = widget.apiUrl.split('/');
                    if (parts.length >= 3) {
                      parts[parts.length - 2] = widget.prevYear;
                      parts[parts.length - 1] = widget.prevMonth;
                      final newUrl = parts.join('/');

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomViewScreen(
                            apiUrl: newUrl,
                            title: widget.title,
                            params: widget.params,
                          ),
                        ),
                      );
                    }
                  },
                  icon: IconMapper.icon(
                    'arrow-left',
                    iconPack: iconPack,
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade900,
                      dark: getThemeColor(context)?.shade200,
                    ),
                  ),
                  label: Text(
                    'Previous',
                    style: TextStyle(
                      color: useThemeMode(
                        context,
                        light: getThemeColor(context)?.shade900,
                        dark: getThemeColor(context)?.shade200,
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.subtitle ?? '${widget.monthName} ${widget.year}',
                  style: TextStyle(
                    fontSize: AppSpacing.kDefaultSpacing(context) * 1.8,
                    fontWeight: FontWeight.bold,
                    fontFamily: getThemeFont(context),
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade900,
                      dark: getThemeColor(context)?.shade200,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to next month
                    // Extract the base URL and construct new URL with nextYear/nextMonth
                    final parts = widget.apiUrl.split('/');
                    if (parts.length >= 3) {
                      parts[parts.length - 2] = widget.nextYear;
                      parts[parts.length - 1] = widget.nextMonth;
                      final newUrl = parts.join('/');

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomViewScreen(
                            apiUrl: newUrl,
                            title: widget.title,
                            params: widget.params,
                          ),
                        ),
                      );
                    }
                  },
                  label: Text(
                    'Next',
                    style: TextStyle(
                      color: useThemeMode(
                        context,
                        light: getThemeColor(context)?.shade900,
                        dark: getThemeColor(context)?.shade200,
                      ),
                    ),
                  ),
                  icon: IconMapper.icon(
                    'arrow-right',
                    iconPack: iconPack,
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade900,
                      dark: getThemeColor(context)?.shade200,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.kDefaultSpacing(context) * 1.5),

            // Selected day data display
            if (selectedDay != null && data.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(
                    bottom: AppSpacing.kDefaultSpacing(context) * 1.5),
                decoration: BoxDecoration(
                  color: useThemeMode(
                    context,
                    light:
                        getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                    dark:
                        getThemeColor(context)?.shade900.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(
                    getThemeBorderRadius(context, intensity: 'medium'),
                  ),
                ),
                child: Padding(
                  padding:
                      EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 1.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  AppSpacing.kDefaultSpacing(context) * 0.8,
                              vertical:
                                  AppSpacing.kDefaultSpacing(context) * 0.4,
                            ),
                            decoration: BoxDecoration(
                              color: selectedDayData?['is_today'] == true
                                  ? useThemeMode(
                                      context,
                                      light: getThemeColor(context)?.shade900,
                                      dark: getThemeColor(context)?.shade200,
                                    )
                                  : useThemeMode(
                                      context,
                                      light: getThemeColor(context)?.shade100,
                                      dark: getThemeColor(context)
                                          ?.shade800
                                          .withValues(alpha: 0.2),
                                    ),
                              borderRadius: BorderRadius.circular(
                                getThemeBorderRadius(context, intensity: 'low'),
                              ),
                            ),
                            child: Text(
                              '$selectedDay ${widget.monthName}, ${widget.year}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    AppSpacing.kDefaultSpacing(context) * 1.4,
                                fontFamily: getThemeFont(context),
                                color: selectedDayData?['is_today'] == true
                                    ? useThemeMode(
                                        context,
                                        light: Colors.white,
                                        dark: getThemeColor(context)
                                            ?.shade900
                                            .withValues(alpha: 0.2),
                                      )
                                    : useThemeMode(
                                        context,
                                        light: getThemeColor(context)?.shade900,
                                        dark: getThemeColor(context)?.shade200,
                                      ),
                              ),
                            ),
                          ),
                          if (selectedDayData?['is_today'] == true) ...[
                            SizedBox(
                                width:
                                    AppSpacing.kDefaultSpacing(context) * 0.5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    AppSpacing.kDefaultSpacing(context) * 0.6,
                                vertical:
                                    AppSpacing.kDefaultSpacing(context) * 0.3,
                              ),
                              decoration: BoxDecoration(
                                color: useThemeMode(
                                  context,
                                  light: Colors.red.shade100,
                                  dark: Colors.red.shade900,
                                ),
                                borderRadius: BorderRadius.circular(
                                  getThemeBorderRadius(context,
                                      intensity: 'low'),
                                ),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  fontSize:
                                      AppSpacing.kDefaultSpacing(context) * 1.1,
                                  fontFamily: getThemeFont(context),
                                  color: useThemeMode(
                                    context,
                                    light: Colors.red.shade900,
                                    dark: Colors.red.shade100,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSpacing.kDefaultSpacing(context)),

                      // Data items
                      ...data.map((item) {
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom:
                                  AppSpacing.kDefaultSpacing(context) * 0.8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['label'] ?? '',
                                  style: TextStyle(
                                    fontSize:
                                        AppSpacing.kDefaultSpacing(context) *
                                            1.3,
                                    fontFamily: getThemeFont(context),
                                    color: useThemeMode(
                                      context,
                                      light: getThemeColor(context)?.shade700,
                                      dark: getThemeColor(context)?.shade300,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                item['value']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize:
                                      AppSpacing.kDefaultSpacing(context) * 1.3,
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
                      }),
                    ],
                  ),
                ),
              ),
            ] else if (selectedDay != null) ...[
              Container(
                margin: EdgeInsets.only(
                    bottom: AppSpacing.kDefaultSpacing(context) * 1.5),
                padding:
                    EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 2),
                decoration: BoxDecoration(
                  color: useThemeMode(
                    context,
                    light:
                        getThemeColor(context)?.shade50.withValues(alpha: 0.5),
                    dark:
                        getThemeColor(context)?.shade900.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(
                    getThemeBorderRadius(context, intensity: 'medium'),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No data for $selectedDay ${widget.monthName}, ${widget.year}',
                    style: TextStyle(
                      fontSize: AppSpacing.kDefaultSpacing(context) * 1.3,
                      fontFamily: getThemeFont(context),
                      color: useThemeMode(
                        context,
                        light: getThemeColor(context)?.shade600,
                        dark: getThemeColor(context)?.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Calendar grid
            _buildInteractiveCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCalendar() {
    List<Widget> weeks = [];
    int currentDay = 1;
    bool started = false;

    while (currentDay <= widget.numberOfDays) {
      List<Widget> weekDays = [];

      for (int i = 1; i <= 7; i++) {
        if (!started && i == widget.startDay) {
          started = true;
        }

        if (started && currentDay <= widget.numberOfDays) {
          final dayData =
              widget.days[currentDay.toString()] as Map<String, dynamic>?;
          final hasData = (dayData?['data'] as List?)?.isNotEmpty ?? false;
          final isToday = dayData?['is_today'] ?? false;
          final day = currentDay;

          weekDays.add(
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDay = day;
                  });
                },
                child: Container(
                  height: 60,
                  margin:
                      EdgeInsets.all(AppSpacing.kDefaultSpacing(context) * 0.2),
                  decoration: BoxDecoration(
                    color: selectedDay == day
                        ? useThemeMode(
                            context,
                            light: getThemeColor(context)?.shade900,
                            dark: getThemeColor(context)?.shade200,
                          )
                        : hasData
                            ? useThemeMode(
                                context,
                                light: getThemeColor(context)
                                    ?.shade50
                                    .withValues(alpha: 0.5),
                                dark: getThemeColor(context)
                                    ?.shade900
                                    .withValues(alpha: 0.2),
                              )
                            : useThemeMode(
                                context,
                                light: getThemeColor(context)
                                    ?.shade50
                                    .withValues(alpha: 0.5),
                                dark: getThemeColor(context)
                                    ?.shade900
                                    .withValues(alpha: 0.3),
                              ),
                    borderRadius: BorderRadius.circular(
                      getThemeBorderRadius(context, intensity: 'low'),
                    ),
                    border: isToday
                        ? Border.all(
                            color: useThemeMode(
                              context,
                              light: Colors.red,
                              dark: Colors.red.shade300,
                            ),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontWeight: selectedDay == day || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: AppSpacing.kDefaultSpacing(context) * 1.4,
                        fontFamily: getThemeFont(context),
                        color: selectedDay == day
                            ? useThemeMode(
                                context,
                                light: Colors.white,
                                dark: getThemeColor(context)
                                    ?.shade900
                                    .withValues(alpha: 0.2),
                              )
                            : hasData
                                ? useThemeMode(
                                    context,
                                    light: getThemeColor(context)?.shade900,
                                    dark: getThemeColor(context)?.shade100,
                                  )
                                : useThemeMode(
                                    context,
                                    light: getThemeColor(context)?.shade400,
                                    dark: getThemeColor(context)?.shade600,
                                  ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          currentDay++;
        } else {
          weekDays.add(const Expanded(child: SizedBox()));
        }
      }

      weeks.add(
        Padding(
          padding: EdgeInsets.symmetric(
              vertical: AppSpacing.kDefaultSpacing(context) * 0.2),
          child: Row(children: weekDays),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: useThemeMode(
          context,
          light: getThemeColor(context)?.shade50.withValues(alpha: 0.5),
          dark: getThemeColor(context)?.shade900.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(
          getThemeBorderRadius(context, intensity: 'medium'),
        ),
      ),
      padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
      child: Column(
        children: [
          // Day headers
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppSpacing.kDefaultSpacing(context) * 1.2,
                            fontFamily: getThemeFont(context),
                            color: useThemeMode(
                              context,
                              light: getThemeColor(context)?.shade700,
                              dark: getThemeColor(context)?.shade300,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),
          ...weeks,
        ],
      ),
    );
  }
}
