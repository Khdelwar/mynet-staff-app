import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../field/drafts.dart';
import '../field/location.dart';
import '../field/photos.dart';
import '../field/scanner.dart';
import '../field/share.dart';
import '../l10n/app_localizations.dart';

final locationReaderProvider = Provider<LocationReader>(
  (ref) => const DeviceLocation(),
);

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => const DevicePhotos(),
);

final codeScannerProvider = Provider<CodeScanner>(
  (ref) => const CameraScanner(),
);

final imageSharerProvider = Provider<ImageSharer>(
  (ref) => const SystemSharer(),
);

final draftStoreProvider = Provider<DraftStore>((ref) => FileDraftStore());

class DeviceLocation implements LocationReader {
  const DeviceLocation();

  @override
  Future<GeoFix?> current() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      return GeoFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isMock: position.isMocked,
      );
    } catch (_) {
      return null;
    }
  }
}

class DevicePhotos implements PhotoPicker {
  const DevicePhotos();

  @override
  Future<String?> pick(PhotoSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 80,
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }
}

/// Opens the camera full screen and returns the first code it reads.
class CameraScanner implements CodeScanner {
  const CameraScanner();

  @override
  Future<String?> scan(BuildContext context) {
    return Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const _ScanPage()));
  }
}

class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  var _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanTitle),
        actions: [
          IconButton(
            tooltip: l.scanTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_done) return;
          for (final code in capture.barcodes) {
            final value = code.rawValue?.trim();
            if (value != null && value.isNotEmpty) {
              _done = true;
              Navigator.of(context).pop(value);
              return;
            }
          }
        },
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.scanCameraOff, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

/// Writes the picture to the app's temp folder and opens the share sheet.
class SystemSharer implements ImageSharer {
  const SystemSharer();

  @override
  Future<void> sharePng(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
      ),
    );
  }
}
