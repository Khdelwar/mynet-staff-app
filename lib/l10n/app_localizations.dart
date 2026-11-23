import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyNet Staff'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @languageToggle.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageToggle;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'This app is not set up for sign-in. Ask the office for the right app.'**
  String get notConfigured;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineBanner;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the ERP. Check your connection and try again.'**
  String get errNetwork;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff sign-in'**
  String get loginTitle;

  /// No description provided for @loginIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Email or mobile number'**
  String get loginIdentifier;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @loginWrong.
  ///
  /// In en, this message translates to:
  /// **'Email / mobile or password is incorrect.'**
  String get loginWrong;

  /// No description provided for @loginHelp.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password? Ask the admin to set a new one.'**
  String get loginHelp;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get twoFactorCode;

  /// No description provided for @twoFactorButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get twoFactorButton;

  /// No description provided for @twoFactorWrong.
  ///
  /// In en, this message translates to:
  /// **'The code is wrong or has expired.'**
  String get twoFactorWrong;

  /// No description provided for @twoFactorSms.
  ///
  /// In en, this message translates to:
  /// **'We sent a code by SMS.'**
  String get twoFactorSms;

  /// No description provided for @twoFactorTelegram.
  ///
  /// In en, this message translates to:
  /// **'We sent a code on Telegram.'**
  String get twoFactorTelegram;

  /// No description provided for @twoFactorTotp.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app and enter its code.'**
  String get twoFactorTotp;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String hello(String name);

  /// No description provided for @staffCode.
  ///
  /// In en, this message translates to:
  /// **'Staff code'**
  String get staffCode;

  /// No description provided for @designation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get designation;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @noStaffProfile.
  ///
  /// In en, this message translates to:
  /// **'This login has no staff profile in HR. Ask the admin to link one.'**
  String get noStaffProfile;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your details.'**
  String get homeLoadFailed;

  /// No description provided for @yourWork.
  ///
  /// In en, this message translates to:
  /// **'Your work'**
  String get yourWork;

  /// No description provided for @featureCollection.
  ///
  /// In en, this message translates to:
  /// **'Bill collection'**
  String get featureCollection;

  /// No description provided for @featureTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get featureTickets;

  /// No description provided for @featureClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get featureClients;

  /// No description provided for @featureHr.
  ///
  /// In en, this message translates to:
  /// **'Attendance, leave & advance'**
  String get featureHr;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in the next update'**
  String get comingSoon;

  /// No description provided for @noFeatures.
  ///
  /// In en, this message translates to:
  /// **'Your role has no app features yet. Use the ERP website.'**
  String get noFeatures;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockHint.
  ///
  /// In en, this message translates to:
  /// **'Ask for fingerprint, face or screen lock when the app opens.'**
  String get appLockHint;

  /// No description provided for @appLockUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This phone has no fingerprint, face or screen lock set up.'**
  String get appLockUnsupported;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this phone?'**
  String get logoutConfirm;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'MyNet Staff is locked'**
  String get lockTitle;

  /// No description provided for @lockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock MyNet Staff'**
  String get lockReason;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'You were signed out. Sign in again.'**
  String get sessionEnded;

  /// No description provided for @pushNotice.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get pushNotice;

  /// No description provided for @pushOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pushOpen;

  /// No description provided for @pushTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{id}'**
  String pushTicketTitle(int id);

  /// No description provided for @pushTicketAssigned.
  ///
  /// In en, this message translates to:
  /// **'This ticket was assigned to you.'**
  String get pushTicketAssigned;

  /// No description provided for @pushTicketHelper.
  ///
  /// In en, this message translates to:
  /// **'You were added as a helper on this ticket.'**
  String get pushTicketHelper;

  /// No description provided for @pushTicketUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Nobody took this ticket. It is back with the office.'**
  String get pushTicketUnassigned;

  /// No description provided for @pushOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket offer'**
  String get pushOfferTitle;

  /// No description provided for @pushOfferBody.
  ///
  /// In en, this message translates to:
  /// **'A nearby ticket was offered to you.'**
  String get pushOfferBody;

  /// No description provided for @pushFromNotification.
  ///
  /// In en, this message translates to:
  /// **'Opened from a notification.'**
  String get pushFromNotification;

  /// No description provided for @pushPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get pushPriority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
