// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'MyNet Staff';

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
  String get lockTitle => 'MyNet Staff লক করা';

  @override
  String get lockReason => 'MyNet Staff আনলক করুন';

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
  String get dutyNotificationTitle => 'MyNet: location on';

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
  String get devicesTitle => 'লগইন করা ফোন';

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
  String get clientsSearch => 'নাম, আইডি, ফোন বা PPPoE';

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
}
