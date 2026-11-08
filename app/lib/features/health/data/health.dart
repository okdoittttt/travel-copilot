import 'package:freezed_annotation/freezed_annotation.dart';

part 'health.freezed.dart';
part 'health.g.dart';

/// 서버 `/health` 응답.
@freezed
abstract class Health with _$Health {
  const factory({required String status}) = _Health;

  factory fromJson(Map<String, dynamic> json) => _$HealthFromJson(json);
}
