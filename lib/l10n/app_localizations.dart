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
  /// **'ISP Staff'**
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

  /// No description provided for @serverLabel.
  ///
  /// In en, this message translates to:
  /// **'ERP address'**
  String get serverLabel;

  /// No description provided for @serverHint.
  ///
  /// In en, this message translates to:
  /// **'bill.example.com'**
  String get serverHint;

  /// No description provided for @serverHelp.
  ///
  /// In en, this message translates to:
  /// **'Your company\'s ERP web address. Ask the office if you don\'t know it.'**
  String get serverHelp;

  /// No description provided for @serverInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an https web address, e.g. bill.example.com'**
  String get serverInvalid;

  /// No description provided for @serverNotErp.
  ///
  /// In en, this message translates to:
  /// **'No ERP found at this address. Check it and try again.'**
  String get serverNotErp;

  /// No description provided for @serverChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get serverChange;

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

  /// No description provided for @loginIdentifierInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the ERP email, or a mobile like 01711000001.'**
  String get loginIdentifierInvalid;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address from the ERP.'**
  String get loginEmailInvalid;

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
  /// **'Email or password is incorrect.'**
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

  /// No description provided for @featureDueList.
  ///
  /// In en, this message translates to:
  /// **'Due list'**
  String get featureDueList;

  /// No description provided for @featureApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get featureApprovals;

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

  /// No description provided for @featureChat.
  ///
  /// In en, this message translates to:
  /// **'Support chat'**
  String get featureChat;

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
  /// **'ISP Staff is locked'**
  String get lockTitle;

  /// No description provided for @lockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock ISP Staff'**
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

  /// No description provided for @featureDuty.
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get featureDuty;

  /// No description provided for @dutyStatus.
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get dutyStatus;

  /// No description provided for @dutyOn.
  ///
  /// In en, this message translates to:
  /// **'On duty'**
  String get dutyOn;

  /// No description provided for @dutyOff.
  ///
  /// In en, this message translates to:
  /// **'Off duty'**
  String get dutyOff;

  /// No description provided for @dutyStart.
  ///
  /// In en, this message translates to:
  /// **'Start duty'**
  String get dutyStart;

  /// No description provided for @dutyEnd.
  ///
  /// In en, this message translates to:
  /// **'End duty'**
  String get dutyEnd;

  /// No description provided for @dutyHours.
  ///
  /// In en, this message translates to:
  /// **'Duty hours'**
  String get dutyHours;

  /// No description provided for @dutyTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get dutyTimezone;

  /// No description provided for @dutyDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance today'**
  String get dutyDistance;

  /// No description provided for @dutyMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String dutyMeters(int meters);

  /// No description provided for @dutyOutsideHours.
  ///
  /// In en, this message translates to:
  /// **'Duty can only start during duty hours.'**
  String get dutyOutsideHours;

  /// No description provided for @dutyStopped.
  ///
  /// In en, this message translates to:
  /// **'Duty ended. Location has stopped.'**
  String get dutyStopped;

  /// No description provided for @dutyNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff app: location on'**
  String get dutyNotificationTitle;

  /// No description provided for @dutyNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Location is shared only while you are on duty.'**
  String get dutyNotificationBody;

  /// No description provided for @featureOffers.
  ///
  /// In en, this message translates to:
  /// **'Job offers'**
  String get featureOffers;

  /// No description provided for @featureAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign a technician'**
  String get featureAssign;

  /// No description provided for @offersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No offers waiting.'**
  String get offersEmpty;

  /// No description provided for @offerAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get offerAccept;

  /// No description provided for @offerReject.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get offerReject;

  /// No description provided for @offerSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s left'**
  String offerSeconds(int seconds);

  /// No description provided for @offerDistance.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String offerDistance(int meters);

  /// No description provided for @offerTicket.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{id}'**
  String offerTicket(int id);

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'You took ticket #{id}.'**
  String offerAccepted(int id);

  /// No description provided for @assignNoTickets.
  ///
  /// In en, this message translates to:
  /// **'No open tickets to assign.'**
  String get assignNoTickets;

  /// No description provided for @assignTicketId.
  ///
  /// In en, this message translates to:
  /// **'Ticket number'**
  String get assignTicketId;

  /// No description provided for @assignLookup.
  ///
  /// In en, this message translates to:
  /// **'Show nearest'**
  String get assignLookup;

  /// No description provided for @assignForTicket.
  ///
  /// In en, this message translates to:
  /// **'Nearest for ticket #{id}'**
  String assignForTicket(int id);

  /// No description provided for @assignNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody on duty nearby.'**
  String get assignNobody;

  /// No description provided for @assignScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String assignScore(String score);

  /// No description provided for @assignEta.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String assignEta(int minutes);

  /// No description provided for @assignBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get assignBusy;

  /// No description provided for @assignSameArea.
  ///
  /// In en, this message translates to:
  /// **'Same area'**
  String get assignSameArea;

  /// No description provided for @assignButton.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignButton;

  /// No description provided for @assignDone.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}.'**
  String assignDone(String name);

  /// No description provided for @assignOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer to the nearest'**
  String get assignOffer;

  /// No description provided for @offerStarted.
  ///
  /// In en, this message translates to:
  /// **'Offered to {name}.'**
  String offerStarted(String name);

  /// No description provided for @offerNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody left to offer. The office has been told.'**
  String get offerNobody;

  /// No description provided for @ticketsSearch.
  ///
  /// In en, this message translates to:
  /// **'Name, ID or phone'**
  String get ticketsSearch;

  /// No description provided for @ticketsActive.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketsActive;

  /// No description provided for @ticketsDone.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get ticketsDone;

  /// No description provided for @ticketsAny.
  ///
  /// In en, this message translates to:
  /// **'Any status'**
  String get ticketsAny;

  /// No description provided for @ticketsMine.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get ticketsMine;

  /// No description provided for @ticketsAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s tickets'**
  String get ticketsAll;

  /// No description provided for @ticketsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tickets here.'**
  String get ticketsEmpty;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Over SLA'**
  String get overdue;

  /// No description provided for @ticketStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ticketStatus;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusOnTheWay;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get statusReopened;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

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

  /// No description provided for @pushPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get pushPriority;

  /// No description provided for @pushTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{id}'**
  String pushTicketTitle(int id);

  /// No description provided for @outcomeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get outcomeDone;

  /// No description provided for @outcomeNoIssue.
  ///
  /// In en, this message translates to:
  /// **'No issue'**
  String get outcomeNoIssue;

  /// No description provided for @outcomeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get outcomeDuplicate;

  /// No description provided for @outcomeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get outcomeCancelled;

  /// No description provided for @roleMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get roleMain;

  /// No description provided for @roleHelper.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get roleHelper;

  /// No description provided for @ticketDescription.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ticketDescription;

  /// No description provided for @ticketComments.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ticketComments;

  /// No description provided for @ticketNoComments.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get ticketNoComments;

  /// No description provided for @ticketNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get ticketNote;

  /// No description provided for @ticketSend.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get ticketSend;

  /// No description provided for @ticketNewConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'A new connection closes only with the client\'s PPPoE ID in the note.'**
  String get ticketNewConnectionHint;

  /// No description provided for @ticketAwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Away from the house'**
  String get ticketAwayTitle;

  /// No description provided for @ticketAwayHint.
  ///
  /// In en, this message translates to:
  /// **'Why are you finishing from here? (at least 5 characters)'**
  String get ticketAwayHint;

  /// No description provided for @ticketFinishDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance from the house'**
  String get ticketFinishDistance;

  /// No description provided for @ticketMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String ticketMeters(int meters);

  /// No description provided for @clientCode.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientCode;

  /// No description provided for @clientAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get clientAddress;

  /// No description provided for @clientPppoe.
  ///
  /// In en, this message translates to:
  /// **'PPPoE'**
  String get clientPppoe;

  /// No description provided for @onuSn.
  ///
  /// In en, this message translates to:
  /// **'ONU serial'**
  String get onuSn;

  /// No description provided for @onuMac.
  ///
  /// In en, this message translates to:
  /// **'ONU MAC'**
  String get onuMac;

  /// No description provided for @onuPort.
  ///
  /// In en, this message translates to:
  /// **'PON port'**
  String get onuPort;

  /// No description provided for @ticketCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get ticketCall;

  /// No description provided for @ticketMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get ticketMap;

  /// No description provided for @ticketLocation.
  ///
  /// In en, this message translates to:
  /// **'Save house GPS'**
  String get ticketLocation;

  /// No description provided for @ticketSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save this spot as the client\'s house?'**
  String get ticketSaveLocation;

  /// No description provided for @ticketLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'House location saved.'**
  String get ticketLocationSaved;

  /// No description provided for @ticketLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Turn it on and try again.'**
  String get ticketLocationDenied;

  /// No description provided for @ticketLocationMock.
  ///
  /// In en, this message translates to:
  /// **'This looks like a fake GPS. Turn it off before saving the house.'**
  String get ticketLocationMock;

  /// No description provided for @ticketDbm.
  ///
  /// In en, this message translates to:
  /// **'Check dBm'**
  String get ticketDbm;

  /// No description provided for @ticketDbmRx.
  ///
  /// In en, this message translates to:
  /// **'RX dBm'**
  String get ticketDbmRx;

  /// No description provided for @ticketDbmTx.
  ///
  /// In en, this message translates to:
  /// **'TX dBm'**
  String get ticketDbmTx;

  /// No description provided for @ticketDbmLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get ticketDbmLevel;

  /// No description provided for @ticketTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get ticketTakePhoto;

  /// No description provided for @ticketAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get ticketAddPhoto;

  /// No description provided for @ticketPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photo(s)'**
  String ticketPhotoCount(int count);

  /// No description provided for @ticketPhotoLimit.
  ///
  /// In en, this message translates to:
  /// **'A note can have up to 5 photos.'**
  String get ticketPhotoLimit;

  /// No description provided for @ticketPhotoTooBig.
  ///
  /// In en, this message translates to:
  /// **'That photo is larger than 5 MB.'**
  String get ticketPhotoTooBig;

  /// No description provided for @ticketCommentKept.
  ///
  /// In en, this message translates to:
  /// **'No internet. The note stays on this phone and will be sent later.'**
  String get ticketCommentKept;

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

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'My phones'**
  String get devicesTitle;

  /// No description provided for @devicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No phones are signed in.'**
  String get devicesEmpty;

  /// No description provided for @devicesUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get devicesUnnamed;

  /// No description provided for @devicesThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get devicesThisPhone;

  /// No description provided for @devicesSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get devicesSignOut;

  /// No description provided for @devicesSignOutThis.
  ///
  /// In en, this message translates to:
  /// **'Sign this phone out? You will need to sign in again.'**
  String get devicesSignOutThis;

  /// No description provided for @devicesSignOutOther.
  ///
  /// In en, this message translates to:
  /// **'Sign that phone out? It will stop receiving staff notifications.'**
  String get devicesSignOutOther;

  /// No description provided for @clientsSearch.
  ///
  /// In en, this message translates to:
  /// **'Name, ID, phone, PPPoE or ONU'**
  String get clientsSearch;

  /// No description provided for @clientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clients.'**
  String get clientsEmpty;

  /// No description provided for @clientsMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get clientsMore;

  /// No description provided for @clientsCode.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get clientsCode;

  /// No description provided for @clientsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get clientsAddress;

  /// No description provided for @clientsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get clientsStatus;

  /// No description provided for @clientsPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientsPackage;

  /// No description provided for @clientsPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get clientsPrice;

  /// No description provided for @clientsExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get clientsExpiry;

  /// No description provided for @clientsDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get clientsDue;

  /// No description provided for @clientsAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get clientsAdvance;

  /// No description provided for @clientsBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get clientsBalance;

  /// No description provided for @clientsPppoe.
  ///
  /// In en, this message translates to:
  /// **'PPPoE'**
  String get clientsPppoe;

  /// No description provided for @clientsNid.
  ///
  /// In en, this message translates to:
  /// **'NID'**
  String get clientsNid;

  /// No description provided for @clientsPop.
  ///
  /// In en, this message translates to:
  /// **'POP'**
  String get clientsPop;

  /// No description provided for @clientsRouter.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get clientsRouter;

  /// No description provided for @clientsOnu.
  ///
  /// In en, this message translates to:
  /// **'ONU'**
  String get clientsOnu;

  /// No description provided for @clientsRx.
  ///
  /// In en, this message translates to:
  /// **'Last RX dBm'**
  String get clientsRx;

  /// No description provided for @clientsConnection.
  ///
  /// In en, this message translates to:
  /// **'Line status'**
  String get clientsConnection;

  /// No description provided for @clientsOnline.
  ///
  /// In en, this message translates to:
  /// **'The line is online.'**
  String get clientsOnline;

  /// No description provided for @clientsOffline.
  ///
  /// In en, this message translates to:
  /// **'The line is offline.'**
  String get clientsOffline;

  /// No description provided for @clientsDisconnects.
  ///
  /// In en, this message translates to:
  /// **'{count} disconnects in 24 hours'**
  String clientsDisconnects(int count);

  /// No description provided for @clientsOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'Open tickets'**
  String get clientsOpenTickets;

  /// No description provided for @clientsPayments.
  ///
  /// In en, this message translates to:
  /// **'Recent payments'**
  String get clientsPayments;

  /// No description provided for @chatsSearch.
  ///
  /// In en, this message translates to:
  /// **'Client name, ID or phone'**
  String get chatsSearch;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations.'**
  String get chatsEmpty;

  /// No description provided for @chatsUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String chatsUnread(int count);

  /// No description provided for @chatsReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatsReply;

  /// No description provided for @collectionToday.
  ///
  /// In en, this message translates to:
  /// **'Collected today'**
  String get collectionToday;

  /// No description provided for @collectionInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get collectionInHand;

  /// No description provided for @collectionNotHanded.
  ///
  /// In en, this message translates to:
  /// **'Not handed over'**
  String get collectionNotHanded;

  /// No description provided for @collectionExpenseLeft.
  ///
  /// In en, this message translates to:
  /// **'Left for expenses'**
  String get collectionExpenseLeft;

  /// No description provided for @collectionHold.
  ///
  /// In en, this message translates to:
  /// **'Hand over cash before taking more.'**
  String get collectionHold;

  /// No description provided for @collectionCash.
  ///
  /// In en, this message translates to:
  /// **'Take cash'**
  String get collectionCash;

  /// No description provided for @collectionExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get collectionExpense;

  /// No description provided for @collectionHandover.
  ///
  /// In en, this message translates to:
  /// **'Hand over'**
  String get collectionHandover;

  /// No description provided for @collectionCashOwner.
  ///
  /// In en, this message translates to:
  /// **'Cash owner'**
  String get collectionCashOwner;

  /// No description provided for @collectionDigitalOwner.
  ///
  /// In en, this message translates to:
  /// **'Digital owner'**
  String get collectionDigitalOwner;

  /// No description provided for @collectionGateway.
  ///
  /// In en, this message translates to:
  /// **'bKash / Nagad'**
  String get collectionGateway;

  /// No description provided for @collectionSearch.
  ///
  /// In en, this message translates to:
  /// **'Name, ID, phone or PPPoE'**
  String get collectionSearch;

  /// No description provided for @collectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get collectionMore;

  /// No description provided for @collectionAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get collectionAmount;

  /// No description provided for @collectionNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get collectionNote;

  /// No description provided for @collectionTxn.
  ///
  /// In en, this message translates to:
  /// **'TrxID'**
  String get collectionTxn;

  /// No description provided for @collectionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get collectionSave;

  /// No description provided for @collectionReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get collectionReceipt;

  /// No description provided for @collectionApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get collectionApproval;

  /// No description provided for @collectionPaidSms.
  ///
  /// In en, this message translates to:
  /// **'Paid SMS'**
  String get collectionPaidSms;

  /// No description provided for @collectionSmsLater.
  ///
  /// In en, this message translates to:
  /// **'The client is told after the office approves.'**
  String get collectionSmsLater;

  /// No description provided for @dueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody is on the due list.'**
  String get dueEmpty;

  /// No description provided for @approvalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for you.'**
  String get approvalsEmpty;

  /// No description provided for @approvalsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approvalsApprove;

  /// No description provided for @featureDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get featureDashboard;

  /// No description provided for @featureExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring clients'**
  String get featureExpiring;

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

  /// No description provided for @workAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Package change'**
  String get workAdjustment;

  /// No description provided for @workAdvances.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get workAdvances;

  /// No description provided for @workAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get workAmount;

  /// No description provided for @workAskAdvance.
  ///
  /// In en, this message translates to:
  /// **'Ask for advance'**
  String get workAskAdvance;

  /// No description provided for @workAskLeave.
  ///
  /// In en, this message translates to:
  /// **'Ask for leave'**
  String get workAskLeave;

  /// No description provided for @workAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get workAttendance;

  /// No description provided for @workAvailable.
  ///
  /// In en, this message translates to:
  /// **'Can spend'**
  String get workAvailable;

  /// No description provided for @workAwaitingClient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client ID'**
  String get workAwaitingClient;

  /// No description provided for @workCableMetres.
  ///
  /// In en, this message translates to:
  /// **'Cable (metres)'**
  String get workCableMetres;

  /// No description provided for @workCannotInstall.
  ///
  /// In en, this message translates to:
  /// **'Install details cannot be given on this ticket now (only the assigned technician, while the client is pending).'**
  String get workCannotInstall;

  /// No description provided for @workClientSearch.
  ///
  /// In en, this message translates to:
  /// **'Name, ID, phone or PPPoE'**
  String get workClientSearch;

  /// No description provided for @workClientsAdvance.
  ///
  /// In en, this message translates to:
  /// **'Clients\' advance held'**
  String get workClientsAdvance;

  /// No description provided for @workCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Serial, barcode or SKU'**
  String get workCodeHint;

  /// No description provided for @workConfirmRecharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge for {months} month(s), ৳ {amount}?'**
  String workConfirmRecharge(String amount, int months);

  /// No description provided for @workCreditAlert.
  ///
  /// In en, this message translates to:
  /// **'Your credit is nearly used up.'**
  String get workCreditAlert;

  /// No description provided for @workCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get workCreditLimit;

  /// No description provided for @workCreditUsed.
  ///
  /// In en, this message translates to:
  /// **'Credit used'**
  String get workCreditUsed;

  /// No description provided for @workDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String workDaysLeft(int days);

  /// No description provided for @workEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity for at least one part.'**
  String get workEnterQuantity;

  /// No description provided for @workFillAll.
  ///
  /// In en, this message translates to:
  /// **'Fill in everything needed.'**
  String get workFillAll;

  /// No description provided for @workForNewConnection.
  ///
  /// In en, this message translates to:
  /// **'For a new connection (client ID later)'**
  String get workForNewConnection;

  /// No description provided for @workGiveClientId.
  ///
  /// In en, this message translates to:
  /// **'Give ID'**
  String get workGiveClientId;

  /// No description provided for @workInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get workInStock;

  /// No description provided for @workInstall.
  ///
  /// In en, this message translates to:
  /// **'New line install'**
  String get workInstall;

  /// No description provided for @workInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Saving turns the line on and resolves the ticket.'**
  String get workInstallHint;

  /// No description provided for @workInstallSaved.
  ///
  /// In en, this message translates to:
  /// **'Install saved.'**
  String get workInstallSaved;

  /// No description provided for @workLateMinutes.
  ///
  /// In en, this message translates to:
  /// **'Late (minutes)'**
  String get workLateMinutes;

  /// No description provided for @workLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get workLeaves;

  /// No description provided for @workMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials used'**
  String get workMaterials;

  /// No description provided for @workMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get workMethod;

  /// No description provided for @workMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get workMonths;

  /// No description provided for @workNewExpiry.
  ///
  /// In en, this message translates to:
  /// **'New expiry'**
  String get workNewExpiry;

  /// No description provided for @dashboardHelp.
  ///
  /// In en, this message translates to:
  /// **'The same numbers as the ERP dashboard. Pull down to refresh.'**
  String get dashboardHelp;

  /// No description provided for @workNoDashboard.
  ///
  /// In en, this message translates to:
  /// **'No dashboard boxes for your login.'**
  String get workNoDashboard;

  /// No description provided for @workNoExpiring.
  ///
  /// In en, this message translates to:
  /// **'No clients expiring.'**
  String get workNoExpiring;

  /// No description provided for @workNoMaterials.
  ///
  /// In en, this message translates to:
  /// **'Nothing used on this ticket yet.'**
  String get workNoMaterials;

  /// No description provided for @workNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales yet.'**
  String get workNoSales;

  /// No description provided for @workNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get workNoteOptional;

  /// No description provided for @workOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get workOk;

  /// No description provided for @workOldExpiry.
  ///
  /// In en, this message translates to:
  /// **'Old expiry'**
  String get workOldExpiry;

  /// No description provided for @workPayBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get workPayBank;

  /// No description provided for @workPayCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get workPayCash;

  /// No description provided for @workPayDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get workPayDigital;

  /// No description provided for @workPayDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get workPayDue;

  /// No description provided for @workPayTotal.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get workPayTotal;

  /// No description provided for @workPickClient.
  ///
  /// In en, this message translates to:
  /// **'Choose client'**
  String get workPickClient;

  /// No description provided for @workPonPort.
  ///
  /// In en, this message translates to:
  /// **'PON port'**
  String get workPonPort;

  /// No description provided for @workPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get workPrice;

  /// No description provided for @workPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get workPurpose;

  /// No description provided for @workPurposeLineWork.
  ///
  /// In en, this message translates to:
  /// **'Line work'**
  String get workPurposeLineWork;

  /// No description provided for @workPurposeNewConnection.
  ///
  /// In en, this message translates to:
  /// **'New connection'**
  String get workPurposeNewConnection;

  /// No description provided for @workPurposeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get workPurposeOther;

  /// No description provided for @workPurposeRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get workPurposeRepair;

  /// No description provided for @workPurposeShift.
  ///
  /// In en, this message translates to:
  /// **'Shifting'**
  String get workPurposeShift;

  /// No description provided for @workQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get workQuantity;

  /// No description provided for @workReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get workReason;

  /// No description provided for @workReceiptAdded.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo added'**
  String get workReceiptAdded;

  /// No description provided for @workReceiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get workReceiptPhoto;

  /// No description provided for @workRecentSales.
  ///
  /// In en, this message translates to:
  /// **'My last sales'**
  String get workRecentSales;

  /// No description provided for @workRecharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get workRecharge;

  /// No description provided for @workRechargeDone.
  ///
  /// In en, this message translates to:
  /// **'Recharged. New expiry: {expiry}'**
  String workRechargeDone(String expiry);

  /// No description provided for @workRechargePending.
  ///
  /// In en, this message translates to:
  /// **'This client must be completed on the website first.'**
  String get workRechargePending;

  /// No description provided for @workRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent.'**
  String get workRequestSent;

  /// No description provided for @workSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get workSave;

  /// No description provided for @workSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get workSaved;

  /// No description provided for @workScan.
  ///
  /// In en, this message translates to:
  /// **'Scan / type code'**
  String get workScan;

  /// No description provided for @workSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get workSell;

  /// No description provided for @workSold.
  ///
  /// In en, this message translates to:
  /// **'Sold.'**
  String get workSold;

  /// No description provided for @workSoldCash.
  ///
  /// In en, this message translates to:
  /// **'Sold. The cash goes into your day-end handover.'**
  String get workSoldCash;

  /// No description provided for @workTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get workTransactions;

  /// No description provided for @workUseParts.
  ///
  /// In en, this message translates to:
  /// **'Use parts'**
  String get workUseParts;

  /// No description provided for @workWalletAfter.
  ///
  /// In en, this message translates to:
  /// **'Wallet after'**
  String get workWalletAfter;

  /// No description provided for @workWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get workWalletBalance;

  /// No description provided for @workWalletCharge.
  ///
  /// In en, this message translates to:
  /// **'From wallet'**
  String get workWalletCharge;

  /// No description provided for @workWithinDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String workWithinDays(int days);

  /// No description provided for @approvalsAcceptAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount to accept (all or part)'**
  String get approvalsAcceptAmount;

  /// No description provided for @approvalsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get approvalsExpenses;

  /// No description provided for @approvalsHandovers.
  ///
  /// In en, this message translates to:
  /// **'Handovers'**
  String get approvalsHandovers;

  /// No description provided for @approvalsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get approvalsReject;

  /// No description provided for @approvalsRejectNote.
  ///
  /// In en, this message translates to:
  /// **'Why? (required)'**
  String get approvalsRejectNote;

  /// No description provided for @collectionMetres.
  ///
  /// In en, this message translates to:
  /// **'{metres} m away'**
  String collectionMetres(int metres);

  /// No description provided for @collectionNearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me with due'**
  String get collectionNearMe;

  /// No description provided for @collectionNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location is off or not allowed.'**
  String get collectionNoLocation;

  /// No description provided for @supportCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportCategory;

  /// No description provided for @supportClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get supportClient;

  /// No description provided for @supportClientSaved.
  ///
  /// In en, this message translates to:
  /// **'Client saved.'**
  String get supportClientSaved;

  /// No description provided for @supportDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get supportDetailsOptional;

  /// No description provided for @supportNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get supportNameOptional;

  /// No description provided for @supportNewClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get supportNewClient;

  /// No description provided for @supportNewClientHint.
  ///
  /// In en, this message translates to:
  /// **'Without a POP the client waits as pending; with a POP the line goes on now.'**
  String get supportNewClientHint;

  /// No description provided for @supportNewTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get supportNewTicket;

  /// No description provided for @supportPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Mobile (optional)'**
  String get supportPhoneOptional;

  /// No description provided for @supportPopOptional.
  ///
  /// In en, this message translates to:
  /// **'POP (optional)'**
  String get supportPopOptional;

  /// No description provided for @supportPppoePassword.
  ///
  /// In en, this message translates to:
  /// **'PPPoE password'**
  String get supportPppoePassword;

  /// No description provided for @supportPppoeUser.
  ///
  /// In en, this message translates to:
  /// **'PPPoE username'**
  String get supportPppoeUser;

  /// No description provided for @supportSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubject;

  /// No description provided for @supportTicketOpened.
  ///
  /// In en, this message translates to:
  /// **'Ticket opened.'**
  String get supportTicketOpened;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get scanTitle;

  /// No description provided for @scanTorch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get scanTorch;

  /// No description provided for @scanCameraOff.
  ///
  /// In en, this message translates to:
  /// **'The camera is off or not allowed. Type the code instead.'**
  String get scanCameraOff;

  /// No description provided for @collectionShareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get collectionShareReceipt;

  /// No description provided for @payslipTitle.
  ///
  /// In en, this message translates to:
  /// **'My payslips'**
  String get payslipTitle;

  /// No description provided for @payslipNone.
  ///
  /// In en, this message translates to:
  /// **'No payslip yet. It shows once the month\'s payroll is approved.'**
  String get payslipNone;

  /// No description provided for @payslipEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get payslipEarnings;

  /// No description provided for @payslipDeductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get payslipDeductions;

  /// No description provided for @payslipNet.
  ///
  /// In en, this message translates to:
  /// **'Net salary'**
  String get payslipNet;

  /// No description provided for @payslipPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payslipPayment;

  /// No description provided for @payslipPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get payslipPaidOn;

  /// No description provided for @payslipDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get payslipDays;

  /// No description provided for @payslipSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get payslipSharePdf;

  /// No description provided for @payslipBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get payslipBasic;

  /// No description provided for @payslipAllowance.
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get payslipAllowance;

  /// No description provided for @payslipBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get payslipBonus;

  /// No description provided for @payslipAttendanceBonus.
  ///
  /// In en, this message translates to:
  /// **'Attendance bonus'**
  String get payslipAttendanceBonus;

  /// No description provided for @payslipOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get payslipOvertime;

  /// No description provided for @payslipLate.
  ///
  /// In en, this message translates to:
  /// **'Late penalty'**
  String get payslipLate;

  /// No description provided for @payslipAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent deduction'**
  String get payslipAbsent;

  /// No description provided for @payslipOther.
  ///
  /// In en, this message translates to:
  /// **'Other deduction'**
  String get payslipOther;

  /// No description provided for @payslipAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance adjusted'**
  String get payslipAdvance;

  /// No description provided for @payslipWorkingDays.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get payslipWorkingDays;

  /// No description provided for @payslipPresentDays.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get payslipPresentDays;

  /// No description provided for @payslipAbsentDays.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get payslipAbsentDays;

  /// No description provided for @payslipLateDays.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get payslipLateDays;

  /// No description provided for @payslipOvertimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Overtime (minutes)'**
  String get payslipOvertimeMinutes;

  /// No description provided for @collectionPickClient.
  ///
  /// In en, this message translates to:
  /// **'Pick the client first.'**
  String get collectionPickClient;

  /// No description provided for @collectionEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount.'**
  String get collectionEnterAmount;

  /// No description provided for @collectionEnterTxn.
  ///
  /// In en, this message translates to:
  /// **'Enter the TrxID.'**
  String get collectionEnterTxn;

  /// No description provided for @collectionEnterNote.
  ///
  /// In en, this message translates to:
  /// **'Write what the expense was for.'**
  String get collectionEnterNote;

  /// No description provided for @collectionSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get collectionSaving;

  /// No description provided for @collectionSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. The money is taken.'**
  String get collectionSaved;

  /// No description provided for @collectionAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'This was already saved before; it was not saved twice.'**
  String get collectionAlreadySaved;

  /// No description provided for @collectionAnother.
  ///
  /// In en, this message translates to:
  /// **'Take another'**
  String get collectionAnother;

  /// No description provided for @collectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get collectionDone;

  /// No description provided for @collectionNoClients.
  ///
  /// In en, this message translates to:
  /// **'No client found.'**
  String get collectionNoClients;

  /// No description provided for @collectionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get collectionChange;

  /// No description provided for @collectionDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get collectionDue;

  /// No description provided for @collectionFind.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get collectionFind;

  /// No description provided for @collectionStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for office approval'**
  String get collectionStatusPending;

  /// No description provided for @collectionStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get collectionStatusApproved;

  /// No description provided for @collectionExpenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved and sent for approval.'**
  String get collectionExpenseSaved;

  /// No description provided for @collectionHandoverSaved.
  ///
  /// In en, this message translates to:
  /// **'Handover sent. Waiting for the owner to accept.'**
  String get collectionHandoverSaved;

  /// No description provided for @clientsFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get clientsFilter;

  /// No description provided for @clientsAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get clientsAny;

  /// No description provided for @clientsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientsClear;

  /// No description provided for @clientsApply.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get clientsApply;

  /// No description provided for @clientsFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get clientsFilterStatus;

  /// No description provided for @clientsFilterZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get clientsFilterZone;

  /// No description provided for @clientsFilterRouter.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get clientsFilterRouter;

  /// No description provided for @clientsFilterPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientsFilterPackage;

  /// No description provided for @clientsFilterReseller.
  ///
  /// In en, this message translates to:
  /// **'Reseller'**
  String get clientsFilterReseller;

  /// No description provided for @clientsFilterPolicy.
  ///
  /// In en, this message translates to:
  /// **'Billing policy'**
  String get clientsFilterPolicy;

  /// No description provided for @clientsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Client type'**
  String get clientsFilterType;

  /// No description provided for @clientsSort.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get clientsSort;

  /// No description provided for @clientsSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get clientsSortOrder;

  /// No description provided for @clientsSortDesc.
  ///
  /// In en, this message translates to:
  /// **'High to low / newest first'**
  String get clientsSortDesc;

  /// No description provided for @clientsSortAsc.
  ///
  /// In en, this message translates to:
  /// **'Low to high / A to Z'**
  String get clientsSortAsc;

  /// No description provided for @clientsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get clientsSortNewest;

  /// No description provided for @clientsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get clientsSortName;

  /// No description provided for @clientsSortClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientsSortClientId;

  /// No description provided for @clientsSortPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientsSortPackage;

  /// No description provided for @clientsSortExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get clientsSortExpiry;

  /// No description provided for @clientsSortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get clientsSortStatus;

  /// No description provided for @clientsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} clients'**
  String clientsTotal(int count);

  /// No description provided for @featureOlt.
  ///
  /// In en, this message translates to:
  /// **'OLT'**
  String get featureOlt;

  /// No description provided for @oltHelp.
  ///
  /// In en, this message translates to:
  /// **'The ERP\'s OLT pages. View only.'**
  String get oltHelp;

  /// No description provided for @oltOnus.
  ///
  /// In en, this message translates to:
  /// **'ONUs'**
  String get oltOnus;

  /// No description provided for @oltOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get oltOnline;

  /// No description provided for @oltOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get oltOffline;

  /// No description provided for @oltWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak Rx'**
  String get oltWeak;

  /// No description provided for @oltUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unreachable'**
  String get oltUnreachable;

  /// No description provided for @oltInactive.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get oltInactive;

  /// No description provided for @oltAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent alerts'**
  String get oltAlerts;

  /// No description provided for @oltUnmatched.
  ///
  /// In en, this message translates to:
  /// **'Unmatched ONUs ({count})'**
  String oltUnmatched(int count);

  /// No description provided for @oltNone.
  ///
  /// In en, this message translates to:
  /// **'No OLTs.'**
  String get oltNone;

  /// No description provided for @oltPorts.
  ///
  /// In en, this message translates to:
  /// **'PON ports'**
  String get oltPorts;

  /// No description provided for @oltPortDead.
  ///
  /// In en, this message translates to:
  /// **'Whole port down'**
  String get oltPortDead;

  /// No description provided for @oltFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ONUs'**
  String get oltFilterAll;

  /// No description provided for @oltFilterGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get oltFilterGood;

  /// No description provided for @oltFilterWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get oltFilterWarning;

  /// No description provided for @oltFilterCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get oltFilterCritical;

  /// No description provided for @oltFilterDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get oltFilterDown;

  /// No description provided for @oltFilterWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak Rx'**
  String get oltFilterWeak;

  /// No description provided for @oltSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get oltSort;

  /// No description provided for @oltSortPon.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get oltSortPon;

  /// No description provided for @oltSortRx.
  ///
  /// In en, this message translates to:
  /// **'Rx'**
  String get oltSortRx;

  /// No description provided for @oltSortDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get oltSortDistance;

  /// No description provided for @oltSortUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get oltSortUptime;

  /// No description provided for @oltSortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get oltSortStatus;

  /// No description provided for @oltAvgRx.
  ///
  /// In en, this message translates to:
  /// **'Average Rx: {rx} dBm'**
  String oltAvgRx(String rx);

  /// No description provided for @oltNoOnus.
  ///
  /// In en, this message translates to:
  /// **'No ONUs found.'**
  String get oltNoOnus;

  /// No description provided for @oltMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get oltMore;

  /// No description provided for @oltSearchOnu.
  ///
  /// In en, this message translates to:
  /// **'Serial, MAC, port or description'**
  String get oltSearchOnu;

  /// No description provided for @oltLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the OLT data.'**
  String get oltLoadFailed;

  /// No description provided for @oltNoClient.
  ///
  /// In en, this message translates to:
  /// **'No client'**
  String get oltNoClient;
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
