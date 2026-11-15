// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Invite {

 String get id; InviteRole get role; int get maxUses; int get useCount; DateTime get expiresAt; DateTime get createdAt; InviteStatus get status; DateTime? get revokedAt; String? get createdByName;
/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCopyWith<Invite> get copyWith => _$InviteCopyWithImpl<Invite>(this as Invite, _$identity);

  /// Serializes this Invite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Invite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invite&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.maxUses, _this.maxUses) || other.maxUses == _this.maxUses)&&(identical(other.useCount, _this.useCount) || other.useCount == _this.useCount)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.revokedAt, _this.revokedAt) || other.revokedAt == _this.revokedAt)&&(identical(other.createdByName, _this.createdByName) || other.createdByName == _this.createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Invite;
  return Object.hash(runtimeType,_this.id,_this.role,_this.maxUses,_this.useCount,_this.expiresAt,_this.createdAt,_this.status,_this.revokedAt,_this.createdByName);
}

@override
String toString() {
  final _this = this as Invite;
  return 'Invite(id: ${_this.id}, role: ${_this.role}, maxUses: ${_this.maxUses}, useCount: ${_this.useCount}, expiresAt: ${_this.expiresAt}, createdAt: ${_this.createdAt}, status: ${_this.status}, revokedAt: ${_this.revokedAt}, createdByName: ${_this.createdByName})';
}


}

/// @nodoc
abstract mixin class $InviteCopyWith<$Res>  {
  factory $InviteCopyWith(Invite value, $Res Function(Invite) _then) = _$InviteCopyWithImpl;
@useResult
$Res call({
 String id, InviteRole role, int maxUses, int useCount, DateTime expiresAt, DateTime createdAt, InviteStatus status, DateTime? revokedAt, String? createdByName
});




}
/// @nodoc
class _$InviteCopyWithImpl<$Res>
    implements $InviteCopyWith<$Res> {
  _$InviteCopyWithImpl(this._self, this._then);

  final Invite _self;
  final $Res Function(Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? role = null,Object? maxUses = null,Object? useCount = null,Object? expiresAt = null,Object? createdAt = null,Object? status = null,Object? revokedAt = freezed,Object? createdByName = freezed,}) {
  return _then(Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InviteRole,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invite].
extension InvitePatterns on Invite {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invite value)  $default,){
final _that = this;
switch (_that) {
case _Invite():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invite value)?  $default,){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  InviteRole role,  int maxUses,  int useCount,  DateTime expiresAt,  DateTime createdAt,  InviteStatus status,  DateTime? revokedAt,  String? createdByName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.role,_that.maxUses,_that.useCount,_that.expiresAt,_that.createdAt,_that.status,_that.revokedAt,_that.createdByName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  InviteRole role,  int maxUses,  int useCount,  DateTime expiresAt,  DateTime createdAt,  InviteStatus status,  DateTime? revokedAt,  String? createdByName)  $default,) {final _that = this;
switch (_that) {
case _Invite():
return $default(_that.id,_that.role,_that.maxUses,_that.useCount,_that.expiresAt,_that.createdAt,_that.status,_that.revokedAt,_that.createdByName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  InviteRole role,  int maxUses,  int useCount,  DateTime expiresAt,  DateTime createdAt,  InviteStatus status,  DateTime? revokedAt,  String? createdByName)?  $default,) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.role,_that.maxUses,_that.useCount,_that.expiresAt,_that.createdAt,_that.status,_that.revokedAt,_that.createdByName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Invite implements Invite {
  const _Invite({required this.id, required this.role, required this.maxUses, required this.useCount, required this.expiresAt, required this.createdAt, required this.status, this.revokedAt, this.createdByName});
  factory _Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

@override final  String id;
@override final  InviteRole role;
@override final  int maxUses;
@override final  int useCount;
@override final  DateTime expiresAt;
@override final  DateTime createdAt;
@override final  InviteStatus status;
@override final  DateTime? revokedAt;
@override final  String? createdByName;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCopyWith<_Invite> get copyWith => __$InviteCopyWithImpl<_Invite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invite&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,role,maxUses,useCount,expiresAt,createdAt,status,revokedAt,createdByName);
}

