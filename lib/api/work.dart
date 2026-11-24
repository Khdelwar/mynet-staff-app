import 'json.dart';

/// Replies for the screens added after STF-10 parts 0 and 1: ticket
/// materials and install (STF-03b), product sales and the expense receipt
/// (STF-06b), reseller wallet and recharge (STF-08), dashboard and own HR
/// (STF-09). Shapes follow mynet-erp `docs/STAFF_APP_API.md`. Every number
/// is the ERP's; the app only shows it.

class NamedId {
  const NamedId(this.id, this.name);
  final int id;
  final String name;

  static List<NamedId> list(Object? raw) => [
    for (final row in asList(raw))
      if (toNum(asMap(row)['id']) != null)
        NamedId(
          toNum(asMap(row)['id'])!.toInt(),
          pickString(asMap(row), const ['name', 'label']) ?? '',
        ),
  ];
}

// --- STF-03b: materials and install on a ticket ---------------------------

class UsedMaterial {
  const UsedMaterial({
    required this.name,
    required this.quantity,
    this.unit,
    this.purpose,
    this.by,
    this.at,
  });

  final String name;
  final num quantity;
  final String? unit;
  final String? purpose;
  final String? by;
  final String? at;

  factory UsedMaterial.fromJson(Object? raw) {
    final m = asMap(raw);
    return UsedMaterial(
      name: pickString(m, const ['name']) ?? '',
      quantity: toNum(m['quantity']) ?? 0,
      unit: pickString(m, const ['unit']),
      purpose: pickString(m, const ['purpose']),
      by: pickString(asMap(m['by']), const ['name']),
      at: pickString(m, const ['at']),
    );
  }

  static List<UsedMaterial> list(Object? raw) => [
    for (final row in asList(raw)) UsedMaterial.fromJson(row),
  ];
}

class StockPart {
  const StockPart({
    required this.id,
    required this.name,
    this.unit,
    this.inStock = 0,
  });

  final int id;
  final String name;
  final String? unit;
  final num inStock;

  factory StockPart.fromJson(Object? raw) {
    final m = asMap(raw);
    return StockPart(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['name']) ?? '',
      unit: pickString(m, const ['unit']),
      inStock: toNum(m['in_stock']) ?? 0,
    );
  }
}

class MaterialsView {
  const MaterialsView({
    this.used = const [],
    this.parts = const [],
    this.purposes = const [],
    this.defaultPurpose,
  });

  final List<UsedMaterial> used;
  final List<StockPart> parts;
  final List<String> purposes;
  final String? defaultPurpose;

  factory MaterialsView.fromJson(Object? raw) {
    final m = asMap(raw);
    return MaterialsView(
      used: UsedMaterial.list(m['materials']),
      parts: [for (final p in asList(m['parts'])) StockPart.fromJson(p)],
      purposes: [
        for (final p in asList(m['purposes']))
          if (p is String) p,
      ],
      defaultPurpose: pickString(m, const ['default_purpose']),
    );
  }
}

class InstallForm {
  const InstallForm({
    this.canInstall = false,
    this.installedAt,
    this.details = const {},
    this.popId,
    this.routerId,
    this.pops = const [],
    this.routers = const [],
  });

  final bool canInstall;
  final String? installedAt;
  final Map<String, String> details;
  final int? popId;
  final int? routerId;
  final List<NamedId> pops;
  final List<NamedId> routers;

  factory InstallForm.fromJson(Object? raw) {
    final m = asMap(raw);
    return InstallForm(
      canInstall: m['can_install'] == true,
      installedAt: pickString(m, const ['installed_at']),
      details: {
        for (final e in asMap(m['details']).entries)
          if (e.value != null) e.key: '${e.value}',
      },
      popId: toNum(m['pop_id'])?.toInt(),
      routerId: toNum(m['router_id'])?.toInt(),
      pops: NamedId.list(m['pops']),
      routers: NamedId.list(m['routers']),
    );
  }
}

// --- STF-06b: product sales ------------------------------------------------

class ScannedProduct {
  const ScannedProduct({
    required this.kind,
    required this.code,
    required this.name,
    this.unit,
    this.inStock,
  });

  /// `item` (one serial) or `part` (counted).
  final String kind;
  final String code;
  final String name;
  final String? unit;
  final num? inStock;

  bool get isPart => kind == 'part';

  factory ScannedProduct.fromJson(Object? raw) {
    final m = asMap(asMap(raw)['found']);
    return ScannedProduct(
      kind: pickString(m, const ['kind']) ?? 'item',
      code: pickString(m, const ['code']) ?? '',
      name: pickString(m, const ['name']) ?? '',
      unit: pickString(m, const ['unit']),
      inStock: toNum(m['in_stock']),
    );
  }
}

class SaleItem {
  const SaleItem({
    required this.id,
    required this.name,
    required this.price,
    this.payment,
    this.paymentMethod,
    this.status,
    this.clientCode,
    this.cashToHandover = false,
    this.at,
  });

