// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Trip {

 String get id; String get title; String get destination;@DateOnlyConverter() DateTime get startDate;@DateOnlyConverter() DateTime get endDate; String get timezone; int get version; TripRole get myRole; int get memberCount; DateTime get updatedAt;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Trip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.destination, _this.destination) || other.destination == _this.destination)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Trip;
  return Object.hash(runtimeType,_this.id,_this.title,_this.destination,_this.startDate,_this.endDate,_this.timezone,_this.version,_this.myRole,_this.memberCount,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Trip;
  return 'Trip(id: ${_this.id}, title: ${_this.title}, destination: ${_this.destination}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, timezone: ${_this.timezone}, version: ${_this.version}, myRole: ${_this.myRole}, memberCount: ${_this.memberCount}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, String title, String destination,@DateOnlyConverter() DateTime startDate,@DateOnlyConverter() DateTime endDate, String timezone, int version, TripRole myRole, int memberCount, DateTime updatedAt
});




}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? destination = null,Object? startDate = null,Object? endDate = null,Object? timezone = null,Object? version = null,Object? myRole = null,Object? memberCount = null,Object? updatedAt = null,}) {
  return _then(Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as TripRole,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String destination, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  String timezone,  int version,  TripRole myRole,  int memberCount,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.title,_that.destination,_that.startDate,_that.endDate,_that.timezone,_that.version,_that.myRole,_that.memberCount,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String destination, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  String timezone,  int version,  TripRole myRole,  int memberCount,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.title,_that.destination,_that.startDate,_that.endDate,_that.timezone,_that.version,_that.myRole,_that.memberCount,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String destination, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  String timezone,  int version,  TripRole myRole,  int memberCount,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.title,_that.destination,_that.startDate,_that.endDate,_that.timezone,_that.version,_that.myRole,_that.memberCount,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip extends Trip {
  const _Trip({required this.id, required this.title, required this.destination, @DateOnlyConverter() required this.startDate, @DateOnlyConverter() required this.endDate, required this.timezone, required this.version, required this.myRole, required this.memberCount, required this.updatedAt}): super._();
  factory _Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

@override final  String id;
@override final  String title;
@override final  String destination;
@override@DateOnlyConverter() final  DateTime startDate;
@override@DateOnlyConverter() final  DateTime endDate;
@override final  String timezone;
@override final  int version;
@override final  TripRole myRole;
@override final  int memberCount;
@override final  DateTime updatedAt;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.version, version) || other.version == version)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,destination,startDate,endDate,timezone,version,myRole,memberCount,updatedAt);
}

@override
String toString() {
    return 'Trip(id: $id, title: $title, destination: $destination, startDate: $startDate, endDate: $endDate, timezone: $timezone, version: $version, myRole: $myRole, memberCount: $memberCount, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String destination,@DateOnlyConverter() DateTime startDate,@DateOnlyConverter() DateTime endDate, String timezone, int version, TripRole myRole, int memberCount, DateTime updatedAt
});




}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? destination = null,Object? startDate = null,Object? endDate = null,Object? timezone = null,Object? version = null,Object? myRole = null,Object? memberCount = null,Object? updatedAt = null,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as TripRole,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$TripMember {

 String get userId; String get displayName; TripRole get role; DateTime get joinedAt;
/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripMemberCopyWith<TripMember> get copyWith => _$TripMemberCopyWithImpl<TripMember>(this as TripMember, _$identity);

  /// Serializes this TripMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TripMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripMember&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TripMember;
  return Object.hash(runtimeType,_this.userId,_this.displayName,_this.role,_this.joinedAt);
}

@override
String toString() {
  final _this = this as TripMember;
  return 'TripMember(userId: ${_this.userId}, displayName: ${_this.displayName}, role: ${_this.role}, joinedAt: ${_this.joinedAt})';
}


}

