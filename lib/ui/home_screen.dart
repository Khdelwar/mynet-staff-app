import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../nav/targets.dart';
import '../state/providers.dart';
import 'approvals_screen.dart';
import 'assign_screen.dart';
import 'chat_screen.dart';
import 'clients_screen.dart';
import 'collection_screen.dart';
import 'due_list_screen.dart';
import 'common.dart';
import 'duty_screen.dart';
import 'offers_screen.dart';
import 'ticket_detail_screen.dart';
import 'tickets_screen.dart';
import 'work_screens.dart';

/// One app feature and the ERP permission that opens it (same as the web).
class Feature {
  const Feature(
    this.permission,
    this.icon,
    this.label, {
    this.screen,
    this.also = const [],
    this.roles = const [],
    this.open,
  });

  final String permission;
  final String? screen;
  final List<String> also;

  /// For screens the ERP gives by role, not permission (`role:reseller`
  /// API routes): any of these roles opens it, no permission needed.
  final List<String> roles;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final WidgetBuilder? open;

  /// Drawn when `/me` grants the permission. When the ERP also sent a
  /// `screens` list, the feature's screen has to be on it. The permission
  /// lists here match the ERP API routes, so an extra per-user grant that
  /// opens the API also shows the button.
  bool allowed(StaffUser user) {
    final byPermission = roles.isNotEmpty
        ? roles.any(user.roles.contains)
        : user.can(permission) || also.any(user.can);
    if (user.screens.isNotEmpty && screen != null) {
      return user.screens.contains(screen) && byPermission;
    }
    return byPermission;
  }
}

/// Planned in mynet-erp ROADMAP Phase 14. Tickets, duty, and offers.
/// The Clients tile opens the staff client list.
final features = <Feature>[
  Feature(
    'dashboard.view',
    Icons.dashboard_outlined,
    (l) => l.featureDashboard,
    screen: 'dashboard',
    open: _openDashboard,
  ),
  Feature(
    'collection.collect',
    Icons.payments_outlined,
    (l) => l.featureCollection,
    screen: 'collection',
    // Same list as the ERP's GET /collection/summary.
    also: const [
      'collection.gateway',
      'collection.expense',
      'collection.view',
      'billing.collect',
      'collection.sell',
      'staff.expense.submit',
      'inventory.sell',
      'collection.approve',
    ],
    open: _openCollection,
  ),
  // Approval-only people (cash / collections / ledger) cannot open the
  // Collection screen, so approvals have their own button.
  Feature(
    'collection.approve',
    Icons.fact_check_outlined,
    (l) => l.featureApprovals,
    screen: 'approvals',
    also: const ['approvals.cash', 'approvals.collections', 'ledger.approve'],
    open: _openApprovals,
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
    open: _openClients,
  ),
  Feature(
    'support_chat.manage',
    Icons.forum_outlined,
    (l) => l.featureChat,
    screen: 'support_chat',
    open: _openChat,
  ),
  Feature(
    'hr.self',
    Icons.event_available_outlined,
    (l) => l.featureHr,
    screen: 'hr',
    open: _openHr,
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
    'billing.due_list',
    Icons.receipt_long_outlined,
    (l) => l.featureDueList,
    screen: 'due_list',
    also: const ['billing.view', 'billing.collect'],
    open: _openDueList,
  ),
  Feature(
    'inventory.sell',
    Icons.point_of_sale_outlined,
    (l) => l.featureSales,
    screen: 'sales',
    also: const ['inventory.manage'],
    open: _openSales,
  ),
  // STF-08: the ERP gives these two to a reseller by role (role:reseller on
  // the API and in `screens`), with or without clients.recharge.
  Feature(
    'clients.recharge',
    Icons.account_balance_wallet_outlined,
    (l) => l.featureWallet,
    screen: 'reseller_wallet',
    roles: const ['reseller'],
    open: _openWallet,
  ),
  Feature(
    'clients.recharge',
    Icons.timer_outlined,
    (l) => l.featureExpiring,
    screen: 'expiring',
    roles: const ['reseller'],
    open: _openExpiring,
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

Widget _openDashboard(BuildContext context) => const DashboardScreen();

Widget _openHr(BuildContext context) => const HrScreen();

Widget _openSales(BuildContext context) => const SalesScreen();

Widget _openWallet(BuildContext context) => const ResellerWalletScreen();

Widget _openExpiring(BuildContext context) => const ExpiringScreen();

Widget _openOffers(BuildContext context) => const OffersScreen();

Widget _openAssign(BuildContext context) => const AssignScreen();

Widget _openTickets(BuildContext context) => const TicketListScreen();

Widget _openClients(BuildContext context) => const ClientListScreen();

Widget _openChat(BuildContext context) => const ChatListScreen();

Widget _openCollection(BuildContext context) => const CollectionScreen();

Widget _openApprovals(BuildContext context) => const ApprovalsScreen();

Widget _openDueList(BuildContext context) => const DueListScreen();

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
    final canTickets =
        user != null &&
        features.any((f) => f.screen == 'tickets' && f.allowed(user));
    final canOffers =
        user != null &&
        features.any((f) => f.screen == 'offers' && f.allowed(user));
    final canChat =
        user != null &&
        features.any((f) => f.screen == 'support_chat' && f.allowed(user));
    NavTargets.ticket = canTickets
        ? (id) => TicketDetailScreen(ticketId: id)
        : null;
    NavTargets.offers = canOffers
        ? (offerId, _) => OffersScreen(offerId: offerId)
        : null;
    NavTargets.chat = canChat
        ? (id) => ChatThreadScreen(conversationId: id)
        : null;

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
