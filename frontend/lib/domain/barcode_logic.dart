import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class BarcodeLogic {
  final bool isFlashOn;

  const BarcodeLogic({required this.isFlashOn});

  Future<String> scanBarcode() async {
    if (kIsWeb) return "1234567890123"; // Mock barcode for web

    try {
      final result = await BarcodeScanner.scan(
        options: ScanOptions(
          restrictFormat: [BarcodeFormat.ean13],
          useCamera: -1, // Default camera
          autoEnableFlash: isFlashOn,
          android: const AndroidOptions(
            aspectTolerance: 0.5,
            useAutoFocus: true,
          ),
        ),
      );
      return result.rawContent;
    } catch (e) {
      return 'Error: $e';
    }
  }

  static void showResultDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}