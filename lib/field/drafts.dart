import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// A ticket note kept on the phone until the ERP accepts it.
class PendingComment {
  const PendingComment({
    required this.ticketId,
    required this.body,
    required this.clientRef,
    this.photoPaths = const [],
  });

  final int ticketId;
  final String body;
  final String clientRef;
  final List<String> photoPaths;

  Map<String, Object?> toJson() => {
    'ticket_id': ticketId,
    'body': body,
    'client_ref': clientRef,
    'photos': photoPaths,
  };

  factory PendingComment.fromJson(Object? raw) {
    final m = raw is Map ? raw : const {};
    return PendingComment(
      ticketId: m['ticket_id'] is int
          ? m['ticket_id'] as int
          : int.tryParse('${m['ticket_id']}') ?? 0,
      body: m['body'] is String ? m['body'] as String : '',
      clientRef: m['client_ref'] is String ? m['client_ref'] as String : '',
      photoPaths: [
        for (final path
            in (m['photos'] is List ? m['photos'] as List : const []))
          if (path is String) path,
      ],
    );
  }
}

/// New random id for one note. The same id is sent again after a retry.
String newClientRef() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

abstract class DraftStore {
  Future<List<PendingComment>> read();
  Future<void> write(List<PendingComment> items);
}

class MemoryDraftStore implements DraftStore {
  List<PendingComment> items = [];

  @override
  Future<List<PendingComment>> read() async => List.of(items);

  @override
  Future<void> write(List<PendingComment> items) async {
    this.items = List.of(items);
  }
}

/// Notes are not secrets, but they are not language or the app lock, so they
/// stay in the app support directory rather than shared preferences.
class FileDraftStore implements DraftStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/pending_ticket_comments.json');
  }

  @override
  Future<List<PendingComment>> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [for (final item in raw) PendingComment.fromJson(item)];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> write(List<PendingComment> items) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }
}

extension DraftQueue on DraftStore {
  Future<List<PendingComment>> forTicket(int ticketId) async {
    final all = await read();
    return [
      for (final item in all)
        if (item.ticketId == ticketId) item,
    ];
  }

  Future<void> upsert(PendingComment comment) async {
    final all = await read();
    final next = [
      for (final item in all)
        if (item.clientRef != comment.clientRef) item,
      comment,
    ];
    await write(next);
  }

  Future<void> remove(String clientRef) async {
    final all = await read();
    await write([
      for (final item in all)
        if (item.clientRef != clientRef) item,
    ]);
  }
}
