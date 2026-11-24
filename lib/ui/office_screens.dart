import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'kit.dart';
import 'words.dart';

/// STF-09: the dashboard boxes this user may see (numbers from the ERP's
/// DashboardMetricsService, unchanged).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureDashboard,
      body: Loader(
        load: (api) => api.get('/dashboard'),
        builder: (context, data, reload) {
          final kpis = asList(data['kpis']).map(asMap).toList();
          if (kpis.isEmpty) return EmptyList(l.noDashboard);
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              for (final k in kpis)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pickString(k, const ['label']) ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          child: Text(
                            k['money'] == true
                                ? money(k['value'])
                                : plainNumber(k['value']),
                            style: Theme.of(context).textTheme.titleLarge,
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

/// STF-09: own attendance, leave and advance (same rules as the web page).
class HrScreen extends ConsumerStatefulWidget {
  const HrScreen({super.key});

  @override
  ConsumerState<HrScreen> createState() => _HrScreenState();
}

class _HrScreenState extends ConsumerState<HrScreen> {
  String _month = thisMonth();
  int _version = 0;

  void _reload() => setState(() => _version++);

  Future<void> _askLeave() async {
    final l = AppLocalizations.of(context);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range == null || !mounted) return;
    final reason = await askText(
      context,
      title: l.leaveReason,
      label: l.leaveReason,
      required: true,
      maxLines: 2,
    );
    if (reason == null || !mounted) return;
    final unpaid = await confirm(context, l.leaveUnpaidQuestion);
    if (!mounted) return;
    String d(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final ok = await act(
      context,
      ref,
      (api) => api.post('/hr/leaves', {
        'pay': unpaid ? 'unpaid' : 'paid',
        'start_date': d(range.start),
        'end_date': d(range.end),
        'reason': reason,
      }),
      done: l.requestSent,
    );
    if (ok != null) _reload();
  }

  Future<void> _askAdvance() async {
    final l = AppLocalizations.of(context);
    final amount = await askText(
      context,
      title: l.askAdvance,
      label: l.amount,
      number: true,
      required: true,
    );
    if (amount == null || !mounted) return;
    final note = await askText(
      context,
      title: l.askAdvance,
      label: l.noteOptional,
    );
    if (note == null || !mounted) return;
    final ok = await act(
      context,
      ref,
      (api) => api.post('/hr/advances', {
        'amount': toNum(amount),
        'month': _month,
        if (note.isNotEmpty) 'note': note,
      }),
      done: l.requestSent,
    );
    if (ok != null) _reload();
  }

  Future<void> _cancel(String path) async {
    final l = AppLocalizations.of(context);
    if (!await confirm(context, l.cancelRequestQuestion) || !mounted) return;
    final ok = await act(context, ref, (api) => api.post(path), done: l.saved);
    if (ok != null) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureHr,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 1),
              lastDate: now,
              initialDate: now,
            );
            if (picked != null) {
              setState(
                () => _month =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}',
              );
            }
          },
        ),
      ],
      body: Loader(
        key: ValueKey('$_month|$_version'),
        load: (api) => api.get('/hr/me', query: {'month': _month}),
        builder: (context, data, reload) {
          final att = asMap(data['attendance']);
          final counts = asMap(att['counts']);
          final leaves = asList(data['leaves']).map(asMap).toList();
          final advances = asList(data['advances']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title:
                    '${l.attendance} · ${pickString(data, const ['month']) ?? _month}',
                children: [
                  for (final c in counts.entries) InfoRow(c.key, '${c.value}'),
                  InfoRow(l.lateMinutes, '${att['late_minutes'] ?? 0}'),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _askLeave,
                    icon: const Icon(Icons.beach_access_outlined),
                    label: Text(l.askLeave),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _askAdvance,
                    icon: const Icon(Icons.savings_outlined),
                    label: Text(l.askAdvance),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.leaves, style: Theme.of(context).textTheme.titleMedium),
              if (leaves.isEmpty) Text(l.none),
              for (final v in leaves)
                Card(
                  child: ListTile(
                    title: Text(
                      '${pickString(v, const ['start_date'])} → ${pickString(v, const ['end_date'])} (${plainNumber(v['days'])})',
                    ),
                    subtitle: Text(
                      '${statusWord(l, pickString(v, const ['status']))} · ${pickString(v, const ['reason']) ?? ''}',
                    ),
                    trailing: v['can_cancel'] == true
                        ? TextButton(
                            onPressed: () =>
                                _cancel('/hr/leaves/${v['id']}/cancel'),
                            child: Text(l.cancel),
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: 16),
              Text(l.advances, style: Theme.of(context).textTheme.titleMedium),
              if (advances.isEmpty) Text(l.none),
              for (final a in advances)
                Card(
                  child: ListTile(
                    title: Text(
                      '${money(a['amount'])} · ${pickString(a, const ['month']) ?? ''}',
                    ),
                    subtitle: Text(
                      '${statusWord(l, pickString(a, const ['status']))} · ${pickString(a, const ['note']) ?? ''}',
                    ),
                    trailing: a['can_cancel'] == true
                        ? TextButton(
                            onPressed: () =>
                                _cancel('/hr/advances/${a['id']}/cancel'),
                            child: Text(l.cancel),
                          )
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// STF-07: support chat with clients (customer app chat).
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.featureChat,
      body: Loader(
        load: (api) => api.get('/chats'),
        builder: (context, data, reload) {
          final list = asList(data['conversations']).map(asMap).toList();
          if (list.isEmpty) return EmptyList(l.noChats);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final c in list)
                Card(
                  child: ListTile(
                    title: Text(
                      '${pickString(asMap(c['client']), const ['name']) ?? ''} · ${pickString(asMap(c['client']), const ['code']) ?? ''}',
                    ),
                    subtitle: Text(
                      pickString(c, const ['preview']) ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: (toNum(c['unread']) ?? 0) > 0
                        ? Badge(label: Text('${c['unread']}'))
                        : null,
                    onTap: () async {
                      await open<void>(
                        context,
                        ChatScreen(id: toNum(c['id'])!.toInt()),
                      );
                      await reload();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  int _version = 0;
  bool _busy = false;

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    setState(() => _busy = true);
    final ok = await act(
      context,
      ref,
      (api) => api.post('/chats/${widget.id}/messages', {'body': body}),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok != null) {
        _text.clear();
        _version++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return WorkPage(
      title: l.featureChat,
      body: Column(
        children: [
          Expanded(
            child: Loader(
              key: ValueKey(_version),
              load: (api) => api.get('/chats/${widget.id}'),
              builder: (context, data, reload) {
                final messages = asList(data['messages']).map(asMap).toList();
                return ListView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final m in messages.reversed)
                      Align(
                        alignment: m['sender'] == 'client'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: m['sender'] == 'client'
                                ? scheme.surfaceContainerHighest
                                : scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pickString(m, const ['body']) ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  pickString(asMap(m['staff']), const ['name']),
                                  when(m['created_at']),
                                ].whereType<String>().join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: l.writeMessage,
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A screen the ERP lists that this app version cannot open yet.
class NotInAppScreen extends StatelessWidget {
  const NotInAppScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [MessageBanner(l.useWebsite)],
      ),
    );
  }
}
