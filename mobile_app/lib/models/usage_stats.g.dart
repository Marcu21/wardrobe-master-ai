// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UsageStatsImpl _$$UsageStatsImplFromJson(Map<String, dynamic> json) =>
    _$UsageStatsImpl(
      rating: (json['rating'] as num).toDouble(),
      wearCount: (json['wear_count'] as num).toInt(),
      lastWornDate: json['last_worn_date'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$$UsageStatsImplToJson(_$UsageStatsImpl instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'wear_count': instance.wearCount,
      'last_worn_date': instance.lastWornDate,
      'status': instance.status,
    };
