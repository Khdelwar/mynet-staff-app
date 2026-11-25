import 'package:flutter/material.dart';

import '../api/staff_api.dart';
import '../config.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

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

/// ERP card: white, thin slate border, 8px corners, title in semibold.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.children,
  });
  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.brightness == Brightness.dark
                            ? Colors.white
                            : ErpColors.slate900,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum BannerTone { info, success, warning, error }

/// ERP `x-ui.alert`: tinted box, matching border, icon, dark text.
class MessageBanner extends StatelessWidget {
  const MessageBanner(this.text, {super.key, this.tone = BannerTone.info});
  final String text;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // [background, border, text] light; dark keeps the hue on charcoal.
    final (bg, line, fg, icon) = switch (tone) {
      BannerTone.error => (
        const Color(0xFFFFF1F2),
        const Color(0xFFFECDD3),
        const Color(0xFF881337),
        Icons.error_outline,
      ),
      BannerTone.success => (
        ErpColors.accent50,
        ErpColors.accent200,
        ErpColors.accent900,
        Icons.check_circle_outline,
      ),
      BannerTone.warning => (
        const Color(0xFFFFFBEB),
        const Color(0xFFFCD34D),
        const Color(0xFF451A03),
        Icons.warning_amber_rounded,
      ),
      BannerTone.info => (
        const Color(0xFFF0F9FF),
        const Color(0xFFBAE6FD),
        const Color(0xFF0C4A6E),
        Icons.info_outline,
      ),
    };
    final background = dark
        ? Color.alphaBlend(line.withValues(alpha: 0.14), ErpColors.sidebarBg)
        : bg;
    final border = dark ? line.withValues(alpha: 0.45) : line;
    final color = dark ? line : fg;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeTone { neutral, success, warning, danger, info }

/// ERP `x-ui.badge`: a small rounded chip that always holds a word.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key, this.tone = BadgeTone.neutral});
  final String text;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, ring, fg) = switch (tone) {
      BadgeTone.neutral => (ErpColors.slate100, null, ErpColors.slate700),
      BadgeTone.success => (
        ErpColors.accent50,
        ErpColors.accent200,
        ErpColors.accent800,
      ),
      BadgeTone.warning => (
        const Color(0xFFFFFBEB),
        const Color(0xFFFDE68A),
        const Color(0xFF78350F),
      ),
      BadgeTone.danger => (
        const Color(0xFFFFF1F2),
        const Color(0xFFFECDD3),
        const Color(0xFF9F1239),
      ),
      BadgeTone.info => (
        const Color(0xFFF0F9FF),
        const Color(0xFFBAE6FD),
        const Color(0xFF075985),
      ),
    };
    final hue = ring ?? ErpColors.slate300;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: dark
            ? Color.alphaBlend(hue.withValues(alpha: 0.16), ErpColors.sidebarBg)
            : bg,
        borderRadius: BorderRadius.circular(999),
        border: ring == null && !dark
            ? null
            : Border.all(color: dark ? hue.withValues(alpha: 0.4) : ring!),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: dark ? hue : fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// ERP page header (`x-page-hero`): a soft tint in the section's colour,
/// the section icon in a white chip, the section name, title and help line.
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.title,
    this.eyebrow,
    this.help,
    this.icon = Icons.dashboard_outlined,
    this.section = ErpSection.overview,
  });
  final String title;
  final String? eyebrow;
  final String? help;
  final IconData icon;
  final ErpSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = section.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tone.bg, tone.bgEnd]),
        border: Border.all(color: tone.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tone.chip,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tone.border),
            ),
            child: Icon(icon, color: tone.fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null && eyebrow!.isNotEmpty)
                  Text(
                    eyebrow!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tone.fg,
                      letterSpacing: 0.8,
                    ),
                  ),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: dark ? Colors.white : ErpColors.slate900,
                  ),
                ),
                if (help != null && help!.isNotEmpty)
                  Text(
                    help!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: dark ? ErpColors.sidebarText : ErpColors.slate600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ERP sidebar section heading: small, uppercase, muted, spaced.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

/// A green "it worked" message, so a save is never silent.
SnackBar successSnack(String text) => SnackBar(
  backgroundColor: ErpColors.accent700,
  content: Row(
    children: [
      const Icon(Icons.check_circle, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    ],
  ),
);

/// The ERP sidebar's brand: a green square with the network mark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ErpColors.accent600, ErpColors.accent800],
        ),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(Icons.wifi_tethering, color: Colors.white, size: size * 0.56),
    );
  }
}
