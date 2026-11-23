import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../nav/targets.dart';
import '../state/providers.dart';
import 'assign_screen.dart';
import 'common.dart';
import 'duty_screen.dart';
import 'offers_screen.dart';
import 'ticket_detail_screen.dart';
import 'tickets_screen.dart';

/// One app feature and the ERP permission that opens it (same as the web).
class Feature {
  const Feature(
    this.permission,
    this.icon,
    this.label, {
    this.screen,
    this.also = const [],
    this.open,
  });

  final String permission;
  final String? screen;
  final List<String> also;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final WidgetBuilder? open;

  /// Drawn when `/me` grants the permission. When the ERP also sent a
  /// `screens` list, the feature's screen has to be on it.
  bool allowed(StaffUser user) {
    final byPermission = user.can(permission) || also.any(user.can);
    if (user.screens.isNotEmpty && screen != null) {
      return user.screens.contains(screen) && byPermission;
    }
    return byPermission;
  }
}

/// Planned in mynet-erp ROADMAP Phase 14. Tickets, duty, and offers.
final features = <Feature>[
  Feature(
    'collection.collect',
    Icons.payments_outlined,
    (l) => l.featureCollection,
    screen: 'collection',
  ),
  Feature(
    'tickets.view',
    Icons.build_outlined,
    (l) => l.featureTickets,
    screen: 'tickets',
    also: const ['tickets.manage'],
    open: _openTickets,
  ),
  Feature(
    'clients.view',
    Icons.people_outline,
    (l) => l.featureClients,
    screen: 'clients',
  ),
  Feature(
    'hr.self',
    Icons.event_available_outlined,
    (l) => l.featureHr,
    screen: 'hr',
  ),
  Feature(
    'staff_app.use',
    Icons.my_location_outlined,
    (l) => l.featureDuty,
    screen: 'duty',
    open: _openDuty,
  ),
  Feature(
    'tickets.update',
    Icons.notifications_active_outlined,
    (l) => l.featureOffers,
    screen: 'offers',
    also: const ['tickets.manage'],
    open: _openOffers,
  ),
  Feature(
    'tickets.assign',
    Icons.person_pin_outlined,
    (l) => l.featureAssign,
    also: const ['tickets.manage'],
    open: _openAssign,
  ),
];

Widget _openDuty(BuildContext context) => const DutyScreen();

Widget _openOffers(BuildContext context) => const OffersScreen();

Widget _openAssign(BuildContext context) => const AssignScreen();

Widget _openTickets(BuildContext context) => const TicketListScreen();

List<Feature> featuresFor(StaffUser user) => [
  for (final f in features)
    if (f.allowed(user)) f,
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));
    NavTargets.ticket = (id) => TicketDetailScreen(ticketId: id);

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
                    subtitle: f.open == null ? Text(l.comingSoon) : null,
                    enabled: f.open != null,
                    onTap: f.open == null
                        ? null
                        : () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: f.open!)),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
