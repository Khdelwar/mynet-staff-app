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
  String get loginIdentifierInvalid =>
      'Enter the ERP email, or a mobile like 01711000001.';

  @override
  String get loginEmailInvalid => 'Enter the email address from the ERP.';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginWrong => 'Email or password is incorrect.';

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
  String get featureDueList => 'Due list';

  @override
  String get featureApprovals => 'Approvals';

  @override
  String get featureTickets => 'Tickets';

  @override
  String get featureClients => 'Clients';

  @override
  String get featureChat => 'Support chat';

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
  String get featureDuty => 'Duty';

  @override
  String get dutyStatus => 'Duty';

  @override
  String get dutyOn => 'On duty';

  @override
  String get dutyOff => 'Off duty';

  @override
  String get dutyStart => 'Start duty';

  @override
  String get dutyEnd => 'End duty';

  @override
  String get dutyHours => 'Duty hours';

  @override
  String get dutyTimezone => 'Time zone';

  @override
  String get dutyDistance => 'Distance today';

  @override
  String dutyMeters(int meters) {
    return '$meters m';
  }

  @override
  String get dutyOutsideHours => 'Duty can only start during duty hours.';

  @override
  String get dutyStopped => 'Duty ended. Location has stopped.';

  @override
  String get dutyNotificationTitle => 'MyNet: location on';

  @override
  String get dutyNotificationBody =>
      'Location is shared only while you are on duty.';

  @override
  String get featureOffers => 'Job offers';

  @override
  String get featureAssign => 'Assign a technician';

  @override
  String get offersEmpty => 'No offers waiting.';

  @override
  String get offerAccept => 'Accept';

  @override
  String get offerReject => 'No';

  @override
  String offerSeconds(int seconds) {
    return '${seconds}s left';
  }

  @override
  String offerDistance(int meters) {
    return '$meters m away';
  }

  @override
  String offerTicket(int id) {
    return 'Ticket #$id';
  }

  @override
  String offerAccepted(int id) {
    return 'You took ticket #$id.';
  }

  @override
  String get assignNoTickets => 'No open tickets to assign.';

  @override
  String get assignTicketId => 'Ticket number';

  @override
  String get assignLookup => 'Show nearest';

  @override
  String assignForTicket(int id) {
    return 'Nearest for ticket #$id';
  }

  @override
  String get assignNobody => 'Nobody on duty nearby.';

  @override
  String assignScore(String score) {
    return 'Score $score';
  }

  @override
  String assignEta(int minutes) {
    return '$minutes min';
  }

  @override
  String get assignBusy => 'Busy';

  @override
  String get assignSameArea => 'Same area';

  @override
  String get assignButton => 'Assign';

  @override
  String assignDone(String name) {
    return 'Assigned to $name.';
  }

  @override
  String get assignOffer => 'Offer to the nearest';

  @override
  String offerStarted(String name) {
    return 'Offered to $name.';
  }

  @override
  String get offerNobody => 'Nobody left to offer. The office has been told.';

  @override
  String get ticketsSearch => 'Name, ID or phone';

  @override
  String get ticketsActive => 'Open';

  @override
  String get ticketsDone => 'Finished';

  @override
  String get ticketsAny => 'Any status';

  @override
  String get ticketsMine => 'My tickets';

  @override
  String get ticketsAll => 'Everyone\'s tickets';

  @override
  String get ticketsEmpty => 'No tickets here.';

  @override
  String get loadMore => 'Load more';

  @override
  String get overdue => 'Over SLA';

  @override
  String get ticketStatus => 'Status';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusOnTheWay => 'On the way';

  @override
  String get statusInProgress => 'Working';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusReopened => 'Reopened';

  @override
  String get statusClosed => 'Closed';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get pushPriority => 'Priority';

  @override
  String pushTicketTitle(int id) {
    return 'Ticket #$id';
  }

  @override
  String get outcomeDone => 'Done';

  @override
  String get outcomeNoIssue => 'No issue';

  @override
  String get outcomeDuplicate => 'Duplicate';

  @override
  String get outcomeCancelled => 'Cancelled';

  @override
  String get roleMain => 'Main';

  @override
  String get roleHelper => 'Helper';

  @override
  String get ticketDescription => 'Details';

  @override
  String get ticketComments => 'Notes';

  @override
  String get ticketNoComments => 'No notes yet.';

  @override
  String get ticketNote => 'Note';

  @override
  String get ticketSend => 'Save';

  @override
  String get ticketNewConnectionHint =>
      'A new connection closes only with the client\'s PPPoE ID in the note.';

  @override
  String get ticketAwayTitle => 'Away from the house';

  @override
  String get ticketAwayHint =>
      'Why are you finishing from here? (at least 5 characters)';

  @override
  String get ticketFinishDistance => 'Distance from the house';

  @override
  String ticketMeters(int meters) {
    return '$meters m';
  }

  @override
  String get clientCode => 'Client ID';

  @override
  String get clientAddress => 'Address';

  @override
  String get clientPppoe => 'PPPoE';

  @override
  String get onuSn => 'ONU serial';

  @override
  String get onuMac => 'ONU MAC';

  @override
  String get onuPort => 'PON port';

  @override
  String get ticketCall => 'Call';

  @override
  String get ticketMap => 'Map';

  @override
  String get ticketLocation => 'Save house GPS';

  @override
  String get ticketSaveLocation => 'Save this spot as the client\'s house?';

  @override
  String get ticketLocationSaved => 'House location saved.';

  @override
  String get ticketLocationDenied =>
      'Location is off. Turn it on and try again.';

  @override
  String get ticketLocationMock =>
      'This looks like a fake GPS. Turn it off before saving the house.';

  @override
  String get ticketDbm => 'Check dBm';

  @override
  String get ticketDbmRx => 'RX dBm';

  @override
  String get ticketDbmTx => 'TX dBm';

  @override
  String get ticketDbmLevel => 'Level';

  @override
  String get ticketTakePhoto => 'Camera';

  @override
  String get ticketAddPhoto => 'Gallery';

  @override
  String ticketPhotoCount(int count) {
    return '$count photo(s)';
  }

  @override
  String get ticketPhotoLimit => 'A note can have up to 5 photos.';

  @override
  String get ticketPhotoTooBig => 'That photo is larger than 5 MB.';

  @override
  String get ticketCommentKept =>
      'No internet. The note stays on this phone and will be sent later.';

  @override
  String get pushNotice => 'New notification';

  @override
  String get pushOpen => 'Open';

  @override
  String get pushTicketAssigned => 'This ticket was assigned to you.';

  @override
  String get pushTicketHelper => 'You were added as a helper on this ticket.';

  @override
  String get pushTicketUnassigned =>
      'Nobody took this ticket. It is back with the office.';

  @override
  String get pushOfferTitle => 'Ticket offer';

  @override
  String get pushOfferBody => 'A nearby ticket was offered to you.';

  @override
  String get pushFromNotification => 'Opened from a notification.';

  @override
  String get devicesTitle => 'My phones';

  @override
  String get devicesEmpty => 'No phones are signed in.';

  @override
  String get devicesUnnamed => 'Phone';

  @override
  String get devicesThisPhone => 'This phone';

  @override
  String get devicesSignOut => 'Sign out';

  @override
  String get devicesSignOutThis =>
      'Sign this phone out? You will need to sign in again.';

  @override
  String get devicesSignOutOther =>
      'Sign that phone out? It will stop receiving staff notifications.';

  @override
  String get clientsSearch => 'Name, ID, phone or PPPoE';

  @override
  String get clientsEmpty => 'No clients.';

  @override
  String get clientsMore => 'More';

  @override
  String get clientsCode => 'ID';

  @override
  String get clientsAddress => 'Address';

  @override
  String get clientsStatus => 'Status';

  @override
  String get clientsPackage => 'Package';

  @override
  String get clientsPrice => 'Price';

  @override
  String get clientsExpiry => 'Expiry';

  @override
  String get clientsDue => 'Due';

  @override
  String get clientsAdvance => 'Advance';

  @override
  String get clientsBalance => 'Balance';

  @override
  String get clientsPppoe => 'PPPoE';

  @override
  String get clientsNid => 'NID';

  @override
  String get clientsPop => 'POP';

  @override
  String get clientsRouter => 'Router';

  @override
  String get clientsOnu => 'ONU';

  @override
  String get clientsRx => 'Last RX dBm';

  @override
  String get clientsConnection => 'Line status';

  @override
  String get clientsOnline => 'The line is online.';

  @override
  String get clientsOffline => 'The line is offline.';

  @override
  String clientsDisconnects(int count) {
    return '$count disconnects in 24 hours';
  }

  @override
  String get clientsOpenTickets => 'Open tickets';

  @override
  String get clientsPayments => 'Recent payments';

  @override
  String get chatsSearch => 'Client name, ID or phone';

  @override
  String get chatsEmpty => 'No conversations.';

  @override
  String chatsUnread(int count) {
    return '$count new';
  }

  @override
  String get chatsReply => 'Reply';

  @override
  String get collectionToday => 'Collected today';

  @override
  String get collectionInHand => 'Cash in hand';

  @override
  String get collectionNotHanded => 'Not handed over';

  @override
  String get collectionExpenseLeft => 'Left for expenses';

  @override
  String get collectionHold => 'Hand over cash before taking more.';

  @override
  String get collectionCash => 'Take cash';

  @override
  String get collectionExpense => 'Expense';

  @override
  String get collectionHandover => 'Hand over';

  @override
  String get collectionCashOwner => 'Cash owner';

  @override
  String get collectionDigitalOwner => 'Digital owner';

  @override
  String get collectionGateway => 'bKash / Nagad';

  @override
  String get collectionSearch => 'Name, ID, phone or PPPoE';

  @override
  String get collectionMore => 'More';

  @override
  String get collectionAmount => 'Amount';

  @override
  String get collectionNote => 'Note';

  @override
  String get collectionTxn => 'TrxID';

  @override
  String get collectionSave => 'Save';

  @override
  String get collectionReceipt => 'Receipt';

  @override
  String get collectionApproval => 'Approval';

  @override
  String get collectionPaidSms => 'Paid SMS';

  @override
  String get collectionSmsLater =>
      'The client is told after the office approves.';

  @override
  String get dueEmpty => 'Nobody is on the due list.';

  @override
  String get approvalsEmpty => 'Nothing is waiting for you.';

  @override
  String get approvalsApprove => 'Approve';

  @override
  String get featureDashboard => 'Dashboard';

  @override
  String get featureExpiring => 'Expiring clients';

  @override
  String get featureSales => 'Sell products';

  @override
  String get featureWallet => 'Wallet';

  @override
  String get workAdjustment => 'Package change';

  @override
  String get workAdvances => 'Advances';

  @override
  String get workAmount => 'Amount';

  @override
  String get workAskAdvance => 'Ask for advance';

  @override
  String get workAskLeave => 'Ask for leave';

  @override
  String get workAttendance => 'Attendance';

  @override
  String get workAvailable => 'Can spend';

  @override
  String get workAwaitingClient => 'Waiting for client ID';

  @override
  String get workCableMetres => 'Cable (metres)';

  @override
  String get workCannotInstall =>
      'Install details cannot be given on this ticket now (only the assigned technician, while the client is pending).';

  @override
  String get workClientSearch => 'Name, ID, phone or PPPoE';

  @override
  String get workClientsAdvance => 'Clients\' advance held';

  @override
  String get workCodeHint => 'Serial, barcode or SKU';

  @override
  String workConfirmRecharge(String amount, int months) {
    return 'Recharge for $months month(s), ৳ $amount?';
  }

  @override
  String get workCreditAlert => 'Your credit is nearly used up.';

  @override
  String get workCreditLimit => 'Credit limit';

  @override
  String get workCreditUsed => 'Credit used';

  @override
  String workDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get workEnterQuantity => 'Enter a quantity for at least one part.';

  @override
  String get workFillAll => 'Fill in everything needed.';

  @override
  String get workForNewConnection => 'For a new connection (client ID later)';

  @override
  String get workGiveClientId => 'Give ID';

  @override
  String get workInStock => 'In stock';

  @override
  String get workInstall => 'New line install';

  @override
  String get workInstallHint =>
      'Saving turns the line on and resolves the ticket.';

  @override
  String get workInstallSaved => 'Install saved.';

  @override
  String get workLateMinutes => 'Late (minutes)';

  @override
  String get workLeaves => 'Leave';

  @override
  String get workMaterials => 'Materials used';

  @override
  String get workMethod => 'Method';

  @override
  String get workMonths => 'Months';

  @override
  String get workNewExpiry => 'New expiry';

  @override
  String get workNoDashboard => 'No dashboard boxes for your login.';

  @override
  String get workNoExpiring => 'No clients expiring.';

  @override
  String get workNoMaterials => 'Nothing used on this ticket yet.';

  @override
  String get workNoSales => 'No sales yet.';

  @override
  String get workNoteOptional => 'Note (optional)';

  @override
  String get workOk => 'OK';

  @override
  String get workOldExpiry => 'Old expiry';

  @override
  String get workPayBank => 'Bank';

  @override
  String get workPayCash => 'Cash';

  @override
  String get workPayDigital => 'Digital';

  @override
  String get workPayDue => 'Due';

  @override
  String get workPayTotal => 'To pay';

  @override
  String get workPickClient => 'Choose client';

  @override
  String get workPonPort => 'PON port';

  @override
  String get workPrice => 'Price';

  @override
  String get workPurpose => 'Purpose';

  @override
  String get workPurposeLineWork => 'Line work';

  @override
  String get workPurposeNewConnection => 'New connection';

  @override
  String get workPurposeOther => 'Other';

  @override
  String get workPurposeRepair => 'Repair';

  @override
  String get workPurposeShift => 'Shifting';

  @override
  String get workQuantity => 'Qty';

  @override
  String get workReason => 'Reason';

  @override
  String get workReceiptAdded => 'Receipt photo added';

  @override
  String get workReceiptPhoto => 'Receipt photo';

  @override
  String get workRecentSales => 'My last sales';

  @override
  String get workRecharge => 'Recharge';

  @override
  String workRechargeDone(String expiry) {
    return 'Recharged. New expiry: $expiry';
  }

  @override
  String get workRechargePending =>
      'This client must be completed on the website first.';

  @override
  String get workRequestSent => 'Request sent.';

  @override
  String get workSave => 'Save';

  @override
  String get workSaved => 'Saved.';

  @override
  String get workScan => 'Scan / type code';

  @override
  String get workSell => 'Sell';

  @override
  String get workSold => 'Sold.';

  @override
  String get workSoldCash => 'Sold. The cash goes into your day-end handover.';

  @override
  String get workTransactions => 'Transactions';

  @override
  String get workUseParts => 'Use parts';

  @override
  String get workWalletAfter => 'Wallet after';

  @override
  String get workWalletBalance => 'Wallet balance';

  @override
  String get workWalletCharge => 'From wallet';

  @override
  String workWithinDays(int days) {
    return '$days d';
  }
}
