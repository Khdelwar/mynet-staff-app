import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/staff_api.dart';
import '../config.dart';
import '../l10n/app_localizations.dart';
import '../login_id.dart';
import '../state/providers.dart';
import 'common.dart';

/// ERP email + password, then the 2FA code when the user has it on.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  TwoFactorNeeded? _twoFactor;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object e) {
    final l = AppLocalizations.of(context);
    if (e is ApiException && !e.isNetwork && !AppConfig.debugApi) {
      if (_twoFactor != null && (e.status == 422 || e.status == 401)) {
        return e.message.isNotEmpty && e.status == 422
            ? e.message
            : l.twoFactorWrong;
      }
      if (e.status == 401 || e.code == 'invalid' || e.code == 'failed') {
        return l.loginWrong;
      }
    }
    return errorText(l, e, l.errGeneric);
  }

  Future<void> _signIn() => _run(() async {
    final outcome = await ref
        .read(authProvider.notifier)
        .login(_email.text, _password.text);
    if (outcome is TwoFactorNeeded && mounted) {
      _code.clear();
      setState(() => _twoFactor = outcome);
    }
  });

  Future<void> _verify() => _run(() async {
    final step = _twoFactor;
    if (step == null) return;
    await ref
        .read(authProvider.notifier)
        .verifyTwoFactor(step.challenge, _code.text);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final configured = ref.watch(configuredProvider);
    final ended = ref.watch(authProvider.select((a) => a.ended));
    final step = _twoFactor;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (step != null)
                          TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _twoFactor = null;
                                    _error = null;
                                  }),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(l.back),
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: ref.read(localeProvider.notifier).toggle,
                          icon: const Icon(Icons.language),
                          label: Text(l.languageToggle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.badge_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.appTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      step == null ? l.loginTitle : l.twoFactorTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (!configured)
                      MessageBanner(l.notConfigured, tone: BannerTone.error),
                    if (ended && step == null && _error == null)
                      MessageBanner(l.sessionEnded, tone: BannerTone.warning),
                    if (step == null) ..._credentials(l, configured),
                    if (step != null) ..._codeStep(l, step),
                    if (_error != null)
                      MessageBanner(_error!, tone: BannerTone.error),
                    FilledButton(
                      key: const ValueKey('submit'),
                      onPressed: configured && !_busy
                          ? (step == null ? _signIn : _verify)
                          : null,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              step == null ? l.loginButton : l.twoFactorButton,
                            ),
                    ),
                    if (step == null) ...[
                      const SizedBox(height: 20),
                      Text(
                        l.loginHelp,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _credentials(AppLocalizations l, bool configured) => [
    TextFormField(
      key: const ValueKey('email'),
      controller: _email,
      enabled: configured && !_busy,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l.loginIdentifier,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: (v) {
        final value = (v ?? '').trim();
        if (value.isEmpty) return l.fieldRequired;
        if (!isStaffLoginId(value)) return l.loginIdentifierInvalid;
        return null;
      },
    ),
    const SizedBox(height: 14),
    TextFormField(
      key: const ValueKey('password'),
      controller: _password,
      enabled: configured && !_busy,
      obscureText: !_showPassword,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => _signIn(),
      decoration: InputDecoration(
        labelText: l.loginPassword,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: l.showPassword,
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
      validator: (v) => (v ?? '').isEmpty ? l.fieldRequired : null,
    ),
    const SizedBox(height: 16),
  ];

  List<Widget> _codeStep(AppLocalizations l, TwoFactorNeeded step) => [
    MessageBanner(switch (step.channel) {
      'totp' => l.twoFactorTotp,
      'telegram' => l.twoFactorTelegram,
      _ => l.twoFactorSms,
    }),
    TextFormField(
      key: const ValueKey('code'),
      controller: _code,
      enabled: !_busy,
      autofocus: true,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      maxLength: 6,
      onFieldSubmitted: (_) => _verify(),
      decoration: InputDecoration(
        labelText: l.twoFactorCode,
        prefixIcon: const Icon(Icons.pin_outlined),
      ),
      validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
          ? null
          : l.fieldRequired,
    ),
    const SizedBox(height: 8),
  ];
}
