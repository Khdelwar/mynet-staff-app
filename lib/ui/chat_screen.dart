import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/chats.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _search = TextEditingController();
  List<ChatThread> _threads = const [];
  Object? _error;
  bool _loading = true;

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiProvider).chats(q: _search.text);
      if (!mounted) return;
      setState(() {
        _threads = result.threads;
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
      appBar: AppBar(title: Text(l.featureChat)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const ValueKey('chat-search'),
              controller: _search,
              decoration: InputDecoration(labelText: l.chatsSearch),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                key: const ValueKey('chats'),
                physics: const AlwaysScrollableScrollPhysics(),
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
                  else if (_threads.isEmpty)
                    MessageBanner(l.chatsEmpty)
                  else
                    for (final thread in _threads)
                      ListTile(
                        key: ValueKey('chat-${thread.id}'),
                        title: Text(thread.clientName ?? '—'),
                        subtitle: Text(thread.preview ?? ''),
                        trailing: thread.unread > 0
                            ? Text(l.chatsUnread(thread.unread))
                            : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ChatThreadScreen(conversationId: thread.id),
                          ),
                        ),
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

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _body = TextEditingController();
  List<ChatMessage> _messages = const [];
  String? _clientName;
  Object? _error;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiProvider).chat(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _clientName = result.clientName;
        _messages = result.messages;
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

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty || _sending) return;
    final l = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      final message = await ref
          .read(apiProvider)
          .sendChat(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _sending = false;
      });
      _body.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(l, e, l.errGeneric))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_clientName ?? l.featureChat)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('chat-thread'),
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  MessageBanner(
                    errorText(l, _error!, l.errGeneric),
                    tone: BannerTone.error,
                  ),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  for (final message in _messages)
                    Align(
                      alignment: message.fromClient
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Text(message.body),
                      ),
                    ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chat-body'),
                      controller: _body,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: l.chatsReply,
                        counterText: '',
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('chat-send'),
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
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
