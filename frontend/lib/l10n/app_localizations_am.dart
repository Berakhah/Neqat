// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ነቃት';

  @override
  String get homePageTitle => 'ቤት';

  @override
  String get settingsPageTitle => 'ቅንብሮች';

  @override
  String get languageToggleLabel => 'ቋንቋ';

  @override
  String get englishOption => 'እንግሊዝኛ';

  @override
  String get amharicOption => 'አማርኛ';

  @override
  String get scanButton => 'ቃኝ';

  @override
  String get productDetailsTitle => 'የምርት ዝርዝሮች';

  @override
  String get goToSettings => 'ወደ ቅንብሮች ይሂዱ';

  @override
  String get preferencesTitle => 'ምርጫዎች';

  @override
  String get supportTitle => 'ድጋፍ';

  @override
  String get notificationOption => 'ማሳወቂያ';

  @override
  String get darkModeOption => 'ጨለማ ሁኔታ';

  @override
  String get helpCenterOption => 'የእገዛ ማዕከል';

  @override
  String get changePasswordOption => 'የይለፍ ቃል መቀየር';

  @override
  String get logOutOption => 'ውጣ';

  @override
  String get cancelButton => 'መሰረዝ';

  @override
  String get webBarcodeUnsupported =>
      'ባርኮድ መቃኘት በድር ላይ አይደገፍም።\nእባክዎ በሞባይል መሣሪያ ላይ ይሞክሩ።';

  @override
  String get imageLoadFailed => 'ምስል መጫን አልተሳካም';

  @override
  String get pointCameraAtBarcode => 'ካሜራውን ወደ ምርቱ ባርኮድ ያመልክቱ';

  @override
  String get errorTitle => 'ስህተት';

  @override
  String get scanBarcodeTitle => 'ባርኮድ ቃኝ';

  @override
  String get startScanningButton => 'መቃኘት ጀምር';

  @override
  String get manualEntryWebPrompt => 'በድር ላይ ለመሞከር በእጅ መግባት ይገኛል።';

  @override
  String get enterCodeManuallyPrompt => 'ወይም ኮድ በእጅ ያስገቡ';

  @override
  String get manualEntryNonWebPrompt =>
      'ባርኮድ በካሜራ መፈለግ ካልቻሉ፣ በእጅ ማስገባት ይችላሉ። ኮዱ 13 አሃዞችን መያዝ አለበት።';

  @override
  String get enterCodeButton => 'ኮድ አስገባ';

  @override
  String userGreeting(Object name) {
    return 'ሰላም፣ $name!';
  }

  @override
  String get editButton => 'አርትዕ';

  @override
  String get globalNewsOption => 'ዓለም አቀፍ ዜና';

  @override
  String get loginTitle => 'ግባ';

  @override
  String get emailHint => 'ኢሜልህን አስገባ';

  @override
  String get passwordHint => 'የይለፍ ቃልህን አስገባ';

  @override
  String get forgotPasswordLink => 'የይለፍ ቃል ረሳሁ?';

  @override
  String get emptyFieldsError => 'እባክህ ሁሉንም መስኮች ሙላ';

  @override
  String get loginFailedError => 'መግባት አልተሳካም። እባክህ እንደገና ሞክር።';

  @override
  String get loginErrorPrefix => 'በመግባት ጊዜ ስህተት ተከስቷል፡';

  @override
  String get socialLoginUnavailableError => 'ማህበራዊ መግባት በአሁኑ ጊዜ አይገኝም';

  @override
  String get loginButton => 'ግባ';

  @override
  String get orContinueWith => 'ወይም ቀጥል በ';

  @override
  String get noAccountPrompt => 'መለያ የለህም?';

  @override
  String get signUpLink => 'ተመዝገብ';

  @override
  String get createAccountTitle => 'መለያ ፍጠር';

  @override
  String get signUpSubtitle => 'መመዝገብ ጀምር';

  @override
  String get fullNameHint => 'ሙሉ ስም';

  @override
  String get confirmPasswordHint => 'የይለፍ ቃል አረጋግጥ';

  @override
  String get termsAndConditionsLabel => 'የአገልግሎት ውሎችን እና የግላዊነት ፖሊሲን እስማማለሁ';

  @override
  String get invalidEmailError => 'እባክህ ትክክለኛ ኢሜል አስገባ';

  @override
  String get passwordRequirementError =>
      'የይለፍ ቃል ቢያንስ 8 ቁምፊዎች መሆን አለበት እና ፊደሎችን እና ቁጥሮችን መያዝ አለበት';

  @override
  String get passwordMismatchError => 'የይለፍ ቃሎች አይዛመዱም';

  @override
  String get termsNotAcceptedError => 'እባክህ የአገልግሎት ውሎችን ተቀበል';

  @override
  String get registrationFailedError => 'መመዝገብ አልተሳካም። እባክህ እንደገና ሞክር።';

  @override
  String get unexpectedError => 'ያልተጠበቀ ስህተት ተከስቷል። እባክህ እንደገና ሞክር።';

  @override
  String get registrationSuccessMessage => 'መመዝገብ ተሳክቷል! አሁን መግባት ትችላለህ።';

  @override
  String get successTitle => 'ስኬት';

  @override
  String get accountCreatedMessage => 'መለያህ በተሳካ ሁኔታ ተፈጥሯል። እባክህ በመለያ መረጃህ ግባ።';

  @override
  String get okButton => 'እሺ';

  @override
  String get registerButton => 'መዝግብ';

  @override
  String get orSignUpWith => 'ወይም መመዝገብ በ';

  @override
  String get alreadyHaveAccountLink => 'መለያ አለህ? ግባ';

  @override
  String get productsTitle => 'ምርቶች';

  @override
  String get searchProductsHint => 'ምርቶችን ፈልግ...';

  @override
  String get errorPrefix => 'ስህተት፡';

  @override
  String get noProductsFound => 'ምርቶች አልተገኙም።';

  @override
  String get noName => 'ስም የለም';

  @override
  String get noBrandInfo => 'የምርት መረጃ የለም';

  @override
  String get enterCodeManuallyTitle => 'ኮድ በእጅ አስገባ';

  @override
  String get codeLengthError => 'ኮዱ 13 አሃዞች መሆን አለበት።';

  @override
  String get enterBarcodeLabel => '13 አሃዝ ባርኮድ አስገባ';

  @override
  String get submitButton => 'አስገባ';

  @override
  String get onboardingFirstTitle => 'ንቃተ ህሊና በጣቶችህ ጫፍ';

  @override
  String get onboardingFirstDescription =>
      'የቅርብ ጊዜ ዜናዎችን መከታተልም ሆነ ስለ ምርቶች እውነትን ማወቅ፣ መተግበሪያችን ንቃተ ህሊናህን እንድትጠብቅ እና በመረጃ ላይ የተመሰረተ ውሳኔ እንድታደርግ ያስችልሃል።';

  @override
  String get onboardingSecondTitle => 'የምትገዛውን ተረዳ';

  @override
  String get onboardingSecondDescription =>
      'የምርት ባርኮዶችን ቃኝ ወይም የተጠቃሚዎችን አስተያየት አንብብ ስለ ምርቶች እውነትን ለመረዳት። በመረጃ ላይ የተመሰረተ ምርጫ አድርግ እና በልበ ሙሉነት ግዢ አድርግ።';

  @override
  String get onboardingThirdTitle => 'መረጃ ይኑርህ፣ ቀድመህ ቆይ';

  @override
  String get onboardingThirdDescription =>
      'ለአንተ አስፈላጊ በሆኑ ርዕሰ ጉዳዮች ላይ የተመረጡ የዜና ዝመናዎችን ተቀበል። በዓለም ዙሪያህ ስላለው መረጃ እወቅ እና የተሻሉ ውሳኔዎችን አድርግ';

  @override
  String get nextButton => 'ቀጣይ';

  @override
  String get getStartedButton => 'ጀምር';

  @override
  String get forgotPasswordTitle => 'የይለፍ ቃል ረሳሁ?';

  @override
  String get emailResetPrompt => 'የይለፍ ቃል መመለሻ መመሪያዎችን ለመቀበል ኢሜልህን አስገባ';

  @override
  String get resetPasswordTitle => 'የይለፍ ቃል መመለስ';

  @override
  String get verificationCodePrompt => 'ወደ ኢሜልህ የተላከውን የማረጋገጊያ ኮድ አስገባ';

  @override
  String get emailEmptyError => 'እባክህ ኢሜልህን አስገባ';

  @override
  String get resetInstructionsSent => 'የመመለሻ መመሪያዎች ወደ ኢሜልህ ተልከዋል';

  @override
  String get resetEmailFailed => 'የመመለሻ ኢሜል መላክ አልተሳካም። እባክህ እንደገና ሞክር።';

  @override
  String get resetPasswordFailed => 'የይለፍ ቃል መመለስ አልተሳካም። እባክህ እንደገና ሞክር።';

  @override
  String get passwordResetSuccess => 'የይለፍ ቃልህ በተሳካ ሁኔታ ተመልሷል።';

  @override
  String get rememberPasswordLink => 'የይለፍ ቃልህን አስታወስክ? ግባ';

  @override
  String get verificationCodeHint => 'የማረጋገጊያ ኮድ';

  @override
  String get newPasswordHint => 'አዲስ የይለፍ ቃል';

  @override
  String get confirmNewPasswordHint => 'አዲስ የይለፍ ቃል አረጋግጥ';

  @override
  String get sendResetInstructionsButton => 'የመመለሻ መመሪያዎችን ላክ';

  @override
  String get resetPasswordButton => 'የይለፍ ቃል መልስ';

  @override
  String newsTitle(String category) {
    return '$category ዜና';
  }

  @override
  String get topCategory => 'ከፍተኛ';

  @override
  String get trendingCategory => 'ተወዳጅ';

  @override
  String get thousandAbbreviation => 'ሺ';

  @override
  String get noTitle => 'ርዕስ የለም';

  @override
  String get noDescription => 'መግለጫ የለም';

  @override
  String shareArticleMessage(String title, String url) {
    return 'ይህን ጽሁፍ ተመልከት፡ $title\n$url';
  }

  @override
  String get currentOnLabel => 'ወቅታዊ በ';

  @override
  String get viewAllLabel => 'ሁሉንም ተመልከት';

  @override
  String get trendingNewsTitle => 'ተወዳጅ ዜና';

  @override
  String get noTrendingNewsMessage => 'ምንም ተወዳጅ ዜና አይገኝም';

  @override
  String get failedToLoadNewsError => 'ዜና መጫን አልተሳካም። እባክህ እንደገና ሞክር።';

  @override
  String get businessCategory => 'ቢዝነስ';

  @override
  String get entertainmentCategory => 'መዝናኛ';

  @override
  String get generalCategory => 'አጠቃላይ';

  @override
  String get healthCategory => 'ጤና';

  @override
  String get scienceCategory => 'ሳይንስ';

  @override
  String get sportsCategory => 'ስፖርት';

  @override
  String get technologyCategory => 'ቴክኖሎጂ';

  @override
  String get commentsPageTitle => 'ሪፕላይቶች';

  @override
  String get noCommentsMessage => 'አሁን ምንም ሪፕላይ የለም';

  @override
  String get addCommentHint => 'ሪፕላይ ያክሉ...';

  @override
  String get writeReplyHint => 'መልስህን ጽፈት...';

  @override
  String get loginAgainMessage => 'እባክዎ ፈጥነው ደግሞ ግቡ';

  @override
  String get sessionExpiredMessage => 'የክፍያ ጊዜ አልፏል። እባክዎ እንደገና ግቡ።';

  @override
  String tokenRefreshError(String error) {
    return 'የቶክን መመልከቻ ስህተት፡ $error';
  }

  @override
  String get articleNotFoundMessage => 'ጽሁፍ በመዋቅር ውስጥ አልተገኘም';

  @override
  String fetchArticleIdError(String details) {
    return 'የጽሁፍ ID መገንጠጥ አልተሳካም፡ $details';
  }

  @override
  String fetchArticleIdException(String error) {
    return 'የጽሁፍ ID መገንጠጥ ስህት፡ $error';
  }

  @override
  String get invalidCommentDataMessage => 'የሪፕላይ ውሂብ መልኩ ያልተመደበ ነው';

  @override
  String loadCommentsError(String details) {
    return 'ሪፕላይቶችን መጫን አልተሳካም፡ $details';
  }

  @override
  String loadCommentsException(String error) {
    return 'ሪፕላይቶችን መጫን ስህት፡ $error';
  }

  @override
  String get postCommentNoIdMessage => 'ሪፕላይ ሊፈጸም አይችልም፡ ጽሁፍ ID አልተገኘም';

  @override
  String get emptyCommentMessage => 'ሪፕላይ መጽሐፍ ባዶ መሆን አይቻልም';

  @override
  String get commentPostedMessage => 'ሪፕላዩ በተሳካ ሁኔታ ተገኝቷል';

  @override
  String postCommentError(String details) {
    return 'ሪፕላዩን መቀመጥ አልተሳካም፡ $details';
  }

  @override
  String generalErrorMessage(String error) {
    return 'ስህተት፡ $error';
  }

  @override
  String replyingToLabel(String username) {
    return 'ለ @$username መልስ መስጠት';
  }

  @override
  String replyCountLabel(int count, int countIsOne) {
    String _temp0 = intl.Intl.pluralLogic(
      countIsOne,
      locale: localeName,
      other: 'ቶች',
      one: 'ት',
    );
    return '$count መልስ$_temp0';
  }

  @override
  String get searchNewsHint => 'ዜና ፈልግ';

  @override
  String originalQueryLabel(String query) {
    return 'ዋናው: $query';
  }

  @override
  String stemmedQueryLabel(String query) {
    return 'የተጣራ: $query';
  }

  @override
  String get noNewsOrMessagesFound => 'ምንም ዜና ወይም የቴሌግራም መልዕክቶች አልተገኙም';

  @override
  String totalArticlesLabel(int count) {
    return '$count አቃፊዎች ተገኝተዋል';
  }

  @override
  String totalTelegramMessagesLabel(int count) {
    return '$count የቴሌግራም መልዕክቶች ተገኝተዋል';
  }

  @override
  String get bookmarksTitle => 'መዝግቦች';

  @override
  String get noBookmarksMessage => 'ምንም መዝግቦች የሉም';

  @override
  String get errorLoadingBookmarks => 'መዝግቦችን ማስጫን አልተሳካም።';

  @override
  String get retryButton => 'ዳግም መሞከር';
}