  final int id;
  final String name;
  final num price;
  final String? payment;
  final String? paymentMethod;
  final String? status;
  final String? clientCode;
  final bool cashToHandover;
  final String? at;

  bool get awaitingClient => status == 'awaiting_client';

  factory SaleItem.fromJson(Object? raw) {
    final m = asMap(raw);
    return SaleItem(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['name']) ?? '',
      price: toNum(m['price']) ?? 0,
      payment: pickString(m, const ['payment']),
      paymentMethod: pickString(m, const ['payment_method']),
      status: pickString(m, const ['status']),
      clientCode: pickString(asMap(m['client']), const ['code']),
      cashToHandover: m['cash_to_handover'] == true,
      at: pickString(m, const ['at']),
    );
  }

  static List<SaleItem> list(Object? raw) => [
    for (final row in asList(raw)) SaleItem.fromJson(row),
  ];
}

class SalesView {
  const SalesView({
    this.awaiting = const [],
    this.recent = const [],
    this.digitalMethods = const [],
  });

  final List<SaleItem> awaiting;
  final List<SaleItem> recent;
  final List<String> digitalMethods;

  factory SalesView.fromJson(Object? raw) {
    final m = asMap(raw);
    return SalesView(
      awaiting: SaleItem.list(m['awaiting_client']),
      recent: SaleItem.list(m['recent']),
      digitalMethods: [
        for (final d in asList(m['digital_methods']))
          if (d is String) d,
      ],
    );
  }
}

// --- STF-08: reseller ---------------------------------------------------

class WalletTx {
  const WalletTx({
    required this.amount,
    this.type,
    this.balanceAfter,
    this.note,
    this.at,
  });
  final num amount;
  final String? type;
  final num? balanceAfter;
  final String? note;
  final String? at;

  factory WalletTx.fromJson(Object? raw) {
    final m = asMap(raw);
    return WalletTx(
      amount: toNum(m['amount']) ?? 0,
      type: pickString(m, const ['type']),
      balanceAfter: toNum(m['balance_after']),
      note: pickString(m, const ['note']),
      at: pickString(m, const ['at']),
    );
  }
}

class ResellerWallet {
  const ResellerWallet({
    this.balance,
    this.creditLimit,
    this.creditUsed,
    this.available,
    this.creditAlert = false,
    this.clientsAdvanceHeld,
    this.transactions = const [],
  });

  final num? balance;
  final num? creditLimit;
  final num? creditUsed;
  final num? available;
  final bool creditAlert;
  final num? clientsAdvanceHeld;
  final List<WalletTx> transactions;

  factory ResellerWallet.fromJson(Object? raw) {
    final m = asMap(raw);
    return ResellerWallet(
      balance: toNum(m['balance']),
      creditLimit: toNum(m['credit_limit']),
      creditUsed: toNum(m['credit_used']),
      available: toNum(m['available']),
      creditAlert: m['credit_alert'] != null && m['credit_alert'] != false,
      clientsAdvanceHeld: toNum(m['clients_advance_held']),
      transactions: [
        for (final t in asList(m['transactions'])) WalletTx.fromJson(t),
      ],
    );
  }
}

class ExpiringClient {
  const ExpiringClient({
    required this.id,
    required this.name,
    this.code,
    this.phone,
    this.packageName,
    this.expiryDate,
    this.daysLeft,
    this.due,
  });

  final int id;
  final String name;
  final String? code;
  final String? phone;
  final String? packageName;
  final String? expiryDate;
  final int? daysLeft;
  final num? due;

  factory ExpiringClient.fromJson(Object? raw) {
    final m = asMap(raw);
    return ExpiringClient(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['name']) ?? '',
      code: pickString(m, const ['code']),
      phone: pickString(m, const ['phone']),
      packageName: pickString(asMap(m['package']), const ['name']),
      expiryDate: pickString(m, const ['expiry_date']),
      daysLeft: toNum(m['days_left'])?.toInt(),
      due: toNum(m['due']),
    );
  }
}

class RechargeQuote {
  const RechargeQuote({
    this.months = 1,
    this.amount,
    this.adjustment,
    this.payTotal,
    this.oldExpiry,
    this.newExpiry,
    this.walletCharge,
    this.walletBalance,
    this.walletAfter,
    this.methods = const [],
    this.pending = false,
  });

  final int months;
  final num? amount;
  final num? adjustment;
  final num? payTotal;
  final String? oldExpiry;
  final String? newExpiry;
  final num? walletCharge;
  final num? walletBalance;
  final num? walletAfter;

  /// `id` is sent back; `name` is the ERP's label.
  final List<({String id, String label})> methods;

  /// The client must be completed on the website first.
  final bool pending;

