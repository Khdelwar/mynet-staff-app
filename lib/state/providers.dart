import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/models.dart';
import '../api/staff_api.dart';
import '../config.dart';
import '../device.dart';
import '../push/push.dart';
import 'stores.dart';

/// Overridden in `main()` with the loaded instance.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const SecureSecretStore(),
);

/// The ERP this phone signs in to (`https://host`), or null until staff
/// type one on the login screen. Saved after a successful sign-in, so the
/// same app works for every ISP that runs the ERP.
class ServerController extends Notifier<String?> {
  static const key = 'erp_server';

  @override
  String? build() {
    final saved = ref.read(prefsProvider).getString(key);
    final server =
        (saved == null ? null : AppConfig.normalizeServer(saved)) ??
        AppConfig.defaultServer;
    AppConfig.activeServer = server;
    return server;
  }

  void set(String server) {
    AppConfig.activeServer = server;
    state = server;
    unawaited(ref.read(prefsProvider).setString(key, server));
  }
}

final serverProvider = NotifierProvider<ServerController, String?>(
  ServerController.new,
);

final apiProvider = Provider<StaffApi>((ref) {
  return StaffApi(
    // Read once: the address only changes on the login screen, where
    // AuthController.login points this client at the new one.
    server: ref.read(serverProvider),
    onUnauthorized: (rejected, code, message) => ref
        .read(authProvider.notifier)
        .sessionExpired(rejectedToken: rejected, code: code, message: message),
  );
});

/// Overridden in tests. The real one no-ops until Firebase is configured.
final pushServiceProvider = Provider<PushService>(
  (ref) => FirebasePush.instance,
);

/// Latest notification. The shell turns a tap into a page.
class PushInbox extends Notifier<PushMessage?> {
  @override
  PushMessage? build() {
    final service = ref.watch(pushServiceProvider);
    final sub = service.messages.listen((message) => state = message);
    ref.onDispose(sub.cancel);
    final pending = service.takePending();
    if (pending != null) {
      Future.microtask(() {
        if (state == null) state = pending;
      });
    }
    return null;
  }
}

final pushInboxProvider = NotifierProvider<PushInbox, PushMessage?>(
  PushInbox.new,
);

// --- Session ------------------------------------------------------------

class AuthState {
  const AuthState({
    this.ready = false,
    this.token,
    this.user,
    this.session = 0,
    this.ended = false,
    this.endMessage,
  });

  /// False until the stored token has been read at startup.
  final bool ready;
  final String? token;

  /// Last known profile. May be from cache while offline.
  final StaffUser? user;

  /// Changes on every sign-in, so screens reload for the new session.
  final int session;

  /// The ERP ended the session (deactivated, permission removed, password
  /// changed, token expired): the login screen says so.
  final bool ended;

  /// Server text for a 401 that ends the session. Not cached.
  final String? endMessage;

  bool get signedIn => token != null;
}

