// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Travel Copilot';

  @override
  String get loginSubtitle => 'AI와 함께 계획하고, 오프라인에서도 든든하게';

  @override
  String get loginWithGoogle => 'Google로 계속하기';

  @override
  String get loginFailed => '로그인하지 못했습니다. 다시 시도해주세요.';

  @override
  String get loginPrivacyNotice => '계속하면 이용약관과 개인정보 처리방침에 동의하게 됩니다.';

  @override
  String get logout => '로그아웃';

  @override
  String get tripsTitle => '내 여행';

  @override
  String get tripsUpcoming => '다가오는 여행';

  @override
  String get tripsPast => '지난 여행';

  @override
  String get tripsEmpty => '아직 여행이 없어요.\n첫 여행을 만들어보세요.';

  @override
  String get tripsLoadFailed => '여행을 불러오지 못했습니다.';

  @override
  String get retry => '다시 시도';

  @override
  String get tripCreate => '여행 만들기';

  @override
  String get tripEdit => '여행 수정';

  @override
  String get tripDelete => '여행 삭제';

  @override
  String get tripLeave => '여행 나가기';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get roleOwner => '소유자';

  @override
  String get roleEditor => '편집자';

  @override
  String get roleViewer => '보기 전용';

  @override
  String memberCount(int count) {
    return '멤버 $count명';
  }

  @override
  String get fieldTitle => '여행 제목';

  @override
  String get fieldDestination => '목적지';

  @override
  String get fieldPeriod => '여행 기간';

  @override
  String get fieldTimezone => '여행지 시간대';

  @override
  String get fieldPeriodHint => '날짜를 골라주세요';

  @override
  String get fieldTimezoneHint => '시간대를 골라주세요';

  @override
  String get timezoneSearch => '도시나 지역 이름으로 검색 (예: Paris)';

  @override
  String get errorRequired => '입력해주세요';

  @override
  String get errorTooLong => '100자 이하로 입력해주세요';

  @override
  String get errorInvalidChars => '줄바꿈 같은 특수 문자는 쓸 수 없어요';

  @override
  String get errorPeriodRequired => '기간을 골라주세요';

  @override
  String get errorPeriodTooLong => '여행 기간은 최대 60일이에요';

  @override
  String get errorTimezoneRequired => '시간대를 골라주세요';

  @override
  String get errorForbidden => '권한이 없습니다.';

  @override
  String get errorTripGone => '접근할 수 없는 여행입니다.';

  @override
  String get errorNotSaved => '저장되지 않았습니다. 연결을 확인하고 다시 시도해주세요.';

  @override
  String get errorGeneric => '처리하지 못했습니다. 다시 시도해주세요.';

  @override
  String get conflictTitle => '다른 멤버가 먼저 수정했습니다';

  @override
  String conflictBody(String summary) {
    return '지금 저장된 내용:\n$summary\n\n내 수정을 다시 적용할까요?';
  }

  @override
  String get conflictReapply => '내 수정 다시 적용';

  @override
  String get tabItinerary => '일정';

  @override
  String get tabVouchers => '바우처';

  @override
  String get tabMembers => '멤버';

  @override
  String get vouchersComingSoon => '바우처는 곧 추가됩니다.';

  @override
  String get deleteTitle => '여행을 삭제할까요?';

  @override
  String deleteBody(String title) {
    return '멤버 모두에게서 이 여행이 사라지고 되돌릴 수 없어요. 확인을 위해 여행 제목 \"$title\"을 입력해주세요.';
  }

  @override
  String get leaveTitle => '여행에서 나갈까요?';

  @override
  String get leaveBody => '다시 참여하려면 소유자에게 초대를 받아야 해요.';

  @override
  String get me => '나';

  @override
  String joinedAt(String date) {
    return '$date 참여';
  }

  @override
  String get memberMakeEditor => '편집자로 바꾸기';

  @override
  String get memberMakeViewer => '보기 전용으로 바꾸기';

  @override
  String get memberTransfer => '소유권 넘기기';

  @override
  String get memberRemove => '내보내기';

  @override
  String transferTitle(String name) {
    return '$name님에게 소유권을 넘길까요?';
  }

  @override
  String transferBody(String name) {
    return '넘기면 나는 편집자가 되고, 여행 삭제와 멤버 관리는 $name님만 할 수 있어요.';
  }

  @override
  String removeTitle(String name) {
    return '$name님을 내보낼까요?';
  }

  @override
  String get removeBody => '이 멤버가 올린 바우처도 함께 삭제됩니다.';

  @override
  String get ownerMemberNotice => '내보낸 멤버의 기기에 남아 있던 여행 정보는 그 기기가 다음에 동기화할 때 지워져요.';

  @override
  String get itineraryEmpty => '이 날은 아직 일정이 없어요.';

  @override
  String get itineraryAdd => '일정 추가';

  @override
  String get itemNew => '일정 추가';

  @override
  String get itemEdit => '일정 수정';

  @override
  String get itemView => '일정';

  @override
  String get fieldItemTitle => '제목';

  @override
  String get fieldPlace => '장소';

  @override
  String get fieldPlaceHint => '장소 선택 (선택)';

  @override
  String get fieldDay => '날짜';

  @override
  String get fieldStartTime => '시작 시각';

  @override
  String get fieldStay => '머무는 시간';

  @override
  String get fieldTravelMode => '이전 일정에서 이동';

  @override
  String get fieldMemo => '메모';

  @override
  String get none => '없음';

  @override
  String get placeRemove => '장소 빼기';

  @override
  String googleNameHint(String name) {
    return 'Google 장소 이름: $name';
  }

  @override
  String get useThisName => '이 이름 사용';

  @override
  String get travelDrive => '차량';

  @override
  String get travelTransit => '대중교통';

  @override
  String get travelWalk => '도보';

  @override
  String get errorMemoTooLong => '1,000자 이하로 입력해주세요';

  @override
  String get itemDeleteTitle => '일정을 삭제할까요?';

  @override
  String itemDeleteBody(String title) {
    return '\"$title\" 일정이 삭제됩니다.';
  }

  @override
  String get delete => '삭제';

  @override
  String get placeSearchTitle => '장소 검색';

  @override
  String get placeSearchHint => '장소 이름이나 주소 (2글자 이상)';

  @override
  String get placeSearchEmpty => '검색 결과가 없어요.';

  @override
  String get placesUnavailable => '장소 검색을 사용할 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get rateLimited => '잠시 후 다시 시도해주세요.';

  @override
  String get placeOpenInMaps => 'Google 지도에서 열기';

  @override
  String get placeLoadFailed => '장소 정보를 불러오지 못했습니다.';

  @override
  String get itineraryChanged => '일정이 바뀌어 새로 불러왔습니다.';

  @override
  String get viewList => '목록';

  @override
  String get viewMap => '지도';

  @override
  String get legNoMode => '이동수단을 선택하세요';

  @override
  String get legNoLocation => '장소 없음';

  @override
  String get legUnavailable => '이동시간을 알 수 없어요';

  @override
  String legLate(int minutes) {
    return '$minutes분 늦음';
  }

  @override
  String get legsLoadFailed => '이동시간을 불러오지 못했습니다.';

  @override
  String get mapUnavailable => '지도를 사용할 수 없습니다.';

  @override
  String get mapNoPlaces => '지도에 표시할 장소가 없어요.';

  @override
  String get invitesTitle => '초대 링크';

  @override
  String get inviteNew => '새 링크';

  @override
  String get inviteCreate => '만들기';

  @override
  String get inviteRole => '역할';

  @override
  String get inviteMaxUses => '사용 횟수';

  @override
  String get inviteExpires => '유효 기간';

  @override
  String inviteUsesValue(int count) {
    return '$count회';
  }

  @override
  String inviteDaysValue(int count) {
    return '$count일';
  }

  @override
  String get inviteEditorWarning => '링크를 받은 누구나 일정을 수정할 수 있습니다.';

  @override
  String get inviteShareNotice => '링크는 만들 때 한 번만 볼 수 있어요. 링크를 받은 사람은 참여하기 전에도 여행 제목과 날짜를 볼 수 있습니다.';

  @override
  String inviteShareText(String url) {
    return 'Travel Copilot 여행에 초대합니다.\n$url';
  }

  @override
  String get invitesEmpty => '만든 초대 링크가 없어요.';

  @override
  String inviteUsage(int used, int max) {
    return '$used/$max회 사용';
  }

  @override
  String inviteExpiresAt(String date) {
    return '$date까지';
  }

  @override
  String get inviteStatusActive => '사용 중';

  @override
  String get inviteStatusExpired => '만료됨';

  @override
  String get inviteStatusRevoked => '폐기됨';

  @override
  String get inviteStatusExhausted => '모두 사용됨';

  @override
  String get inviteRevoke => '폐기';

  @override
  String get inviteRevokeTitle => '이 링크를 폐기할까요?';

  @override
  String get inviteRevokeBody => '폐기하면 이 링크로 더 이상 참여할 수 없습니다.';

  @override
  String get inviteShared => '링크를 만들었어요. 지금 공유하지 않으면 다시 볼 수 없습니다.';

  @override
  String get inviteJoinTitle => '초대 참여';

  @override
  String inviteJoinBody(String inviter, String title, String period, String role) {
    return '$inviter님이 \'$title\'($period)에 $role 멤버로 초대했습니다.';
  }

  @override
  String inviteJoinBodyNoInviter(String title, String period, String role) {
    return '\'$title\'($period)에 $role 멤버로 초대받았습니다.';
  }

  @override
  String get inviteJoin => '참여';

  @override
  String get inviteGone => '더 이상 쓸 수 없는 초대 링크입니다. 초대한 사람에게 새 링크를 요청하세요.';

  @override
  String get inviteNotFound => '초대 링크를 찾을 수 없습니다. 링크를 다시 확인해주세요.';

  @override
  String get inviteMemberLimit => '이 여행은 멤버가 가득 찼습니다.';

  @override
  String get inviteLoadFailed => '초대 정보를 불러오지 못했습니다.';

  @override
  String get inviteJoinByLink => '초대 링크로 참여';

  @override
  String get invitePasteHint => '받은 초대 링크를 붙여넣으세요';

  @override
  String get inviteLinkInvalid => '초대 링크 형식이 아닙니다.';

  @override
  String get inviteNext => '다음';

  @override
  String removeRevokeInvites(int count) {
    return '열린 초대 링크도 모두 폐기 ($count개)';
  }

  @override
  String get errorNetwork => '연결을 확인하고 다시 시도해주세요.';

  @override
  String get offlineBanner => '오프라인';

  @override
  String offlineBannerSynced(String ago) {
    return '오프라인 · 마지막 동기화: $ago';
  }

  @override
  String get agoJustNow => '방금';

  @override
  String agoMinutes(int count) {
    return '$count분 전';
  }

  @override
  String agoHours(int count) {
    return '$count시간 전';
  }

  @override
  String agoDays(int count) {
    return '$count일 전';
  }

  @override
  String get offlineEditBlocked => '연결 후 수정할 수 있습니다.';

  @override
  String get legsOffline => '오프라인 — 이동시간은 연결 후 표시됩니다.';

  @override
  String get mapOffline => '지도는 연결 후 볼 수 있습니다.';

  @override
  String get placeOffline => '장소 정보는 연결 후 볼 수 있습니다.';
}
