// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LatLng {

 double get lat; double get lng;
/// Create a copy of LatLng
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LatLngCopyWith<LatLng> get copyWith => _$LatLngCopyWithImpl<LatLng>(this as LatLng, _$identity);

  /// Serializes this LatLng to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LatLng;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LatLng&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LatLng;
  return Object.hash(runtimeType,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as LatLng;
  return 'LatLng(lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $LatLngCopyWith<$Res>  {
  factory $LatLngCopyWith(LatLng value, $Res Function(LatLng) _then) = _$LatLngCopyWithImpl;
@useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class _$LatLngCopyWithImpl<$Res>
    implements $LatLngCopyWith<$Res> {
  _$LatLngCopyWithImpl(this._self, this._then);

  final LatLng _self;
  final $Res Function(LatLng) _then;

/// Create a copy of LatLng
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(LatLng(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [LatLng].
extension LatLngPatterns on LatLng {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LatLng value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LatLng() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LatLng value)  $default,){
final _that = this;
switch (_that) {
case _LatLng():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LatLng value)?  $default,){
final _that = this;
switch (_that) {
case _LatLng() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LatLng() when $default != null:
return $default(_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _LatLng():
return $default(_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _LatLng() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LatLng implements LatLng {
  const _LatLng({required this.lat, required this.lng});
  factory _LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);

@override final  double lat;
@override final  double lng;

/// Create a copy of LatLng
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LatLngCopyWith<_LatLng> get copyWith => __$LatLngCopyWithImpl<_LatLng>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LatLngToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LatLng&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lat,lng);
}

@override
String toString() {
    return 'LatLng(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$LatLngCopyWith<$Res> implements $LatLngCopyWith<$Res> {
  factory _$LatLngCopyWith(_LatLng value, $Res Function(_LatLng) _then) = __$LatLngCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class __$LatLngCopyWithImpl<$Res>
    implements _$LatLngCopyWith<$Res> {
  __$LatLngCopyWithImpl(this._self, this._then);

  final _LatLng _self;
  final $Res Function(_LatLng) _then;

/// Create a copy of LatLng
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(_LatLng(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PlaceSuggestion {

 String get placeId; String get name; String? get secondary;
/// Create a copy of PlaceSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceSuggestionCopyWith<PlaceSuggestion> get copyWith => _$PlaceSuggestionCopyWithImpl<PlaceSuggestion>(this as PlaceSuggestion, _$identity);

  /// Serializes this PlaceSuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaceSuggestion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceSuggestion&&(identical(other.placeId, _this.placeId) || other.placeId == _this.placeId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.secondary, _this.secondary) || other.secondary == _this.secondary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaceSuggestion;
  return Object.hash(runtimeType,_this.placeId,_this.name,_this.secondary);
}

@override
String toString() {
  final _this = this as PlaceSuggestion;
  return 'PlaceSuggestion(placeId: ${_this.placeId}, name: ${_this.name}, secondary: ${_this.secondary})';
}


}

/// @nodoc
abstract mixin class $PlaceSuggestionCopyWith<$Res>  {
  factory $PlaceSuggestionCopyWith(PlaceSuggestion value, $Res Function(PlaceSuggestion) _then) = _$PlaceSuggestionCopyWithImpl;
@useResult
$Res call({
 String placeId, String name, String? secondary
});




}
/// @nodoc
class _$PlaceSuggestionCopyWithImpl<$Res>
    implements $PlaceSuggestionCopyWith<$Res> {
  _$PlaceSuggestionCopyWithImpl(this._self, this._then);

  final PlaceSuggestion _self;
  final $Res Function(PlaceSuggestion) _then;

/// Create a copy of PlaceSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? placeId = null,Object? name = null,Object? secondary = freezed,}) {
  return _then(PlaceSuggestion(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,secondary: freezed == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceSuggestion].
extension PlaceSuggestionPatterns on PlaceSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _PlaceSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String placeId,  String name,  String? secondary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceSuggestion() when $default != null:
return $default(_that.placeId,_that.name,_that.secondary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String placeId,  String name,  String? secondary)  $default,) {final _that = this;
switch (_that) {
case _PlaceSuggestion():
return $default(_that.placeId,_that.name,_that.secondary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String placeId,  String name,  String? secondary)?  $default,) {final _that = this;
switch (_that) {
case _PlaceSuggestion() when $default != null:
return $default(_that.placeId,_that.name,_that.secondary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceSuggestion implements PlaceSuggestion {
  const _PlaceSuggestion({required this.placeId, required this.name, this.secondary});
  factory _PlaceSuggestion.fromJson(Map<String, dynamic> json) => _$PlaceSuggestionFromJson(json);

@override final  String placeId;
@override final  String name;
@override final  String? secondary;

/// Create a copy of PlaceSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceSuggestionCopyWith<_PlaceSuggestion> get copyWith => __$PlaceSuggestionCopyWithImpl<_PlaceSuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceSuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceSuggestion&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.secondary, secondary) || other.secondary == secondary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,placeId,name,secondary);
}

@override
String toString() {
    return 'PlaceSuggestion(placeId: $placeId, name: $name, secondary: $secondary)';
}


}

/// @nodoc
abstract mixin class _$PlaceSuggestionCopyWith<$Res> implements $PlaceSuggestionCopyWith<$Res> {
  factory _$PlaceSuggestionCopyWith(_PlaceSuggestion value, $Res Function(_PlaceSuggestion) _then) = __$PlaceSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String placeId, String name, String? secondary
});




}
/// @nodoc
class __$PlaceSuggestionCopyWithImpl<$Res>
    implements _$PlaceSuggestionCopyWith<$Res> {
  __$PlaceSuggestionCopyWithImpl(this._self, this._then);

  final _PlaceSuggestion _self;
  final $Res Function(_PlaceSuggestion) _then;

/// Create a copy of PlaceSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? placeId = null,Object? name = null,Object? secondary = freezed,}) {
  return _then(_PlaceSuggestion(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,secondary: freezed == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PlaceInfo {

 String get placeId; LatLng get location; String get mapsUrl; String get attribution; String? get address;
/// Create a copy of PlaceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceInfoCopyWith<PlaceInfo> get copyWith => _$PlaceInfoCopyWithImpl<PlaceInfo>(this as PlaceInfo, _$identity);

  /// Serializes this PlaceInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaceInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceInfo&&(identical(other.placeId, _this.placeId) || other.placeId == _this.placeId)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.mapsUrl, _this.mapsUrl) || other.mapsUrl == _this.mapsUrl)&&(identical(other.attribution, _this.attribution) || other.attribution == _this.attribution)&&(identical(other.address, _this.address) || other.address == _this.address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaceInfo;
  return Object.hash(runtimeType,_this.placeId,_this.location,_this.mapsUrl,_this.attribution,_this.address);
}

@override
String toString() {
  final _this = this as PlaceInfo;
  return 'PlaceInfo(placeId: ${_this.placeId}, location: ${_this.location}, mapsUrl: ${_this.mapsUrl}, attribution: ${_this.attribution}, address: ${_this.address})';
}


}

/// @nodoc
abstract mixin class $PlaceInfoCopyWith<$Res>  {
  factory $PlaceInfoCopyWith(PlaceInfo value, $Res Function(PlaceInfo) _then) = _$PlaceInfoCopyWithImpl;
@useResult
$Res call({
 String placeId, LatLng location, String mapsUrl, String attribution, String? address
});


$LatLngCopyWith<$Res> get location;

}
/// @nodoc
class _$PlaceInfoCopyWithImpl<$Res>
    implements $PlaceInfoCopyWith<$Res> {
  _$PlaceInfoCopyWithImpl(this._self, this._then);

  final PlaceInfo _self;
  final $Res Function(PlaceInfo) _then;

/// Create a copy of PlaceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? placeId = null,Object? location = null,Object? mapsUrl = null,Object? attribution = null,Object? address = freezed,}) {
  return _then(PlaceInfo(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as LatLng,mapsUrl: null == mapsUrl ? _self.mapsUrl : mapsUrl // ignore: cast_nullable_to_non_nullable
as String,attribution: null == attribution ? _self.attribution : attribution // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PlaceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res> get location {
  
  return $LatLngCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaceInfo].
extension PlaceInfoPatterns on PlaceInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceInfo value)  $default,){
final _that = this;
switch (_that) {
case _PlaceInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String placeId,  LatLng location,  String mapsUrl,  String attribution,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceInfo() when $default != null:
return $default(_that.placeId,_that.location,_that.mapsUrl,_that.attribution,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String placeId,  LatLng location,  String mapsUrl,  String attribution,  String? address)  $default,) {final _that = this;
switch (_that) {
case _PlaceInfo():
return $default(_that.placeId,_that.location,_that.mapsUrl,_that.attribution,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String placeId,  LatLng location,  String mapsUrl,  String attribution,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _PlaceInfo() when $default != null:
return $default(_that.placeId,_that.location,_that.mapsUrl,_that.attribution,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceInfo implements PlaceInfo {
  const _PlaceInfo({required this.placeId, required this.location, required this.mapsUrl, required this.attribution, this.address});
  factory _PlaceInfo.fromJson(Map<String, dynamic> json) => _$PlaceInfoFromJson(json);

@override final  String placeId;
@override final  LatLng location;
@override final  String mapsUrl;
@override final  String attribution;
@override final  String? address;

/// Create a copy of PlaceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceInfoCopyWith<_PlaceInfo> get copyWith => __$PlaceInfoCopyWithImpl<_PlaceInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceInfo&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.location, location) || other.location == location)&&(identical(other.mapsUrl, mapsUrl) || other.mapsUrl == mapsUrl)&&(identical(other.attribution, attribution) || other.attribution == attribution)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,placeId,location,mapsUrl,attribution,address);
}

@override
String toString() {
    return 'PlaceInfo(placeId: $placeId, location: $location, mapsUrl: $mapsUrl, attribution: $attribution, address: $address)';
}


}

/// @nodoc
abstract mixin class _$PlaceInfoCopyWith<$Res> implements $PlaceInfoCopyWith<$Res> {
  factory _$PlaceInfoCopyWith(_PlaceInfo value, $Res Function(_PlaceInfo) _then) = __$PlaceInfoCopyWithImpl;
@override @useResult
$Res call({
 String placeId, LatLng location, String mapsUrl, String attribution, String? address
});


@override $LatLngCopyWith<$Res> get location;

}
/// @nodoc
class __$PlaceInfoCopyWithImpl<$Res>
    implements _$PlaceInfoCopyWith<$Res> {
  __$PlaceInfoCopyWithImpl(this._self, this._then);

  final _PlaceInfo _self;
  final $Res Function(_PlaceInfo) _then;

/// Create a copy of PlaceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? placeId = null,Object? location = null,Object? mapsUrl = null,Object? attribution = null,Object? address = freezed,}) {
  return _then(_PlaceInfo(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as LatLng,mapsUrl: null == mapsUrl ? _self.mapsUrl : mapsUrl // ignore: cast_nullable_to_non_nullable
as String,attribution: null == attribution ? _self.attribution : attribution // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlaceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res> get location {
  
  return $LatLngCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

/// @nodoc
mixin _$PlacePick {

 String get placeId; String get googleName; String? get address;
/// Create a copy of PlacePick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlacePickCopyWith<PlacePick> get copyWith => _$PlacePickCopyWithImpl<PlacePick>(this as PlacePick, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlacePick;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlacePick&&(identical(other.placeId, _this.placeId) || other.placeId == _this.placeId)&&(identical(other.googleName, _this.googleName) || other.googleName == _this.googleName)&&(identical(other.address, _this.address) || other.address == _this.address));
}


@override
int get hashCode {
  final _this = this as PlacePick;
  return Object.hash(runtimeType,_this.placeId,_this.googleName,_this.address);
}

@override
String toString() {
  final _this = this as PlacePick;
  return 'PlacePick(placeId: ${_this.placeId}, googleName: ${_this.googleName}, address: ${_this.address})';
}


}

/// @nodoc
abstract mixin class $PlacePickCopyWith<$Res>  {
  factory $PlacePickCopyWith(PlacePick value, $Res Function(PlacePick) _then) = _$PlacePickCopyWithImpl;
@useResult
$Res call({
 String placeId, String googleName, String? address
});




}
/// @nodoc
class _$PlacePickCopyWithImpl<$Res>
    implements $PlacePickCopyWith<$Res> {
  _$PlacePickCopyWithImpl(this._self, this._then);

  final PlacePick _self;
  final $Res Function(PlacePick) _then;

/// Create a copy of PlacePick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? placeId = null,Object? googleName = null,Object? address = freezed,}) {
  return _then(PlacePick(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,googleName: null == googleName ? _self.googleName : googleName // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlacePick].
extension PlacePickPatterns on PlacePick {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlacePick value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlacePick() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlacePick value)  $default,){
final _that = this;
switch (_that) {
case _PlacePick():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlacePick value)?  $default,){
final _that = this;
switch (_that) {
case _PlacePick() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String placeId,  String googleName,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlacePick() when $default != null:
return $default(_that.placeId,_that.googleName,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String placeId,  String googleName,  String? address)  $default,) {final _that = this;
switch (_that) {
case _PlacePick():
return $default(_that.placeId,_that.googleName,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String placeId,  String googleName,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _PlacePick() when $default != null:
return $default(_that.placeId,_that.googleName,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _PlacePick implements PlacePick {
  const _PlacePick({required this.placeId, required this.googleName, this.address});
  

@override final  String placeId;
@override final  String googleName;
@override final  String? address;

/// Create a copy of PlacePick
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlacePickCopyWith<_PlacePick> get copyWith => __$PlacePickCopyWithImpl<_PlacePick>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlacePick&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.googleName, googleName) || other.googleName == googleName)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode {
    return Object.hash(runtimeType,placeId,googleName,address);
}

@override
String toString() {
    return 'PlacePick(placeId: $placeId, googleName: $googleName, address: $address)';
}


}

/// @nodoc
abstract mixin class _$PlacePickCopyWith<$Res> implements $PlacePickCopyWith<$Res> {
  factory _$PlacePickCopyWith(_PlacePick value, $Res Function(_PlacePick) _then) = __$PlacePickCopyWithImpl;
@override @useResult
$Res call({
 String placeId, String googleName, String? address
});




}
/// @nodoc
class __$PlacePickCopyWithImpl<$Res>
    implements _$PlacePickCopyWith<$Res> {
  __$PlacePickCopyWithImpl(this._self, this._then);

  final _PlacePick _self;
  final $Res Function(_PlacePick) _then;

/// Create a copy of PlacePick
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? placeId = null,Object? googleName = null,Object? address = freezed,}) {
  return _then(_PlacePick(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,googleName: null == googleName ? _self.googleName : googleName // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
