// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyNet Staff';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get languageToggle => 'বাংলা';

  @override
  String get notConfigured =>
      'This app is not set up for sign-in. Ask the office for the right app.';

  @override
  String get offlineBanner => 'No internet connection';

  @override
  String get errNetwork =>
      'Can\'t reach the ERP. Check your connection and try again.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get loginTitle => 'Staff sign-in';

  @override
  String get loginIdentifier => 'Email or mobile number';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginWrong => 'Email / mobile or password is incorrect.';

  @override
  String get loginHelp =>
      'Forgot your password? Ask the admin to set a new one.';

  @override
  String get showPassword => 'Show password';

  @override
  String get twoFactorTitle => 'Verification code';

  @override
  String get twoFactorCode => '6-digit code';

  @override
  String get twoFactorButton => 'Verify';

  @override
  String get twoFactorWrong => 'The code is wrong or has expired.';

  @override
  String get twoFactorSms => 'We sent a code by SMS.';

  @override
  String get twoFactorTelegram => 'We sent a code on Telegram.';

  @override
  String get twoFactorTotp => 'Open your authenticator app and enter its code.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabAccount => 'Account';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get staffCode => 'Staff code';

  @override
  String get designation => 'Designation';

  @override
  String get roles => 'Roles';

  @override
  String get noStaffProfile =>
      'This login has no staff profile in HR. Ask the admin to link one.';

  @override
  String get homeLoadFailed => 'Couldn\'t load your details.';

  @override
  String get yourWork => 'Your work';

  @override
  String get featureCollection => 'Bill collection';

  @override
  String get featureTickets => 'Tickets';

  @override
  String get featureClients => 'Clients';

  @override
  String get featureHr => 'Attendance, leave & advance';

  @override
  String get comingSoon => 'Coming in the next update';

  @override
  String get noFeatures =>
      'Your role has no app features yet. Use the ERP website.';

  @override
  String get accountTitle => 'Account';

  @override
  String get email => 'Email';

  @override
  String get mobile => 'Mobile';

  @override
  String get language => 'Language';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint =>
      'Ask for fingerprint, face or screen lock when the app opens.';

  @override
  String get appLockUnsupported =>
      'This phone has no fingerprint, face or screen lock set up.';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out of this phone?';

  @override
  String get lockTitle => 'MyNet Staff is locked';

  @override
  String get lockReason => 'Unlock MyNet Staff';

  @override
  String get unlock => 'Unlock';

  @override
  String get sessionEnded => 'You were signed out. Sign in again.';

  @override
  String get acceptAmount => 'Amount to accept';

  @override
  String get addExpense => 'Expense';

  @override
  String get addNote => 'Add note';

  @override
  String get addPhotosQuestion => 'Add photos to this note?';

  @override
  String get address => 'Address';

  @override
  String get adjustment => 'Package change';

  @override
  String get advance => 'Advance';

  @override
  String get advances => 'Advances';

  @override
  String get alreadySaved =>
      'This was already saved earlier. Do not take the money again.';

  @override
  String get amount => 'Amount';

  @override
  String get amountPartOptional => 'Amount (empty = all)';

  @override
  String get approve => 'Approve';

  @override
  String get askAdvance => 'Ask for advance';

  @override
  String get askLeave => 'Ask for leave';

  @override
  String get assign => 'Assign';

  @override
  String get assignTechnician => 'Nearest technicians';

  @override
  String get assigned => 'Assigned.';

  @override
  String get attendance => 'Attendance';

  @override
  String get available => 'Can spend';

  @override
  String get awaitingClientId => 'Waiting for client ID';

  @override
  String get awayTitle => 'Far from the house';

  @override
  String get busy => 'busy';

  @override
  String get cableMetres => 'Cable (metres)';

  @override
  String get call => 'Call';

  @override
  String get cancelRequestQuestion => 'Cancel this request?';

  @override
  String get cannotInstall =>
      'This ticket cannot take install details now (only the assigned technician, while the client is pending).';

  @override
  String get cashHint =>
      'The line turns on now. The payment waits for the owner; the client\'s paid SMS goes after approval.';

  @override
  String get category => 'Category';

  @override
  String get client => 'Client';

  @override
  String get clientId => 'Client ID';

  @override
  String get clientSaved => 'Client saved.';

  @override
  String get clientSearchHint => 'Name, ID, phone or PPPoE';

  @override
  String get clientsAdvanceHeld => 'Clients\' advance held';

  @override
  String get collected => 'Collected';

  @override
  String get collectedBy => 'Collected by';

  @override
  String get collectedToday => 'Collected today';

  @override
  String confirmRecharge(String amount, String months) {
    return 'Recharge for $months month(s), $amount?';
  }

  @override
  String confirmTake(String amount, String name) {
    return 'Take $amount from $name?';
  }

  @override
  String get creditAlert => 'Your credit is nearly used up.';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String get creditUsed => 'Credit used';

  @override
  String get date => 'Date';

  @override
  String get dayEndHandover => 'Day-end handover';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get decline => 'No';

  @override
  String get descriptionOptional => 'Details (optional)';

  @override
  String get disconnects24h => 'Disconnects (24 h)';

  @override
  String get distance => 'Distance';

  @override
  String get due => 'Due';

  @override
  String get dutyEnded => 'Duty ended.';

  @override
  String get dutyHours => 'Duty hours';

  @override
  String get dutyLocationHint =>
      'Your location is asked when you start or end duty. Location is never taken off duty.';

  @override
  String get dutyStarted => 'Duty started.';

  @override
  String get dutyStatus => 'Duty';

  @override
  String get endDuty => 'End duty';

  @override
  String get enterQuantity => 'Enter a quantity for at least one part.';

  @override
  String get expenseAvailable => 'Can spend on expenses';

  @override
  String get expenseHint => 'Every expense waits for someone else\'s approval.';

  @override
  String get expenseSaved => 'Expense saved. It waits for approval.';

  @override
  String get expenses => 'Expenses';

  @override
  String get expiry => 'Expiry';

  @override
  String get featureApprovals => 'Approvals';

  @override
  String get featureChat => 'Support chat';

  @override
  String get featureDashboard => 'Dashboard';

  @override
  String get featureDueList => 'Due list';

  @override
  String get featureDuty => 'Duty';

  @override
  String get featureExpenses => 'Expenses';

  @override
  String get featureExpiring => 'Expiring clients';

  @override
  String get featureOffers => 'Job offers';

  @override
  String get featureSales => 'Sell products';

  @override
  String get featureWallet => 'Wallet';

  @override
  String get fillAll => 'Fill in everything needed.';

  @override
  String get forNewConnection => 'For a new connection';

  @override
  String get forNewConnectionHint => 'The client ID is given later.';

  @override
  String get gateway => 'Gateway';

  @override
  String get giveClientId => 'Give ID';

  @override
  String get handoverDue => 'To hand over';

  @override
  String get handoverSent => 'Handover sent to the owner.';

  @override
  String get handovers => 'Handovers';

  @override
  String get holdBlocked => 'Your cash limit is reached. Hand over first.';

  @override
  String get inHand => 'In hand';

  @override
  String get inStock => 'In stock';

  @override
  String get installHint =>
      'Saving turns the line on from today and resolves the ticket.';

  @override
  String get installSaved => 'Install saved.';

  @override
  String get installedAt => 'Installed';

  @override
  String get lastDisconnect => 'Last disconnect';

  @override
  String get lastRx => 'Last RX power';

  @override
  String get lateMinutes => 'Late (minutes)';

  @override
  String get leaveReason => 'Reason';

  @override
  String get leaveUnpaidQuestion => 'Unpaid leave? (Cancel = paid leave)';

  @override
  String get leaves => 'Leave';

  @override
  String get liveConnection => 'Online now?';

  @override
  String get locationOff => 'Location is off or not allowed.';

  @override
  String get map => 'Map';

  @override
  String get materials => 'Materials used';

  @override
  String get method => 'Method';

  @override
  String get minutes => 'min';

  @override
  String get mobileOptional => 'Mobile (optional)';

  @override
  String get months => 'Months';

  @override
  String get myExpenses => 'My expenses (7 days)';

  @override
  String get name => 'Name';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get newClient => 'New client';

  @override
  String get newClientHint =>
      'Without a POP the client waits as pending; with a POP the line goes on now.';

  @override
  String get newConnection => 'New connection';

  @override
  String get newExpiry => 'New expiry';

  @override
  String get newTicket => 'New ticket';

  @override
  String get nextStep => 'Next step';

  @override
  String get noChats => 'No conversations.';

  @override
  String get noClients => 'No clients found.';

  @override
  String get noDashboard => 'No dashboard boxes for your login.';

  @override
  String get noDues => 'No dues.';

  @override
  String get noExpiring => 'No clients expiring.';

  @override
  String get noMaterials => 'Nothing used on this ticket yet.';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get noOffers => 'No job offers now.';

  @override
  String get noParts => 'The office has no parts in stock.';

  @override
  String get noPayments => 'No payments.';

  @override
  String get noSales => 'No sales yet.';

  @override
  String get noSuggestions => 'No technician on duty nearby.';

  @override
  String get noTickets => 'No tickets.';

  @override
  String get none => 'None.';

  @override
  String get note => 'Note';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteRequired => 'Note (required)';

  @override
  String get notes => 'Notes';

  @override
  String get nothingToApprove => 'Nothing waiting for you.';

  @override
  String get offDuty => 'Off duty';

  @override
  String get offerSent => 'Offered to the nearest technician.';

  @override
  String get offerTaken => 'The ticket is yours.';

  @override
  String get offerToNearest => 'Offer to the nearest';

  @override
  String get offline => 'Offline';

  @override
  String get ok => 'OK';

  @override
  String get oldExpiry => 'Old expiry';

  @override
  String get onDuty => 'On duty';

  @override
  String get online => 'Online';

  @override
  String get onuPower => 'ONU power';

  @override
  String get openTickets => 'Open tickets';

  @override
  String get outCancelled => 'Cancelled';

  @override
  String get outDone => 'Work done';

  @override
  String get outDuplicate => 'Duplicate';

  @override
  String get outNoIssue => 'No problem found';

  @override
  String get outcomeTitle => 'How did it end?';

  @override
  String get outsideDutyHours => 'Outside duty hours: duty cannot start now.';

  @override
  String get overdue => 'Late';

  @override
  String get ownerCash => 'Cash owner';

  @override
  String get ownerDigital => 'Digital owner';

  @override
  String get package => 'Package';

  @override
  String get payBank => 'Bank';

  @override
  String get payCash => 'Cash';

  @override
  String get payDigital => 'Digital';

  @override
  String get payDue => 'Due';

  @override
  String get payTotal => 'To pay';

  @override
  String get photoCamera => 'Camera';

  @override
  String get photoGallery => 'Gallery';

  @override
  String get pickClient => 'Choose client';

  @override
  String get ponPort => 'PON port';

  @override
  String get pop => 'POP';

  @override
  String get popOptional => 'POP (optional)';

  @override
  String get pppoePassword => 'PPPoE password';

  @override
  String get pppoeUser => 'PPPoE username';

  @override
  String get prHigh => 'High';

  @override
  String get prLow => 'Low';

  @override
  String get prMedium => 'Medium';

  @override
  String get prUrgent => 'Urgent';

  @override
  String get price => 'Price';

  @override
  String get priority => 'Priority';

  @override
  String get purLineWork => 'Line work';

  @override
  String get purNewConnection => 'New connection';

  @override
  String get purOther => 'Other';

  @override
  String get purRepair => 'Repair';

  @override
  String get purShift => 'Shifting';

  @override
  String get purpose => 'Purpose';

  @override
  String get quantity => 'Qty';

  @override
  String get receipt => 'Receipt';

  @override
  String get receiptNotImage =>
      'This receipt is not a picture. Open it on the ERP website.';

  @override
  String get receiptPhoto => 'Receipt photo';

  @override
  String get receiptPhotoAdded => 'Receipt photo added';

  @override
  String get recentPayments => 'Last payments';

  @override
  String get recentSales => 'My last sales';

  @override
  String get recharge => 'Recharge';

  @override
  String rechargeDone(String expiry) {
    return 'Recharged. New expiry: $expiry';
  }

  @override
  String get rechargePending =>
      'This client must be completed on the website first.';

  @override
  String get recordInstall => 'Record install';

  @override
  String get reject => 'Reject';

  @override
  String get requestSent => 'Request sent.';

  @override
  String get roleHelper => 'Helper';

  @override
  String get router => 'Router';

  @override
  String get sales => 'Sales';

  @override
  String get save => 'Save';

  @override
  String get saveHouseLocation => 'Save house GPS';

  @override
  String get saveHouseLocationQuestion =>
      'Are you standing at the client\'s house? Save this place as the house location?';

  @override
  String get saved => 'Saved.';

  @override
  String get scanCodeHint => 'Serial, barcode or SKU';

  @override
  String get scanItem => 'Scan / type code';

  @override
  String secondsLeft(int seconds) {
    return '$seconds s left';
  }

  @override
  String get sell => 'Sell';

  @override
  String get send => 'Send';

  @override
  String get since => 'Since';

  @override
  String get sold => 'Sold.';

  @override
  String get soldCashToHandover =>
      'Sold. The cash goes into your day-end handover.';

  @override
  String get stActive => 'Active';

  @override
  String get stApproved => 'Approved';

  @override
  String get stAssigned => 'Assigned';

  @override
  String get stAwaitingClient => 'Waiting for client ID';

  @override
  String get stCancelled => 'Cancelled';

  @override
  String get stClosed => 'Closed';

  @override
  String get stDone => 'Done';

  @override
  String get stExpired => 'Expired';

  @override
  String get stInProgress => 'Working';

  @override
  String get stOnTheWay => 'On the way';

  @override
  String get stOpen => 'Open';

  @override
  String get stPartial => 'Partly approved';

  @override
  String get stPending => 'Waiting';

  @override
  String get stRejected => 'Rejected';

  @override
  String get stReopened => 'Reopened';

  @override
  String get stResolved => 'Resolved';

  @override
  String get stScheduled => 'Scheduled';

  @override
  String get stSuspended => 'Suspended';

  @override
  String get startDuty => 'Start duty';

  @override
  String get startedAt => 'Started';

  @override
  String get status => 'Status';

  @override
  String get subject => 'Subject';

  @override
  String get subjectRequired => 'Write the subject.';

  @override
  String get take => 'Take';

  @override
  String get takeCash => 'Cash';

  @override
  String get takeTrx => 'bKash / Nagad TrxID';

  @override
  String get ticketOpened => 'Ticket opened.';

  @override
  String get ticketSearchHint => 'Subject, #ID, client';

  @override
  String get ticketsActive => 'Active';

  @override
  String get ticketsAll => 'All';

  @override
  String get ticketsDone => 'Done (30 days)';

  @override
  String get ticketsMine => 'Mine';

  @override
  String get transactions => 'Transactions';

  @override
  String get trxHint => 'The digital owner checks the TrxID before it counts.';

  @override
  String get trxId => 'TrxID';

  @override
  String get useParts => 'Use parts';

  @override
  String get useWebsite => 'Use the ERP website for this.';

  @override
  String get waitingHandovers => 'Handovers waiting';

  @override
  String get waitsForApproval =>
      'The client\'s paid SMS goes after the owner approves.';

  @override
  String get walletAfter => 'Wallet after';

  @override
  String get walletBalance => 'Wallet balance';

  @override
  String get walletCharge => 'From wallet';

  @override
  String get whatFor => 'What for';

  @override
  String withinDays(int days) {
    return '$days d';
  }

  @override
  String get writeMessage => 'Write a message';
}
