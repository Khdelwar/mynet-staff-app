import 'package:flutter/widgets.dart';

/// Reads a barcode / QR code (ONU serial, item barcode, part SKU) with the
/// camera. The ERP decides what the code is; the app only reads it.
abstract class CodeScanner {
  /// The code, or null when the user went back or the camera is off.
  Future<String?> scan(BuildContext context);
}

/// Used where no camera is wanted (tests): the code is typed instead.
class NoScanner implements CodeScanner {
  const NoScanner();

  @override
  Future<String?> scan(BuildContext context) async => null;
}
