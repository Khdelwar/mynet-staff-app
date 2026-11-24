import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/staff_api.dart';
import '../api/tickets.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';
import 'ticket_detail_screen.dart';
import 'ticket_labels.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  final _search = TextEditingController();
  final _tickets = <TicketSummary>[];
  String _status = 'active';
  String _scope = 'mine';
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  Object? _error;

  bool get _canSeeAll {
    final user = ref.read(authProvider).user;
    if (user == null) return false;
    return user.can('tickets.manage') || user.roles.contains('support');
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    final nextPage = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _tickets.clear();
    });
    try {
      final result = await ref
          .read(apiProvider)
          .tickets(
            scope: _canSeeAll ? _scope : 'mine',
            status: _status,
            q: _search.text,
            page: nextPage,
          );
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _lastPage = result.lastPage;
        _tickets.addAll(result.tickets);
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

  void _setStatus(String status) {
    if (status == _status) return;
    setState(() => _status = status);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureTickets)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              key: const ValueKey('ticket-search'),
              controller: _search,
              decoration: InputDecoration(
                labelText: l.ticketsSearch,
                suffixIcon: IconButton(
                  onPressed: () => _load(reset: true),
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _load(reset: true),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final status in const ['active', 'done', 'all'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        status == 'active'
                            ? l.ticketsActive
                            : status == 'done'
                            ? l.ticketsDone
                            : l.ticketsAny,
                      ),
                      selected: _status == status,
                      onSelected: (_) => _setStatus(status),
                    ),
                  ),
                if (_canSeeAll)
                  FilterChip(
                    key: const ValueKey('scope-all'),
                    label: Text(_scope == 'all' ? l.ticketsAll : l.ticketsMine),
                    selected: _scope == 'all',
                    onSelected: (_) {
                      setState(() => _scope = _scope == 'all' ? 'mine' : 'all');
                      _load(reset: true);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    MessageBanner(
                      errorText(l, _error!, l.errGeneric),
                      tone: BannerTone.error,
                    ),
                  if (_tickets.isEmpty && !_loading)
                    MessageBanner(l.ticketsEmpty),
                  for (final ticket in _tickets)
                    Card(
                      key: ValueKey('ticket-${ticket.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(ticket.subject),
                        subtitle: Text(
                          [
                            if (ticket.client?.name != null)
                              ticket.client!.name,
                            if (ticket.client?.code != null)
                              ticket.client!.code,
                            statusLabel(l, ticket.status),
                            if (ticket.priority != null)
                              priorityLabel(l, ticket.priority),
                            if (roleLabel(l, ticket.role).isNotEmpty)
                              roleLabel(l, ticket.role),
                            if (ticket.overdue) l.overdue,
                          ].whereType<String>().join(' · '),
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  TicketDetailScreen(ticketId: ticket.id),
                            ),
                          );
                          if (mounted) _load(reset: true);
                        },
                      ),
                    ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_loading && _page < _lastPage)
                    OutlinedButton(
                      onPressed: () => _load(reset: false),
                      child: Text(l.loadMore),
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
