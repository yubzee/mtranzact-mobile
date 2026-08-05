/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: sortable_table
*/

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/models/message.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/control_loading.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';
import 'package:salepro/widgets/data_table.dart';
import 'package:salepro/widgets/dynamic_form_screen.dart';
import 'package:salepro/widgets/html_widget.dart';
import 'package:salepro/widgets/tabbed_data_table.dart';
import 'package:salepro/widgets/text_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SortableTable extends StatefulWidget {
  const SortableTable({
    super.key,
    required this.rows,
    required this.columns,
    this.tableActions,
    this.enabledColumns,
    this.dataRowHeight,
    this.disabledIndexes,
    this.onTap,
    this.onDelete,
  });

  final List<dynamic> rows;
  final List<dynamic> columns;
  final List<Widget>? Function(int id)? tableActions;
  final List<bool>? enabledColumns;
  final double? dataRowHeight;
  final List<int>? disabledIndexes;
  final void Function(int id)? onTap;
  final Future<void> Function(String apiUrl)? onDelete;

  @override
  State<SortableTable> createState() => _SortableTableState();
}

class _SortableTableState extends State<SortableTable> {
  late List<dynamic> filteredRows;
  List<double> columnWidths = [];

  int? sortColumnIndex;

  bool isAscending = false;

  // Check if columns are in new format (Map) or old format (String)
  bool get _isNewFormat {
    return widget.columns.isNotEmpty &&
        widget.columns.first is Map<String, dynamic>;
  }

  // Get column label from either old or new format
  String _getColumnLabel(dynamic col) {
    if (col is Map<String, dynamic>) {
      return col['label'] ?? '';
    }
    return col.toString();
  }

  // Get column field from new format, or use label as field in old format
  String _getColumnField(dynamic col) {
    if (col is Map<String, dynamic>) {
      return col['field'] ?? col['label'] ?? '';
    }
    return col.toString();
  }

  // Get column type from new format, default to 'text' in old format
  String _getColumnType(dynamic col) {
    if (col is Map<String, dynamic>) {
      return col['type'] ?? 'text';
    }
    return 'text';
  }

  // Get cell data based on format
  dynamic _getCellData(dynamic row, int columnIndex) {
    if (_isNewFormat) {
      // New format: row is a Map, access by field name
      if (row is Map<String, dynamic>) {
        String field = _getColumnField(widget.columns[columnIndex]);
        return row[field];
      }
      return null;
    } else {
      // Old format: row is a List, access by index
      if (row is List && columnIndex < row.length) {
        return row[columnIndex];
      }
      return null;
    }
  }

