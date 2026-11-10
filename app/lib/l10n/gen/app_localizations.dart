import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ko')];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'Travel Copilot'**
  String get appTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'AI와 함께 계획하고, 오프라인에서도 든든하게'**
  String get loginSubtitle;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get loginWithGoogle;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 못했습니다. 다시 시도해주세요.'**
  String get loginFailed;

  /// No description provided for @loginPrivacyNotice.
  ///
  /// In ko, this message translates to:
  /// **'계속하면 이용약관과 개인정보 처리방침에 동의하게 됩니다.'**
  String get loginPrivacyNotice;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @tripsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 여행'**
  String get tripsTitle;

  /// No description provided for @tripsUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 여행'**
  String get tripsUpcoming;

  /// No description provided for @tripsPast.
  ///
  /// In ko, this message translates to:
  /// **'지난 여행'**
  String get tripsPast;

  /// No description provided for @tripsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 여행이 없어요.\n첫 여행을 만들어보세요.'**
  String get tripsEmpty;

  /// No description provided for @tripsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'여행을 불러오지 못했습니다.'**
  String get tripsLoadFailed;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @tripCreate.
  ///
  /// In ko, this message translates to:
  /// **'여행 만들기'**
  String get tripCreate;

  /// No description provided for @tripEdit.
  ///
  /// In ko, this message translates to:
  /// **'여행 수정'**
  String get tripEdit;

  /// No description provided for @tripDelete.
  ///
  /// In ko, this message translates to:
  /// **'여행 삭제'**
  String get tripDelete;

  /// No description provided for @tripLeave.
  ///
  /// In ko, this message translates to:
  /// **'여행 나가기'**
  String get tripLeave;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @roleOwner.
  ///
  /// In ko, this message translates to:
  /// **'소유자'**
  String get roleOwner;

  /// No description provided for @roleEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집자'**
  String get roleEditor;

  /// No description provided for @roleViewer.
  ///
  /// In ko, this message translates to:
  /// **'보기 전용'**
  String get roleViewer;

  /// No description provided for @memberCount.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {count}명'**
  String memberCount(int count);

  /// No description provided for @fieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행 제목'**
  String get fieldTitle;

  /// No description provided for @fieldDestination.
  ///
  /// In ko, this message translates to:
  /// **'목적지'**
  String get fieldDestination;

  /// No description provided for @fieldPeriod.
  ///
  /// In ko, this message translates to:
  /// **'여행 기간'**
  String get fieldPeriod;

  /// No description provided for @fieldTimezone.
  ///
  /// In ko, this message translates to:
  /// **'여행지 시간대'**
  String get fieldTimezone;

  /// No description provided for @fieldPeriodHint.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 골라주세요'**
  String get fieldPeriodHint;

  /// No description provided for @fieldTimezoneHint.
  ///
  /// In ko, this message translates to:
  /// **'시간대를 골라주세요'**
  String get fieldTimezoneHint;

  /// No description provided for @timezoneSearch.
  ///
  /// In ko, this message translates to:
  /// **'도시나 지역 이름으로 검색 (예: Paris)'**
  String get timezoneSearch;

  /// No description provided for @errorRequired.
  ///
  /// In ko, this message translates to:
  /// **'입력해주세요'**
  String get errorRequired;

  /// No description provided for @errorTooLong.
  ///
  /// In ko, this message translates to:
  /// **'100자 이하로 입력해주세요'**
  String get errorTooLong;

  /// No description provided for @errorInvalidChars.
  ///
  /// In ko, this message translates to:
  /// **'줄바꿈 같은 특수 문자는 쓸 수 없어요'**
  String get errorInvalidChars;

  /// No description provided for @errorPeriodRequired.
  ///
  /// In ko, this message translates to:
  /// **'기간을 골라주세요'**
  String get errorPeriodRequired;

  /// No description provided for @errorPeriodTooLong.
  ///
  /// In ko, this message translates to:
  /// **'여행 기간은 최대 60일이에요'**
  String get errorPeriodTooLong;

  /// No description provided for @errorTimezoneRequired.
  ///
  /// In ko, this message translates to:
  /// **'시간대를 골라주세요'**
  String get errorTimezoneRequired;

  /// No description provided for @errorForbidden.
  ///
  /// In ko, this message translates to:
  /// **'권한이 없습니다.'**
  String get errorForbidden;

  /// No description provided for @errorTripGone.
  ///
  /// In ko, this message translates to:
  /// **'접근할 수 없는 여행입니다.'**
  String get errorTripGone;

  /// No description provided for @errorNotSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장되지 않았습니다. 연결을 확인하고 다시 시도해주세요.'**
  String get errorNotSaved;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'처리하지 못했습니다. 다시 시도해주세요.'**
  String get errorGeneric;

  /// No description provided for @conflictTitle.
  ///
  /// In ko, this message translates to:
  /// **'다른 멤버가 먼저 수정했습니다'**
  String get conflictTitle;

  /// No description provided for @conflictBody.
  ///
  /// In ko, this message translates to:
  /// **'지금 저장된 내용:\n{summary}\n\n내 수정을 다시 적용할까요?'**
  String conflictBody(String summary);

  /// No description provided for @conflictReapply.
  ///
  /// In ko, this message translates to:
  /// **'내 수정 다시 적용'**
  String get conflictReapply;

  /// No description provided for @tabItinerary.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get tabItinerary;

  /// No description provided for @tabVouchers.
  ///
  /// In ko, this message translates to:
  /// **'바우처'**
  String get tabVouchers;

  /// No description provided for @tabMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get tabMembers;

  /// No description provided for @itineraryComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'일정은 곧 추가됩니다.'**
  String get itineraryComingSoon;

  /// No description provided for @vouchersComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'바우처는 곧 추가됩니다.'**
  String get vouchersComingSoon;

  /// No description provided for @deleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행을 삭제할까요?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In ko, this message translates to:
  /// **'멤버 모두에게서 이 여행이 사라지고 되돌릴 수 없어요. 확인을 위해 여행 제목 \"{title}\"을 입력해주세요.'**
  String deleteBody(String title);

  /// No description provided for @leaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행에서 나갈까요?'**
  String get leaveTitle;

  /// No description provided for @leaveBody.
  ///
  /// In ko, this message translates to:
  /// **'다시 참여하려면 소유자에게 초대를 받아야 해요.'**
  String get leaveBody;

  /// No description provided for @me.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get me;

  /// No description provided for @joinedAt.
  ///
  /// In ko, this message translates to:
  /// **'{date} 참여'**
  String joinedAt(String date);

  /// No description provided for @memberMakeEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집자로 바꾸기'**
  String get memberMakeEditor;

  /// No description provided for @memberMakeViewer.
  ///
  /// In ko, this message translates to:
  /// **'보기 전용으로 바꾸기'**
  String get memberMakeViewer;

  /// No description provided for @memberTransfer.
  ///
  /// In ko, this message translates to:
  /// **'소유권 넘기기'**
  String get memberTransfer;

  /// No description provided for @memberRemove.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get memberRemove;

  /// No description provided for @transferTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 소유권을 넘길까요?'**
  String transferTitle(String name);

  /// No description provided for @transferBody.
  ///
  /// In ko, this message translates to:
  /// **'넘기면 나는 편집자가 되고, 여행 삭제와 멤버 관리는 {name}님만 할 수 있어요.'**
  String transferBody(String name);

  /// No description provided for @removeTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 내보낼까요?'**
  String removeTitle(String name);

  /// No description provided for @removeBody.
  ///
  /// In ko, this message translates to:
  /// **'이 멤버가 올린 바우처도 함께 삭제됩니다.'**
  String get removeBody;

  /// No description provided for @ownerMemberNotice.
  ///
  /// In ko, this message translates to:
  /// **'내보낸 멤버의 기기에 남아 있던 여행 정보는 그 기기가 다음에 동기화할 때 지워져요.'**
  String get ownerMemberNotice;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
