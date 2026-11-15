// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItineraryItem {

 String get id;@DateOnlyConverter() DateTime get day; int get position; String get title; int get version; DateTime get updatedAt; String? get memo; String? get placeId; LatLng? get location; String? get startTime; int? get stayMinutes; TravelMode? get travelMode;
/// Create a copy of ItineraryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItineraryItemCopyWith<ItineraryItem> get copyWith => _$ItineraryItemCopyWithImpl<ItineraryItem>(this as ItineraryItem, _$identity);

  /// Serializes this ItineraryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ItineraryItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItineraryItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.day, _this.day) || other.day == _this.day)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.placeId, _this.placeId) || other.placeId == _this.placeId)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.stayMinutes, _this.stayMinutes) || other.stayMinutes == _this.stayMinutes)&&(identical(other.travelMode, _this.travelMode) || other.travelMode == _this.travelMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ItineraryItem;
  return Object.hash(runtimeType,_this.id,_this.day,_this.position,_this.title,_this.version,_this.updatedAt,_this.memo,_this.placeId,_this.location,_this.startTime,_this.stayMinutes,_this.travelMode);
}

@override
String toString() {
  final _this = this as ItineraryItem;
  return 'ItineraryItem(id: ${_this.id}, day: ${_this.day}, position: ${_this.position}, title: ${_this.title}, version: ${_this.version}, updatedAt: ${_this.updatedAt}, memo: ${_this.memo}, placeId: ${_this.placeId}, location: ${_this.location}, startTime: ${_this.startTime}, stayMinutes: ${_this.stayMinutes}, travelMode: ${_this.travelMode})';
}


}

