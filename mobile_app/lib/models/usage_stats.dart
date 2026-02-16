import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_stats.freezed.dart';
part 'usage_stats.g.dart';

@freezed
class UsageStats with _$UsageStats {
  const factory UsageStats({
    required double rating,
    @JsonKey(name: 'wear_count') required int wearCount,
    @JsonKey(name: 'last_worn_date') required String lastWornDate,
    required String status,
  }) = _UsageStats;

  factory UsageStats.fromJson(Map<String, dynamic> json) =>
      _$UsageStatsFromJson(json);
}
