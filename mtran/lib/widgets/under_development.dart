import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/utils/get_app_logo.dart';
import 'package:salepro/widgets/drawer.dart';

class UnderDevelopmentScreen extends StatelessWidget {
  final Map? params;

  const UnderDevelopmentScreen({super.key, this.params});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const AppDrawer(),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.kDefaultSpacing(context) * 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(
                AppSpacing.kDefaultSpacing(context),
              ),
              child: hasNetworkLogo(context)
                  ? Image.network(
                      getAppLogo(context)!,
                      height: AppSpacing.kDefaultSpacing(context) * 4,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        getAppLogo(context, useNetworkLogo: false)!,
                        height: AppSpacing.kDefaultSpacing(context) * 4,
                      ),
                    )
                  : Image.asset(
                      getAppLogo(context)!,
                      height: AppSpacing.kDefaultSpacing(context) * 4,
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.kDefaultSpacing(context),
              ),
              child: Text(
                params?['title'] ??
                    'Sorry, this page is on under development...',
                style: TextStyle(
                  fontSize: AppSpacing.kDefaultSpacing(context) * 2,
                  fontWeight: FontWeight.w700,
                  fontFamily: GoogleFonts.firaSansCondensed().fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
