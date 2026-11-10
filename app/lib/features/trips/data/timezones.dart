import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

List<String>? _cache;

/// 고를 수 있는 IANA 시간대 이름 (예: `Europe/Paris`), 이름 순.
///
/// `Etc/GMT+9`처럼 부호가 반대로 읽혀 헷갈리는 이름과 지역이 없는 이름은 뺀다.
List<String> availableTimezones() {
  if (_cache != null) return _cache!;
  tz_data.initializeTimeZones();
  _cache =
      tz.timeZoneDatabase.locations.keys
          .where((name) => name.contains('/') && !name.startsWith('Etc/'))
          .toList()
        ..sort();
  return _cache!;
}
