import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../field/drafts.dart';
import '../field/location.dart';
import '../field/photos.dart';

final locationReaderProvider = Provider<LocationReader>(
  (ref) => const DeviceLocation(),
);

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => const DevicePhotos(),
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
