import 'json.dart';

class ChatThread {
  const ChatThread({
    required this.id,
    this.clientName,
    this.clientCode,
    this.preview,
    this.unread = 0,
    this.lastMessageAt,
  });

  final int id;
  final String? clientName;
  final String? clientCode;
  final String? preview;
  final int unread;
  final String? lastMessageAt;

  factory ChatThread.fromJson(Object? raw) {
    final m = asMap(raw);
    final client = asMap(m['client']);
    return ChatThread(
      id: toNum(m['id'])?.toInt() ?? 0,
      clientName: pickString(client, const ['name']),
      clientCode: pickString(client, const ['code']),
      preview: pickString(m, const ['preview']),
      unread: toNum(m['unread'])?.toInt() ?? 0,
      lastMessageAt: pickString(m, const ['last_message_at']),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    this.sender,
    this.staffName,
    this.createdAt,
  });

  final int id;
  final String body;
  final String? sender;
  final String? staffName;
  final String? createdAt;

  bool get fromClient => sender == 'client';

  factory ChatMessage.fromJson(Object? raw) {
    final m = asMap(raw);
    final staff = asMap(m['staff']);
    return ChatMessage(
      id: toNum(m['id'])?.toInt() ?? 0,
      body: pickString(m, const ['body']) ?? '',
      sender: pickString(m, const ['sender']),
      staffName: pickString(staff, const ['name']),
      createdAt: pickString(m, const ['created_at']),
    );
  }
}
