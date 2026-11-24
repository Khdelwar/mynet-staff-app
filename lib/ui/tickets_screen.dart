import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../api/request_key.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';
import 'kit.dart';
import 'words.dart';

/// STF-03 / STF-03b / STF-05: tickets. The ERP decides which tickets a user
/// sees (a technician only their own), which steps are offered and who may
/// install; the app draws what it is given.
class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  String _status = 'active';
  String _scope = 'mine';
  String _q = '';
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));
    final canAll =
        user != null &&
        (user.can('tickets.manage') ||
            !user.hasRole('technician') ||
            user.hasRole('support'));
    final canCreate =
        user?.canAny(const ['tickets.create', 'tickets.manage']) ?? false;

    return WorkPage(
      title: l.featureTickets,
      fab: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final client = await pickClient(context);
                if (client == null || !context.mounted) return;
                final made = await open<bool>(
                  context,
                  NewTicketScreen(client: client),
                );
                if (made == true) setState(() => _version++);
              },
              icon: const Icon(Icons.add),
              label: Text(l.newTicket),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'active',
                      label: Text(l.ticketsActive),
                    ),
                    ButtonSegment(value: 'done', label: Text(l.ticketsDone)),
                  ],
                  selected: {_status},
                  onSelectionChanged: (s) => setState(() => _status = s.first),
                ),
                if (canAll) ...[
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'mine', label: Text(l.ticketsMine)),
                      ButtonSegment(value: 'all', label: Text(l.ticketsAll)),
                    ],
                    selected: {_scope},
                    onSelectionChanged: (s) => setState(() => _scope = s.first),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l.ticketSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (v) => setState(() => _q = v.trim()),
                ),
              ],
            ),
          ),
          Expanded(
            child: Loader(
              key: ValueKey('$_status|$_scope|$_q|$_version'),
              load: (api) => api.get(
                '/tickets',
                query: {
                  'status': _status,
                  'scope': _scope,
                  if (_q.isNotEmpty) 'q': _q,
                  'per_page': 50,
                },
              ),
              builder: (context, data, reload) {
                final tickets = asList(data['tickets']).map(asMap).toList();
                if (tickets.isEmpty) return EmptyList(l.noTickets);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final t in tickets)
                      TicketCard(
                        t,
                        onTap: () async {
                          await open<void>(
                            context,
                            TicketDetailScreen(id: toNum(t['id'])!.toInt()),
                          );
                          await reload();
                        },
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

class TicketCard extends StatelessWidget {
  const TicketCard(this.t, {super.key, this.onTap});
  final Json t;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final client = asMap(t['client']);
    final priority = pickString(t, const ['priority']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text('#${t['id']} · ${pickString(t, const ['subject']) ?? ''}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.isNotEmpty)
              Text(
                [
                  pickString(client, const ['name']),
                  pickString(client, const ['code']),
                  pickString(client, const ['address']),
                ].whereType<String>().join(' · '),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Tag(statusWord(l, pickString(t, const ['status']))),
                Tag(
                  priorityWord(l, priority),
                  tone: priorityColor(context, priority),
                ),
                if (t['role'] == 'helper') Tag(l.roleHelper),
                if (t['overdue'] == true)
                  Tag(l.overdue, tone: Colors.red.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  int _version = 0;

  void _reload() => setState(() => _version++);

  /// One step (on the way, resolved…). Finishing sends the phone's location;
  /// when the ERP says it is far from the house it asks why (STF-05b).
  Future<void> _step(Json ticket, String status) async {
    final l = AppLocalizations.of(context);
    final needsNote = asList(ticket['note_required_for']).contains(status);
    String? note;
    String? outcome;
    if (needsNote) {
      note = await askText(
        context,
        title: statusWord(l, status),
        label: l.noteRequired,
        required: true,
        maxLines: 3,
      );
      if (note == null || !mounted) return;
    }
    if (status == 'closed') {
      outcome = await _pickOutcome(
        asList(ticket['outcomes']).whereType<String>().toList(),
      );
      if (outcome == null || !mounted) return;
    }
    final finishing = status == 'resolved' || status == 'closed';
    final position = finishing ? await ref.read(locatorProvider)() : null;
    if (!mounted) return;

    final body = <String, Object?>{
      'status': status,
      'note': ?note,
      'outcome': ?outcome,
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    };
    final api = ref.read(apiProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await api.post('/tickets/${widget.id}/status', body);
    } on ApiException catch (e) {
      final away = e.errorFor('away_reason');
      if (e.status == 422 && away != null && mounted) {
        final reason = await askText(
          context,
          title: l.awayTitle,
          label: away,
          required: true,
          maxLines: 2,
        );
        if (reason == null || !mounted) return;
        final ok = await act(
          context,
          ref,
          (api) => api.post('/tickets/${widget.id}/status', {
            ...body,
            'away_reason': reason,
          }),
        );
        if (ok != null) _reload();
        return;
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(l, e, l.errGeneric))),
      );
      return;
    }
    _reload();
  }

  Future<String?> _pickOutcome(List<String> outcomes) {
    final l = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(l.outcomeTitle),
        children: [
          for (final o in outcomes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, o),
              child: Text(outcomeWord(l, o)),
            ),
        ],
      ),
    );
  }

  Future<void> _addNote() async {
    final l = AppLocalizations.of(context);
    final text = await askText(
      context,
      title: l.addNote,
      label: l.note,
      required: true,
      maxLines: 4,
    );
    if (text == null || !mounted) return;
    final wantsPhotos = await confirm(context, l.addPhotosQuestion);
    if (!mounted) return;
    final photos = wantsPhotos ? await pickPhotos(context) : const <String>[];
    if (!mounted) return;
    final ok = await act(
      context,
      ref,
      (api) => api.postFiles(
        '/tickets/${widget.id}/comments',
        {'body': text, 'client_ref': newRequestKey()},
        files: {if (photos.isNotEmpty) 'photos[]': photos},
      ),
      done: l.saved,
    );
    if (ok != null) _reload();
  }

  Future<void> _checkDbm(int clientId) async {
    final l = AppLocalizations.of(context);
    final res = await act(
      context,
      ref,
      (api) => api.post('/clients/$clientId/dbm'),
    );
    if (res == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.onuPower),
        content: Text(
          [
            if (res['rx_dbm'] != null) 'RX: ${res['rx_dbm']} dBm',
            if (res['tx_dbm'] != null) 'TX: ${res['tx_dbm']} dBm',
            pickString(res, const ['message']),
          ].whereType<String>().join('\n'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: Text(l.ok)),
        ],
      ),
    );
  }

  Future<void> _saveHouseLocation(int clientId) async {
    final l = AppLocalizations.of(context);
    if (!await confirm(context, l.saveHouseLocationQuestion) || !mounted) {
      return;
    }
    final p = await ref.read(locatorProvider)();
    if (!mounted) return;
    if (p == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.locationOff)));
      return;
    }
    final ok = await act(
      context,
      ref,
      (api) => api.post('/clients/$clientId/location', {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'accuracy': p.accuracy,
      }),
      done: l.saved,
    );
    if (ok != null) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));
    final api = ref.read(apiProvider);

    return WorkPage(
      title: '#${widget.id}',
      body: Loader(
        key: ValueKey(_version),
        load: (api) => api.get('/tickets/${widget.id}'),
        builder: (context, data, reload) {
          final t = asMap(data['ticket']);
          final client = asMap(t['client']);
          final clientId = toNum(client['id'])?.toInt();
          final can = asMap(t['can']);
          final onu = asMap(client['onu']);
          final steps = asList(t['next_statuses']).whereType<String>().toList();
          final comments = asList(t['comments']).map(asMap).toList();
          final install = asMap(t['install_details']);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                pickString(t, const ['subject']) ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  Tag(statusWord(l, pickString(t, const ['status']))),
                  Tag(
                    priorityWord(l, pickString(t, const ['priority'])),
                    tone: priorityColor(
                      context,
                      pickString(t, const ['priority']),
                    ),
                  ),
                  if (t['role'] == 'helper') Tag(l.roleHelper),
                ],
              ),
              const SizedBox(height: 12),
              if (pickString(t, const ['description']) != null)
                SectionCard(
                  children: [
                    Text(pickString(t, const ['description'])!),
                  ],
                ),
              if (client.isNotEmpty)
                SectionCard(
                  title: l.client,
                  children: [
                    InfoRow(l.name, pickString(client, const ['name'])),
                    InfoRow(l.clientId, pickString(client, const ['code'])),
                    InfoRow(l.address, pickString(client, const ['address'])),
                    InfoRow(
                      'PPPoE',
                      pickString(client, const ['pppoe_username']),
                    ),
                    if (onu.isNotEmpty)
                      InfoRow('ONU', pickString(onu, const ['sn', 'mac'])),
                    if (onu['last_rx_dbm'] != null)
                      InfoRow(l.lastRx, '${onu['last_rx_dbm']} dBm'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (pickString(client, const ['phone']) != null)
                          OutlinedButton.icon(
                            onPressed: () =>
                                callPhone(pickString(client, const ['phone'])),
                            icon: const Icon(Icons.call_outlined),
                            label: Text(l.call),
                          ),
                        if (client['location'] != null)
                          OutlinedButton.icon(
                            onPressed: () => openMap(client['location']),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(l.map),
                          ),
                        if (can['check_dbm'] == true && clientId != null)
                          OutlinedButton.icon(
                            onPressed: () => _checkDbm(clientId),
                            icon: const Icon(Icons.network_check),
                            label: Text(l.onuPower),
                          ),
                        if (can['set_location'] == true && clientId != null)
                          OutlinedButton.icon(
                            onPressed: () => _saveHouseLocation(clientId),
                            icon: const Icon(Icons.home_outlined),
                            label: Text(l.saveHouseLocation),
                          ),
                      ],
                    ),
                  ],
                ),
              if (steps.isNotEmpty && can['update_status'] == true)
                SectionCard(
                  title: l.nextStep,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in steps)
                          FilledButton.tonal(
                            onPressed: () => _step(t, s),
                            child: Text(statusWord(l, s)),
                          ),
                      ],
                    ),
                  ],
                ),
              if (t['new_connection'] == true)
                SectionCard(
                  title: l.newConnection,
                  children: [
                    if (t['installed_at'] != null) ...[
                      InfoRow(l.installedAt, when(t['installed_at'])),
                      InfoRow('ONU SN', pickString(install, const ['onu_sn'])),
                      InfoRow(
                        'ONU MAC',
                        pickString(install, const ['onu_mac']),
                      ),
                      InfoRow(l.router, pickString(install, const ['router'])),
                    ],
                    if (can['install'] == true)
                      FilledButton.icon(
                        onPressed: () async {
                          final done = await open<bool>(
                            context,
                            InstallScreen(ticketId: widget.id),
                          );
                          if (done == true) _reload();
                        },
                        icon: const Icon(Icons.router_outlined),
                        label: Text(l.recordInstall),
                      ),
                  ],
                ),
              if (can['use_materials'] == true || can['scan_items'] == true)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(l.materials),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open<void>(
                      context,
                      MaterialsScreen(
                        ticketId: widget.id,
                        canScan: can['scan_items'] == true,
                        canUse: can['use_materials'] == true,
                      ),
                    ),
                  ),
                ),
              if (user?.canAny(const ['tickets.assign', 'tickets.manage']) ??
                  false)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_search_outlined),
                    title: Text(l.assignTechnician),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await open<void>(
                        context,
                        AssignScreen(ticketId: widget.id),
                      );
                      _reload();
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.notes,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (can['comment'] == true)
                    TextButton.icon(
                      onPressed: _addNote,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: Text(l.addNote),
                    ),
                ],
              ),
              if (comments.isEmpty) Text(l.noNotes),
              for (final c in comments.reversed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pickString(asMap(c['user']), const ['name']) ?? ''} · ${when(c['created_at'])}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(pickString(c, const ['body']) ?? ''),
                        for (final p in asList(c['photos']).map(asMap))
                          if (pickString(p, const ['download_url', 'url']) !=
                              null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Image.network(
                                pickString(p, const ['download_url', 'url'])!,
                                headers: api.imageHeaders,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                      ],
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

/// STF-03b: parts used on the ticket (office stock) and scanned items.
class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({
    super.key,
    required this.ticketId,
    required this.canUse,
    required this.canScan,
  });
  final int ticketId;
  final bool canUse;
  final bool canScan;

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  int _version = 0;

  Future<void> _use(Json data) async {
    final l = AppLocalizations.of(context);
    final parts = asList(data['parts']).map(asMap).toList();
    if (parts.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noParts)));
      return;
    }
    final purposes = asList(data['purposes']).whereType<String>().toList();
    final done = await open<bool>(
      context,
      _UsePartsForm(
        ticketId: widget.ticketId,
        parts: parts,
        purposes: purposes,
        purpose:
            pickString(data, const ['default_purpose']) ??
            (purposes.isEmpty ? 'repair' : purposes.first),
      ),
    );
    if (done == true) setState(() => _version++);
  }

  Future<void> _scan() async {
    final l = AppLocalizations.of(context);
    final code = await askText(
      context,
      title: l.scanItem,
      label: l.scanCodeHint,
      required: true,
    );
    if (code == null || !mounted) return;
    final key = newRequestKey();
    final ok = await act(
      context,
      ref,
      (api) => api.post('/tickets/${widget.ticketId}/scan', {
        'code': code,
        'request_key': key,
      }),
      done: l.saved,
    );
    if (ok != null) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.materials,
      body: Loader(
        key: ValueKey(_version),
        load: (api) => api.get('/tickets/${widget.ticketId}/materials'),
        builder: (context, data, reload) {
          final used = asList(data['materials']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.canUse)
                    FilledButton.icon(
                      onPressed: () => _use(data),
                      icon: const Icon(Icons.add),
                      label: Text(l.useParts),
                    ),
                  if (widget.canScan)
                    OutlinedButton.icon(
                      onPressed: _scan,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(l.scanItem),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (used.isEmpty) MessageBanner(l.noMaterials),
              for (final m in used)
                Card(
                  child: ListTile(
                    title: Text(pickString(m, const ['name']) ?? ''),
                    subtitle: Text(
                      [
                        '${plainNumber(m['quantity'])} ${pickString(m, const ['unit']) ?? ''}'
                            .trim(),
                        if (m['purpose'] != null)
                          purposeWord(l, pickString(m, const ['purpose'])),
                        pickString(asMap(m['by']), const ['name']),
                        when(m['at']),
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

class _UsePartsForm extends ConsumerStatefulWidget {
  const _UsePartsForm({
    required this.ticketId,
    required this.parts,
    required this.purposes,
    required this.purpose,
  });
  final int ticketId;
  final List<Json> parts;
  final List<String> purposes;
  final String purpose;

  @override
  ConsumerState<_UsePartsForm> createState() => _UsePartsFormState();
}

class _UsePartsFormState extends ConsumerState<_UsePartsForm> {
  final Map<int, TextEditingController> _qty = {};
  final _note = TextEditingController();
  late String _purpose = widget.purpose;
  final _key = newRequestKey();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final p in widget.parts) {
      _qty[toNum(p['id'])!.toInt()] = TextEditingController();
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final lines = [
      for (final e in _qty.entries)
        if ((toNum(e.value.text) ?? 0) > 0)
          {'consumable_id': e.key, 'quantity': toNum(e.value.text)},
    ];
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.enterQuantity)));
      return;
    }
    setState(() => _busy = true);
    final ok = await act(
      context,
      ref,
      (api) => api.post('/tickets/${widget.ticketId}/materials', {
        'lines': lines,
        'purpose': _purpose,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
        'request_key': _key,
      }),
      done: l.saved,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.useParts,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: widget.purposes.contains(_purpose) ? _purpose : null,
            decoration: InputDecoration(labelText: l.purpose),
            items: [
              for (final p in widget.purposes)
                DropdownMenuItem(value: p, child: Text(purposeWord(l, p))),
            ],
            onChanged: (v) => setState(() => _purpose = v ?? _purpose),
          ),
          const SizedBox(height: 12),
          for (final p in widget.parts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pickString(p, const ['name'])} (${l.inStock}: ${plainNumber(p['in_stock'])} ${pickString(p, const ['unit']) ?? ''})',
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _qty[toNum(p['id'])!.toInt()],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l.quantity,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.noteOptional),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
        ],
      ),
    );
  }
}

