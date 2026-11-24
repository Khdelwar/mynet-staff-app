import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../api/request_key.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';
import 'kit.dart';
import 'words.dart';

/// STF-06: bill collection. Every amount here is the ERP's (CollectionBook);
/// cash a collector takes waits for the owner (R4) and the client's "paid"
/// SMS goes only after approval (R7). Every money request carries a
/// request_key that is kept while retrying, so a payment is never taken twice.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  int _version = 0;

  void _reload() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureCollection,
      body: Loader(
        key: ValueKey(_version),
        load: (api) => api.get('/collection/summary'),
        builder: (context, data, reload) {
          final can = asMap(data['can']);
          final hold = asMap(data['hold']);
          final owners = asMap(data['owners']);
          final waiting = asList(data['waiting_handovers']).map(asMap).toList();
          final expenses = asList(data['my_expenses']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                children: [
                  InfoRow(l.collectedToday, money(data['collected_today'])),
                  InfoRow(l.inHand, money(data['in_hand'])),
                  InfoRow(l.handoverDue, money(data['handover_due'])),
                  InfoRow(l.expenseAvailable, money(data['expense_available'])),
                ],
              ),
              if (hold['blocked'] == true)
                MessageBanner(
                  pickString(hold, const ['message']) ?? l.holdBlocked,
                  tone: BannerTone.warning,
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (can['cash'] == true)
                    FilledButton.icon(
                      onPressed: () async {
                        if (await open<bool>(
                              context,
                              const PaymentForm(gateway: false),
                            ) ==
                            true) {
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(l.takeCash),
                    ),
                  if (can['gateway'] == true)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        if (await open<bool>(
                              context,
                              const PaymentForm(gateway: true),
                            ) ==
                            true) {
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.phone_android),
                      label: Text(l.takeTrx),
                    ),
                  if (can['expense'] == true)
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (await open<bool>(context, const ExpenseForm()) ==
                            true) {
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: Text(l.addExpense),
                    ),
                  if (can['handover'] == true)
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (await open<bool>(
                              context,
                              HandoverForm(
                                owners: owners,
                                due: data['handover_due'],
                              ),
                            ) ==
                            true) {
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.outbox_outlined),
                      label: Text(l.dayEndHandover),
                    ),
                ],
              ),
              if (waiting.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l.waitingHandovers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final h in waiting)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${money(h['amount'])} → ${pickString(h, const ['recipient']) ?? ''}',
                      ),
                      subtitle: Text(
                        '${statusWord(l, pickString(h, const ['status']))} · ${when(h['submitted_at'])}',
                      ),
                    ),
                  ),
              ],
              if (expenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l.myExpenses,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final e in expenses) ExpenseTile(e),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ExpenseTile extends ConsumerWidget {
  const ExpenseTile(this.e, {super.key, this.trailing});
  final Json e;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final receipt = pickString(e, const ['receipt_url']);
    return Card(
      child: ListTile(
        title: Text(
          '${money(e['amount'])} · ${pickString(e, const ['note']) ?? ''}',
        ),
        subtitle: Text(
          [
            pickString(asMap(e['collector']), const ['name']),
            statusWord(l, pickString(e, const ['status'])),
            pickString(e, const ['date']),
            pickString(e, const ['decision_note']),
          ].whereType<String>().join(' · '),
        ),
        leading: receipt == null
            ? null
            : IconButton(
                tooltip: l.receiptPhoto,
                icon: const Icon(Icons.image_outlined),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialog) => Dialog(
                    child: InteractiveViewer(
                      child: Image.network(
                        receipt,
                        headers: ref.read(apiProvider).imageHeaders,
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l.receiptNotImage),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        trailing: trailing,
      ),
    );
  }
}

/// Cash, or a bKash / Nagad … TrxID the client paid to the office number.
class PaymentForm extends ConsumerStatefulWidget {
  const PaymentForm({super.key, required this.gateway, this.client});
  final bool gateway;
  final Json? client;

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  late Json? _client = widget.client;
  final _amount = TextEditingController();
  final _trx = TextEditingController();
  final _note = TextEditingController();
  String _gateway = 'bkash';
  // Kept until saved: a retry after a timeout sends the same key.
  String _key = newRequestKey();
  bool _busy = false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final amount = toNum(_amount.text);
    if (_client == null ||
        amount == null ||
        amount <= 0 ||
        (widget.gateway && _trx.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fillAll)));
      return;
    }
    if (!await confirm(
          context,
          l.confirmTake(
            money(amount),
            pickString(_client, const ['name']) ?? '',
          ),
        ) ||
        !mounted) {
      return;
    }
    setState(() => _busy = true);
    final res = await act(
      context,
      ref,
      (api) => api.post(
        widget.gateway ? '/collection/gateway' : '/collection/cash',
        {
          'client_id': _client!['id'],
          'amount': amount,
          if (widget.gateway) 'gateway': _gateway,
          if (widget.gateway) 'txn_id': _trx.text.trim(),
          if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
          'request_key': _key,
        },
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res == null) return;
    _key = newRequestKey();
    await showDialog<void>(
      context: context,
      builder: (_) => ReceiptDialog(
        asMap(res['payment']),
        replayed: res['replayed'] == true,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: widget.gateway ? l.takeTrx : l.takeCash,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                _client == null
                    ? l.pickClient
                    : '${pickString(_client, const ['name'])} · ${pickString(_client, const ['code'])}',
              ),
              subtitle: _client?['due'] != null
                  ? Text('${l.due}: ${money(_client!['due'])}')
                  : null,
              trailing: const Icon(Icons.search),
              onTap: () async {
                final c = await pickClient(
                  context,
                  path: '/collection/clients',
                );
                if (c != null) setState(() => _client = c);
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.amount, prefixText: '৳ '),
          ),
          if (widget.gateway) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gateway,
              decoration: InputDecoration(labelText: l.gateway),
              items: [
                for (final g in const ['bkash', 'nagad', 'rocket', 'upay'])
                  DropdownMenuItem(value: g, child: Text(methodWord(l, g))),
              ],
              onChanged: (v) => setState(() => _gateway = v ?? _gateway),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trx,
              decoration: InputDecoration(labelText: l.trxId),
            ),
            const SizedBox(height: 8),
            MessageBanner(l.trxHint),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.noteOptional),
          ),
          const SizedBox(height: 8),
          if (!widget.gateway) MessageBanner(l.cashHint),
          FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
        ],
      ),
    );
  }
}

