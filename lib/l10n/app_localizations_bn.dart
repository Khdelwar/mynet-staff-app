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
  String get loginPassword => 'পাসওয়ার্ড';

  @override
  String get loginButton => 'লগইন';

  @override
  String get loginWrong => 'ইমেইল / মোবাইল বা পাসওয়ার্ড সঠিক নয়।';

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
  String get acceptAmount => 'কত টাকা নেবেন';

  @override
  String get addExpense => 'খরচ';

  @override
  String get addNote => 'নোট লিখুন';

  @override
  String get addPhotosQuestion => 'এই নোটের সাথে ছবি দেবেন?';

  @override
  String get address => 'ঠিকানা';

  @override
  String get adjustment => 'প্যাকেজ বদলের হিসাব';

  @override
  String get advance => 'অগ্রিম';

  @override
  String get advances => 'অগ্রিম';

  @override
  String get alreadySaved => 'এটা আগেই সেভ হয়েছে। আবার টাকা নেবেন না।';

  @override
  String get amount => 'টাকা';

  @override
  String get amountPartOptional => 'টাকা (খালি রাখলে সব)';

  @override
  String get approve => 'অনুমোদন';

  @override
  String get askAdvance => 'অগ্রিম চাই';

  @override
  String get askLeave => 'ছুটি চাই';

  @override
  String get assign => 'দিন';

  @override
  String get assignTechnician => 'কাছের technician';

  @override
  String get assigned => 'দেওয়া হয়েছে।';

  @override
  String get attendance => 'হাজিরা';

  @override
  String get available => 'খরচ করা যাবে';

  @override
  String get awaitingClientId => 'ক্লায়েন্ট আইডি বাকি';

  @override
  String get awayTitle => 'বাসা থেকে দূরে';

  @override
  String get busy => 'ব্যস্ত';

  @override
  String get cableMetres => 'ক্যাবল (মিটার)';

  @override
  String get call => 'কল';

  @override
  String get cancelRequestQuestion => 'এই আবেদন ফেরত নেবেন?';

  @override
  String get cannotInstall =>
      'এই টিকেটে এখন install তথ্য দেওয়া যাবে না (শুধু দায়িত্বপ্রাপ্ত technician, ক্লায়েন্ট pending থাকা অবস্থায়)।';

  @override
  String get cashHint =>
      'লাইন এখনই চালু হবে। পেমেন্ট মালিকের অনুমোদনের অপেক্ষায় থাকবে; অনুমোদনের পরে ক্লায়েন্ট paid SMS পাবেন।';

  @override
  String get category => 'ধরন';

  @override
  String get client => 'ক্লায়েন্ট';

  @override
  String get clientId => 'ক্লায়েন্ট আইডি';

  @override
  String get clientSaved => 'ক্লায়েন্ট সেভ হয়েছে।';

  @override
  String get clientSearchHint => 'নাম, আইডি, ফোন বা PPPoE';

  @override
  String get clientsAdvanceHeld => 'গ্রাহকের অগ্রিম হাতে';

  @override
  String get collected => 'কালেকশন';

  @override
  String get collectedBy => 'যিনি নিলেন';

  @override
  String get collectedToday => 'আজ কালেকশন';

  @override
  String confirmRecharge(String amount, String months) {
    return '$months মাসের রিচার্জ, $amount?';
  }

  @override
  String confirmTake(String amount, String name) {
    return '$name-এর কাছ থেকে $amount নেবেন?';
  }

  @override
  String get creditAlert => 'আপনার ক্রেডিট প্রায় শেষ।';

  @override
  String get creditLimit => 'ক্রেডিট লিমিট';

  @override
  String get creditUsed => 'ক্রেডিট ব্যবহার';

  @override
  String get date => 'তারিখ';

  @override
  String get dayEndHandover => 'দিন শেষের জমা';

  @override
  String daysLeft(int days) {
    return '$days দিন বাকি';
  }

  @override
  String get decline => 'না';

  @override
  String get descriptionOptional => 'বিস্তারিত (ইচ্ছা হলে)';

  @override
  String get disconnects24h => 'সংযোগ কাটা (২৪ ঘণ্টা)';

  @override
  String get distance => 'দূরত্ব';

  @override
  String get due => 'বকেয়া';

  @override
  String get dutyEnded => 'ডিউটি শেষ।';

  @override
  String get dutyHours => 'ডিউটির সময়';

  @override
  String get dutyLocationHint =>
      'ডিউটি শুরু বা শেষ করার সময় আপনার location নেওয়া হয়। ডিউটির বাইরে কখনো নয়।';

  @override
  String get dutyStarted => 'ডিউটি শুরু।';

  @override
  String get dutyStatus => 'ডিউটি';

  @override
  String get endDuty => 'ডিউটি শেষ';

  @override
  String get enterQuantity => 'অন্তত একটা মালের পরিমাণ দিন।';

  @override
  String get expenseAvailable => 'খরচ করা যাবে';

  @override
  String get expenseHint => 'প্রতিটা খরচ অন্য একজনের অনুমোদনের অপেক্ষায় থাকে।';

  @override
  String get expenseSaved => 'খরচ সেভ হয়েছে। অনুমোদনের অপেক্ষায়।';

  @override
  String get expenses => 'খরচ';

  @override
  String get expiry => 'মেয়াদ';

  @override
  String get featureApprovals => 'অনুমোদন';

  @override
  String get featureChat => 'সাপোর্ট চ্যাট';

  @override
  String get featureDashboard => 'ড্যাশবোর্ড';

  @override
  String get featureDueList => 'বকেয়া তালিকা';

  @override
  String get featureDuty => 'ডিউটি';

  @override
  String get featureExpenses => 'খরচ';

  @override
  String get featureExpiring => 'মেয়াদ শেষ হচ্ছে';

  @override
  String get featureOffers => 'কাজের অফার';

  @override
  String get featureSales => 'মাল বিক্রি';

  @override
  String get featureWallet => 'ওয়ালেট';

  @override
  String get fillAll => 'দরকারি সব ঘর পূরণ করুন।';

  @override
  String get forNewConnection => 'নতুন সংযোগের জন্য';

  @override
  String get forNewConnectionHint => 'ক্লায়েন্ট আইডি পরে দেওয়া হবে।';

  @override
  String get gateway => 'মাধ্যম';

  @override
  String get giveClientId => 'আইডি দিন';

  @override
  String get handoverDue => 'জমা দিতে হবে';

  @override
  String get handoverSent => 'মালিকের কাছে জমা পাঠানো হয়েছে।';

  @override
  String get handovers => 'জমা';

  @override
  String get holdBlocked => 'হাতে টাকার সীমা পূর্ণ। আগে জমা দিন।';

  @override
  String get inHand => 'হাতে';

  @override
  String get inStock => 'স্টকে';

  @override
  String get installHint =>
      'সেভ করলে আজ থেকে লাইন চালু হবে আর টিকেট resolved হবে।';

  @override
  String get installSaved => 'Install সেভ হয়েছে।';

  @override
  String get installedAt => 'Install হয়েছে';

  @override
  String get lastDisconnect => 'শেষ সংযোগ কাটা';

  @override
  String get lastRx => 'শেষ RX power';

  @override
  String get lateMinutes => 'দেরি (মিনিট)';

  @override
  String get leaveReason => 'কারণ';

  @override
  String get leaveUnpaidQuestion => 'বিনা বেতনে ছুটি? (বাতিল = বেতনসহ)';

  @override
  String get leaves => 'ছুটি';

  @override
  String get liveConnection => 'এখন অনলাইন?';

  @override
  String get locationOff => 'Location বন্ধ বা অনুমতি নেই।';

  @override
  String get map => 'ম্যাপ';

  @override
  String get materials => 'ব্যবহৃত মাল';

  @override
  String get method => 'মাধ্যম';

  @override
  String get minutes => 'মিনিট';

  @override
  String get mobileOptional => 'মোবাইল (ইচ্ছা হলে)';

  @override
  String get months => 'মাস';

  @override
  String get myExpenses => 'আমার খরচ (৭ দিন)';

  @override
  String get name => 'নাম';

  @override
  String get nameOptional => 'নাম (ইচ্ছা হলে)';

  @override
  String get newClient => 'নতুন ক্লায়েন্ট';

  @override
  String get newClientHint =>
      'POP ছাড়া ক্লায়েন্ট pending থাকবে; POP দিলে লাইন এখনই চালু হবে।';

  @override
  String get newConnection => 'নতুন সংযোগ';

  @override
  String get newExpiry => 'নতুন মেয়াদ';

  @override
  String get newTicket => 'নতুন টিকেট';

  @override
  String get nextStep => 'পরের ধাপ';

  @override
  String get noChats => 'কোনো কথোপকথন নেই।';

  @override
  String get noClients => 'কোনো ক্লায়েন্ট পাওয়া যায়নি।';

  @override
  String get noDashboard => 'আপনার লগইনে ড্যাশবোর্ডের কোনো বক্স নেই।';

  @override
  String get noDues => 'কোনো বকেয়া নেই।';

  @override
  String get noExpiring => 'কারো মেয়াদ শেষ হচ্ছে না।';

  @override
  String get noMaterials => 'এই টিকেটে এখনো কোনো মাল ব্যবহার হয়নি।';

  @override
  String get noNotes => 'এখনো কোনো নোট নেই।';

  @override
  String get noOffers => 'এখন কোনো অফার নেই।';

  @override
  String get noParts => 'অফিসে কোনো মাল স্টকে নেই।';

  @override
  String get noPayments => 'কোনো পেমেন্ট নেই।';

  @override
  String get noSales => 'এখনো বিক্রি নেই।';

  @override
  String get noSuggestions => 'কাছে কোনো technician ডিউটিতে নেই।';

  @override
  String get noTickets => 'কোনো টিকেট নেই।';

  @override
  String get none => 'নেই।';

  @override
  String get note => 'নোট';

  @override
  String get noteOptional => 'নোট (ইচ্ছা হলে)';

  @override
  String get noteRequired => 'নোট (দরকার)';

  @override
  String get notes => 'নোট';

  @override
  String get nothingToApprove => 'আপনার অনুমোদনের কিছু নেই।';

  @override
  String get offDuty => 'ডিউটিতে নেই';

  @override
  String get offerSent => 'কাছের technician-কে অফার পাঠানো হয়েছে।';

  @override
  String get offerTaken => 'টিকেট আপনার।';

  @override
  String get offerToNearest => 'কাছের জনকে অফার';

  @override
  String get offline => 'অফলাইন';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get oldExpiry => 'পুরনো মেয়াদ';

  @override
  String get onDuty => 'ডিউটিতে';

  @override
  String get online => 'অনলাইন';

  @override
  String get onuPower => 'ONU power';

  @override
  String get openTickets => 'খোলা টিকেট';

  @override
  String get outCancelled => 'বাতিল';

  @override
  String get outDone => 'কাজ শেষ';

  @override
  String get outDuplicate => 'একই টিকেট আগে আছে';

  @override
  String get outNoIssue => 'কোনো সমস্যা পাওয়া যায়নি';

  @override
  String get outcomeTitle => 'কীভাবে শেষ হলো?';

  @override
  String get outsideDutyHours =>
      'ডিউটির সময়ের বাইরে: এখন ডিউটি শুরু করা যাবে না।';

  @override
  String get overdue => 'দেরি';

  @override
  String get ownerCash => 'ক্যাশ মালিক';

  @override
  String get ownerDigital => 'ডিজিটাল মালিক';

  @override
  String get package => 'প্যাকেজ';

  @override
  String get payBank => 'ব্যাংক';

  @override
  String get payCash => 'ক্যাশ';

  @override
  String get payDigital => 'ডিজিটাল';

  @override
  String get payDue => 'বাকি';

  @override
  String get payTotal => 'মোট দিতে হবে';

  @override
  String get photoCamera => 'ক্যামেরা';

  @override
  String get photoGallery => 'গ্যালারি';

  @override
  String get pickClient => 'ক্লায়েন্ট বাছুন';

  @override
  String get ponPort => 'PON পোর্ট';

  @override
  String get pop => 'POP';

  @override
  String get popOptional => 'POP (ইচ্ছা হলে)';

  @override
  String get pppoePassword => 'PPPoE পাসওয়ার্ড';

  @override
  String get pppoeUser => 'PPPoE ইউজার';

  @override
  String get prHigh => 'জরুরি';

  @override
  String get prLow => 'কম';

  @override
  String get prMedium => 'মাঝারি';

  @override
  String get prUrgent => 'খুব জরুরি';

  @override
  String get price => 'দাম';

  @override
  String get priority => 'গুরুত্ব';

  @override
  String get purLineWork => 'লাইনের কাজ';

  @override
  String get purNewConnection => 'নতুন সংযোগ';

  @override
  String get purOther => 'অন্যান্য';

  @override
  String get purRepair => 'মেরামত';

  @override
  String get purShift => 'স্থানান্তর';

  @override
  String get purpose => 'কাজের ধরন';

  @override
  String get quantity => 'পরিমাণ';

  @override
  String get receipt => 'রসিদ';

  @override
  String get receiptNotImage => 'এই রসিদ ছবি নয়। ERP ওয়েবসাইটে খুলুন।';

  @override
  String get receiptPhoto => 'রসিদের ছবি';

  @override
  String get receiptPhotoAdded => 'রসিদের ছবি দেওয়া হয়েছে';

  @override
  String get recentPayments => 'শেষ পেমেন্ট';

  @override
  String get recentSales => 'আমার শেষ বিক্রি';

  @override
  String get recharge => 'রিচার্জ';

  @override
  String rechargeDone(String expiry) {
    return 'রিচার্জ হয়েছে। নতুন মেয়াদ: $expiry';
  }

  @override
  String get rechargePending =>
      'এই ক্লায়েন্টের তথ্য আগে ওয়েবসাইটে পূরণ করতে হবে।';

  @override
  String get recordInstall => 'Install তথ্য দিন';

  @override
  String get reject => 'বাতিল';

  @override
  String get requestSent => 'আবেদন পাঠানো হয়েছে।';

  @override
  String get roleHelper => 'সহকারী';

  @override
  String get router => 'রাউটার';

  @override
  String get sales => 'বিক্রি';

  @override
  String get save => 'সেভ';

  @override
  String get saveHouseLocation => 'বাসার GPS সেভ';

  @override
  String get saveHouseLocationQuestion =>
      'আপনি কি ক্লায়েন্টের বাসায় দাঁড়িয়ে আছেন? এই জায়গাকে বাসার location হিসেবে সেভ করবেন?';

  @override
  String get saved => 'সেভ হয়েছে।';

  @override
  String get scanCodeHint => 'সিরিয়াল, বারকোড বা SKU';

  @override
  String get scanItem => 'কোড স্ক্যান / লিখুন';

  @override
  String secondsLeft(int seconds) {
    return '$seconds সেকেন্ড বাকি';
  }

  @override
  String get sell => 'বিক্রি';

  @override
  String get send => 'পাঠান';

  @override
  String get since => 'কখন থেকে';

  @override
  String get sold => 'বিক্রি হয়েছে।';

  @override
  String get soldCashToHandover => 'বিক্রি হয়েছে। টাকা দিন শেষের জমায় যাবে।';

  @override
  String get stActive => 'চালু';

  @override
  String get stApproved => 'অনুমোদিত';

  @override
  String get stAssigned => 'দেওয়া হয়েছে';

  @override
  String get stAwaitingClient => 'আইডি বাকি';

  @override
  String get stCancelled => 'বাতিল';

  @override
  String get stClosed => 'বন্ধ';

  @override
  String get stDone => 'শেষ';

  @override
  String get stExpired => 'মেয়াদ শেষ';

  @override
  String get stInProgress => 'কাজ চলছে';

  @override
  String get stOnTheWay => 'যাচ্ছি';

  @override
  String get stOpen => 'খোলা';

  @override
  String get stPartial => 'আংশিক অনুমোদিত';

  @override
  String get stPending => 'অপেক্ষায়';

  @override
  String get stRejected => 'বাতিল';

  @override
  String get stReopened => 'আবার খোলা';

  @override
  String get stResolved => 'সমাধান';

  @override
  String get stScheduled => 'সময় ঠিক';

  @override
  String get stSuspended => 'স্থগিত';

  @override
  String get startDuty => 'ডিউটি শুরু';

  @override
  String get startedAt => 'শুরু';

  @override
  String get status => 'অবস্থা';

  @override
  String get subject => 'বিষয়';

  @override
  String get subjectRequired => 'বিষয় লিখুন।';

  @override
  String get take => 'নেব';

  @override
  String get takeCash => 'ক্যাশ';

  @override
  String get takeTrx => 'bKash / Nagad TrxID';

  @override
  String get ticketOpened => 'টিকেট খোলা হয়েছে।';

  @override
  String get ticketSearchHint => 'বিষয়, #আইডি, ক্লায়েন্ট';

  @override
  String get ticketsActive => 'চলমান';

  @override
  String get ticketsAll => 'সব';

  @override
  String get ticketsDone => 'শেষ (৩০ দিন)';

  @override
  String get ticketsMine => 'আমার';

  @override
  String get transactions => 'লেনদেন';

  @override
  String get trxHint => 'ডিজিটাল মালিক TrxID যাচাই করার পরে গণ্য হবে।';

  @override
  String get trxId => 'TrxID';

  @override
  String get useParts => 'মাল ব্যবহার';

  @override
  String get useWebsite => 'এটার জন্য ERP ওয়েবসাইট ব্যবহার করুন।';

  @override
  String get waitingHandovers => 'অপেক্ষায় থাকা জমা';

  @override
  String get waitsForApproval =>
      'মালিক অনুমোদন দিলে ক্লায়েন্ট paid SMS পাবেন।';

  @override
  String get walletAfter => 'পরে ওয়ালেটে থাকবে';

  @override
  String get walletBalance => 'ওয়ালেট ব্যালান্স';

  @override
  String get walletCharge => 'ওয়ালেট থেকে কাটবে';

  @override
  String get whatFor => 'কিসের খরচ';

  @override
  String withinDays(int days) {
    return '$days দিন';
  }

  @override
  String get writeMessage => 'মেসেজ লিখুন';
}
