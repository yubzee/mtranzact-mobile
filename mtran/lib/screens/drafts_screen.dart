import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/offline_submission_provider.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/widgets/dynamic_form_screen.dart';
import 'package:intl/intl.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraftsScreen extends StatefulWidget {
  final String? filterUrl;

  const DraftsScreen({super.key, this.filterUrl});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  @override
  void initState() {
    super.initState();
    hasInternet();
  }

  Future<void> hasInternet() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await http.get(
        Uri.parse(prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL),
        headers: {
          'Authorization': 'Bearer ${context.read<CommonDataProvider>().token}',
          'Accept': 'application/json'
        },
      );
      prefs.setString(AppKeys.noInternetKey, "false");
      await context.read<CommonDataProvider>().checkInternet();
      await syncSubmission();
    } on SocketException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(AppKeys.noInternetKey, "true");
      await context.read<CommonDataProvider>().checkInternet();
    }
  }

  Future<void> syncSubmission() async {
    if (!context.read<CommonDataProvider>().noInternet) {
      await context.read<OfflineSubmissionProvider>().syncSubmissions(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfflineSubmissionProvider>();

    final submissions = widget.filterUrl != null
        ? provider.submissions.where((s) => s.url == widget.filterUrl).toList()
        : provider.submissions;

    return Scaffold(
      appBar: AppBar(title: const Text("Sync Drafts")),
      body: submissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconMapper.icon(
                    'refresh',
                    iconPack: context
                        .watch<CommonDataProvider>()
                        .currentThemeSetting
                        ?.iconPack,
                    size: 64,
                    color: useThemeMode(
                      context,
                      light: Colors.grey.shade400,
                      dark: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.kDefaultSpacing(context)),
                  Text(
                    "Your app is all synced!",
                    style: TextStyle(
                      fontSize: 18,
                      color: useThemeMode(
                        context,
                        light: Colors.grey.shade600,
                        dark: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
              itemCount: submissions.length,
              separatorBuilder: (ctx, i) =>
                  SizedBox(height: AppSpacing.kDefaultSpacing(context) * 0.5),
              itemBuilder: (ctx, i) {
                final sub = submissions[i];
                return Dismissible(
                  key: Key(sub.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Delete Item?"),
                          content: const Text(
                              "Are you sure you want to delete this item? This action cannot be undone."),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: getThemeBorderRadiusCircular(context),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: IconMapper.icon(
                      'delete',
                      iconPack: context
                          .watch<CommonDataProvider>()
                          .currentThemeSetting!
                          .iconPack,
                      color: Colors.red.shade700,
                    ),
                  ),
                  onDismissed: (direction) {
                    provider.removeSubmission(sub.id);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: useThemeMode(
                        context,
                        light: Colors.white,
                        dark: getThemeColor(context)?.shade900.withValues(
                              alpha: 0.2,
                            ),
                      ),
                      borderRadius: getThemeBorderRadiusCircular(context),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: useThemeMode(
                          context,
                          light: Colors.grey.shade200,
                          dark: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.kDefaultSpacing(context),
                        vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: getThemeColor(context)!.shade50,
                          borderRadius: getThemeBorderRadiusCircular(
                            context,
                            intensity: 'low',
                          ),
                        ),
                        child: IconMapper.icon(
                          'document-text',
                          iconPack: context
                              .watch<CommonDataProvider>()
                              .currentThemeSetting
                              ?.iconPack,
                          color: getThemeColor(context),
                        ),
                      ),
                      title: Text(
                        sub.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('MMM d, y • h:mm a').format(sub.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: useThemeMode(
                              context,
                              light: Colors.grey.shade600,
                              dark: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (provider.isSyncing(sub.id))
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: IconMapper.icon(
                                'delete',
                                iconPack: context
                                    .watch<CommonDataProvider>()
                                    .currentThemeSetting!
                                    .iconPack,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Delete Item?"),
                                      content: const Text(
                                          "Are you sure you want to delete this item?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true) {
                                  provider.removeSubmission(sub.id);
                                }
                              },
                            ),
                          const SizedBox(width: 8),
                          IconMapper.icon(
                            'chevron-right',
                            iconPack: context
                                .watch<CommonDataProvider>()
                                .currentThemeSetting
                                ?.iconPack,
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: sub.method.toLowerCase() == 'delete' &&
                              provider.isSyncing(sub.id)
                          ? null
                          : () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DynamicFormScreen(
                                            apiUrl: sub.url,
                                            initialData: sub.data,
                                            initialFiles: sub.files,
                                            title: sub.title,
                                            jsonString: sub.formSchema != null
                                                ? jsonEncode(sub.formSchema)
                                                : null,
                                          )));
                            },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
