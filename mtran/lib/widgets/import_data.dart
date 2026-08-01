/*
  Author Name: Zarif Sadman
  Company: LionCoders
  Website: https://lion-coders.com/
  File Name: import_data
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/widgets/file_picker.dart';
import 'package:salepro/widgets/form.dart';

class ImportData extends StatelessWidget {
  const ImportData({
    super.key,
    this.prefix,
    this.suffix,
    this.controller,
    this.fileLink,
    this.hintText,
    this.sampleFileName,
    this.downloadTitle,
    this.glass = false,
    this.gradient = false,
  });

  final List<Widget>? prefix;
  final List<Widget>? suffix;
  final TextEditingController? controller;
  final String? fileLink;
  final String? hintText;
  final String? sampleFileName;
  final String? downloadTitle;
  final bool glass;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;
    return Column(
      children: generateInputGroups([
        if (prefix != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.kDefaultSpacing(context) * 0.5,
            ),
            child: Column(
              children: prefix!,
            ),
          ),
        AppFilePicker(
          hintText: hintText ?? "Upload CSV File",
          allowMultiple: false,
          controller: controller,
          glass: glass,
          gradient: gradient,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.kDefaultSpacing(context) * 0.25,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sampleFileName ?? "Sample File",
                style: TextStyle(
                  fontSize: AppSpacing.kDefaultSpacing(context),
                ),
              ),
              SizedBox(
                height: AppSpacing.kDefaultSpacing(context),
              ),
              SizedBox(
                width: double.infinity,
                child: Transform.scale(
                  scale: 0.9,
                  child: AppButton(
                    title: downloadTitle ?? "Download",
                    onPressed: () {},
                    icon: IconMapper.icon('download', iconPack: iconPack),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...?suffix,
      ]),
    );
  }
}
