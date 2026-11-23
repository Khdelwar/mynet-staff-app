import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';

/// One app feature and the ERP permission that opens it (same as the web).
class Feature {
  const Feature(this.permission, this.icon, this.label);
  final String permission;
  final IconData icon;
  final String Function(AppLocalizations) label;
}

/// Planned in mynet-erp ROADMAP Phase 14 (STF-02 … STF-05).
final features = <Feature>[
  Feature(
    'collection.collect',
    Icons.payments_outlined,
    (l) => l.featureCollection,
  ),
  Feature('tickets.view', Icons.build_outlined, (l) => l.featureTickets),
  Feature('clients.view', Icons.people_outline, (l) => l.featureClients),
  Feature('hr.self', Icons.event_available_outlined, (l) => l.featureHr),
];

List<Feature> featuresFor(StaffUser user) => [
  for (final f in features)
    if (user.can(f.permission)) f,
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(authProvider.notifier).refreshProfile().catchError((_) {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null) ...[
            MessageBanner(l.homeLoadFailed, tone: BannerTone.warning),
            FilledButton(
              onPressed: () => ref
                  .read(authProvider.notifier)
                  .refreshProfile()
                  .catchError((_) {}),
              child: Text(l.retry),
            ),
          ] else ...[
            Text(
              l.hello(user.staff?.name ?? user.name),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            SectionCard(
              children: [
                if (user.staff != null) ...[
                  InfoRow(l.staffCode, user.staff!.code),
                  InfoRow(l.designation, user.staff!.designation),
                ],
                InfoRow(l.roles, user.roles.join(', ')),
              ],
            ),
            if (user.staff == null)
              MessageBanner(l.noStaffProfile, tone: BannerTone.info),
            const SizedBox(height: 4),
            Text(l.yourWork, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (featuresFor(user).isEmpty)
              MessageBanner(l.noFeatures)
            else
              for (final f in featuresFor(user))
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(f.icon, color: theme.colorScheme.primary),
                    title: Text(f.label(l)),
                    subtitle: Text(l.comingSoon),
                    enabled: false,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
