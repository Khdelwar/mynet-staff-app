import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/clients.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'client_detail_screen.dart';
import 'common.dart';
import 'support_screens.dart';
import 'theme.dart';

/// What the ERP sent. Display only — the app does not add due and advance.
String erpAmount(num? value) {
  if (value == null) return '—';
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _search = TextEditingController();
  final _clients = <ClientRow>[];
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loading = true;
  Object? _error;
  Timer? _typing;
  int _asked = 0;

  /// The web list's filters, as the ERP names them.
  Map<String, String> _filters = const {};
  ClientFilterOptions? _options;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _loadOptions();
  }

  @override
  void dispose() {
    _typing?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final lang = ref.read(localeProvider).languageCode;
      final options = await ref.read(apiProvider).clientFilters(lang: lang);
      if (mounted) setState(() => _options = options);
    } catch (_) {
      // An older ERP has no filters: the list still works without them.
    }
  }

  Future<void> _load({required bool reset}) async {
    final next = reset ? 1 : _page + 1;
    final ask = ++_asked;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _clients.clear();
    });
    try {
      final result = await ref
          .read(apiProvider)
          .clients(q: _search.text, filters: _filters, page: next);
      // A newer search was typed meanwhile: keep only its answer.
      if (!mounted || ask != _asked) return;
      setState(() {
        _page = result.page;
        _lastPage = result.lastPage;
        _total = result.total;
        if (reset) _clients.clear();
        _clients.addAll(result.clients);
        _loading = false;
      });
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (!mounted || ask != _asked) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// As the web: results follow the typing (from 2 letters).
  void _typed(String text) {
    _typing?.cancel();
    final q = text.trim();
    if (q.isNotEmpty && q.length < 2) return;
    _typing = Timer(
      const Duration(milliseconds: 350),
      () => _load(reset: true),
    );
  }

  /// As the web's Enter: an exact client ID / PPPoE opens that client.
  Future<void> _submitted(String text) async {
    _typing?.cancel();
    final q = text.trim();
    if (q.length >= 2) {
      try {
        final hit = await ref.read(apiProvider).clientSuggest(q);
        if (!mounted) return;
        if (hit.exactId != null) {
          _open(hit.exactId!);
          return;
        }
      } catch (_) {
        // Fall back to the list.
      }
    }
    if (mounted) await _load(reset: true);
  }

  void _open(int id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ClientDetailScreen(clientId: id)),
    );
  }

  int get _filterCount => _filters.entries
      .where(
        (e) => e.value.isNotEmpty && e.key != 'sort' && e.key != 'sort_dir',
      )
      .length;

  Future<void> _openFilters() async {
    final options = _options;
    if (options == null) return;
    final picked = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ClientFilterSheet(options: options, initial: _filters),
    );
    if (picked == null || !mounted) return;
    setState(() => _filters = picked);
    await _load(reset: true);
  }

  String _subtitle(AppLocalizations l, ClientRow client) {
    final status =
        _options?.statusLabel(client.displayStatus) ?? client.displayStatus;
    return [
      client.code,
      if (client.pppoe != null && client.pppoe != client.code) client.pppoe,
      client.phone,
      if (status != null && status.isNotEmpty) status,
      if (client.isVip) 'VIP',
      if (client.due != null && client.due! > 0)
        '${l.collectionDue} ৳ ${erpAmount(client.due)}',
      client.pop,
    ].whereType<String>().where((t) => t.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canCreate =
        ref.watch(authProvider.select((a) => a.user))?.can('clients.create') ??
        false;
    final count = _filterCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.featureClients),
        actions: [
          if (_options != null)
            IconButton(
              key: const ValueKey('client-filters'),
              tooltip: l.clientsFilter,
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.tune),
              ),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              key: const ValueKey('new-client'),
              onPressed: () async {
                final made = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NewClientScreen()),
                );
                if (made == true) await _load(reset: true);
              },
              icon: const Icon(Icons.person_add_alt),
              label: Text(l.supportNewClient),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const ValueKey('client-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l.clientsSearch,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('client-search-clear'),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                          _load(reset: true);
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (text) {
                setState(() {});
                _typed(text);
              },
              onSubmitted: _submitted,
            ),
          ),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('client-filters-clear'),
                  onPressed: () {
                    setState(() => _filters = const {});
                    _load(reset: true);
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(
                    '${l.clientsFilter} ($count) · ${l.clientsClear}',
                  ),
                ),
              ),
            ),
          if (!_loading || _clients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.clientsTotal(_total),
                  key: const ValueKey('clients-total'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView(
                key: const ValueKey('clients'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                children: [
                  if (_error != null)
                    MessageBanner(
                      errorText(l, _error!, l.errGeneric),
                      tone: BannerTone.error,
                    ),
                  if (_clients.isEmpty && !_loading)
                    MessageBanner(l.clientsEmpty),
                  for (final client in _clients)
                    Card(
                      key: ValueKey('client-${client.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(client.name ?? client.code ?? '—'),
                        subtitle: Text(_subtitle(l, client)),
                        trailing: client.seenOnline == null
                            ? null
                            : Icon(
                                client.seenOnline!
                                    ? Icons.circle
                                    : Icons.circle_outlined,
                                size: 12,
                                color: client.seenOnline!
                                    ? ErpColors.accent600
                                    : null,
                              ),
                        onTap: () => _open(client.id),
                      ),
                    ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_loading && _page < _lastPage)
                    OutlinedButton(
                      key: const ValueKey('clients-more'),
                      onPressed: () => _load(reset: false),
                      child: Text(l.clientsMore),
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

/// The web client list's filters (choices and labels from the ERP).
class ClientFilterSheet extends StatefulWidget {
  const ClientFilterSheet({
    super.key,
    required this.options,
    required this.initial,
  });

  final ClientFilterOptions options;
  final Map<String, String> initial;

  @override
  State<ClientFilterSheet> createState() => _ClientFilterSheetState();
}

class _ClientFilterSheetState extends State<ClientFilterSheet> {
  late final Map<String, String> _picked = {...widget.initial};

  Widget _choice(
    String key,
    String label,
    List<FilterOption> options, {
    bool any = true,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final current = _picked[key] ?? '';
    final known = options.any((o) => o.value == current);
    // Without "any", nothing picked means the ERP's default (the first).
    final shown = known ? current : (any ? '' : options.first.value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('filter-$key'),
        initialValue: shown,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          if (any) DropdownMenuItem(value: '', child: Text(l.clientsAny)),
          for (final o in options)
            DropdownMenuItem(value: o.value, child: Text(o.label)),
        ],
        onChanged: (value) => setState(() {
          _picked[key] = value ?? '';
          // A router belongs to a POP: a new POP clears the router.
          if (key == 'pop_id') _picked.remove('router_id');
        }),
      ),
    );
  }

  String _sortLabel(AppLocalizations l, String sort) => switch (sort) {
    'id' => l.clientsSortNewest,
    'name' => l.clientsSortName,
    'client_id' => l.clientsSortClientId,
    'package' => l.clientsSortPackage,
    'expiry' => l.clientsSortExpiry,
    'status' => l.clientsSortStatus,
    _ => sort,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.options;
    final pop = _picked['pop_id'] ?? '';
    final routers = [
      for (final (router, popId) in o.routers)
        if (pop.isEmpty || popId == pop) router,
    ];
    final directories = o.directories.isEmpty
        ? const <FilterOption>[]
        : o.directories;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Text(l.clientsFilter, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (directories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final d in directories)
                    ChoiceChip(
                      key: ValueKey('filter-directory-${d.value}'),
                      label: Text(d.label),
                      selected: (_picked['directory'] ?? 'all').isEmpty
                          ? d.value == 'all'
                          : (_picked['directory'] ?? 'all') == d.value,
                      onSelected: (_) => setState(
                        () => _picked['directory'] = d.value == 'all'
                            ? ''
                            : d.value,
                      ),
                    ),
                ],
              ),
            ),
          _choice('status', l.clientsFilterStatus, o.statuses),
          _choice('pop_id', 'POP', o.pops),
          _choice('zone_id', l.clientsFilterZone, o.zones),
          _choice('router_id', l.clientsFilterRouter, routers),
          _choice('package_id', l.clientsFilterPackage, o.packages),
          _choice('reseller_id', l.clientsFilterReseller, o.resellers),
          _choice('billing_policy', l.clientsFilterPolicy, o.billingPolicies),
          _choice('client_type', l.clientsFilterType, o.clientTypes),
          if (o.sorts.isNotEmpty) ...[
            _choice('sort', l.clientsSort, [
              for (final s in o.sorts) FilterOption(s, _sortLabel(l, s)),
            ], any: false),
            _choice('sort_dir', l.clientsSortOrder, [
              FilterOption('desc', l.clientsSortDesc),
              FilterOption('asc', l.clientsSortAsc),
            ], any: false),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('filter-clear'),
                  onPressed: () =>
                      Navigator.of(context).pop(<String, String>{}),
                  child: Text(l.clientsClear),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('filter-apply'),
                  onPressed: () => Navigator.of(context).pop({
                    for (final e in _picked.entries)
                      if (e.value.isNotEmpty) e.key: e.value,
                  }),
                  child: Text(l.clientsApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
