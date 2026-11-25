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
import 'theme.dart';
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
    this.open,
    this.section = ErpSection.overview,
  });

  final String permission;
  final String? screen;
  final List<String> also;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final WidgetBuilder? open;

  /// The ERP menu section this lives under; its tile takes that colour.
  final ErpSection section;

  /// Drawn when `/me` grants the permission. When the ERP also sent a
  /// `screens` list, the feature's screen has to be on it. The permission
  /// lists here match the ERP API routes, so an extra per-user grant that
  /// opens the API also shows the button.
  bool allowed(StaffUser user) {
    final byPermission = user.can(permission) || also.any(user.can);
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
    section: ErpSection.overview,
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
    section: ErpSection.billing,
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
    section: ErpSection.approvals,
  ),
  Feature(
    'tickets.view',
    Icons.build_outlined,
    (l) => l.featureTickets,
    screen: 'tickets',
    also: const ['tickets.manage'],
    open: _openTickets,
    section: ErpSection.tickets,
  ),
  Feature(
    'clients.view',
    Icons.people_outline,
    (l) => l.featureClients,
    screen: 'clients',
    open: _openClients,
    section: ErpSection.customers,
  ),
  Feature(
    'support_chat.manage',
    Icons.forum_outlined,
    (l) => l.featureChat,
    screen: 'support_chat',
    open: _openChat,
    section: ErpSection.sms,
  ),
  Feature(
    'hr.self',
    Icons.event_available_outlined,
    (l) => l.featureHr,
    screen: 'hr',
    open: _openHr,
    section: ErpSection.hr,
  ),
  Feature(
    'staff_app.use',
    Icons.my_location_outlined,
    (l) => l.featureDuty,
    screen: 'duty',
    open: _openDuty,
    section: ErpSection.accounts,
  ),
  Feature(
    'tickets.update',
    Icons.notifications_active_outlined,
    (l) => l.featureOffers,
    screen: 'offers',
    also: const ['tickets.manage'],
    open: _openOffers,
    section: ErpSection.tickets,
  ),
  Feature(
    'billing.due_list',
    Icons.receipt_long_outlined,
    (l) => l.featureDueList,
    screen: 'due_list',
    also: const ['billing.view', 'billing.collect'],
    open: _openDueList,
    section: ErpSection.billing,
  ),
  Feature(
    'inventory.sell',
    Icons.point_of_sale_outlined,
    (l) => l.featureSales,
    screen: 'sales',
    also: const ['inventory.manage'],
    open: _openSales,
    section: ErpSection.inventory,
  ),
  // STF-08: the ERP lists these two only for a reseller (role:reseller).
  Feature(
    'clients.recharge',
    Icons.account_balance_wallet_outlined,
    (l) => l.featureWallet,
    screen: 'reseller_wallet',
    open: _openWallet,
    section: ErpSection.resellers,
  ),
  Feature(
    'clients.recharge',
    Icons.timer_outlined,
    (l) => l.featureExpiring,
    screen: 'expiring',
    open: _openExpiring,
    section: ErpSection.resellers,
  ),
  Feature(
    'tickets.assign',
    Icons.person_pin_outlined,
    (l) => l.featureAssign,
    also: const ['tickets.manage'],
    open: _openAssign,
    section: ErpSection.tickets,
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
            PageHero(
              title: l.hello(user.staff?.name ?? user.name),
              eyebrow: user.roles.join(' · '),
              help: [
                ?user.staff?.designation,
                ?user.staff?.code,
              ].where((v) => v.isNotEmpty).join(' · '),
              icon: Icons.badge_outlined,
            ),
            if (user.staff == null)
              MessageBanner(l.noStaffProfile, tone: BannerTone.info),
            SectionLabel(l.yourWork),
            if (featuresFor(user).isEmpty)
              MessageBanner(l.noFeatures)
            else
              _FeatureGrid(features: featuresFor(user)),
          ],
        ],
      ),
    );
  }
}

/// Two tiles per row (three on wide screens), like the ERP dashboard cards.
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});
  final List<Feature> features;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final perRow = box.maxWidth >= 560 ? 3 : 2;
        const gap = 10.0;
        final width = (box.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final f in features)
              SizedBox(
                width: width,
                child: _FeatureTile(feature: f),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});
  final Feature feature;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tone = feature.section.of(context);
    final open = feature.open;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: open == null
            ? null
            : () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: open)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tone.bg, tone.bgEnd],
                      ),
                      border: Border.all(color: tone.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(feature.icon, color: tone.fg, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                // Room for two lines, so every tile in a row is the same height.
                height: 40,
                child: Text(
                  feature.label(l),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : ErpColors.slate900,
                    height: 1.3,
                  ),
                ),
              ),
              if (open == null)
                Text(l.comingSoon, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
