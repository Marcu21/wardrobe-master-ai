// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laundry_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LaundryInfoImpl _$$LaundryInfoImplFromJson(Map<String, dynamic> json) =>
    _$LaundryInfoImpl(
      colorGroup: json['color_group'] as String,
      maxTempCelsius: (json['max_temp_celsius'] as num).toInt(),
      careInstructions: (json['care_instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$LaundryInfoImplToJson(_$LaundryInfoImpl instance) =>
    <String, dynamic>{
      'color_group': instance.colorGroup,
      'max_temp_celsius': instance.maxTempCelsius,
      'care_instructions': instance.careInstructions,
    };
