import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';

import '../api/clients.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'clients_screen.dart';
import 'common.dart';
import 'support_screens.dart';
import 'work_screens.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final int clientId;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  ClientDetail? _client;
  ClientConnection? _connection;
  Object? _error;
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await ref.read(apiProvider).client(widget.clientId);
      if (!mounted) return;
      setState(() {
        _client = client;
        _loading = false;
      });
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _connectionCheck() async {
    final l = AppLocalizations.of(context);
    setState(() => _checking = true);
    try {
      final connection = await ref
          .read(apiProvider)
          .clientConnection(widget.clientId);
      if (!mounted) return;
      setState(() {
        _connection = connection;
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(l, e, l.errGeneric))));
    }
  }

  /// STF-07: tap to fix phone / address / NID when the ERP allows it.
  Widget _contactRow(
    String label,
    String field,
    String? value,
    ClientDetail client,
  ) {
    final row = InfoRow(client.canUpdate ? '$label ✎' : label, value);
    if (!client.canUpdate) return row;
    return InkWell(
      key: ValueKey('edit-$field'),
      onTap: () async {
        final saved = await editClientContact(
          context,
          ref,
          clientId: widget.clientId,
          field: field,
          label: label,
          current: value,
        );
        if (saved) await _load();
      },
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final client = _client;
    final row = client?.row;
    return Scaffold(
      appBar: AppBar(title: Text(row?.name ?? l.featureClients)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const ValueKey('client-detail'),
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  MessageBanner(
                    errorText(l, _error!, l.errGeneric),
                    tone: BannerTone.error,
                  ),
                if (row != null) ...[
                  SectionCard(
                    children: [
                      InfoRow(l.clientsCode, row.code),
                      _contactRow(l.mobile, 'phone', row.phone, client!),
                      _contactRow(
                        l.clientsAddress,
                        'address',
                        row.address,
                        client,
                      ),
                      InfoRow(l.clientsStatus, row.status),
                      InfoRow(l.clientsPackage, row.packageName),
                      InfoRow(l.clientsPrice, erpAmount(row.packagePrice)),
                      InfoRow(l.clientsExpiry, row.expiryDate),
                      InfoRow(l.clientsDue, erpAmount(row.due)),
                      InfoRow(l.clientsAdvance, erpAmount(row.advance)),
                      InfoRow(l.clientsBalance, erpAmount(row.balance)),
                      InfoRow(l.clientsPppoe, client.pppoeUsername),
                      _contactRow(l.clientsNid, 'nid', client.nid, client),
                      InfoRow(l.clientsPop, client.pop),
                      InfoRow(l.clientsRouter, client.router),
                      InfoRow(l.clientsOnu, client.onuSn),
                      InfoRow(l.clientsRx, erpAmount(client.lastRxDbm)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('client-connection'),
                    onPressed: _checking ? null : _connectionCheck,
                    icon: const Icon(Icons.wifi_tethering),
                    label: Text(l.clientsConnection),
                  ),
                  if (client.canOpenTicket)
                    OutlinedButton.icon(
                      key: const ValueKey('client-new-ticket'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NewTicketScreen(
                            clientId: row.id,
                            clientName: row.name ?? '',
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_task),
                      label: Text(l.supportNewTicket),
                    ),
                  if (_canRecharge(
                    ref.watch(authProvider.select((a) => a.user)),
                  ))
                    FilledButton.tonalIcon(
                      key: const ValueKey('client-recharge'),
                      onPressed: () async {
                        final done = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => RechargeScreen(
                              clientId: row.id,
                              clientName: row.name ?? '',
                            ),
                          ),
                        );
                        if (done == true) await _load();
                      },
                      icon: const Icon(Icons.autorenew),
                      label: Text(l.workRecharge),
                    ),
                  if (_connection != null) ...[
                    const SizedBox(height: 8),
                    MessageBanner(
                      _connection!.online == true
                          ? l.clientsOnline
                          : l.clientsOffline,
                      tone: _connection!.online == true
                          ? BannerTone.info
                          : BannerTone.warning,
                    ),
                    if (_connection!.disconnects24h != null)
                      Text(l.clientsDisconnects(_connection!.disconnects24h!)),
                  ],
                  if (client.openTickets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l.clientsOpenTickets,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final ticket in client.openTickets)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(ticket.subject ?? '—'),
                        subtitle: Text(ticket.status ?? ''),
                      ),
                  ],
                  if (client.recentPayments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.clientsPayments,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final payment in client.recentPayments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(payment.receiptNo ?? '—'),
                        subtitle: Text(
                          [
                            erpAmount(payment.amount),
                            payment.approvalStatus,
                          ].whereType<String>().join(' · '),
                        ),
                      ),
                  ],
                ],
              ],
            ),
    );
  }
}

/// STF-08: recharge is the web's `clients.recharge|billing.collect`; the ERP
/// checks the client's policy again.
bool _canRecharge(StaffUser? user) =>
    user != null &&
    (user.can('clients.recharge') || user.can('billing.collect'));
