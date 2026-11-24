import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/collection.dart';
import '../api/staff_api.dart';
import '../api/work.dart';
import '../l10n/app_localizations.dart';
import '../state/field.dart';
import '../state/providers.dart';
import 'clients_screen.dart' show erpAmount;
import 'common.dart';

/// Screens for STF-03b (materials, install), STF-06b (sales), STF-08
/// (reseller wallet, expiring, recharge) and STF-09 (dashboard, own HR).
/// The app only shows and sends (R15); the ERP decides and checks again.

/// Loads with [load]; spinner, error with retry, or [builder]. Pull to reload.
class _Loaded<T> extends ConsumerStatefulWidget {
  const _Loaded({super.key, required this.load, required this.builder});

  final Future<T> Function(StaffApi api) load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;

  @override
  ConsumerState<_Loaded<T>> createState() => _LoadedState<T>();
}

class _LoadedState<T> extends ConsumerState<_Loaded<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.load(ref.read(apiProvider));
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MessageBanner(
            errorText(l, _error!, l.errGeneric),
            tone: BannerTone.error,
          ),
          FilledButton(onPressed: _reload, child: Text(l.retry)),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: widget.builder(context, _data as T, _reload),
    );
  }
}

/// Runs a button's ERP call; shows the ERP's refusal, or [done]. True on success.
Future<bool> _run(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(StaffApi api) call, {
  String? done,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await call(ref.read(apiProvider));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } catch (e) {
    if (e is ApiException && e.status == 403) {
      ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
    }
    messenger.showSnackBar(
      SnackBar(content: Text(errorText(l, e, l.errGeneric))),
    );
    return false;
  }
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  bool number = false,
  Future<String?> Function()? scan,
}) {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: TextField(
        key: const ValueKey('ask-text'),
        controller: controller,
        autofocus: true,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(
          labelText: label,
          // STF-10: read the code with the camera instead of typing it.
          suffixIcon: scan == null
              ? null
              : IconButton(
                  key: const ValueKey('ask-scan'),
                  tooltip: l.scanTitle,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final code = await scan();
                    if (code != null && dialog.mounted) {
                      Navigator.of(dialog).pop(code);
                    }
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('ask-ok'),
          onPressed: () => Navigator.of(dialog).pop(controller.text.trim()),
          child: Text(l.workOk),
        ),
      ],
    ),
  );
}

String _purposeLabel(AppLocalizations l, String p) => switch (p) {
  'new_connection' => l.workPurposeNewConnection,
  'repair' => l.workPurposeRepair,
  'shift' => l.workPurposeShift,
  'line_work' => l.workPurposeLineWork,
  'other' => l.workPurposeOther,
  _ => p,
};

String _paymentLabel(AppLocalizations l, String? p) => switch (p) {
  'cash' => l.workPayCash,
  'due' => l.workPayDue,
  'digital' => l.workPayDigital,
  'bkash' => 'bKash',
  'nagad' => 'Nagad',
  'rocket' => 'Rocket',
  'upay' => 'Upay',
  'bank' => l.workPayBank,
  'bangla_qr' => 'Bangla QR',
  _ => p ?? '—',
};

