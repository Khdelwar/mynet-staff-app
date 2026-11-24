import 'json.dart';

class ClientPage {
  const ClientPage({
    required this.clients,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<ClientRow> clients;
  final int page;
  final int lastPage;
  final int total;

  factory ClientPage.fromJson(Object? raw) {
    final m = asMap(raw);
    return ClientPage(
      clients: [
        for (final row in listFrom(m, const ['clients']))
          ClientRow.fromJson(row),
      ],
      page: toNum(m['page'])?.toInt() ?? 1,
      lastPage: toNum(m['last_page'])?.toInt() ?? 1,
      total: toNum(m['total'])?.toInt() ?? 0,
    );
  }
}

class ClientRow {
  const ClientRow({
    required this.id,
    this.code,
    this.name,
    this.phone,
    this.address,
    this.status,
    this.packageName,
    this.packagePrice,
    this.expiryDate,
    this.due,
    this.advance,
    this.balance,
    this.seenOnline,
  });

  final int id;
  final String? code;
  final String? name;
  final String? phone;
  final String? address;
  final String? status;
  final String? packageName;
  final num? packagePrice;
  final String? expiryDate;
  final num? due;
  final num? advance;
  final num? balance;
  final bool? seenOnline;

  factory ClientRow.fromJson(Object? raw) {
    final m = asMap(raw);
    final package = asMap(m['package']);
    return ClientRow(
      id: toNum(m['id'])?.toInt() ?? 0,
      code: pickString(m, const ['code']),
      name: pickString(m, const ['name']),
      phone: pickString(m, const ['phone']),
      address: pickString(m, const ['address']),
      status: pickString(m, const ['status']),
      packageName: pickString(package, const ['name']),
      packagePrice: toNum(package['price']),
      expiryDate: pickString(m, const ['expiry_date']),
      due: toNum(m['due']),
      advance: toNum(m['advance']),
      balance: toNum(m['balance']),
      seenOnline: m['seen_online'] is bool ? m['seen_online'] as bool : null,
    );
  }
}

class ClientPayment {
  const ClientPayment({
    required this.id,
    this.receiptNo,
    this.amount,
    this.method,
    this.date,
    this.approvalStatus,
  });

  final int id;
  final String? receiptNo;
  final num? amount;
  final String? method;
  final String? date;
  final String? approvalStatus;

  factory ClientPayment.fromJson(Object? raw) {
    final m = asMap(raw);
    return ClientPayment(
      id: toNum(m['id'])?.toInt() ?? 0,
      receiptNo: pickString(m, const ['receipt_no']),
      amount: toNum(m['amount']),
      method: pickString(m, const ['method']),
      date: pickString(m, const ['date']),
      approvalStatus: pickString(m, const ['approval_status']),
    );
  }
}

class ClientTicket {
  const ClientTicket({
    required this.id,
    this.subject,
    this.status,
    this.priority,
  });

  final int id;
  final String? subject;
  final String? status;
  final String? priority;

  factory ClientTicket.fromJson(Object? raw) {
    final m = asMap(raw);
    return ClientTicket(
      id: toNum(m['id'])?.toInt() ?? 0,
      subject: pickString(m, const ['subject']),
      status: pickString(m, const ['status']),
      priority: pickString(m, const ['priority']),
    );
  }
}

class ClientDetail {
  const ClientDetail({
    required this.row,
    this.pppoeUsername,
    this.nid,
    this.pop,
    this.router,
    this.billingPolicy,
    this.onuSn,
    this.onuMac,
    this.lastRxDbm,
    this.openTickets = const [],
    this.recentPayments = const [],
    this.canUpdate = false,
    this.canOpenTicket = false,
  });

  final ClientRow row;
  final String? pppoeUsername;
  final String? nid;
  final String? pop;
  final String? router;
  final String? billingPolicy;
  final String? onuSn;
  final String? onuMac;
  final num? lastRxDbm;
  final List<ClientTicket> openTickets;
  final List<ClientPayment> recentPayments;
  final bool canUpdate;

  /// STF-07: may open a ticket for this client.
  final bool canOpenTicket;

  factory ClientDetail.fromJson(Object? raw) {
    final root = asMap(raw);
    final m = root['client'] is Map ? asMap(root['client']) : root;
    final onu = asMap(m['onu']);
    final can = asMap(m['can']);
    return ClientDetail(
      row: ClientRow.fromJson(m),
      pppoeUsername: pickString(m, const ['pppoe_username']),
      nid: pickString(m, const ['nid']),
      pop: pickString(m, const ['pop']),
      router: pickString(m, const ['router']),
      billingPolicy: pickString(m, const ['billing_policy']),
      onuSn: pickString(onu, const ['sn']),
      onuMac: pickString(onu, const ['mac']),
      lastRxDbm: toNum(onu['last_rx_dbm']),
      openTickets: m['open_tickets'] is List
          ? [
              for (final row in asList(m['open_tickets']))
                ClientTicket.fromJson(row),
            ]
          : const [],
      recentPayments: [
        for (final row in asList(m['recent_payments']))
          ClientPayment.fromJson(row),
      ],
      canUpdate: can['update'] == true,
      canOpenTicket: can['open_ticket'] == true,
    );
  }
}

class ClientConnection {
  const ClientConnection({
    this.online,
    this.since,
    this.lastDisconnectAt,
    this.disconnects24h,
  });

  final bool? online;
  final String? since;
  final String? lastDisconnectAt;
  final int? disconnects24h;

  factory ClientConnection.fromJson(Object? raw) {
    final m = asMap(raw);
    return ClientConnection(
      online: m['online'] is bool ? m['online'] as bool : null,
      since: pickString(m, const ['since']),
      lastDisconnectAt: pickString(m, const ['last_disconnect_at']),
      disconnects24h: toNum(m['disconnects_24h'])?.toInt(),
    );
  }
}
