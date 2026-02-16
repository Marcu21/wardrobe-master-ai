// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clothing_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ClothingItem _$ClothingItemFromJson(Map<String, dynamic> json) {
  return _ClothingItem.fromJson(json);
}

/// @nodoc
mixin _$ClothingItem {
  @JsonKey(name: 'item_id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'basic_info')
  BasicInfo get basicInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'styling_info')
  StylingInfo get stylingInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'laundry_info')
  LaundryInfo get laundryInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'sustainability_info')
  SustainabilityInfo get sustainabilityInfo =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'usage_stats')
  UsageStats get usageStats => throw _privateConstructorUsedError;

  /// Serializes this ClothingItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClothingItemCopyWith<ClothingItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClothingItemCopyWith<$Res> {
  factory $ClothingItemCopyWith(
    ClothingItem value,
    $Res Function(ClothingItem) then,
  ) = _$ClothingItemCopyWithImpl<$Res, ClothingItem>;
  @useResult
  $Res call({
    @JsonKey(name: 'item_id') String id,
    @JsonKey(name: 'image_url') String imageUrl,
    @JsonKey(name: 'basic_info') BasicInfo basicInfo,
    @JsonKey(name: 'styling_info') StylingInfo stylingInfo,
    @JsonKey(name: 'laundry_info') LaundryInfo laundryInfo,
    @JsonKey(name: 'sustainability_info') SustainabilityInfo sustainabilityInfo,
    @JsonKey(name: 'usage_stats') UsageStats usageStats,
  });

  $BasicInfoCopyWith<$Res> get basicInfo;
  $StylingInfoCopyWith<$Res> get stylingInfo;
  $LaundryInfoCopyWith<$Res> get laundryInfo;
  $SustainabilityInfoCopyWith<$Res> get sustainabilityInfo;
  $UsageStatsCopyWith<$Res> get usageStats;
}

