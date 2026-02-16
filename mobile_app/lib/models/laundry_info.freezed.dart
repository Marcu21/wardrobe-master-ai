// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'laundry_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LaundryInfo _$LaundryInfoFromJson(Map<String, dynamic> json) {
  return _LaundryInfo.fromJson(json);
}

/// @nodoc
mixin _$LaundryInfo {
  @JsonKey(name: 'color_group')
  String get colorGroup => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_temp_celsius')
  int get maxTempCelsius => throw _privateConstructorUsedError;
  @JsonKey(name: 'care_instructions')
  List<String> get careInstructions => throw _privateConstructorUsedError;

  /// Serializes this LaundryInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LaundryInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LaundryInfoCopyWith<LaundryInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LaundryInfoCopyWith<$Res> {
  factory $LaundryInfoCopyWith(
    LaundryInfo value,
    $Res Function(LaundryInfo) then,
  ) = _$LaundryInfoCopyWithImpl<$Res, LaundryInfo>;
  @useResult
  $Res call({
    @JsonKey(name: 'color_group') String colorGroup,
    @JsonKey(name: 'max_temp_celsius') int maxTempCelsius,
    @JsonKey(name: 'care_instructions') List<String> careInstructions,
  });
}

/// @nodoc
class _$LaundryInfoCopyWithImpl<$Res, $Val extends LaundryInfo>
    implements $LaundryInfoCopyWith<$Res> {
  _$LaundryInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LaundryInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? colorGroup = null,
    Object? maxTempCelsius = null,
    Object? careInstructions = null,
  }) {
    return _then(
      _value.copyWith(
            colorGroup: null == colorGroup
                ? _value.colorGroup
                : colorGroup // ignore: cast_nullable_to_non_nullable
                      as String,
            maxTempCelsius: null == maxTempCelsius
                ? _value.maxTempCelsius
                : maxTempCelsius // ignore: cast_nullable_to_non_nullable
                      as int,
            careInstructions: null == careInstructions
                ? _value.careInstructions
                : careInstructions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LaundryInfoImplCopyWith<$Res>
    implements $LaundryInfoCopyWith<$Res> {
  factory _$$LaundryInfoImplCopyWith(
    _$LaundryInfoImpl value,
    $Res Function(_$LaundryInfoImpl) then,
  ) = __$$LaundryInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'color_group') String colorGroup,
    @JsonKey(name: 'max_temp_celsius') int maxTempCelsius,
    @JsonKey(name: 'care_instructions') List<String> careInstructions,
  });
}

/// @nodoc
class __$$LaundryInfoImplCopyWithImpl<$Res>
    extends _$LaundryInfoCopyWithImpl<$Res, _$LaundryInfoImpl>
    implements _$$LaundryInfoImplCopyWith<$Res> {
  __$$LaundryInfoImplCopyWithImpl(
    _$LaundryInfoImpl _value,
    $Res Function(_$LaundryInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LaundryInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? colorGroup = null,
    Object? maxTempCelsius = null,
    Object? careInstructions = null,
  }) {
    return _then(
      _$LaundryInfoImpl(
        colorGroup: null == colorGroup
            ? _value.colorGroup
            : colorGroup // ignore: cast_nullable_to_non_nullable
                  as String,
        maxTempCelsius: null == maxTempCelsius
            ? _value.maxTempCelsius
            : maxTempCelsius // ignore: cast_nullable_to_non_nullable
                  as int,
        careInstructions: null == careInstructions
            ? _value._careInstructions
            : careInstructions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LaundryInfoImpl implements _LaundryInfo {
  const _$LaundryInfoImpl({
    @JsonKey(name: 'color_group') required this.colorGroup,
    @JsonKey(name: 'max_temp_celsius') required this.maxTempCelsius,
    @JsonKey(name: 'care_instructions')
    required final List<String> careInstructions,
  }) : _careInstructions = careInstructions;

  factory _$LaundryInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LaundryInfoImplFromJson(json);

  @override
  @JsonKey(name: 'color_group')
  final String colorGroup;
  @override
  @JsonKey(name: 'max_temp_celsius')
  final int maxTempCelsius;
  final List<String> _careInstructions;
  @override
  @JsonKey(name: 'care_instructions')
  List<String> get careInstructions {
    if (_careInstructions is EqualUnmodifiableListView)
      return _careInstructions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_careInstructions);
  }

  @override
  String toString() {
    return 'LaundryInfo(colorGroup: $colorGroup, maxTempCelsius: $maxTempCelsius, careInstructions: $careInstructions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LaundryInfoImpl &&
            (identical(other.colorGroup, colorGroup) ||
                other.colorGroup == colorGroup) &&
            (identical(other.maxTempCelsius, maxTempCelsius) ||
                other.maxTempCelsius == maxTempCelsius) &&
            const DeepCollectionEquality().equals(
              other._careInstructions,
              _careInstructions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    colorGroup,
    maxTempCelsius,
    const DeepCollectionEquality().hash(_careInstructions),
  );

  /// Create a copy of LaundryInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LaundryInfoImplCopyWith<_$LaundryInfoImpl> get copyWith =>
      __$$LaundryInfoImplCopyWithImpl<_$LaundryInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LaundryInfoImplToJson(this);
  }
}

abstract class _LaundryInfo implements LaundryInfo {
  const factory _LaundryInfo({
    @JsonKey(name: 'color_group') required final String colorGroup,
    @JsonKey(name: 'max_temp_celsius') required final int maxTempCelsius,
    @JsonKey(name: 'care_instructions')
    required final List<String> careInstructions,
  }) = _$LaundryInfoImpl;

  factory _LaundryInfo.fromJson(Map<String, dynamic> json) =
      _$LaundryInfoImpl.fromJson;

  @override
  @JsonKey(name: 'color_group')
  String get colorGroup;
  @override
  @JsonKey(name: 'max_temp_celsius')
  int get maxTempCelsius;
  @override
  @JsonKey(name: 'care_instructions')
  List<String> get careInstructions;

  /// Create a copy of LaundryInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LaundryInfoImplCopyWith<_$LaundryInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
