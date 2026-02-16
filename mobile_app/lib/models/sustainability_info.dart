import 'package:freezed_annotation/freezed_annotation.dart';

part 'sustainability_info.freezed.dart';
part 'sustainability_info.g.dart';

@freezed
class SustainabilityInfo with _$SustainabilityInfo {
  const factory SustainabilityInfo({
    required String brand,
    required double price,
    required String currency,
    @JsonKey(name: 'purchase_date') required String purchaseDate,
  }) = _SustainabilityInfo;

  factory SustainabilityInfo.fromJson(Map<String, dynamic> json) =>
      _$SustainabilityInfoFromJson(json);
}
