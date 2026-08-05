import 'package:flutter/foundation.dart';
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

  @override
  void initState() {
    super.initState();
    _getAppData();
  }

  Future<void> _getAppData() async {
    Future.microtask(() async {
      try {
        debugPrint("");
        debugPrint("======================================");
        debugPrint("🚀 APPLICATION STARTING");
        debugPrint("======================================");

        final SharedPreferences prefs =
            await SharedPreferences.getInstance();

        final String? apiUrl =
            prefs.getString(AppKeys.saleproInstallURL);

        final String? spToken =
            prefs.getString(AppKeys.saleproSetupToken);

        debugPrint("API URL:");
        debugPrint(apiUrl ?? "(NULL)");

        debugPrint("Setup Token:");
        debugPrint(spToken ?? "(NULL)");

        if (!mounted) return;

        if (apiUrl != null && spToken != null) {
          debugPrint("Loading CommonDataProvider...");

          await context.read<CommonDataProvider>().getData();

          debugPrint("CommonDataProvider Loaded.");

          if (!mounted) return;

          if (context.read<CommonDataProvider>().token != null) {
            debugPrint("User already logged in.");
            debugPrint("Opening Dashboard.");

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CustomViewScreen(
                  apiUrl: '/dashboard',
                  title: 'Dashboard',
                ),
              ),
            );
          } else {
            debugPrint("User not logged in.");
            debugPrint("Opening Login Screen.");

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const DynamicFormScreen(
                  title: "Login",
                  apiUrl: "/login/create",
                ),
              ),
            );
          }
        } else {
          debugPrint("No installation found.");
          debugPrint("Opening Setup Screen.");

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const SetupScreen(),
            ),
          );
        }
      } catch (e, stack) {
        debugPrint("");
        debugPrint("======================================");
        debugPrint("🚨 WELCOME SCREEN ERROR");
        debugPrint("======================================");
        debugPrint(e.toString());
        debugPrint(stack.toString());
        debugPrint("======================================");

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              title: const Text("Application Error"),
              content: SingleChildScrollView(
                child: SelectableText(
                  "$e\n\n$stack",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SetupScreen(),
                      ),
                    );
                  },
                  child: const Text("Go to Setup"),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        errorBuilder:
                            (context, error, stackTrace) =>
                                Image.asset(
                          getAppLogo(
                            context,
                            useNetworkLogo: false,
                          )!,
                          height:
                              AppSpacing.kDefaultSpacing(context) *
                                  4,
                        ),
                      )
                    : Image.asset(
                        getAppLogo(
                          context,
                          useNetworkLogo: false,
                        )!,
                        height:
                            AppSpacing.kDefaultSpacing(context) *
                                4,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}