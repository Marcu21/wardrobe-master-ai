// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'basic_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BasicInfo _$BasicInfoFromJson(Map<String, dynamic> json) {
  return _BasicInfo.fromJson(json);
}

/// @nodoc
mixin _$BasicInfo {
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'sub_category')
  String get subCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_colors')
  List<String> get primaryColors => throw _privateConstructorUsedError;
  String get material => throw _privateConstructorUsedError;
  String get pattern => throw _privateConstructorUsedError;

  /// Serializes this BasicInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BasicInfoCopyWith<BasicInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BasicInfoCopyWith<$Res> {
  factory $BasicInfoCopyWith(BasicInfo value, $Res Function(BasicInfo) then) =
      _$BasicInfoCopyWithImpl<$Res, BasicInfo>;
  @useResult
  $Res call({
    String category,
    @JsonKey(name: 'sub_category') String subCategory,
    @JsonKey(name: 'primary_colors') List<String> primaryColors,
    String material,
    String pattern,
  });
}

/// @nodoc
class _$BasicInfoCopyWithImpl<$Res, $Val extends BasicInfo>
    implements $BasicInfoCopyWith<$Res> {
  _$BasicInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? subCategory = null,
    Object? primaryColors = null,
    Object? material = null,
    Object? pattern = null,
  }) {
    return _then(
      _value.copyWith(
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            subCategory: null == subCategory
                ? _value.subCategory
                : subCategory // ignore: cast_nullable_to_non_nullable
                      as String,
            primaryColors: null == primaryColors
                ? _value.primaryColors
                : primaryColors // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            material: null == material
                ? _value.material
                : material // ignore: cast_nullable_to_non_nullable
                      as String,
            pattern: null == pattern
                ? _value.pattern
                : pattern // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BasicInfoImplCopyWith<$Res>
    implements $BasicInfoCopyWith<$Res> {
  factory _$$BasicInfoImplCopyWith(
    _$BasicInfoImpl value,
    $Res Function(_$BasicInfoImpl) then,
  ) = __$$BasicInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String category,
    @JsonKey(name: 'sub_category') String subCategory,
    @JsonKey(name: 'primary_colors') List<String> primaryColors,
    String material,
    String pattern,
  });
}

/// @nodoc
class __$$BasicInfoImplCopyWithImpl<$Res>
    extends _$BasicInfoCopyWithImpl<$Res, _$BasicInfoImpl>
    implements _$$BasicInfoImplCopyWith<$Res> {
  __$$BasicInfoImplCopyWithImpl(
    _$BasicInfoImpl _value,
    $Res Function(_$BasicInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? subCategory = null,
    Object? primaryColors = null,
    Object? material = null,
    Object? pattern = null,
  }) {
    return _then(
      _$BasicInfoImpl(
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        subCategory: null == subCategory
            ? _value.subCategory
            : subCategory // ignore: cast_nullable_to_non_nullable
                  as String,
        primaryColors: null == primaryColors
            ? _value._primaryColors
            : primaryColors // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        material: null == material
            ? _value.material
            : material // ignore: cast_nullable_to_non_nullable
                  as String,
        pattern: null == pattern
            ? _value.pattern
            : pattern // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BasicInfoImpl implements _BasicInfo {
  const _$BasicInfoImpl({
    required this.category,
    @JsonKey(name: 'sub_category') required this.subCategory,
    @JsonKey(name: 'primary_colors') required final List<String> primaryColors,
    required this.material,
    required this.pattern,
  }) : _primaryColors = primaryColors;

  factory _$BasicInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$BasicInfoImplFromJson(json);

  @override
  final String category;
  @override
  @JsonKey(name: 'sub_category')
  final String subCategory;
  final List<String> _primaryColors;
  @override
  @JsonKey(name: 'primary_colors')
  List<String> get primaryColors {
    if (_primaryColors is EqualUnmodifiableListView) return _primaryColors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_primaryColors);
  }

  @override
  final String material;
  @override
  final String pattern;

  @override
  String toString() {
    return 'BasicInfo(category: $category, subCategory: $subCategory, primaryColors: $primaryColors, material: $material, pattern: $pattern)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BasicInfoImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.subCategory, subCategory) ||
                other.subCategory == subCategory) &&
            const DeepCollectionEquality().equals(
              other._primaryColors,
              _primaryColors,
            ) &&
            (identical(other.material, material) ||
                other.material == material) &&
            (identical(other.pattern, pattern) || other.pattern == pattern));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    category,
    subCategory,
    const DeepCollectionEquality().hash(_primaryColors),
    material,
    pattern,
  );

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BasicInfoImplCopyWith<_$BasicInfoImpl> get copyWith =>
      __$$BasicInfoImplCopyWithImpl<_$BasicInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BasicInfoImplToJson(this);
  }
}

abstract class _BasicInfo implements BasicInfo {
  const factory _BasicInfo({
    required final String category,
    @JsonKey(name: 'sub_category') required final String subCategory,
    @JsonKey(name: 'primary_colors') required final List<String> primaryColors,
    required final String material,
    required final String pattern,
  }) = _$BasicInfoImpl;

  factory _BasicInfo.fromJson(Map<String, dynamic> json) =
      _$BasicInfoImpl.fromJson;

  @override
  String get category;
  @override
  @JsonKey(name: 'sub_category')
  String get subCategory;
  @override
  @JsonKey(name: 'primary_colors')
  List<String> get primaryColors;
  @override
  String get material;
  @override
  String get pattern;

  /// Create a copy of BasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BasicInfoImplCopyWith<_$BasicInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
