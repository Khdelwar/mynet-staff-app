import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/collection.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'collection_screen.dart';
import 'common.dart';
import 'note_photo.dart';

/// Handovers sent to this user as owner (R3) and other people's expenses
/// (R12). The ERP never lists one's own (R5) and checks every decision again.
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
  bool _busy = false;

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

  /// Asks the amount (approve: all or part) or the note (reject: required).
  Future<({String text})?> _ask({
    required String title,
    required String label,
    String initial = '',
    bool number = false,
    bool required = false,
  }) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<({String text})>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: TextField(
          key: const ValueKey('approval-input'),
          controller: controller,
          autofocus: true,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('approval-ok'),
            onPressed: () {
              final text = controller.text.trim();
              if (required && text.isEmpty) return;
              Navigator.of(dialog).pop((text: text));
            },
            child: Text(l.workOk),
          ),
        ],
      ),
    );
  }

  Future<void> _decide(Future<void> Function(StaffApi api) call) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await call(ref.read(apiProvider));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workSaved)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(l, e, l.errGeneric))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approveHandover(CashHandoverItem item) async {
    final l = AppLocalizations.of(context);
    final answer = await _ask(
      title: l.approvalsApprove,
      label: l.approvalsAcceptAmount,
      initial: shownAmount(item.amount).replaceAll('—', ''),
      number: true,
    );
    final amount = num.tryParse(answer?.text ?? '');
    if (amount == null || !mounted) return;
    await _decide((api) => api.approveHandover(item.id, amount: amount));
  }

  Future<void> _rejectHandover(CashHandoverItem item) async {
    final l = AppLocalizations.of(context);
    final answer = await _ask(
      title: l.approvalsReject,
      label: l.approvalsRejectNote,
      required: true,
    );
    if (answer == null || !mounted) return;
    await _decide((api) => api.rejectHandover(item.id, note: answer.text));
  }

  Future<void> _decideExpense(ExpenseItem item, {required bool approve}) async {
    final l = AppLocalizations.of(context);
    final answer = await _ask(
      title: approve ? l.approvalsApprove : l.approvalsReject,
      label: approve ? l.workNoteOptional : l.approvalsRejectNote,
      required: !approve,
    );
    if (answer == null || !mounted) return;
    await _decide(
      (api) => api.decideExpense(item.id, approve: approve, note: answer.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureApprovals)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
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
              if (_handovers.isNotEmpty)
                Text(l.approvalsHandovers, style: title),
              for (final item in _handovers)
                Card(
                  key: ValueKey('handover-${item.id}'),
                  child: ListTile(
                    title: Text(item.collector ?? '—'),
                    subtitle: Text(shownAmount(item.amount)),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        OutlinedButton(
                          key: ValueKey('reject-${item.id}'),
                          onPressed: _busy ? null : () => _rejectHandover(item),
                          child: Text(l.approvalsReject),
                        ),
                        FilledButton(
                          key: ValueKey('approve-${item.id}'),
                          onPressed: _busy || item.amount == null
                              ? null
                              : () => _approveHandover(item),
                          child: Text(l.approvalsApprove),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_expenses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l.approvalsExpenses, style: title),
              ],
              for (final item in _expenses)
                Card(
                  key: ValueKey('expense-${item.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${item.collector ?? '—'} · ${shownAmount(item.amount)}',
                        ),
                        if (item.note != null) Text(item.note!),
                        if (item.receiptUrl != null) ...[
                          const SizedBox(height: 8),
                          NotePhoto(url: item.receiptUrl!, authenticated: true),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: ValueKey('expense-reject-${item.id}'),
                                onPressed: _busy
                                    ? null
                                    : () =>
                                          _decideExpense(item, approve: false),
                                child: Text(l.approvalsReject),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                key: ValueKey('expense-approve-${item.id}'),
                                onPressed: _busy
                                    ? null
                                    : () => _decideExpense(item, approve: true),
                                child: Text(l.approvalsApprove),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
