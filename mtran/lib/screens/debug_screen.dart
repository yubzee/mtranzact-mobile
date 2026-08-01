import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/debug_provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Console'),
        actions: [
          IconButton(
            icon: IconMapper.icon(
              'delete',
              iconPack: context
                  .watch<CommonDataProvider>()
                  .currentThemeSetting!
                  .iconPack,
            ),
            tooltip: 'Clear all logs',
            onPressed: () {
              context.read<DebugProvider>().clearLogs();
              showSnackBar('All logs cleared', context, type: "success");
            },
          ),
        ],
      ),
      body: Consumer<DebugProvider>(
        builder: (context, debugProvider, child) {
          final logs = debugProvider.apiLogs;

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconMapper.icon(
                    'network',
                    iconPack: context
                        .watch<CommonDataProvider>()
                        .currentThemeSetting!
                        .iconPack,
                    size: 64,
                    color: AppColors.slateColor[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No network requests yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slateColor[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogTile(context, log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogTile(BuildContext context, ApiLog log) {
    Color statusColor;
    String statusIconKey;

    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    switch (log.status) {
      case 'Success':
        statusColor = const Color(0xFF4CAF50);
        statusIconKey = 'status-success';
        break;
      case 'Failed':
        statusColor = const Color(0xFFEF5350);
        statusIconKey = 'status-failed';
        break;
      case 'Error':
        statusColor = const Color(0xFFFF9800);
        statusIconKey = 'status-warning';
        break;
      default:
        statusColor = AppColors.slateColor[500]!;
        statusIconKey = 'status-pending';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: getThemeBorderRadiusCircular(context, intensity: 'low'),
        border: Border.all(
          color: AppColors.slateColor[500]!.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconMapper.icon(
            statusIconKey,
            iconPack: iconPack,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getMethodColor(log.method),
                borderRadius: getThemeBorderRadiusCircular(
                  context,
                  intensity: 'low',
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getMethodColor(log.method).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                log.method,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (log.statusCode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: getThemeBorderRadiusCircular(
                    context,
                    intensity: 'low',
                  ),
                ),
                child: Text(
                  '${log.statusCode}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.displayUrl,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              IconMapper.icon(
                'time',
                iconPack: iconPack,
                size: 12,
                color: AppColors.slateColor[600],
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimestamp(log.timestamp),
                style:
                    TextStyle(fontSize: 11, color: AppColors.slateColor[600]),
              ),
              if (log.duration != null) ...[
                const SizedBox(width: 12),
                IconMapper.icon(
                  'speed',
                  iconPack: iconPack,
                  size: 12,
                  color: AppColors.slateColor[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${log.duration!.inMilliseconds}ms',
                  style: TextStyle(
                    fontSize: 11,
                    color: log.duration!.inMilliseconds < 500
                        ? const Color(0xFF4CAF50)
                        : log.duration!.inMilliseconds < 1000
                            ? const Color(0xFFFF9800)
                            : const Color(0xFFEF5350),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        onTap: () => _showLogDetails(context, log),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF2196F3); // Bright blue
      case 'POST':
        return const Color(0xFF4CAF50); // Bright green
      case 'PUT':
        return const Color(0xFFFF9800); // Bright orange
      case 'DELETE':
        return const Color(0xFFEF5350); // Bright red
      case 'PATCH':
        return const Color(0xFF9C27B0); // Bright purple
      default:
        return const Color(0xFF607D8B); // Blue grey
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return DateFormat('HH:mm:ss').format(timestamp);
    }
  }

  void _showLogDetails(BuildContext context, ApiLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogDetailsSheet(log: log),
    );
  }
}

class _LogDetailsSheet extends StatefulWidget {
  final ApiLog log;

  const _LogDetailsSheet({required this.log});

  @override
  State<_LogDetailsSheet> createState() => _LogDetailsSheetState();
}

class _LogDetailsSheetState extends State<_LogDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String?
      _copiedButton; // Track which button was clicked: 'headers', 'request', 'response', 'error'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(
              top: getThemeRadius(context, intensity: 'high'),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slateColor[700],
                  borderRadius: getThemeBorderRadiusCircular(
                    context,
                    intensity: 'low',
                  ),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.slateColor[800]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getMethodColor(widget.log.method),
                            borderRadius: getThemeBorderRadiusCircular(
                              context,
                              intensity: 'low',
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getMethodColor(widget.log.method)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.log.method,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (widget.log.statusCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.log.statusCode!),
                              borderRadius: BorderRadius.circular(
                                getThemeBorderRadius(context, intensity: 'low'),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(widget.log.statusCode!)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${widget.log.statusCode}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.slateColor[800],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: IconMapper.icon(
                              'close',
                              iconPack: iconPack,
                              color: AppColors.slateColor[400],
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      widget.log.url,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slateColor[300],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconMapper.icon(
                          'time',
                          iconPack: iconPack,
                          size: 14,
                          color: AppColors.slateColor[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm:ss.SSS')
                              .format(widget.log.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slateColor[500],
                          ),
                        ),
                        if (widget.log.duration != null) ...[
                          const SizedBox(width: 16),
                          IconMapper.icon(
                            'speed',
                            iconPack: iconPack,
                            size: 14,
                            color: AppColors.slateColor[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.log.duration!.inMilliseconds}ms',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.log.duration!.inMilliseconds < 500
                                  ? const Color(0xFF4CAF50)
                                  : widget.log.duration!.inMilliseconds < 1000
                                      ? const Color(0xFFFF9800)
                                      : const Color(0xFFEF5350),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF2196F3),
                  labelColor: const Color(0xFF2196F3),
                  unselectedLabelColor: AppColors.slateColor[500],
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconMapper.icon(
                            'upload',
                            iconPack: iconPack,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Payload',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconMapper.icon(
                            'download',
                            iconPack: iconPack,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Response',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab view
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPayloadTab(scrollController),
                    _buildResponseTab(scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayloadTab(ScrollController scrollController) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headers section
            if (widget.log.headers != null &&
                widget.log.headers!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconMapper.icon(
                        'http',
                        iconPack: iconPack,
                        size: 18,
                        color: AppColors.slateColor[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Headers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateColor[200],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.slateColor[800],
                      borderRadius: getThemeBorderRadiusCircular(
                        context,
                        intensity: 'low',
                      ),
                    ),
                    child: IconButton(
                      icon: IconMapper.icon(
                        _copiedButton == 'headers' ? 'check' : 'copy',
                        iconPack: iconPack,
                        size: 18,
                        color: _copiedButton == 'headers'
                            ? const Color(0xFF4CAF50)
                            : AppColors.slateColor[400],
                      ),
                      onPressed: () => _copyToClipboard(
                        jsonEncode(widget.log.headers),
                        'headers',
                      ),
                      tooltip: 'Copy headers',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius:
                      getThemeBorderRadiusCircular(context, intensity: 'low'),
                ),
                child: SelectableText(
                  _formatJson(widget.log.headers!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF4CAF50),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Request body section
            if (widget.log.requestBody != null &&
                widget.log.requestBody!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconMapper.icon(
                        'data-object',
                        iconPack: iconPack,
                        size: 18,
                        color: AppColors.slateColor[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Request Body',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateColor[200],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.slateColor[800],
                      borderRadius: getThemeBorderRadiusCircular(
                        context,
                        intensity: 'low',
                      ),
                    ),
                    child: IconButton(
                      icon: IconMapper.icon(
                        _copiedButton == 'request' ? 'check' : 'copy',
                        iconPack: iconPack,
                        size: 18,
                        color: _copiedButton == 'request'
                            ? const Color(0xFF4CAF50)
                            : AppColors.slateColor[400],
                      ),
                      onPressed: () => _copyToClipboard(
                        widget.log.requestBody!,
                        'request',
                      ),
                      tooltip: 'Copy request body',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius:
                      getThemeBorderRadiusCircular(context, intensity: 'low'),
                ),
                child: SelectableText(
                  _formatJsonString(widget.log.requestBody!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF2196F3),
                    height: 1.5,
                  ),
                ),
              ),
            ],

            if ((widget.log.headers == null || widget.log.headers!.isEmpty) &&
                (widget.log.requestBody == null ||
                    widget.log.requestBody!.isEmpty))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      IconMapper.icon(
                        'inbox',
                        iconPack: iconPack,
                        size: 48,
                        color: AppColors.slateColor[700],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No payload data',
                        style: TextStyle(
                          color: AppColors.slateColor[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTab(ScrollController scrollController) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error section
            if (widget.log.error != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconMapper.icon(
                        'error-outline',
                        iconPack: iconPack,
                        size: 18,
                        color: const Color(0xFFEF5350),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        getThemeBorderRadius(context, intensity: 'low'),
                      ),
                    ),
                    child: IconButton(
                      icon: IconMapper.icon(
                        _copiedButton == 'error' ? 'check' : 'copy',
                        iconPack: iconPack,
                        size: 18,
                        color: _copiedButton == 'error'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                      ),
                      onPressed: () => _copyToClipboard(
                        widget.log.error!,
                        'error',
                      ),
                      tooltip: 'Copy error',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    getThemeBorderRadius(context, intensity: 'medium'),
                  ),
                  border: Border.all(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: SelectableText(
                  widget.log.error!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFFEF5350),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Response body section
            if (widget.log.responseBody != null &&
                widget.log.responseBody!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconMapper.icon(
                        'code',
                        iconPack: iconPack,
                        size: 18,
                        color: AppColors.slateColor[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Response Body',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateColor[200],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.slateColor[800],
                      borderRadius: BorderRadius.circular(
                        getThemeBorderRadius(context, intensity: 'low'),
                      ),
                    ),
                    child: IconButton(
                      icon: IconMapper.icon(
                        _copiedButton == 'response' ? 'check' : 'copy',
                        iconPack: iconPack,
                        size: 18,
                        color: _copiedButton == 'response'
                            ? const Color(0xFF4CAF50)
                            : AppColors.slateColor[400],
                      ),
                      onPressed: () => _copyToClipboard(
                        widget.log.responseBody!,
                        'response',
                      ),
                      tooltip: 'Copy response',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(
                    getThemeBorderRadius(context, intensity: 'medium'),
                  ),
                ),
                child: SelectableText(
                  _formatJsonString(widget.log.responseBody!),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.slateColor[300],
                    height: 1.5,
                  ),
                ),
              ),
            ],

            if (widget.log.error == null &&
                (widget.log.responseBody == null ||
                    widget.log.responseBody!.isEmpty))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      IconMapper.icon(
                        'inbox',
                        iconPack: iconPack,
                        size: 48,
                        color: AppColors.slateColor[700],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No response data',
                        style: TextStyle(
                          color: AppColors.slateColor[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF2196F3); // Bright blue
      case 'POST':
        return const Color(0xFF4CAF50); // Bright green
      case 'PUT':
        return const Color(0xFFFF9800); // Bright orange
      case 'DELETE':
        return const Color(0xFFEF5350); // Bright red
      case 'PATCH':
        return const Color(0xFF9C27B0); // Bright purple
      default:
        return const Color(0xFF607D8B); // Blue grey
    }
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return const Color(0xFF4CAF50);
    if (statusCode >= 400 && statusCode < 500) return const Color(0xFFFF9800);
    if (statusCode >= 500) return const Color(0xFFEF5350);
    return const Color(0xFF607D8B);
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  String _formatJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return jsonString;
    }
  }

  void _copyToClipboard(String text, String buttonId) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedButton = buttonId;
    });
    // Reset after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _copiedButton = null;
        });
      }
    });
  }
}
