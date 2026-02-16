// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UsageStats _$UsageStatsFromJson(Map<String, dynamic> json) {
  return _UsageStats.fromJson(json);
}

/// @nodoc
mixin _$UsageStats {
  double get rating => throw _privateConstructorUsedError;
  @JsonKey(name: 'wear_count')
  int get wearCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_worn_date')
  String get lastWornDate => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this UsageStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UsageStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UsageStatsCopyWith<UsageStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UsageStatsCopyWith<$Res> {
  factory $UsageStatsCopyWith(
    UsageStats value,
    $Res Function(UsageStats) then,
  ) = _$UsageStatsCopyWithImpl<$Res, UsageStats>;
  @useResult
  $Res call({
    double rating,
    @JsonKey(name: 'wear_count') int wearCount,
    @JsonKey(name: 'last_worn_date') String lastWornDate,
    String status,
  });
}

/// @nodoc
class _$UsageStatsCopyWithImpl<$Res, $Val extends UsageStats>
    implements $UsageStatsCopyWith<$Res> {
  _$UsageStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UsageStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rating = null,
    Object? wearCount = null,
    Object? lastWornDate = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            wearCount: null == wearCount
                ? _value.wearCount
                : wearCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastWornDate: null == lastWornDate
                ? _value.lastWornDate
                : lastWornDate // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UsageStatsImplCopyWith<$Res>
    implements $UsageStatsCopyWith<$Res> {
  factory _$$UsageStatsImplCopyWith(
    _$UsageStatsImpl value,
    $Res Function(_$UsageStatsImpl) then,
  ) = __$$UsageStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double rating,
    @JsonKey(name: 'wear_count') int wearCount,
    @JsonKey(name: 'last_worn_date') String lastWornDate,
    String status,
  });
}

/// @nodoc
class __$$UsageStatsImplCopyWithImpl<$Res>
    extends _$UsageStatsCopyWithImpl<$Res, _$UsageStatsImpl>
    implements _$$UsageStatsImplCopyWith<$Res> {
  __$$UsageStatsImplCopyWithImpl(
    _$UsageStatsImpl _value,
    $Res Function(_$UsageStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UsageStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rating = null,
    Object? wearCount = null,
    Object? lastWornDate = null,
    Object? status = null,
  }) {
    return _then(
      _$UsageStatsImpl(
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        wearCount: null == wearCount
            ? _value.wearCount
            : wearCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastWornDate: null == lastWornDate
            ? _value.lastWornDate
            : lastWornDate // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UsageStatsImpl implements _UsageStats {
  const _$UsageStatsImpl({
    required this.rating,
    @JsonKey(name: 'wear_count') required this.wearCount,
    @JsonKey(name: 'last_worn_date') required this.lastWornDate,
    required this.status,
  });

  factory _$UsageStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UsageStatsImplFromJson(json);

  @override
  final double rating;
  @override
  @JsonKey(name: 'wear_count')
  final int wearCount;
  @override
  @JsonKey(name: 'last_worn_date')
  final String lastWornDate;
  @override
  final String status;

  @override
  String toString() {
    return 'UsageStats(rating: $rating, wearCount: $wearCount, lastWornDate: $lastWornDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UsageStatsImpl &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.wearCount, wearCount) ||
                other.wearCount == wearCount) &&
            (identical(other.lastWornDate, lastWornDate) ||
                other.lastWornDate == lastWornDate) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, rating, wearCount, lastWornDate, status);

  /// Create a copy of UsageStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UsageStatsImplCopyWith<_$UsageStatsImpl> get copyWith =>
      __$$UsageStatsImplCopyWithImpl<_$UsageStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UsageStatsImplToJson(this);
  }
}

abstract class _UsageStats implements UsageStats {
  const factory _UsageStats({
    required final double rating,
    @JsonKey(name: 'wear_count') required final int wearCount,
    @JsonKey(name: 'last_worn_date') required final String lastWornDate,
    required final String status,
  }) = _$UsageStatsImpl;

  factory _UsageStats.fromJson(Map<String, dynamic> json) =
      _$UsageStatsImpl.fromJson;

  @override
  double get rating;
  @override
  @JsonKey(name: 'wear_count')
  int get wearCount;
  @override
  @JsonKey(name: 'last_worn_date')
  String get lastWornDate;
  @override
  String get status;

  /// Create a copy of UsageStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UsageStatsImplCopyWith<_$UsageStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