/// @nodoc
abstract mixin class $TripMemberCopyWith<$Res>  {
  factory $TripMemberCopyWith(TripMember value, $Res Function(TripMember) _then) = _$TripMemberCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, TripRole role, DateTime joinedAt
});




}
/// @nodoc
class _$TripMemberCopyWithImpl<$Res>
    implements $TripMemberCopyWith<$Res> {
  _$TripMemberCopyWithImpl(this._self, this._then);

  final TripMember _self;
  final $Res Function(TripMember) _then;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(TripMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TripRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TripMember].
extension TripMemberPatterns on TripMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripMember value)  $default,){
final _that = this;
switch (_that) {
case _TripMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripMember value)?  $default,){
final _that = this;
switch (_that) {
case _TripMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  TripRole role,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  TripRole role,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _TripMember():
return $default(_that.userId,_that.displayName,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  TripRole role,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripMember implements TripMember {
  const _TripMember({required this.userId, required this.displayName, required this.role, required this.joinedAt});
  factory _TripMember.fromJson(Map<String, dynamic> json) => _$TripMemberFromJson(json);

@override final  String userId;
@override final  String displayName;
@override final  TripRole role;
@override final  DateTime joinedAt;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripMemberCopyWith<_TripMember> get copyWith => __$TripMemberCopyWithImpl<_TripMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripMemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,displayName,role,joinedAt);
}

@override
String toString() {
    return 'TripMember(userId: $userId, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$TripMemberCopyWith<$Res> implements $TripMemberCopyWith<$Res> {
  factory _$TripMemberCopyWith(_TripMember value, $Res Function(_TripMember) _then) = __$TripMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, TripRole role, DateTime joinedAt
});




}
/// @nodoc
class __$TripMemberCopyWithImpl<$Res>
    implements _$TripMemberCopyWith<$Res> {
  __$TripMemberCopyWithImpl(this._self, this._then);

  final _TripMember _self;
  final $Res Function(_TripMember) _then;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(_TripMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TripRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$TripSnapshot {

 Trip get trip; List<TripMember> get members;
/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripSnapshotCopyWith<TripSnapshot> get copyWith => _$TripSnapshotCopyWithImpl<TripSnapshot>(this as TripSnapshot, _$identity);

  /// Serializes this TripSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TripSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripSnapshot&&(identical(other.trip, _this.trip) || other.trip == _this.trip)&&const DeepCollectionEquality().equals(other.members, _this.members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TripSnapshot;
  return Object.hash(runtimeType,_this.trip,const DeepCollectionEquality().hash(_this.members));
}

@override
String toString() {
  final _this = this as TripSnapshot;
  return 'TripSnapshot(trip: ${_this.trip}, members: ${_this.members})';
}


}

/// @nodoc
abstract mixin class $TripSnapshotCopyWith<$Res>  {
  factory $TripSnapshotCopyWith(TripSnapshot value, $Res Function(TripSnapshot) _then) = _$TripSnapshotCopyWithImpl;
@useResult
$Res call({
 Trip trip, List<TripMember> members
});


$TripCopyWith<$Res> get trip;

}
/// @nodoc
class _$TripSnapshotCopyWithImpl<$Res>
    implements $TripSnapshotCopyWith<$Res> {
  _$TripSnapshotCopyWithImpl(this._self, this._then);

  final TripSnapshot _self;
  final $Res Function(TripSnapshot) _then;

/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trip = null,Object? members = null,}) {
  return _then(TripSnapshot(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<TripMember>,
  ));
}
/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res> get trip {
  
  return $TripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripSnapshot].
extension TripSnapshotPatterns on TripSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _TripSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Trip trip,  List<TripMember> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
return $default(_that.trip,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Trip trip,  List<TripMember> members)  $default,) {final _that = this;
switch (_that) {
case _TripSnapshot():
return $default(_that.trip,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Trip trip,  List<TripMember> members)?  $default,) {final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
return $default(_that.trip,_that.members);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripSnapshot implements TripSnapshot {
  const _TripSnapshot({required this.trip, required  List<TripMember> members}): _members = members;
  factory _TripSnapshot.fromJson(Map<String, dynamic> json) => _$TripSnapshotFromJson(json);

@override final  Trip trip;
 final  List<TripMember> _members;
@override List<TripMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripSnapshotCopyWith<_TripSnapshot> get copyWith => __$TripSnapshotCopyWithImpl<_TripSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripSnapshot&&(identical(other.trip, trip) || other.trip == trip)&&const DeepCollectionEquality().equals(other.members, _members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,trip,const DeepCollectionEquality().hash(_members));
}

@override
String toString() {
    return 'TripSnapshot(trip: $trip, members: $members)';
}


}

/// @nodoc
abstract mixin class _$TripSnapshotCopyWith<$Res> implements $TripSnapshotCopyWith<$Res> {
  factory _$TripSnapshotCopyWith(_TripSnapshot value, $Res Function(_TripSnapshot) _then) = __$TripSnapshotCopyWithImpl;
@override @useResult
$Res call({
 Trip trip, List<TripMember> members
});


@override $TripCopyWith<$Res> get trip;

}
/// @nodoc
class __$TripSnapshotCopyWithImpl<$Res>
    implements _$TripSnapshotCopyWith<$Res> {
  __$TripSnapshotCopyWithImpl(this._self, this._then);

  final _TripSnapshot _self;
  final $Res Function(_TripSnapshot) _then;

/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trip = null,Object? members = null,}) {
  return _then(_TripSnapshot(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<TripMember>,
  ));
}

