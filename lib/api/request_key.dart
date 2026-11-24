import 'dart:math';

final _random = Random.secure();

/// A new random key for one money / stock request (mynet-erp `request_key`).
/// Keep it while retrying the same request; make a new one for the next.
String newRequestKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
