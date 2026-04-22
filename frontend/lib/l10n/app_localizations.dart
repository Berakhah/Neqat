import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
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
/// import 'gen_l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Neqat'**
  String get appTitle;

  /// No description provided for @homePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePageTitle;

  /// No description provided for @settingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// No description provided for @languageToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageToggleLabel;

  /// No description provided for @englishOption.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishOption;

  /// No description provided for @amharicOption.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get amharicOption;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanButton;

  /// No description provided for @productDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailsTitle;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// No description provided for @notificationOption.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationOption;

  /// No description provided for @darkModeOption.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeOption;

  /// No description provided for @helpCenterOption.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterOption;

  /// No description provided for @changePasswordOption.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordOption;

  /// No description provided for @logOutOption.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutOption;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @webBarcodeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanning is not supported on the web.\nPlease test on a mobile device.'**
  String get webBarcodeUnsupported;

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get imageLoadFailed;

  /// No description provided for @pointCameraAtBarcode.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the product barcode'**
  String get pointCameraAtBarcode;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @scanBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcodeTitle;

  /// No description provided for @startScanningButton.
  ///
  /// In en, this message translates to:
  /// **'Start Scanning'**
  String get startScanningButton;

  /// No description provided for @manualEntryWebPrompt.
  ///
  /// In en, this message translates to:
  /// **'Manual entry is available for testing on the web.'**
  String get manualEntryWebPrompt;

  /// No description provided for @enterCodeManuallyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Or Enter Code Manually'**
  String get enterCodeManuallyPrompt;

  /// No description provided for @manualEntryNonWebPrompt.
  ///
  /// In en, this message translates to:
  /// **'If you unable to find the barcode using the camera, you can enter manually. The code must contain 13 digits.'**
  String get manualEntryNonWebPrompt;

  /// No description provided for @enterCodeButton.
  ///
  /// In en, this message translates to:
  /// **'ENTER CODE'**
  String get enterCodeButton;

  /// No description provided for @userGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey, {name}!'**
  String userGreeting(Object name);

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @globalNewsOption.
  ///
  /// In en, this message translates to:
  /// **'Global news'**
  String get globalNewsOption;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordLink;

  /// No description provided for @emptyFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get emptyFieldsError;

  /// No description provided for @loginFailedError.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailedError;

  /// No description provided for @loginErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during login:'**
  String get loginErrorPrefix;

  /// No description provided for @socialLoginUnavailableError.
  ///
  /// In en, this message translates to:
  /// **'Social login is currently unavailable'**
  String get socialLoginUnavailableError;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signUpSubtitle;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// No description provided for @termsAndConditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get termsAndConditionsLabel;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailError;

  /// No description provided for @passwordRequirementError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters with letters and numbers'**
  String get passwordRequirementError;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatchError;

  /// No description provided for @termsNotAcceptedError.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get termsNotAcceptedError;

  /// No description provided for @registrationFailedError.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailedError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// No description provided for @registrationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You can now login.'**
  String get registrationSuccessMessage;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @accountCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully. Please login with your credentials.'**
  String get accountCreatedMessage;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'Or Sign Up with'**
  String get orSignUpWith;

  /// No description provided for @alreadyHaveAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountLink;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProductsHint;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorPrefix;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get noProductsFound;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// No description provided for @noBrandInfo.
  ///
  /// In en, this message translates to:
  /// **'No brand info'**
  String get noBrandInfo;

  /// No description provided for @enterCodeManuallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Code Manually'**
  String get enterCodeManuallyTitle;

  /// No description provided for @codeLengthError.
  ///
  /// In en, this message translates to:
  /// **'The code must be 13 digits long.'**
  String get codeLengthError;

  /// No description provided for @enterBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter 13-digit barcode'**
  String get enterBarcodeLabel;

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @onboardingFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Awareness at Your Fingertips'**
  String get onboardingFirstTitle;

  /// No description provided for @onboardingFirstDescription.
  ///
  /// In en, this message translates to:
  /// **'Whether it’s staying updated on the latest news or knowing the truth about products, our app empowers you to stay aware and make informed decisions.'**
  String get onboardingFirstDescription;

  /// No description provided for @onboardingSecondTitle.
  ///
  /// In en, this message translates to:
  /// **'Know What You Buy'**
  String get onboardingSecondTitle;

  /// No description provided for @onboardingSecondDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan product barcodes or read user feedback to uncover the truth about products. Make informed choices and shop with confidence.'**
  String get onboardingSecondDescription;

  /// No description provided for @onboardingThirdTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Informed, Stay Ahead'**
  String get onboardingThirdTitle;

  /// No description provided for @onboardingThirdDescription.
  ///
  /// In en, this message translates to:
  /// **'Get curated news updates on topics that matter to you. Stay informed about the world around you and make better decisions'**
  String get onboardingThirdDescription;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @getStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @emailResetPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive password reset instructions'**
  String get emailResetPrompt;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @verificationCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your email'**
  String get verificationCodePrompt;

  /// No description provided for @emailEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get emailEmptyError;

  /// No description provided for @resetInstructionsSent.
  ///
  /// In en, this message translates to:
  /// **'Reset instructions sent to your email'**
  String get resetInstructionsSent;

  /// No description provided for @resetEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Please try again.'**
  String get resetEmailFailed;

  /// No description provided for @resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password. Please try again.'**
  String get resetPasswordFailed;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully.'**
  String get passwordResetSuccess;

  /// No description provided for @rememberPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Remember your password? Login'**
  String get rememberPasswordLink;

  /// No description provided for @verificationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCodeHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordHint;

  /// No description provided for @sendResetInstructionsButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Instructions'**
  String get sendResetInstructionsButton;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// Title for a news section with a dynamic category name
  ///
  /// In en, this message translates to:
  /// **'{category} News'**
  String newsTitle(String category);

  /// The category name for top news
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get topCategory;

  /// The category name for trending news
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trendingCategory;

  /// Abbreviation for thousands (e.g., 1K for 1000)
  ///
  /// In en, this message translates to:
  /// **'K'**
  String get thousandAbbreviation;

  /// Placeholder when an article has no title
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get noTitle;

  /// Placeholder when an article has no description
  ///
  /// In en, this message translates to:
  /// **'No Description'**
  String get noDescription;

  /// Message format for sharing an article
  ///
  /// In en, this message translates to:
  /// **'Check out this article: {title}\n{url}'**
  String shareArticleMessage(String title, String url);

  /// Label for the app title prefix
  ///
  /// In en, this message translates to:
  /// **'Current on '**
  String get currentOnLabel;

  /// Label for the view all link in section headers
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllLabel;

  /// Title for the trending news section
  ///
  /// In en, this message translates to:
  /// **'Trending News'**
  String get trendingNewsTitle;

  /// Message displayed when there are no trending news articles
  ///
  /// In en, this message translates to:
  /// **'No trending news available'**
  String get noTrendingNewsMessage;

  /// Error message when news fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load news. Please try again.'**
  String get failedToLoadNewsError;

  /// Category name for business news
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessCategory;

  /// Category name for entertainment news
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainmentCategory;

  /// Category name for general news
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalCategory;

  /// Category name for health news
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthCategory;

  /// Category name for science news
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get scienceCategory;

  /// Category name for sports news
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sportsCategory;

  /// Category name for technology news
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technologyCategory;

  /// Title of the comments page
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsPageTitle;

  /// Message displayed when there are no comments
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsMessage;

  /// Hint text for adding a new comment
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// Hint text for replying to a comment
  ///
  /// In en, this message translates to:
  /// **'Write your reply...'**
  String get writeReplyHint;

  /// Message prompting user to log in again
  ///
  /// In en, this message translates to:
  /// **'Please log in again'**
  String get loginAgainMessage;

  /// Message indicating session expiration
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpiredMessage;

  /// Error message for token refresh failure
  ///
  /// In en, this message translates to:
  /// **'Error refreshing token: {error}'**
  String tokenRefreshError(String error);

  /// Message when an article is not found in the backend
  ///
  /// In en, this message translates to:
  /// **'Article not found in backend'**
  String get articleNotFoundMessage;

  /// Error message for failing to fetch article ID
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch article ID: {details}'**
  String fetchArticleIdError(String details);

  /// Exception message for fetching article ID
  ///
  /// In en, this message translates to:
  /// **'Error fetching article ID: {error}'**
  String fetchArticleIdException(String error);

  /// Message for invalid comment data format
  ///
  /// In en, this message translates to:
  /// **'Invalid comment data format'**
  String get invalidCommentDataMessage;

  /// Error message for failing to load comments
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments: {details}'**
  String loadCommentsError(String details);

  /// Exception message for loading comments
  ///
  /// In en, this message translates to:
  /// **'Error loading comments: {error}'**
  String loadCommentsException(String error);

  /// Message when posting a comment fails due to missing article ID
  ///
  /// In en, this message translates to:
  /// **'Cannot post comment: Article ID not found'**
  String get postCommentNoIdMessage;

  /// Message when a comment field is empty
  ///
  /// In en, this message translates to:
  /// **'Comment cannot be empty'**
  String get emptyCommentMessage;

  /// Success message for posting a comment
  ///
  /// In en, this message translates to:
  /// **'Comment posted successfully'**
  String get commentPostedMessage;

  /// Error message for failing to post a comment
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment: {details}'**
  String postCommentError(String details);

  /// General error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String generalErrorMessage(String error);

  /// Label indicating a reply to a specific user
  ///
  /// In en, this message translates to:
  /// **'Replying to @{username}'**
  String replyingToLabel(String username);

  /// Label for the number of replies, with plural support
  ///
  /// In en, this message translates to:
  /// **'{count} repl{countIsOne, plural, one{y} other{ies}}'**
  String replyCountLabel(int count, int countIsOne);

  /// Hint text for the search news input field
  ///
  /// In en, this message translates to:
  /// **'Search News'**
  String get searchNewsHint;

  /// Label for the original search query
  ///
  /// In en, this message translates to:
  /// **'Original: {query}'**
  String originalQueryLabel(String query);

  /// Label for the stemmed search query
  ///
  /// In en, this message translates to:
  /// **'Stemmed: {query}'**
  String stemmedQueryLabel(String query);

  /// Message displayed when no news or Telegram messages are found
  ///
  /// In en, this message translates to:
  /// **'No news or Telegram messages found'**
  String get noNewsOrMessagesFound;

  /// Label for the total number of articles found
  ///
  /// In en, this message translates to:
  /// **'Found {count} articles'**
  String totalArticlesLabel(int count);

  /// Label for the total number of Telegram messages found
  ///
  /// In en, this message translates to:
  /// **'Found {count} telegram messages'**
  String totalTelegramMessagesLabel(int count);

  /// Title of the bookmarks screen
  ///
  /// In en: “Bookmarks”
  /// In am: “መዝግቦች”
  String get bookmarksTitle;

  /// Message shown when no bookmarks exist
  ///
  /// In en: “No bookmarks yet”
  /// In am: “ምንም መዝግቦች የሉም”
  String get noBookmarksMessage;

  /// Error text when loading bookmarks fails
  ///
  /// In en: “Error loading bookmarks”
  /// In am: “መዝግቦችን ማስጫን አልተሳካም።”
  String get errorLoadingBookmarks;

  /// Label for retry button on bookmarks error
  ///
  /// In en: “Retry”
  /// In am: “ዳግም መሞከር”
  String get retryButton;
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
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
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