/// The receipt the ERP returned (R-number); the collector shows it to the client.
class ReceiptDialog extends StatelessWidget {
  const ReceiptDialog(this.p, {super.key, this.replayed = false});
  final Json p;
  final bool replayed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final client = asMap(p['client']);
    return AlertDialog(
      title: Text('${l.receipt} ${pickString(p, const ['receipt_no']) ?? ''}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replayed) MessageBanner(l.alreadySaved, tone: BannerTone.warning),
          InfoRow(
            l.client,
            '${pickString(client, const ['name']) ?? ''} · ${pickString(client, const ['code']) ?? ''}',
          ),
          InfoRow(l.amount, money(p['amount'])),
          InfoRow(l.method, methodWord(l, pickString(p, const ['method']))),
          InfoRow(l.date, pickString(p, const ['date'])),
          InfoRow(l.newExpiry, pickString(p, const ['new_expiry'])),
          InfoRow(l.collectedBy, pickString(p, const ['collected_by'])),
          const SizedBox(height: 8),
          Text(
            l.waitsForApproval,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.ok)),
      ],
    );
  }
}

/// A field expense: always waits for someone else's approval (R12).
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({super.key});

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final String _key = newRequestKey();
  String? _photo;
  bool _busy = false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final amount = toNum(_amount.text);
    if (amount == null || amount <= 0 || _note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fillAll)));
      return;
    }
    setState(() => _busy = true);
    final ok = await act(
      context,
      ref,
      (api) => api.postFiles(
        '/collection/expenses',
        {'amount': amount, 'note': _note.text.trim(), 'request_key': _key},
        files: {
          if (_photo != null) 'receipt': [_photo!],
        },
      ),
      done: l.expenseSaved,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.addExpense,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.amount, prefixText: '৳ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.whatFor),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final p = await pickPhotos(context, max: 1);
              if (p.isNotEmpty) setState(() => _photo = p.first);
            },
            icon: Icon(
              _photo == null
                  ? Icons.add_a_photo_outlined
                  : Icons.check_circle_outline,
            ),
            label: Text(_photo == null ? l.receiptPhoto : l.receiptPhotoAdded),
          ),
          const SizedBox(height: 8),
          MessageBanner(l.expenseHint),
          FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
        ],
      ),
    );
  }
}

