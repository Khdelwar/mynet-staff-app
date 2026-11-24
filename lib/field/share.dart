import 'dart:typed_data';

/// Hands a picture (the payment receipt) to the phone's share sheet
/// (WhatsApp, Messenger…). No printer (owner's decision).
abstract class ImageSharer {
  Future<void> sharePng(Uint8List png, {required String name, String? text});

  /// Any file the ERP sent (the payslip PDF), e.g. to save or send it.
  Future<void> shareFile(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  });
}

class NoSharer implements ImageSharer {
  const NoSharer();

  @override
  Future<void> sharePng(
    Uint8List png, {
    required String name,
    String? text,
  }) async {}

  @override
  Future<void> shareFile(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {}
}
