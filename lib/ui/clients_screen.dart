import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../api/request_key.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'collection_screen.dart';
import 'common.dart';
import 'kit.dart';
import 'tickets_screen.dart';
import 'words.dart';

/// STF-07 / STF-08: clients, due list, reseller wallet and recharge. A
/// reseller's people only ever get their own clients (the ERP filters).

class ClientRow extends StatelessWidget {
  const ClientRow(this.c, {super.key, this.onTap, this.trailing});
  final Json c;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final due = toNum(c['due']) ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${pickString(c, const ['name']) ?? ''} · ${pickString(c, const ['code']) ?? ''}',
        ),
        subtitle: Text(
          [
            statusWord(l, pickString(c, const ['status'])),
            pickString(asMap(c['package']), const ['name']),
            if (c['expiry_date'] != null) '${l.expiry}: ${c['expiry_date']}',
            if (c['days_left'] != null)
              l.daysLeft(toNum(c['days_left'])!.toInt()),
            if (due > 0) '${l.due}: ${money(due)}',
            if (c['seen_online'] == true) l.online,
          ].whereType<String>().join(' · '),
        ),
        trailing: trailing,
      ),
    );
  }
}

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _q = '';
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));
    return WorkPage(
      title: l.featureClients,
      fab: (user?.can('clients.create') ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => open<void>(context, const NewClientScreen()),
              icon: const Icon(Icons.person_add_alt),
              label: Text(l.newClient),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l.clientSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (v) => setState(() {
                _q = v.trim();
                _page = 1;
              }),
            ),
          ),
          Expanded(
            child: Loader(
              key: ValueKey('$_q|$_page'),
              load: (api) => api.get(
                '/clients',
                query: {if (_q.length >= 2) 'q': _q, 'page': _page},
              ),
              builder: (context, data, reload) {
                final list = asList(data['clients']).map(asMap).toList();
                if (list.isEmpty) return EmptyList(l.noClients);
                final last = toNum(data['last_page'])?.toInt() ?? 1;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  children: [
                    for (final c in list)
                      ClientRow(
                        c,
                        onTap: () => open<void>(
                          context,
                          ClientDetailScreen(id: toNum(c['id'])!.toInt()),
                        ),
                      ),
                    _Pager(
                      page: _page,
                      last: last,
                      onPage: (p) => setState(() => _page = p),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.last, required this.onPage});
  final int page;
  final int last;
  final void Function(int) onPage;

  @override
  Widget build(BuildContext context) {
    if (last <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $last'),
        IconButton(
          onPressed: page < last ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  int _version = 0;

  void _reload() => setState(() => _version++);

  Future<void> _edit(String field, String label, String? current) async {
    final l = AppLocalizations.of(context);
    final value = await askText(
      context,
      title: label,
      label: label,
      initial: current ?? '',
    );
    if (value == null || !mounted) return;
    final ok = await act(
      context,
      ref,
      (api) => api.patch('/clients/${widget.id}/contact', {
        'field': field,
        'value': value,
      }),
      done: l.saved,
    );
    if (ok != null) _reload();
  }

  Future<void> _connection() async {
    final l = AppLocalizations.of(context);
    final res = await act(
      context,
      ref,
      (api) => api.get('/clients/${widget.id}/connection'),
    );
    if (res == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(res['online'] == true ? l.online : l.offline),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (res['since'] != null) InfoRow(l.since, when(res['since'])),
            if (res['last_disconnect_at'] != null)
              InfoRow(l.lastDisconnect, when(res['last_disconnect_at'])),
            if (res['disconnects_24h'] != null)
              InfoRow(l.disconnects24h, '${res['disconnects_24h']}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: Text(l.ok)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));
    return WorkPage(
      title: l.client,
      body: Loader(
        key: ValueKey(_version),
        load: (api) => api.get('/clients/${widget.id}'),
        builder: (context, data, reload) {
          final c = asMap(data['client']);
          final can = asMap(c['can']);
          final onu = asMap(c['onu']);
          final tickets = c['open_tickets'] == null
              ? null
              : asList(c['open_tickets']).map(asMap).toList();
          final payments = asList(c['recent_payments']).map(asMap).toList();
          Widget editable(String field, String label, String? value) => InkWell(
            onTap: can['update'] == true
                ? () => _edit(field, label, value)
                : null,
            child: InfoRow(label + (can['update'] == true ? ' ✎' : ''), value),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${pickString(c, const ['name']) ?? ''} · ${pickString(c, const ['code']) ?? ''}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              SectionCard(
                children: [
                  InfoRow(
                    l.status,
                    statusWord(l, pickString(c, const ['status'])),
                  ),
                  InfoRow(
                    l.package,
                    '${pickString(asMap(c['package']), const ['name']) ?? '—'} (${money(asMap(c['package'])['price'])})',
                  ),
                  InfoRow(l.expiry, pickString(c, const ['expiry_date'])),
                  InfoRow(l.due, money(c['due'])),
                  InfoRow(l.advance, money(c['advance'])),
                  InfoRow('PPPoE', pickString(c, const ['pppoe_username'])),
                  InfoRow(l.pop, pickString(c, const ['pop'])),
                  InfoRow(l.router, pickString(c, const ['router'])),
                  editable('phone', l.mobile, pickString(c, const ['phone'])),
                  editable(
                    'address',
                    l.address,
                    pickString(c, const ['address']),
                  ),
                  editable('nid', 'NID', pickString(c, const ['nid'])),
                  if (onu.isNotEmpty)
                    InfoRow('ONU', pickString(onu, const ['sn', 'mac'])),
                  if (onu['last_rx_dbm'] != null)
                    InfoRow(l.lastRx, '${onu['last_rx_dbm']} dBm'),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (pickString(c, const ['phone']) != null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          callPhone(pickString(c, const ['phone'])),
                      icon: const Icon(Icons.call_outlined),
                      label: Text(l.call),
                    ),
                  if (c['location'] != null)
                    OutlinedButton.icon(
                      onPressed: () => openMap(c['location']),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l.map),
                    ),
                  OutlinedButton.icon(
                    onPressed: _connection,
                    icon: const Icon(Icons.wifi_tethering),
                    label: Text(l.liveConnection),
                  ),
                  if (can['collect'] == true)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        if (await open<bool>(
                              context,
                              PaymentForm(gateway: false, client: c),
                            ) ==
                            true) {
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(l.takeCash),
                    ),
                  if (user?.canAny(const [
                        'clients.recharge',
                        'billing.collect',
                      ]) ??
                      false)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        if (await open<bool>(
                              context,
                              RechargeScreen(client: c),
                            ) ==
                            true) {
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.autorenew),
                      label: Text(l.recharge),
                    ),
                  if (can['open_ticket'] == true)
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (await open<bool>(
                              context,
                              NewTicketScreen(client: c),
                            ) ==
                            true) {
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.add_task),
                      label: Text(l.newTicket),
                    ),
                ],
              ),
              if (tickets != null) ...[
                const SizedBox(height: 16),
                Text(
                  l.openTickets,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (tickets.isEmpty) Text(l.noTickets),
                for (final t in tickets)
                  Card(
                    child: ListTile(
                      title: Text(
                        '#${t['id']} · ${pickString(t, const ['subject']) ?? ''}',
                      ),
                      subtitle: Text(
                        '${statusWord(l, pickString(t, const ['status']))} · ${priorityWord(l, pickString(t, const ['priority']))}',
                      ),
                      onTap: () => open<void>(
                        context,
                        TicketDetailScreen(id: toNum(t['id'])!.toInt()),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Text(
                l.recentPayments,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (payments.isEmpty) Text(l.noPayments),
              for (final p in payments)
                Card(
                  child: ListTile(
                    title: Text(
                      '${pickString(p, const ['receipt_no']) ?? ''} · ${money(p['amount'])}',
                    ),
                    subtitle: Text(
                      '${methodWord(l, pickString(p, const ['method']))} · ${pickString(p, const ['date']) ?? ''} · ${statusWord(l, pickString(p, const ['approval_status']))}',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Quick add, as on the web: without a POP the client waits as pending.
class NewClientScreen extends ConsumerStatefulWidget {
  const NewClientScreen({super.key});

  @override
  ConsumerState<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends ConsumerState<NewClientScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int? _package;
  int? _pop;
  int? _router;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.newClient,
      body: Loader(
        load: (api) => api.get('/clients/form-options'),
        builder: (context, data, reload) {
          final packages = asList(data['packages']).map(asMap).toList();
          final pops = asList(data['pops']).map(asMap).toList();
          final routers = asList(
            asMap(
              pops.where((p) => toNum(p['id'])?.toInt() == _pop).firstOrNull,
            )['routers'],
          ).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _user,
                decoration: InputDecoration(labelText: l.pppoeUser),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                decoration: InputDecoration(labelText: l.pppoePassword),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _package,
                decoration: InputDecoration(labelText: l.package),
                items: [
                  for (final p in packages)
                    DropdownMenuItem(
                      value: toNum(p['id'])!.toInt(),
                      child: Text(
                        '${pickString(p, const ['name'])} (${money(p['price'])})',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _package = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l.nameOptional),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l.mobileOptional),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _pop,
                decoration: InputDecoration(labelText: l.popOptional),
                items: [
                  for (final p in pops)
                    DropdownMenuItem(
                      value: toNum(p['id'])!.toInt(),
                      child: Text(pickString(p, const ['name']) ?? ''),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _pop = v;
                  _router = null;
                }),
              ),
              if (routers.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _router,
                  decoration: InputDecoration(labelText: l.router),
                  items: [
                    for (final r in routers)
                      DropdownMenuItem(
                        value: toNum(r['id'])!.toInt(),
                        child: Text(pickString(r, const ['name']) ?? ''),
                      ),
                  ],
                  onChanged: (v) => setState(() => _router = v),
                ),
              ],
              const SizedBox(height: 8),
              MessageBanner(l.newClientHint),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        if (_user.text.trim().isEmpty ||
                            _pass.text.isEmpty ||
                            _package == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(l.fillAll)));
                          return;
                        }
                        setState(() => _busy = true);
                        final ok = await act(
                          context,
                          ref,
                          (api) => api.post('/clients', {
                            'pppoe_username': _user.text.trim(),
                            'pppoe_password': _pass.text,
                            'package_id': _package,
                            if (_name.text.trim().isNotEmpty)
                              'name': _name.text.trim(),
                            if (_phone.text.trim().isNotEmpty)
                              'phone': _phone.text.trim(),
                            'pop_id': ?_pop,
                            'router_id': ?_router,
                          }),
                          done: l.clientSaved,
                        );
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        if (ok != null) Navigator.pop(context);
                      },
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DueListScreen extends ConsumerStatefulWidget {
  const DueListScreen({super.key});

  @override
  ConsumerState<DueListScreen> createState() => _DueListScreenState();
}

class _DueListScreenState extends ConsumerState<DueListScreen> {
  String _q = '';
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));
    return WorkPage(
      title: l.featureDueList,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l.clientSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (v) => setState(() {
                _q = v.trim();
                _page = 1;
              }),
            ),
          ),
          Expanded(
            child: Loader(
              key: ValueKey('$_q|$_page'),
              load: (api) => api.get(
                '/due-list',
                query: {if (_q.length >= 2) 'q': _q, 'page': _page},
              ),
              builder: (context, data, reload) {
                final list = asList(data['clients']).map(asMap).toList();
                if (list.isEmpty) return EmptyList(l.noDues);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final c in list)
                      ClientRow(
                        c,
                        onTap: (user?.can('clients.view') ?? false)
                            ? () => open<void>(
                                context,
                                ClientDetailScreen(id: toNum(c['id'])!.toInt()),
                              )
                            : null,
                        trailing: pickString(c, const ['phone']) == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.call_outlined),
                                onPressed: () =>
                                    callPhone(pickString(c, const ['phone'])),
                              ),
                      ),
                    _Pager(
                      page: _page,
                      last: toNum(data['last_page'])?.toInt() ?? 1,
                      onPage: (p) => setState(() => _page = p),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// STF-08: quote first (what it costs, new expiry, wallet after), then
/// the web's RechargeClient once per request_key.
class RechargeScreen extends ConsumerStatefulWidget {
  const RechargeScreen({super.key, required this.client});
  final Json client;

  @override
  ConsumerState<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends ConsumerState<RechargeScreen> {
  int _months = 1;
  String? _method;
  final _remarks = TextEditingController();
  String _key = newRequestKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final id = widget.client['id'];
    return WorkPage(
      title:
          '${l.recharge} · ${pickString(widget.client, const ['name']) ?? ''}',
      body: Loader(
        key: ValueKey(_months),
        load: (api) =>
            api.get('/clients/$id/recharge-quote', query: {'months': _months}),
        builder: (context, q, reload) {
          final methods = asList(q['methods']).map(asMap).toList();
          final ids = methods
              .map((m) => pickString(m, const ['id']))
              .whereType<String>()
              .toList();
          if (_method == null || !ids.contains(_method)) {
            _method = ids.isEmpty ? null : ids.first;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (q['pending'] == true)
                MessageBanner(l.rechargePending, tone: BannerTone.warning),
              DropdownButtonFormField<int>(
                initialValue: _months,
                decoration: InputDecoration(labelText: l.months),
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(value: m, child: Text('$m')),
                ],
                onChanged: (v) => setState(() {
                  _months = v ?? 1;
                  _key = newRequestKey();
                }),
              ),
              const SizedBox(height: 12),
              SectionCard(
                children: [
                  InfoRow(l.amount, money(q['amount'])),
                  if ((toNum(q['upgrade_adjustment']) ?? 0) != 0)
                    InfoRow(l.adjustment, money(q['upgrade_adjustment'])),
                  InfoRow(l.payTotal, money(q['pay_total'])),
                  InfoRow(l.oldExpiry, pickString(q, const ['old_expiry'])),
                  InfoRow(l.newExpiry, pickString(q, const ['new_expiry'])),
                  if (q['wallet_charge'] != null) ...[
                    InfoRow(l.walletCharge, money(q['wallet_charge'])),
                    InfoRow(l.walletBalance, money(q['wallet_balance'])),
                    InfoRow(l.walletAfter, money(q['wallet_after'])),
                  ],
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(labelText: l.method),
                items: [
                  for (final m in methods)
                    DropdownMenuItem(
                      value: pickString(m, const ['id']),
                      child: Text(pickString(m, const ['label', 'id']) ?? ''),
                    ),
                ],
                onChanged: (v) => setState(() => _method = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarks,
                decoration: InputDecoration(labelText: l.noteOptional),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || q['pending'] == true || _method == null
                    ? null
                    : () async {
                        if (!await confirm(
                              context,
                              l.confirmRecharge(
                                money(q['pay_total']),
                                '$_months',
                              ),
                            ) ||
                            !context.mounted) {
                          return;
                        }
                        setState(() => _busy = true);
                        final res = await act(
                          context,
                          ref,
                          (api) => api.post('/clients/$id/recharge', {
                            'months': _months,
                            'method': _method,
                            if (_remarks.text.trim().isNotEmpty)
                              'remarks': _remarks.text.trim(),
                            'request_key': _key,
                          }),
                        );
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        if (res == null) return;
                        final after = asMap(res['client']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l.rechargeDone(
                                pickString(after, const ['expiry_date']) ?? '',
                              ),
                            ),
                          ),
                        );
                        Navigator.pop(context, true);
                      },
                child: Text(l.recharge),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ResellerWalletScreen extends ConsumerWidget {
  const ResellerWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureWallet,
      body: Loader(
        load: (api) => api.get('/reseller/wallet'),
        builder: (context, w, reload) {
          final tx = asList(w['transactions']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                children: [
                  InfoRow(l.walletBalance, money(w['balance'])),
                  InfoRow(l.creditLimit, money(w['credit_limit'])),
                  InfoRow(l.creditUsed, money(w['credit_used'])),
                  InfoRow(l.available, money(w['available'])),
                  InfoRow(
                    l.clientsAdvanceHeld,
                    money(w['clients_advance_held']),
                  ),
                ],
              ),
              if (w['credit_alert'] != null)
                MessageBanner(l.creditAlert, tone: BannerTone.warning),
              Text(
                l.transactions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final t in tx)
                Card(
                  child: ListTile(
                    title: Text(
                      '${money(t['amount'])} · ${pickString(t, const ['type']) ?? ''}',
                    ),
                    subtitle: Text(
                      [
                        pickString(t, const ['note']),
                        when(t['at']),
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: Text(money(t['balance_after'])),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ExpiringScreen extends ConsumerStatefulWidget {
  const ExpiringScreen({super.key});

  @override
  ConsumerState<ExpiringScreen> createState() => _ExpiringScreenState();
}

class _ExpiringScreenState extends ConsumerState<ExpiringScreen> {
  int _days = 3;
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureExpiring,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<int>(
              segments: [
                for (final d in const [0, 3, 7, 30])
                  ButtonSegment(value: d, label: Text(l.withinDays(d))),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
          ),
          Expanded(
            child: Loader(
              key: ValueKey('$_days|$_version'),
              load: (api) =>
                  api.get('/reseller/expiring', query: {'days': _days}),
              builder: (context, data, reload) {
                final list = asList(data['clients']).map(asMap).toList();
                if (list.isEmpty) return EmptyList(l.noExpiring);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final c in list)
                      ClientRow(
                        c,
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            if (await open<bool>(
                                  context,
                                  RechargeScreen(client: c),
                                ) ==
                                true) {
                              setState(() => _version++);
                            }
                          },
                          child: Text(l.recharge),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
