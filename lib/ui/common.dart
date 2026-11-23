import 'package:flutter/material.dart';

import '../api/staff_api.dart';
import '../config.dart';
import '../l10n/app_localizations.dart';

/// Text safe to show for a failed call. API paths and HTTP codes appear only
/// in debug builds; short ERP messages (validation, "not allowed") pass through.
String errorText(AppLocalizations l, Object error, String fallback) {
  if (error is! ApiException) return fallback;
  if (AppConfig.debugApi) {
    return '$fallback [${error.status} ${error.path}] ${error.message}';
  }
  if (error.isNetwork) return l.errNetwork;
  final fromErp =
      const [400, 401, 403, 409, 422, 429].contains(error.status) &&
      error.message.isNotEmpty &&
      error.message.length < 200 &&
      !RegExp(r'[<{]|https?:', caseSensitive: false).hasMatch(error.message);
  return fromErp ? error.message : fallback;
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value == null || value!.isEmpty ? '—' : value!,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

enum BannerTone { info, warning, error }

class MessageBanner extends StatelessWidget {
  const MessageBanner(this.text, {super.key, this.tone = BannerTone.info});
  final String text;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final (bg, fg, icon) = switch (tone) {
      BannerTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      BannerTone.warning => (
        dark ? const Color(0xFF4A3A00) : const Color(0xFFFFF3CD),
        dark ? const Color(0xFFFFE08A) : const Color(0xFF5C4400),
        Icons.warning_amber_rounded,
      ),
      BannerTone.info => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.info_outline,
      ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: fg)),
          ),
        ],
      ),
    );
  }
}
