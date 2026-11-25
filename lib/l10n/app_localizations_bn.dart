// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'আইএসপি স্টাফ';

  @override
  String get loading => 'লোড হচ্ছে…';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get back => 'পেছনে';

  @override
  String get languageToggle => 'English';

  @override
  String get notConfigured =>
      'এই অ্যাপে লগইন চালু নেই। অফিস থেকে সঠিক অ্যাপ নিন।';

  @override
  String get serverLabel => 'ERP ঠিকানা';

  @override
  String get serverHint => 'bill.example.com';

  @override
  String get serverHelp =>
      'আপনার কোম্পানির ERP-র ওয়েব ঠিকানা। না জানলে অফিসে জিজ্ঞেস করুন।';

  @override
  String get serverInvalid => 'https ওয়েব ঠিকানা দিন, যেমন bill.example.com';

  @override
  String get serverNotErp =>
      'এই ঠিকানায় ERP পাওয়া যায়নি। ঠিকানা দেখে আবার চেষ্টা করুন।';

  @override
  String get serverChange => 'বদলান';

  @override
  String get offlineBanner => 'ইন্টারনেট সংযোগ নেই';

  @override
  String get errNetwork =>
      'ERP-তে পৌঁছানো যাচ্ছে না। ইন্টারনেট দেখে আবার চেষ্টা করুন।';

  @override
  String get errGeneric => 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get fieldRequired => 'দরকার';

  @override
  String get loginTitle => 'স্টাফ লগইন';

  @override
  String get loginIdentifier => 'ইমেইল বা মোবাইল নম্বর';

  @override
  String get loginIdentifierInvalid =>
      'ERP ইমেইল দিন, অথবা 01711000001-এর মতো মোবাইল।';

  @override
  String get loginEmailInvalid => 'ERP-এর ইমেইল দিন।';

  @override
  String get loginPassword => 'পাসওয়ার্ড';

  @override
  String get loginButton => 'লগইন';

  @override
  String get loginWrong => 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।';

  @override
  String get loginHelp =>
      'পাসওয়ার্ড ভুলে গেছেন? অ্যাডমিনকে নতুন পাসওয়ার্ড দিতে বলুন।';

  @override
  String get showPassword => 'পাসওয়ার্ড দেখুন';

  @override
  String get twoFactorTitle => 'যাচাই কোড';

  @override
  String get twoFactorCode => '৬ সংখ্যার কোড';

  @override
  String get twoFactorButton => 'যাচাই করুন';

  @override
  String get twoFactorWrong => 'কোড ভুল বা মেয়াদ শেষ।';

  @override
  String get twoFactorSms => 'SMS-এ কোড পাঠানো হয়েছে।';

  @override
  String get twoFactorTelegram => 'Telegram-এ কোড পাঠানো হয়েছে।';

  @override
  String get twoFactorTotp => 'Authenticator অ্যাপ খুলে তার কোড দিন।';

  @override
  String get tabHome => 'হোম';

  @override
  String get tabAccount => 'অ্যাকাউন্ট';

  @override
  String hello(String name) {
    return 'স্বাগতম, $name';
  }

  @override
  String get staffCode => 'স্টাফ কোড';

  @override
  String get designation => 'পদ';

  @override
  String get roles => 'রোল';

  @override
  String get noStaffProfile =>
      'এই লগইনের সাথে HR-এ কোনো স্টাফ প্রোফাইল যুক্ত নেই। অ্যাডমিনকে যুক্ত করতে বলুন।';

  @override
  String get homeLoadFailed => 'আপনার তথ্য আনা গেল না।';

  @override
  String get yourWork => 'আপনার কাজ';

  @override
  String get featureCollection => 'বিল কালেকশন';

  @override
  String get featureDueList => 'বকেয়া তালিকা';

  @override
  String get featureApprovals => 'অনুমোদন';

  @override
  String get featureTickets => 'টিকেট';

  @override
  String get featureClients => 'ক্লায়েন্ট';

  @override
  String get featureChat => 'সাপোর্ট চ্যাট';

  @override
  String get featureHr => 'হাজিরা, ছুটি ও অগ্রিম';

  @override
  String get comingSoon => 'পরের আপডেটে আসছে';

  @override
  String get noFeatures =>
      'আপনার রোলে এখনো অ্যাপের কোনো কাজ নেই। ERP ওয়েবসাইট ব্যবহার করুন।';

  @override
  String get accountTitle => 'অ্যাকাউন্ট';

  @override
  String get email => 'ইমেইল';

  @override
  String get mobile => 'মোবাইল';

  @override
  String get language => 'ভাষা';

  @override
  String get appLock => 'অ্যাপ লক';

  @override
  String get appLockHint => 'অ্যাপ খুললে আঙুলের ছাপ, ফেস বা স্ক্রিন লক চাইবে।';

  @override
  String get appLockUnsupported =>
      'এই ফোনে আঙুলের ছাপ, ফেস বা স্ক্রিন লক চালু নেই।';

  @override
  String get logout => 'লগআউট';

  @override
  String get logoutConfirm => 'এই ফোন থেকে লগআউট করবেন?';

  @override
  String get lockTitle => 'আইএসপি স্টাফ লক করা';

  @override
  String get lockReason => 'আইএসপি স্টাফ আনলক করুন';

  @override
  String get unlock => 'আনলক';

  @override
  String get sessionEnded => 'আপনাকে লগআউট করা হয়েছে। আবার লগইন করুন।';

  @override
  String get featureDuty => 'ডিউটি';

  @override
  String get dutyStatus => 'ডিউটি';

  @override
  String get dutyOn => 'ডিউটিতে';

  @override
  String get dutyOff => 'ডিউটি বন্ধ';

  @override
  String get dutyStart => 'ডিউটি শুরু';

  @override
  String get dutyEnd => 'ডিউটি শেষ';

  @override
  String get dutyHours => 'ডিউটির সময়';

  @override
  String get dutyTimezone => 'সময় অঞ্চল';

  @override
  String get dutyDistance => 'আজকের দূরত্ব';

  @override
  String dutyMeters(int meters) {
    return '$meters মি';
  }

  @override
  String get dutyOutsideHours =>
      'ডিউটি শুধু ডিউটির সময়ের মধ্যে শুরু করা যায়।';

  @override
  String get dutyStopped => 'ডিউটি শেষ। লোকেশন বন্ধ হয়েছে।';

  @override
  String get dutyNotificationTitle => 'স্টাফ অ্যাপ: লোকেশন চালু';

  @override
  String get dutyNotificationBody => 'লোকেশন শুধু ডিউটিতে থাকাকালীন যায়।';

  @override
  String get featureOffers => 'কাজের অফার';

  @override
  String get featureAssign => 'টেকনিশিয়ান দিন';

  @override
  String get offersEmpty => 'কোনো অফার নেই।';

  @override
  String get offerAccept => 'নেব';

  @override
  String get offerReject => 'না';

  @override
  String offerSeconds(int seconds) {
    return 'আর $seconds সেকেন্ড';
  }

  @override
  String offerDistance(int meters) {
    return '$meters মিটার দূরে';
  }

  @override
  String offerTicket(int id) {
    return 'টিকেট #$id';
  }

  @override
  String offerAccepted(int id) {
    return 'আপনি টিকেট #$id নিয়েছেন।';
  }

  @override
  String get assignNoTickets => 'দেওয়ার মতো খোলা টিকেট নেই।';

  @override
  String get assignTicketId => 'টিকেট নম্বর';

  @override
  String get assignLookup => 'কাছের জন দেখুন';

  @override
  String assignForTicket(int id) {
    return 'টিকেট #$id-এর কাছের জন';
  }

  @override
  String get assignNobody => 'ডিউটিতে কাছে কেউ নেই।';

  @override
  String assignScore(String score) {
    return 'নম্বর $score';
  }

  @override
  String assignEta(int minutes) {
    return '$minutes মিনিট';
  }

  @override
  String get assignBusy => 'ব্যস্ত';

  @override
  String get assignSameArea => 'একই এলাকা';

  @override
  String get assignButton => 'দিন';

  @override
  String assignDone(String name) {
    return '$name-কে দেওয়া হয়েছে।';
  }

  @override
  String get assignOffer => 'কাছের জনকে অফার';

  @override
  String offerStarted(String name) {
    return '$name-কে অফার করা হয়েছে।';
  }

  @override
  String get offerNobody => 'আর কাউকে অফার করার নেই। অফিসকে জানানো হয়েছে।';

  @override
  String get ticketsSearch => 'নাম, আইডি বা ফোন';

  @override
  String get ticketsActive => 'খোলা';

  @override
  String get ticketsDone => 'শেষ';

  @override
  String get ticketsAny => 'সব স্ট্যাটাস';

  @override
  String get ticketsMine => 'আমার টিকেট';

  @override
  String get ticketsAll => 'সবার টিকেট';

  @override
  String get ticketsEmpty => 'এখানে কোনো টিকেট নেই।';

  @override
  String get loadMore => 'আরও দেখুন';

  @override
  String get overdue => 'সময় পার';

  @override
  String get ticketStatus => 'স্ট্যাটাস';

  @override
  String get statusOpen => 'খোলা';

  @override
  String get statusAssigned => 'দেওয়া হয়েছে';

  @override
  String get statusScheduled => 'সময় ধার্য';

  @override
  String get statusOnTheWay => 'রাস্তায়';

  @override
  String get statusInProgress => 'কাজ চলছে';

  @override
  String get statusResolved => 'সমাধান';

  @override
  String get statusReopened => 'আবার খোলা';

  @override
  String get statusClosed => 'বন্ধ';

  @override
  String get priorityLow => 'কম';

  @override
  String get priorityMedium => 'মাঝারি';

  @override
  String get priorityHigh => 'বেশি';

  @override
  String get priorityUrgent => 'জরুরি';

  @override
  String get pushPriority => 'অগ্রাধিকার';

  @override
  String pushTicketTitle(int id) {
    return 'টিকেট #$id';
  }

  @override
  String get outcomeDone => 'হয়ে গেছে';

  @override
  String get outcomeNoIssue => 'সমস্যা ছিল না';

  @override
  String get outcomeDuplicate => 'ডুপ্লিকেট';

  @override
  String get outcomeCancelled => 'বাতিল';

  @override
  String get roleMain => 'মূল দায়িত্ব';

  @override
  String get roleHelper => 'সহকারী';

  @override
  String get ticketDescription => 'বিবরণ';

  @override
  String get ticketComments => 'নোট';

  @override
  String get ticketNoComments => 'এখনো কোনো নোট নেই।';

  @override
  String get ticketNote => 'নোট';

  @override
  String get ticketSend => 'সেভ';

  @override
  String get ticketNewConnectionHint =>
      'নতুন লাইন বন্ধ করতে নোটে ক্লায়েন্টের PPPoE আইডি লাগবে।';

  @override
  String get ticketAwayTitle => 'বাসা থেকে দূরে';

  @override
  String get ticketAwayHint => 'এখান থেকে শেষ করছেন কেন? (কমপক্ষে ৫ অক্ষর)';

  @override
  String get ticketFinishDistance => 'বাসা থেকে দূরত্ব';

  @override
  String ticketMeters(int meters) {
    return '$meters মি';
  }

  @override
  String get clientCode => 'ক্লায়েন্ট আইডি';

  @override
  String get clientAddress => 'ঠিকানা';

  @override
  String get clientPppoe => 'PPPoE';

  @override
  String get onuSn => 'ONU সিরিয়াল';

  @override
  String get onuMac => 'ONU MAC';

  @override
  String get onuPort => 'PON পোর্ট';

  @override
  String get ticketCall => 'কল';

  @override
  String get ticketMap => 'ম্যাপ';

  @override
  String get ticketLocation => 'বাসার GPS সেভ';

  @override
  String get ticketSaveLocation =>
      'এই জায়গাটা ক্লায়েন্টের বাসা হিসেবে সেভ করবেন?';

  @override
  String get ticketLocationSaved => 'বাসার লোকেশন সেভ হয়েছে।';

  @override
  String get ticketLocationDenied =>
      'লোকেশন বন্ধ আছে। চালু করে আবার চেষ্টা করুন।';

  @override
  String get ticketLocationMock =>
      'এটা নকল GPS মনে হচ্ছে। বাসা সেভ করার আগে বন্ধ করুন।';

  @override
  String get ticketDbm => 'dBm দেখুন';

  @override
  String get ticketDbmRx => 'RX dBm';

  @override
  String get ticketDbmTx => 'TX dBm';

  @override
  String get ticketDbmLevel => 'লেভেল';

  @override
  String get ticketTakePhoto => 'ক্যামেরা';

  @override
  String get ticketAddPhoto => 'গ্যালারি';

  @override
  String ticketPhotoCount(int count) {
    return '$countটা ছবি';
  }

  @override
  String get ticketPhotoLimit => 'একটা নোটে সর্বোচ্চ ৫টা ছবি।';

  @override
  String get ticketPhotoTooBig => 'ছবিটা ৫ MB-এর বেশি।';

  @override
  String get ticketCommentKept =>
      'ইন্টারনেট নেই। নোটটা ফোনে থাকবে, পরে পাঠানো হবে।';

  @override
  String get pushNotice => 'নতুন নোটিফিকেশন';

  @override
  String get pushOpen => 'খুলুন';

  @override
  String get pushTicketAssigned => 'এই টিকেট আপনাকে দেওয়া হয়েছে।';

  @override
  String get pushTicketHelper => 'আপনাকে এই টিকেটের সহকারী করা হয়েছে।';

  @override
  String get pushTicketUnassigned =>
      'কেউ এই টিকেট নেয়নি। এটি অফিসের কাছে ফিরে গেছে।';

  @override
  String get pushOfferTitle => 'টিকেট অফার';

  @override
  String get pushOfferBody => 'কাছের একটি টিকেট আপনাকে দেওয়া হয়েছে।';

  @override
  String get pushFromNotification => 'নোটিফিকেশন থেকে খোলা হয়েছে।';

  @override
  String get devicesTitle => 'আমার ফোন';

  @override
  String get devicesEmpty => 'কোনো ফোন লগইন নেই।';

  @override
  String get devicesUnnamed => 'ফোন';

  @override
  String get devicesThisPhone => 'এই ফোন';

  @override
  String get devicesSignOut => 'সাইন আউট';

  @override
  String get devicesSignOutThis =>
      'এই ফোন থেকে সাইন আউট করবেন? আবার লগইন করতে হবে।';

  @override
  String get devicesSignOutOther =>
      'ওই ফোন থেকে সাইন আউট করবেন? সেখানে স্টাফ নোটিফিকেশন বন্ধ হবে।';

  @override
  String get clientsSearch => 'নাম, আইডি, ফোন, PPPoE বা ONU';

  @override
  String get clientsEmpty => 'কোনো ক্লায়েন্ট নেই।';

  @override
  String get clientsMore => 'আরও';

  @override
  String get clientsCode => 'আইডি';

  @override
  String get clientsAddress => 'ঠিকানা';

  @override
  String get clientsStatus => 'অবস্থা';

  @override
  String get clientsPackage => 'প্যাকেজ';

  @override
  String get clientsPrice => 'দাম';

  @override
  String get clientsExpiry => 'মেয়াদ';

  @override
  String get clientsDue => 'বকেয়া';

  @override
  String get clientsAdvance => 'অগ্রিম';

  @override
  String get clientsBalance => 'ব্যালেন্স';

  @override
  String get clientsPppoe => 'PPPoE';

  @override
  String get clientsNid => 'এনআইডি';

  @override
  String get clientsPop => 'পপ';

  @override
  String get clientsRouter => 'রাউটার';

  @override
  String get clientsOnu => 'ONU';

  @override
  String get clientsRx => 'শেষ RX dBm';

  @override
  String get clientsConnection => 'লাইন স্ট্যাটাস';

  @override
  String get clientsOnline => 'লাইন অনলাইন।';

  @override
  String get clientsOffline => 'লাইন অফলাইন।';

  @override
  String clientsDisconnects(int count) {
    return '২৪ ঘণ্টায় $count বার সংযোগ ছিঁড়েছে';
  }

  @override
  String get clientsOpenTickets => 'খোলা টিকেট';

  @override
  String get clientsPayments => 'সাম্প্রতিক পেমেন্ট';

  @override
  String get chatsSearch => 'ক্লায়েন্টের নাম, আইডি বা ফোন';

  @override
  String get chatsEmpty => 'কোনো কথোপকথন নেই।';

  @override
  String chatsUnread(int count) {
    return '$count নতুন';
  }

  @override
  String get chatsReply => 'উত্তর';

  @override
  String get collectionToday => 'আজকের কালেকশন';

  @override
  String get collectionInHand => 'হাতে নগদ';

  @override
  String get collectionNotHanded => 'এখনো জমা হয়নি';

  @override
  String get collectionExpenseLeft => 'খরচের জন্য বাকি';

  @override
  String get collectionHold => 'আর টাকা নেওয়ার আগে নগদ জমা দিন।';

  @override
  String get collectionCash => 'নগদ নিন';

  @override
  String get collectionExpense => 'খরচ';

  @override
  String get collectionHandover => 'জমা দিন';

  @override
  String get collectionCashOwner => 'নগদের মালিক';

  @override
  String get collectionDigitalOwner => 'ডিজিটালের মালিক';

  @override
  String get collectionGateway => 'বিকাশ / নগদ';

  @override
  String get collectionSearch => 'নাম, আইডি, ফোন বা PPPoE';

  @override
  String get collectionMore => 'আরও';

  @override
  String get collectionAmount => 'টাকা';

  @override
  String get collectionNote => 'নোট';

  @override
  String get collectionTxn => 'TrxID';

  @override
  String get collectionSave => 'সেভ';

  @override
  String get collectionReceipt => 'রসিদ';

  @override
  String get collectionApproval => 'অনুমোদন';

  @override
  String get collectionPaidSms => 'পেইড SMS';

  @override
  String get collectionSmsLater => 'অফিস অনুমোদনের পর ক্লায়েন্টকে জানানো হবে।';

  @override
  String get dueEmpty => 'বকেয়া তালিকায় কেউ নেই।';

  @override
  String get approvalsEmpty => 'আপনার জন্য কিছু অপেক্ষা করছে না।';

  @override
  String get approvalsApprove => 'অনুমোদন';

  @override
  String get featureDashboard => 'ড্যাশবোর্ড';

  @override
  String get featureExpiring => 'মেয়াদ শেষ হচ্ছে';

  @override
  String get featureSales => 'মাল বিক্রি';

  @override
  String get featureWallet => 'ওয়ালেট';

  @override
  String get workAdjustment => 'প্যাকেজ বদলের হিসাব';

  @override
  String get workAdvances => 'অগ্রিম';

  @override
  String get workAmount => 'টাকা';

  @override
  String get workAskAdvance => 'অগ্রিম চাই';

  @override
  String get workAskLeave => 'ছুটি চাই';

  @override
  String get workAttendance => 'হাজিরা';

  @override
  String get workAvailable => 'খরচ করা যাবে';

  @override
  String get workAwaitingClient => 'ক্লায়েন্ট আইডি বাকি';

  @override
  String get workCableMetres => 'ক্যাবল (মিটার)';

  @override
  String get workCannotInstall =>
      'এই টিকেটে এখন install তথ্য দেওয়া যাবে না (শুধু দায়িত্বপ্রাপ্ত technician, ক্লায়েন্ট pending থাকা অবস্থায়)।';

  @override
  String get workClientSearch => 'নাম, আইডি, ফোন বা PPPoE';

  @override
  String get workClientsAdvance => 'গ্রাহকের অগ্রিম হাতে';

  @override
  String get workCodeHint => 'সিরিয়াল, বারকোড বা SKU';

  @override
  String workConfirmRecharge(String amount, int months) {
    return '$months মাসের রিচার্জ, ৳ $amount?';
  }

  @override
  String get workCreditAlert => 'আপনার ক্রেডিট প্রায় শেষ।';

  @override
  String get workCreditLimit => 'ক্রেডিট লিমিট';

  @override
  String get workCreditUsed => 'ক্রেডিট ব্যবহার';

  @override
  String workDaysLeft(int days) {
    return '$days দিন বাকি';
  }

  @override
  String get workEnterQuantity => 'অন্তত একটা মালের পরিমাণ দিন।';

  @override
  String get workFillAll => 'দরকারি সব ঘর পূরণ করুন।';

  @override
  String get workForNewConnection => 'নতুন সংযোগের জন্য (আইডি পরে)';

  @override
  String get workGiveClientId => 'আইডি দিন';

  @override
  String get workInStock => 'স্টকে';

  @override
  String get workInstall => 'নতুন লাইনের install';

  @override
  String get workInstallHint => 'সেভ করলে লাইন চালু হবে আর টিকেট resolved হবে।';

  @override
  String get workInstallSaved => 'Install সেভ হয়েছে।';

  @override
  String get workLateMinutes => 'দেরি (মিনিট)';

  @override
  String get workLeaves => 'ছুটি';

  @override
  String get workMaterials => 'ব্যবহৃত মাল';

  @override
  String get workMethod => 'মাধ্যম';

  @override
  String get workMonths => 'মাস';

  @override
  String get workNewExpiry => 'নতুন মেয়াদ';

  @override
  String get dashboardHelp =>
      'ERP-র ড্যাশবোর্ডের একই সংখ্যা। নিচে টেনে নতুন করুন।';

  @override
  String get workNoDashboard => 'আপনার লগইনে ড্যাশবোর্ডের কোনো বক্স নেই।';

  @override
  String get workNoExpiring => 'কারো মেয়াদ শেষ হচ্ছে না।';

  @override
  String get workNoMaterials => 'এই টিকেটে এখনো কোনো মাল ব্যবহার হয়নি।';

  @override
  String get workNoSales => 'এখনো বিক্রি নেই।';

  @override
  String get workNoteOptional => 'নোট (ইচ্ছা হলে)';

  @override
  String get workOk => 'ঠিক আছে';

  @override
  String get workOldExpiry => 'পুরনো মেয়াদ';

  @override
  String get workPayBank => 'ব্যাংক';

  @override
  String get workPayCash => 'ক্যাশ';

  @override
  String get workPayDigital => 'ডিজিটাল';

  @override
  String get workPayDue => 'বাকি';

  @override
  String get workPayTotal => 'মোট দিতে হবে';

  @override
  String get workPickClient => 'ক্লায়েন্ট বাছুন';

  @override
  String get workPonPort => 'PON পোর্ট';

  @override
  String get workPrice => 'দাম';

  @override
  String get workPurpose => 'কাজের ধরন';

  @override
  String get workPurposeLineWork => 'লাইনের কাজ';

  @override
  String get workPurposeNewConnection => 'নতুন সংযোগ';

  @override
  String get workPurposeOther => 'অন্যান্য';

  @override
  String get workPurposeRepair => 'মেরামত';

  @override
  String get workPurposeShift => 'স্থানান্তর';

  @override
  String get workQuantity => 'পরিমাণ';

  @override
  String get workReason => 'কারণ';

  @override
  String get workReceiptAdded => 'রসিদের ছবি দেওয়া হয়েছে';

  @override
  String get workReceiptPhoto => 'রসিদের ছবি';

  @override
  String get workRecentSales => 'আমার শেষ বিক্রি';

  @override
  String get workRecharge => 'রিচার্জ';

  @override
  String workRechargeDone(String expiry) {
    return 'রিচার্জ হয়েছে। নতুন মেয়াদ: $expiry';
  }

  @override
  String get workRechargePending =>
      'এই ক্লায়েন্টের তথ্য আগে ওয়েবসাইটে পূরণ করতে হবে।';

  @override
  String get workRequestSent => 'আবেদন পাঠানো হয়েছে।';

  @override
  String get workSave => 'সেভ';

  @override
  String get workSaved => 'সেভ হয়েছে।';

  @override
  String get workScan => 'কোড স্ক্যান / লিখুন';

  @override
  String get workSell => 'বিক্রি';

  @override
  String get workSold => 'বিক্রি হয়েছে।';

  @override
  String get workSoldCash => 'বিক্রি হয়েছে। টাকা দিন শেষের জমায় যাবে।';

  @override
  String get workTransactions => 'লেনদেন';

  @override
  String get workUseParts => 'মাল ব্যবহার';

  @override
  String get workWalletAfter => 'পরে ওয়ালেটে থাকবে';

  @override
  String get workWalletBalance => 'ওয়ালেট ব্যালান্স';

  @override
  String get workWalletCharge => 'ওয়ালেট থেকে কাটবে';

  @override
  String workWithinDays(int days) {
    return '$days দিন';
  }

  @override
  String get approvalsAcceptAmount => 'কত টাকা নেবেন (সব বা কিছু অংশ)';

  @override
  String get approvalsExpenses => 'খরচ';

  @override
  String get approvalsHandovers => 'জমা';

  @override
  String get approvalsReject => 'বাতিল';

  @override
  String get approvalsRejectNote => 'কেন? (দরকার)';

  @override
  String collectionMetres(int metres) {
    return '$metres মিটার দূরে';
  }

  @override
  String get collectionNearMe => 'কাছের বকেয়া ক্লায়েন্ট';

  @override
  String get collectionNoLocation => 'Location বন্ধ বা অনুমতি নেই।';

  @override
  String get supportCategory => 'ধরন';

  @override
  String get supportClient => 'ক্লায়েন্ট';

  @override
  String get supportClientSaved => 'ক্লায়েন্ট সেভ হয়েছে।';

  @override
  String get supportDetailsOptional => 'বিস্তারিত (ইচ্ছা হলে)';

  @override
  String get supportNameOptional => 'নাম (ইচ্ছা হলে)';

  @override
  String get supportNewClient => 'নতুন ক্লায়েন্ট';

  @override
  String get supportNewClientHint =>
      'POP ছাড়া ক্লায়েন্ট pending থাকবে; POP দিলে লাইন এখনই চালু হবে।';

  @override
  String get supportNewTicket => 'নতুন টিকেট';

  @override
  String get supportPhoneOptional => 'মোবাইল (ইচ্ছা হলে)';

  @override
  String get supportPopOptional => 'POP (ইচ্ছা হলে)';

  @override
  String get supportPppoePassword => 'PPPoE পাসওয়ার্ড';

  @override
  String get supportPppoeUser => 'PPPoE ইউজার';

  @override
  String get supportSubject => 'বিষয়';

  @override
  String get supportTicketOpened => 'টিকেট খোলা হয়েছে।';

  @override
  String get scanTitle => 'কোড স্ক্যান';

  @override
  String get scanTorch => 'টর্চ';

  @override
  String get scanCameraOff => 'ক্যামেরা বন্ধ বা অনুমতি নেই। কোড হাতে লিখুন।';

  @override
  String get collectionShareReceipt => 'রসিদ শেয়ার';

  @override
  String get payslipTitle => 'আমার বেতনের স্লিপ';

  @override
  String get payslipNone =>
      'এখনো কোনো স্লিপ নেই। মাসের payroll অনুমোদনের পরে দেখাবে।';

  @override
  String get payslipEarnings => 'আয়';

  @override
  String get payslipDeductions => 'কাটা';

  @override
  String get payslipNet => 'মোট বেতন';

  @override
  String get payslipPayment => 'পরিশোধ';

  @override
  String get payslipPaidOn => 'পরিশোধের তারিখ';

  @override
  String get payslipDays => 'দিন';

  @override
  String get payslipSharePdf => 'PDF শেয়ার';

  @override
  String get payslipBasic => 'মূল বেতন';

  @override
  String get payslipAllowance => 'ভাতা';

  @override
  String get payslipBonus => 'বোনাস';

  @override
  String get payslipAttendanceBonus => 'হাজিরা বোনাস';

  @override
  String get payslipOvertime => 'ওভারটাইম';

  @override
  String get payslipLate => 'দেরির জরিমানা';

  @override
  String get payslipAbsent => 'অনুপস্থিতির কাটা';

  @override
  String get payslipOther => 'অন্যান্য কাটা';

  @override
  String get payslipAdvance => 'অগ্রিম সমন্বয়';

  @override
  String get payslipWorkingDays => 'কর্মদিবস';

  @override
  String get payslipPresentDays => 'উপস্থিত';

  @override
  String get payslipAbsentDays => 'অনুপস্থিত';

  @override
  String get payslipLateDays => 'দেরি';

  @override
  String get payslipOvertimeMinutes => 'ওভারটাইম (মিনিট)';

  @override
  String get collectionPickClient => 'আগে ক্লায়েন্ট বাছাই করুন।';

  @override
  String get collectionEnterAmount => 'টাকার পরিমাণ লিখুন।';

  @override
  String get collectionEnterTxn => 'TrxID লিখুন।';

  @override
  String get collectionEnterNote => 'কিসের খরচ, নোটে লিখুন।';

  @override
  String get collectionSaving => 'সেভ হচ্ছে…';

  @override
  String get collectionSaved => 'সেভ হয়েছে। টাকা নেওয়া হয়েছে।';

  @override
  String get collectionAlreadySaved => 'এটা আগেই সেভ হয়েছিল, দুইবার হয়নি।';

  @override
  String get collectionAnother => 'আরেকটা নিন';

  @override
  String get collectionDone => 'শেষ';

  @override
  String get collectionNoClients => 'কোনো ক্লায়েন্ট পাওয়া যায়নি।';

  @override
  String get collectionChange => 'বদলান';

  @override
  String get collectionDue => 'বকেয়া';

  @override
  String get collectionFind => 'খুঁজুন';

  @override
  String get collectionStatusPending => 'অফিসের অনুমোদনের অপেক্ষায়';

  @override
  String get collectionStatusApproved => 'অনুমোদিত';

  @override
  String get collectionExpenseSaved => 'খরচ সেভ হয়েছে, অনুমোদনের জন্য গেছে।';

  @override
  String get collectionHandoverSaved =>
      'জমা পাঠানো হয়েছে, মালিকের গ্রহণের অপেক্ষায়।';

  @override
  String get clientsFilter => 'ফিল্টার';

  @override
  String get clientsAny => 'যেকোনো';

  @override
  String get clientsClear => 'মুছুন';

  @override
  String get clientsApply => 'দেখান';

  @override
  String get clientsFilterStatus => 'অবস্থা';

  @override
  String get clientsFilterZone => 'জোন';

  @override
  String get clientsFilterRouter => 'রাউটার';

  @override
  String get clientsFilterPackage => 'প্যাকেজ';

  @override
  String get clientsFilterReseller => 'রিসেলার';

  @override
  String get clientsFilterPolicy => 'বিলিং নিয়ম';

  @override
  String get clientsFilterType => 'ক্লায়েন্টের ধরন';

  @override
  String get clientsSort => 'সাজানো';

  @override
  String get clientsSortOrder => 'ক্রম';

  @override
  String get clientsSortDesc => 'বড় থেকে ছোট / নতুন আগে';

  @override
  String get clientsSortAsc => 'ছোট থেকে বড় / ক থেকে';

  @override
  String get clientsSortNewest => 'নতুন';

  @override
  String get clientsSortName => 'নাম';

  @override
  String get clientsSortClientId => 'ক্লায়েন্ট আইডি';

  @override
  String get clientsSortPackage => 'প্যাকেজ';

  @override
  String get clientsSortExpiry => 'মেয়াদ';

  @override
  String get clientsSortStatus => 'অবস্থা';

  @override
  String clientsTotal(int count) {
    return '$count জন ক্লায়েন্ট';
  }
}
