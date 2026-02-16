// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'styling_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StylingInfoImpl _$$StylingInfoImplFromJson(Map<String, dynamic> json) =>
    _$StylingInfoImpl(
      fit: json['fit'] as String,
      length: json['length'] as String,
      neckline: json['neckline'] as String,
      sleeveLength: json['sleeve_length'] as String,
      styleOccasions: (json['style_occasions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      seasonality: (json['seasonality'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      mood: (json['mood'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$StylingInfoImplToJson(_$StylingInfoImpl instance) =>
    <String, dynamic>{
      'fit': instance.fit,
      'length': instance.length,
      'neckline': instance.neckline,
      'sleeve_length': instance.sleeveLength,
      'style_occasions': instance.styleOccasions,
      'seasonality': instance.seasonality,
      'mood': instance.mood,
    };
