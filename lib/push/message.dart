/// One staff push, parsed from FCM `data` (every value arrives as a string).
///
/// Types the ERP sends today: `ticket_assigned`, `ticket_helper`,
/// `ticket_offer`, and `ticket_unassigned` (office, when nobody took an offer).
class PushMessage {
  const PushMessage({
    required this.type,
    this.ticketId,
    this.offerId,
    this.priority,
    this.title,
    this.body,
    this.tapped = false,
  });

  final String type;
  final int? ticketId;
  final int? offerId;
  final String? priority;
  final String? title;
  final String? body;

  /// True when the person tapped the notification (tray or a killed start).
  /// A foreground arrival is false: show it, don't jump the screen.
  final bool tapped;

  bool get opensTicket =>
      ticketId != null &&
      (type == 'ticket_assigned' ||
          type == 'ticket_helper' ||
          type == 'ticket_unassigned');

  bool get opensOffer => type == 'ticket_offer';
}

/// Reads ERP `data`. Returns null when there is no `type`.
PushMessage? parsePush(
  Map<String, dynamic> data, {
  String? title,
  String? body,
  bool tapped = false,
}) {
  final type = data['type']?.toString().trim() ?? '';
  if (type.isEmpty) return null;
  return PushMessage(
    type: type,
    ticketId: _asInt(data['ticket_id']),
    offerId: _asInt(data['offer_id']),
    priority: _text(data['priority']),
    title: _text(title),
    body: _text(body),
    tapped: tapped,
  );
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
