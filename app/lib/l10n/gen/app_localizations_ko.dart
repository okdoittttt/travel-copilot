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
  String get itineraryComingSoon => '일정은 곧 추가됩니다.';

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
}
