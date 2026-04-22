// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Neqat';

  @override
  String get homePageTitle => 'Home';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get languageToggleLabel => 'Language';

  @override
  String get englishOption => 'English';

  @override
  String get amharicOption => 'Amharic';

  @override
  String get scanButton => 'Scan';

  @override
  String get productDetailsTitle => 'Product Details';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get supportTitle => 'Support';

  @override
  String get notificationOption => 'Notification';

  @override
  String get darkModeOption => 'Dark Mode';

  @override
  String get helpCenterOption => 'Help Center';

  @override
  String get changePasswordOption => 'Change Password';

  @override
  String get logOutOption => 'Log Out';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get webBarcodeUnsupported => 'Barcode scanning is not supported on the web.\nPlease test on a mobile device.';

  @override
  String get imageLoadFailed => 'Failed to load image';

  @override
  String get pointCameraAtBarcode => 'Point the camera at the product barcode';

  @override
  String get errorTitle => 'Error';

  @override
  String get scanBarcodeTitle => 'Scan barcode';

  @override
  String get startScanningButton => 'Start Scanning';

  @override
  String get manualEntryWebPrompt => 'Manual entry is available for testing on the web.';

  @override
  String get enterCodeManuallyPrompt => 'Or Enter Code Manually';

  @override
  String get manualEntryNonWebPrompt => 'If you unable to find the barcode using the camera, you can enter manually. The code must contain 13 digits.';

  @override
  String get enterCodeButton => 'ENTER CODE';

  @override
  String userGreeting(Object name) {
    return 'Hey, $name!';
  }

  @override
  String get editButton => 'Edit';

  @override
  String get globalNewsOption => 'Global news';

  @override
  String get loginTitle => 'Login';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPasswordLink => 'Forgot Password?';

  @override
  String get emptyFieldsError => 'Please fill in all fields';

  @override
  String get loginFailedError => 'Login failed. Please try again.';

  @override
  String get loginErrorPrefix => 'An error occurred during login:';

  @override
  String get socialLoginUnavailableError => 'Social login is currently unavailable';

  @override
  String get loginButton => 'Login';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get signUpSubtitle => 'Sign up to get started';

  @override
  String get fullNameHint => 'Full Name';

  @override
  String get firstNameHint => 'First Name';

  @override
  String get lastNameHint => 'Last Name';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get termsAndConditionsLabel => 'I agree to the Terms of Service and Privacy Policy';

  @override
  String get invalidEmailError => 'Please enter a valid email address';

  @override
  String get passwordRequirementError => 'Password must be at least 8 characters with letters and numbers';

  @override
  String get passwordMismatchError => 'Passwords do not match';

  @override
  String get termsNotAcceptedError => 'Please accept the terms and conditions';

  @override
  String get registrationFailedError => 'Registration failed. Please try again.';

  @override
  String get unexpectedError => 'An unexpected error occurred. Please try again.';

  @override
  String get registrationSuccessMessage => 'Registration successful! You can now login.';

  @override
  String get successTitle => 'Success';

  @override
  String get accountCreatedMessage => 'Your account has been created successfully. Please login with your credentials.';

  @override
  String get okButton => 'OK';

  @override
  String get registerButton => 'Register';

  @override
  String get orSignUpWith => 'Or Sign Up with';

  @override
  String get alreadyHaveAccountLink => 'Already have an account? Login';

  @override
  String get productsTitle => 'Products';

  @override
  String get searchProductsHint => 'Search products...';

  @override
  String get errorPrefix => 'Error:';

  @override
  String get noProductsFound => 'No products found.';

  @override
  String get noName => 'No name';

  @override
  String get noBrandInfo => 'No brand info';

  @override
  String get enterCodeManuallyTitle => 'Enter Code Manually';

  @override
  String get codeLengthError => 'The code must be 13 digits long.';

  @override
  String get enterBarcodeLabel => 'Enter 13-digit barcode';

  @override
  String get submitButton => 'Submit';

  @override
  String get onboardingFirstTitle => 'Awareness at Your Fingertips';

  @override
  String get onboardingFirstDescription => 'Whether it\'s staying updated on the latest news or knowing the truth about products, our app empowers you to stay aware and make informed decisions.';

  @override
  String get onboardingSecondTitle => 'Know What You Buy';

  @override
  String get onboardingSecondDescription => 'Scan product barcodes or read user feedback to uncover the truth about products. Make informed choices and shop with confidence.';

  @override
  String get onboardingThirdTitle => 'Stay Informed, Stay Ahead';

  @override
  String get onboardingThirdDescription => 'Get curated news updates on topics that matter to you. Stay informed about the world around you and make better decisions';

  @override
  String get nextButton => 'Next';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get emailResetPrompt => 'Enter your email to receive password reset instructions';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get verificationCodePrompt => 'Enter the verification code sent to your email';

  @override
  String get emailEmptyError => 'Please enter your email address';

  @override
  String get resetInstructionsSent => 'Reset instructions sent to your email';

  @override
  String get resetEmailFailed => 'Failed to send reset email. Please try again.';

  @override
  String get resetPasswordFailed => 'Failed to reset password. Please try again.';

  @override
  String get passwordResetSuccess => 'Your password has been reset successfully.';

  @override
  String get rememberPasswordLink => 'Remember your password? Login';

  @override
  String get verificationCodeHint => 'Verification Code';

  @override
  String get newPasswordHint => 'New Password';

  @override
  String get confirmNewPasswordHint => 'Confirm New Password';

  @override
  String get sendResetInstructionsButton => 'Send Reset Instructions';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get resendCodeButton => 'Resend Code';

  @override
  String newsTitle(String category) {
    return '$category News';
  }

  @override
  String get topCategory => 'Top';

  @override
  String get trendingCategory => 'Trending';

  @override
  String get thousandAbbreviation => 'K';

  @override
  String get noTitle => 'No Title';

  @override
  String get noDescription => 'No Description';

  @override
  String shareArticleMessage(String title, String url) {
    return 'Check out this article: $title\n$url';
  }

  @override
  String get currentOnLabel => 'Current on ';

  @override
  String get viewAllLabel => 'View all';

  @override
  String get trendingNewsTitle => 'Trending News';

  @override
  String get noTrendingNewsMessage => 'No trending news available';

  @override
  String get failedToLoadNewsError => 'Failed to load news. Please try again.';

  @override
  String get businessCategory => 'Business';

  @override
  String get entertainmentCategory => 'Entertainment';

  @override
  String get generalCategory => 'General';

  @override
  String get healthCategory => 'Health';

  @override
  String get scienceCategory => 'Science';

  @override
  String get sportsCategory => 'Sports';

  @override
  String get technologyCategory => 'Technology';
}
