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

  /// No description provided for @itineraryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 날은 아직 일정이 없어요.'**
  String get itineraryEmpty;

  /// No description provided for @itineraryAdd.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get itineraryAdd;

  /// No description provided for @itemNew.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get itemNew;

  /// No description provided for @itemEdit.
  ///
  /// In ko, this message translates to:
  /// **'일정 수정'**
  String get itemEdit;

  /// No description provided for @itemView.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get itemView;

  /// No description provided for @fieldItemTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get fieldItemTitle;

  /// No description provided for @fieldPlace.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get fieldPlace;

  /// No description provided for @fieldPlaceHint.
  ///
  /// In ko, this message translates to:
  /// **'장소 선택 (선택)'**
  String get fieldPlaceHint;

  /// No description provided for @fieldDay.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get fieldDay;

  /// No description provided for @fieldStartTime.
  ///
  /// In ko, this message translates to:
  /// **'시작 시각'**
  String get fieldStartTime;

  /// No description provided for @fieldStay.
  ///
  /// In ko, this message translates to:
  /// **'머무는 시간'**
  String get fieldStay;

  /// No description provided for @fieldTravelMode.
  ///
  /// In ko, this message translates to:
  /// **'이전 일정에서 이동'**
  String get fieldTravelMode;

  /// No description provided for @fieldMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get fieldMemo;

  /// No description provided for @none.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get none;

  /// No description provided for @placeRemove.
  ///
  /// In ko, this message translates to:
  /// **'장소 빼기'**
  String get placeRemove;

  /// No description provided for @googleNameHint.
  ///
  /// In ko, this message translates to:
  /// **'Google 장소 이름: {name}'**
  String googleNameHint(String name);

  /// No description provided for @useThisName.
  ///
  /// In ko, this message translates to:
  /// **'이 이름 사용'**
  String get useThisName;

  /// No description provided for @travelDrive.
  ///
  /// In ko, this message translates to:
  /// **'차량'**
  String get travelDrive;

  /// No description provided for @travelTransit.
  ///
  /// In ko, this message translates to:
  /// **'대중교통'**
  String get travelTransit;

  /// No description provided for @travelWalk.
  ///
  /// In ko, this message translates to:
  /// **'도보'**
  String get travelWalk;

  /// No description provided for @errorMemoTooLong.
  ///
  /// In ko, this message translates to:
  /// **'1,000자 이하로 입력해주세요'**
  String get errorMemoTooLong;

  /// No description provided for @itemDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'일정을 삭제할까요?'**
  String get itemDeleteTitle;

  /// No description provided for @itemDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 일정이 삭제됩니다.'**
  String itemDeleteBody(String title);

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @placeSearchTitle.
  ///
  /// In ko, this message translates to:
  /// **'장소 검색'**
  String get placeSearchTitle;

  /// No description provided for @placeSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'장소 이름이나 주소 (2글자 이상)'**
  String get placeSearchHint;

  /// No description provided for @placeSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요.'**
  String get placeSearchEmpty;

  /// No description provided for @placesUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'장소 검색을 사용할 수 없습니다. 잠시 후 다시 시도해주세요.'**
  String get placesUnavailable;

  /// No description provided for @rateLimited.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해주세요.'**
  String get rateLimited;

  /// No description provided for @placeOpenInMaps.
  ///
  /// In ko, this message translates to:
  /// **'Google 지도에서 열기'**
  String get placeOpenInMaps;

  /// No description provided for @placeLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'장소 정보를 불러오지 못했습니다.'**
  String get placeLoadFailed;

  /// No description provided for @itineraryChanged.
  ///
  /// In ko, this message translates to:
  /// **'일정이 바뀌어 새로 불러왔습니다.'**
  String get itineraryChanged;

  /// No description provided for @viewList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get viewList;

  /// No description provided for @viewMap.
  ///
  /// In ko, this message translates to:
  /// **'지도'**
  String get viewMap;

  /// No description provided for @legNoMode.
  ///
  /// In ko, this message translates to:
  /// **'이동수단을 선택하세요'**
  String get legNoMode;

  /// No description provided for @legNoLocation.
  ///
  /// In ko, this message translates to:
  /// **'장소 없음'**
  String get legNoLocation;

  /// No description provided for @legUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이동시간을 알 수 없어요'**
  String get legUnavailable;

  /// No description provided for @legLate.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 늦음'**
  String legLate(int minutes);

  /// No description provided for @legsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'이동시간을 불러오지 못했습니다.'**
  String get legsLoadFailed;

  /// No description provided for @mapUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'지도를 사용할 수 없습니다.'**
  String get mapUnavailable;

  /// No description provided for @mapNoPlaces.
  ///
  /// In ko, this message translates to:
  /// **'지도에 표시할 장소가 없어요.'**
  String get mapNoPlaces;

  /// No description provided for @invitesTitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크'**
  String get invitesTitle;

  /// No description provided for @inviteNew.
  ///
  /// In ko, this message translates to:
  /// **'새 링크'**
  String get inviteNew;

  /// No description provided for @inviteCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get inviteCreate;

  /// No description provided for @inviteRole.
  ///
  /// In ko, this message translates to:
  /// **'역할'**
  String get inviteRole;

  /// No description provided for @inviteMaxUses.
  ///
  /// In ko, this message translates to:
  /// **'사용 횟수'**
  String get inviteMaxUses;

  /// No description provided for @inviteExpires.
  ///
  /// In ko, this message translates to:
  /// **'유효 기간'**
  String get inviteExpires;

  /// No description provided for @inviteUsesValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String inviteUsesValue(int count);

  /// No description provided for @inviteDaysValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String inviteDaysValue(int count);

  /// No description provided for @inviteEditorWarning.
  ///
  /// In ko, this message translates to:
  /// **'링크를 받은 누구나 일정을 수정할 수 있습니다.'**
  String get inviteEditorWarning;

  /// No description provided for @inviteShareNotice.
  ///
  /// In ko, this message translates to:
  /// **'링크는 만들 때 한 번만 볼 수 있어요. 링크를 받은 사람은 참여하기 전에도 여행 제목과 날짜를 볼 수 있습니다.'**
  String get inviteShareNotice;

  /// No description provided for @inviteShareText.
  ///
  /// In ko, this message translates to:
  /// **'Travel Copilot 여행에 초대합니다.\n{url}'**
  String inviteShareText(String url);

  /// No description provided for @invitesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'만든 초대 링크가 없어요.'**
  String get invitesEmpty;

  /// No description provided for @inviteUsage.
  ///
  /// In ko, this message translates to:
  /// **'{used}/{max}회 사용'**
  String inviteUsage(int used, int max);

  /// No description provided for @inviteExpiresAt.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지'**
  String inviteExpiresAt(String date);

  /// No description provided for @inviteStatusActive.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get inviteStatusActive;

  /// No description provided for @inviteStatusExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료됨'**
  String get inviteStatusExpired;

  /// No description provided for @inviteStatusRevoked.
  ///
  /// In ko, this message translates to:
  /// **'폐기됨'**
  String get inviteStatusRevoked;

  /// No description provided for @inviteStatusExhausted.
  ///
  /// In ko, this message translates to:
  /// **'모두 사용됨'**
  String get inviteStatusExhausted;

  /// No description provided for @inviteRevoke.
  ///
  /// In ko, this message translates to:
  /// **'폐기'**
  String get inviteRevoke;

  /// No description provided for @inviteRevokeTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 링크를 폐기할까요?'**
  String get inviteRevokeTitle;

  /// No description provided for @inviteRevokeBody.
  ///
  /// In ko, this message translates to:
  /// **'폐기하면 이 링크로 더 이상 참여할 수 없습니다.'**
  String get inviteRevokeBody;

  /// No description provided for @inviteShared.
  ///
  /// In ko, this message translates to:
  /// **'링크를 만들었어요. 지금 공유하지 않으면 다시 볼 수 없습니다.'**
  String get inviteShared;

  /// No description provided for @inviteJoinTitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 참여'**
  String get inviteJoinTitle;

  /// No description provided for @inviteJoinBody.
  ///
  /// In ko, this message translates to:
  /// **'{inviter}님이 \'{title}\'({period})에 {role} 멤버로 초대했습니다.'**
  String inviteJoinBody(String inviter, String title, String period, String role);

  /// No description provided for @inviteJoinBodyNoInviter.
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\'({period})에 {role} 멤버로 초대받았습니다.'**
  String inviteJoinBodyNoInviter(String title, String period, String role);

  /// No description provided for @inviteJoin.
  ///
  /// In ko, this message translates to:
  /// **'참여'**
  String get inviteJoin;

  /// No description provided for @inviteGone.
  ///
  /// In ko, this message translates to:
  /// **'더 이상 쓸 수 없는 초대 링크입니다. 초대한 사람에게 새 링크를 요청하세요.'**
  String get inviteGone;

  /// No description provided for @inviteNotFound.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크를 찾을 수 없습니다. 링크를 다시 확인해주세요.'**
  String get inviteNotFound;

  /// No description provided for @inviteMemberLimit.
  ///
  /// In ko, this message translates to:
  /// **'이 여행은 멤버가 가득 찼습니다.'**
  String get inviteMemberLimit;

  /// No description provided for @inviteLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'초대 정보를 불러오지 못했습니다.'**
  String get inviteLoadFailed;

  /// No description provided for @inviteJoinByLink.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크로 참여'**
  String get inviteJoinByLink;

  /// No description provided for @invitePasteHint.
  ///
  /// In ko, this message translates to:
  /// **'받은 초대 링크를 붙여넣으세요'**
  String get invitePasteHint;

  /// No description provided for @inviteLinkInvalid.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크 형식이 아닙니다.'**
  String get inviteLinkInvalid;

  /// No description provided for @inviteNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get inviteNext;

  /// No description provided for @removeRevokeInvites.
  ///
  /// In ko, this message translates to:
  /// **'열린 초대 링크도 모두 폐기 ({count}개)'**
  String removeRevokeInvites(int count);

  /// No description provided for @errorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'연결을 확인하고 다시 시도해주세요.'**
  String get errorNetwork;

  /// No description provided for @offlineBanner.
  ///
  /// In ko, this message translates to:
  /// **'오프라인'**
  String get offlineBanner;

  /// No description provided for @offlineBannerSynced.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 · 마지막 동기화: {ago}'**
  String offlineBannerSynced(String ago);

  /// No description provided for @agoJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get agoJustNow;

  /// No description provided for @agoMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String agoDays(int count);

  /// No description provided for @offlineEditBlocked.
  ///
  /// In ko, this message translates to:
  /// **'연결 후 수정할 수 있습니다.'**
  String get offlineEditBlocked;

  /// No description provided for @legsOffline.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 — 이동시간은 연결 후 표시됩니다.'**
  String get legsOffline;

  /// No description provided for @mapOffline.
  ///
  /// In ko, this message translates to:
  /// **'지도는 연결 후 볼 수 있습니다.'**
  String get mapOffline;

  /// No description provided for @placeOffline.
  ///
  /// In ko, this message translates to:
  /// **'장소 정보는 연결 후 볼 수 있습니다.'**
  String get placeOffline;
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
