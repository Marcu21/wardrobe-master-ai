// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clothing_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClothingItemImpl _$$ClothingItemImplFromJson(Map<String, dynamic> json) =>
    _$ClothingItemImpl(
      id: json['item_id'] as String,
      imageUrl: json['image_url'] as String,
      basicInfo: BasicInfo.fromJson(json['basic_info'] as Map<String, dynamic>),
      stylingInfo: StylingInfo.fromJson(
        json['styling_info'] as Map<String, dynamic>,
      ),
      laundryInfo: LaundryInfo.fromJson(
        json['laundry_info'] as Map<String, dynamic>,
      ),
      sustainabilityInfo: SustainabilityInfo.fromJson(
        json['sustainability_info'] as Map<String, dynamic>,
      ),
      usageStats: UsageStats.fromJson(
        json['usage_stats'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$$ClothingItemImplToJson(_$ClothingItemImpl instance) =>
    <String, dynamic>{
      'item_id': instance.id,
      'image_url': instance.imageUrl,
      'basic_info': instance.basicInfo,
      'styling_info': instance.stylingInfo,
      'laundry_info': instance.laundryInfo,
      'sustainability_info': instance.sustainabilityInfo,
      'usage_stats': instance.usageStats,
    };
