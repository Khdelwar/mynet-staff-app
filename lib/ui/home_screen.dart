import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'clients_screen.dart';
import 'collection_screen.dart';
import 'common.dart';
import 'kit.dart';
import 'office_screens.dart';
import 'tickets_screen.dart';

/// One work screen. [screen] is the ERP's name for it in `/me` → `screens`
/// (mynet-erp `config/staff_app.php`); [permissions] is the fallback for a
/// cached profile from an older ERP without `screens`.
class Feature {
  const Feature(
    this.screen,
    this.permissions,
    this.icon,
    this.label,
    this.page,
  );
  final String screen;
  final List<String> permissions;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final Widget Function() page;
}

final features = <Feature>[
  Feature(
    'dashboard',
    const ['dashboard.view'],
    Icons.dashboard_outlined,
    (l) => l.featureDashboard,
    () => const DashboardScreen(),
  ),
  Feature(
    'duty',
    const ['staff_app.use'],
    Icons.badge_outlined,
    (l) => l.featureDuty,
    () => const DutyScreen(),
  ),
  Feature(
    'tickets',
    const ['tickets.view'],
    Icons.build_outlined,
    (l) => l.featureTickets,
    () => const TicketsScreen(),
  ),
  Feature(
    'offers',
    const [],
    Icons.campaign_outlined,
    (l) => l.featureOffers,
    () => const OffersScreen(),
  ),
  Feature(
    'collection',
    const ['collection.collect', 'collection.gateway', 'billing.collect'],
    Icons.payments_outlined,
    (l) => l.featureCollection,
    () => const CollectionScreen(),
  ),
  Feature(
    'expenses',
    const ['collection.expense'],
    Icons.receipt_long_outlined,
    (l) => l.featureExpenses,
    () => const CollectionScreen(),
  ),
  Feature(
    'approvals',
    const [
      'collection.approve',
      'approvals.cash',
      'approvals.collections',
      'ledger.approve',
    ],
    Icons.fact_check_outlined,
    (l) => l.featureApprovals,
    () => const ApprovalsScreen(),
  ),
  Feature(
    'sales',
    const ['inventory.sell', 'inventory.manage'],
    Icons.point_of_sale_outlined,
    (l) => l.featureSales,
    () => const SalesScreen(),
  ),
  Feature(
    'clients',
    const ['clients.view'],
    Icons.people_outline,
    (l) => l.featureClients,
    () => const ClientsScreen(),
  ),
  Feature(
    'due_list',
    const ['billing.due_list'],
    Icons.request_quote_outlined,
    (l) => l.featureDueList,
    () => const DueListScreen(),
  ),
  Feature(
    'support_chat',
    const ['support_chat.manage'],
    Icons.chat_outlined,
    (l) => l.featureChat,
    () => const ChatsScreen(),
  ),
  Feature(
    'reseller_wallet',
    const [],
    Icons.account_balance_wallet_outlined,
    (l) => l.featureWallet,
    () => const ResellerWalletScreen(),
  ),
  Feature(
    'expiring',
    const [],
    Icons.timer_outlined,
    (l) => l.featureExpiring,
    () => const ExpiringScreen(),
  ),
  Feature(
    'hr',
    const ['hr.self'],
    Icons.event_available_outlined,
    (l) => l.featureHr,
    () => const HrScreen(),
  ),
];

/// The work this login may do: what the ERP lists, in the app's order. The
/// ERP lists collection and expenses separately; they are one screen here.
List<Feature> featuresFor(StaffUser user) {
  final listed = user.screens.isNotEmpty
      ? [
          for (final f in features)
            if (user.screens.contains(f.screen)) f,
        ]
      : [
          for (final f in features)
            if (f.permissions.isNotEmpty && user.canAny(f.permissions)) f,
        ];
  final hasCollection = listed.any((f) => f.screen == 'collection');
  return [
    for (final f in listed)
      if (!(f.screen == 'expenses' && hasCollection)) f,
  ];
}

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
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open<void>(context, f.page()),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
