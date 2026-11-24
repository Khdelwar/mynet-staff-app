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
  String get serverLabel => 'ERP address';

  @override
  String get serverHint => 'bill.example.com';

  @override
  String get serverHelp =>
      'Your company\'s ERP web address. Ask the office if you don\'t know it.';

  @override
  String get serverInvalid =>
      'Enter an https web address, e.g. bill.example.com';

  @override
  String get serverNotErp =>
      'No ERP found at this address. Check it and try again.';

  @override
  String get serverChange => 'Change';

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
}
