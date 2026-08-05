import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import 'package:salepro/models/invoice_data.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/services/invoice_service.dart';
import 'package:salepro/services/printer_service.dart';
import 'package:salepro/utils/get_theme_border_radius.dart';
import 'package:salepro/utils/get_theme_color.dart';
import 'package:salepro/utils/icon_mapper.dart';

class PrintDialog extends StatefulWidget {
  final String? invoiceDataUrl;
  final Map<String, dynamic>? invoiceData;

  const PrintDialog({
    super.key,
    this.invoiceDataUrl,
    this.invoiceData,
  }) : assert(
          invoiceDataUrl != null || invoiceData != null,
          'Either invoiceDataUrl or invoiceData must be provided',
        );

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  final PrinterService _printerService = PrinterService();
  final InvoiceService _invoiceService = InvoiceService();

  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;
  InvoiceData? _invoiceData;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);

    // Use direct invoice data if provided (for offline mode)
    if (widget.invoiceData != null) {
      try {
        _invoiceData = InvoiceData.fromJson(widget.invoiceData!);
      } catch (e) {
        debugPrint("Error parsing invoice data: $e");
      }
    }
    // Otherwise fetch from URL if available
    else if (widget.invoiceDataUrl != null) {
      try {
        final uri = Uri.parse(widget.invoiceDataUrl!);
        final segments = uri.pathSegments;
        final id = int.tryParse(segments.last);
        if (id != null) {
          _invoiceData = await _invoiceService.fetchInvoiceData(id);
        }
      } catch (e) {
        debugPrint("Error loading invoice: $e");
      }
    }

    // Check Printer
    try {
      bool isConnected = await _printerService.isConnected();
      if (isConnected == true) {
        setState(() => _isConnected = true);
      } else {
        await _scanDevices();
      }
    } catch (e) {
      debugPrint("Bluetooth printer check failed (normal on simulator): $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _scanDevices() async {
    // setState(() => _isScanning = true);
    try {
      List<BluetoothInfo> devices = await _printerService.getBondedDevices();
      setState(() => _devices = devices);
    } catch (e) {
      debugPrint("Error scanning: $e");
    }
    // setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothInfo device) async {
    setState(() => _isLoading = true);
    try {
      await _printerService.connect(device);
      setState(() {
        _isConnected = true;
        _selectedDevice = device;
      });
    } catch (e) {
      debugPrint("Error connecting: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _print() async {
    if (_invoiceData == null) return;

    setState(() => _isLoading = true);
    try {
      await _printerService.printInvoice(_invoiceData!,
          isConnected: _isConnected);
      if (mounted) Navigator.pop(context); // Close dialog on success
    } catch (e) {
      debugPrint("Print Error: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final iconPack =
        context.watch<CommonDataProvider>().currentThemeSetting?.iconPack;
    return AlertDialog(
      title: const Text("Print Invoice"),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            const SizedBox(height: 10),
            if (_invoiceData == null && !_isLoading)
              const Text("Failed to load invoice data.",
                  style: TextStyle(color: Colors.red)),
            if (_invoiceData != null) ...[
              Text("Sale: ${_invoiceData?.sale?.referenceNo ?? ''}"),
              const SizedBox(height: 20),
              if (_isConnected)
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: getThemeBorderRadiusCircular(context)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconMapper.icon(
                          'check-circle',
                          iconPack: iconPack,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            "Connected to ${_selectedDevice?.name ?? 'Printer'}"),
                        IconButton(
                          icon: IconMapper.icon('refresh', iconPack: iconPack),
                          onPressed: () {
                            _scanDevices();
                            setState(() => _isConnected = false);
                          },
                        )
                      ],
                    ))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Select Printer:"),
                    IconButton(
                        icon: IconMapper.icon('refresh', iconPack: iconPack),
                        onPressed: _scanDevices)
                  ],
                ),
                if (_devices.isEmpty)
                  const Text(
                      "No paired devices found. Please pair a printer in Bluetooth settings."),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (ctx, i) {
                        return ListTile(
                          title: Text(_devices[i].name),
                          subtitle: Text(_devices[i].macAdress),
                          onTap: () => _connect(_devices[i]),
                          trailing: IconMapper.icon(
                            'bluetooth-connected',
                            iconPack: iconPack,
                          ),
                        );
                      }),
                )
              ]
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        if (_invoiceData != null && _isConnected)
          TextButton(
            onPressed: _print,
            child: Text(
              "Print",
              style: TextStyle(
                color: getThemeColor(context),
              ),
            ),
          ),
      ],
    );
  }
}