  // Replace placeholders like {id}, {field_name} with actual row data
  String _replacePlaceholders(String url, dynamic row) {
    if (row is! Map<String, dynamic>) {
      return url;
    }

    String result = url;
    // Match patterns like {id}, {name}, {any_field}
    final regex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
    final matches = regex.allMatches(url);

    for (final match in matches) {
      final placeholder = match.group(0)!; // e.g., "{id}"
      final fieldName = match.group(1)!; // e.g., "id"

      if (row.containsKey(fieldName)) {
        result = result.replaceAll(placeholder, row[fieldName].toString());
      }
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    filteredRows = widget.rows;
  }

  @override
  void didUpdateWidget(covariant SortableTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      setState(() {
        filteredRows = widget.rows;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      dividerThickness: 0.5,
      columnSpacing: AppSpacing.kDefaultSpacing(context),
      dataRowMinHeight: widget.dataRowHeight != null
          ? AppSpacing.kDefaultSpacing(context) * widget.dataRowHeight!
          : AppSpacing.kDefaultSpacing(context) * 4,
      dataRowMaxHeight: widget.dataRowHeight != null
          ? AppSpacing.kDefaultSpacing(context) * widget.dataRowHeight!
          : AppSpacing.kDefaultSpacing(context) * 4,
      sortAscending: isAscending,
      sortColumnIndex: sortColumnIndex,
      columns: widget.tableActions != null
          ? getColumns(
              [...widget.columns, "Manage"],
              tableActions: widget.tableActions,
              enabledColumns: widget.enabledColumns,
            )
          : getColumns(
              widget.columns,
              enabledColumns: widget.enabledColumns,
            ),
      rows: widget.tableActions != null
          ? getRows(
              filteredRows,
              widget.rows,
              tableActions: widget.tableActions,
              enabledColumns: widget.enabledColumns,
              disabledIndexes: widget.disabledIndexes,
              onTap: widget.onTap,
            )
          : getRows(
              filteredRows,
              widget.rows,
              enabledColumns: widget.enabledColumns,
              onTap: widget.onTap,
            ),
    );
  }

  /// Show popup menu with all actions
  void _showActionsMenu(BuildContext context, List children, dynamic row) {
    showMenu(
      context: context,
      position:
          RelativeRect.fromLTRB(1000, 100, 0, 0), // Will be adjusted by Flutter
      items: children.map<PopupMenuItem>((child) {
        String label = '';

        if (child is Map<String, dynamic>) {
          if (child['type'] == 'button') {
            label = child['label'] ?? 'Button';
          } else if (child['type'] == 'action') {
            String iconName = child['icon'] ?? 'action';
            label = iconName[0].toUpperCase() + iconName.substring(1);
          }
        }

        return PopupMenuItem(
          child: Row(
            children: [
              if (child['icon'] != null) ...[
                IconMapper.icon(
                  child['icon'],
                  iconPack: context
                      .read<CommonDataProvider>()
                      .currentThemeSetting
                      ?.iconPack,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
          onTap: () async {
            // Delay to allow menu to close
            await Future.delayed(const Duration(milliseconds: 100));
            if (child is Map<String, dynamic>) {
              final action = child['action'];
              if (action != null) {
                String apiUrl = action['api_url'] ?? '';

                // Replace placeholders in URL with row data
                if (row != null) {
                  apiUrl = _replacePlaceholders(apiUrl, row);
                }

                if (action['type'] == 'datatable') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DataTableScreen(
                        apiUrl: apiUrl,
                        title: 'View',
                      ),
                    ),
                  );
                } else if (action['type'] == 'tabbeddatatable') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => TabbedDataTableScreen(
                        apiUrl: apiUrl,
                        title: 'View',
                      ),
                    ),
                  );
                } else if (action['type'] == 'form') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DynamicFormScreen(
                        apiUrl: apiUrl,
                        title: label,
                      ),
                    ),
                  );
                } else if (action['type'] == 'custom') {
                  await callCustomApi({'api_url': apiUrl});
                } else if (action['type'] == 'delete') {
                  if (widget.onDelete != null) {
                    await widget.onDelete!(apiUrl);
                  }
                }
              }
            }
          },
        );
      }).toList(),
    );
  }

  List<DataColumn> getColumns(
    List<dynamic> columns, {
    List<Widget>? Function(int id)? tableActions,
    List? enabledColumns,
  }) =>
      columns.map(
        (dynamic column) {
          String columnLabel = _getColumnLabel(column);
          bool isManageColumn = columnLabel.toLowerCase() == "manage";
          int columnIndex = columns.indexOf(column);
          bool isEnabled =
              enabledColumns == null || enabledColumns[columnIndex];

          if (!isManageColumn && isEnabled) {
            return DataColumn(
              label: Text(
                columnLabel,
                style: TextStyle(
                  fontSize: AppSpacing.kDefaultSpacing(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onSort: onSort,
            );
          } else if (isManageColumn) {
            return DataColumn(
              label: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: tableActions != null
                        ? AppSpacing.kDefaultSpacing(context)
                        : 0),
                child: Text(
                  columnLabel,
                  style: TextStyle(
                    fontSize: AppSpacing.kDefaultSpacing(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onSort: onSort,
            );
          } else {
            return DataColumn(
              label: SizedBox(),
            );
          }
        },
      ).toList();

  List<DataRow> getRows(
    List<dynamic> rows,
    List<dynamic> originalRows, {
    List<Widget>? Function(int id)? tableActions,
    List<bool>? enabledColumns,
    List? disabledIndexes,
    void Function(int id)? onTap,
  }) =>
      rows.map((row) {
        // Get the row ID for onTap callback
        final rowId = (row is Map<String, dynamic> && row['id'] != null)
            ? row['id'] as int
            : originalRows.indexWhere(
                (r) => r.toString() == row.toString(),
              );

        return DataRow(
          cells: tableActions != null
              ? [
                  ...getCells(
                    row,
                    enabledColumns,
                    onTap: () {
                      if (onTap != null) {
                        onTap(rowId);
                      }
                    },
                  ),
                  DataCell(
                    disabledIndexes != null &&
                            disabledIndexes.contains(rows.indexOf(row))
                        ? Container()
                        : Row(
                            children: tableActions(
                              originalRows.indexWhere(
                                (r) => r.toString() == row.toString(),
                              ),
                            )!,
                          ),
                  ),
                ]
              : getCells(
                  row,
                  enabledColumns,
                  onTap: () {
                    if (onTap != null) {
                      onTap(rowId);
                    }
                  },
                ),
        );
      }).toList();

  List<DataCell> getCells(
    dynamic row,
    List<bool>? enabledColumns, {
    VoidCallback? onTap,
  }) {
    List<DataCell> cells = [];

    for (int i = 0; i < widget.columns.length; i++) {
      bool isEnabled = enabledColumns == null || enabledColumns[i];

      if (!isEnabled) {
        cells.add(DataCell(SizedBox(), onTap: onTap));
        continue;
      }

      // Check if column type is 'row' (Manage column with action buttons)
      String columnType = _getColumnType(widget.columns[i]);
      if (columnType == 'row') {
        // Get children from column definition, not from row data
        if (widget.columns[i] is Map<String, dynamic>) {
          Map<String, dynamic> columnDef = widget.columns[i];
          if (columnDef['children'] != null) {
            List children = columnDef['children'];

            // If more than 3 actions, show popup menu
            if (children.length > 3) {
              cells.add(DataCell(
                IconButton(
                  icon: IconMapper.icon(
                    'more',
                    iconPack: context
                        .read<CommonDataProvider>()
                        .currentThemeSetting
                        ?.iconPack,
                  ),
                  onPressed: () {
                    _showActionsMenu(context, children, row);
                  },
                ),
              ));
            } else {
              // Show inline action buttons for 3 or fewer actions
              List<Widget> actionWidgets = [];
              for (var child in children) {
                actionWidgets.add(buildCell(child, row));
              }
              cells.add(DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: actionWidgets,
              )));
            }
            continue;
          }
        }
      }

      dynamic data = _getCellData(row, i);

      // Handle different column types
      if (data == null) {
        cells.add(DataCell(const Text("N/A"), onTap: onTap));
        continue;
      }

      // Check if the cell is a map (old format with action buttons)
      if (data is Map<String, dynamic>) {
        cells.add(DataCell(buildCell(data, row), onTap: onTap));
        continue;
      }

      // Handle new format column types
      Widget cellWidget;
      switch (columnType) {
        case 'image':
          cellWidget = _buildImageCell(data);
          break;
        case 'html':
          cellWidget = _buildHtmlCell(data);
          break;
        case 'avatar':
          cellWidget = _buildAvatarCell(data);
          break;
        case 'text':
        default:
          cellWidget = Text('$data');
          break;
      }

      cells.add(DataCell(cellWidget, onTap: onTap));
    }

    return cells;
  }

  Widget _buildImageCell(dynamic imageUrl) {
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return IconMapper.icon(
        'image-not-supported',
        iconPack:
            context.read<CommonDataProvider>().currentThemeSetting?.iconPack,
        size: 40,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        getThemeBorderRadius(context, intensity: 'low'),
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl.toString(),
        height: 40,
        width: 40,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          height: 40,
          width: 40,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        errorWidget: (context, url, error) => IconMapper.icon(
          'broken-image',
          iconPack:
              context.read<CommonDataProvider>().currentThemeSetting?.iconPack,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildHtmlCell(dynamic htmlContent) {
    if (htmlContent == null) {
      return const Text("N/A");
    }
    return HtmlWidget(
      data: htmlContent.toString(),
    );
  }

  Widget _buildAvatarCell(dynamic avatarUrl) {
    if (avatarUrl == null || avatarUrl.toString().isEmpty) {
      return CircleAvatar(
        radius: 20,
        child: IconMapper.icon(
          'person',
          iconPack:
              context.read<CommonDataProvider>().currentThemeSetting?.iconPack,
        ),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundImage: CachedNetworkImageProvider(avatarUrl.toString()),
      onBackgroundImageError: (exception, stackTrace) {
        // Error handling is done in the error widget
      },
      child: CachedNetworkImage(
        imageUrl: avatarUrl.toString(),
        imageBuilder: (context, imageProvider) => Container(),
        errorWidget: (context, url, error) => IconMapper.icon(
          'person',
          iconPack:
              context.read<CommonDataProvider>().currentThemeSetting?.iconPack,
        ),
      ),
    );
  }

  Widget buildCell(Map<String, dynamic> data, [dynamic row]) {
    switch (data['type']) {
      case 'row':
        // New case: row with children actions
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: data['children'].map<Widget>((child) {
            return buildCell(child, row);
          }).toList(),
        );

      case 'action':
        return IconButton(
          icon: IconMapper.icon(
            data['icon'],
            iconPack: context
                .read<CommonDataProvider>()
                .currentThemeSetting
                ?.iconPack,
            size: 20,
            color: data['icon'] == 'delete' ? Colors.red : null,
          ),
          onPressed: () async {
            final action = data['action'];
            String apiUrl = action['api_url'] ?? '';

            // Replace placeholders in URL with row data
            if (row != null) {
              apiUrl = _replacePlaceholders(apiUrl, row);
            }

            if (action['type'] == 'datatable') {
              // Navigate to DataTableScreen for view
              if (apiUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => DataTableScreen(
                      apiUrl: apiUrl,
                      title: 'View',
                    ),
                  ),
                );
              }
            } else if (action['type'] == 'tabbeddatatable') {
              // Navigate to TabbedDataTableScreen for view
              if (apiUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => TabbedDataTableScreen(
                      apiUrl: apiUrl,
                      title: 'View',
                    ),
                  ),
                );
              }
            } else if (action['type'] == 'form') {
              // Navigate to DynamicFormScreen for edit/add
              if (apiUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => DynamicFormScreen(
                      apiUrl: apiUrl,
                      title: 'Edit',
                    ),
                  ),
                );
              }
            } else if (action['type'] == 'custom') {
              // Call your custom function
              if (apiUrl.isNotEmpty) {
                await callCustomApi({'api_url': apiUrl});
              }
            } else if (action['type'] == 'delete') {
              // Call your delete function
              if (apiUrl.isNotEmpty && widget.onDelete != null) {
                await widget.onDelete!(apiUrl);
              }
            }
          },
        );

      case 'button':
        return Material(
          child: InkWell(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.kDefaultSpacing(context),
                vertical: AppSpacing.kDefaultSpacing(context) * 0.5,
              ),
              decoration: BoxDecoration(
                color: useThemeMode(
                  context,
                  light: getThemeColor(context)!.shade100,
                  dark: getThemeColor(context)!.shade700,
                ),
                borderRadius: BorderRadius.circular(
                  getThemeBorderRadius(context, intensity: 'medium'),
                ),
              ),
              child: Text(
                data['label'] ?? 'Button',
                style: TextStyle(
                  color: useThemeMode(
                    context,
                    light: getThemeColor(context)!.shade800,
                    dark: getThemeColor(context)!.shade200,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () async {
              final action = data['action'];
              String apiUrl = action['api_url'] ?? '';

              // Replace placeholders in URL with row data
              if (row != null) {
                apiUrl = _replacePlaceholders(apiUrl, row);
              }

              if (action['type'] == 'datatable') {
                // Navigate to DataTableScreen for view
                if (apiUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DataTableScreen(
                        apiUrl: apiUrl,
                        title: 'View',
                      ),
                    ),
                  );
                }
              } else if (action['type'] == 'form') {
                // Navigate to DynamicFormScreen for edit/add
                if (apiUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DynamicFormScreen(
                        apiUrl: apiUrl,
                        title: 'Edit',
                      ),
                    ),
                  );
                }
              } else if (action['type'] == 'custom') {
                // Call your custom function
                if (apiUrl.isNotEmpty) {
                  await callCustomApi({'api_url': apiUrl});
                }
              } else if (action['type'] == 'delete') {
                // Call your delete function
                if (apiUrl.isNotEmpty && widget.onDelete != null) {
                  await widget.onDelete!(apiUrl);
                }
              }
            },
          ),
        );

      case 'avatar':
        return data['value'] != null
            ? CachedNetworkImage(
                imageUrl: data['value'],
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  foregroundImage: imageProvider,
                ),
                placeholder: (context, url) =>
                    const CircularProgressIndicator.adaptive(),
                errorWidget: (context, url, error) => IconMapper.icon(
                  'error',
                  iconPack: context
                      .read<CommonDataProvider>()
                      .currentThemeSetting
                      ?.iconPack,
                ),
              )
            : IconMapper.icon(
                'error',
                iconPack: context
                    .read<CommonDataProvider>()
                    .currentThemeSetting
                    ?.iconPack,
              );

      case 'image':
        return data['value'] != null
            ? CachedNetworkImage(
                imageUrl: data['value'],
                imageBuilder: (context, imageProvider) => Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.kDefaultSpacing(context) * 0.2,
                  ),
                  child: Container(
                    width: AppSpacing.kDefaultSpacing(context) * 4,
                    height: AppSpacing.kDefaultSpacing(context) * 4,
                    margin: EdgeInsets.all(
                      AppSpacing.kDefaultSpacing(context) * 0.2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        getThemeBorderRadius(context, intensity: 'medium'),
                      ),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: imageProvider,
                      ),
                    ),
                  ),
                ),
                placeholder: (context, url) =>
                    const CircularProgressIndicator.adaptive(),
                errorWidget: (context, url, error) => IconMapper.icon(
                  'error',
                  iconPack: context
                      .read<CommonDataProvider>()
                      .currentThemeSetting
                      ?.iconPack,
                ),
              )
            : IconMapper.icon(
                'error',
                iconPack: context
                    .read<CommonDataProvider>()
                    .currentThemeSetting
                    ?.iconPack,
              );

      case "blank":
        return Container();
      case "text":
        return Text('${data['value']}');
      case "html":
        return HtmlWidget(
          data: data['value'].toString(),
        );
      case "custom":
        return data['child'];
      default:
        return Container();
    }
  }

  void onSort(int columnIndex, bool ascending) {
    filteredRows.sort((row1, row2) => compareString(
        ascending, '${row1[columnIndex]}', '${row2[columnIndex]}'));

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  Future<void> callCustomApi(dynamic action) async {
    if (action['api_url'] != null) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String serverUrl =
          prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
      String spToken = prefs.getString(AppKeys.saleproSetupToken) ?? "";
      String token = prefs.getString(AppKeys.loginKey) ?? "";

      try {
        final response = await http.get(
          Uri.parse("$serverUrl${action['api_url']}?token=$spToken"),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          },
        );
        if (response.statusCode == 200) {
          await Loading.stop(context);
          Message message = Message.fromJson(jsonDecode(response.body));
          if (mounted) {
            showSnackBar(message.message, context, type: "success");
          }
        } else {
          if (mounted) {
            await Loading.stop(context);
            showSnackBar("Something went wrong...", context, type: "error");
          }
        }
      } on SocketException catch (_) {
        if (mounted) {
          await Loading.stop(context);
          showSnackBar("You are currently in offline mode...", context,
              type: "error");
        }
      } catch (e) {
        if (mounted) {
          await Loading.stop(context);
          showSnackBar("Something went wrong...", context, type: "error");
        }
      }
    }
  }
}

