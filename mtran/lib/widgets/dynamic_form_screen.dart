/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: dynamic_form_screen.dart
*/

import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/constants/nav_links.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/models/message.dart';
import 'package:salepro/models/nav_link.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/providers/theme_provider.dart';
import 'package:salepro/screens/auth/welcome.dart';
import 'package:salepro/utils/control_loading.dart';
import 'package:salepro/utils/create_select_input_data.dart';
import 'package:salepro/utils/get_app_logo.dart';
import 'package:salepro/utils/get_nav_link.dart';
import 'package:salepro/utils/get_screensize.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/widgets/checkbox.dart';
import 'package:salepro/widgets/date_picker.dart';
import 'package:salepro/widgets/date_range_picker.dart';
import 'package:salepro/widgets/editor.dart';
import 'package:salepro/widgets/file_picker.dart';
import 'package:salepro/widgets/form.dart';
import 'package:salepro/widgets/form_screen.dart';
import 'package:salepro/widgets/import_data.dart';
import 'package:salepro/widgets/input.dart';
import 'package:salepro/widgets/select.dart';
import 'package:salepro/widgets/table_generator.dart';
import 'package:salepro/widgets/pos_cart_input.dart';
import 'package:salepro/widgets/tags_input.dart';
import 'package:salepro/widgets/time_picker.dart';
import 'package:salepro/screens/print_selection_screen.dart';
import 'package:salepro/widgets/variant_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salepro/providers/offline_submission_provider.dart';
import 'package:salepro/models/offline_submission.dart';
import 'package:salepro/widgets/draft_button.dart';

class DynamicFormScreen extends StatefulWidget {
  final String? apiUrl;
  final String? jsonString;
  final String? title;
  final Widget? redirectScreen;
  final Map<String, dynamic>? initialData;
  final Map<String, List<String>>? initialFiles;
  final Map? params;

