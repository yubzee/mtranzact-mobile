/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: setup_app
*/

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:salepro/api/auth.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/models/message.dart';
import 'package:salepro/models/nav_link.dart';
import 'package:salepro/models/theme_setting.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/utils/control_loading.dart';
import 'package:salepro/utils/get_app_logo.dart';
import 'package:salepro/utils/get_nav_link.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';
import 'package:salepro/widgets/app_loader.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/widgets/checkbox.dart';
import 'package:salepro/widgets/input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool showForm = false;
  TextEditingController? urlController;
  TextEditingController? keyController;
  bool useDemo = true;
  String demoUrl = defaultServerUrl;
  String demoKey = "000000";
  Message? message;
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchForm(context);
  }

  Future<void> fetchForm(BuildContext context) async {
    setState(() {
      _isFetching = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final uri = Uri.parse(
        "$defaultApiURL/setup${demoTenantId != null ? "?tenant_id=$demoTenantId" : ""}",
      );

      final startTime = DateTime.now();
      String? requestId;
      if (mounted) {
        requestId = context.read<DebugProvider>().logRequest(
          method: 'GET',
          url: uri.toString(),
          headers: {'Accept': 'application/json'},
        );
      }

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      final duration = DateTime.now().difference(startTime);

      if (mounted && requestId != null) {
        context.read<DebugProvider>().logResponse(
          id: requestId,
          statusCode: response.statusCode,
          responseBody: response.body,
          duration: duration,
        );
      }

      await Loading.stop(context);

      prefs.setString(AppKeys.noInternetKey, "false");
      await context.read<CommonDataProvider>().checkInternet();

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final String installUrl = body['install_url'] ?? "";
        final String appKey = body['app_key'] ?? "";

        setState(() {
          demoUrl = installUrl;
          demoKey = appKey;
          urlController = TextEditingController(text: installUrl);
          keyController = TextEditingController(text: appKey);
        });

        context.read<CommonDataProvider>().setCurrentThemeSetting(
          ThemeSetting.fromJson(body['current_theme_setting'] ?? {}),
        );
        if (body['is_demo'] == true) {
          context.read<CommonDataProvider>().setDemo();
        }

        if (!body['show_setup']) {
          message = await setup({"install_url": installUrl, "app_key": appKey});
          setState(() {});

          await Loading.stop(context);

          if (message?.success == true && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => getNavScreen(
                  context,
                  NavLink(
                    title: "Login",
                    group: false,
                    apiUrl: message?.navigateUrl ?? '/login/create',
                    type: 'form',
                  ),
                ),
              ),
            );
            return;
          } else if (mounted) {
            showSnackBar(message?.message ?? 'Setup failed', context, type: "error");
          }
        }

        if (mounted) {
          setState(() {
            showForm = body['show_setup'] ?? false;
            _isFetching = false;
          });
        }
      } else {
        if (mounted) {
          showSnackBar("Failed to fetch setup data. Status: ${response.statusCode}", context, type: "error");
          setState(() {
            _isFetching = false;
          });
        }
      }
    } on SocketException catch (_) {
      if (mounted) {
        showSnackBar(
          "You are currently in offline mode and this page is not available in offline mode...",
          context,
          type: "error",
        );
        setState(() {
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar("Something went wrong: $e", context, type: "error");
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    urlController?.dispose();
    keyController?.dispose();
    super.dispose();
  }

  Future<void> scanQRCode(BuildContext context) async {
    try {
      String code = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666",
        "Cancel",
        true,
        ScanMode.QR,
      );

      if (code != '-1') {
        List items = code.split('?app_key=');
        if (items.length > 1) {
          setState(() {
            urlController?.text = items[0];
            keyController?.text = items[1];
          });

          await handleSubmit(context);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar("QR scan failed: $e", context, type: "error");
      }
    }
  }

  Future<void> handleSubmit(BuildContext context) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await Loading.start(context);

      final urlText = urlController?.text.trim() ?? '';
      final keyText = keyController?.text.trim() ?? '';

      if (urlText.isEmpty || keyText.isEmpty) {
        await Loading.stop(context);
        if (mounted) {
          showSnackBar("Please fill all the fields...", context, type: "error");
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final installUrl = urlText.endsWith('/') 
          ? urlText.substring(0, urlText.length - 1) 
          : urlText;

      message = await setup({
        "install_url": installUrl,
        "app_key": keyText,
      });
      setState(() {});

      await Loading.stop(context);

      if (message?.success == true && mounted) {
        showSnackBar(message?.message ?? 'Connected successfully', context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => getNavScreen(
              context,
              NavLink(
                title: "Login",
                group: false,
                apiUrl: message?.navigateUrl ?? '/login/create',
                type: 'form',
              ),
            ),
          ),
        );
      } else if (mounted) {
        showSnackBar(message?.message ?? 'Connection failed', context, type: "error");
      }
    } catch (e) {
      await Loading.stop(context);
      if (mounted) {
        showSnackBar("Error: $e", context, type: "error");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Loading setup...',
                style: TextStyle(
                  color: useThemeMode(
                    context,
                    light: Colors.grey.shade600,
                    dark: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: AppLoader(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 700),
                crossFadeState: showForm
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      hasNetworkLogo(context)
                          ? Image.network(
                              getAppLogo(context)!,
                              height: AppSpacing.kDefaultSpacing(context) * 4,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                    getAppLogo(context, useNetworkLogo: false)!,
                                    height:
                                        AppSpacing.kDefaultSpacing(context) * 4,
                                  ),
                            )
                          : Image.asset(
                              getAppLogo(context, useNetworkLogo: false)!,
                              height: AppSpacing.kDefaultSpacing(context) * 4,
                            ),
                    ],
                  ),
                ),
                secondChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    hasNetworkLogo(context)
                        ? Image.network(
                            getAppLogo(context)!,
                            height: AppSpacing.kDefaultSpacing(context) * 3,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  getAppLogo(context, useNetworkLogo: false)!,
                                  height:
                                      AppSpacing.kDefaultSpacing(context) * 3,
                                ),
                          )
                        : Image.asset(
                            getAppLogo(context, useNetworkLogo: false)!,
                            height: AppSpacing.kDefaultSpacing(context) * 3,
                          ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                    Text(
                      "Connect Server with this App",
                      style: TextStyle(
                        fontSize: AppSpacing.kDefaultSpacing(context) * 1.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: useThemeMode(
                          context,
                          light: getThemeColor(
                            context,
                          )?.shade900.withValues(alpha: 0.7),
                          dark: getThemeColor(
                            context,
                          )?.shade50.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context) * 3.5),
                    AppInput(
                      controller: urlController,
                      hintText: "Installation URL",
                      iconKey: 'server',
                      gradient: true,
                      errorLine: message?.errors?['install_url'],
                      readOnly: useDemo,
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                    AppInput(
                      controller: keyController,
                      hintText: "App Key",
                      iconKey: 'key',
                      gradient: true,
                      errorLine: message?.errors?['app_key'],
                      readOnly: useDemo,
                      password: true,
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.kDefaultSpacing(context),
                      ),
                      child: AppCheckBox(
                        hintText: "Use Demo $defaultAppName Details",
                        value: useDemo,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              useDemo = value;
                              if (value) {
                                urlController?.text = demoUrl.replaceAll(
                                  "/api",
                                  "",
                                );
                                keyController?.text = demoKey;
                              } else {
                                urlController?.text = "";
                                keyController?.text = "";
                              }
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context) * 3),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.kDefaultSpacing(context) * 0.8,
                      ),
                      child: AppButton(
                        onPressed: _isLoading ? null : () => handleSubmit(context),
                        title: _isLoading ? "Connecting..." : "Connect",
                      ),
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context) * 4),
                    Text(
                      "Or Scan QR Code",
                      style: TextStyle(
                        fontSize: AppSpacing.kDefaultSpacing(context),
                        color: useThemeMode(
                          context,
                          light: getThemeColor(
                            context,
                          )?.shade900.withValues(alpha: 0.7),
                          dark: getThemeColor(
                            context,
                          )?.shade50.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: () => scanQRCode(context),
                        child: IconMapper.icon(
                          'qr-scanner',
                          iconPack: context
                              .watch<CommonDataProvider>()
                              .currentThemeSetting
                              ?.iconPack,
                          size: AppSpacing.kDefaultSpacing(context) * 4,
                          color: useThemeMode(
                            context,
                            light: getThemeColor(context)?.shade900,
                            dark: getThemeColor(context)?.shade50,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context) * 4),
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: () async {
                          try {
                            final url = Uri.parse(defaultServerUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showSnackBar("Cannot open URL: $e", context, type: "error");
                            }
                          }
                        },
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize:
                                  AppSpacing.kDefaultSpacing(context) * 1.2,
                              fontWeight: FontWeight.w600,
                              fontFamily: getThemeFont(context),
                              color: useThemeMode(
                                context,
                                light: AppColors.slateSwatch.shade400,
                                dark: AppColors.slateSwatch.shade50,
                              ),
                            ),
                            text: "Join the world of $defaultAppName with a ",
                            children: [
                              TextSpan(
                                text: "Free Trial",
                                style: TextStyle(
                                  height: 1.2,
                                  color: useThemeMode(
                                    context,
                                    light: getThemeColor(context)?.shade600,
                                    dark: getThemeColor(context)?.shade300,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      AppSpacing.kDefaultSpacing(context) * 1.2,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}