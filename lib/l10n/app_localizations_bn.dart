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
}