// --- STF-03b: materials ----------------------------------------------------

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({
    super.key,
    required this.ticketId,
    this.canUse = false,
    this.canScan = false,
  });

  final int ticketId;
  final bool canUse;
  final bool canScan;

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  int _version = 0;

  Future<void> _scan() async {
    final l = AppLocalizations.of(context);
    final code = await _askText(
      context,
      title: l.workScan,
      label: l.workCodeHint,
      scan: () => ref.read(codeScannerProvider).scan(context),
    );
    if (code == null || code.isEmpty || !mounted) return;
    final key = newRequestKey();
    final ok = await _run(
      context,
      ref,
      (api) => api.scanForTicket(widget.ticketId, code: code, requestKey: key),
      done: l.workSaved,
    );
    if (ok && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.workMaterials)),
      body: _Loaded<MaterialsView>(
        key: ValueKey(_version),
        load: (api) => api.ticketMaterials(widget.ticketId),
        builder: (context, view, reload) => ListView(
          key: const ValueKey('materials'),
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.canUse)
                  FilledButton.icon(
                    key: const ValueKey('use-parts'),
                    onPressed: view.parts.isEmpty
                        ? null
                        : () async {
                            final saved = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => _UsePartsScreen(
                                      ticketId: widget.ticketId,
                                      view: view,
                                    ),
                                  ),
                                );
                            if (saved == true && mounted) {
                              setState(() => _version++);
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: Text(l.workUseParts),
                  ),
                if (widget.canScan)
                  OutlinedButton.icon(
                    key: const ValueKey('scan-item'),
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l.workScan),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (view.used.isEmpty) MessageBanner(l.workNoMaterials),
            for (final m in view.used)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.name),
                subtitle: Text(
                  [
                    '${erpAmount(m.quantity)} ${m.unit ?? ''}'.trim(),
                    if (m.purpose != null) _purposeLabel(l, m.purpose!),
                    m.by,
                  ].whereType<String>().join(' · '),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UsePartsScreen extends ConsumerStatefulWidget {
  const _UsePartsScreen({required this.ticketId, required this.view});
  final int ticketId;
  final MaterialsView view;

  @override
  ConsumerState<_UsePartsScreen> createState() => _UsePartsScreenState();
}

class _UsePartsScreenState extends ConsumerState<_UsePartsScreen> {
  late final Map<int, TextEditingController> _qty = {
    for (final p in widget.view.parts) p.id: TextEditingController(),
  };
  final _note = TextEditingController();
  late String _purpose =
      widget.view.defaultPurpose ??
      (widget.view.purposes.isEmpty ? 'repair' : widget.view.purposes.first);
  // Kept until saved: a retry sends the same key, so stock is taken once.
  final String _key = newRequestKey();
  bool _busy = false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final lines = <int, num>{
      for (final e in _qty.entries)
        if ((num.tryParse(e.value.text.trim()) ?? 0) > 0)
          e.key: num.parse(e.value.text.trim()),
    };
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workEnterQuantity)));
      return;
    }
    setState(() => _busy = true);
    final ok = await _run(
      context,
      ref,
      (api) => api.useMaterials(
        widget.ticketId,
        lines: lines,
        purpose: _purpose,
        requestKey: _key,
        note: _note.text,
      ),
      done: l.workSaved,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.workUseParts)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: widget.view.purposes.contains(_purpose)
                ? _purpose
                : null,
            decoration: InputDecoration(labelText: l.workPurpose),
            items: [
              for (final p in widget.view.purposes)
                DropdownMenuItem(value: p, child: Text(_purposeLabel(l, p))),
            ],
            onChanged: (v) => setState(() => _purpose = v ?? _purpose),
          ),
          const SizedBox(height: 12),
          for (final p in widget.view.parts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.name} (${l.workInStock}: ${erpAmount(p.inStock)} ${p.unit ?? ''})',
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      key: ValueKey('qty-${p.id}'),
                      controller: _qty[p.id],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l.workQuantity,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.workNoteOptional),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('parts-save'),
            onPressed: _busy ? null : _save,
            child: Text(l.workSave),
          ),
        ],
      ),
    );
  }
}

// --- STF-03b: new-line install --------------------------------------------

class InstallScreen extends ConsumerStatefulWidget {
  const InstallScreen({super.key, required this.ticketId});
  final int ticketId;

  @override
  ConsumerState<InstallScreen> createState() => _InstallScreenState();
}

