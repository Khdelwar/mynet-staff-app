import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'common.dart';

String priorityLabel(AppLocalizations l, String? priority) {
  return switch (priority) {
    'low' => l.priorityLow,
    'medium' => l.priorityMedium,
    'high' => l.priorityHigh,
    'urgent' => l.priorityUrgent,
    _ => priority ?? '',
  };
}

/// Shown when a ticket notification is tapped before the ticket screen
/// has registered itself (STF-03).
class PushTicketPage extends StatelessWidget {
  const PushTicketPage({
    super.key,
    required this.ticketId,
    this.title,
    this.body,
    this.priority,
    this.helper = false,
    this.unassigned = false,
  });

  final int ticketId;
  final String? title;
  final String? body;
  final String? priority;
  final bool helper;
  final bool unassigned;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final headline = title ?? l.pushTicketTitle(ticketId);
    return Scaffold(
      appBar: AppBar(title: Text(l.pushTicketTitle(ticketId))),
      body: ListView(
        key: const ValueKey('push-ticket'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(headline, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          MessageBanner(
            unassigned
                ? l.pushTicketUnassigned
                : helper
                ? l.pushTicketHelper
                : l.pushTicketAssigned,
          ),
          SectionCard(
            children: [
              InfoRow(l.pushPriority, priorityLabel(l, priority)),
              if (body != null) InfoRow(l.pushFromNotification, body),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown when an offer notification is tapped before the offers screen
/// has registered itself (STF-05).
class PushOfferPage extends StatelessWidget {
  const PushOfferPage({super.key, this.offerId, this.ticketId});

  final int? offerId;
  final int? ticketId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.pushOfferTitle)),
      body: ListView(
        key: ValueKey('push-offer-$offerId'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.pushOfferTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          MessageBanner(l.pushOfferBody),
          if (ticketId != null)
            SectionCard(
              children: [InfoRow(l.pushTicketTitle(ticketId!), '#$ticketId')],
            ),
        ],
      ),
    );
  }
}