/// @nodoc
class _$ClothingItemCopyWithImpl<$Res, $Val extends ClothingItem>
    implements $ClothingItemCopyWith<$Res> {
  _$ClothingItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? basicInfo = null,
    Object? stylingInfo = null,
    Object? laundryInfo = null,
    Object? sustainabilityInfo = null,
    Object? usageStats = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            basicInfo: null == basicInfo
                ? _value.basicInfo
                : basicInfo // ignore: cast_nullable_to_non_nullable
                      as BasicInfo,
            stylingInfo: null == stylingInfo
                ? _value.stylingInfo
                : stylingInfo // ignore: cast_nullable_to_non_nullable
                      as StylingInfo,
            laundryInfo: null == laundryInfo
                ? _value.laundryInfo
                : laundryInfo // ignore: cast_nullable_to_non_nullable
                      as LaundryInfo,
            sustainabilityInfo: null == sustainabilityInfo
                ? _value.sustainabilityInfo
                : sustainabilityInfo // ignore: cast_nullable_to_non_nullable
                      as SustainabilityInfo,
            usageStats: null == usageStats
                ? _value.usageStats
                : usageStats // ignore: cast_nullable_to_non_nullable
                      as UsageStats,
          )
          as $Val,
    );
  }

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BasicInfoCopyWith<$Res> get basicInfo {
    return $BasicInfoCopyWith<$Res>(_value.basicInfo, (value) {
      return _then(_value.copyWith(basicInfo: value) as $Val);
    });
  }

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StylingInfoCopyWith<$Res> get stylingInfo {
    return $StylingInfoCopyWith<$Res>(_value.stylingInfo, (value) {
      return _then(_value.copyWith(stylingInfo: value) as $Val);
    });
  }

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LaundryInfoCopyWith<$Res> get laundryInfo {
    return $LaundryInfoCopyWith<$Res>(_value.laundryInfo, (value) {
      return _then(_value.copyWith(laundryInfo: value) as $Val);
    });
  }

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SustainabilityInfoCopyWith<$Res> get sustainabilityInfo {
    return $SustainabilityInfoCopyWith<$Res>(_value.sustainabilityInfo, (
      value,
    ) {
      return _then(_value.copyWith(sustainabilityInfo: value) as $Val);
    });
  }

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UsageStatsCopyWith<$Res> get usageStats {
    return $UsageStatsCopyWith<$Res>(_value.usageStats, (value) {
      return _then(_value.copyWith(usageStats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClothingItemImplCopyWith<$Res>
    implements $ClothingItemCopyWith<$Res> {
  factory _$$ClothingItemImplCopyWith(
    _$ClothingItemImpl value,
    $Res Function(_$ClothingItemImpl) then,
  ) = __$$ClothingItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'item_id') String id,
    @JsonKey(name: 'image_url') String imageUrl,
    @JsonKey(name: 'basic_info') BasicInfo basicInfo,
    @JsonKey(name: 'styling_info') StylingInfo stylingInfo,
    @JsonKey(name: 'laundry_info') LaundryInfo laundryInfo,
    @JsonKey(name: 'sustainability_info') SustainabilityInfo sustainabilityInfo,
    @JsonKey(name: 'usage_stats') UsageStats usageStats,
  });

  @override
  $BasicInfoCopyWith<$Res> get basicInfo;
  @override
  $StylingInfoCopyWith<$Res> get stylingInfo;
  @override
  $LaundryInfoCopyWith<$Res> get laundryInfo;
  @override
  $SustainabilityInfoCopyWith<$Res> get sustainabilityInfo;
  @override
  $UsageStatsCopyWith<$Res> get usageStats;
}

/// @nodoc
class __$$ClothingItemImplCopyWithImpl<$Res>
    extends _$ClothingItemCopyWithImpl<$Res, _$ClothingItemImpl>
    implements _$$ClothingItemImplCopyWith<$Res> {
  __$$ClothingItemImplCopyWithImpl(
    _$ClothingItemImpl _value,
    $Res Function(_$ClothingItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? basicInfo = null,
    Object? stylingInfo = null,
    Object? laundryInfo = null,
    Object? sustainabilityInfo = null,
    Object? usageStats = null,
  }) {
    return _then(
      _$ClothingItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        basicInfo: null == basicInfo
            ? _value.basicInfo
            : basicInfo // ignore: cast_nullable_to_non_nullable
                  as BasicInfo,
        stylingInfo: null == stylingInfo
            ? _value.stylingInfo
            : stylingInfo // ignore: cast_nullable_to_non_nullable
                  as StylingInfo,
        laundryInfo: null == laundryInfo
            ? _value.laundryInfo
            : laundryInfo // ignore: cast_nullable_to_non_nullable
                  as LaundryInfo,
        sustainabilityInfo: null == sustainabilityInfo
            ? _value.sustainabilityInfo
            : sustainabilityInfo // ignore: cast_nullable_to_non_nullable
                  as SustainabilityInfo,
        usageStats: null == usageStats
            ? _value.usageStats
            : usageStats // ignore: cast_nullable_to_non_nullable
                  as UsageStats,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClothingItemImpl implements _ClothingItem {
  const _$ClothingItemImpl({
    @JsonKey(name: 'item_id') required this.id,
    @JsonKey(name: 'image_url') required this.imageUrl,
    @JsonKey(name: 'basic_info') required this.basicInfo,
    @JsonKey(name: 'styling_info') required this.stylingInfo,
    @JsonKey(name: 'laundry_info') required this.laundryInfo,
    @JsonKey(name: 'sustainability_info') required this.sustainabilityInfo,
    @JsonKey(name: 'usage_stats') required this.usageStats,
  });

  factory _$ClothingItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClothingItemImplFromJson(json);

  @override
  @JsonKey(name: 'item_id')
  final String id;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @override
  @JsonKey(name: 'basic_info')
  final BasicInfo basicInfo;
  @override
  @JsonKey(name: 'styling_info')
  final StylingInfo stylingInfo;
  @override
  @JsonKey(name: 'laundry_info')
  final LaundryInfo laundryInfo;
  @override
  @JsonKey(name: 'sustainability_info')
  final SustainabilityInfo sustainabilityInfo;
  @override
  @JsonKey(name: 'usage_stats')
  final UsageStats usageStats;

  @override
  String toString() {
    return 'ClothingItem(id: $id, imageUrl: $imageUrl, basicInfo: $basicInfo, stylingInfo: $stylingInfo, laundryInfo: $laundryInfo, sustainabilityInfo: $sustainabilityInfo, usageStats: $usageStats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClothingItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.basicInfo, basicInfo) ||
                other.basicInfo == basicInfo) &&
            (identical(other.stylingInfo, stylingInfo) ||
                other.stylingInfo == stylingInfo) &&
            (identical(other.laundryInfo, laundryInfo) ||
                other.laundryInfo == laundryInfo) &&
            (identical(other.sustainabilityInfo, sustainabilityInfo) ||
                other.sustainabilityInfo == sustainabilityInfo) &&
            (identical(other.usageStats, usageStats) ||
                other.usageStats == usageStats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    imageUrl,
    basicInfo,
    stylingInfo,
    laundryInfo,
    sustainabilityInfo,
    usageStats,
  );

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClothingItemImplCopyWith<_$ClothingItemImpl> get copyWith =>
      __$$ClothingItemImplCopyWithImpl<_$ClothingItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClothingItemImplToJson(this);
  }
}

abstract class _ClothingItem implements ClothingItem {
  const factory _ClothingItem({
    @JsonKey(name: 'item_id') required final String id,
    @JsonKey(name: 'image_url') required final String imageUrl,
    @JsonKey(name: 'basic_info') required final BasicInfo basicInfo,
    @JsonKey(name: 'styling_info') required final StylingInfo stylingInfo,
    @JsonKey(name: 'laundry_info') required final LaundryInfo laundryInfo,
    @JsonKey(name: 'sustainability_info')
    required final SustainabilityInfo sustainabilityInfo,
    @JsonKey(name: 'usage_stats') required final UsageStats usageStats,
  }) = _$ClothingItemImpl;

  factory _ClothingItem.fromJson(Map<String, dynamic> json) =
      _$ClothingItemImpl.fromJson;

  @override
  @JsonKey(name: 'item_id')
  String get id;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  @JsonKey(name: 'basic_info')
  BasicInfo get basicInfo;
  @override
  @JsonKey(name: 'styling_info')
  StylingInfo get stylingInfo;
  @override
  @JsonKey(name: 'laundry_info')
  LaundryInfo get laundryInfo;
  @override
  @JsonKey(name: 'sustainability_info')
  SustainabilityInfo get sustainabilityInfo;
  @override
  @JsonKey(name: 'usage_stats')
  UsageStats get usageStats;

  /// Create a copy of ClothingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClothingItemImplCopyWith<_$ClothingItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