class _InstallScreenState extends ConsumerState<InstallScreen> {
  final _sn = TextEditingController();
  final _mac = TextEditingController();
  final _pon = TextEditingController();
  final _cable = TextEditingController();
  final _note = TextEditingController();
  int? _pop;
  int? _router;
  int? _loadedPop;
  bool _busy = false;
  Map<String, String> _errors = const {};

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final pop = _pop;
    if (pop == null) return;
    setState(() {
      _busy = true;
      _errors = const {};
    });
    try {
      await ref
          .read(apiProvider)
          .recordInstall(
            widget.ticketId,
            popId: pop,
            routerId: _router,
            onuSn: _sn.text,
            onuMac: _mac.text,
            ponPort: _pon.text,
            cableM: int.tryParse(_cable.text.trim()),
            note: _note.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workInstallSaved)));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = {for (final k in e.errors.keys) k: e.field(k)!});
      if (e.errors.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(l, e, l.errGeneric))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.workInstall)),
      body: _Loaded<InstallForm>(
        key: ValueKey(_loadedPop),
        load: (api) => api.installForm(widget.ticketId, popId: _loadedPop),
        builder: (context, form, reload) {
          if (!form.canInstall) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [MessageBanner(l.workCannotInstall)],
            );
          }
          _pop ??= form.popId;
          if (_router == null && form.routers.length == 1) {
            _router = form.routers.first.id;
          }
          return ListView(
            key: const ValueKey('install-form'),
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                initialValue: form.pops.any((p) => p.id == _pop) ? _pop : null,
                decoration: InputDecoration(
                  labelText: l.clientsPop,
                  errorText: _errors['pop_id'],
                ),
                items: [
                  for (final p in form.pops)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() {
                  _pop = v;
                  _router = null;
                  _loadedPop = v;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: form.routers.any((r) => r.id == _router)
                    ? _router
                    : null,
                decoration: InputDecoration(
                  labelText: l.clientsRouter,
                  errorText: _errors['router_id'],
                ),
                items: [
                  for (final r in form.routers)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setState(() => _router = v),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('install-sn'),
                controller: _sn,
                decoration: InputDecoration(
                  labelText: 'ONU SN',
                  errorText: _errors['onu_sn'],
                  suffixIcon: IconButton(
                    key: const ValueKey('install-sn-scan'),
                    tooltip: l.scanTitle,
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final code = await ref
                          .read(codeScannerProvider)
                          .scan(context);
                      if (code != null) _sn.text = code;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mac,
                decoration: InputDecoration(
                  labelText: 'ONU MAC',
                  errorText: _errors['onu_mac'],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pon,
                decoration: InputDecoration(
                  labelText: l.workPonPort,
                  errorText: _errors['pon_port'],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cable,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.workCableMetres,
                  errorText: _errors['cable_m'],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: l.workNoteOptional),
              ),
              const SizedBox(height: 12),
              MessageBanner(l.workInstallHint),
              FilledButton(
                key: const ValueKey('install-save'),
                onPressed: _busy || _pop == null ? null : _save,
                child: Text(l.workSave),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- STF-06b: sales ----------------------------------------------------------

/// A client from the search the user may use: `/clients` with `clients.view`,
/// else the collector search.
Future<({int id, String label})?> _pickClient(
  BuildContext context,
  WidgetRef ref,
) {
  return Navigator.of(context).push<({int id, String label})>(
    MaterialPageRoute(builder: (_) => const _ClientPicker()),
  );
}

class _ClientPicker extends ConsumerStatefulWidget {
  const _ClientPicker();

  @override
  ConsumerState<_ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends ConsumerState<_ClientPicker> {
  final _q = TextEditingController();
  List<({int id, String label})> _found = const [];
  bool _busy = false;
  Object? _error;

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.length < 2) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final user = ref.read(authProvider).user;
      final found = (user?.can('clients.view') ?? false)
          ? [
              for (final c in (await api.clients(q: q)).clients)
                (id: c.id, label: '${c.name ?? ''} · ${c.code ?? ''}'),
            ]
          : [
              for (final CollectionClient c in await api.collectionClients(q))
                (id: c.id, label: '${c.name ?? ''} · ${c.code ?? ''}'),
            ];
      if (mounted) setState(() => _found = found);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.workPickClient)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const ValueKey('client-search'),
            controller: _q,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: l.workClientSearch,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            MessageBanner(
              errorText(l, _error!, l.errGeneric),
              tone: BannerTone.error,
            ),
          for (final c in _found)
            ListTile(
              title: Text(c.label),
              onTap: () => Navigator.of(context).pop(c),
            ),
        ],
      ),
    );
  }
}

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  int _version = 0;

  Future<void> _newSale(SalesView view) async {
    final l = AppLocalizations.of(context);
    final code = await _askText(
      context,
      title: l.workScan,
      label: l.workCodeHint,
      scan: () => ref.read(codeScannerProvider).scan(context),
    );
    if (code == null || code.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    ScannedProduct product;
    try {
      product = await ref.read(apiProvider).scanProduct(code);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(l, e, l.errGeneric))),
      );
      return;
    }
    if (!mounted) return;
    final sold = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _SellScreen(product: product, methods: view.digitalMethods),
      ),
    );
    if (sold == true && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureSales)),
      body: _Loaded<SalesView>(
        key: ValueKey(_version),
        load: (api) => api.sales(),
        builder: (context, view, reload) => ListView(
          key: const ValueKey('sales'),
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              key: const ValueKey('new-sale'),
              onPressed: () => _newSale(view),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l.workSell),
            ),
            const SizedBox(height: 16),
            if (view.awaiting.isNotEmpty) ...[
              Text(
                l.workAwaitingClient,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final s in view.awaiting)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${s.name} · ${erpAmount(s.price)}'),
                  subtitle: Text(_paymentLabel(l, s.payment)),
                  trailing: TextButton(
                    onPressed: () async {
                      final c = await _pickClient(context, ref);
                      if (c == null || !context.mounted) return;
                      final ok = await _run(
                        context,
                        ref,
                        (api) => api.giveSaleClient(s.id, c.id),
                        done: l.workSaved,
                      );
                      if (ok) await reload();
                    },
                    child: Text(l.workGiveClientId),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            Text(
              l.workRecentSales,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (view.recent.isEmpty) MessageBanner(l.workNoSales),
            for (final s in view.recent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${s.name} · ${erpAmount(s.price)}'),
                subtitle: Text(
                  [
                    _paymentLabel(l, s.paymentMethod ?? s.payment),
                    s.clientCode,
                  ].whereType<String>().join(' · '),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SellScreen extends ConsumerStatefulWidget {
  const _SellScreen({required this.product, required this.methods});
  final ScannedProduct product;
  final List<String> methods;

  @override
  ConsumerState<_SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<_SellScreen> {
  final _price = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _note = TextEditingController();
  String _payment = 'cash';
  String? _method;
  ({int id, String label})? _client;
  bool _newConnection = false;
  final String _key = newRequestKey();
  bool _busy = false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final price = num.tryParse(_price.text.trim());
    if (price == null ||
        price <= 0 ||
        (_client == null && !_newConnection) ||
        (_payment == 'digital' && _method == null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workFillAll)));
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sale = await ref
          .read(apiProvider)
          .sell(
            code: widget.product.code,
            price: price,
            payment: _payment,
            paymentMethod: _payment == 'digital' ? _method : null,
            quantity: widget.product.isPart
                ? num.tryParse(_qty.text.trim()) ?? 1
                : null,
            clientId: _client?.id,
            newConnection: _newConnection,
            note: _note.text,
            requestKey: _key,
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(sale.cashToHandover ? l.workSoldCash : l.workSold),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(l, e, l.errGeneric))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(l.workSell)),
      body: ListView(
        key: const ValueKey('sell-form'),
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            children: [
              Text(p.name, style: Theme.of(context).textTheme.titleMedium),
              if (p.isPart)
                InfoRow(
                  l.workInStock,
                  '${erpAmount(p.inStock)} ${p.unit ?? ''}',
                ),
            ],
          ),
          if (p.isPart) ...[
            TextField(
              controller: _qty,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l.workQuantity),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const ValueKey('sell-price'),
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.workPrice),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'cash', label: Text(l.workPayCash)),
              ButtonSegment(value: 'due', label: Text(l.workPayDue)),
              ButtonSegment(value: 'digital', label: Text(l.workPayDigital)),
            ],
            selected: {_payment},
            onSelectionChanged: (s) => setState(() => _payment = s.first),
          ),
          if (_payment == 'digital') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(labelText: l.workMethod),
              items: [
                for (final m in widget.methods)
                  DropdownMenuItem(value: m, child: Text(_paymentLabel(l, m))),
              ],
              onChanged: (v) => setState(() => _method = v),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _newConnection,
            onChanged: (v) => setState(() => _newConnection = v),
            title: Text(l.workForNewConnection),
          ),
          if (!_newConnection)
            ListTile(
              key: const ValueKey('sell-client'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(_client?.label ?? l.workPickClient),
              trailing: const Icon(Icons.search),
              onTap: () async {
                final c = await _pickClient(context, ref);
                if (c != null) setState(() => _client = c);
              },
            ),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.workNoteOptional),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('sell-save'),
            onPressed: _busy ? null : _save,
            child: Text(l.workSell),
          ),
        ],
      ),
    );
  }
}

