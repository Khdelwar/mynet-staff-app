import '../l10n/app_localizations.dart';

/// ERP words (status, priority…) in the user's language. An unknown word from
/// a newer ERP is shown as it came.

String statusWord(AppLocalizations l, String? s) => switch (s) {
  'open' => l.stOpen,
  'assigned' => l.stAssigned,
  'scheduled' => l.stScheduled,
  'on_the_way' => l.stOnTheWay,
  'in_progress' => l.stInProgress,
  'resolved' => l.stResolved,
  'reopened' => l.stReopened,
  'closed' => l.stClosed,
  'pending' => l.stPending,
  'pending_approval' => l.stPending,
  'approved' => l.stApproved,
  'rejected' => l.stRejected,
  'partial' => l.stPartial,
  'cancelled' => l.stCancelled,
  'active' => l.stActive,
  'expired' => l.stExpired,
  'suspended' => l.stSuspended,
  'done' => l.stDone,
  'awaiting_client' => l.stAwaitingClient,
  _ => s ?? '—',
};

String priorityWord(AppLocalizations l, String? p) => switch (p) {
  'urgent' => l.prUrgent,
  'high' => l.prHigh,
  'medium' => l.prMedium,
  'low' => l.prLow,
  _ => p ?? '—',
};

String outcomeWord(AppLocalizations l, String? o) => switch (o) {
  'done' => l.outDone,
  'no_issue' => l.outNoIssue,
  'duplicate' => l.outDuplicate,
  'cancelled' => l.outCancelled,
  _ => o ?? '—',
};

String purposeWord(AppLocalizations l, String? p) => switch (p) {
  'new_connection' => l.purNewConnection,
  'repair' => l.purRepair,
  'shift' => l.purShift,
  'line_work' => l.purLineWork,
  'other' => l.purOther,
  _ => p ?? '—',
};

String methodWord(AppLocalizations l, String? m) => switch (m) {
  'cash' => l.payCash,
  'due' => l.payDue,
  'digital' => l.payDigital,
  'bkash' => 'bKash',
  'nagad' => 'Nagad',
  'rocket' => 'Rocket',
  'upay' => 'Upay',
  'bank' => l.payBank,
  'bangla_qr' => 'Bangla QR',
  _ => m ?? '—',
};
