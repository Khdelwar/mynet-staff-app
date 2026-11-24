import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/clients.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'client_detail_screen.dart';
import 'common.dart';

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
  bool _loading = true;
  Object? _error;

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
    final next = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _clients.clear();
    });
    try {
      final result = await ref
          .read(apiProvider)
          .clients(q: _search.text, page: next);
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _lastPage = result.lastPage;
        _clients.addAll(result.clients);
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureClients)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const ValueKey('client-search'),
              controller: _search,
              decoration: InputDecoration(
                labelText: l.clientsSearch,
                suffixIcon: IconButton(
                  onPressed: () => _load(reset: true),
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _load(reset: true),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView(
                key: const ValueKey('clients'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        subtitle: Text(
                          [
                            if (client.code != null) client.code,
                            if (client.phone != null) client.phone,
                            if (client.status != null) client.status,
                          ].join(' · '),
                        ),
                        trailing: client.seenOnline == null
                            ? null
                            : Icon(
                                client.seenOnline!
                                    ? Icons.circle
                                    : Icons.circle_outlined,
                                size: 12,
                                color: client.seenOnline! ? Colors.green : null,
                              ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ClientDetailScreen(clientId: client.id),
                          ),
                        ),
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
