// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basic_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BasicInfoImpl _$$BasicInfoImplFromJson(Map<String, dynamic> json) =>
    _$BasicInfoImpl(
      category: json['category'] as String,
      subCategory: json['sub_category'] as String,
      primaryColors: (json['primary_colors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      material: json['material'] as String,
      pattern: json['pattern'] as String,
    );

Map<String, dynamic> _$$BasicInfoImplToJson(_$BasicInfoImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'sub_category': instance.subCategory,
      'primary_colors': instance.primaryColors,
      'material': instance.material,
      'pattern': instance.pattern,
    };
