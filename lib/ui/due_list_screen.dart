import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/collection.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'collection_screen.dart';
import 'common.dart';

class DueListScreen extends ConsumerStatefulWidget {
  const DueListScreen({super.key});

  @override
  ConsumerState<DueListScreen> createState() => _DueListScreenState();
}

class _DueListScreenState extends ConsumerState<DueListScreen> {
  final _search = TextEditingController();
  final _clients = <CollectionClient>[];
  int _page = 1;
  int _lastPage = 1;
  Object? _error;
  bool _loading = true;

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
          .dueList(q: _search.text, page: next);
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
      appBar: AppBar(title: Text(l.featureDueList)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const ValueKey('due-search'),
              controller: _search,
              decoration: InputDecoration(labelText: l.collectionSearch),
              onSubmitted: (_) => _load(reset: true),
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('due-list'),
              children: [
                if (_error != null)
                  MessageBanner(
                    errorText(l, _error!, l.errGeneric),
                    tone: BannerTone.error,
                  ),
                if (_clients.isEmpty && !_loading) MessageBanner(l.dueEmpty),
                for (final client in _clients)
                  ListTile(
                    key: ValueKey('due-${client.id}'),
                    title: Text(client.name ?? '—'),
                    subtitle: Text(client.code ?? ''),
                    trailing: Text(shownAmount(client.due)),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_loading && _page < _lastPage)
                  OutlinedButton(
                    onPressed: () => _load(reset: false),
                    child: Text(l.collectionMore),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
