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
  String homeGreeting(String name) {
    return '$name님, 로그인되었습니다';
  }

  @override
  String get homeComingSoon => '여행 목록은 곧 추가됩니다.';

  @override
  String get logout => '로그아웃';
}
