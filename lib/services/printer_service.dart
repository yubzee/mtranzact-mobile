import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:salepro/api/client.dart';
import 'package:salepro/models/invoice_data.dart';

class PrinterService {
  Future<List<BluetoothInfo>> getBondedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  Future<void> connect(BluetoothInfo device) async {
    await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
  }

  Future<void> disconnect() async {
    // print_bluetooth_thermal doesn't expose a method to explicitly disconnect in some versions,
    // but typically we can just manage connection status or assume it stays connected.
    // If needed, we can check documentation updates. But usually connection persists until
    // another connection attempt or app kill.
    // However, some forks/versions might have it. The standard package doesn't list 'disconnect' in basic usage.
    // We will leave this empty or remove if unused.
  }

  Future<void> printInvoice(InvoiceData invoice,
      {bool isConnected = false}) async {
    if (!isConnected) {
      bool connected = await PrintBluetoothThermal.connectionStatus;
      if (!connected) {
        // handle not connected
        return;
      }
    }

    // Config
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      invoice.company?.name ?? defaultAppName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      invoice.company?.address ?? '',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Tel: ${invoice.company?.phone ?? ''}',
      styles: const PosStyles(align: PosAlign.center),
    );
    if (invoice.company?.vat != null && invoice.company!.vat!.isNotEmpty) {
      bytes += generator.text(
        'VAT: ${invoice.company?.vat}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr();

    // Sale Info
    bytes += generator.text('Invoice: ${invoice.sale?.referenceNo ?? ''}');
    bytes += generator.text('Date: ${invoice.sale?.date ?? ''}');
    bytes += generator
        .text('Customer: ${invoice.customer?.name ?? 'Walk-in Customer'}');
    bytes += generator.hr();

    // Items
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(
          text: 'Price',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(
          text: 'Total',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    if (invoice.items != null) {
      for (final item in invoice.items!) {
        bytes += generator.row([
          PosColumn(text: item.name ?? '', width: 6),
          PosColumn(
              text: '${item.qty}',
              width: 2,
              styles: const PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '${item.unitPrice}',
              width: 2,
              styles: const PosStyles(align: PosAlign.right)),
          PosColumn(
              text: '${item.total}',
              width: 2,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr();

    // Totals
    if (invoice.totals != null) {
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 6),
        PosColumn(
            text: '${invoice.totals?.subtotal}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      if (parse(invoice.totals?.totalTax) > 0) {
        bytes += generator.row([
          PosColumn(text: 'Tax', width: 6),
          PosColumn(
              text: '${invoice.totals?.totalTax}',
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      if (parse(invoice.totals?.totalDiscount) > 0) {
        bytes += generator.row([
          PosColumn(text: 'Discount', width: 6),
          PosColumn(
              text: '${invoice.totals?.totalDiscount}',
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.row([
        PosColumn(
            text: 'Grand Total',
            width: 6,
            styles: const PosStyles(bold: true, height: PosTextSize.size2)),
        PosColumn(
            text: '${invoice.totals?.grandTotal}',
            width: 6,
            styles: const PosStyles(
                bold: true, align: PosAlign.right, height: PosTextSize.size2)),
      ]);

      if (invoice.sale?.numberInWords != null) {
        bytes += generator.feed(1);
        bytes += generator.text('In Words: ${invoice.sale!.numberInWords}',
            styles: const PosStyles(align: PosAlign.left));
      }
    }

    bytes += generator.hr();

    // QR Code
    if (invoice.sale?.qrCode != null && invoice.sale!.qrCode!.isNotEmpty) {
      // Decode Base64 QR if provided (ZATCA) or generate regular QR
      // ZATCA QR is base64 encoded TLV, but some printers take raw image or regular QR command.
      // ESC/POS utils qrcode generator takes string.
      // If result is base64 of an image, we should print image.
      // If it is base64 of TLV data, we can try to print it as QR code content.

      // Assuming generic usage: Use the raw content.
      bytes += generator.qrcode(invoice.sale!.qrCode!, size: QRSize.size4);
      bytes += generator.feed(1);
    }

    // Footer
    if (invoice.footer != null) {
      bytes += generator.text(invoice.footer!,
          styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  double parse(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
