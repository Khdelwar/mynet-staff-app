import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/staff_api.dart';
import '../api/stock.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'clients_screen.dart' show erpAmount;
import 'common.dart';
import 'theme.dart';

/// Read-only stock (`GET /stock`). Everyone with the screen sees what they
/// hold and the office parts (web "My stock"); `inventory.view|manage` also
/// gets the web Stock page's lists with its search and filters.
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _search = TextEditingController();
  StockView? _view;
  Object? _error;
  bool _loading = true;
  bool _all = false;
  String? _status;
  int? _category;
  List<StockItem> _items = [];
  List<StockPart> _parts = [];
  int _itemsPage = 1;
  int _partsPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  StaffApi get _api => ref.read(apiProvider);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final view = await _api.stock(
        q: _search.text,
        status: _status,
        category: _category,
      );
      if (!mounted) return;
      setState(() {
        _view = view;
        _items = [...view.items.rows];
        _parts = [...view.parts.rows];
        _itemsPage = view.items.page;
        _partsPage = view.parts.page;
        _error = null;
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

  Future<void> _more({required bool items}) async {
    setState(() => _loading = true);
    try {
      final next = await _api.stock(
        q: _search.text,
        status: _status,
        category: _category,
        page: items ? _itemsPage + 1 : _itemsPage,
        partsPage: items ? _partsPage : _partsPage + 1,
      );
      if (!mounted) return;
      setState(() {
        _view = next;
        if (items) {
          _items = [..._items, ...next.items.rows];
          _itemsPage = next.items.page;
        } else {
          _parts = [..._parts, ...next.parts.rows];
          _partsPage = next.parts.page;
        }
        _loading = false;
      });
    } catch (e) {
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
    final view = _view;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureStock)),
      body: view == null
          ? (_error == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      MessageBanner(
                        errorText(l, _error!, l.stockLoadFailed),
                        tone: BannerTone.error,
                      ),
                      FilledButton(onPressed: _load, child: Text(l.retry)),
                    ],
                  ))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                key: const ValueKey('stock'),
                padding: const EdgeInsets.all(16),
                children: [
                  PageHero(
                    title: l.featureStock,
                    help: l.stockHelp,
                    icon: Icons.inventory_2_outlined,
                    section: ErpSection.inventory,
                  ),
                  if (_error != null)
                    MessageBanner(
                      errorText(l, _error!, l.stockLoadFailed),
                      tone: BannerTone.warning,
                    ),
                  if (view.canViewAll) ...[
                    SegmentedButton<bool>(
                      key: const ValueKey('stock-tabs'),
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(l.stockTabMine),
                        ),
                        ButtonSegment(value: true, label: Text(l.stockTabAll)),
                      ],
                      selected: {_all},
                      onSelectionChanged: (v) => setState(() => _all = v.first),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_all && view.canViewAll)
                    ..._allStock(context, l, view)
                  else
                    ..._mine(context, l, view),
                  if (_loading) const LinearProgressIndicator(),
                ],
              ),
            ),
    );
  }

  List<Widget> _mine(BuildContext context, AppLocalizations l, StockView v) => [
    SectionCard(
      key: const ValueKey('stock-mine'),
      title: l.stockInHand,
      children: [
        if (v.myItems.isEmpty && v.myParts.isEmpty) Text(l.stockNothingInHand),
        for (final i in v.myItems) _ItemRow(item: i),
        for (final p in v.myParts) _PartRow(part: p),
      ],
    ),
    SectionCard(
      key: const ValueKey('stock-office'),
      title: l.stockOfficeParts,
      children: [
        if (v.officeParts.isEmpty) Text(l.stockNoOfficeParts),
        for (final p in v.officeParts) _PartRow(part: p),
      ],
    ),
  ];

  List<Widget> _allStock(
    BuildContext context,
    AppLocalizations l,
    StockView v,
  ) => [
    // Status counts: tap one to filter, as the web Stock page.
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l.stockAllStatuses),
          selected: _status == null,
          onSelected: (_) {
            setState(() => _status = null);
            _load();
          },
        ),
        for (final s in v.statusCounts)
          ChoiceChip(
            key: ValueKey('stock-status-${s.status}'),
            label: Text('${s.label} · ${s.count}'),
            selected: _status == s.status,
            onSelected: (on) {
              setState(() => _status = on ? s.status : null);
              _load();
            },
          ),
      ],
    ),
    const SizedBox(height: 12),
    if (v.lowStockAlerts > 0)
      MessageBanner(
        l.stockLowAlerts(v.lowStockAlerts),
        tone: BannerTone.warning,
      ),
    TextField(
      key: const ValueKey('stock-search'),
      controller: _search,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _load(),
      decoration: InputDecoration(
        labelText: l.stockSearch,
        prefixIcon: const Icon(Icons.search),
      ),
    ),
    const SizedBox(height: 10),
    DropdownButtonFormField<int?>(
      key: const ValueKey('stock-category'),
      initialValue: _category,
      isExpanded: true,
      items: [
        DropdownMenuItem(value: null, child: Text(l.stockAllCategories)),
        for (final (id, name) in v.categories)
          DropdownMenuItem(value: id, child: Text(name)),
      ],
      onChanged: (c) {
        setState(() => _category = c);
        _load();
      },
    ),
    const SizedBox(height: 12),
    SectionCard(
      key: const ValueKey('stock-items'),
      title: l.stockItems(v.items.total),
      children: [
        if (_items.isEmpty) Text(l.stockNoItems),
        for (final i in _items) _ItemRow(item: i, showHolder: true),
        if (v.items.hasMore)
          TextButton(
            key: const ValueKey('stock-items-more'),
            onPressed: _loading ? null : () => _more(items: true),
            child: Text(l.stockMore),
          ),
      ],
    ),
    SectionCard(
      key: const ValueKey('stock-parts'),
      title: l.stockParts(v.parts.total),
      children: [
        if (_parts.isEmpty) Text(l.stockNoItems),
        for (final p in _parts) _PartRow(part: p),
        if (v.parts.hasMore)
          TextButton(
            key: const ValueKey('stock-parts-more'),
            onPressed: _loading ? null : () => _more(items: false),
            child: Text(l.stockMore),
          ),
      ],
    ),
  ];
}

