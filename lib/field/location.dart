/// A GPS fix from the phone. The ERP stores the house pin and the finish
/// proof; this app only reads the sensor.
class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.isMock = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isMock;
}

abstract class LocationReader {
  Future<GeoFix?> current();
}

/// Used when the screen does not need a real sensor (tests, or GPS off).
class UnavailableLocation implements LocationReader {
  const UnavailableLocation();

  @override
  Future<GeoFix?> current() async => null;
}