/// Day end: the net goes to the owner the user picks (R3).
class HandoverForm extends ConsumerStatefulWidget {
  const HandoverForm({super.key, required this.owners, required this.due});
  final Json owners;
  final Object? due;

  @override
  ConsumerState<HandoverForm> createState() => _HandoverFormState();
}

class _HandoverFormState extends ConsumerState<HandoverForm> {
  String _owner = 'cash';
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final String _key = newRequestKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.dayEndHandover,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoRow(l.handoverDue, money(widget.due)),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _owner,
            onChanged: (v) => setState(() => _owner = v ?? _owner),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'cash',
                  title: Text(
                    '${l.ownerCash}: ${pickString(widget.owners, const ['cash']) ?? '—'}',
                  ),
                ),
                RadioListTile<String>(
                  value: 'digital',
                  title: Text(
                    '${l.ownerDigital}: ${pickString(widget.owners, const ['digital']) ?? '—'}',
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.amountPartOptional,
              prefixText: '৳ ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.noteOptional),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final ok = await act(
                      context,
                      ref,
                      (api) => api.post('/collection/handover', {
                        'owner': _owner,
                        if (toNum(_amount.text) != null)
                          'amount': toNum(_amount.text),
                        if (_note.text.trim().isNotEmpty)
                          'note': _note.text.trim(),
                        'request_key': _key,
                      }),
                      done: l.handoverSent,
                    );
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (ok != null) Navigator.pop(context, true);
                  },
            child: Text(l.send),
          ),
        ],
      ),
    );
  }
}

