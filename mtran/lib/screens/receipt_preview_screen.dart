import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/constants/spacing.dart';
import 'package:salepro/models/invoice_data.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/utils/icon_mapper.dart';
import 'package:salepro/widgets/button.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final InvoiceData invoiceData;

  const ReceiptPreviewScreen({
    super.key,
    required this.invoiceData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt Preview"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.kDefaultSpacing(context)),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Company Info
                  if (invoiceData.company?.name != null)
                    Text(
                      invoiceData.company!.name!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (invoiceData.company?.address != null)
                    Text(
                      invoiceData.company!.address!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (invoiceData.company?.phone != null)
                    Text(
                      "Tel: ${invoiceData.company!.phone!}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (invoiceData.company?.vat != null &&
                      invoiceData.company!.vat!.isNotEmpty)
                    Text(
                      "VAT: ${invoiceData.company!.vat!}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  const Divider(height: 30),

                  // Sale Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Date:"),
                      Text(invoiceData.sale?.date ?? ""),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ref:"),
                      Text(invoiceData.sale?.referenceNo ?? ""),
                    ],
                  ),
                  if (invoiceData.sale?.billBy != null &&
                      invoiceData.sale!.billBy!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Biller:"),
                        Text(invoiceData.sale!.billBy!),
                      ],
                    ),
                  ],
                  if (invoiceData.customer?.name != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Customer:"),
                        Text(invoiceData.customer!.name!),
                      ],
                    ),
                  ],

                  const Divider(height: 30),

                  // Items Header
                  const Row(
                    children: [
                      Expanded(
                          flex: 4,
                          child: Text("Item",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Qty",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Price",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 3,
                          child: Text("Total",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Items List
                  if (invoiceData.items != null)
                    ...invoiceData.items!.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                item.name ?? "",
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.qty?.toStringAsFixed(0) ?? "0",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.unitPrice?.toStringAsFixed(2) ?? "0.00",
                                textAlign: TextAlign.end,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.total?.toStringAsFixed(2) ?? "0.00",
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const Divider(height: 30),

                  // Totals
                  _buildTotalRow("Total Quantity",
                      invoiceData.totals?.totalQty?.toStringAsFixed(0) ?? "0"),
                  _buildTotalRow(
                      "Subtotal",
                      invoiceData.totals?.subtotal?.toStringAsFixed(2) ??
                          "0.00"),
                  if ((invoiceData.totals?.totalTax ?? 0) > 0)
                    _buildTotalRow(
                        "Tax",
                        invoiceData.totals?.totalTax?.toStringAsFixed(2) ??
                            "0.00"),
                  if ((invoiceData.totals?.totalDiscount ?? 0) > 0)
                    _buildTotalRow(
                        "Discount",
                        invoiceData.totals?.totalDiscount?.toStringAsFixed(2) ??
                            "0.00"),

                  const SizedBox(height: 10),
                  const Divider(),
                  _buildTotalRow(
                    "Grand Total",
                    invoiceData.totals?.grandTotal?.toStringAsFixed(2) ??
                        "0.00",
                    isBold: true,
                    fontSize: 16,
                  ),
                  _buildTotalRow(
                    "Paid Amount",
                    invoiceData.totals?.paidAmount?.toStringAsFixed(2) ??
                        "0.00",
                  ),
                  _buildTotalRow(
                    "Change",
                    invoiceData.totals?.changeReturn?.toStringAsFixed(2) ??
                        "0.00",
                  ),

                  // Payments
                  if (invoiceData.payments != null &&
                      invoiceData.payments!.isNotEmpty) ...[
                    const Divider(height: 30),
                    const Text(
                      "Payments",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    ...invoiceData.payments!.map((p) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${p.method} (${p.date?.split(' ').first})"),
                            Text(p.amount?.toStringAsFixed(2) ?? "0.00"),
                          ],
                        )),
                  ],

                  const Divider(height: 30),

                  // Footer
                  if (invoiceData.warehouseName != null)
                    Text(
                      invoiceData.warehouseName!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (invoiceData.footer != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        invoiceData.footer!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    "Thank You For Shopping With Us!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.kDefaultSpacing(context)),
            AppButton(
              title: "Close",
              icon: IconMapper.icon(
                'close-circle',
                iconPack: context
                    .watch<CommonDataProvider>()
                    .currentThemeSetting
                    ?.iconPack,
                color: Colors.white,
              ),
              width: double.infinity,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value,
      {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