  const DynamicFormScreen({
    super.key,
    this.apiUrl,
    this.jsonString,
    this.title,
    this.redirectScreen,
    this.initialData,
    this.initialFiles,
    this.params,
  });

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen> {
  Map<String, dynamic>? formSchema;
  Map<String, dynamic> formData = {};
  final Map<String, TextEditingController> controllers = {};
  final Map<String, List<String>> images = {};
  final Map<String, DateTime?> selectedDates =
      {}; // Track actual selected dates
  final Map<String, String?> selectedTimes = {}; // Track actual selected times
  final Map<String, Map<String, DateTime>?> selectedDateRanges =
      {}; // Track selected date ranges
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<int> groupIndexes = [];
  String? serverUrl;
  Message? message;

  @override
  void dispose() {
    // Dispose all TextEditingControllers
    for (final controller in controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> fetchForm({bool repeat = false}) async {
    if (widget.apiUrl != null) {
      context.read<CommonDataProvider>().getData();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
      String token = prefs.getString(AppKeys.loginKey) ?? "";
      setState(() {
        serverUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      });

      try {
        if (!repeat) {
          if (prefs.getString(widget.apiUrl!) != null &&
              prefs.getString(widget.apiUrl!)!.isNotEmpty) {
            Loading.stop(context);
            formSchema = jsonDecode(prefs.getString(widget.apiUrl!)!);
            setState(() {});
          }
        }

        final uri = Uri.parse(
          "$serverUrl${widget.apiUrl.toString().split('?')[0]}?token=$spToken${widget.apiUrl.toString().split('?').length > 1 ? "&${widget.apiUrl.toString().split('?')[1]}" : ""}",
        );

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
            'Accept': 'application/json',
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

        await Loading.stop(context);

        prefs.setString(AppKeys.noInternetKey, "false");
        await context.read<CommonDataProvider>().checkInternet();

        if (response.statusCode == 200) {
          prefs.setString(widget.apiUrl!, response.body);

          setState(() {
            formSchema = jsonDecode(response.body);
            _initializeFormData();
          });

          // Start timing for debug logging
          final startTime = DateTime.now();

          // Log the request
          String? requestId;

          if (formSchema != null && formSchema?['offline_submit_url'] != null) {
            final offlineUri = Uri.parse(
              "$serverUrl${formSchema!['offline_submit_url'].toString().split('?')[0]}?token=$spToken${formSchema!['offline_submit_url'].toString().split('?').length > 1 ? "&${formSchema!['offline_submit_url'].toString().split('?')[1]}" : ""}",
            );
            if (mounted) {
              requestId = context.read<DebugProvider>().logRequest(
                method: 'GET',
                url: offlineUri.toString(),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Accept': 'application/json',
                },
              );
            }

            final offlineRes = await http.get(
              offlineUri,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );

            // Calculate duration
            final duration = DateTime.now().difference(startTime);

            // Log the response
            if (mounted && requestId != null) {
              context.read<DebugProvider>().logResponse(
                id: requestId,
                statusCode: offlineRes.statusCode,
                responseBody: offlineRes.body,
                duration: duration,
              );
            }

            prefs.setString(formSchema?['offline_submit_url'], offlineRes.body);
          }

          if (formSchema != null &&
              formSchema?['submit_strategy'] == 'params') {
            final offlineUri = Uri.parse(
              "$serverUrl${formSchema!['submit_url'].toString().split('?')[0]}?token=$spToken${formSchema!['submit_url'].toString().split('?').length > 1 ? "&${formSchema!['submit_url'].toString().split('?')[1]}" : ""}",
            );
            if (mounted) {
              requestId = context.read<DebugProvider>().logRequest(
                method: 'GET',
                url: offlineUri.toString(),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Accept': 'application/json',
                },
              );
            }

            final offlineRes = await http.get(
              offlineUri,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );

            // Calculate duration
            final duration = DateTime.now().difference(startTime);

            // Log the response
            if (mounted && requestId != null) {
              context.read<DebugProvider>().logResponse(
                id: requestId,
                statusCode: offlineRes.statusCode,
                responseBody: offlineRes.body,
                duration: duration,
              );
            }

            prefs.setString(formSchema?['submit_url'], offlineRes.body);
          }
        } else {
          message = Message.fromJson(jsonDecode(response.body));

          if (message != null) {
            if (message!.invalidToken) {
              // Token is invalid, force logout
              prefs.remove(AppKeys.loginKey);
              await context.read<CommonDataProvider>().logout();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => WelcomeScreen()),
              );
            } else if (message!.invalidLicenseToken) {
              prefs.clear();
              await context.read<CommonDataProvider>().clearData();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => WelcomeScreen()),
              );
            }
          }
          if (mounted) {
            showSnackBar(message?.message, context, type: "error");
          }
          context.read<ThemeProvider>().changeDebugBar(
            message?.debugBar ?? false,
          );
        }
      } on SocketException catch (_) {
        await Loading.stop(context);
        if (prefs.getString(widget.apiUrl!) != null &&
            prefs.getString(widget.apiUrl!)!.isNotEmpty) {
          setState(() {
            formSchema = jsonDecode(prefs.getString(widget.apiUrl!)!);
            _initializeFormData();
          });
          prefs.setString(AppKeys.noInternetKey, "true");
          await context.read<CommonDataProvider>().checkInternet();
        } else {
          prefs.setString(AppKeys.noInternetKey, "true");
          await context.read<CommonDataProvider>().checkInternet();
          if (mounted) {
            showSnackBar(
              "You are currently in offline mode and this page is not available in offline mode...",
              context,
              type: "error",
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showSnackBar("Something went wrong...", context, type: "error");
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      formData.addAll(widget.initialData!);
    }
    if (widget.initialFiles != null) {
      images.addAll(widget.initialFiles!);
    }

    if (widget.jsonString != null) {
      formSchema = jsonDecode(widget.jsonString!);
      _initializeFormData();
    } else {
      fetchForm();
    }
  }

  void _initializeFormData() {
    if (formSchema == null || formSchema!['fields'] == null) return;

    // Pre-initialize all form data to avoid setState during build
    for (var field in formSchema!['fields']) {
      _initializeFieldData(field);
    }
  }

  void _initializeFieldData(Map<String, dynamic> field) {
    if (field['name'] == null) return;

    final fieldName = field['name'];

    // Handle different field types
    switch (field['type']) {
      case 'checkbox':
        // Always ensure checkbox has a boolean value
        if (formData[fieldName] == null) {
          var value =
              field['value'] ??
              widget.params?[field['param']] ??
              widget.params?[fieldName];
          // Convert various truthy values to boolean
          if (value == true || value == 1 || value == '1' || value == 'true') {
            formData[fieldName] = true;
          } else if (value == false ||
              value == 0 ||
              value == '0' ||
              value == 'false') {
            formData[fieldName] = false;
          } else {
            formData[fieldName] = false; // Default to false
          }
        }
        break;

      case 'tags':
        if (formData[fieldName] == null) {
          var value =
              field['value'] ??
              widget.params?[field['param']] ??
              widget.params?[fieldName];
          formData[fieldName] = value is List
              ? List<String>.from(value)
              : <String>[];
        }
        break;

      case 'file':
        if (images[fieldName] == null) {
          images[fieldName] = [];
        }
        break;

      case 'hidden':
        formData[fieldName] =
            field['value'] ??
            widget.params?[field['param']] ??
            widget.params?[fieldName];
        break;

      case 'group':
        // Recursively initialize group items
        if (field['items'] != null) {
          for (var item in field['items']) {
            _initializeFieldData(item);
          }
        }
        break;

      default:
        if (formData[fieldName] == null &&
            field['value'] == null &&
            field['param'] != null &&
            widget.params != null &&
            widget.params![field['param']] != null) {
          formData[fieldName] = widget.params![field['param']];
        } else if (formData[fieldName] == null &&
            field['value'] == null &&
            widget.params != null &&
            widget.params![fieldName] != null) {
          formData[fieldName] = widget.params![fieldName];
        }
        break;
    }
  }

  bool logicBuilder(dynamic field, dynamic Function(dynamic logic) item) {
    bool isFirst = true;

    if (field['logics'] == null || field['logics'].isEmpty) {
      return true;
    }
    for (var logic in field['logics']) {
      if (logic['field'] == null || logic['values'] == null) continue;

      // Get the value from formData, handle null case
      var fieldValue = item(logic);

      // Check if the field value matches any of the expected values
      // Handle null values properly
      if (logic['values'].contains(fieldValue)) {
        isFirst = true;
      } else {
        isFirst = false;
        break;
      }
    }

    return isFirst;
  }

  CrossFadeState generateCrossFadeState(dynamic field) {
    bool isFirst = logicBuilder(field, (logic) => formData[logic['field']]);
    return isFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond;
  }

  TextInputType parseKeyboardType(String? type) {
    switch (type) {
      case "number":
        return TextInputType.number;
      case "email":
        return TextInputType.emailAddress;
      case "phone":
        return TextInputType.phone;
      case "multiline":
        return TextInputType.multiline;
      case "datetime":
        return TextInputType.datetime;
      case "url":
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  TextAlign handleTextAlignment(String? align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  FontWeight? handleFontWeight(String? weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case '100':
        return FontWeight.w100;
      case '200':
        return FontWeight.w200;
      case '300':
        return FontWeight.w300;
      case '400':
        return FontWeight.w400;
      case '500':
        return FontWeight.w500;
      case '600':
        return FontWeight.w600;
      case '700':
        return FontWeight.w700;
      case '800':
        return FontWeight.w800;
      case '900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  /// Build dynamic field with your custom widgets
  Widget generateField(Map<String, dynamic> field) {
    bool isGradient =
        formSchema?['background'] != null &&
        formSchema?['background']['gradient'] != null;
    if (field['fancy'] == true) {
      isGradient = true;
    }

    bool isGlass =
        formSchema?['background'] != null &&
        formSchema?['background']['image'] != null;
    if (field['glass'] == true) {
      isGlass = true;
    }

    switch (field['type']) {
      case 'text':
        final controller = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                formData[field['name']]?.toString() ??
                field['value']?.toString() ??
                widget.params?[field['param']]?.toString() ??
                widget.params?[field['name']]?.toString() ??
                "",
          ),
        );
        return AppInput(
          hintText: field['label'],
          placeholder: field['placeholder'],
          controller: controller,
          errorLine: message?.errors?[field['name']],
          keyboardType: parseKeyboardType(field['keyboard_type']),
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          iconKey: field['icon'],
          gradient: isGradient,
          glass: isGlass,
          multiline: field['multiline'] ?? false,
          readOnly: field['readonly'] ?? false,
          password: field['password'] ?? false,
          onChanged: (value) {
            formData[field['name']] = value;
            if (field['payment_trigger'] == true) {
              double received = double.tryParse(value) ?? 0;
              double paying =
                  double.tryParse(controllers['paying_amount']?.text ?? '0') ??
                  0;
              double change = received - paying;
              if (controllers.containsKey('change')) {
                controllers['change']!.text = change.toStringAsFixed(2);
              }
            }
          },
          screenToOpenOnSuffixTap: field['action'] != null
              ? customScreens[field['action']]
              : field['new_screen'] != null
              ? getNavScreen(
                  context,
                  NavLink(
                    title: "",
                    group: false,
                    apiUrl: field['new_screen'],
                    type: field['new_screen_type'] ?? 'form',
                  ),
                )
              : null,
        );

      case 'datagenerator':
        String? generatedData;

        if (field['generator'] != null &&
            field['generator']['generated_type'] == 'reference_no') {
          generatedData =
              '${field['generator']['prefix'] ?? '${defaultAppName.substring(0, 3).toUpperCase()}-'}${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateFormat('HHmmss').format(DateTime.now())}';
        }

        final controller = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                formData[field['name']]?.toString() ??
                field['value']?.toString() ??
                generatedData ??
                widget.params?[field['param']]?.toString() ??
                widget.params?[field['name']]?.toString() ??
                "",
          ),
        );
        if (field['generator_url'] != null) {
          return AppInput(
            hintText: field['label'],
            placeholder: field['placeholder'],
            controller: controller,
            errorLine: message?.errors?[field['name']],
            keyboardType: parseKeyboardType(field['keyboard_type']),
            iconKey: field['icon'],
            info: field['info'],
            showInfoIcon: field['show_info_icon'] ?? false,
            gradient: isGradient,
            glass: isGlass,
            multiline: field['multiline'] ?? false,
            readOnly: field['readonly'] ?? false,
            actionIcon: 'magic-wand',
            screenToOpenOnSuffixTap: field['action'] != null
                ? customScreens[field['action']]
                : field['new_screen'] != null
                ? getNavScreen(
                    context,
                    NavLink(
                      title: "",
                      group: false,
                      apiUrl: field['new_screen'],
                      type: field['new_screen_type'] ?? 'form',
                    ),
                  )
                : null,
            onAction: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              setState(() {
                serverUrl =
                    prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
              });
              String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
              String token = prefs.getString(AppKeys.loginKey) ?? "";

              try {
                final response = await http.get(
                  Uri.parse(
                    "$serverUrl${field['generator_url']}?token=$spToken",
                  ),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                  },
                );
                if (response.statusCode == 200) {
                  await Loading.stop(context);
                  controller.text = response.body;
                } else {
                  if (mounted) {
                    showSnackBar(
                      "Something went wrong...",
                      context,
                      type: "error",
                    );
                  }
                }
              } on SocketException catch (_) {
                await Loading.stop(context);
                if (mounted) {
                  showSnackBar(
                    "You are currently in offline mode...",
                    context,
                    type: "error",
                  );
                }
              } catch (e) {
                if (mounted) {
                  showSnackBar(
                    "Something went wrong...",
                    context,
                    type: "error",
                  );
                }
              }
            },
          );
        } else {
          return AppInput(
            hintText: field['label'],
            placeholder: field['placeholder'],
            controller: controller,
            errorLine: message?.errors?[field['name']],
            keyboardType: parseKeyboardType(field['keyboard_type']),
            iconKey: field['icon'],
            info: field['info'],
            showInfoIcon: field['show_info_icon'] ?? false,
            gradient: isGradient,
            glass: isGlass,
            multiline: field['multiline'] ?? false,
            readOnly: field['readonly'] ?? false,
            screenToOpenOnSuffixTap: field['action'] != null
                ? customScreens[field['action']]
                : field['new_screen'] != null
                ? getNavScreen(
                    context,
                    NavLink(
                      title: "",
                      group: false,
                      apiUrl: field['new_screen'],
                      type: field['new_screen_type'] ?? 'form',
                    ),
                  )
                : null,
          );
        }

      case 'productinput':
        if (formData[field['name']] == null) {
          if (field['value'] != null) {
            setState(() {
              formData[field['name']] = field['value'].toString();
            });
          } else if (widget.params?[field['param']] != null) {
            setState(() {
              formData[field['name']] = widget.params?[field['param']]
                  .toString();
            });
          } else if (widget.params?[field['name']] != null) {
            setState(() {
              formData[field['name']] = widget.params?[field['name']]
                  .toString();
            });
          }
        }
        return AppSelect(
          hintText: field['label'],
          value: formData[field['name']],
          items: selectDataFromBody(
            field['options'] ?? [],
            logicField: 'logics',
          ),
          logicBuilder: (option) {
            if (logicBuilder(option, (logic) => formData[logic['field']])) {
              return option;
            } else {
              return null;
            }
          },
          onChange: (value) {
            setState(() {
              formData[field['name']] = value;
            });
          },
          enableFilter: field['enable_filter'] ?? false,
          enableSearch: field['enable_search'] ?? false,
          errorLine: message?.errors?[field['name']],
          icon: field['icon'],
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          gradient: isGradient,
          glass: isGlass,
          screenToOpenOnSuffixTap: field['action'] != null
              ? customScreens[field['action']]
              : field['new_screen'] != null
              ? getNavScreen(
                  context,
                  NavLink(
                    title: "",
                    group: false,
                    apiUrl: field['new_screen'],
                    type: field['new_screen_type'] ?? 'form',
                  ),
                )
              : null,
        );

      case 'select':
        if (formData[field['name']] == null) {
          if (field['value'] != null) {
            setState(() {
              formData[field['name']] = field['value'].toString();
            });
          } else if (widget.params?[field['param']] != null) {
            setState(() {
              formData[field['name']] = widget.params?[field['param']]
                  .toString();
            });
          } else if (widget.params?[field['name']] != null) {
            setState(() {
              formData[field['name']] = widget.params?[field['name']]
                  .toString();
            });
          }
        }
        return AppSelect(
          hintText: field['label'],
          value: formData[field['name']],
          items: selectDataFromBody(
            field['options'] ?? [],
            logicField: 'logics',
          ),
          logicBuilder: (option) {
            if (logicBuilder(option, (logic) => formData[logic['field']])) {
              return option;
            } else {
              return null;
            }
          },
          onChange: (value) {
            setState(() {
              formData[field['name']] = value;
            });
          },
          enableFilter: field['enable_filter'] ?? false,
          enableSearch: field['enable_search'] ?? false,
          errorLine: message?.errors?[field['name']],
          icon: field['icon'],
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          gradient: isGradient,
          glass: isGlass,
          screenToOpenOnSuffixTap: field['action'] != null
              ? customScreens[field['action']]
              : field['new_screen'] != null
              ? getNavScreen(
                  context,
                  NavLink(
                    title: "",
                    group: false,
                    apiUrl: field['new_screen'],
                    type: field['new_screen_type'] ?? 'form',
                  ),
                )
              : null,
        );

      case 'checkbox':
        // Ensure value is never null
        if (formData[field['name']] == null) {
          formData[field['name']] =
              field['value'] ??
              widget.params?[field['param']] ??
              widget.params?[field['name']] ??
              false;
        }
        // Ensure value is always boolean
        final boolValue =
            formData[field['name']] == true ||
            formData[field['name']] == 1 ||
            formData[field['name']] == '1' ||
            formData[field['name']] == 'true';

        return AppCheckBox(
          hintText: field['label'],
          value: boolValue,
          onChanged: (value) {
            setState(() {
              formData[field['name']] = value!;
            });
          },
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          errorLine: message?.errors?[field['name']],
          glass: isGlass,
        );

      case 'tags':
        // Data already initialized in initState
        if (formData[field['name']] == null) {
          var val =
              field['value'] ??
              widget.params?[field['param']] ??
              widget.params?[field['name']];
          formData[field['name']] = val is List
              ? List<String>.from(val)
              : <String>[];
        }
        return AppTagsInput(
          hintText: field['label'],
          placeholder: field['placeholder'],
          initialTags: formData[field['name']] is List
              ? List<String>.from(formData[field['name']])
              : <String>[],
          onChanged: (tags) {
            setState(() {
              formData[field['name']] = tags;
            });
          },
          errorLine: message?.errors?[field['name']]?.join(', '),
          iconKey: field['icon'],
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          gradient: isGradient,
          glass: isGlass,
        );

      case 'file':
        final controller = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                images[field['name']] != null &&
                    images[field['name']]!.isNotEmpty
                ? (field['multiple'] == true
                      ? "${images[field['name']]!.length} files selected"
                      : images[field['name']]!.first.split('/').last)
                : "",
          ),
        );
        // Data already initialized in initState
        return AppFilePicker(
          allowedExtensions: List<String>.from(
            field['allowed_extensions'] ?? [],
          ),
          hintText: field['label'],
          controller: controller,
          allowMultiple: field['multiple'] ?? false,
          icon: field['icon'],
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          gradient: isGradient,
          glass: isGlass,
          errorLine: message?.errors?[field['name']],
          onChanged: (img) {
            setState(() {
              images[field['name']] = field['multiple']
                  ? (img as List<File>).map((i) => i.path).toList()
                  : [(img as File).path];
            });
          },
        );

      case 'editor':
        final editorController = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                formData[field['name']]?.toString() ??
                field['value']?.toString() ??
                widget.params?[field['param']]?.toString() ??
                widget.params?[field['name']]?.toString(),
          ),
        );
        return Editor(
          controller: editorController,
          label: field['label'],
          glass: isGlass,
          gradient: isGradient,
          background: formSchema?['background'],
          serverUrl: serverUrl?.replaceFirst('/api', '') ?? defaultApiURL,
          errorLine: message?.errors?[field['name']],
        );

      case 'datepicker':
        final controller = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                formData[field['name']]?.toString() ??
                field['value']?.toString() ??
                widget.params?[field['param']]?.toString() ??
                widget.params?[field['name']]?.toString(),
          ),
        );
        return AppDatePicker(
          controller: controller,
          hintText: field['label'],
          value: DateTime.tryParse(controller.text),
          startingDate: formData[field['starting_date']] != null
              ? DateTime.tryParse(formData[field['starting_date']])
              : null,
          endingDate: formData[field['ending_date']] != null
              ? DateTime.tryParse(formData[field['ending_date']])
              : null,
          icon: field['icon'],
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          gradient: isGradient,
          glass: isGlass,
          errorLine: message?.errors?[field['name']],
          formatSpecifier: field['format_specifier'],
          onChanged: (date) {
            selectedDates[field['name']] = date;
          },
        );

      case 'daterangepicker':
        final controller = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                formData[field['name']]?.toString() ??
                field['value']?.toString() ??
                widget.params?[field['param']]?.toString() ??
                widget.params?[field['name']]?.toString(),
          ),
        );
        return AppDateRangePicker(
          controller: controller,
          hintText: field['label'],
          value: DateTime.tryParse(controller.text),
          startingDate: formData[field['starting_date']] != null
              ? DateTime.tryParse(formData[field['starting_date']])
              : null,
          endingDate: formData[field['ending_date']] != null
              ? DateTime.tryParse(formData[field['ending_date']])
              : null,
          icon: field['icon'],
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          gradient: isGradient,
          glass: isGlass,
          errorLine: message?.errors?[field['name']],
          formatSpecifier: field['format_specifier'],
          onChanged: (startDate, endDate) {
            selectedDateRanges[field['name']] = {
              'start': startDate,
              'end': endDate,
            };
          },
        );

      case 'timepicker':
        final controller = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                formData[field['name']]?.toString() ??
                field['value']?.toString() ??
                widget.params?[field['param']]?.toString() ??
                widget.params?[field['name']]?.toString(),
          ),
        );
        return AppTimePicker(
          controller: controller,
          hintText: field['label'],
          value: DateTime.tryParse(controller.text),
          startingDate: formData[field['starting_date']] != null
              ? DateTime.tryParse(formData[field['starting_date']])
              : null,
          endingDate: formData[field['ending_date']] != null
              ? DateTime.tryParse(formData[field['ending_date']])
              : null,
          icon: field['icon'],
          info: field['info'],
          showInfoIcon: field['show_info_icon'] ?? false,
          gradient: isGradient,
          glass: isGlass,
          errorLine: message?.errors?[field['name']],
          formatSpecifier: field['format_specifier'],
          onChanged: (time) {
            selectedTimes[field['name']] = DateFormat(
              field['format_specifier'] ?? 'jm',
            ).format(time);
          },
        );

      case 'importdata':
        final controller = controllers.putIfAbsent(
          field['name'],
          () => TextEditingController(
            text:
                formData[field['name']]?.toString() ??
                field['value']?.toString() ??
                widget.params?[field['param']]?.toString() ??
                widget.params?[field['name']]?.toString(),
          ),
        );
        return ImportData(
          controller: controller,
          fileLink: field['file_link'],
          hintText: field['hint_text'],
          sampleFileName: field['sample_file_name'],
          downloadTitle: field['download_title'],
          glass: isGlass,
          gradient: isGradient,
        );

      case 'helpertext':
        return Text(
          field['text'],
          textAlign: handleTextAlignment(field['text_align']),
          style: TextStyle(
            fontSize:
                double.tryParse(field['font_size'].toString()) ??
                AppSpacing.kDefaultSpacing(context),
            fontWeight: handleFontWeight(field['font_weight']),
            fontStyle: field['font_style'] == 'italic'
                ? FontStyle.italic
                : FontStyle.normal,
            color: useThemeMode(
              context,
              light:
                  field['light_color'] ??
                      formSchema?['background'] != null &&
                          formSchema?['background']['image'] != null &&
                          formSchema?['background']['image']['light'] != null
                  ? AppColors.slateSwatch
                  : getThemeColor(context)?.shade900,
              dark:
                  field['dark_color'] ??
                      formSchema?['background'] != null &&
                          formSchema?['background']['image'] != null &&
                          formSchema?['background']['image']['dark'] != null
                  ? AppColors.white
                  : getThemeColor(context)?.shade100,
            ),
          ),
        );

      case 'space':
        return SizedBox(
          height: field['height'] != null
              ? double.tryParse(field['height'].toString()) ??
                    AppSpacing.kDefaultSpacing(context)
              : 0,
          width: field['width'] != null
              ? double.tryParse(field['width'].toString()) ??
                    AppSpacing.kDefaultSpacing(context)
              : 0,
        );

      case 'image':
        if (field['src'] == null && field['dark_src'] == null) {
          return hasNetworkLogo(context)
              ? Image.network(
                  getAppLogo(context)!,
                  height: field['height'] != null
                      ? double.tryParse(field['height'].toString()) ??
                            AppSpacing.kDefaultSpacing(context) * 5
                      : null,
                  width: field['width'] != null
                      ? double.tryParse(field['width'].toString()) ??
                            AppSpacing.kDefaultSpacing(context) * 5
                      : null,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    getAppLogo(context, useNetworkLogo: false)!,
                    height: field['height'] != null
                        ? double.tryParse(field['height'].toString()) ??
                              AppSpacing.kDefaultSpacing(context) * 5
                        : null,
                    width: field['width'] != null
                        ? double.tryParse(field['width'].toString()) ??
                              AppSpacing.kDefaultSpacing(context) * 5
                        : null,
                  ),
                )
              : Image.asset(
                  getAppLogo(context, useNetworkLogo: false)!,
                  height: field['height'] != null
                      ? double.tryParse(field['height'].toString()) ??
                            AppSpacing.kDefaultSpacing(context) * 5
                      : null,
                  width: field['width'] != null
                      ? double.tryParse(field['width'].toString()) ??
                            AppSpacing.kDefaultSpacing(context) * 5
                      : null,
                );
        } else {
          return CachedNetworkImage(
            imageUrl: useThemeMode(
              context,
              light:
                  "${serverUrl.toString().replaceAll('/api', '/')}${field['src'] ?? field['dark_src']}",
              dark:
                  "${serverUrl.toString().replaceAll('/api', '/')}${field['dark_src'] ?? field['src']}",
            ),
            height: field['height'] != null
                ? double.tryParse(field['height'].toString()) ??
                      AppSpacing.kDefaultSpacing(context) * 5
                : AppSpacing.kDefaultSpacing(context) * 5,
            width: field['width'] != null
                ? double.tryParse(field['width'].toString()) ??
                      AppSpacing.kDefaultSpacing(context) * 5
                : AppSpacing.kDefaultSpacing(context) * 5,
            errorWidget: (context, url, error) => hasNetworkLogo(context)
                ? Image.network(
                    getAppLogo(context)!,
                    height: AppSpacing.kDefaultSpacing(context) * 5,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      getAppLogo(context, useNetworkLogo: false)!,
                      height: field['height'] != null
                          ? double.tryParse(field['height'].toString()) ??
                                AppSpacing.kDefaultSpacing(context) * 5
                          : AppSpacing.kDefaultSpacing(context) * 5,
                      width: field['width'] != null
                          ? double.tryParse(field['width'].toString()) ??
                                AppSpacing.kDefaultSpacing(context) * 5
                          : AppSpacing.kDefaultSpacing(context) * 5,
                    ),
                  )
                : Image.asset(
                    getAppLogo(context, useNetworkLogo: false)!,
                    height: field['height'] != null
                        ? double.tryParse(field['height'].toString()) ??
                              AppSpacing.kDefaultSpacing(context) * 5
                        : AppSpacing.kDefaultSpacing(context) * 5,
                    width: field['width'] != null
                        ? double.tryParse(field['width'].toString()) ??
                              AppSpacing.kDefaultSpacing(context) * 5
                        : AppSpacing.kDefaultSpacing(context) * 5,
                  ),
          );
        }

      case 'anchor':
        return SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => getNavScreen(
                    context,
                    NavLink(
                      title: "",
                      group: false,
                      apiUrl: field['href'],
                      type: field['href_type'] ?? 'form',
                    ),
                  ),
                ),
              );
            },
            child: RichText(
              textAlign: handleTextAlignment(field['text_align']),
              text: TextSpan(
                style: TextStyle(
                  fontSize:
                      double.tryParse(field['font_size']?.toString() ?? '') ??
                      AppSpacing.kDefaultSpacing(context) * 0.8,
                  fontWeight: handleFontWeight(field['font_weight']),
                  fontFamily: getThemeFont(context),
                  color: useThemeMode(
                    context,
                    light:
                        field['light_color'] ??
                            formSchema?['background'] != null &&
                                formSchema?['background']['image'] != null &&
                                formSchema?['background']['image']['light'] !=
                                    null
                        ? AppColors.slateSwatch.shade800
                        : getThemeColor(context)?.shade800,
                    dark:
                        field['dark_color'] ??
                            formSchema?['background'] != null &&
                                formSchema?['background']['image'] != null &&
                                formSchema?['background']['image']['dark'] !=
                                    null
                        ? AppColors.slateSwatch.shade50
                        : getThemeColor(context)?.shade300,
                  ),
                  fontStyle: field['font_style'] == 'italic'
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                text: field['text'] ?? "Click ",
                children: field['highlight'] != null
                    ? [
                        TextSpan(
                          text: field['highlight']['text'],
                          style: TextStyle(
                            height: 1.2,
                            color: useThemeMode(
                              context,
                              light:
                                  field['highlight']['light_color'] ??
                                      formSchema?['background'] != null &&
                                          formSchema?['background']['image'] !=
                                              null &&
                                          formSchema?['background']['image']['light'] !=
                                              null
                                  ? AppColors.slateSwatch
                                  : getThemeColor(context)?.shade900,
                              dark:
                                  field['highlight']['dark_color'] ??
                                      formSchema?['background'] != null &&
                                          formSchema?['background']['image'] !=
                                              null &&
                                          formSchema?['background']['image']['dark'] !=
                                              null
                                  ? AppColors.white
                                  : getThemeColor(context)?.shade100,
                            ),
                            fontWeight: handleFontWeight(
                              field['highlight']['font_weight'],
                            ),
                            fontSize: field['highlight']['font_size'] != null
                                ? double.tryParse(
                                        field['highlight']['font_size']
                                            .toString(),
                                      ) ??
                                      AppSpacing.kDefaultSpacing(context) * 0.8
                                : null,
                            fontStyle:
                                field['highlight']['font_style'] == 'italic'
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );

      case 'table_generator':
        return TableGeneratorInput(
          config: field,
          formData: formData,
          glass: isGlass,
          gradient: isGradient,
          onDataChanged: (data) {
            setState(() {
              // Store rows data directly with the field name (e.g., "products")
              final rows = data['rows'] as List<Map<String, dynamic>>;

              // Store the rows array directly
              formData[field['name']] = rows;

              // Also store totals for reference
              formData['${field['name']}_totals'] = data['totals'];
            });
          },
        );

      case 'variant_generator':
        // Get product code from formData if it exists
        String? productCode = formData['code']?.toString();

        return AppVariantGenerator(
          field: field,
          productCode: productCode,
          glass: isGlass,
          gradient: isGradient,
          onChange:
              (
                variantOptions,
                variantValues,
                variantNames,
                itemCodes,
                additionalCosts,
                additionalPrices,
              ) {
                setState(() {
                  // Store option/value arrays for backend
                  formData['variant_option'] = variantOptions;
                  formData['variant_value'] = variantValues;

                  // Store generated variant detail arrays
                  formData['variant_name'] = variantNames;
                  formData['item_code'] = itemCodes;
                  formData['additional_cost'] = additionalCosts;
                  formData['additional_price'] = additionalPrices;
                });
              },
        );

      case 'pos_cart':
        return PosCartInput(
          config: field,
          formData: formData,
          onSubmit: (type) => handleSubmit(submitType: type),
          onDataChanged: (data) {
            setState(() {
              // Merge all data from cart (items + summary fields + totals) into formData
              formData.addAll(data);
            });
          },
        );

      case 'hidden':
        // Data already initialized in initState
        return SizedBox(height: 0, width: 0);

      case 'group':
        if (field['collapsible'] == null ||
            (field['collapsible'] != null && !field['collapsible'])) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: generateInputGroups([
              if (field['label'] != null)
                Text(
                  field['label'],
                  style: TextStyle(
                    fontSize: AppSpacing.kDefaultSpacing(context),
                    fontWeight: FontWeight.bold,
                    color: useThemeMode(
                      context,
                      light: getThemeColor(context)?.shade900,
                      dark: getThemeColor(context)?.shade200,
                    ),
                  ),
                ),
              ...field['items']
                  .map<Widget>(
                    (item) => AnimatedCrossFade(
                      duration: Duration(milliseconds: 500),
                      firstChild: buildField(item),
                      secondChild: SizedBox.shrink(),
                      crossFadeState: generateCrossFadeState(item),
                    ),
                  )
                  .toList(),
            ]),
          );
        } else {
          return ExpansionTile(
            title: Text(
              field['label'] ?? "See More",
              style: TextStyle(
                fontSize: AppSpacing.kDefaultSpacing(context),
                fontWeight: FontWeight.bold,
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)?.shade900,
                  dark: getThemeColor(context)?.shade200,
                ),
              ),
            ),
            children: generateInputGroups(
              field['items']
                  .map<Widget>(
                    (item) => AnimatedCrossFade(
                      duration: Duration(milliseconds: 500),
                      firstChild: buildField(item),
                      secondChild: SizedBox.shrink(),
                      crossFadeState: generateCrossFadeState(item),
                    ),
                  )
                  .toList(),
            ),
          );
        }

      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildField(Map<String, dynamic> field) {
    final iconPack = context
        .watch<CommonDataProvider>()
        .currentThemeSetting
        ?.iconPack;
    if (field['name'].toString().contains("[]")) {
      // ---------- GROUP ARRAYS ----------
      if (field['type'] == "group" && field['items'] != null) {
        final List items = List.from(field['items']);
        if (items.isEmpty) return const SizedBox.shrink();

        final String firstItem = items[0]['name'];

        // Compute current group indexes
        groupIndexes =
            formData.keys
                .where((k) => k.startsWith("$firstItem["))
                .map(
                  (k) => int.parse(
                    k.replaceAll("$firstItem[", "").replaceAll("]", ""),
                  ),
                )
                .toList()
              ..sort();

        setState(() {});

        // Delete a whole group at index `idx`
        void deleteGroupAt(int idx) {
          // Remove exact keys for this group
          for (var item in items) {
            final String name = item['name'];
            formData.remove("$name[$idx]");
            if (controllers.containsKey("$name[$idx]")) {
              controllers["$name[$idx]"]!.dispose();
              controllers.remove("$name[$idx]");
            }
          }

          // Shift higher indices down
          int nextIdx = idx + 1;
          bool shifted = true;
          while (shifted) {
            shifted = false;
            for (var item in items) {
              final String name = item['name'];
              if (formData.containsKey("$name[$nextIdx]")) {
                formData["$name[${nextIdx - 1}]"] = formData["$name[$nextIdx]"];
                formData.remove("$name[$nextIdx]");
                setState(() {});
                shifted = true;
              }
            }
            nextIdx++;
          }
          setState(() {});
        }

        // Add a new group
        void addGroup() {
          int maxIndex = -1;
          for (var item in items) {
            final String name = item['name'];
            final existingIndexes = formData.keys
                .where((k) => k.startsWith("$name["))
                .map(
                  (k) =>
                      int.parse(k.replaceAll("$name[", "").replaceAll("]", "")),
                );
            if (existingIndexes.isNotEmpty) {
              final localMax = existingIndexes.reduce((a, b) => a > b ? a : b);
              if (localMax > maxIndex) maxIndex = localMax;
            }
          }
          final int newIndex = maxIndex + 1;
          for (var item in items) {
            formData["${item['name']}[$newIndex]"] = "";
          }
          setState(() {});
        }

        return Column(
          children: [
            ...generateInputGroups(
              groupIndexes.map((idx) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: generateInputGroups([
                          if (field['label'] != null)
                            Text(
                              "${field['label']} ${idx + 1}",
                              style: TextStyle(
                                fontSize: AppSpacing.kDefaultSpacing(context),
                                fontWeight: FontWeight.bold,
                                color: useThemeMode(
                                  context,
                                  light: getThemeColor(context)?.shade900,
                                  dark: getThemeColor(context)?.shade200,
                                ),
                              ),
                            ),
                          ...items.map<Widget>((it) {
                            final String indexedName = "${it['name']}[$idx]";
                            return AnimatedCrossFade(
                              duration: Duration(milliseconds: 500),
                              firstChild: buildField({
                                ...it,
                                'name': indexedName,
                                'value': formData[indexedName] ?? "",
                                'label': it['label'],
                              }),
                              secondChild: SizedBox.shrink(),
                              crossFadeState: generateCrossFadeState({
                                ...it,
                                'name': indexedName,
                                'value': formData[indexedName] ?? "",
                                'label': it['label'],
                              }),
                            );
                          }),
                        ]),
                      ),
                    ),
                    SizedBox(width: AppSpacing.kDefaultSpacing(context) * 0.5),
                    IconButton.outlined(
                      onPressed: () => deleteGroupAt(idx),
                      icon: IconMapper.icon(
                        'delete',
                        iconPack: iconPack,
                        color: Colors.red,
                        size: AppSpacing.kDefaultSpacing(context) * 2,
                      ),
                    ),
                  ],
                );
              }).toList(),
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
              ),
            ),
            // Add button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.kDefaultSpacing(context) * 0.5,
              ),
              child: AppButton(
                title: "Add ${field['label']}",
                width: getScreenSize(context, type: "width"),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.kDefaultSpacing(context) * 2,
                  vertical: AppSpacing.kDefaultSpacing(context) * 0.8,
                ),
                icon: IconMapper.icon('plus-circle', iconPack: iconPack),
                fontSize: AppSpacing.kDefaultSpacing(context),
                onPressed: addGroup,
              ),
            ),
          ],
        );
      }

      // ---------- NORMAL ARRAYS ----------
      String baseName = field['name'].toString().replaceAll('[]', '');
      var entries =
          formData.entries
              .where(
                (e) =>
                    e.key.startsWith("$baseName[") &&
                    e.value.toString().isNotEmpty,
              )
              .toList()
            ..sort((a, b) {
              int aIndex = int.parse(
                a.key.replaceAll("$baseName[", "").replaceAll("]", ""),
              );
              int bIndex = int.parse(
                b.key.replaceAll("$baseName[", "").replaceAll("]", ""),
              );
              return aIndex.compareTo(bIndex);
            });

      return Column(
        children: [
          ...generateInputGroups(
            entries.map((e) {
              int index = int.parse(
                e.key.replaceAll("$baseName[", "").replaceAll("]", ""),
              );
              return Row(
                children: [
                  Expanded(
                    child: generateField({
                      ...field,
                      'label': "${field['label']} ${index + 1}",
                      'name': "$baseName[$index]",
                      'value': e.value,
                    }),
                  ),
                  SizedBox(width: AppSpacing.kDefaultSpacing(context) * 0.5),
                  IconButton.outlined(
                    onPressed: () {
                      // Delete and shift down
                      int k = index;
                      while (formData.containsKey("$baseName[${k + 1}]")) {
                        formData["$baseName[$k]"] =
                            formData["$baseName[${k + 1}]"];
                        k++;
                      }
                      formData.remove("$baseName[$k]");
                      setState(() {});
                    },
                    icon: IconMapper.icon(
                      'delete',
                      iconPack: iconPack,
                      color: Colors.red,
                      size: AppSpacing.kDefaultSpacing(context) * 2,
                    ),
                  ),
                ],
              );
            }).toList(),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.kDefaultSpacing(context) * 0.5,
              vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
          ),
          if (entries.isNotEmpty)
            SizedBox(height: AppSpacing.kDefaultSpacing(context)),
          AppButton(
            title: "Add ${field['label']}",
            width: getScreenSize(context, type: "width"),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.kDefaultSpacing(context) * 2,
              vertical: AppSpacing.kDefaultSpacing(context) * 0.8,
            ),
            icon: IconMapper.icon('plus-circle', iconPack: iconPack),
            fontSize: AppSpacing.kDefaultSpacing(context),
            onPressed: () {
              int next = entries.isEmpty
                  ? 0
                  : entries
                            .map(
                              (e) => int.parse(
                                e.key
                                    .replaceAll("$baseName[", "")
                                    .replaceAll("]", ""),
                              ),
                            )
                            .reduce((a, b) => a > b ? a : b) +
                        1;
              formData["$baseName[$next]"] = "";
              setState(() {});
            },
          ),
        ],
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(
          top: field['padding'] != null
              ? double.tryParse(field['padding']['top'].toString()) ?? 0
              : AppSpacing.kDefaultSpacing(context) * 0.5,
          bottom: field['padding'] != null
              ? double.tryParse(field['padding']['bottom'].toString()) ?? 0
              : AppSpacing.kDefaultSpacing(context) * 0.5,
          left: field['padding'] != null
              ? double.tryParse(field['padding']['left'].toString()) ?? 0
              : 0,
          right: field['padding'] != null
              ? double.tryParse(field['padding']['right'].toString()) ?? 0
              : 0,
        ),
        child: generateField(field),
      );
    }
  }

  // Helper function to check if form has file fields
  bool hasFileFields() {
    bool hasFiles = false;

    void checkForFileFields(List<dynamic> fields) {
      for (final field in fields) {
        if (field is Map<String, dynamic>) {
          final String? type = field['type'];

          if (type == 'file') {
            hasFiles = true;
            return;
          }

          // Handle nested groups
          if (type == 'group' && field['items'] is List) {
            checkForFileFields(field['items'] as List<dynamic>);
          }
        }
      }
    }

    if (formSchema != null && formSchema!['fields'] is List) {
      checkForFileFields(formSchema!['fields'] as List<dynamic>);
    }

    return hasFiles;
  }

  Map<String, dynamic> prepareFormData(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};

    // Build field type map from formSchema
    final Map<String, String> fieldTypeMap = {};

    void extractFieldTypes(List<dynamic> fields, {String prefix = ''}) {
      for (final field in fields) {
        if (field is Map<String, dynamic>) {
          final String? type = field['type'];
          final String? name = field['name'];

          if (type != null && name != null) {
            final fullName = prefix.isEmpty ? name : '$prefix.$name';
            fieldTypeMap[fullName] = type;

            // Remove array markers for comparison
            final baseName = fullName.replaceAll(RegExp(r'\[\d*\]$'), '');
            if (baseName != fullName) {
              fieldTypeMap[baseName] = type;
            }
          }

          // Handle nested groups
          if (type == 'group' && field['items'] is List) {
            extractFieldTypes(field['items'] as List<dynamic>, prefix: prefix);
          }
        }
      }
    }

    if (formSchema != null && formSchema!['fields'] is List) {
      extractFieldTypes(formSchema!['fields'] as List<dynamic>);
    }

    data.forEach((key, value) {
      if (images[key] != null) {
        // Skip image fields from normal data
        return;
      }

      // ✅ Convert only booleans → 1/0 (int)
      dynamic processedValue = value;
      if (value is bool) {
        processedValue = value ? 1 : 0;
      }

      // 🔥 GLOBAL FIX: Convert empty strings to null for specific field types
      // Only text/textarea/editor fields should keep empty strings
      // All other fields (select, date, time, file, number) should send null
      if (processedValue is String && processedValue.isEmpty) {
        final fieldType = fieldTypeMap[key];

        // These field types should send null when empty
        const nullableTypes = [
          'select',
          'date',
          'datetime',
          'datepicker',
          'daterangepicker',
          'time',
          'timepicker',
          'file',
          'number',
          'datagenerator',
        ];

        if (fieldType != null && nullableTypes.contains(fieldType)) {
          processedValue = null;
        }
        // text, textarea, editor keep empty strings
      }

      final arrayMatch = RegExp(r"^([^\[]+)\[(\d+)\]$").firstMatch(key);
      if (arrayMatch != null) {
        final baseKey = arrayMatch.group(1)!;
        if (!result.containsKey(baseKey)) {
          result[baseKey] = [];
        }
        if (processedValue != null &&
            processedValue.toString().trim().isNotEmpty) {
          result[baseKey].add(processedValue);
        }
      } else {
        // Handle arrays/lists (e.g., tags) - keep as array
        if (processedValue is List) {
          if (processedValue.isNotEmpty) {
            result[key] = processedValue;
          }
        } else {
          // 🔥 IMPORTANT: Include null values (they're intentional for optional fields)
          // Only skip if it's an empty string that wasn't converted to null
          final shouldInclude =
              processedValue != null ||
              (processedValue == null && fieldTypeMap.containsKey(key));

          if (shouldInclude) {
            result[key] = processedValue;
          }
        }
      }
    });

    return result;
  }

  Future<http.Response> uploadFiles({
    required Uri url,
    required Map<String, String> data,
    required Map<String, List<String>> fileData,
    // key: form field name, value: list of file paths
    String? token,
  }) async {
    // For Laravel, always use POST for file uploads
    // If method is PUT/PATCH, we'll add _method field
    final originalMethod = formSchema?['method'] ?? "POST";
    var request = http.MultipartRequest("POST", url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add Accept header for JSON responses
    request.headers['Accept'] = 'application/json';

    // Add regular fields
    request.fields.addAll(data);

    // If original method was PUT or PATCH, add _method field for Laravel
    if (originalMethod.toUpperCase() == 'PUT' ||
        originalMethod.toUpperCase() == 'PATCH') {
      request.fields['_method'] = originalMethod.toUpperCase();
    }

    // Add files for each key
    for (var entry in fileData.entries) {
      final key = entry.key; // e.g. "images[]" or "profile_pic"
      final paths = entry.value;

      for (var path in paths) {
        var file = File(path);
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();

        var multipartFile = http.MultipartFile(
          key,
          stream,
          length,
          filename: path.split('/').last,
        );

        request.files.add(multipartFile);
      }
    }

    // Send request
    var streamedResponse = await request.send();
    var responseBody = await streamedResponse.stream.bytesToString();
    return http.Response(responseBody, streamedResponse.statusCode);
  }

  /// Submit dynamically to API from schema
  Future<void> handleSubmit({String? submitType}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      serverUrl = prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    });
    String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
    String token = prefs.getString(AppKeys.loginKey) ?? "";

    await Loading.start(context);

    // Determine submit parameters based on submitType
    String? currentStrategy = formSchema?['submit_strategy'];
    String? submitUrlStr = formSchema?['submit_url'];
    String method = formSchema?['method'] ?? 'POST';

    // Override with draft configuration if available
    if (submitType == 'draft' && formSchema?['draft'] != null) {
      final draftConfig = formSchema!['draft'];
      if (draftConfig['submit_strategy'] != null) {
        currentStrategy = draftConfig['submit_strategy'];
      }
      if (draftConfig['submit_url'] != null) {
        submitUrlStr = draftConfig['submit_url'];
      }
      if (draftConfig['method'] != null) {
        method = draftConfig['method'];
      }
    }

    if ((currentStrategy == null && submitUrlStr != null) ||
        currentStrategy != 'params') {
      final url = Uri.parse("$serverUrl$submitUrlStr?token=$spToken");

      // collect values from controllers and editors
      for (final entry in controllers.entries) {
        // Check if this is a date/time field and use the actual selected value
        if (selectedDates.containsKey(entry.key)) {
          // Send null if no date selected, otherwise send ISO format
          formData[entry.key] = selectedDates[entry.key]?.toIso8601String();
        } else if (selectedTimes.containsKey(entry.key)) {
          // Send the formatted time or null
          formData[entry.key] = selectedTimes[entry.key];
        } else if (selectedDateRanges.containsKey(entry.key) &&
            selectedDateRanges[entry.key] != null) {
          // For date ranges, send as formatted string
          final range = selectedDateRanges[entry.key]!;
          formData[entry.key] =
              "${range['start']!.toIso8601String()} - ${range['end']!.toIso8601String()}";
        } else if (entry.value.text == "Select a Date" ||
            entry.value.text == "Select a Time" ||
            entry.value.text == "Select Date Range" ||
            entry.value.text == "No file selected..." ||
            entry.value.text.startsWith("No file selected")) {
          // If placeholder text is still there, send null (don't send placeholder text)
          formData[entry.key] = null;
        } else {
          formData[entry.key] = entry.value.text;
        }
      }
      final data = prepareFormData(formData);
      http.Response response;

      String? requestId;
      final startTime = DateTime.now();

      // Check if form has file fields (determines if we use multipart)
      final bool isMultipartForm = hasFileFields();

      try {
        if (isMultipartForm) {
          // Filter out null values AND empty strings for picker-based fields
          // Build field type map for filtering
          final Map<String, String> fieldTypeMap = {};
          void extractFieldTypes(List<dynamic> fields) {
            for (final field in fields) {
              if (field is Map<String, dynamic>) {
                final String? type = field['type'];
                final String? name = field['name'];
                if (type != null && name != null) {
                  final baseName = name.replaceAll(RegExp(r'\[\d*\]$'), '');
                  fieldTypeMap[baseName] = type;
                  fieldTypeMap[name] = type;
                }
                if (type == 'group' && field['items'] is List) {
                  extractFieldTypes(field['items'] as List<dynamic>);
                }
              }
            }
          }

          if (formSchema != null && formSchema!['fields'] is List) {
            extractFieldTypes(formSchema!['fields'] as List<dynamic>);
          }

          // Picker-based field types that should be removed if null or empty
          const pickerTypes = [
            'select',
            'datepicker',
            'daterangepicker',
            'timepicker',
            'file',
          ];

          // Common placeholder texts to exclude
          const placeholderTexts = [
            'Select a Date',
            'Select a Time',
            'Select Date Range',
            'No file selected...',
            'No file selected',
          ];

          final filteredData = Map.fromEntries(
            data.entries.where((entry) {
              final value = entry.value;
              final fieldType = fieldTypeMap[entry.key];

              // Remove if null
              if (value == null) return false;

              // For picker-based fields, also remove if empty string or placeholder text
              if (fieldType != null && pickerTypes.contains(fieldType)) {
                if (value is String) {
                  if (value.isEmpty) return false;
                  // Check if it's a placeholder text
                  if (placeholderTexts.any(
                    (placeholder) => value.startsWith(placeholder),
                  )) {
                    return false;
                  }
                }
              }

              return true;
            }),
          );

          // Prepare multipart payload for logging (showing what will be sent)
          final multipartPayload = <String, dynamic>{};
          // Only include non-null values
          for (var entry in filteredData.entries) {
            if (entry.value is List || entry.value is Map) {
              multipartPayload[entry.key] = jsonEncode(entry.value);
            } else {
              multipartPayload[entry.key] = entry.value.toString();
            }
          }
          // Add file info
          for (var entry in images.entries) {
            multipartPayload[entry.key] = entry.value.length == 1
                ? '[File: ${entry.value.first.split('/').last}]'
                : '[Files: ${entry.value.map((p) => p.split('/').last).join(", ")}]';
          }

          // Log file upload request
          if (mounted) {
            requestId = context.read<DebugProvider>().logRequest(
              method: method.toUpperCase(),
              url: url.toString(),
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "multipart/form-data",
              },
              requestBody: jsonEncode(multipartPayload),
            );
          }

          response = await uploadFiles(
            url: url,
            data: filteredData.map((key, value) {
              if (value is List || value is Map) {
                return MapEntry(key, jsonEncode(value));
              }
              return MapEntry(key, value.toString());
            }),
            fileData: images,
            token: token,
          );

          // Log file upload response
          if (mounted && requestId != null) {
            context.read<DebugProvider>().logResponse(
              id: requestId,
              statusCode: response.statusCode,
              responseBody: response.body,
              duration: DateTime.now().difference(startTime),
            );
          }
        } else {
          if (method.toUpperCase() == 'POST') {
            // Log POST request
            if (mounted) {
              requestId = context.read<DebugProvider>().logRequest(
                method: 'POST',
                url: url.toString(),
                headers: {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "Authorization":
                      "Bearer ${context.read<CommonDataProvider>().token}",
                },
                requestBody: jsonEncode(data),
              );
            }

            response = await http.post(
              url,
              headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization":
                    "Bearer ${context.read<CommonDataProvider>().token}",
              },
              body: jsonEncode(data),
            );

            // Log POST response
            if (mounted && requestId != null) {
              context.read<DebugProvider>().logResponse(
                id: requestId,
                statusCode: response.statusCode,
                responseBody: response.body,
                duration: DateTime.now().difference(startTime),
              );
            }
          } else if (method.toUpperCase() == 'PUT') {
            // Log PUT request
            if (mounted) {
              requestId = context.read<DebugProvider>().logRequest(
                method: 'PUT',
                url: url.toString(),
                headers: {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "Authorization": "Bearer $token",
                },
                requestBody: jsonEncode(data),
              );
            }

            response = await http.put(
              url,
              headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(data),
            );

            // Log PUT response
            if (mounted && requestId != null) {
              context.read<DebugProvider>().logResponse(
                id: requestId,
                statusCode: response.statusCode,
                responseBody: response.body,
                duration: DateTime.now().difference(startTime),
              );
            }
          } else {
            throw Exception("Unsupported method $method");
          }
        }

        final responseJson = jsonDecode(response.body);
        message = Message.fromJson(responseJson);

        if (message != null) {
          if (message!.invalidToken) {
            // Token is invalid, force logout
            prefs.remove(AppKeys.loginKey);
            await context.read<CommonDataProvider>().logout();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => WelcomeScreen()),
            );
          } else if (message!.invalidLicenseToken) {
            prefs.clear();
            await context.read<CommonDataProvider>().clearData();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => WelcomeScreen()),
            );
          }
        }

        setState(() {});

        await Loading.stop(context);

        if (message!.success) {
          if (mounted) {
            showSnackBar(message!.message, context, type: "success");
          }

          if (((message?.invoiceDataUrl != null &&
                      message!.invoiceDataUrl!.isNotEmpty) ||
                  (message?.invoiceUrl != null &&
                      message!.invoiceUrl!.isNotEmpty) ||
                  message?.invoiceData != null) &&
              mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrintSelectionScreen(
                  invoiceDataUrl: message?.invoiceDataUrl,
                  invoiceUrl: message?.invoiceUrl,
                  invoiceData: message?.invoiceData,
                ),
              ),
            );
          }

          if (message?.navigateUrl != null &&
              message!.navigateUrl!.isNotEmpty &&
              mounted) {
            await context.read<CommonDataProvider>().getData();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => getNavScreen(
                  context,
                  NavLink(
                    title: "",
                    group: false,
                    apiUrl: message!.navigateUrl,
                    type: message?.navigateType ?? "datatable",
                    params: {
                      ...widget.params ?? {},
                      ...message!.navigateParams ?? {},
                    },
                  ),
                ),
              ),
            );
          } else if (message?.action != null &&
              message!.action!.isNotEmpty &&
              mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => getNavScreen(
                  context,
                  NavLink(
                    title: "",
                    group: false,
                    action: message!.action,
                    type: "action",
                    params: {
                      ...widget.params ?? {},
                      ...message!.navigateParams ?? {},
                    },
                  ),
                ),
              ),
            );
          } else if (widget.redirectScreen != null && mounted) {
            await context.read<CommonDataProvider>().getData();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => widget.redirectScreen!),
            );
          } else {
            await context.read<CommonDataProvider>().getData();
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            showSnackBar(message!.message, context, type: "error");
          }
          await context.read<CommonDataProvider>().getData();
        }
      } on SocketException catch (_) {
        await Loading.stop(context);

        // Save to drafts
        final submission = OfflineSubmission(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: formSchema?['submit_url'] ?? widget.apiUrl ?? "",
          method: formSchema?['method'] ?? 'POST',
          data: data,
          files: images,
          timestamp: DateTime.now(),
          title: formSchema?['title'] ?? widget.title ?? 'Untitled Draft',
          formSchema: formSchema,
        );

        if (mounted) {
          context.read<OfflineSubmissionProvider>().addSubmission(submission);
          showSnackBar(
            "You are currently in Offline Mode. Saved to Drafts.",
            context,
            type: "success",
          );

          if (formSchema?['offline_receipt'] != null &&
              formSchema!['offline_receipt'] == true) {
            // Format invoice data manually for offline mode
            Map<String, dynamic> offlineInvoiceData = {};

            // Add company details if available in static_data
            if (formSchema?['static_data']?['general_settings'] != null) {
              final settings = formSchema!['static_data']['general_settings'];
              offlineInvoiceData['company'] = {
                'name':
                    settings['company_name'] ??
                    settings['site_title'] ??
                    defaultAppName,
                'vat': settings['vat_registration_number'] ?? '',
                'phone': settings['phone'] ?? '',
                'email': settings['email'] ?? '',
                'address': settings['address'] ?? '',
              };
            }

            // Marge sale data and items from params
            if (widget.params != null) {
              offlineInvoiceData['items'] = widget.params?['cart'];

              // Structure totals if they exist in params
              offlineInvoiceData['totals'] = {
                'grand_total': widget.params?['grand_total'],
                'total_qty':
                    widget.params?['total_qty'] ??
                    widget.params?['total_items'] ??
                    widget.params?['cart'].length,
                'total_item':
                    widget.params?['total_qty'] ??
                    widget.params?['total_items'] ??
                    widget.params?['cart'].length,
                'subtotal':
                    (double.tryParse(
                          widget.params!['grand_total'].toString(),
                        ) ??
                        0) -
                    (double.tryParse(widget.params!['order_tax'].toString()) ??
                        0) -
                    (double.tryParse(
                          widget.params!['order_discount'].toString(),
                        ) ??
                        0),
                'total_tax': widget.params?['order_tax'],
                'total_discount': widget.params?['order_discount'],
                'paid_amount': formData['paying_amount'],
                'change_return': formData['change'],
              };

              // Fill basic sale info
              offlineInvoiceData['sale'] = {
                'reference_no': widget.params?['sale_reference'],
                'date': DateTime.now().toIso8601String(),
                'status': 'Completed',
                'payment_status': 'Paid',
              };
            }

            // Payments
            offlineInvoiceData['payments'] = [
              {
                'date': DateTime.now().toIso8601String(),
                'method': formData['paying_method'] ?? 'Cash',
                'amount': formData['paying_amount'] ?? 0,
                'note': formData['payment_note'] ?? '',
              },
            ];

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PrintSelectionScreen(invoiceData: offlineInvoiceData),
              ),
            );
          }

          if (formSchema?['offline_submit_url'] != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => getNavScreen(
                  context,
                  NavLink(
                    title: "",
                    group: false,
                    apiUrl: formSchema!['offline_submit_url'],
                    type: message?.action == null
                        ? formSchema!['offline_submit_type'] ?? 'datatable'
                        : 'action',
                    action: message?.action,
                    params: {...widget.params ?? {}, ...formData},
                  ),
                ),
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        await Loading.stop(context);
        if (mounted) {
          showSnackBar("Something went wrong: $e", context, type: "error");
        }
      }
    } else if (formSchema?['submit_strategy'] == 'params') {
      // Submit via URL parameters
      String baseUrl = formSchema?['submit_url'] ?? "";

      // collect values from controllers and editors
      for (final entry in controllers.entries) {
        // Check if this is a date/time field and use the actual selected value
        if (selectedDates.containsKey(entry.key)) {
          // Send null if no date selected, otherwise send ISO format
          formData[entry.key] = selectedDates[entry.key]?.toIso8601String();
        } else if (selectedTimes.containsKey(entry.key)) {
          // Send the formatted time or null
          formData[entry.key] = selectedTimes[entry.key];
        } else if (selectedDateRanges.containsKey(entry.key) &&
            selectedDateRanges[entry.key] != null) {
          // For date ranges, send as formatted string
          final range = selectedDateRanges[entry.key]!;
          formData[entry.key] =
              "${range['start']!.toIso8601String()} - ${range['end']!.toIso8601String()}";
        } else if (entry.value.text == "Select a Date" ||
            entry.value.text == "Select a Time" ||
            entry.value.text == "Select Date Range" ||
            entry.value.text == "No file selected..." ||
            entry.value.text.startsWith("No file selected")) {
          // If placeholder text is still there, send null (don't send placeholder text)
          formData[entry.key] = null;
        } else {
          formData[entry.key] = entry.value.text;
        }
      }
      final data = prepareFormData(formData);

      await Loading.stop(context);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => getNavScreen(
            context,
            NavLink(
              title: "",
              group: false,
              apiUrl: baseUrl,
              action: formSchema?['action'],
              type: formSchema?['action'] != null
                  ? 'action'
                  : formSchema?['screen_type'] ?? "datatable",
              params: {...widget.params ?? {}, ...data},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = (formSchema?['fields'] as List<dynamic>? ?? []);
    final fieldsAfterButton =
        (formSchema?['fields_after_button'] as List<dynamic>? ?? []);

    return FormScreen(
      scaffoldKey: _scaffoldKey,
      onRefresh: () async {
        setState(() {
          formSchema = null;
        });
        await fetchForm(repeat: true);
        setState(() {});
      },
      apiUrl: widget.apiUrl,
      title: formSchema?['title'] ?? widget.title ?? "Dynamic Form",
      serverUrl: serverUrl?.replaceAll('/api', '') ?? defaultApiURL,
      showAppBar: formSchema?['show_app_bar'] ?? true,
      debugBar: formSchema?['debug_bar'] == true,
      actions: [DraftButton(filterUrl: formSchema?['submit_url'])],
      buttonTitle: formSchema?['submit_button_text'] ?? "Submit",
      hideButton: formSchema?['hide_submit_button'] == true,
      onSubmit: handleSubmit,
      background: formSchema?['background'],
      centerItems: formSchema?['center_items'] == true,
      padding: EdgeInsets.zero,
      childrenAfterButton: fieldsAfterButton
          .map(
            (f) => AnimatedCrossFade(
              duration: Duration(milliseconds: 500),
              firstChild: buildField(f),
              secondChild: SizedBox.shrink(),
              crossFadeState: generateCrossFadeState(f),
            ),
          )
          .toList(),
      children: fields
          .map(
            (f) => AnimatedCrossFade(
              duration: Duration(milliseconds: 500),
              firstChild: buildField(f),
              secondChild: SizedBox.shrink(),
              crossFadeState: generateCrossFadeState(f),
            ),
          )
          .toList(),
    );
  }
}
