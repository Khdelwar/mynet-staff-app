enum PhotoSource { camera, gallery }

abstract class PhotoPicker {
  Future<String?> pick(PhotoSource source);
}

class UnavailablePhotos implements PhotoPicker {
  const UnavailablePhotos();

  @override
  Future<String?> pick(PhotoSource source) async => null;
}