const _sessionEndCodes = {
  'unauthenticated',
  'inactive',
  'no_access',
  'reseller_inactive',
};

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(Future.microtask(_restore));
    return const AuthState();
  }

  StaffApi get _api => ref.read(apiProvider);
  SecretStore get _store => ref.read(secretStoreProvider);

  Future<void> _restore() async {
    final token = await _store.read(sessionTokenKey);
    if (token == null || token.isEmpty) {
      state = const AuthState(ready: true);
      return;
    }
    StaffUser? cached;
    try {
      final raw = await _store.read(cachedUserKey);
      if (raw != null) cached = StaffUser.fromJson(jsonDecode(raw));
    } catch (_) {
      cached = null;
    }
    _api.token = token;
    state = AuthState(ready: true, token: token, user: cached, session: 1);
    try {
      await refreshProfile();
    } on ApiException {
      // Offline: keep the cached profile; a 401 already signed out.
    }
    if (state.signedIn) unawaited(_bindPush());
  }

  /// ERP address of a sign-in still waiting for its 2FA code.
  String? _pendingServer;

  /// Signs in to [server] (default: the saved one), or returns
  /// [TwoFactorNeeded] for the code step. The address is saved only once
  /// the ERP has accepted the sign-in.
  Future<LoginOutcome> login(
    String email,
    String password, {
    String? server,
  }) async {
    final target = server ?? ref.read(serverProvider);
    if (target == null) {
      throw const ApiException(0, '', path: '/auth/login', code: 'no_server');
    }
    _api.server = target;
    _pendingServer = target;
    AppConfig.activeServer = target;
    final LoginOutcome outcome;
    try {
      outcome = await _api.login(
        email,
        password,
        deviceId: await ensureDeviceId(_store),
        deviceName: await deviceName(),
        appVersion: staffAppVersion,
      );
    } catch (_) {
      // A refused or unreachable address does not replace the saved one.
      AppConfig.activeServer = ref.read(serverProvider);
      rethrow;
    }
    if (outcome is SignedIn) await _start(outcome);
    return outcome;
  }

  Future<void> verifyTwoFactor(String challenge, String code) async {
    final outcome = await _api.verifyTwoFactor(challenge, code);
    if (outcome is SignedIn) {
      await _start(outcome);
    } else {
      // A second challenge here would be an ERP fault: treat as failed.
      throw const ApiException(422, '', path: '/auth/two-factor');
    }
  }

  Future<void> _start(SignedIn signedIn) async {
    final server = _pendingServer;
    if (server != null && server != ref.read(serverProvider)) {
      ref.read(serverProvider.notifier).set(server);
    }
    _pendingServer = null;
    await _store.write(sessionTokenKey, signedIn.token);
    await _cache(signedIn.user);
    _api.token = signedIn.token;
    state = AuthState(
      ready: true,
      token: signedIn.token,
      user: signedIn.user,
      session: state.session + 1,
    );
    unawaited(_bindPush());
  }

  /// Tells the ERP this phone's FCM token. Failures never block sign-in.
  Future<void> _bindPush() async {
    if (state.token == null) return;
    try {
      await ref.read(pushServiceProvider).register(_api);
    } catch (_) {
      // Push stays off.
    }
  }

  Future<void> refreshProfile() async {
    final token = state.token;
    if (token == null) return;
    final user = await _api.me();
    if (state.token != token) return; // signed out meanwhile
    await _cache(user);
    state = AuthState(
      ready: true,
      token: token,
      user: user,
      session: state.session,
    );
  }

  Future<void> _cache(StaffUser user) async {
    try {
      await _store.write(cachedUserKey, jsonEncode(user.toJson()));
    } catch (_) {
      // Cache only.
    }
  }

  Future<void> logout() async {
    // Clear the FCM token while the session still exists, then sign out.
    // Logout on the server also drops pushes if this call does not land.
    try {
      await ref.read(pushServiceProvider).unregister(_api);
    } catch (_) {
      // Signing out continues.
    }
    try {
      await _api.logout();
    } catch (_) {
      // Offline or already gone: the phone forgets the token either way.
    }
    await _clear(ended: false);
  }

  /// ERP answered 401 for [rejectedToken]. The cached profile is dropped.
  Future<void> sessionExpired({
    required String rejectedToken,
    String? code,
    String? message,
  }) async {
    if (state.token != rejectedToken) return; // an older request
    final text = message?.trim() ?? '';
    final show = text.isNotEmpty && _sessionEndCodes.contains(code);
    await _clear(ended: true, message: show ? text : null);
  }

  Future<void> _clear({required bool ended, String? message}) async {
    _api.token = null;
    await _store.delete(sessionTokenKey);
    await _store.delete(cachedUserKey);
    state = AuthState(
      ready: true,
      session: state.session + 1,
      ended: ended,
      endMessage: message,
    );
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// --- Preferences --------------------------------------------------------

class LocaleController extends Notifier<Locale> {
  static const _key = 'locale';

  @override
  Locale build() => Locale(ref.read(prefsProvider).getString(_key) ?? 'bn');

  void toggle() {
    state = Locale(state.languageCode == 'bn' ? 'en' : 'bn');
    unawaited(ref.read(prefsProvider).setString(_key, state.languageCode));
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class AppLockController extends Notifier<bool> {
  static const _key = 'app_lock';

  @override
  bool build() => ref.read(prefsProvider).getBool(_key) ?? false;

  void set(bool enabled) {
    state = enabled;
    unawaited(ref.read(prefsProvider).setBool(_key, enabled));
  }
}

final appLockProvider = NotifierProvider<AppLockController, bool>(
  AppLockController.new,
);