/// @nodoc
abstract mixin class $ItineraryItemCopyWith<$Res>  {
  factory $ItineraryItemCopyWith(ItineraryItem value, $Res Function(ItineraryItem) _then) = _$ItineraryItemCopyWithImpl;
@useResult
$Res call({
 String id,@DateOnlyConverter() DateTime day, int position, String title, int version, DateTime updatedAt, String? memo, String? placeId, LatLng? location, String? startTime, int? stayMinutes, TravelMode? travelMode
});


$LatLngCopyWith<$Res>? get location;

}
/// @nodoc
class _$ItineraryItemCopyWithImpl<$Res>
    implements $ItineraryItemCopyWith<$Res> {
  _$ItineraryItemCopyWithImpl(this._self, this._then);

  final ItineraryItem _self;
  final $Res Function(ItineraryItem) _then;

/// Create a copy of ItineraryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? day = null,Object? position = null,Object? title = null,Object? version = null,Object? updatedAt = null,Object? memo = freezed,Object? placeId = freezed,Object? location = freezed,Object? startTime = freezed,Object? stayMinutes = freezed,Object? travelMode = freezed,}) {
  return _then(ItineraryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as LatLng?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,stayMinutes: freezed == stayMinutes ? _self.stayMinutes : stayMinutes // ignore: cast_nullable_to_non_nullable
as int?,travelMode: freezed == travelMode ? _self.travelMode : travelMode // ignore: cast_nullable_to_non_nullable
as TravelMode?,
  ));
}
/// Create a copy of ItineraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $LatLngCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [ItineraryItem].
extension ItineraryItemPatterns on ItineraryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItineraryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItineraryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItineraryItem value)  $default,){
final _that = this;
switch (_that) {
case _ItineraryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItineraryItem value)?  $default,){
final _that = this;
switch (_that) {
case _ItineraryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @DateOnlyConverter()  DateTime day,  int position,  String title,  int version,  DateTime updatedAt,  String? memo,  String? placeId,  LatLng? location,  String? startTime,  int? stayMinutes,  TravelMode? travelMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItineraryItem() when $default != null:
return $default(_that.id,_that.day,_that.position,_that.title,_that.version,_that.updatedAt,_that.memo,_that.placeId,_that.location,_that.startTime,_that.stayMinutes,_that.travelMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @DateOnlyConverter()  DateTime day,  int position,  String title,  int version,  DateTime updatedAt,  String? memo,  String? placeId,  LatLng? location,  String? startTime,  int? stayMinutes,  TravelMode? travelMode)  $default,) {final _that = this;
switch (_that) {
case _ItineraryItem():
return $default(_that.id,_that.day,_that.position,_that.title,_that.version,_that.updatedAt,_that.memo,_that.placeId,_that.location,_that.startTime,_that.stayMinutes,_that.travelMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @DateOnlyConverter()  DateTime day,  int position,  String title,  int version,  DateTime updatedAt,  String? memo,  String? placeId,  LatLng? location,  String? startTime,  int? stayMinutes,  TravelMode? travelMode)?  $default,) {final _that = this;
switch (_that) {
case _ItineraryItem() when $default != null:
return $default(_that.id,_that.day,_that.position,_that.title,_that.version,_that.updatedAt,_that.memo,_that.placeId,_that.location,_that.startTime,_that.stayMinutes,_that.travelMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItineraryItem implements ItineraryItem {
  const _ItineraryItem({required this.id, @DateOnlyConverter() required this.day, required this.position, required this.title, required this.version, required this.updatedAt, this.memo, this.placeId, this.location, this.startTime, this.stayMinutes, this.travelMode});
  factory _ItineraryItem.fromJson(Map<String, dynamic> json) => _$ItineraryItemFromJson(json);

@override final  String id;
@override@DateOnlyConverter() final  DateTime day;
@override final  int position;
@override final  String title;
@override final  int version;
@override final  DateTime updatedAt;
@override final  String? memo;
@override final  String? placeId;
@override final  LatLng? location;
@override final  String? startTime;
@override final  int? stayMinutes;
@override final  TravelMode? travelMode;

/// Create a copy of ItineraryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItineraryItemCopyWith<_ItineraryItem> get copyWith => __$ItineraryItemCopyWithImpl<_ItineraryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItineraryItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItineraryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.day, day) || other.day == day)&&(identical(other.position, position) || other.position == position)&&(identical(other.title, title) || other.title == title)&&(identical(other.version, version) || other.version == version)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.location, location) || other.location == location)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.stayMinutes, stayMinutes) || other.stayMinutes == stayMinutes)&&(identical(other.travelMode, travelMode) || other.travelMode == travelMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,day,position,title,version,updatedAt,memo,placeId,location,startTime,stayMinutes,travelMode);
}

@override
String toString() {
    return 'ItineraryItem(id: $id, day: $day, position: $position, title: $title, version: $version, updatedAt: $updatedAt, memo: $memo, placeId: $placeId, location: $location, startTime: $startTime, stayMinutes: $stayMinutes, travelMode: $travelMode)';
}


}

/// @nodoc
abstract mixin class _$ItineraryItemCopyWith<$Res> implements $ItineraryItemCopyWith<$Res> {
  factory _$ItineraryItemCopyWith(_ItineraryItem value, $Res Function(_ItineraryItem) _then) = __$ItineraryItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@DateOnlyConverter() DateTime day, int position, String title, int version, DateTime updatedAt, String? memo, String? placeId, LatLng? location, String? startTime, int? stayMinutes, TravelMode? travelMode
});


@override $LatLngCopyWith<$Res>? get location;

}
/// @nodoc
class __$ItineraryItemCopyWithImpl<$Res>
    implements _$ItineraryItemCopyWith<$Res> {
  __$ItineraryItemCopyWithImpl(this._self, this._then);

  final _ItineraryItem _self;
  final $Res Function(_ItineraryItem) _then;

/// Create a copy of ItineraryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? day = null,Object? position = null,Object? title = null,Object? version = null,Object? updatedAt = null,Object? memo = freezed,Object? placeId = freezed,Object? location = freezed,Object? startTime = freezed,Object? stayMinutes = freezed,Object? travelMode = freezed,}) {
  return _then(_ItineraryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as LatLng?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,stayMinutes: freezed == stayMinutes ? _self.stayMinutes : stayMinutes // ignore: cast_nullable_to_non_nullable
as int?,travelMode: freezed == travelMode ? _self.travelMode : travelMode // ignore: cast_nullable_to_non_nullable
as TravelMode?,
  ));
}

/// Create a copy of ItineraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $LatLngCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$DayItems {

@DateOnlyConverter() DateTime get date; List<ItineraryItem> get items;
/// Create a copy of DayItems
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayItemsCopyWith<DayItems> get copyWith => _$DayItemsCopyWithImpl<DayItems>(this as DayItems, _$identity);

  /// Serializes this DayItems to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DayItems;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayItems&&(identical(other.date, _this.date) || other.date == _this.date)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DayItems;
  return Object.hash(runtimeType,_this.date,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as DayItems;
  return 'DayItems(date: ${_this.date}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $DayItemsCopyWith<$Res>  {
  factory $DayItemsCopyWith(DayItems value, $Res Function(DayItems) _then) = _$DayItemsCopyWithImpl;
@useResult
$Res call({
@DateOnlyConverter() DateTime date, List<ItineraryItem> items
});




}
/// @nodoc
class _$DayItemsCopyWithImpl<$Res>
    implements $DayItemsCopyWith<$Res> {
  _$DayItemsCopyWithImpl(this._self, this._then);

  final DayItems _self;
  final $Res Function(DayItems) _then;

/// Create a copy of DayItems
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? items = null,}) {
  return _then(DayItems(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ItineraryItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayItems].
extension DayItemsPatterns on DayItems {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayItems value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayItems() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayItems value)  $default,){
final _that = this;
switch (_that) {
case _DayItems():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayItems value)?  $default,){
final _that = this;
switch (_that) {
case _DayItems() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime date,  List<ItineraryItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayItems() when $default != null:
return $default(_that.date,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime date,  List<ItineraryItem> items)  $default,) {final _that = this;
switch (_that) {
case _DayItems():
return $default(_that.date,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DateOnlyConverter()  DateTime date,  List<ItineraryItem> items)?  $default,) {final _that = this;
switch (_that) {
case _DayItems() when $default != null:
return $default(_that.date,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayItems implements DayItems {
  const _DayItems({@DateOnlyConverter() required this.date, required  List<ItineraryItem> items}): _items = items;
  factory _DayItems.fromJson(Map<String, dynamic> json) => _$DayItemsFromJson(json);

@override@DateOnlyConverter() final  DateTime date;
 final  List<ItineraryItem> _items;
@override List<ItineraryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of DayItems
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayItemsCopyWith<_DayItems> get copyWith => __$DayItemsCopyWithImpl<_DayItems>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayItemsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayItems&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'DayItems(date: $date, items: $items)';
}


}

/// @nodoc
abstract mixin class _$DayItemsCopyWith<$Res> implements $DayItemsCopyWith<$Res> {
  factory _$DayItemsCopyWith(_DayItems value, $Res Function(_DayItems) _then) = __$DayItemsCopyWithImpl;
@override @useResult
$Res call({
@DateOnlyConverter() DateTime date, List<ItineraryItem> items
});




}
/// @nodoc
class __$DayItemsCopyWithImpl<$Res>
    implements _$DayItemsCopyWith<$Res> {
  __$DayItemsCopyWithImpl(this._self, this._then);

  final _DayItems _self;
  final $Res Function(_DayItems) _then;

/// Create a copy of DayItems
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? items = null,}) {
  return _then(_DayItems(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ItineraryItem>,
  ));
}


}


/// @nodoc
mixin _$ItemDraft {

@DateOnlyConverter() DateTime get day; String get title; String? get memo; String? get placeId; String? get startTime; int? get stayMinutes; TravelMode? get travelMode;
/// Create a copy of ItemDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemDraftCopyWith<ItemDraft> get copyWith => _$ItemDraftCopyWithImpl<ItemDraft>(this as ItemDraft, _$identity);

  /// Serializes this ItemDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ItemDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemDraft&&(identical(other.day, _this.day) || other.day == _this.day)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.placeId, _this.placeId) || other.placeId == _this.placeId)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.stayMinutes, _this.stayMinutes) || other.stayMinutes == _this.stayMinutes)&&(identical(other.travelMode, _this.travelMode) || other.travelMode == _this.travelMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ItemDraft;
  return Object.hash(runtimeType,_this.day,_this.title,_this.memo,_this.placeId,_this.startTime,_this.stayMinutes,_this.travelMode);
}

@override
String toString() {
  final _this = this as ItemDraft;
  return 'ItemDraft(day: ${_this.day}, title: ${_this.title}, memo: ${_this.memo}, placeId: ${_this.placeId}, startTime: ${_this.startTime}, stayMinutes: ${_this.stayMinutes}, travelMode: ${_this.travelMode})';
}


}

/// @nodoc
abstract mixin class $ItemDraftCopyWith<$Res>  {
  factory $ItemDraftCopyWith(ItemDraft value, $Res Function(ItemDraft) _then) = _$ItemDraftCopyWithImpl;
@useResult
$Res call({
@DateOnlyConverter() DateTime day, String title, String? memo, String? placeId, String? startTime, int? stayMinutes, TravelMode? travelMode
});




}
/// @nodoc
class _$ItemDraftCopyWithImpl<$Res>
    implements $ItemDraftCopyWith<$Res> {
  _$ItemDraftCopyWithImpl(this._self, this._then);

  final ItemDraft _self;
  final $Res Function(ItemDraft) _then;

/// Create a copy of ItemDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? title = null,Object? memo = freezed,Object? placeId = freezed,Object? startTime = freezed,Object? stayMinutes = freezed,Object? travelMode = freezed,}) {
  return _then(ItemDraft(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,stayMinutes: freezed == stayMinutes ? _self.stayMinutes : stayMinutes // ignore: cast_nullable_to_non_nullable
as int?,travelMode: freezed == travelMode ? _self.travelMode : travelMode // ignore: cast_nullable_to_non_nullable
as TravelMode?,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemDraft].
extension ItemDraftPatterns on ItemDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemDraft value)  $default,){
final _that = this;
switch (_that) {
case _ItemDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ItemDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime day,  String title,  String? memo,  String? placeId,  String? startTime,  int? stayMinutes,  TravelMode? travelMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemDraft() when $default != null:
return $default(_that.day,_that.title,_that.memo,_that.placeId,_that.startTime,_that.stayMinutes,_that.travelMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime day,  String title,  String? memo,  String? placeId,  String? startTime,  int? stayMinutes,  TravelMode? travelMode)  $default,) {final _that = this;
switch (_that) {
case _ItemDraft():
return $default(_that.day,_that.title,_that.memo,_that.placeId,_that.startTime,_that.stayMinutes,_that.travelMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DateOnlyConverter()  DateTime day,  String title,  String? memo,  String? placeId,  String? startTime,  int? stayMinutes,  TravelMode? travelMode)?  $default,) {final _that = this;
switch (_that) {
case _ItemDraft() when $default != null:
return $default(_that.day,_that.title,_that.memo,_that.placeId,_that.startTime,_that.stayMinutes,_that.travelMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemDraft extends ItemDraft {
  const _ItemDraft({@DateOnlyConverter() required this.day, required this.title, this.memo, this.placeId, this.startTime, this.stayMinutes, this.travelMode}): super._();
  factory _ItemDraft.fromJson(Map<String, dynamic> json) => _$ItemDraftFromJson(json);

@override@DateOnlyConverter() final  DateTime day;
@override final  String title;
@override final  String? memo;
@override final  String? placeId;
@override final  String? startTime;
@override final  int? stayMinutes;
@override final  TravelMode? travelMode;

/// Create a copy of ItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemDraftCopyWith<_ItemDraft> get copyWith => __$ItemDraftCopyWithImpl<_ItemDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemDraftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemDraft&&(identical(other.day, day) || other.day == day)&&(identical(other.title, title) || other.title == title)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.stayMinutes, stayMinutes) || other.stayMinutes == stayMinutes)&&(identical(other.travelMode, travelMode) || other.travelMode == travelMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,day,title,memo,placeId,startTime,stayMinutes,travelMode);
}

@override
String toString() {
    return 'ItemDraft(day: $day, title: $title, memo: $memo, placeId: $placeId, startTime: $startTime, stayMinutes: $stayMinutes, travelMode: $travelMode)';
}


}

/// @nodoc
abstract mixin class _$ItemDraftCopyWith<$Res> implements $ItemDraftCopyWith<$Res> {
  factory _$ItemDraftCopyWith(_ItemDraft value, $Res Function(_ItemDraft) _then) = __$ItemDraftCopyWithImpl;
@override @useResult
$Res call({
@DateOnlyConverter() DateTime day, String title, String? memo, String? placeId, String? startTime, int? stayMinutes, TravelMode? travelMode
});




}
/// @nodoc
class __$ItemDraftCopyWithImpl<$Res>
    implements _$ItemDraftCopyWith<$Res> {
  __$ItemDraftCopyWithImpl(this._self, this._then);

  final _ItemDraft _self;
  final $Res Function(_ItemDraft) _then;

/// Create a copy of ItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? title = null,Object? memo = freezed,Object? placeId = freezed,Object? startTime = freezed,Object? stayMinutes = freezed,Object? travelMode = freezed,}) {
  return _then(_ItemDraft(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,stayMinutes: freezed == stayMinutes ? _self.stayMinutes : stayMinutes // ignore: cast_nullable_to_non_nullable
as int?,travelMode: freezed == travelMode ? _self.travelMode : travelMode // ignore: cast_nullable_to_non_nullable
as TravelMode?,
  ));
}


}


/// @nodoc
mixin _$RouteLeg {

 String get fromItemId; String get toItemId; LegStatus get status; TravelMode? get mode; int? get durationSeconds; int? get distanceMeters;
/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteLegCopyWith<RouteLeg> get copyWith => _$RouteLegCopyWithImpl<RouteLeg>(this as RouteLeg, _$identity);

  /// Serializes this RouteLeg to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RouteLeg;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteLeg&&(identical(other.fromItemId, _this.fromItemId) || other.fromItemId == _this.fromItemId)&&(identical(other.toItemId, _this.toItemId) || other.toItemId == _this.toItemId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds)&&(identical(other.distanceMeters, _this.distanceMeters) || other.distanceMeters == _this.distanceMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RouteLeg;
  return Object.hash(runtimeType,_this.fromItemId,_this.toItemId,_this.status,_this.mode,_this.durationSeconds,_this.distanceMeters);
}

@override
String toString() {
  final _this = this as RouteLeg;
  return 'RouteLeg(fromItemId: ${_this.fromItemId}, toItemId: ${_this.toItemId}, status: ${_this.status}, mode: ${_this.mode}, durationSeconds: ${_this.durationSeconds}, distanceMeters: ${_this.distanceMeters})';
}


}

/// @nodoc
abstract mixin class $RouteLegCopyWith<$Res>  {
  factory $RouteLegCopyWith(RouteLeg value, $Res Function(RouteLeg) _then) = _$RouteLegCopyWithImpl;
@useResult
$Res call({
 String fromItemId, String toItemId, LegStatus status, TravelMode? mode, int? durationSeconds, int? distanceMeters
});




}
/// @nodoc
class _$RouteLegCopyWithImpl<$Res>
    implements $RouteLegCopyWith<$Res> {
  _$RouteLegCopyWithImpl(this._self, this._then);

  final RouteLeg _self;
  final $Res Function(RouteLeg) _then;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromItemId = null,Object? toItemId = null,Object? status = null,Object? mode = freezed,Object? durationSeconds = freezed,Object? distanceMeters = freezed,}) {
  return _then(RouteLeg(
fromItemId: null == fromItemId ? _self.fromItemId : fromItemId // ignore: cast_nullable_to_non_nullable
as String,toItemId: null == toItemId ? _self.toItemId : toItemId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LegStatus,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as TravelMode?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteLeg].
extension RouteLegPatterns on RouteLeg {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteLeg value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteLeg() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteLeg value)  $default,){
final _that = this;
switch (_that) {
case _RouteLeg():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteLeg value)?  $default,){
final _that = this;
switch (_that) {
case _RouteLeg() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fromItemId,  String toItemId,  LegStatus status,  TravelMode? mode,  int? durationSeconds,  int? distanceMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteLeg() when $default != null:
return $default(_that.fromItemId,_that.toItemId,_that.status,_that.mode,_that.durationSeconds,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fromItemId,  String toItemId,  LegStatus status,  TravelMode? mode,  int? durationSeconds,  int? distanceMeters)  $default,) {final _that = this;
switch (_that) {
case _RouteLeg():
return $default(_that.fromItemId,_that.toItemId,_that.status,_that.mode,_that.durationSeconds,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fromItemId,  String toItemId,  LegStatus status,  TravelMode? mode,  int? durationSeconds,  int? distanceMeters)?  $default,) {final _that = this;
switch (_that) {
case _RouteLeg() when $default != null:
return $default(_that.fromItemId,_that.toItemId,_that.status,_that.mode,_that.durationSeconds,_that.distanceMeters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteLeg implements RouteLeg {
  const _RouteLeg({required this.fromItemId, required this.toItemId, required this.status, this.mode, this.durationSeconds, this.distanceMeters});
  factory _RouteLeg.fromJson(Map<String, dynamic> json) => _$RouteLegFromJson(json);

@override final  String fromItemId;
@override final  String toItemId;
@override final  LegStatus status;
@override final  TravelMode? mode;
@override final  int? durationSeconds;
@override final  int? distanceMeters;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteLegCopyWith<_RouteLeg> get copyWith => __$RouteLegCopyWithImpl<_RouteLeg>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteLegToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteLeg&&(identical(other.fromItemId, fromItemId) || other.fromItemId == fromItemId)&&(identical(other.toItemId, toItemId) || other.toItemId == toItemId)&&(identical(other.status, status) || other.status == status)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fromItemId,toItemId,status,mode,durationSeconds,distanceMeters);
}

@override
String toString() {
    return 'RouteLeg(fromItemId: $fromItemId, toItemId: $toItemId, status: $status, mode: $mode, durationSeconds: $durationSeconds, distanceMeters: $distanceMeters)';
}


}

/// @nodoc
abstract mixin class _$RouteLegCopyWith<$Res> implements $RouteLegCopyWith<$Res> {
  factory _$RouteLegCopyWith(_RouteLeg value, $Res Function(_RouteLeg) _then) = __$RouteLegCopyWithImpl;
@override @useResult
$Res call({
 String fromItemId, String toItemId, LegStatus status, TravelMode? mode, int? durationSeconds, int? distanceMeters
});




}
/// @nodoc
class __$RouteLegCopyWithImpl<$Res>
    implements _$RouteLegCopyWith<$Res> {
  __$RouteLegCopyWithImpl(this._self, this._then);

  final _RouteLeg _self;
  final $Res Function(_RouteLeg) _then;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromItemId = null,Object? toItemId = null,Object? status = null,Object? mode = freezed,Object? durationSeconds = freezed,Object? distanceMeters = freezed,}) {
  return _then(_RouteLeg(
fromItemId: null == fromItemId ? _self.fromItemId : fromItemId // ignore: cast_nullable_to_non_nullable
as String,toItemId: null == toItemId ? _self.toItemId : toItemId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LegStatus,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as TravelMode?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$DayView {

@DateOnlyConverter() DateTime get date; List<ItineraryItem> get items; List<RouteLeg> get legs;
/// Create a copy of DayView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayViewCopyWith<DayView> get copyWith => _$DayViewCopyWithImpl<DayView>(this as DayView, _$identity);

  /// Serializes this DayView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DayView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayView&&(identical(other.date, _this.date) || other.date == _this.date)&&const DeepCollectionEquality().equals(other.items, _this.items)&&const DeepCollectionEquality().equals(other.legs, _this.legs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DayView;
  return Object.hash(runtimeType,_this.date,const DeepCollectionEquality().hash(_this.items),const DeepCollectionEquality().hash(_this.legs));
}

@override
String toString() {
  final _this = this as DayView;
  return 'DayView(date: ${_this.date}, items: ${_this.items}, legs: ${_this.legs})';
}


}

/// @nodoc
abstract mixin class $DayViewCopyWith<$Res>  {
  factory $DayViewCopyWith(DayView value, $Res Function(DayView) _then) = _$DayViewCopyWithImpl;
@useResult
$Res call({
@DateOnlyConverter() DateTime date, List<ItineraryItem> items, List<RouteLeg> legs
});




}
/// @nodoc
class _$DayViewCopyWithImpl<$Res>
    implements $DayViewCopyWith<$Res> {
  _$DayViewCopyWithImpl(this._self, this._then);

  final DayView _self;
  final $Res Function(DayView) _then;

/// Create a copy of DayView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? items = null,Object? legs = null,}) {
  return _then(DayView(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ItineraryItem>,legs: null == legs ? _self.legs : legs // ignore: cast_nullable_to_non_nullable
as List<RouteLeg>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayView].
extension DayViewPatterns on DayView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayView value)  $default,){
final _that = this;
switch (_that) {
case _DayView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayView value)?  $default,){
final _that = this;
switch (_that) {
case _DayView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime date,  List<ItineraryItem> items,  List<RouteLeg> legs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayView() when $default != null:
return $default(_that.date,_that.items,_that.legs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime date,  List<ItineraryItem> items,  List<RouteLeg> legs)  $default,) {final _that = this;
switch (_that) {
case _DayView():
return $default(_that.date,_that.items,_that.legs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DateOnlyConverter()  DateTime date,  List<ItineraryItem> items,  List<RouteLeg> legs)?  $default,) {final _that = this;
switch (_that) {
case _DayView() when $default != null:
return $default(_that.date,_that.items,_that.legs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayView implements DayView {
  const _DayView({@DateOnlyConverter() required this.date, required  List<ItineraryItem> items, required  List<RouteLeg> legs}): _items = items,_legs = legs;
  factory _DayView.fromJson(Map<String, dynamic> json) => _$DayViewFromJson(json);

@override@DateOnlyConverter() final  DateTime date;
 final  List<ItineraryItem> _items;
@override List<ItineraryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<RouteLeg> _legs;
@override List<RouteLeg> get legs {
  if (_legs is EqualUnmodifiableListView) return _legs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_legs);
}


/// Create a copy of DayView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayViewCopyWith<_DayView> get copyWith => __$DayViewCopyWithImpl<_DayView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayView&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.items, _items)&&const DeepCollectionEquality().equals(other.legs, _legs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_legs));
}

@override
String toString() {
    return 'DayView(date: $date, items: $items, legs: $legs)';
}


}

/// @nodoc
abstract mixin class _$DayViewCopyWith<$Res> implements $DayViewCopyWith<$Res> {
  factory _$DayViewCopyWith(_DayView value, $Res Function(_DayView) _then) = __$DayViewCopyWithImpl;
@override @useResult
$Res call({
@DateOnlyConverter() DateTime date, List<ItineraryItem> items, List<RouteLeg> legs
});




}
/// @nodoc
class __$DayViewCopyWithImpl<$Res>
    implements _$DayViewCopyWith<$Res> {
  __$DayViewCopyWithImpl(this._self, this._then);

  final _DayView _self;
  final $Res Function(_DayView) _then;

/// Create a copy of DayView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? items = null,Object? legs = null,}) {
  return _then(_DayView(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ItineraryItem>,legs: null == legs ? _self._legs : legs // ignore: cast_nullable_to_non_nullable
as List<RouteLeg>,
  ));
}


}

// dart format on