/// Handovers sent to this user as owner, and other people's expenses.
/// Never one's own (R5): the ERP leaves them out.
class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureApprovals,
      body: Loader(
        load: (api) => api.get('/collection/approvals'),
        builder: (context, data, reload) {
          final handovers = asList(data['handovers']).map(asMap).toList();
          final expenses = asList(data['expenses']).map(asMap).toList();
          if (handovers.isEmpty && expenses.isEmpty) {
            return EmptyList(l.nothingToApprove);
          }

          Future<void> decide(
            String path, {
            bool amount = false,
            bool noteRequired = false,
            Object? full,
          }) async {
            String? value;
            if (amount) {
              value = await askText(
                context,
                title: l.acceptAmount,
                label: l.amount,
                initial: plainNumber(full).replaceAll(',', ''),
                number: true,
                required: true,
              );
              if (value == null || !context.mounted) return;
            }
            final note = await askText(
              context,
              title: l.note,
              label: noteRequired ? l.noteRequired : l.noteOptional,
              required: noteRequired,
            );
            if (note == null || !context.mounted) return;
            final ok = await act(
              context,
              ref,
              (api) => api.post(path, {
                if (value != null) 'amount': toNum(value),
                if (note.isNotEmpty) 'note': note,
              }),
              done: l.saved,
            );
            if (ok != null) await reload();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (handovers.isNotEmpty)
                Text(
                  l.handovers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              for (final h in handovers)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${pickString(asMap(h['collector']), const ['name']) ?? ''} · ${money(h['amount'])}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        InfoRow(l.collected, money(h['collected'])),
                        InfoRow(l.sales, money(h['sales'])),
                        InfoRow(l.expenses, money(h['expenses'])),
                        if (pickString(h, const ['note']) != null)
                          Text(pickString(h, const ['note'])!),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => decide(
                                  '/collection/handovers/${h['id']}/approve',
                                  amount: true,
                                  full: h['amount'],
                                ),
                                child: Text(l.approve),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => decide(
                                  '/collection/handovers/${h['id']}/reject',
                                  noteRequired: true,
                                ),
                                child: Text(l.reject),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (expenses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l.expenses,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              for (final e in expenses)
                Column(
                  children: [
                    ExpenseTile(e),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => decide(
                              '/collection/expenses/${e['id']}/approve',
                            ),
                            child: Text(l.approve),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => decide(
                              '/collection/expenses/${e['id']}/reject',
                              noteRequired: true,
                            ),
                            child: Text(l.reject),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// STF-06b: sell a product by scanning its code (the web's My stock "Sell").
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureSales,
      fab: FloatingActionButton.extended(
        onPressed: () async {
          final api = ref.read(apiProvider);
          final code = await askText(
            context,
            title: l.scanItem,
            label: l.scanCodeHint,
            required: true,
          );
          if (code == null || !context.mounted) return;
          final found = await act(
            context,
            ref,
            (_) => api.post('/sales/scan', {'code': code}),
          );
          if (found == null || !context.mounted) return;
          final list = await api
              .get('/sales')
              .catchError((_) => <String, dynamic>{});
          if (!context.mounted) return;
          final sold = await open<bool>(
            context,
            SellForm(
              found: asMap(found['found']),
              methods: asList(list['digital_methods'])
                  .whereType<String>()
                  .toList(),
            ),
          );
          if (sold == true) setState(() => _version++);
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l.sell),
      ),
      body: Loader(
        key: ValueKey(_version),
        load: (api) => api.get('/sales'),
        builder: (context, data, reload) {
          final awaiting = asList(data['awaiting_client']).map(asMap).toList();
          final recent = asList(data['recent']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              if (awaiting.isNotEmpty) ...[
                Text(
                  l.awaitingClientId,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final s in awaiting)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${pickString(s, const ['name']) ?? ''} · ${money(s['price'])}',
                      ),
                      subtitle: Text(
                        methodWord(l, pickString(s, const ['payment'])),
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () async {
                          final c = await pickClient(context);
                          if (c == null || !context.mounted) return;
                          final ok = await act(
                            context,
                            ref,
                            (api) => api.post('/sales/${s['id']}/client', {
                              'client_id': c['id'],
                            }),
                            done: l.saved,
                          );
                          if (ok != null) await reload();
                        },
                        child: Text(l.giveClientId),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              Text(
                l.recentSales,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (recent.isEmpty) MessageBanner(l.noSales),
              for (final s in recent)
                Card(
                  child: ListTile(
                    title: Text(
                      '${pickString(s, const ['name']) ?? ''} · ${money(s['price'])}',
                    ),
                    subtitle: Text(
                      [
                        methodWord(
                          l,
                          pickString(s, const ['payment_method', 'payment']),
                        ),
                        statusWord(l, pickString(s, const ['status'])),
                        pickString(asMap(s['client']), const ['code']),
                        when(s['at']),
                      ].whereType<String>().join(' · '),
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

class SellForm extends ConsumerStatefulWidget {
  const SellForm({super.key, required this.found, required this.methods});
  final Json found;
  final List<String> methods;

  @override
  ConsumerState<SellForm> createState() => _SellFormState();
}

class _SellFormState extends ConsumerState<SellForm> {
  final _price = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _note = TextEditingController();
  String _payment = 'cash';
  String? _method;
  Json? _client;
  bool _newConnection = false;
  final String _key = newRequestKey();
  bool _busy = false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final price = toNum(_price.text);
    if (price == null ||
        price <= 0 ||
        (_client == null && !_newConnection) ||
        (_payment == 'digital' && _method == null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fillAll)));
      return;
    }
    setState(() => _busy = true);
    final res = await act(
      context,
      ref,
      (api) => api.post('/sales', {
        'code': widget.found['code'],
        if (widget.found['kind'] == 'part') 'quantity': toNum(_qty.text) ?? 1,
        'price': price,
        'payment': _payment,
        if (_payment == 'digital') 'payment_method': _method,
        if (_newConnection)
          'new_connection': true
        else
          'client_id': _client!['id'],
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
        'request_key': _key,
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res == null) return;
    final sale = asMap(res['sale']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sale['cash_to_handover'] == true ? l.soldCashToHandover : l.sold,
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = widget.found;
    return WorkPage(
      title: l.sell,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            children: [
              Text(
                pickString(f, const ['name']) ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (f['kind'] == 'part')
                InfoRow(
                  l.inStock,
                  '${plainNumber(f['in_stock'])} ${pickString(f, const ['unit']) ?? ''}',
                ),
            ],
          ),
          if (f['kind'] == 'part') ...[
            TextField(
              controller: _qty,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l.quantity),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.price, prefixText: '৳ '),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'cash', label: Text(l.payCash)),
              ButtonSegment(value: 'due', label: Text(l.payDue)),
              ButtonSegment(value: 'digital', label: Text(l.payDigital)),
            ],
            selected: {_payment},
            onSelectionChanged: (s) => setState(() => _payment = s.first),
          ),
          if (_payment == 'digital') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(labelText: l.gateway),
              items: [
                for (final m in widget.methods)
                  DropdownMenuItem(value: m, child: Text(methodWord(l, m))),
              ],
              onChanged: (v) => setState(() => _method = v),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            value: _newConnection,
            onChanged: (v) => setState(() => _newConnection = v),
            title: Text(l.forNewConnection),
            subtitle: Text(l.forNewConnectionHint),
          ),
          if (!_newConnection)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  _client == null
                      ? l.pickClient
                      : '${pickString(_client, const ['name'])} · ${pickString(_client, const ['code'])}',
                ),
                trailing: const Icon(Icons.search),
                onTap: () async {
                  final c = await pickClient(context);
                  if (c != null) setState(() => _client = c);
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.noteOptional),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: Text(l.sell)),
        ],
      ),
    );
  }
}

/// STF-04: duty on / off. Location is asked once at start and end; the ERP
/// refuses outside duty hours.
class DutyScreen extends ConsumerStatefulWidget {
  const DutyScreen({super.key});

  @override
  ConsumerState<DutyScreen> createState() => _DutyScreenState();
}

class _DutyScreenState extends ConsumerState<DutyScreen> {
  int _version = 0;

  Future<void> _toggle(bool start) async {
    final l = AppLocalizations.of(context);
    final p = await ref.read(locatorProvider)();
    if (!mounted) return;
    final ok = await act(
      context,
      ref,
      (api) => api.post(start ? '/duty/start' : '/duty/end', {
        if (p != null) 'latitude': p.latitude,
        if (p != null) 'longitude': p.longitude,
      }),
      done: start ? l.dutyStarted : l.dutyEnded,
    );
    if (ok != null) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureDuty,
      body: Loader(
        key: ValueKey(_version),
        load: (api) => api.get('/duty'),
        builder: (context, data, reload) {
          final on = data['on_duty'] == true;
          final session = asMap(data['session']);
          final tracking = asMap(data['tracking']);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                children: [
                  InfoRow(l.dutyStatus, on ? l.onDuty : l.offDuty),
                  if (on) InfoRow(l.startedAt, when(session['started_at'])),
                  if (on && session['distance_m'] != null)
                    InfoRow(
                      l.distance,
                      '${(toNum(session['distance_m'])! / 1000).toStringAsFixed(1)} km',
                    ),
                  InfoRow(
                    l.dutyHours,
                    '${pickString(tracking, const ['duty_start']) ?? ''} – ${pickString(tracking, const ['duty_end']) ?? ''}',
                  ),
                ],
              ),
              if (data['within_duty_hours'] == false && !on)
                MessageBanner(l.outsideDutyHours, tone: BannerTone.warning),
              MessageBanner(l.dutyLocationHint),
              FilledButton.icon(
                onPressed: () => _toggle(!on),
                icon: Icon(
                  on ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                ),
                label: Text(on ? l.endDuty : l.startDuty),
              ),
            ],
          );
        },
      ),
    );
  }
}
