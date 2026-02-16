// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sustainability_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SustainabilityInfo _$SustainabilityInfoFromJson(Map<String, dynamic> json) {
  return _SustainabilityInfo.fromJson(json);
}

/// @nodoc
mixin _$SustainabilityInfo {
  String get brand => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_date')
  String get purchaseDate => throw _privateConstructorUsedError;

  /// Serializes this SustainabilityInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SustainabilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SustainabilityInfoCopyWith<SustainabilityInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SustainabilityInfoCopyWith<$Res> {
  factory $SustainabilityInfoCopyWith(
    SustainabilityInfo value,
    $Res Function(SustainabilityInfo) then,
  ) = _$SustainabilityInfoCopyWithImpl<$Res, SustainabilityInfo>;
  @useResult
  $Res call({
    String brand,
    double price,
    String currency,
    @JsonKey(name: 'purchase_date') String purchaseDate,
  });
}

/// @nodoc
class _$SustainabilityInfoCopyWithImpl<$Res, $Val extends SustainabilityInfo>
    implements $SustainabilityInfoCopyWith<$Res> {
  _$SustainabilityInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SustainabilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? brand = null,
    Object? price = null,
    Object? currency = null,
    Object? purchaseDate = null,
  }) {
    return _then(
      _value.copyWith(
            brand: null == brand
                ? _value.brand
                : brand // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            purchaseDate: null == purchaseDate
                ? _value.purchaseDate
                : purchaseDate // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SustainabilityInfoImplCopyWith<$Res>
    implements $SustainabilityInfoCopyWith<$Res> {
  factory _$$SustainabilityInfoImplCopyWith(
    _$SustainabilityInfoImpl value,
    $Res Function(_$SustainabilityInfoImpl) then,
  ) = __$$SustainabilityInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String brand,
    double price,
    String currency,
    @JsonKey(name: 'purchase_date') String purchaseDate,
  });
}

/// @nodoc
class __$$SustainabilityInfoImplCopyWithImpl<$Res>
    extends _$SustainabilityInfoCopyWithImpl<$Res, _$SustainabilityInfoImpl>
    implements _$$SustainabilityInfoImplCopyWith<$Res> {
  __$$SustainabilityInfoImplCopyWithImpl(
    _$SustainabilityInfoImpl _value,
    $Res Function(_$SustainabilityInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SustainabilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? brand = null,
    Object? price = null,
    Object? currency = null,
    Object? purchaseDate = null,
  }) {
    return _then(
      _$SustainabilityInfoImpl(
        brand: null == brand
            ? _value.brand
            : brand // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        purchaseDate: null == purchaseDate
            ? _value.purchaseDate
            : purchaseDate // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SustainabilityInfoImpl implements _SustainabilityInfo {
  const _$SustainabilityInfoImpl({
    required this.brand,
    required this.price,
    required this.currency,
    @JsonKey(name: 'purchase_date') required this.purchaseDate,
  });

  factory _$SustainabilityInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SustainabilityInfoImplFromJson(json);

  @override
  final String brand;
  @override
  final double price;
  @override
  final String currency;
  @override
  @JsonKey(name: 'purchase_date')
  final String purchaseDate;

  @override
  String toString() {
    return 'SustainabilityInfo(brand: $brand, price: $price, currency: $currency, purchaseDate: $purchaseDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SustainabilityInfoImpl &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, brand, price, currency, purchaseDate);

  /// Create a copy of SustainabilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SustainabilityInfoImplCopyWith<_$SustainabilityInfoImpl> get copyWith =>
      __$$SustainabilityInfoImplCopyWithImpl<_$SustainabilityInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SustainabilityInfoImplToJson(this);
  }
}

abstract class _SustainabilityInfo implements SustainabilityInfo {
  const factory _SustainabilityInfo({
    required final String brand,
    required final double price,
    required final String currency,
    @JsonKey(name: 'purchase_date') required final String purchaseDate,
  }) = _$SustainabilityInfoImpl;

  factory _SustainabilityInfo.fromJson(Map<String, dynamic> json) =
      _$SustainabilityInfoImpl.fromJson;

  @override
  String get brand;
  @override
  double get price;
  @override
  String get currency;
  @override
  @JsonKey(name: 'purchase_date')
  String get purchaseDate;

  /// Create a copy of SustainabilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SustainabilityInfoImplCopyWith<_$SustainabilityInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
