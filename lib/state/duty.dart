import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../api/duty.dart';
import '../duty/tracker.dart';

final dutyTrackerProvider = Provider<DutyTracker>((ref) => GeolocatorTracker());

/// One GPS fix for duty start. Null when the phone will not share location.
final hereProvider = Provider<Future<LocationPoint?> Function()>((ref) {
  return () async {
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
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        recordedAt: position.timestamp,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading.round().clamp(0, 360).toInt(),
        isMock: position.isMocked,
      );
    } catch (_) {
      return null;
    }
  };
});
