// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sustainability_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SustainabilityInfoImpl _$$SustainabilityInfoImplFromJson(
  Map<String, dynamic> json,
) => _$SustainabilityInfoImpl(
  brand: json['brand'] as String,
  price: (json['price'] as num).toDouble(),
  currency: json['currency'] as String,
  purchaseDate: json['purchase_date'] as String,
);

Map<String, dynamic> _$$SustainabilityInfoImplToJson(
  _$SustainabilityInfoImpl instance,
) => <String, dynamic>{
  'brand': instance.brand,
  'price': instance.price,
  'currency': instance.currency,
  'purchase_date': instance.purchaseDate,
};
