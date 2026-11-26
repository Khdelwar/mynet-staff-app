import 'json.dart';

/// `GET /stock`: read-only stock, as the ERP's "My stock" and Stock pages.
class StockView {
  const StockView({
    this.myItems = const [],
    this.myParts = const [],
    this.officeParts = const [],
    this.canViewAll = false,
    this.statusCounts = const [],
    this.lowStockAlerts = 0,
    this.categories = const [],
    this.items = const StockPage<StockItem>(),
    this.parts = const StockPage<StockPart>(),
  });

  final List<StockItem> myItems;
  final List<StockPart> myParts;
  final List<StockPart> officeParts;

  /// `inventory.view|manage` on the ERP: the lists below are filled.
  final bool canViewAll;
  final List<StatusCount> statusCounts;
  final int lowStockAlerts;
  final List<(int, String)> categories;
  final StockPage<StockItem> items;
  final StockPage<StockPart> parts;

  factory StockView.fromJson(Object? raw) {
    final m = asMap(raw);
    final mine = asMap(m['mine']);
    final counts = asMap(m['counts']);
    return StockView(
      myItems: [for (final i in asList(mine['items'])) StockItem.fromJson(i)],
      myParts: [for (final p in asList(mine['parts'])) StockPart.fromJson(p)],
      officeParts: [
        for (final p in asList(m['parts_in_office'])) StockPart.fromJson(p),
      ],
      canViewAll: m['can_view_all'] == true,
      statusCounts: [
        for (final s in asList(counts['statuses'])) StatusCount.fromJson(s),
      ],
      lowStockAlerts: toNum(counts['low_stock_alerts'])?.toInt() ?? 0,
      categories: [
        for (final c in asList(m['categories']))
          (
            toNum(asMap(c)['id'])?.toInt() ?? 0,
            pickString(asMap(c), const ['name']) ?? '',
          ),
      ],
      items: StockPage.fromJson(m['items'], StockItem.fromJson),
      parts: StockPage.fromJson(m['parts'], StockPart.fromJson),
    );
  }
}

class StockPage<T> {
  const StockPage({
    this.rows = const [],
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
  });
  final List<T> rows;
  final int page;
  final int lastPage;
  final int total;

  bool get hasMore => page < lastPage;

  factory StockPage.fromJson(Object? raw, T Function(Object?) row) {
    final m = asMap(raw);
    return StockPage(
      rows: [for (final r in asList(m['data'])) row(r)],
      page: toNum(m['page'])?.toInt() ?? 1,
      lastPage: toNum(m['last_page'])?.toInt() ?? 1,
      total: toNum(m['total'])?.toInt() ?? 0,
    );
  }
}

class StatusCount {
  const StatusCount(this.status, this.label, this.count);
  final String status;
  final String label;
  final int count;

  factory StatusCount.fromJson(Object? raw) {
    final m = asMap(raw);
    final status = pickString(m, const ['status']) ?? '';
    return StatusCount(
      status,
      pickString(m, const ['label']) ?? status,
      toNum(m['count'])?.toInt() ?? 0,
    );
  }
}

class StockItem {
  const StockItem({
    required this.id,
    this.category,
    this.model,
    this.serial,
    this.mac,
    this.status = '',
    this.statusLabel,
    this.technician,
    this.clientName,
    this.clientCode,
  });

  final int id;
  final String? category;
  final String? model;
  final String? serial;
  final String? mac;
  final String status;
  final String? statusLabel;
  final String? technician;
  final String? clientName;
  final String? clientCode;

  factory StockItem.fromJson(Object? raw) {
    final m = asMap(raw);
    final client = asMap(m['client']);
    return StockItem(
      id: toNum(m['id'])?.toInt() ?? 0,
      category: pickString(m, const ['category']),
      model: pickString(m, const ['model']),
      serial: pickString(m, const ['serial', 'barcode']),
      mac: pickString(m, const ['mac']),
      status: pickString(m, const ['status']) ?? '',
      statusLabel: pickString(m, const ['status_label']),
      technician: pickString(m, const ['technician']),
      clientName: pickString(client, const ['name']),
      clientCode: pickString(client, const ['code']),
    );
  }
}

class StockPart {
  const StockPart({
    required this.id,
    required this.name,
    this.unit,
    this.quantity,
    this.category,
    this.low = false,
    this.useOnly = false,
  });

  final int id;
  final String name;
  final String? unit;
  final num? quantity;
  final String? category;
  final bool low;
  final bool useOnly;

  factory StockPart.fromJson(Object? raw) {
    final m = asMap(raw);
    return StockPart(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['name']) ?? '',
      unit: pickString(m, const ['unit']),
      quantity: toNum(m['quantity']) ?? toNum(m['in_stock']),
      category: pickString(m, const ['category']),
      low: m['low'] == true,
      useOnly: m['use_only'] == true,
    );
  }
}
