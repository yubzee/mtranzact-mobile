/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: app_loader
*/

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/colors.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_screensize.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/utils/is_dark.dart';

class AppLoader extends StatelessWidget {
  const AppLoader(
      {super.key,
      required this.child,
      this.isSyncing = false,
      this.isForm = true,
      this.physics,
      this.includeScrollView = true});

  final Widget child;
  final bool isSyncing;
  final bool isForm;
  final ScrollPhysics? physics;
  final bool includeScrollView;

  @override
  Widget build(BuildContext context) {
    if (isForm) {
      return Stack(
        children: [
          child,
          if (context.watch<CommonDataProvider>().isLoading)
            Container(
              decoration: BoxDecoration(
                color: AppColors.slateSwatch.withValues(
                  alpha: 0.5,
                ),
              ),
              width: getScreenSize(context, type: 'width'),
              height: getScreenSize(context),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: AppSpacing.kDefaultSpacing(context) * 9,
                            height: AppSpacing.kDefaultSpacing(context) * 9,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  getThemeColor(context)?.shade900.withValues(
                                            alpha: 0.5,
                                          ) ??
                                      AppColors.slateSwatch.withValues(
                                        alpha: 0.5,
                                      ),
                                  getThemeColor(context)?.shade800.withValues(
                                            alpha: 0.7,
                                          ) ??
                                      AppColors.slateSwatch.withValues(
                                        alpha: 0.7,
                                      ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                getThemeBorderRadius(context,
                                    intensity: 'medium'),
                              ),
                            ),
                          ),
                          Lottie.asset(
                            'assets/animations/loading.json',
                            width: AppSpacing.kDefaultSpacing(context) * 16,
                            height: AppSpacing.kDefaultSpacing(context) * 16,
                          ),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      duration: Duration(
                        seconds: 1,
                      ),
                      opacity: isSyncing ? 1 : 0,
                      child: SafeArea(
                        child: Text(
                          "Syncing Data from the Server. Please Wait...",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize:
                                AppSpacing.kDefaultSpacing(context) * 1.05,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.kDefaultSpacing(context) * 2,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else if (includeScrollView) {
      return SingleChildScrollView(
        physics: physics ?? NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            AppBanner(
              title:
                  "Backing Up Data from the Server (${(context.watch<CommonDataProvider>().progressCount / context.watch<CommonDataProvider>().totalCount * 100).toStringAsFixed(0)}%)",
              show: context.watch<CommonDataProvider>().isSyncing,
              right: SizedBox(
                width: AppSpacing.kDefaultSpacing(context),
                height: AppSpacing.kDefaultSpacing(context),
                child: CircularProgressIndicator(
                  color: AppColors.white,
                ),
              ),
            ),
            AppBanner(
              title: "Syncing Data with the Server...",
              show: context.watch<CommonDataProvider>().isLoading,
              right: SizedBox(
                width: AppSpacing.kDefaultSpacing(context),
                height: AppSpacing.kDefaultSpacing(context),
                child: CircularProgressIndicator(
                  color: AppColors.white,
                ),
              ),
            ),
            AppBanner(
              title:
                  "Downloading your Data from the Server.\nPlease wait for few minutes...",
              show: context.watch<CommonDataProvider>().isCaching,
              color: AppColors.orangeSwatch,
              right: SizedBox(
                width: AppSpacing.kDefaultSpacing(context),
                height: AppSpacing.kDefaultSpacing(context),
                child: CircularProgressIndicator(
                  color: AppColors.white,
                ),
              ),
            ),
            AppBanner(
              title: "It seems like you are currently in Offline...",
              color: AppColors.roseSwatch,
              show: context.watch<CommonDataProvider>().noInternet,
              right: SizedBox(
                height: AppSpacing.kDefaultSpacing(context),
                child: IconMapper.icon(
                  'warning',
                  iconPack: context
                      .watch<CommonDataProvider>()
                      .currentThemeSetting
                      ?.iconPack,
                  color: AppColors.white,
                ),
              ),
            ),
            child,
          ],
        ),
      );
    } else {
      return Column(
        children: [
          AppBanner(
            title:
                "Backing Up Data from the Server (${(context.watch<CommonDataProvider>().progressCount / context.watch<CommonDataProvider>().totalCount * 100).toStringAsFixed(0)}%)",
            show: context.watch<CommonDataProvider>().isSyncing,
            right: SizedBox(
              width: AppSpacing.kDefaultSpacing(context),
              height: AppSpacing.kDefaultSpacing(context),
              child: CircularProgressIndicator(
                color: AppColors.white,
              ),
            ),
          ),
          AppBanner(
            title: "Syncing Data with the Server...",
            show: context.watch<CommonDataProvider>().isLoading,
            right: SizedBox(
              width: AppSpacing.kDefaultSpacing(context),
              height: AppSpacing.kDefaultSpacing(context),
              child: CircularProgressIndicator(
                color: AppColors.white,
              ),
            ),
          ),
          AppBanner(
            title:
                "Downloading your Data from the Server.\nPlease wait for few minutes...",
            show: context.watch<CommonDataProvider>().isCaching,
            color: AppColors.orangeSwatch,
            right: SizedBox(
              width: AppSpacing.kDefaultSpacing(context),
              height: AppSpacing.kDefaultSpacing(context),
              child: CircularProgressIndicator(
                color: AppColors.white,
              ),
            ),
          ),
          AppBanner(
            title: "It seems like you are currently in Offline...",
            color: AppColors.roseSwatch,
            show: context.watch<CommonDataProvider>().noInternet,
            right: SizedBox(
              height: AppSpacing.kDefaultSpacing(context),
              child: IconMapper.icon(
                'warning',
                iconPack: context
                    .watch<CommonDataProvider>()
                    .currentThemeSetting
                    ?.iconPack,
                color: AppColors.white,
              ),
            ),
          ),
          child,
        ],
      );
    }
  }
}

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.show,
    required this.title,
    required this.right,
    this.color,
  });

  final bool show;
  final String title;
  final Widget right;
  final MaterialColor? color;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: Duration(
        milliseconds: 500,
      ),
      firstChild: SizedBox(),
      secondChild: Container(
        padding: EdgeInsets.all(
          AppSpacing.kDefaultSpacing(context),
        ),
        decoration: BoxDecoration(
          color: useThemeMode(
            context,
            light: color != null
                ? color?.shade600
                : getThemeColor(context)?.shade600,
            dark: color != null
                ? color?.shade800
                : getThemeColor(context)?.shade900.withValues(
                      alpha: 0.6,
                    ),
          ),
        ),
        width: getScreenSize(
          context,
          type: "width",
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            right,
          ],
        ),
      ),
      crossFadeState:
          show ? CrossFadeState.showSecond : CrossFadeState.showFirst,
    );
  }
}
