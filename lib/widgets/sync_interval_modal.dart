import 'package:flutter/material.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_input_design.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/services/background_service.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/constants/spacing.dart';

class SyncIntervalModal extends StatefulWidget {
  final void Function(bool backupNow) onSaved;
  final Map<dynamic, dynamic>? params;

  const SyncIntervalModal({super.key, required this.onSaved, this.params});

  @override
  State<SyncIntervalModal> createState() => _SyncIntervalModalState();
}

class _SyncIntervalModalState extends State<SyncIntervalModal> {
  int _selectedInterval = 1440; // Default 1440 minutes (Daily)

  final List<Map<String, dynamic>> _intervals = [
    {"label": "Daily", "value": 1440},
    {"label": "Weekly", "value": 10080},
    {"label": "Monthly", "value": 43200},
    {"label": "2 Months", "value": 86400},
  ];

  Future<void> _saveInterval() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppKeys.syncIntervalKey, _selectedInterval);

    // Register the task
    Workmanager().registerPeriodicTask(
      "1",
      fetchRoutesTask,
      frequency: Duration(minutes: _selectedInterval),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: useThemeMode(
              context,
              light: AppColors.white,
              dark: AppColors.slateSwatch,
            ),
            title: Text(widget.params?['backupTitle'] ?? "Take Backup Now?"),
            content: Text(widget.params?['backupDescription'] ??
                "Do you want to take an immediate backup of the data now? It will take around a few minutes depending on the data size."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSaved(false);
                },
                child: Text(widget.params?['backupNoText'] ?? "No"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSaved(true);
                },
                child: Text(
                  widget.params?['backupYesText'] ?? "Yes",
                  style: TextStyle(
                    color: getThemeColor(context),
                  ),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final bool outlinedInput = isOutlinedThemeInput(context);

    return Container(
      padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
      decoration: BoxDecoration(
        color: useThemeMode(
          context,
          light: AppColors.white,
          dark: AppColors.slateSwatch,
        ),
        borderRadius: BorderRadius.vertical(
          top: getThemeRadius(context, intensity: 'high'),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.params?['title'] ?? "Set Data Backup Interval",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.params?['description'] ??
                "Choose how often the app should take backup of the data in the background (for offline mode).",
            style: TextStyle(
              color: useThemeMode(
                context,
                light: AppColors.slateSwatch,
                dark: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: _selectedInterval,
            decoration: InputDecoration(
              labelText: widget.params?['labelText'] ?? "Sync Interval",
              filled: !outlinedInput,
              fillColor: !outlinedInput
                  ? useThemeMode(
                      context,
                      light: getThemeColor(context)
                              ?.shade50
                              .withValues(alpha: 0.6) ??
                          Colors.grey.withValues(alpha: 0.08),
                      dark: Colors.white.withValues(alpha: 0.06),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    getThemeBorderRadius(context, intensity: 'low')),
                borderSide: outlinedInput
                    ? BorderSide(
                        color: useThemeMode(
                          context,
                          light: getThemeColor(context)
                                  ?.shade400
                                  .withValues(alpha: 0.5) ??
                              Colors.grey.withValues(alpha: 0.4),
                          dark: getThemeColor(context)
                                  ?.shade200
                                  .withValues(alpha: 0.5) ??
                              Colors.grey.withValues(alpha: 0.4),
                        ),
                        width: 1,
                      )
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    getThemeBorderRadius(context, intensity: 'low')),
                borderSide: outlinedInput
                    ? BorderSide(
                        color: useThemeMode(
                          context,
                          light: getThemeColor(context)
                                  ?.shade400
                                  .withValues(alpha: 0.5) ??
                              Colors.grey.withValues(alpha: 0.4),
                          dark: getThemeColor(context)
                                  ?.shade200
                                  .withValues(alpha: 0.5) ??
                              Colors.grey.withValues(alpha: 0.4),
                        ),
                        width: 1,
                      )
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    getThemeBorderRadius(context, intensity: 'low')),
                borderSide: outlinedInput
                    ? BorderSide(
                        color: useThemeMode(
                          context,
                          light:
                              getThemeColor(context)?.shade600 ?? Colors.blue,
                          dark: getThemeColor(context)?.shade300 ?? Colors.blue,
                        ),
                        width: 2,
                      )
                    : BorderSide.none,
              ),
            ),
            items: _intervals.map((interval) {
              return DropdownMenuItem<int>(
                value: interval['value'],
                child: Text(interval['label']),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedInterval = value;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              title: widget.params?['saveButtonText'] ?? "Save & Continue",
              onPressed: _saveInterval,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
