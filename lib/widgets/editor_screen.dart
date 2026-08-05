/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: editor_screen
*/

import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/utils/get_theme_font.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.initialContent,
    required this.title,
    this.background,
    this.serverUrl,
    this.gradient = false,
    this.glass = false,
  });

  final String title;
  final String initialContent;
  final Map<String, dynamic>? background;
  final String? serverUrl;
  final bool gradient;
  final bool glass;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final QuillController _controller;
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initEditor();
  }

  void _initEditor() {
    Document doc;
    try {
      if (widget.initialContent.isNotEmpty) {
        // Fix: Convert HTML to Delta List and pass directly to Document.fromJson
        // This avoids using the 'Delta' class directly which caused the import error
        final deltaList = HtmlToDelta().convert(widget.initialContent);
        doc = Document.fromJson(deltaList.toJson());
      } else {
        doc = Document();
      }
    } catch (e) {
      debugPrint('Error converting HTML to Delta: $e');
      doc = Document();
    }

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  // --- Background Logic ---
  bool get _isGradient =>
      widget.gradient || widget.background?['gradient'] != null;

  BoxDecoration? _buildBackgroundDecoration() {
    final background = widget.background;
    if (background == null) return null;

    final resolvedServerUrl =
        (widget.serverUrl ?? defaultApiURL).replaceFirst('/api', '');
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

  String _getGoogleFontName(String key) {
    switch (key) {
      case 'josefin':
        return 'Josefin Sans';
      default:
        return key[0].toUpperCase() + key.substring(1).toLowerCase();
    }
  }

  Future<void> _saveAndExit() async {
    try {
      // Fix: Correct way to access Delta in newer versions
      final deltaJson = _controller.document.toDelta().toJson();
      final converter = QuillDeltaToHtmlConverter(
        deltaJson,
        ConverterOptions.forEmail(),
      );
      final html = converter.convert();

      if (mounted) {
        Navigator.pop(context, html);
      }
    } catch (e) {
      debugPrint("Error converting Delta to HTML: $e");
      if (mounted) {
        Navigator.pop(context, "");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = isDark(context);
    final String fontKey = getThemeFontKey(context);
    final String fontName = _getGoogleFontName(fontKey);
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;

    final bodyPadding = widget.background != null
        ? EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          )
        : EdgeInsets.zero;

    final baseTextStyle = TextStyle(
      fontFamily: fontName,
      color: isDarkMode ? Colors.white : Colors.black,
      fontSize: 16,
    );

    return Scaffold(
      extendBodyBehindAppBar: widget.background != null,
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        backgroundColor: widget.background != null ? Colors.transparent : null,
        elevation: widget.background != null ? 0 : null,
        surfaceTintColor: widget.background != null ? Colors.transparent : null,
        actions: [
          IconButton(
            onPressed: _saveAndExit,
            icon: IconMapper.icon('check', iconPack: iconPack),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (widget.background != null)
            Positioned.fill(
              child: Container(
                decoration: _buildBackgroundDecoration(),
              ),
            ),
          Padding(
            padding: bodyPadding,
            child: Column(
              children: [
                // Fix: Use QuillToolbar.simple constructor
                QuillSimpleToolbar(
                  controller: _controller,
                  config: QuillSimpleToolbarConfig(
                    showFontFamily: false,
                    showFontSize: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    toolbarSectionSpacing: 4,
                    toolbarIconAlignment: WrapAlignment.start,
                    multiRowsDisplay: false,
                    // Fix: withOpacity deprecated -> withValues(alpha: ...)
                    color: _isGradient
                        ? Colors.white.withValues(alpha: 0.1)
                        : null,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: QuillEditor.basic(
                      controller: _controller,
                      scrollController: _editorScrollController,
                      config: QuillEditorConfig(
                        placeholder: "Your text here...",
                        autoFocus: true,
                        // Fix: DefaultTextBlockStyle now requires 5 arguments
                        // (style, horizontalSpacing, verticalSpacing, verticalSpacing, decoration)
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            baseTextStyle,
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                          placeHolder: DefaultTextBlockStyle(
                            baseTextStyle.copyWith(color: Colors.grey),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
