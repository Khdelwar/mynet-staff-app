import 'dart:math';
import 'dart:typed_data';

import 'json.dart';

/// One idempotency key for a money call. Keep it until the ERP accepts it.
String newRequestKey() {
  final random = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => random.nextInt(256)),
  );
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class CollectionSummary {
  const CollectionSummary({
    this.collectedToday,
    this.inHand,
    this.notHandedOver,
    this.expenseAvailable,
    this.holdBlocked = false,
    this.holdMessage,
    this.canCash = false,
    this.canGateway = false,
    this.canExpense = false,
    this.canHandover = false,
    this.cashOwner,
    this.digitalOwner,
  });

  final num? collectedToday;
  final num? inHand;
  final num? notHandedOver;
  final num? expenseAvailable;
  final bool holdBlocked;
  final String? holdMessage;
  final bool canCash;
  final bool canGateway;
  final bool canExpense;
  final bool canHandover;
  final String? cashOwner;
  final String? digitalOwner;

  factory CollectionSummary.fromJson(Object? raw) {
    final m = asMap(raw);
    final hold = asMap(m['hold']);
    final can = asMap(m['can']);
    final owners = asMap(m['owners']);
    return CollectionSummary(
      collectedToday: toNum(m['collected_today']),
      inHand: toNum(m['in_hand']),
      notHandedOver: toNum(m['not_handed_over']),
      expenseAvailable: toNum(m['expense_available']),
      holdBlocked: hold['blocked'] == true,
      holdMessage: pickString(hold, const ['message']),
      canCash: can['cash'] == true,
      canGateway: can['gateway'] == true,
      canExpense: can['expense'] == true,
      canHandover: can['handover'] == true,
      cashOwner: pickString(owners, const ['cash']),
      digitalOwner: pickString(owners, const ['digital']),
    );
  }
}

class CollectionClient {
  const CollectionClient({
    required this.id,
    this.code,
    this.name,
    this.phone,
    this.due,
    this.balance,
    this.distanceM,
  });

  final int id;
  final String? code;
  final String? name;
  final String? phone;
  final num? due;
  final num? balance;

  /// Only in the "near me" search: metres from the phone, as the ERP worked it out.
  final num? distanceM;

  factory CollectionClient.fromJson(Object? raw) {
    final m = asMap(raw);
    return CollectionClient(
      id: toNum(m['id'])?.toInt() ?? 0,
      code: pickString(m, const ['code']),
      name: pickString(m, const ['name']),
      phone: pickString(m, const ['phone']),
      due: toNum(m['due']),
      balance: toNum(m['balance']),
      distanceM: toNum(m['distance_m']),
    );
  }
}

class PaymentReceipt {
  const PaymentReceipt({
    required this.replayed,
    this.receiptNo,
    this.amount,
    this.approvalStatus,
    this.paidSms,
    this.clientName,
    this.method,
  });

  final bool replayed;
  final String? receiptNo;
  final num? amount;
  final String? approvalStatus;
  final String? paidSms;
  final String? clientName;
  final String? method;

  factory PaymentReceipt.fromJson(Object? raw) {
    final root = asMap(raw);
    final payment = asMap(root['payment']);
    final client = asMap(payment['client']);
    return PaymentReceipt(
      replayed: root['replayed'] == true,
      receiptNo: pickString(payment, const ['receipt_no']),
      amount: toNum(payment['amount']),
      approvalStatus: pickString(payment, const ['approval_status']),
      paidSms: pickString(payment, const ['paid_sms']),
      clientName: pickString(client, const ['name']),
      method: pickString(payment, const ['method']),
    );
  }
}

class DuePage {
  const DuePage({
    required this.clients,
    required this.page,
    required this.lastPage,
  });

  final List<CollectionClient> clients;
  final int page;
  final int lastPage;

  factory DuePage.fromJson(Object? raw) {
    final m = asMap(raw);
    return DuePage(
      clients: [
        for (final row in listFrom(m, const ['clients']))
          CollectionClient.fromJson(row),
      ],
      page: toNum(m['page'])?.toInt() ?? 1,
      lastPage: toNum(m['last_page'])?.toInt() ?? 1,
    );
  }
}

class CashHandoverItem {
  const CashHandoverItem({
    required this.id,
    this.collector,
    this.amount,
    this.status,
    this.owner,
  });

  final int id;
  final String? collector;
  final num? amount;
  final String? status;
  final String? owner;

  factory CashHandoverItem.fromJson(Object? raw) {
    final m = asMap(raw);
    return CashHandoverItem(
      id: toNum(m['id'])?.toInt() ?? 0,
      collector: pickString(asMap(m['collector']), const ['name']),
      amount: toNum(m['amount']),
      status: pickString(m, const ['status']),
      owner: pickString(m, const ['owner']),
    );
  }
}

class ExpenseItem {
  const ExpenseItem({
    required this.id,
    this.collector,
    this.amount,
    this.note,
    this.status,
    this.receiptUrl,
  });

  final int id;
  final String? collector;
  final num? amount;
  final String? note;
  final String? status;

  /// STF-06b: the receipt photo (needs the Bearer token).
  final String? receiptUrl;

  factory ExpenseItem.fromJson(Object? raw) {
    final m = asMap(raw);
    return ExpenseItem(
      id: toNum(m['id'])?.toInt() ?? 0,
      collector: pickString(asMap(m['collector']), const ['name']),
      amount: toNum(m['amount']),
      note: pickString(m, const ['note']),
      status: pickString(m, const ['status']),
      receiptUrl: pickString(m, const ['receipt_url']),
    );
  }
}
