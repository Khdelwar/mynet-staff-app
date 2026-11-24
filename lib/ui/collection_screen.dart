import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final messenger = ScaffoldMessenger.of(context);
    final amount = TextEditingController();
    final note = TextEditingController();
    var owner = 'cash';
    String? receipt;
    String? problem;
    num? parsed;
    final key = newRequestKey();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(expense ? l.collectionExpense : l.collectionHandover),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (problem != null)
                  MessageBanner(problem!, tone: BannerTone.error),
                TextField(
                  key: const ValueKey('money-amount'),
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l.collectionAmount,
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('money-note'),
                  controller: note,
                  decoration: InputDecoration(labelText: l.collectionNote),
                ),
                const SizedBox(height: 8),
                // STF-06b: a photo of the receipt, for whoever approves it.
                if (expense)
                  TextButton.icon(
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
                if (!expense)
                  DropdownButton<String>(
                    key: const ValueKey('handover-owner'),
                    isExpanded: true,
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              key: const ValueKey('money-save'),
              onPressed: () {
                // Say what is missing here, instead of closing and doing nothing.
                final text = amount.text.trim();
                parsed = num.tryParse(text);
                final amountBad = expense
                    ? (parsed == null || parsed! <= 0)
                    : (text.isNotEmpty && (parsed == null || parsed! <= 0));
                if (amountBad) {
                  setLocal(() => problem = l.collectionEnterAmount);
                } else if (expense && note.text.trim().isEmpty) {
                  setLocal(() => problem = l.collectionEnterNote);
                } else {
                  Navigator.of(dialog).pop(true);
                }
              },
              child: Text(l.collectionSave),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) {
      amount.dispose();
      note.dispose();
      return;
    }
    try {
      if (expense) {
        await ref
            .read(apiProvider)
            .addExpense(
              amount: parsed!,
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
      messenger.showSnackBar(
        successSnack(
          expense ? l.collectionExpenseSaved : l.collectionHandoverSaved,
        ),
      );
      if (mounted) await _load();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(l, e, l.errGeneric))),
      );
    } finally {
      amount.dispose();
      note.dispose();
    }
  }

  Future<void> _openCollect({required bool cash}) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => CollectScreen(cash: cash)));
    // Back from taking money: show the new totals.
    if (mounted) await _load();
  }

  Widget _action({
    required String key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: filled
          ? FilledButton.icon(
              key: ValueKey(key),
              onPressed: onPressed,
              icon: Icon(icon),
              label: child,
            )
          : OutlinedButton.icon(
              key: ValueKey(key),
              onPressed: onPressed,
              icon: Icon(icon),
              label: child,
            ),
    );
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
                _action(
                  key: 'collect-cash',
                  icon: Icons.payments_outlined,
                  label: l.collectionCash,
                  filled: true,
                  onPressed: summary.holdBlocked
                      ? null
                      : () => _openCollect(cash: true),
                ),
              if (summary.canGateway)
                _action(
                  key: 'collect-gateway',
                  icon: Icons.phone_android_outlined,
                  label: l.collectionGateway,
                  onPressed: () => _openCollect(cash: false),
                ),
              if (summary.canExpense)
                _action(
                  key: 'collect-expense',
                  icon: Icons.receipt_long_outlined,
                  label: l.collectionExpense,
                  onPressed: () => _moneyDialog(expense: true),
                ),
              if (summary.canHandover)
                _action(
                  key: 'collect-handover',
                  icon: Icons.move_to_inbox_outlined,
                  label: l.collectionHandover,
                  onPressed: () => _moneyDialog(expense: false),
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
  Object? _searchError;
  Object? _error;
  String? _problem;
  bool _busy = false;
  bool _searching = false;
  bool _searched = false;
  Timer? _typing;

  @override
  void dispose() {
    _typing?.cancel();
    _search.dispose();
    _amount.dispose();
    _note.dispose();
    _txn.dispose();
    super.dispose();
  }

  Future<void> _findClients(
    Future<List<CollectionClient>> Function() fetch,
  ) async {
    setState(() {
      _searchError = null;
      _searching = true;
    });
    try {
      final clients = await fetch();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _searching = false;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = e;
      });
    }
  }

  Future<void> _searchClients() async {
    _typing?.cancel();
    final q = _search.text.trim();
    if (q.length < 2) return;
    await _findClients(() => ref.read(apiProvider).collectionClients(q));
  }

  /// "Near me with due": the phone's position, the ERP's list (nearest first).
  Future<void> _nearMe() async {
    final l = AppLocalizations.of(context);
    final fix = await ref.read(locationReaderProvider).current();
    if (!mounted) return;
    if (fix == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.collectionNoLocation)));
      return;
    }
    await _findClients(
      () => ref
          .read(apiProvider)
          .collectionClientsNear(
            latitude: fix.latitude,
            longitude: fix.longitude,
          ),
    );
  }

  void _pick(CollectionClient client) {
    setState(() {
      _picked = client;
      _problem = null;
      final due = client.due;
      if (_amount.text.trim().isEmpty && due != null && due > 0) {
        _amount.text = shownAmount(due);
      }
    });
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
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final client = _picked;
    final amount = num.tryParse(_amount.text.trim());
    // Never a silent no-op: say what is missing.
    final problem = client == null
        ? l.collectionPickClient
        : (amount == null || amount <= 0)
        ? l.collectionEnterAmount
        : (!widget.cash && _txn.text.trim().isEmpty)
        ? l.collectionEnterTxn
        : null;
    if (problem != null) {
      setState(() {
        _problem = problem;
        _error = null;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _problem = null;
    });
    try {
      final receipt = widget.cash
          ? await ref
                .read(apiProvider)
                .collectCash(
                  clientId: client!.id,
                  amount: amount!,
                  requestKey: _key,
                  note: _note.text,
                )
          : await ref
                .read(apiProvider)
                .collectGateway(
                  clientId: client!.id,
                  amount: amount!,
                  gateway: _gateway,
                  txnId: _txn.text.trim(),
                  requestKey: _key,
                  note: _note.text,
                );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _busy = false;
        _key = newRequestKey();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        successSnack(
          receipt.replayed ? l.collectionAlreadySaved : l.collectionSaved,
        ),
      );
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

  /// A fresh form for the next client.
  void _another() {
    setState(() {
      _receipt = null;
      _picked = null;
      _clients = const [];
      _searched = false;
      _error = null;
      _problem = null;
      _search.clear();
      _amount.clear();
      _note.clear();
      _txn.clear();
    });
  }

  final _receiptKey = GlobalKey();

  Future<void> _shareReceipt(PaymentReceipt receipt) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    try {
      final boundary =
          _receiptKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('no image');
      await ref
          .read(imageSharerProvider)
          .sharePng(
            data.buffer.asUint8List(),
            name: receipt.receiptNo ?? 'receipt',
            text: '${l.collectionReceipt} ${receipt.receiptNo ?? ''}'.trim(),
          );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errGeneric)));
    }
  }

  String? _status(AppLocalizations l, String? raw) => switch (raw) {
    'pending' => l.collectionStatusPending,
    'approved' => l.collectionStatusApproved,
    _ => raw,
  };

  List<Widget> _receiptView(AppLocalizations l, PaymentReceipt receipt) => [
    MessageBanner(
      receipt.replayed ? l.collectionAlreadySaved : l.collectionSaved,
      tone: BannerTone.success,
    ),
    // STF-10: the receipt is drawn here and shared as a picture
    // (WhatsApp etc.); every value on it is the ERP's.
    RepaintBoundary(
      key: _receiptKey,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SectionCard(
          // The receipt goes to the client: show the ISP's own name.
          title:
              ref.watch(authProvider.select((a) => a.user?.companyName)) ??
              l.appTitle,
          children: [
            InfoRow(l.collectionReceipt, receipt.receiptNo),
            if (receipt.clientName != null)
              InfoRow(l.supportClient, receipt.clientName),
            InfoRow(l.collectionAmount, '৳ ${shownAmount(receipt.amount)}'),
            if (receipt.method != null) InfoRow(l.workMethod, receipt.method),
            InfoRow(l.collectionApproval, _status(l, receipt.approvalStatus)),
            InfoRow(
              l.collectionPaidSms,
              receipt.paidSms == 'after_approval'
                  ? l.collectionSmsLater
                  : receipt.paidSms,
            ),
          ],
        ),
      ),
    ),
    FilledButton.icon(
      key: const ValueKey('share-receipt'),
      onPressed: () => _shareReceipt(receipt),
      icon: const Icon(Icons.share_outlined),
      label: Text(l.collectionShareReceipt),
    ),
    const SizedBox(height: 8),
    OutlinedButton.icon(
      key: const ValueKey('collect-another'),
      onPressed: _another,
      icon: const Icon(Icons.add),
      label: Text(l.collectionAnother),
    ),
    TextButton(
      key: const ValueKey('collect-done'),
      onPressed: () => Navigator.of(context).maybePop(),
      child: Text(l.collectionDone),
    ),
  ];

  Widget _pickedCard(AppLocalizations l, CollectionClient client) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('collect-picked'),
      color: scheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: scheme.primary),
        title: Text(client.name ?? '—'),
        subtitle: Text(
          [
            client.code,
            if (client.due != null)
              '${l.collectionDue} ৳ ${shownAmount(client.due)}',
          ].whereType<String>().join(' · '),
        ),
        trailing: TextButton(
          key: const ValueKey('collect-change-client'),
          onPressed: () => setState(() => _picked = null),
          child: Text(l.collectionChange),
        ),
      ),
    );
  }

  List<Widget> _clientPicker(AppLocalizations l) => [
    TextField(
      key: const ValueKey('collect-search'),
      controller: _search,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: l.collectionSearch,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          key: const ValueKey('collect-search-go'),
          tooltip: l.collectionFind,
          icon: const Icon(Icons.search),
          onPressed: _searchClients,
        ),
      ),
      // As the web: results follow the typing.
      onChanged: (text) {
        _typing?.cancel();
        if (text.trim().length < 2) return;
        _typing = Timer(const Duration(milliseconds: 350), _searchClients);
      },
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
    if (_searchError != null)
      MessageBanner(
        errorText(l, _searchError!, l.errGeneric),
        tone: BannerTone.error,
      ),
    if (_searching)
      const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      )
    else if (_searched && _clients.isEmpty)
      MessageBanner(l.collectionNoClients),
    for (final client in _clients)
      Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          key: ValueKey('pay-client-${client.id}'),
          leading: const Icon(Icons.person_outline),
          title: Text(client.name ?? '—'),
          subtitle: Text(
            [
              client.code,
              if (client.due != null)
                '${l.collectionDue} ৳ ${shownAmount(client.due)}',
              if (client.distanceM != null)
                l.collectionMetres(client.distanceM!.round()),
            ].whereType<String>().join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pick(client),
        ),
      ),
    const SizedBox(height: 8),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final receipt = _receipt;
    final picked = _picked;
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cash ? l.collectionCash : l.collectionGateway),
      ),
      body: ListView(
        key: const ValueKey('collect'),
        padding: const EdgeInsets.all(16),
        children: [
          if (receipt != null)
            ..._receiptView(l, receipt)
          else ...[
            if (picked != null) _pickedCard(l, picked) else ..._clientPicker(l),
            TextField(
              key: const ValueKey('collect-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.collectionAmount,
                prefixText: '৳ ',
                border: const OutlineInputBorder(),
              ),
            ),
            if (!widget.cash) ...[
              gap,
              DropdownButtonFormField<String>(
                key: const ValueKey('collect-gateway-pick'),
                initialValue: _gateway,
                decoration: const InputDecoration(border: OutlineInputBorder()),
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
              gap,
              TextField(
                key: const ValueKey('collect-txn'),
                controller: _txn,
                decoration: InputDecoration(
                  labelText: l.collectionTxn,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            gap,
            TextField(
              key: const ValueKey('collect-note'),
              controller: _note,
              decoration: InputDecoration(
                labelText: l.collectionNote,
                border: const OutlineInputBorder(),
              ),
            ),
            gap,
            // Problems sit right above the button, where the eye already is.
            if (_problem != null)
              MessageBanner(
                _problem!,
                key: const ValueKey('collect-problem'),
                tone: BannerTone.error,
              ),
            if (_error != null)
              MessageBanner(
                errorText(l, _error!, l.errGeneric),
                tone: BannerTone.error,
              ),
            FilledButton.icon(
              key: const ValueKey('collect-submit'),
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _busy ? l.collectionSaving : l.collectionSave,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
