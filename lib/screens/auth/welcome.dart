/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: welcome
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/hero_tags.dart';
import 'package:salepro/constants/keys.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/screens/auth/setup_app.dart';
import 'package:salepro/utils/get_app_logo.dart';
import 'package:salepro/utils/is_dark.dart';
import 'package:salepro/widgets/custom_view_screen.dart';
import 'package:salepro/widgets/dynamic_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getAppData();
  }

  Future<void> _getAppData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? apiUrl = prefs.getString(AppKeys.saleproInstallURL);
      final String? spToken = prefs.getString(AppKeys.saleproSetupToken);

      if (!mounted) return;

      if (apiUrl == null || spToken == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => const SetupScreen(),
            ),
          );
        }
        return;
      }

      try {
        await context.read<CommonDataProvider>().getData();
      } catch (e) {
        debugPrint('Failed to fetch data: $e');
        // Continue - we can still try to navigate
      }

      if (!mounted) return;

      final token = context.read<CommonDataProvider>().token;
      if (token != null && token.isNotEmpty) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => CustomViewScreen(
                apiUrl: '/dashboard',
                title: 'Dashboard',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => const DynamicFormScreen(
                title: "Login",
                apiUrl: "/login/create",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('WelcomeScreen error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _retry() {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });
    _getAppData();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Container(
          color: useThemeMode(
            context,
            light: AppColors.white,
            dark: Colors.black,
          ),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: useThemeMode(
                      context,
                      light: Colors.black87,
                      dark: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: useThemeMode(
                      context,
                      light: Colors.grey.shade700,
                      dark: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        color: useThemeMode(
          context,
          light: AppColors.white,
          dark: Colors.black,
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: AppHeroTags.appLogo,
                child: hasNetworkLogo(context)
                    ? Image.network(
                        getAppLogo(context)!,
                        height: AppSpacing.kDefaultSpacing(context) * 4,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          getAppLogo(context, useNetworkLogo: false)!,
                          height: AppSpacing.kDefaultSpacing(context) * 4,
                        ),
                      )
                    : Image.asset(
                        getAppLogo(context, useNetworkLogo: false)!,
                        height: AppSpacing.kDefaultSpacing(context) * 4,
                      ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Loading...',
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
      ),
    );
  }
}