/// STF-03b: the new line's "Installed" form (ONU SN/MAC, POP, router).
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
  Map<String, String> _errors = {};

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      await ref.read(apiProvider).post('/tickets/${widget.ticketId}/install', {
        'pop_id': _pop,
        'router_id': ?_router,
        if (_sn.text.trim().isNotEmpty) 'onu_sn': _sn.text.trim(),
        if (_mac.text.trim().isNotEmpty) 'onu_mac': _mac.text.trim(),
        if (_pon.text.trim().isNotEmpty) 'pon_port': _pon.text.trim(),
        if (_cable.text.trim().isNotEmpty)
          'cable_m': int.tryParse(_cable.text.trim()),
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.installSaved)));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _errors = {for (final k in e.errors.keys) k: e.errorFor(k)!},
      );
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
    return WorkPage(
      title: l.recordInstall,
      body: Loader(
        key: ValueKey(_loadedPop),
        load: (api) => api.get(
          '/tickets/${widget.ticketId}/install',
          query: {'pop_id': ?_loadedPop},
        ),
        builder: (context, data, reload) {
          final pops = asList(data['pops']).map(asMap).toList();
          final routers = asList(data['routers']).map(asMap).toList();
          _pop ??= toNum(data['pop_id'])?.toInt();
          if (_router == null && routers.length == 1) {
            _router = toNum(routers.first['id'])?.toInt();
          }
          if (data['can_install'] != true) return EmptyList(l.cannotInstall);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                initialValue: pops.any((p) => toNum(p['id'])?.toInt() == _pop)
                    ? _pop
                    : null,
                decoration: InputDecoration(
                  labelText: l.pop,
                  errorText: _errors['pop_id'],
                ),
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
                  _loadedPop = v;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue:
                    routers.any((r) => toNum(r['id'])?.toInt() == _router)
                    ? _router
                    : null,
                decoration: InputDecoration(
                  labelText: l.router,
                  errorText: _errors['router_id'],
                ),
                items: [
                  for (final r in routers)
                    DropdownMenuItem(
                      value: toNum(r['id'])!.toInt(),
                      child: Text(pickString(r, const ['name']) ?? ''),
                    ),
                ],
                onChanged: (v) => setState(() => _router = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sn,
                decoration: InputDecoration(
                  labelText: 'ONU SN',
                  errorText: _errors['onu_sn'],
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
                  labelText: l.ponPort,
                  errorText: _errors['pon_port'],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cable,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.cableMetres,
                  errorText: _errors['cable_m'],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: l.noteOptional,
                  errorText: _errors['note'],
                ),
              ),
              const SizedBox(height: 16),
              MessageBanner(l.installHint),
              FilledButton(
                onPressed: _busy || _pop == null ? null : _save,
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// STF-05: the office picks from the nearest technicians, or offers the job.
class AssignScreen extends ConsumerWidget {
  const AssignScreen({super.key, required this.ticketId});
  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.assignTechnician,
      body: Loader(
        load: (api) => api.get('/tickets/$ticketId/suggestions'),
        builder: (context, data, reload) {
          final list = asList(data['suggestions']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await act(
                    context,
                    ref,
                    (api) => api.post('/tickets/$ticketId/offer'),
                    done: l.offerSent,
                  );
                  if (ok != null && context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.campaign_outlined),
                label: Text(l.offerToNearest),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty) MessageBanner(l.noSuggestions),
              for (final s in list)
                Card(
                  child: ListTile(
                    title: Text(
                      pickString(asMap(s['user']), const ['name']) ?? '',
                    ),
                    subtitle: Text(
                      [
                        if (s['distance_m'] != null)
                          '${(toNum(s['distance_m'])! / 1000).toStringAsFixed(1)} km',
                        if (s['eta_min'] != null)
                          '${s['eta_min']} ${l.minutes}',
                        '${l.openTickets}: ${s['open_tickets'] ?? 0}',
                        if (s['busy'] == true) l.busy,
                      ].join(' · '),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () async {
                        final ok = await act(
                          context,
                          ref,
                          (api) => api.post('/tickets/$ticketId/assign', {
                            'user_id': asMap(s['user'])['id'],
                          }),
                          done: l.assigned,
                        );
                        if (ok != null && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(l.assign),
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

/// STF-05: job offers for a technician (take / no).
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureOffers,
      body: Loader(
        load: (api) => api.get('/offers'),
        builder: (context, data, reload) {
          final offers = asList(data['offers']).map(asMap).toList();
          if (offers.isEmpty) return EmptyList(l.noOffers);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final o in offers)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TicketCard(asMap(o['ticket'])),
                        Text(
                          [
                            if (o['distance_m'] != null)
                              '${(toNum(o['distance_m'])! / 1000).toStringAsFixed(1)} km',
                            if (o['seconds_left'] != null)
                              l.secondsLeft(toNum(o['seconds_left'])!.toInt()),
                          ].join(' · '),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  final ok = await act(
                                    context,
                                    ref,
                                    (api) =>
                                        api.post('/offers/${o['id']}/accept'),
                                    done: l.offerTaken,
                                  );
                                  if (ok != null) await reload();
                                },
                                child: Text(l.take),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final ok = await act(
                                    context,
                                    ref,
                                    (api) =>
                                        api.post('/offers/${o['id']}/reject'),
                                  );
                                  if (ok != null) await reload();
                                },
                                child: Text(l.decline),
                              ),
                            ),
                          ],
                        ),
                      ],
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

/// STF-07: open a ticket for a client (the ERP suggests technicians after).
class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key, required this.client});
  final Json client;

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String? _priority;
  int? _category;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.newTicket,
      body: Loader(
        load: (api) => api.get('/tickets/options'),
        builder: (context, data, reload) {
          final categories = asList(data['categories']).map(asMap).toList();
          final priorities = asList(data['priorities'])
              .whereType<String>()
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InfoRow(
                l.client,
                '${pickString(widget.client, const ['name']) ?? ''} · ${pickString(widget.client, const ['code']) ?? ''}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subject,
                decoration: InputDecoration(labelText: l.subject),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.descriptionOptional),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: InputDecoration(labelText: l.priority),
                items: [
                  for (final p in priorities)
                    DropdownMenuItem(value: p, child: Text(priorityWord(l, p))),
                ],
                onChanged: (v) => setState(() => _priority = v),
              ),
              const SizedBox(height: 12),
              if (categories.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _category,
                  decoration: InputDecoration(labelText: l.category),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(
                        value: toNum(c['id'])!.toInt(),
                        child: Text(pickString(c, const ['name']) ?? ''),
                      ),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        if (_subject.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.subjectRequired)),
                          );
                          return;
                        }
                        setState(() => _busy = true);
                        final ok = await act(
                          context,
                          ref,
                          (api) => api.post('/tickets', {
                            'client_id': widget.client['id'],
                            'subject': _subject.text.trim(),
                            if (_description.text.trim().isNotEmpty)
                              'description': _description.text.trim(),
                            'priority': ?_priority,
                            'ticket_category_id': ?_category,
                          }),
                          done: l.ticketOpened,
                        );
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        if (ok != null) Navigator.pop(context, true);
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