/// ERP badge tone per item status (in stock green, with a client blue …).
BadgeTone _tone(String status) => switch (status) {
  'in_stock' => BadgeTone.success,
  'assigned_tech' || 'on_trial' => BadgeTone.warning,
  'issued_client' || 'sold' || 'installed_network' => BadgeTone.info,
  'damaged' || 'void' => BadgeTone.danger,
  _ => BadgeTone.neutral,
};

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, this.showHolder = false});
  final StockItem item;
  final bool showHolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = [?item.category, ?item.model].join(' · ');
    final client = item.clientName == null
        ? null
        : [?item.clientName, ?item.clientCode].join(' · ');
    final sub = [
      ?item.serial,
      ?item.mac,
      if (showHolder) ?item.technician,
      if (showHolder) ?client,
    ].join(' · ');
    return Padding(
      key: ValueKey('stock-item-${item.id}'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '#${item.id}' : title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub.isNotEmpty) Text(sub, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            item.statusLabel ?? item.status,
            tone: _tone(item.status),
          ),
        ],
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({required this.part});
  final StockPart part;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey('stock-part-${part.id}'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (part.category != null)
                  Text(part.category!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (part.low) ...[
            StatusBadge(l.stockLow, tone: BadgeTone.danger),
            const SizedBox(width: 6),
          ],
          if (part.useOnly) ...[
            StatusBadge(l.stockUseOnly),
            const SizedBox(width: 6),
          ],
          Text(
            '${erpAmount(part.quantity)} ${part.unit ?? ''}'.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
