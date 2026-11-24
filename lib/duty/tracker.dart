import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../api/duty.dart';

/// Emits a point on the interval the ERP last sent. While this is running
/// the phone shows a permanent "MyNet: location on" notification, which is
/// what Android requires for location taken in the background.
abstract class DutyTracker {
  Stream<LocationPoint> get points;

  Future<void> start({
    required int intervalSeconds,
    required String title,
    required String body,
  });

  Future<void> stop();
}

class IdleTracker implements DutyTracker {
  IdleTracker();

  final _points = StreamController<LocationPoint>.broadcast();
  var running = false;

  @override
  Stream<LocationPoint> get points => _points.stream;

  void emit(LocationPoint point) {
    if (running && !_points.isClosed) _points.add(point);
  }

  @override
  Future<void> start({
    required int intervalSeconds,
    required String title,
    required String body,
  }) async {
    running = true;
  }

  @override
  Future<void> stop() async {
    running = false;
  }
}

class GeolocatorTracker implements DutyTracker {
  GeolocatorTracker();

  final _points = StreamController<LocationPoint>.broadcast();
  StreamSubscription<Position>? _sub;

  @override
  Stream<LocationPoint> get points => _points.stream;

  @override
  Future<void> start({
    required int intervalSeconds,
    required String title,
    required String body,
  }) async {
    await stop();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final seconds = intervalSeconds < 10 ? 10 : intervalSeconds;
    _sub =
        Geolocator.getPositionStream(
          locationSettings: _settings(seconds, title, body),
        ).listen((position) {
          if (_points.isClosed) return;
          _points.add(
            LocationPoint(
              latitude: position.latitude,
              longitude: position.longitude,
              recordedAt: position.timestamp,
              accuracy: position.accuracy,
              speed: position.speed,
              heading: position.heading.round().clamp(0, 360).toInt(),
              isMock: position.isMocked,
            ),
          );
        });
  }

  LocationSettings _settings(int seconds, String title, String body) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: seconds),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: title,
          notificationText: body,
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