  factory RechargeQuote.fromJson(Object? raw) {
    final m = asMap(raw);
    return RechargeQuote(
      months: toNum(m['months'])?.toInt() ?? 1,
      amount: toNum(m['amount']),
      adjustment: toNum(m['upgrade_adjustment']),
      payTotal: toNum(m['pay_total']),
      oldExpiry: pickString(m, const ['old_expiry']),
      newExpiry: pickString(m, const ['new_expiry']),
      walletCharge: toNum(m['wallet_charge']),
      walletBalance: toNum(m['wallet_balance']),
      walletAfter: toNum(m['wallet_after']),
      methods: [
        for (final row in asList(m['methods']))
          if (pickString(asMap(row), const ['id']) != null)
            (
              id: pickString(asMap(row), const ['id'])!,
              label: pickString(asMap(row), const ['label', 'id'])!,
            ),
      ],
      pending: m['pending'] == true,
    );
  }
}

// --- STF-09: dashboard and own HR ----------------------------------------

class Kpi {
  const Kpi({required this.label, this.value, this.money = false});
  final String label;
  final num? value;
  final bool money;

  factory Kpi.fromJson(Object? raw) {
    final m = asMap(raw);
    return Kpi(
      label: pickString(m, const ['label', 'key']) ?? '',
      value: toNum(m['value']),
      money: m['money'] == true,
    );
  }
}

class HrRequest {
  const HrRequest({
    required this.id,
    this.status,
    this.canCancel = false,
    this.title = '',
    this.note,
  });

  final int id;
  final String? status;
  final bool canCancel;
  final String title;
  final String? note;
}

class HrView {
  const HrView({
    this.month,
    this.counts = const {},
    this.lateMinutes = 0,
    this.leaves = const [],
    this.advances = const [],
  });

  final String? month;
  final Map<String, num> counts;
  final int lateMinutes;
  final List<HrRequest> leaves;

  /// [HrRequest.title] holds the amount as the ERP sent it; the screen formats it.
  final List<({HrRequest request, num amount, String? month})> advances;

  factory HrView.fromJson(Object? raw) {
    final m = asMap(raw);
    final att = asMap(m['attendance']);
    return HrView(
      month: pickString(m, const ['month']),
      counts: {
        for (final e in asMap(att['counts']).entries)
          if (toNum(e.value) != null) e.key: toNum(e.value)!,
      },
      lateMinutes: toNum(att['late_minutes'])?.toInt() ?? 0,
      leaves: [
        for (final row in asList(m['leaves']).map(asMap))
          HrRequest(
            id: toNum(row['id'])?.toInt() ?? 0,
            status: pickString(row, const ['status']),
            canCancel: row['can_cancel'] == true,
            title:
                '${pickString(row, const ['start_date']) ?? ''} → ${pickString(row, const ['end_date']) ?? ''}',
            note: pickString(row, const ['reason']),
          ),
      ],
      advances: [
        for (final row in asList(m['advances']).map(asMap))
          (
            request: HrRequest(
              id: toNum(row['id'])?.toInt() ?? 0,
              status: pickString(row, const ['status']),
              canCancel: row['can_cancel'] == true,
              note: pickString(row, const ['note']),
            ),
            amount: toNum(row['amount']) ?? 0,
            month: pickString(row, const ['month']),
          ),
      ],
    );
  }
}

// --- STF-07: support (new client, contact, new ticket) -------------------

class PackageOption {
  const PackageOption(this.id, this.name, this.price);
  final int id;
  final String name;
  final num? price;
}

class PopOption {
  const PopOption(this.id, this.name, this.routers);
  final int id;
  final String name;
  final List<NamedId> routers;
}

/// What this user may pick in the quick-add form (packages they may sell).
class ClientFormOptions {
  const ClientFormOptions({this.packages = const [], this.pops = const []});
  final List<PackageOption> packages;
  final List<PopOption> pops;

  factory ClientFormOptions.fromJson(Object? raw) {
    final m = asMap(raw);
    return ClientFormOptions(
      packages: [
        for (final p in asList(m['packages']).map(asMap))
          if (toNum(p['id']) != null)
            PackageOption(
              toNum(p['id'])!.toInt(),
              pickString(p, const ['name']) ?? '',
              toNum(p['price']),
            ),
      ],
      pops: [
        for (final p in asList(m['pops']).map(asMap))
          if (toNum(p['id']) != null)
            PopOption(
              toNum(p['id'])!.toInt(),
              pickString(p, const ['name']) ?? '',
              NamedId.list(p['routers']),
            ),
      ],
    );
  }
}

class TicketOptions {
  const TicketOptions({this.categories = const [], this.priorities = const []});
  final List<NamedId> categories;
  final List<String> priorities;

  factory TicketOptions.fromJson(Object? raw) {
    final m = asMap(raw);
    return TicketOptions(
      categories: NamedId.list(m['categories']),
      priorities: [
        for (final p in asList(m['priorities']))
          if (p is String) p,
      ],
    );
  }
}
