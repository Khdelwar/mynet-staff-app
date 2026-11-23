// ERP sends through the FCM HTTP v1 API to a classic registration token, so
// getToken / onTokenRefresh are used on purpose instead of the newer
// installation-ID API, which the ERP does not send to.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/staff_api.dart';
import 'message.dart';

export 'message.dart';

/// Push for the signed-in phone. Best-effort: a build without Firebase
/// config, a refused permission or a failed call never blocks sign-in.
/// The FCM token is never logged.
abstract class PushService {
  Future<void> register(StaffApi api);

  Future<void> unregister(StaffApi api);

  Stream<PushMessage> get messages;

  /// A tap that arrived before the shell was listening (cold start).
  PushMessage? takePending();
}

@pragma('vm:entry-point')
Future<void> staffFirebaseBackground(RemoteMessage message) async {}

class FirebasePush implements PushService {
  FirebasePush._();
  static final FirebasePush instance = FirebasePush._();

  bool _ready = false;
  PushMessage? _pending;
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  final _messages = StreamController<PushMessage>.broadcast();

  /// Leaves push off when this build has no Firebase config.
  Future<void> init() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      _ready = true;
    } catch (_) {
      _ready = false;
      return;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(staffFirebaseBackground);
    } catch (_) {
      // Already registered, or this start cannot take a background handler.
    }
    await _foreground?.cancel();
    await _opened?.cancel();
    _foreground = FirebaseMessaging.onMessage.listen(
      (m) => _emit(m, tapped: false),
    );
    _opened = FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _emit(m, tapped: true),
    );
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _emit(initial, tapped: true);
    } catch (_) {
      // Cold-start payload is optional.
    }
  }

  void _emit(RemoteMessage message, {required bool tapped}) {
    final parsed = parsePush(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
      tapped: tapped,
    );
    if (parsed == null) return;
    if (tapped) _pending = parsed;
    if (!_messages.isClosed) _messages.add(parsed);
  }

  @override
  Stream<PushMessage> get messages =>
      _ready ? _messages.stream : const Stream.empty();

  @override
  PushMessage? takePending() {
    final pending = _pending;
    _pending = null;
    return pending;
  }

  @override
  Future<void> register(StaffApi api) async {
    if (!_ready || api.token == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken().timeout(
        const Duration(seconds: 10),
      );
      if (token == null || token.isEmpty) return;
      await api.registerPush(token);
      await _refresh?.cancel();
      _refresh = messaging.onTokenRefresh.listen((fresh) {
        if (fresh.isEmpty || api.token == null) return;
        unawaited(() async {
          try {
            await api.registerPush(fresh);
          } catch (_) {
            // The next refresh tries again.
          }
        }());
      });
    } catch (_) {
      // Push stays off; the app works without it.
    }
  }

  @override
  Future<void> unregister(StaffApi api) async {
    await _refresh?.cancel();
    _refresh = null;
    if (!_ready || api.token == null) return;
    try {
      await api.unregisterPush().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Signing out continues regardless. Logout also drops the token.
    }
  }
}