class TableActionIcon extends StatelessWidget {
  const TableActionIcon(
      {super.key,
      required this.iconType,
      this.icon,
      this.lightColor,
      this.darkColor,
      this.onTap,
      this.screen});
  final String iconType;
  final dynamic icon;
  final Color? lightColor;
  final Color? darkColor;
  final VoidCallback? onTap;
  final Widget? screen;

  @override
  Widget build(BuildContext context) {
    switch (iconType) {
      case "iconMapper":
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.kDefaultSpacing(context) * 0.25,
          ),
          child: AppTextButton(
            onTap: () {
              if (onTap == null && screen != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => screen!,
                  ),
                );
              } else if (onTap != null && screen == null) {
                onTap!();
              }
            },
            child: IconMapper.icon(
              icon,
              iconPack: context
                  .read<CommonDataProvider>()
                  .currentThemeSetting
                  ?.iconPack,
              color: useThemeMode(
                context,
                dark: darkColor ?? getThemeColor(context)!.shade300,
                light: lightColor ?? getThemeColor(context)!.shade600,
              ),
              size: AppSpacing.kDefaultSpacing(context) * 2,
            ),
          ),
        );
      case "heroIcon":
        // Backwards-compat: treat `icon` as an IconMapper key.
        return TableActionIcon(
          iconType: 'iconMapper',
          icon: icon,
          lightColor: lightColor,
          darkColor: darkColor,
          onTap: onTap,
          screen: screen,
        );
      case "fontAwesomeIcon":
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.kDefaultSpacing(context) * 0.25,
          ),
          child: AppTextButton(
            onTap: () {
              if (onTap == null && screen != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => screen!,
                  ),
                );
              } else if (onTap != null && screen == null) {
                onTap!();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(
                AppSpacing.kDefaultSpacing(context) * 0.2,
              ),
              child: Icon(
                icon,
                color: useThemeMode(
                  context,
                  dark: darkColor ?? getThemeColor(context)!.shade300,
                  light: lightColor ?? getThemeColor(context)!.shade600,
                ),
                size: AppSpacing.kDefaultSpacing(context) * 1.7,
              ),
            ),
          ),
        );
      default:
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.kDefaultSpacing(context) * 0.25,
          ),
          child: AppTextButton(
            onTap: () {
              if (onTap == null && screen != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => screen!,
                  ),
                );
              } else if (onTap != null && screen == null) {
                onTap!();
              }
            },
            child: Icon(
              icon,
              color: useThemeMode(
                context,
                light: lightColor ?? getThemeColor(context)!.shade600,
                dark: darkColor ?? getThemeColor(context)!.shade300,
              ),
              size: AppSpacing.kDefaultSpacing(context) * 2,
            ),
          ),
        );
    }
  }
}
