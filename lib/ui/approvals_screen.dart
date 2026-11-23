import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/collection.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'collection_screen.dart';
import 'common.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  List<CashHandoverItem> _handovers = const [];
  List<ExpenseItem> _expenses = const [];
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
      final result = await ref.read(apiProvider).collectionApprovals();
      if (!mounted) return;
      setState(() {
        _handovers = result.handovers;
        _expenses = result.expenses;
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

  Future<void> _approve(CashHandoverItem item) async {
    final amount = item.amount;
    if (amount == null) return;
    await ref.read(apiProvider).approveHandover(item.id, amount: amount);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureApprovals)),
      body: ListView(
        key: const ValueKey('approvals'),
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
          else if (_handovers.isEmpty && _expenses.isEmpty)
            MessageBanner(l.approvalsEmpty)
          else ...[
            for (final item in _handovers)
              ListTile(
                key: ValueKey('handover-${item.id}'),
                title: Text(item.collector ?? '—'),
                subtitle: Text(shownAmount(item.amount)),
                trailing: FilledButton(
                  key: ValueKey('approve-${item.id}'),
                  onPressed: () => _approve(item),
                  child: Text(l.approvalsApprove),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
