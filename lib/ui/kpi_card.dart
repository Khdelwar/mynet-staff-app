import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/work.dart';
import 'theme.dart';

/// Colour of an ERP dashboard card (`components/dashboard/kpi-card.blade.php`):
/// band background (-200), band text (-900), band border (-300).
enum KpiTone {
  brand(Color(0xFFA7F3D0), Color(0xFF064E3B), Color(0xFF6EE7B7)),
  green(Color(0xFFA7F3D0), Color(0xFF064E3B), Color(0xFF6EE7B7)),
  red(Color(0xFFFECDD3), Color(0xFF881337), Color(0xFFFDA4AF)),
  amber(Color(0xFFFDE68A), Color(0xFF78350F), Color(0xFFFCD34D)),
  navy(Color(0xFFE2E8F0), Color(0xFF1E293B), Color(0xFFCBD5E1)),
  violet(Color(0xFFDDD6FE), Color(0xFF4C1D95), Color(0xFFC4B5FD)),
  sky(Color(0xFFBAE6FD), Color(0xFF0C4A6E), Color(0xFF7DD3FC));

  const KpiTone(this.band, this.text, this.border);
  final Color band;
  final Color text;
  final Color border;
}

/// Icon and colour per ERP KPI key, the same as `dashboard.blade.php`.
/// Only the look; the number is the ERP's, shown as it came.
(IconData, KpiTone) kpiStyle(Kpi kpi) {
  final positive = (kpi.value ?? 0) > 0;
  return switch (kpi.key) {
    'kpi_total' => (Icons.people_outline, KpiTone.navy),
    'kpi_active' => (Icons.how_to_reg_outlined, KpiTone.green),
    'kpi_active_offline' => (
      Icons.signal_cellular_alt,
      positive ? KpiTone.amber : KpiTone.navy,
    ),
    'kpi_expired' => (Icons.schedule, KpiTone.red),
    'kpi_expired_online' => (
      Icons.signal_cellular_alt,
      positive ? KpiTone.red : KpiTone.navy,
    ),
    'kpi_online' => (Icons.signal_cellular_alt, KpiTone.sky),
    'kpi_new' => (Icons.person_add_alt, KpiTone.violet),
    'kpi_due' => (Icons.error_outline, KpiTone.amber),
    'kpi_collected_today' => (Icons.payments_outlined, KpiTone.green),
    'kpi_income_today' => (Icons.insert_chart_outlined, KpiTone.violet),
    'kpi_collected_month' => (Icons.insert_chart_outlined, KpiTone.brand),
    'kpi_expense_today' ||
    'kpi_expense_total' => (Icons.account_balance_wallet_outlined, KpiTone.red),
    _ => (Icons.insert_chart_outlined, KpiTone.brand),
  };
}

final _whole = NumberFormat('#,##0', 'en');

/// The ERP card's number: `৳ 12,345` for money (whole taka, as the web
/// dashboard), `1,234` for counts.
String kpiValue(Kpi kpi) {
  final v = kpi.value;
  if (v == null) return '—';
  final text = _whole.format(v);
  return kpi.money ? '৳ $text' : text;
}

/// ERP dashboard card: a light band in the tone colour with the icon and
/// label, the big number on white below.
class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.kpi});
  final Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final (icon, tone) = kpiStyle(kpi);
    final band = dark
        ? Color.alphaBlend(
            tone.border.withValues(alpha: 0.18),
            ErpColors.sidebarBg,
          )
        : tone.band;
    final bandText = dark ? tone.border : tone.text;
    final bandLine = dark ? tone.border.withValues(alpha: 0.35) : tone.border;
    return Card(
      key: ValueKey('kpi-${kpi.key}'),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: band,
              border: Border(bottom: BorderSide(color: bandLine)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: bandText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    kpi.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: bandText,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                kpiValue(kpi),
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 23,
                  color: dark ? Colors.white : ErpColors.slate900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
