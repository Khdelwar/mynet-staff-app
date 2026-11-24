import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/collection.dart';
import '../api/staff_api.dart';
import '../field/photos.dart';
import '../l10n/app_localizations.dart';
import '../state/field.dart';
import '../state/providers.dart';
import 'approvals_screen.dart';
import 'common.dart';

String shownAmount(num? value) {
  if (value == null) return '—';
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  CollectionSummary? _summary;
  Object? _error;
  bool _loading = true;

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
      final summary = await ref.read(apiProvider).collectionSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  Future<void> _moneyDialog({required bool expense}) async {
    final l = AppLocalizations.of(context);
    final amount = TextEditingController();
    final note = TextEditingController();
    var owner = 'cash';
    String? receipt;
    final key = newRequestKey();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(expense ? l.collectionExpense : l.collectionHandover),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('money-amount'),
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.collectionAmount),
            ),
            TextField(
              key: const ValueKey('money-note'),
              controller: note,
              decoration: InputDecoration(labelText: l.collectionNote),
            ),
            // STF-06b: a photo of the receipt, for whoever approves it.
            if (expense)
              StatefulBuilder(
                builder: (context, setLocal) => TextButton.icon(
                  key: const ValueKey('expense-receipt'),
                  onPressed: () async {
                    final path = await ref
                        .read(photoPickerProvider)
                        .pick(PhotoSource.camera);
                    if (path != null) setLocal(() => receipt = path);
                  },
                  icon: Icon(
                    receipt == null
                        ? Icons.add_a_photo_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    receipt == null ? l.workReceiptPhoto : l.workReceiptAdded,
                  ),
                ),
              ),
            if (!expense)
              StatefulBuilder(
                builder: (context, setLocal) => DropdownButton<String>(
                  key: const ValueKey('handover-owner'),
                  value: owner,
                  items: [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text(l.collectionCashOwner),
                    ),
                    DropdownMenuItem(
                      value: 'digital',
                      child: Text(l.collectionDigitalOwner),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setLocal(() => owner = value);
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('money-save'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.collectionSave),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      amount.dispose();
      note.dispose();
      return;
    }
    final parsed = num.tryParse(amount.text.trim());
    try {
      if (expense) {
        if (parsed == null || note.text.trim().isEmpty) return;
        await ref
            .read(apiProvider)
            .addExpense(
              amount: parsed,
              note: note.text,
              requestKey: key,
              receiptPath: receipt,
            );
      } else {
        await ref
            .read(apiProvider)
            .handover(
              owner: owner,
              requestKey: key,
              amount: parsed,
              note: note.text,
            );
      }
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(l, e, l.errGeneric))));
    } finally {
      amount.dispose();
      note.dispose();
    }
  }

  void _openCollect({required bool cash}) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => CollectScreen(cash: cash)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final summary = _summary;
    final user = ref.watch(authProvider.select((a) => a.user));
    final canApprove =
        user != null &&
        (user.can('collection.approve') ||
            user.can('approvals.cash') ||
            user.can('approvals.collections') ||
            user.can('ledger.approve'));
    return Scaffold(
      appBar: AppBar(title: Text(l.featureCollection)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('collection'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              MessageBanner(
                errorText(l, _error!, l.errGeneric),
                tone: BannerTone.error,
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (summary != null) ...[
              if (summary.holdBlocked)
                MessageBanner(
                  summary.holdMessage ?? l.collectionHold,
                  tone: BannerTone.warning,
                ),
              SectionCard(
                children: [
                  InfoRow(
                    l.collectionToday,
                    shownAmount(summary.collectedToday),
                  ),
                  InfoRow(l.collectionInHand, shownAmount(summary.inHand)),
                  InfoRow(
                    l.collectionNotHanded,
                    shownAmount(summary.notHandedOver),
                  ),
                  InfoRow(
                    l.collectionExpenseLeft,
                    shownAmount(summary.expenseAvailable),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (summary.canCash)
                FilledButton(
                  key: const ValueKey('collect-cash'),
                  onPressed: summary.holdBlocked
                      ? null
                      : () => _openCollect(cash: true),
                  child: Text(l.collectionCash),
                ),
              if (summary.canGateway)
                OutlinedButton(
                  key: const ValueKey('collect-gateway'),
                  onPressed: () => _openCollect(cash: false),
                  child: Text(l.collectionGateway),
                ),
              if (summary.canExpense)
                OutlinedButton(
                  key: const ValueKey('collect-expense'),
                  onPressed: () => _moneyDialog(expense: true),
                  child: Text(l.collectionExpense),
                ),
              if (summary.canHandover)
                OutlinedButton(
                  key: const ValueKey('collect-handover'),
                  onPressed: () => _moneyDialog(expense: false),
                  child: Text(l.collectionHandover),
                ),
              if (canApprove)
                TextButton(
                  key: const ValueKey('open-approvals'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ApprovalsScreen(),
                    ),
                  ),
                  child: Text(l.featureApprovals),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class CollectScreen extends ConsumerStatefulWidget {
  const CollectScreen({super.key, required this.cash});

  final bool cash;

  @override
  ConsumerState<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends ConsumerState<CollectScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _txn = TextEditingController();
  String _gateway = 'bkash';
  String _key = newRequestKey();
  List<CollectionClient> _clients = const [];
  CollectionClient? _picked;
  PaymentReceipt? _receipt;
  Object? _error;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    _amount.dispose();
    _note.dispose();
    _txn.dispose();
    super.dispose();
  }

  Future<void> _searchClients() async {
    final q = _search.text.trim();
    if (q.length < 2) return;
    setState(() => _error = null);
    try {
      final clients = await ref.read(apiProvider).collectionClients(q);
      if (!mounted) return;
      setState(() => _clients = clients);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  /// "Near me with due": the phone's position, the ERP's list (nearest first).
  Future<void> _nearMe() async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    final fix = await ref.read(locationReaderProvider).current();
    if (!mounted) return;
    if (fix == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.collectionNoLocation)));
      return;
    }
    try {
      final clients = await ref
          .read(apiProvider)
          .collectionClientsNear(
            latitude: fix.latitude,
            longitude: fix.longitude,
          );
      if (!mounted) return;
      setState(() => _clients = clients);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  /// The ERP shows due (and the near-me list) only with these rights.
  bool get _canSeeDue {
    final user = ref.watch(authProvider.select((a) => a.user));
    return user != null &&
        const [
          'clients.view',
          'billing.due_list',
          'billing.view',
          'billing.collect',
        ].any(user.can);
  }

  Future<void> _submit() async {
    final client = _picked;
    final amount = num.tryParse(_amount.text.trim());
    if (client == null || amount == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = widget.cash
          ? await ref
                .read(apiProvider)
                .collectCash(
                  clientId: client.id,
                  amount: amount,
                  requestKey: _key,
                  note: _note.text,
                )
          : await ref
                .read(apiProvider)
                .collectGateway(
                  clientId: client.id,
                  amount: amount,
                  gateway: _gateway,
                  txnId: _txn.text,
                  requestKey: _key,
                  note: _note.text,
                );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _busy = false;
        _key = newRequestKey();
      });
    } on ApiException catch (e) {
      if (e.code == 'key_reused') _key = newRequestKey();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final receipt = _receipt;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cash ? l.collectionCash : l.collectionGateway),
      ),
      body: ListView(
        key: const ValueKey('collect'),
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            MessageBanner(
              errorText(l, _error!, l.errGeneric),
              tone: BannerTone.error,
            ),
          if (receipt != null)
            SectionCard(
              children: [
                InfoRow(l.collectionReceipt, receipt.receiptNo),
                InfoRow(l.collectionAmount, shownAmount(receipt.amount)),
                InfoRow(l.collectionApproval, receipt.approvalStatus),
                InfoRow(
                  l.collectionPaidSms,
                  receipt.paidSms == 'after_approval'
                      ? l.collectionSmsLater
                      : receipt.paidSms,
                ),
              ],
            )
          else ...[
            TextField(
              key: const ValueKey('collect-search'),
              controller: _search,
              decoration: InputDecoration(labelText: l.collectionSearch),
              onSubmitted: (_) => _searchClients(),
            ),
            if (_canSeeDue)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('collect-near-me'),
                  onPressed: _nearMe,
                  icon: const Icon(Icons.near_me_outlined),
                  label: Text(l.collectionNearMe),
                ),
              ),
            for (final client in _clients)
              ListTile(
                key: ValueKey('pay-client-${client.id}'),
                title: Text(client.name ?? '—'),
                subtitle: Text(
                  [
                    client.code,
                    if (client.due != null) shownAmount(client.due),
                    if (client.distanceM != null)
                      l.collectionMetres(client.distanceM!.round()),
                  ].whereType<String>().join(' · '),
                ),
                selected: _picked?.id == client.id,
                onTap: () => setState(() => _picked = client),
              ),
            TextField(
              key: const ValueKey('collect-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.collectionAmount),
            ),
            if (!widget.cash) ...[
              DropdownButton<String>(
                key: const ValueKey('collect-gateway-pick'),
                value: _gateway,
                items: const [
                  DropdownMenuItem(value: 'bkash', child: Text('bKash')),
                  DropdownMenuItem(value: 'nagad', child: Text('Nagad')),
                  DropdownMenuItem(value: 'rocket', child: Text('Rocket')),
                  DropdownMenuItem(value: 'upay', child: Text('Upay')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _gateway = value);
                },
              ),
              TextField(
                key: const ValueKey('collect-txn'),
                controller: _txn,
                decoration: InputDecoration(labelText: l.collectionTxn),
              ),
            ],
            TextField(
              key: const ValueKey('collect-note'),
              controller: _note,
              decoration: InputDecoration(labelText: l.collectionNote),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('collect-submit'),
              onPressed: _busy ? null : _submit,
              child: Text(l.collectionSave),
            ),
          ],
        ],
      ),
    );
  }
}
