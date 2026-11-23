/// Small helpers for reading loosely-shaped ERP JSON.
library;

typedef Json = Map<String, dynamic>;

Json asMap(Object? value) => value is Map
    ? value.map((k, v) => MapEntry(k.toString(), v))
    : <String, dynamic>{};

List<dynamic> asList(Object? value) => value is List ? value : const [];

/// Unwraps a single `{ data: {...} }` envelope.
Json unwrapData(Object? body) {
  final root = asMap(body);
  final data = root['data'];
  if (data is Map &&
      root.keys.every((k) => k == 'data' || k == 'meta' || k == 'links')) {
    return asMap(data);
  }
  return root;
}

/// First non-empty string (numbers are stringified) among [keys].
String? pickString(Json? record, List<String> keys) {
  if (record == null) return null;
  for (final key in keys) {
    final value = record[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num && value.isFinite) return value.toString();
  }
  return null;
}

String? firstString(List<Object?> candidates) {
  for (final c in candidates) {
    if (c is String && c.trim().isNotEmpty) return c.trim();
  }
  return null;
}

num? toNum(Object? value) {
  if (value is num) return value.isFinite ? value : null;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

/// A list found at the root, under one of [keys], or under `data`.
List<dynamic> listFrom(Object? raw, List<String> keys) {
  if (raw is List) return raw;
  final root = asMap(raw);
  for (final key in keys) {
    if (root[key] is List) return root[key] as List;
  }
  final data = root['data'];
  if (data is List) return data;
  final nested = asMap(data);
  for (final key in keys) {
    if (nested[key] is List) return nested[key] as List;
  }
  return const [];
}