@override
String toString() {
    return 'Invite(id: $id, role: $role, maxUses: $maxUses, useCount: $useCount, expiresAt: $expiresAt, createdAt: $createdAt, status: $status, revokedAt: $revokedAt, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class _$InviteCopyWith<$Res> implements $InviteCopyWith<$Res> {
  factory _$InviteCopyWith(_Invite value, $Res Function(_Invite) _then) = __$InviteCopyWithImpl;
@override @useResult
$Res call({
 String id, InviteRole role, int maxUses, int useCount, DateTime expiresAt, DateTime createdAt, InviteStatus status, DateTime? revokedAt, String? createdByName
});




}
/// @nodoc
class __$InviteCopyWithImpl<$Res>
    implements _$InviteCopyWith<$Res> {
  __$InviteCopyWithImpl(this._self, this._then);

  final _Invite _self;
  final $Res Function(_Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? role = null,Object? maxUses = null,Object? useCount = null,Object? expiresAt = null,Object? createdAt = null,Object? status = null,Object? revokedAt = freezed,Object? createdByName = freezed,}) {
  return _then(_Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InviteRole,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InvitePreview {

 String get tripTitle;@DateOnlyConverter() DateTime get startDate;@DateOnlyConverter() DateTime get endDate; InviteRole get role; bool get alreadyMember; String? get inviterName; String? get tripId;
/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitePreviewCopyWith<InvitePreview> get copyWith => _$InvitePreviewCopyWithImpl<InvitePreview>(this as InvitePreview, _$identity);

  /// Serializes this InvitePreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvitePreview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitePreview&&(identical(other.tripTitle, _this.tripTitle) || other.tripTitle == _this.tripTitle)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.alreadyMember, _this.alreadyMember) || other.alreadyMember == _this.alreadyMember)&&(identical(other.inviterName, _this.inviterName) || other.inviterName == _this.inviterName)&&(identical(other.tripId, _this.tripId) || other.tripId == _this.tripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvitePreview;
  return Object.hash(runtimeType,_this.tripTitle,_this.startDate,_this.endDate,_this.role,_this.alreadyMember,_this.inviterName,_this.tripId);
}

@override
String toString() {
  final _this = this as InvitePreview;
  return 'InvitePreview(tripTitle: ${_this.tripTitle}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, role: ${_this.role}, alreadyMember: ${_this.alreadyMember}, inviterName: ${_this.inviterName}, tripId: ${_this.tripId})';
}


}

/// @nodoc
abstract mixin class $InvitePreviewCopyWith<$Res>  {
  factory $InvitePreviewCopyWith(InvitePreview value, $Res Function(InvitePreview) _then) = _$InvitePreviewCopyWithImpl;
@useResult
$Res call({
 String tripTitle,@DateOnlyConverter() DateTime startDate,@DateOnlyConverter() DateTime endDate, InviteRole role, bool alreadyMember, String? inviterName, String? tripId
});




}
/// @nodoc
class _$InvitePreviewCopyWithImpl<$Res>
    implements $InvitePreviewCopyWith<$Res> {
  _$InvitePreviewCopyWithImpl(this._self, this._then);

  final InvitePreview _self;
  final $Res Function(InvitePreview) _then;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripTitle = null,Object? startDate = null,Object? endDate = null,Object? role = null,Object? alreadyMember = null,Object? inviterName = freezed,Object? tripId = freezed,}) {
  return _then(InvitePreview(
tripTitle: null == tripTitle ? _self.tripTitle : tripTitle // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InviteRole,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,inviterName: freezed == inviterName ? _self.inviterName : inviterName // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitePreview].
extension InvitePreviewPatterns on InvitePreview {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitePreview value)  $default,){
final _that = this;
switch (_that) {
case _InvitePreview():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitePreview value)?  $default,){
final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tripTitle, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  InviteRole role,  bool alreadyMember,  String? inviterName,  String? tripId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that.tripTitle,_that.startDate,_that.endDate,_that.role,_that.alreadyMember,_that.inviterName,_that.tripId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tripTitle, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  InviteRole role,  bool alreadyMember,  String? inviterName,  String? tripId)  $default,) {final _that = this;
switch (_that) {
case _InvitePreview():
return $default(_that.tripTitle,_that.startDate,_that.endDate,_that.role,_that.alreadyMember,_that.inviterName,_that.tripId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tripTitle, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  InviteRole role,  bool alreadyMember,  String? inviterName,  String? tripId)?  $default,) {final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that.tripTitle,_that.startDate,_that.endDate,_that.role,_that.alreadyMember,_that.inviterName,_that.tripId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitePreview implements InvitePreview {
  const _InvitePreview({required this.tripTitle, @DateOnlyConverter() required this.startDate, @DateOnlyConverter() required this.endDate, required this.role, required this.alreadyMember, this.inviterName, this.tripId});
  factory _InvitePreview.fromJson(Map<String, dynamic> json) => _$InvitePreviewFromJson(json);

@override final  String tripTitle;
@override@DateOnlyConverter() final  DateTime startDate;
@override@DateOnlyConverter() final  DateTime endDate;
@override final  InviteRole role;
@override final  bool alreadyMember;
@override final  String? inviterName;
@override final  String? tripId;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitePreviewCopyWith<_InvitePreview> get copyWith => __$InvitePreviewCopyWithImpl<_InvitePreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitePreviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitePreview&&(identical(other.tripTitle, tripTitle) || other.tripTitle == tripTitle)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.role, role) || other.role == role)&&(identical(other.alreadyMember, alreadyMember) || other.alreadyMember == alreadyMember)&&(identical(other.inviterName, inviterName) || other.inviterName == inviterName)&&(identical(other.tripId, tripId) || other.tripId == tripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tripTitle,startDate,endDate,role,alreadyMember,inviterName,tripId);
}

@override
String toString() {
    return 'InvitePreview(tripTitle: $tripTitle, startDate: $startDate, endDate: $endDate, role: $role, alreadyMember: $alreadyMember, inviterName: $inviterName, tripId: $tripId)';
}


}

/// @nodoc
abstract mixin class _$InvitePreviewCopyWith<$Res> implements $InvitePreviewCopyWith<$Res> {
  factory _$InvitePreviewCopyWith(_InvitePreview value, $Res Function(_InvitePreview) _then) = __$InvitePreviewCopyWithImpl;
@override @useResult
$Res call({
 String tripTitle,@DateOnlyConverter() DateTime startDate,@DateOnlyConverter() DateTime endDate, InviteRole role, bool alreadyMember, String? inviterName, String? tripId
});




}
/// @nodoc
class __$InvitePreviewCopyWithImpl<$Res>
    implements _$InvitePreviewCopyWith<$Res> {
  __$InvitePreviewCopyWithImpl(this._self, this._then);

  final _InvitePreview _self;
  final $Res Function(_InvitePreview) _then;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripTitle = null,Object? startDate = null,Object? endDate = null,Object? role = null,Object? alreadyMember = null,Object? inviterName = freezed,Object? tripId = freezed,}) {
  return _then(_InvitePreview(
tripTitle: null == tripTitle ? _self.tripTitle : tripTitle // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InviteRole,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,inviterName: freezed == inviterName ? _self.inviterName : inviterName // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
