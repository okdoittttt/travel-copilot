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
  String get healthTitle => '서버 상태';

  @override
  String get healthChecking => '확인 중…';

  @override
  String get healthOk => '정상';

  @override
  String get healthFailed => '연결 실패';

  @override
  String get retry => '다시 시도';
}
