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
  /// **'MyNet: location on'**
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
