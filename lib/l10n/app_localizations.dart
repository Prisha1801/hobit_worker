import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hobit Worker'**
  String get appTitle;

  /// No description provided for @languageSelection.
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get languageSelection;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Trusted Home Service Partner'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Hobit Worker is a platform created to empower service professionals by connecting them with verified service requests in their nearby areas. Our goal is to provide flexible work opportunities, transparent earnings, and a secure working environment for all workers.\n\nThis app helps workers manage jobs, track earnings, and grow their professional journey with ease.'**
  String get aboutDescription;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get supportEmail;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Hobit Pvt. Ltd.'**
  String get companyName;

  /// No description provided for @supportEmailValue.
  ///
  /// In en, this message translates to:
  /// **'support@hobit.in'**
  String get supportEmailValue;

  /// No description provided for @websiteValue.
  ///
  /// In en, this message translates to:
  /// **'www.hobit.in'**
  String get websiteValue;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Hobit. All rights reserved.'**
  String get copyright;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @needHelpHeader.
  ///
  /// In en, this message translates to:
  /// **'Need help? We’re here for you.\nGet quick support for your work.'**
  String get needHelpHeader;

  /// No description provided for @quickSupport.
  ///
  /// In en, this message translates to:
  /// **'Quick Support'**
  String get quickSupport;

  /// No description provided for @callSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get callSupport;

  /// No description provided for @callSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Talk to our support executive'**
  String get callSupportSubtitle;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @emailSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'support@hobit.in'**
  String get emailSupportSubtitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @helloWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello, Welcome Back'**
  String get helloWelcome;

  /// No description provided for @jobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Jobs Completed'**
  String get jobsCompleted;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @personalInfoSub.
  ///
  /// In en, this message translates to:
  /// **'Name, contact, location'**
  String get personalInfoSub;

  /// No description provided for @addBank.
  ///
  /// In en, this message translates to:
  /// **'Add Bank'**
  String get addBank;

  /// No description provided for @addBankSub.
  ///
  /// In en, this message translates to:
  /// **'Add your bank account for payouts'**
  String get addBankSub;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Payouts'**
  String get earnings;

  /// No description provided for @earningsSub.
  ///
  /// In en, this message translates to:
  /// **'View your earnings and payout history'**
  String get earningsSub;

  /// No description provided for @helpSupportSub.
  ///
  /// In en, this message translates to:
  /// **'Get help or contact support'**
  String get helpSupportSub;

  /// No description provided for @languageSelectionSub.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSelectionSub;

  /// No description provided for @aboutUsSub.
  ///
  /// In en, this message translates to:
  /// **'App info, terms & privacy'**
  String get aboutUsSub;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutSub.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get logoutSub;

  /// No description provided for @addBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Your Bank Details'**
  String get addBankTitle;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderName;

  /// No description provided for @accountHolderHint.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderHint;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @accountNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Your Account Number'**
  String get accountNumberHint;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @bankNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your Bank Name'**
  String get bankNameHint;

  /// No description provided for @ifscCode.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get ifscCode;

  /// No description provided for @ifscCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Your Bank IFSC Code'**
  String get ifscCodeHint;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @bankUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bank details updated'**
  String get bankUpdated;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

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

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @availabilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Availability Status'**
  String get availabilityStatus;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @selectCityFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select city first'**
  String get selectCityFirst;

  /// No description provided for @selectZoneFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select zone first'**
  String get selectZoneFirst;

  /// No description provided for @workerAvailability.
  ///
  /// In en, this message translates to:
  /// **'Worker Availability'**
  String get workerAvailability;

  /// No description provided for @availableDates.
  ///
  /// In en, this message translates to:
  /// **'Available Dates'**
  String get availableDates;

  /// No description provided for @availableTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'Available Time Slots'**
  String get availableTimeSlots;

  /// No description provided for @noAvailability.
  ///
  /// In en, this message translates to:
  /// **'No Availability Added'**
  String get noAvailability;

  /// No description provided for @selectAvailableDates.
  ///
  /// In en, this message translates to:
  /// **'Select Available Dates'**
  String get selectAvailableDates;

  /// No description provided for @noDatesAdded.
  ///
  /// In en, this message translates to:
  /// **'No dates added'**
  String get noDatesAdded;

  /// No description provided for @addDate.
  ///
  /// In en, this message translates to:
  /// **'Add Date'**
  String get addDate;

  /// No description provided for @selectTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'Select time range'**
  String get selectTimeSlots;

  /// No description provided for @noTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'No time slots added'**
  String get noTimeSlots;

  /// No description provided for @addTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Add Time Slot'**
  String get addTimeSlot;

  /// No description provided for @kycDetails.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification Details'**
  String get kycDetails;

  /// No description provided for @aadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get aadhaarNumber;

  /// No description provided for @policeId.
  ///
  /// In en, this message translates to:
  /// **'Police Verification ID'**
  String get policeId;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded'**
  String get documentUploaded;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @kycUploaded.
  ///
  /// In en, this message translates to:
  /// **'KYC uploaded successfully'**
  String get kycUploaded;

  /// No description provided for @uploadAllDocs.
  ///
  /// In en, this message translates to:
  /// **'Please upload all documents'**
  String get uploadAllDocs;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @enterAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Aadhaar Number'**
  String get enterAadhaarNumber;

  /// No description provided for @enterPoliceId.
  ///
  /// In en, this message translates to:
  /// **'Enter ID'**
  String get enterPoliceId;

  /// No description provided for @aadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card (Front)'**
  String get aadhaarFront;

  /// No description provided for @aadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card (Back)'**
  String get aadhaarBack;

  /// No description provided for @policeFront.
  ///
  /// In en, this message translates to:
  /// **'Police Verification (Front)'**
  String get policeFront;

  /// No description provided for @policeBack.
  ///
  /// In en, this message translates to:
  /// **'Police Verification (Back)'**
  String get policeBack;

  /// No description provided for @myEarnings.
  ///
  /// In en, this message translates to:
  /// **'My Earnings'**
  String get myEarnings;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @withdrawRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Request'**
  String get withdrawRequest;

  /// No description provided for @withdrawHistory.
  ///
  /// In en, this message translates to:
  /// **'Withdraw History'**
  String get withdrawHistory;

  /// No description provided for @noWithdrawHistory.
  ///
  /// In en, this message translates to:
  /// **'No withdrawal history found'**
  String get noWithdrawHistory;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @requestNote.
  ///
  /// In en, this message translates to:
  /// **'Request Note'**
  String get requestNote;

  /// No description provided for @weeklyPayout.
  ///
  /// In en, this message translates to:
  /// **'Weekly payout'**
  String get weeklyPayout;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get enterAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get enterValidAmount;

  /// No description provided for @withdrawDefaultNote.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request'**
  String get withdrawDefaultNote;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get logoutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @allRequests.
  ///
  /// In en, this message translates to:
  /// **'All Requests'**
  String get allRequests;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsFound;

  /// No description provided for @serviceRequested.
  ///
  /// In en, this message translates to:
  /// **'Service Requested'**
  String get serviceRequested;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @workShift.
  ///
  /// In en, this message translates to:
  /// **'Work shift : 09:00 AM to 06:00 PM'**
  String get workShift;

  /// No description provided for @currentAssignJob.
  ///
  /// In en, this message translates to:
  /// **'Current Assigned Job'**
  String get currentAssignJob;

  /// No description provided for @noAssignedJobToday.
  ///
  /// In en, this message translates to:
  /// **'No assigned job for today'**
  String get noAssignedJobToday;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// No description provided for @startService.
  ///
  /// In en, this message translates to:
  /// **'Start your Service'**
  String get startService;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @enterOtpMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get enterOtpMsg;

  /// No description provided for @dontReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Don\'t receive the code?'**
  String get dontReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @enterValidOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter valid OTP'**
  String get enterValidOtp;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalidOtp;

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'We are here for you!'**
  String get onboardTitle1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'All services at one tap'**
  String get onboardTitle2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'Trusted professionals nearby'**
  String get onboardTitle3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @allowLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow location access?'**
  String get allowLocationTitle;

  /// No description provided for @allowLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'We need your location to find nearby services.'**
  String get allowLocationDesc;

  /// No description provided for @allowLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get allowLocationButton;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your number'**
  String get enterPhone;

  /// No description provided for @keepSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get keepSignedIn;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an Account?'**
  String get dontHaveAccount;

  /// No description provided for @signUpHere.
  ///
  /// In en, this message translates to:
  /// **'Sign up here'**
  String get signUpHere;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid phone number'**
  String get invalidPhone;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP Sent'**
  String get otpSent;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @minPassword.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minPassword;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get selectCategories;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @selectServices.
  ///
  /// In en, this message translates to:
  /// **'Select Services'**
  String get selectServices;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @referCode.
  ///
  /// In en, this message translates to:
  /// **'Refer / Referral Code'**
  String get referCode;

  /// No description provided for @referHint.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code (optional)'**
  String get referHint;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get selectCity;

  /// No description provided for @selectZone.
  ///
  /// In en, this message translates to:
  /// **'Select zone'**
  String get selectZone;

  /// No description provided for @selectArea.
  ///
  /// In en, this message translates to:
  /// **'Select area'**
  String get selectArea;

  /// No description provided for @selectDates.
  ///
  /// In en, this message translates to:
  /// **'Select available dates'**
  String get selectDates;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Accept Terms & Conditions'**
  String get acceptTerms;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Have an account?'**
  String get haveAccount;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get signupSuccess;

  /// No description provided for @errName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get errName;

  /// No description provided for @errEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get errEmail;

  /// No description provided for @errEmailValid.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid email'**
  String get errEmailValid;

  /// No description provided for @errPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get errPhone;

  /// No description provided for @errPhoneLen.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get errPhoneLen;

  /// No description provided for @errPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get errPassword;

  /// No description provided for @errPasswordLen.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errPasswordLen;

  /// No description provided for @errCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one category'**
  String get errCategory;

  /// No description provided for @errService.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service'**
  String get errService;

  /// No description provided for @errCity.
  ///
  /// In en, this message translates to:
  /// **'Please select city'**
  String get errCity;

  /// No description provided for @errZone.
  ///
  /// In en, this message translates to:
  /// **'Please select zone'**
  String get errZone;

  /// No description provided for @errArea.
  ///
  /// In en, this message translates to:
  /// **'Please select area'**
  String get errArea;

  /// No description provided for @errDates.
  ///
  /// In en, this message translates to:
  /// **'Please select available dates'**
  String get errDates;

  /// No description provided for @errTimes.
  ///
  /// In en, this message translates to:
  /// **'Please select available time slots'**
  String get errTimes;

  /// No description provided for @errTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept Terms & Conditions'**
  String get errTerms;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