/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res> get trip {
  
  return $TripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}


/// @nodoc
mixin _$TripDraft {

 String get title; String get destination;@DateOnlyConverter() DateTime get startDate;@DateOnlyConverter() DateTime get endDate; String get timezone;
/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripDraftCopyWith<TripDraft> get copyWith => _$TripDraftCopyWithImpl<TripDraft>(this as TripDraft, _$identity);

  /// Serializes this TripDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TripDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripDraft&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.destination, _this.destination) || other.destination == _this.destination)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TripDraft;
  return Object.hash(runtimeType,_this.title,_this.destination,_this.startDate,_this.endDate,_this.timezone);
}

@override
String toString() {
  final _this = this as TripDraft;
  return 'TripDraft(title: ${_this.title}, destination: ${_this.destination}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, timezone: ${_this.timezone})';
}


}

/// @nodoc
abstract mixin class $TripDraftCopyWith<$Res>  {
  factory $TripDraftCopyWith(TripDraft value, $Res Function(TripDraft) _then) = _$TripDraftCopyWithImpl;
@useResult
$Res call({
 String title, String destination,@DateOnlyConverter() DateTime startDate,@DateOnlyConverter() DateTime endDate, String timezone
});




}
/// @nodoc
class _$TripDraftCopyWithImpl<$Res>
    implements $TripDraftCopyWith<$Res> {
  _$TripDraftCopyWithImpl(this._self, this._then);

  final TripDraft _self;
  final $Res Function(TripDraft) _then;

/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? destination = null,Object? startDate = null,Object? endDate = null,Object? timezone = null,}) {
  return _then(TripDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TripDraft].
extension TripDraftPatterns on TripDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripDraft value)  $default,){
final _that = this;
switch (_that) {
case _TripDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripDraft value)?  $default,){
final _that = this;
switch (_that) {
case _TripDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String destination, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  String timezone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripDraft() when $default != null:
return $default(_that.title,_that.destination,_that.startDate,_that.endDate,_that.timezone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String destination, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  String timezone)  $default,) {final _that = this;
switch (_that) {
case _TripDraft():
return $default(_that.title,_that.destination,_that.startDate,_that.endDate,_that.timezone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String destination, @DateOnlyConverter()  DateTime startDate, @DateOnlyConverter()  DateTime endDate,  String timezone)?  $default,) {final _that = this;
switch (_that) {
case _TripDraft() when $default != null:
return $default(_that.title,_that.destination,_that.startDate,_that.endDate,_that.timezone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripDraft extends TripDraft {
  const _TripDraft({required this.title, required this.destination, @DateOnlyConverter() required this.startDate, @DateOnlyConverter() required this.endDate, required this.timezone}): super._();
  factory _TripDraft.fromJson(Map<String, dynamic> json) => _$TripDraftFromJson(json);

@override final  String title;
@override final  String destination;
@override@DateOnlyConverter() final  DateTime startDate;
@override@DateOnlyConverter() final  DateTime endDate;
@override final  String timezone;

/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripDraftCopyWith<_TripDraft> get copyWith => __$TripDraftCopyWithImpl<_TripDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripDraftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.timezone, timezone) || other.timezone == timezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,destination,startDate,endDate,timezone);
}

@override
String toString() {
    return 'TripDraft(title: $title, destination: $destination, startDate: $startDate, endDate: $endDate, timezone: $timezone)';
}


}

/// @nodoc
abstract mixin class _$TripDraftCopyWith<$Res> implements $TripDraftCopyWith<$Res> {
  factory _$TripDraftCopyWith(_TripDraft value, $Res Function(_TripDraft) _then) = __$TripDraftCopyWithImpl;
@override @useResult
$Res call({
 String title, String destination,@DateOnlyConverter() DateTime startDate,@DateOnlyConverter() DateTime endDate, String timezone
});




}
/// @nodoc
class __$TripDraftCopyWithImpl<$Res>
    implements _$TripDraftCopyWith<$Res> {
  __$TripDraftCopyWithImpl(this._self, this._then);

  final _TripDraft _self;
  final $Res Function(_TripDraft) _then;

/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? destination = null,Object? startDate = null,Object? endDate = null,Object? timezone = null,}) {
  return _then(_TripDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
