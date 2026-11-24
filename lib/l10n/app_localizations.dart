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

  /// No description provided for @acceptAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount to accept'**
  String get acceptAmount;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get addExpense;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @addPhotosQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add photos to this note?'**
  String get addPhotosQuestion;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @adjustment.
  ///
  /// In en, this message translates to:
  /// **'Package change'**
  String get adjustment;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @advances.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get advances;

  /// No description provided for @alreadySaved.
  ///
  /// In en, this message translates to:
  /// **'This was already saved earlier. Do not take the money again.'**
  String get alreadySaved;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountPartOptional.
  ///
  /// In en, this message translates to:
  /// **'Amount (empty = all)'**
  String get amountPartOptional;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @askAdvance.
  ///
  /// In en, this message translates to:
  /// **'Ask for advance'**
  String get askAdvance;

  /// No description provided for @askLeave.
  ///
  /// In en, this message translates to:
  /// **'Ask for leave'**
  String get askLeave;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @assignTechnician.
  ///
  /// In en, this message translates to:
  /// **'Nearest technicians'**
  String get assignTechnician;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned.'**
  String get assigned;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Can spend'**
  String get available;

  /// No description provided for @awaitingClientId.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client ID'**
  String get awaitingClientId;

  /// No description provided for @awayTitle.
  ///
  /// In en, this message translates to:
  /// **'Far from the house'**
  String get awayTitle;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'busy'**
  String get busy;

  /// No description provided for @cableMetres.
  ///
  /// In en, this message translates to:
  /// **'Cable (metres)'**
  String get cableMetres;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @cancelRequestQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get cancelRequestQuestion;

  /// No description provided for @cannotInstall.
  ///
  /// In en, this message translates to:
  /// **'This ticket cannot take install details now (only the assigned technician, while the client is pending).'**
  String get cannotInstall;

  /// No description provided for @cashHint.
  ///
  /// In en, this message translates to:
  /// **'The line turns on now. The payment waits for the owner; the client\'s paid SMS goes after approval.'**
  String get cashHint;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @clientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientId;

  /// No description provided for @clientSaved.
  ///
  /// In en, this message translates to:
  /// **'Client saved.'**
  String get clientSaved;

  /// No description provided for @clientSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, ID, phone or PPPoE'**
  String get clientSearchHint;

  /// No description provided for @clientsAdvanceHeld.
  ///
  /// In en, this message translates to:
  /// **'Clients\' advance held'**
  String get clientsAdvanceHeld;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @collectedBy.
  ///
  /// In en, this message translates to:
  /// **'Collected by'**
  String get collectedBy;

  /// No description provided for @collectedToday.
  ///
  /// In en, this message translates to:
  /// **'Collected today'**
  String get collectedToday;

  /// No description provided for @confirmRecharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge for {months} month(s), {amount}?'**
  String confirmRecharge(String amount, String months);

  /// No description provided for @confirmTake.
  ///
  /// In en, this message translates to:
  /// **'Take {amount} from {name}?'**
  String confirmTake(String amount, String name);

  /// No description provided for @creditAlert.
  ///
  /// In en, this message translates to:
  /// **'Your credit is nearly used up.'**
  String get creditAlert;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @creditUsed.
  ///
  /// In en, this message translates to:
  /// **'Credit used'**
  String get creditUsed;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dayEndHandover.
  ///
  /// In en, this message translates to:
  /// **'Day-end handover'**
  String get dayEndHandover;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysLeft(int days);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get decline;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get descriptionOptional;

  /// No description provided for @disconnects24h.
  ///
  /// In en, this message translates to:
  /// **'Disconnects (24 h)'**
  String get disconnects24h;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @dutyEnded.
  ///
  /// In en, this message translates to:
  /// **'Duty ended.'**
  String get dutyEnded;

  /// No description provided for @dutyHours.
  ///
  /// In en, this message translates to:
  /// **'Duty hours'**
  String get dutyHours;

  /// No description provided for @dutyLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Your location is asked when you start or end duty. Location is never taken off duty.'**
  String get dutyLocationHint;

  /// No description provided for @dutyStarted.
  ///
  /// In en, this message translates to:
  /// **'Duty started.'**
  String get dutyStarted;

  /// No description provided for @dutyStatus.
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get dutyStatus;

  /// No description provided for @endDuty.
  ///
  /// In en, this message translates to:
  /// **'End duty'**
  String get endDuty;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity for at least one part.'**
  String get enterQuantity;

  /// No description provided for @expenseAvailable.
  ///
  /// In en, this message translates to:
  /// **'Can spend on expenses'**
  String get expenseAvailable;

  /// No description provided for @expenseHint.
  ///
  /// In en, this message translates to:
  /// **'Every expense waits for someone else\'s approval.'**
  String get expenseHint;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved. It waits for approval.'**
  String get expenseSaved;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// No description provided for @featureApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get featureApprovals;

  /// No description provided for @featureChat.
  ///
  /// In en, this message translates to:
  /// **'Support chat'**
  String get featureChat;

  /// No description provided for @featureDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get featureDashboard;

  /// No description provided for @featureDueList.
  ///
  /// In en, this message translates to:
  /// **'Due list'**
  String get featureDueList;

  /// No description provided for @featureDuty.
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get featureDuty;

  /// No description provided for @featureExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get featureExpenses;

  /// No description provided for @featureExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring clients'**
  String get featureExpiring;

  /// No description provided for @featureOffers.
  ///
  /// In en, this message translates to:
  /// **'Job offers'**
  String get featureOffers;

  /// No description provided for @featureSales.
  ///
  /// In en, this message translates to:
  /// **'Sell products'**
  String get featureSales;

  /// No description provided for @featureWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get featureWallet;

  /// No description provided for @fillAll.
  ///
  /// In en, this message translates to:
  /// **'Fill in everything needed.'**
  String get fillAll;

  /// No description provided for @forNewConnection.
  ///
  /// In en, this message translates to:
  /// **'For a new connection'**
  String get forNewConnection;

  /// No description provided for @forNewConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'The client ID is given later.'**
  String get forNewConnectionHint;

  /// No description provided for @gateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gateway;

  /// No description provided for @giveClientId.
  ///
  /// In en, this message translates to:
  /// **'Give ID'**
  String get giveClientId;

  /// No description provided for @handoverDue.
  ///
  /// In en, this message translates to:
  /// **'To hand over'**
  String get handoverDue;

  /// No description provided for @handoverSent.
  ///
  /// In en, this message translates to:
  /// **'Handover sent to the owner.'**
  String get handoverSent;

  /// No description provided for @handovers.
  ///
  /// In en, this message translates to:
  /// **'Handovers'**
  String get handovers;

  /// No description provided for @holdBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your cash limit is reached. Hand over first.'**
  String get holdBlocked;

  /// No description provided for @inHand.
  ///
  /// In en, this message translates to:
  /// **'In hand'**
  String get inHand;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @installHint.
  ///
  /// In en, this message translates to:
  /// **'Saving turns the line on from today and resolves the ticket.'**
  String get installHint;

  /// No description provided for @installSaved.
  ///
  /// In en, this message translates to:
  /// **'Install saved.'**
  String get installSaved;

  /// No description provided for @installedAt.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedAt;

  /// No description provided for @lastDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Last disconnect'**
  String get lastDisconnect;

  /// No description provided for @lastRx.
  ///
  /// In en, this message translates to:
  /// **'Last RX power'**
  String get lastRx;

  /// No description provided for @lateMinutes.
  ///
  /// In en, this message translates to:
  /// **'Late (minutes)'**
  String get lateMinutes;

  /// No description provided for @leaveReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get leaveReason;

  /// No description provided for @leaveUnpaidQuestion.
  ///
  /// In en, this message translates to:
  /// **'Unpaid leave? (Cancel = paid leave)'**
  String get leaveUnpaidQuestion;

  /// No description provided for @leaves.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaves;

  /// No description provided for @liveConnection.
  ///
  /// In en, this message translates to:
  /// **'Online now?'**
  String get liveConnection;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off or not allowed.'**
  String get locationOff;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @materials.
  ///
  /// In en, this message translates to:
  /// **'Materials used'**
  String get materials;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @mobileOptional.
  ///
  /// In en, this message translates to:
  /// **'Mobile (optional)'**
  String get mobileOptional;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @myExpenses.
  ///
  /// In en, this message translates to:
  /// **'My expenses (7 days)'**
  String get myExpenses;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get nameOptional;

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get newClient;

  /// No description provided for @newClientHint.
  ///
  /// In en, this message translates to:
  /// **'Without a POP the client waits as pending; with a POP the line goes on now.'**
  String get newClientHint;

  /// No description provided for @newConnection.
  ///
  /// In en, this message translates to:
  /// **'New connection'**
  String get newConnection;

  /// No description provided for @newExpiry.
  ///
  /// In en, this message translates to:
  /// **'New expiry'**
  String get newExpiry;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get newTicket;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No conversations.'**
  String get noChats;

  /// No description provided for @noClients.
  ///
  /// In en, this message translates to:
  /// **'No clients found.'**
  String get noClients;

  /// No description provided for @noDashboard.
  ///
  /// In en, this message translates to:
  /// **'No dashboard boxes for your login.'**
  String get noDashboard;

  /// No description provided for @noDues.
  ///
  /// In en, this message translates to:
  /// **'No dues.'**
  String get noDues;

  /// No description provided for @noExpiring.
  ///
  /// In en, this message translates to:
  /// **'No clients expiring.'**
  String get noExpiring;

  /// No description provided for @noMaterials.
  ///
  /// In en, this message translates to:
  /// **'Nothing used on this ticket yet.'**
  String get noMaterials;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @noOffers.
  ///
  /// In en, this message translates to:
  /// **'No job offers now.'**
  String get noOffers;

  /// No description provided for @noParts.
  ///
  /// In en, this message translates to:
  /// **'The office has no parts in stock.'**
  String get noParts;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments.'**
  String get noPayments;

  /// No description provided for @noSales.
  ///
  /// In en, this message translates to:
  /// **'No sales yet.'**
  String get noSales;

  /// No description provided for @noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No technician on duty nearby.'**
  String get noSuggestions;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets.'**
  String get noTickets;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None.'**
  String get none;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @noteRequired.
  ///
  /// In en, this message translates to:
  /// **'Note (required)'**
  String get noteRequired;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @nothingToApprove.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for you.'**
  String get nothingToApprove;

  /// No description provided for @offDuty.
  ///
  /// In en, this message translates to:
  /// **'Off duty'**
  String get offDuty;

  /// No description provided for @offerSent.
  ///
  /// In en, this message translates to:
  /// **'Offered to the nearest technician.'**
  String get offerSent;

  /// No description provided for @offerTaken.
  ///
  /// In en, this message translates to:
  /// **'The ticket is yours.'**
  String get offerTaken;

  /// No description provided for @offerToNearest.
  ///
  /// In en, this message translates to:
  /// **'Offer to the nearest'**
  String get offerToNearest;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @oldExpiry.
  ///
  /// In en, this message translates to:
  /// **'Old expiry'**
  String get oldExpiry;

  /// No description provided for @onDuty.
  ///
  /// In en, this message translates to:
  /// **'On duty'**
  String get onDuty;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @onuPower.
  ///
  /// In en, this message translates to:
  /// **'ONU power'**
  String get onuPower;

  /// No description provided for @openTickets.
  ///
  /// In en, this message translates to:
  /// **'Open tickets'**
  String get openTickets;

  /// No description provided for @outCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get outCancelled;

  /// No description provided for @outDone.
  ///
  /// In en, this message translates to:
  /// **'Work done'**
  String get outDone;

  /// No description provided for @outDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get outDuplicate;

  /// No description provided for @outNoIssue.
  ///
  /// In en, this message translates to:
  /// **'No problem found'**
  String get outNoIssue;

  /// No description provided for @outcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'How did it end?'**
  String get outcomeTitle;

  /// No description provided for @outsideDutyHours.
  ///
  /// In en, this message translates to:
  /// **'Outside duty hours: duty cannot start now.'**
  String get outsideDutyHours;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get overdue;

  /// No description provided for @ownerCash.
  ///
  /// In en, this message translates to:
  /// **'Cash owner'**
  String get ownerCash;

  /// No description provided for @ownerDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital owner'**
  String get ownerDigital;

  /// No description provided for @package.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get package;

  /// No description provided for @payBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get payBank;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get payDigital;

  /// No description provided for @payDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get payDue;

  /// No description provided for @payTotal.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get payTotal;

  /// No description provided for @photoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get photoCamera;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get photoGallery;

  /// No description provided for @pickClient.
  ///
  /// In en, this message translates to:
  /// **'Choose client'**
  String get pickClient;

  /// No description provided for @ponPort.
  ///
  /// In en, this message translates to:
  /// **'PON port'**
  String get ponPort;

  /// No description provided for @pop.
  ///
  /// In en, this message translates to:
  /// **'POP'**
  String get pop;

  /// No description provided for @popOptional.
  ///
  /// In en, this message translates to:
  /// **'POP (optional)'**
  String get popOptional;

  /// No description provided for @pppoePassword.
  ///
  /// In en, this message translates to:
  /// **'PPPoE password'**
  String get pppoePassword;

  /// No description provided for @pppoeUser.
  ///
  /// In en, this message translates to:
  /// **'PPPoE username'**
  String get pppoeUser;

  /// No description provided for @prHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get prHigh;

  /// No description provided for @prLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get prLow;

  /// No description provided for @prMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get prMedium;

  /// No description provided for @prUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get prUrgent;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @purLineWork.
  ///
  /// In en, this message translates to:
  /// **'Line work'**
  String get purLineWork;

  /// No description provided for @purNewConnection.
  ///
  /// In en, this message translates to:
  /// **'New connection'**
  String get purNewConnection;

  /// No description provided for @purOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get purOther;

  /// No description provided for @purRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get purRepair;

  /// No description provided for @purShift.
  ///
  /// In en, this message translates to:
  /// **'Shifting'**
  String get purShift;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantity;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @receiptNotImage.
  ///
  /// In en, this message translates to:
  /// **'This receipt is not a picture. Open it on the ERP website.'**
  String get receiptNotImage;

  /// No description provided for @receiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get receiptPhoto;

  /// No description provided for @receiptPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo added'**
  String get receiptPhotoAdded;

  /// No description provided for @recentPayments.
  ///
  /// In en, this message translates to:
  /// **'Last payments'**
  String get recentPayments;

  /// No description provided for @recentSales.
  ///
  /// In en, this message translates to:
  /// **'My last sales'**
  String get recentSales;

  /// No description provided for @recharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get recharge;

  /// No description provided for @rechargeDone.
  ///
  /// In en, this message translates to:
  /// **'Recharged. New expiry: {expiry}'**
  String rechargeDone(String expiry);

  /// No description provided for @rechargePending.
  ///
  /// In en, this message translates to:
  /// **'This client must be completed on the website first.'**
  String get rechargePending;

  /// No description provided for @recordInstall.
  ///
  /// In en, this message translates to:
  /// **'Record install'**
  String get recordInstall;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent.'**
  String get requestSent;

  /// No description provided for @roleHelper.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get roleHelper;

  /// No description provided for @router.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get router;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveHouseLocation.
  ///
  /// In en, this message translates to:
  /// **'Save house GPS'**
  String get saveHouseLocation;

  /// No description provided for @saveHouseLocationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you standing at the client\'s house? Save this place as the house location?'**
  String get saveHouseLocationQuestion;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get saved;

  /// No description provided for @scanCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Serial, barcode or SKU'**
  String get scanCodeHint;

  /// No description provided for @scanItem.
  ///
  /// In en, this message translates to:
  /// **'Scan / type code'**
  String get scanItem;

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s left'**
  String secondsLeft(int seconds);

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get since;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold.'**
  String get sold;

  /// No description provided for @soldCashToHandover.
  ///
  /// In en, this message translates to:
  /// **'Sold. The cash goes into your day-end handover.'**
  String get soldCashToHandover;

  /// No description provided for @stActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stActive;

  /// No description provided for @stApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get stApproved;

  /// No description provided for @stAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get stAssigned;

  /// No description provided for @stAwaitingClient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client ID'**
  String get stAwaitingClient;

  /// No description provided for @stCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get stCancelled;

  /// No description provided for @stClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get stClosed;

  /// No description provided for @stDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stDone;

  /// No description provided for @stExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get stExpired;

  /// No description provided for @stInProgress.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get stInProgress;

  /// No description provided for @stOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get stOnTheWay;

  /// No description provided for @stOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get stOpen;

  /// No description provided for @stPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly approved'**
  String get stPartial;

  /// No description provided for @stPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get stPending;

  /// No description provided for @stRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get stRejected;

  /// No description provided for @stReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get stReopened;

  /// No description provided for @stResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get stResolved;

  /// No description provided for @stScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get stScheduled;

  /// No description provided for @stSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get stSuspended;

  /// No description provided for @startDuty.
  ///
  /// In en, this message translates to:
  /// **'Start duty'**
  String get startDuty;

  /// No description provided for @startedAt.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedAt;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @subjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Write the subject.'**
  String get subjectRequired;

  /// No description provided for @take.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get take;

  /// No description provided for @takeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get takeCash;

  /// No description provided for @takeTrx.
  ///
  /// In en, this message translates to:
  /// **'bKash / Nagad TrxID'**
  String get takeTrx;

  /// No description provided for @ticketOpened.
  ///
  /// In en, this message translates to:
  /// **'Ticket opened.'**
  String get ticketOpened;

  /// No description provided for @ticketSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Subject, #ID, client'**
  String get ticketSearchHint;

  /// No description provided for @ticketsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ticketsActive;

  /// No description provided for @ticketsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ticketsAll;

  /// No description provided for @ticketsDone.
  ///
  /// In en, this message translates to:
  /// **'Done (30 days)'**
  String get ticketsDone;

  /// No description provided for @ticketsMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get ticketsMine;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @trxHint.
  ///
  /// In en, this message translates to:
  /// **'The digital owner checks the TrxID before it counts.'**
  String get trxHint;

  /// No description provided for @trxId.
  ///
  /// In en, this message translates to:
  /// **'TrxID'**
  String get trxId;

  /// No description provided for @useParts.
  ///
  /// In en, this message translates to:
  /// **'Use parts'**
  String get useParts;

  /// No description provided for @useWebsite.
  ///
  /// In en, this message translates to:
  /// **'Use the ERP website for this.'**
  String get useWebsite;

  /// No description provided for @waitingHandovers.
  ///
  /// In en, this message translates to:
  /// **'Handovers waiting'**
  String get waitingHandovers;

  /// No description provided for @waitsForApproval.
  ///
  /// In en, this message translates to:
  /// **'The client\'s paid SMS goes after the owner approves.'**
  String get waitsForApproval;

  /// No description provided for @walletAfter.
  ///
  /// In en, this message translates to:
  /// **'Wallet after'**
  String get walletAfter;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get walletBalance;

  /// No description provided for @walletCharge.
  ///
  /// In en, this message translates to:
  /// **'From wallet'**
  String get walletCharge;

  /// No description provided for @whatFor.
  ///
  /// In en, this message translates to:
  /// **'What for'**
  String get whatFor;

  /// No description provided for @withinDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String withinDays(int days);

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get writeMessage;
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
