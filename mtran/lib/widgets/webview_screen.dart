import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/widgets/drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({
    super.key,
    required this.url,
    required this.title,
    this.params,
  });

  final String title;
  final String url;
  final Map? params;

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  WebViewController? controller;

  @override
  void initState() {
    super.initState();
    loadWebView();
  }

  Future<void> loadWebView() async {
    final prefs = await SharedPreferences.getInstance();

    context.read<CommonDataProvider>().getData();

    String serverUrl =
        prefs.getString(AppKeys.saleproInstallURL) ?? defaultApiURL;
    String token = prefs.getString(AppKeys.loginKey) ?? "";

    // Remove trailing slash if present
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }

    // Replace '/api' with '' (remove it)
    serverUrl = serverUrl.replaceFirst('/api', '');

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
          Uri.parse(
            '$serverUrl/webview/auth?redirect=${widget.url}',
          ),
          headers: {
            'Authorization': 'Bearer $token',
          });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              widget.title,
            ).animate().slideX(
                  begin: -1.0,
                  end: 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
          ],
        ),
        leading: const AppDrawerIcon(),
      ),
      drawer: AppDrawer(
        activeLink: widget.url,
      ),
      body: controller == null
          ? Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : SafeArea(
              child: WebViewWidget(
                controller: controller!,
              ),
            ),
    );
  }
}
