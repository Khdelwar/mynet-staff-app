import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/staff_api.dart';
import '../api/work.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'assign_screen.dart';
import 'clients_screen.dart' show erpAmount;
import 'common.dart';
import 'ticket_detail_screen.dart';
import 'ticket_labels.dart';

/// STF-07 support work: quick-add a client, fix a client's phone / address /
/// NID, and open a ticket. The ERP's QuickCreateClient, UpdateClientContact
/// and CreateTicket do the work with the web's rules (R15).

/// Asks a new value for `phone`, `address` or `nid` and sends it.
/// True when the ERP saved it.
Future<bool> editClientContact(
  BuildContext context,
  WidgetRef ref, {
  required int clientId,
  required String field,
  required String label,
  String? current,
}) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController(text: current ?? '');
  final value = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(label),
      content: TextField(
        key: const ValueKey('contact-value'),
        controller: controller,
        autofocus: true,
        keyboardType: field == 'phone' ? TextInputType.phone : null,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('contact-save'),
          onPressed: () => Navigator.of(dialog).pop(controller.text),
          child: Text(l.workSave),
        ),
      ],
    ),
  );
  if (value == null || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(apiProvider).updateClientContact(clientId, field, value);
    messenger.showSnackBar(SnackBar(content: Text(l.workSaved)));
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(errorText(l, e, l.errGeneric))),
    );
    return false;
  }
}

class NewClientScreen extends ConsumerStatefulWidget {
  const NewClientScreen({super.key});

  @override
  ConsumerState<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends ConsumerState<NewClientScreen> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  ClientFormOptions? _options;
  Object? _error;
  Map<String, String> _fieldErrors = const {};
  int? _package;
  int? _pop;
  int? _router;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final options = await ref.read(apiProvider).clientFormOptions();
      if (mounted) setState(() => _options = options);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final package = _package;
    if (_user.text.trim().isEmpty ||
        _password.text.isEmpty ||
        package == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workFillAll)));
      return;
    }
    setState(() {
      _busy = true;
      _fieldErrors = const {};
    });
    try {
      await ref
          .read(apiProvider)
          .createClient(
            pppoeUsername: _user.text,
            pppoePassword: _password.text,
            packageId: package,
            name: _name.text,
            phone: _phone.text,
            popId: _pop,
            routerId: _router,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.supportClientSaved)));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _fieldErrors = {for (final k in e.errors.keys) k: e.field(k)!},
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
    final options = _options;
    final routers = [
      for (final p in options?.pops ?? const <PopOption>[])
        if (p.id == _pop) ...p.routers,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.supportNewClient)),
      body: options == null
          ? (_error == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      MessageBanner(
                        errorText(l, _error!, l.errGeneric),
                        tone: BannerTone.error,
                      ),
                    ],
                  ))
          : ListView(
              key: const ValueKey('new-client'),
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  key: const ValueKey('nc-user'),
                  controller: _user,
                  decoration: InputDecoration(
                    labelText: l.supportPppoeUser,
                    errorText: _fieldErrors['pppoe_username'],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('nc-password'),
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: l.supportPppoePassword,
                    errorText: _fieldErrors['pppoe_password'],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: const ValueKey('nc-package'),
                  initialValue: _package,
                  decoration: InputDecoration(
                    labelText: l.clientsPackage,
                    errorText: _fieldErrors['package_id'],
                  ),
                  items: [
                    for (final p in options.packages)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (${erpAmount(p.price)})'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _package = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l.supportNameOptional,
                    errorText: _fieldErrors['name'],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l.supportPhoneOptional,
                    errorText: _fieldErrors['phone'],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _pop,
                  decoration: InputDecoration(
                    labelText: l.supportPopOptional,
                    errorText: _fieldErrors['pop_id'],
                  ),
                  items: [
                    for (final p in options.pops)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
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
                    decoration: InputDecoration(labelText: l.clientsRouter),
                    items: [
                      for (final r in routers)
                        DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ],
                    onChanged: (v) => setState(() => _router = v),
                  ),
                ],
                const SizedBox(height: 12),
                MessageBanner(l.supportNewClientHint),
                FilledButton(
                  key: const ValueKey('nc-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(l.workSave),
                ),
              ],
            ),
    );
  }
}

/// Opens a ticket for a client. People who assign go on to the nearest
/// technicians for it; others see the new ticket.
class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  final int clientId;
  final String clientName;

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  TicketOptions? _options;
  Object? _error;
  String? _priority;
  int? _category;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final options = await ref.read(apiProvider).ticketOptions();
      if (mounted) setState(() => _options = options);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_subject.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workFillAll)));
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(apiProvider)
          .createTicket(
            clientId: widget.clientId,
            subject: _subject.text,
            description: _description.text,
            priority: _priority,
            categoryId: _category,
          );
      if (!mounted) return;
      final user = ref.read(authProvider).user;
      final assigns =
          user != null &&
          (user.can('tickets.assign') || user.can('tickets.manage'));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.supportTicketOpened)));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => assigns
              ? AssignScreen(ticketId: id)
              : TicketDetailScreen(ticketId: id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(l, e, l.errGeneric))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = _options;
    return Scaffold(
      appBar: AppBar(title: Text(l.supportNewTicket)),
      body: ListView(
        key: const ValueKey('new-ticket'),
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            MessageBanner(
              errorText(l, _error!, l.errGeneric),
              tone: BannerTone.error,
            ),
          InfoRow(l.supportClient, widget.clientName),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('nt-subject'),
            controller: _subject,
            decoration: InputDecoration(labelText: l.supportSubject),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: InputDecoration(labelText: l.supportDetailsOptional),
          ),
          const SizedBox(height: 12),
          if (options != null) ...[
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: InputDecoration(labelText: l.pushPriority),
              items: [
                for (final p in options.priorities)
                  DropdownMenuItem(value: p, child: Text(priorityLabel(l, p))),
              ],
              onChanged: (v) => setState(() => _priority = v),
            ),
            if (options.categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l.supportCategory),
                items: [
                  for (final c in options.categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
            ],
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('nt-save'),
            onPressed: _busy ? null : _save,
            child: Text(l.workSave),
          ),
        ],
      ),
    );
  }
}
