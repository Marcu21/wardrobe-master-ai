import 'package:freezed_annotation/freezed_annotation.dart';

part 'laundry_info.freezed.dart';
part 'laundry_info.g.dart';

@freezed
class LaundryInfo with _$LaundryInfo {
  const factory LaundryInfo({
    @JsonKey(name: 'color_group') required String colorGroup,
    @JsonKey(name: 'max_temp_celsius') required int maxTempCelsius,
    @JsonKey(name: 'care_instructions') required List<String> careInstructions,
  }) = _LaundryInfo;

  factory LaundryInfo.fromJson(Map<String, dynamic> json) =>
      _$LaundryInfoFromJson(json);
}
