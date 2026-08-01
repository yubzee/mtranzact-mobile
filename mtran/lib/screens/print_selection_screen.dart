import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/widgets/button.dart';
import 'package:salepro/widgets/print_dialog.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/widgets/webview_screen.dart';
import 'package:salepro/screens/receipt_preview_screen.dart';
import 'package:salepro/models/invoice_data.dart';
import 'package:salepro/utils/show_success_snack_bar.dart';

class PrintSelectionScreen extends StatelessWidget {
  final String? invoiceUrl;
  final String? invoiceDataUrl;
  final Map<String, dynamic>? invoiceData;
  final VoidCallback? onDone;

  const PrintSelectionScreen({
    super.key,
    this.invoiceUrl,
    this.invoiceDataUrl,
    this.invoiceData,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sale Successful"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconMapper.icon(
              'check-circle',
              iconPack: context
                  .watch<CommonDataProvider>()
                  .currentThemeSetting
                  ?.iconPack,
              color: Colors.green,
              size: 80,
            ),
            SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            Text(
              "Sale has been completed successfully!",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.kDefaultSpacing(context) * 2),
            if (invoiceDataUrl != null || invoiceData != null) ...[
              AppButton(
                title: "Print Receipt (Thermal Printer Bluetooth)",
                icon: IconMapper.icon(
                  'printer',
                  iconPack: context
                      .watch<CommonDataProvider>()
                      .currentThemeSetting
                      ?.iconPack,
                  color: Colors.white,
                ),
                bgColor: getThemeColor(context),
                textColor: Colors.white,
                width: double.infinity,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => PrintDialog(
                      invoiceDataUrl: invoiceDataUrl,
                      invoiceData: invoiceData,
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            ],
            if (invoiceData != null) ...[
              AppButton(
                title: "View Receipt",
                icon: IconMapper.icon(
                  'view',
                  iconPack: context
                      .watch<CommonDataProvider>()
                      .currentThemeSetting
                      ?.iconPack,
                  color: Colors.white,
                ),
                bgColor: Colors.orange,
                textColor: Colors.white,
                width: double.infinity,
                onPressed: () {
                  // Try to parse invoice data if it's not already parsed
                  InvoiceData? data;
                  if (invoiceData != null) {
                    data = InvoiceData.fromJson(invoiceData!);
                  }

                  if (data != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptPreviewScreen(
                          invoiceData: data!,
                        ),
                      ),
                    );
                  } else {
                    showSnackBar(
                        "Receipt data not available for preview", context,
                        type: "error");
                  }
                },
              ),
              SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            ],
            if (invoiceUrl != null) ...[
              AppButton(
                title: "View/Print PDF Invoice",
                icon: IconMapper.icon(
                  'file-text',
                  iconPack: context
                      .watch<CommonDataProvider>()
                      .currentThemeSetting
                      ?.iconPack,
                  color: Colors.white,
                ),
                bgColor: Colors.blueAccent,
                textColor: Colors.white,
                width: double.infinity,
                onPressed: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => WebviewScreen(
                        url: invoiceUrl!,
                        title: 'Print Invoice',
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            ],
            SizedBox(height: AppSpacing.kDefaultSpacing(context) * 2),
            AppButton(
              title: "Back to POS",
              icon: IconMapper.icon(
                'arrow-left',
                iconPack: context
                    .watch<CommonDataProvider>()
                    .currentThemeSetting
                    ?.iconPack,
                color: Colors.black87,
              ),
              bgColor: Colors.grey.shade200,
              textColor: Colors.black87,
              width: double.infinity,
              onPressed: () {
                Navigator.of(context).pop();
                if (onDone != null) onDone!();
              },
            ),
          ],
        ),
      ),
    );
  }
}
