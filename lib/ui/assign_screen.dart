import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/offers.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';

/// Office: the nearest technicians for a ticket, then assign or start an offer.
/// Shown only when the user has `tickets.assign` or `tickets.manage`.
class AssignScreen extends ConsumerStatefulWidget {
  const AssignScreen({super.key});

  @override
  ConsumerState<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends ConsumerState<AssignScreen> {
  final _ticketId = TextEditingController();
  List<OfferTicket> _tickets = const [];
  List<TechnicianSuggestion> _suggestions = const [];
  int? _openId;
  Object? _error;
  bool _loading = false;
  bool _busy = false;
  bool _started = false;
  bool _listDenied = false;

  bool _canList(WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return user != null &&
        (user.can('tickets.view') || user.can('tickets.manage'));
  }

  @override
  void dispose() {
    _ticketId.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tickets = await ref.read(apiProvider).assignableTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 403) {
        setState(() {
          _listDenied = true;
          _loading = false;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _open(int id) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _openId = id;
      _error = null;
    });
    try {
      final rows = await ref.read(apiProvider).suggestions(id);
      if (!mounted) return;
      setState(() {
        _suggestions = rows;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(errorText(l, e, l.errGeneric));
    }
  }

  Future<void> _assign(TechnicianSuggestion person) async {
    final id = _openId;
    final l = AppLocalizations.of(context);
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).assignTicket(id, person.userId);
      if (!mounted) return;
      _show(l.assignDone(person.name));
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(errorText(l, e, l.errGeneric));
    }
  }

  Future<void> _offer() async {
    final id = _openId;
    final l = AppLocalizations.of(context);
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(apiProvider).offerTicket(id);
      if (!mounted) return;
      setState(() => _busy = false);
      _show(
        result.ok && result.offeredTo != null
            ? l.offerStarted(result.offeredTo!)
            : l.offerNobody,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(errorText(l, e, l.errGeneric));
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canList = _canList(ref) && !_listDenied;
    if (canList && !_started) {
      _started = true;
      _loading = true;
      Future.microtask(_loadTickets);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.featureAssign)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            MessageBanner(
              errorText(l, _error!, l.errGeneric),
              tone: BannerTone.error,
            ),
          if (canList) ...[
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_tickets.isEmpty)
              MessageBanner(l.assignNoTickets)
            else
              for (final ticket in _tickets)
                ListTile(
                  key: ValueKey('assign-ticket-${ticket.id}'),
                  title: Text(ticket.subject),
                  subtitle: Text(ticket.clientName ?? ''),
                  onTap: () => _open(ticket.id),
                ),
          ] else ...[
            TextField(
              key: const ValueKey('assign-ticket-id'),
              controller: _ticketId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.assignTicketId),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('assign-lookup'),
              onPressed: () {
                final id = int.tryParse(_ticketId.text.trim());
                if (id != null) _open(id);
              },
              child: Text(l.assignLookup),
            ),
          ],
          if (_openId != null) ...[
            const SizedBox(height: 12),
            Text(
              l.assignForTicket(_openId!),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_suggestions.isEmpty && !_busy) MessageBanner(l.assignNobody),
            for (final person in _suggestions)
              Card(
                key: ValueKey('suggestion-${person.userId}'),
                child: ListTile(
                  title: Text(person.name),
                  subtitle: Text(
                    [
                      l.assignScore(person.score.toStringAsFixed(1)),
                      if (person.distanceM != null)
                        l.offerDistance(person.distanceM!),
                      if (person.etaMin != null) l.assignEta(person.etaMin!),
                      if (person.busy) l.assignBusy,
                      if (person.sameArea) l.assignSameArea,
                    ].join(' · '),
                  ),
                  trailing: FilledButton(
                    key: ValueKey('assign-${person.userId}'),
                    onPressed: _busy ? null : () => _assign(person),
                    child: Text(l.assignButton),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('start-offer'),
              onPressed: _busy ? null : _offer,
              child: Text(l.assignOffer),
            ),
          ],
        ],
      ),
    );
  }
}