// --- STF-08: reseller -------------------------------------------------------

class ResellerWalletScreen extends StatelessWidget {
  const ResellerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureWallet)),
      body: _Loaded<ResellerWallet>(
        load: (api) => api.resellerWallet(),
        builder: (context, w, reload) => ListView(
          key: const ValueKey('wallet'),
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              children: [
                InfoRow(l.workWalletBalance, erpAmount(w.balance)),
                InfoRow(l.workCreditLimit, erpAmount(w.creditLimit)),
                InfoRow(l.workCreditUsed, erpAmount(w.creditUsed)),
                InfoRow(l.workAvailable, erpAmount(w.available)),
                InfoRow(l.workClientsAdvance, erpAmount(w.clientsAdvanceHeld)),
              ],
            ),
            if (w.creditAlert)
              MessageBanner(l.workCreditAlert, tone: BannerTone.warning),
            Text(
              l.workTransactions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final t in w.transactions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${erpAmount(t.amount)} · ${t.type ?? ''}'),
                subtitle: Text([t.note, t.at].whereType<String>().join(' · ')),
                trailing: Text(erpAmount(t.balanceAfter)),
              ),
          ],
        ),
      ),
    );
  }
}

class ExpiringScreen extends StatefulWidget {
  const ExpiringScreen({super.key});

