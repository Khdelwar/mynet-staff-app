import '../l10n/app_localizations.dart';

String statusLabel(AppLocalizations l, String? status) {
  return switch (status) {
    'open' => l.statusOpen,
    'assigned' => l.statusAssigned,
    'scheduled' => l.statusScheduled,
    'on_the_way' => l.statusOnTheWay,
    'in_progress' => l.statusInProgress,
    'resolved' => l.statusResolved,
    'reopened' => l.statusReopened,
    'closed' => l.statusClosed,
    _ => status ?? '',
  };
}

String priorityLabel(AppLocalizations l, String? priority) {
  return switch (priority) {
    'low' => l.priorityLow,
    'medium' => l.priorityMedium,
    'high' => l.priorityHigh,
    'urgent' => l.priorityUrgent,
    _ => priority ?? '',
  };
}

String outcomeLabel(AppLocalizations l, String outcome) {
  return switch (outcome) {
    'done' => l.outcomeDone,
    'no_issue' => l.outcomeNoIssue,
    'duplicate' => l.outcomeDuplicate,
    'cancelled' => l.outcomeCancelled,
    _ => outcome,
  };
}

String roleLabel(AppLocalizations l, String? role) {
  return switch (role) {
    'main' => l.roleMain,
    'helper' => l.roleHelper,
    _ => '',
  };
}