  @override
  State<ExpiringScreen> createState() => _ExpiringScreenState();
}

class _ExpiringScreenState extends State<ExpiringScreen> {
  int _days = 3;
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureExpiring)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<int>(
              segments: [
                for (final d in const [0, 3, 7, 30])
                  ButtonSegment(value: d, label: Text(l.workWithinDays(d))),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
          ),
          Expanded(
            child: _Loaded<List<ExpiringClient>>(
              key: ValueKey('$_days|$_version'),
              load: (api) => api.expiringClients(days: _days),
              builder: (context, clients, reload) => ListView(
                key: const ValueKey('expiring'),
                padding: const EdgeInsets.all(16),
                children: [
                  if (clients.isEmpty) MessageBanner(l.workNoExpiring),
                  for (final c in clients)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${c.name} · ${c.code ?? ''}'),
                      subtitle: Text(
                        [
                          c.packageName,
                          c.expiryDate,
                          if (c.daysLeft != null) l.workDaysLeft(c.daysLeft!),
                        ].whereType<String>().join(' · '),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final done = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => RechargeScreen(
                                clientId: c.id,
                                clientName: c.name,
                              ),
                            ),
                          );
                          if (done == true && mounted) {
                            setState(() => _version++);
                          }
                        },
                        child: Text(l.workRecharge),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quote first (cost, new expiry, wallet after), then the web's RechargeClient once.
class RechargeScreen extends ConsumerStatefulWidget {
  const RechargeScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });
  final int clientId;
  final String clientName;

  @override
  ConsumerState<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends ConsumerState<RechargeScreen> {
  int _months = 1;
  String? _method;
  String _key = newRequestKey();
  bool _busy = false;

  Future<void> _recharge(RechargeQuote q) async {
    final l = AppLocalizations.of(context);
    final method = _method;
    if (method == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(l.workConfirmRecharge(erpAmount(q.payTotal), _months)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('recharge-confirm'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.workOk),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final expiry = await ref
          .read(apiProvider)
          .recharge(
            widget.clientId,
            months: _months,
            method: method,
            requestKey: _key,
          );
      messenger.showSnackBar(
        SnackBar(content: Text(l.workRechargeDone(expiry ?? '—'))),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (e is ApiException && e.code == 'key_reused') _key = newRequestKey();
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(l, e, l.errGeneric))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l.workRecharge} · ${widget.clientName}')),
      body: _Loaded<RechargeQuote>(
        key: ValueKey(_months),
        load: (api) => api.rechargeQuote(widget.clientId, months: _months),
        builder: (context, q, reload) {
          final ids = [for (final m in q.methods) m.id];
          if (_method == null || !ids.contains(_method)) {
            _method = ids.isEmpty ? null : ids.first;
          }
          return ListView(
            key: const ValueKey('recharge'),
            padding: const EdgeInsets.all(16),
            children: [
              if (q.pending)
                MessageBanner(l.workRechargePending, tone: BannerTone.warning),
              DropdownButtonFormField<int>(
                initialValue: _months,
                decoration: InputDecoration(labelText: l.workMonths),
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
                  InfoRow(l.workAmount, erpAmount(q.amount)),
                  if ((q.adjustment ?? 0) != 0)
                    InfoRow(l.workAdjustment, erpAmount(q.adjustment)),
                  InfoRow(l.workPayTotal, erpAmount(q.payTotal)),
                  InfoRow(l.workOldExpiry, q.oldExpiry),
                  InfoRow(l.workNewExpiry, q.newExpiry),
                  if (q.walletCharge != null) ...[
                    InfoRow(l.workWalletCharge, erpAmount(q.walletCharge)),
                    InfoRow(l.workWalletBalance, erpAmount(q.walletBalance)),
                    InfoRow(l.workWalletAfter, erpAmount(q.walletAfter)),
                  ],
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(labelText: l.workMethod),
                items: [
                  for (final m in q.methods)
                    DropdownMenuItem(value: m.id, child: Text(m.label)),
                ],
                onChanged: (v) => setState(() => _method = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('recharge-save'),
                onPressed: _busy || q.pending || _method == null
                    ? null
                    : () => _recharge(q),
                child: Text(l.workRecharge),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- STF-09: dashboard and own HR ----------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureDashboard)),
      body: _Loaded<List<Kpi>>(
        load: (api) => api.dashboard(),
        builder: (context, kpis, reload) => ListView(
          key: const ValueKey('dashboard'),
          padding: const EdgeInsets.all(16),
          children: [
            if (kpis.isEmpty) MessageBanner(l.workNoDashboard),
            for (final k in kpis)
              Card(
                child: ListTile(
                  title: Text(k.label),
                  trailing: Text(
                    k.money ? '৳ ${erpAmount(k.value)}' : erpAmount(k.value),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HrScreen extends ConsumerStatefulWidget {
  const HrScreen({super.key});

  @override
  ConsumerState<HrScreen> createState() => _HrScreenState();
}

class _HrScreenState extends ConsumerState<HrScreen> {
  int _version = 0;

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _askLeave() async {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (range == null || !mounted) return;
    final reason = await _askText(
      context,
      title: l.workAskLeave,
      label: l.workReason,
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    final ok = await _run(
      context,
      ref,
      (api) => api.askLeave(
        startDate: _date(range.start),
        endDate: _date(range.end),
        reason: reason,
      ),
      done: l.workRequestSent,
    );
    if (ok && mounted) setState(() => _version++);
  }

  Future<void> _askAdvance(String month) async {
    final l = AppLocalizations.of(context);
    final amount = await _askText(
      context,
      title: l.workAskAdvance,
      label: l.workAmount,
      number: true,
    );
    final parsed = num.tryParse(amount ?? '');
    if (parsed == null || !mounted) return;
    final ok = await _run(
      context,
      ref,
      (api) => api.askAdvance(amount: parsed, month: month),
      done: l.workRequestSent,
    );
    if (ok && mounted) setState(() => _version++);
  }

  Future<void> _cancel(Future<void> Function(StaffApi api) call) async {
    final l = AppLocalizations.of(context);
    final ok = await _run(context, ref, call, done: l.workSaved);
    if (ok && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: Text(l.featureHr)),
      body: _Loaded<HrView>(
        key: ValueKey(_version),
        load: (api) => api.myHr(month: month),
        builder: (context, hr, reload) => ListView(
          key: const ValueKey('hr'),
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '${l.workAttendance} · ${hr.month ?? month}',
              children: [
                for (final c in hr.counts.entries)
                  InfoRow(c.key, erpAmount(c.value)),
                InfoRow(l.workLateMinutes, '${hr.lateMinutes}'),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _askLeave,
                  child: Text(l.workAskLeave),
                ),
                FilledButton.tonal(
                  key: const ValueKey('ask-advance'),
                  onPressed: () => _askAdvance(month),
                  child: Text(l.workAskAdvance),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l.workLeaves, style: Theme.of(context).textTheme.titleMedium),
            for (final v in hr.leaves)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(v.title),
                subtitle: Text(
                  [v.status, v.note].whereType<String>().join(' · '),
                ),
                trailing: v.canCancel
                    ? TextButton(
                        onPressed: () =>
                            _cancel((api) => api.cancelLeave(v.id)),
                        child: Text(l.cancel),
                      )
                    : null,
              ),
            const SizedBox(height: 16),
            Text(
              l.workAdvances,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final a in hr.advances)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${erpAmount(a.amount)} · ${a.month ?? ''}'),
                subtitle: Text(
                  [
                    a.request.status,
                    a.request.note,
                  ].whereType<String>().join(' · '),
                ),
                trailing: a.request.canCancel
                    ? TextButton(
                        onPressed: () =>
                            _cancel((api) => api.cancelAdvance(a.request.id)),
                        child: Text(l.cancel),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
