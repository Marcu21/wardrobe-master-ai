import 'package:freezed_annotation/freezed_annotation.dart';

part 'styling_info.freezed.dart';
part 'styling_info.g.dart';

@freezed
class StylingInfo with _$StylingInfo {
  const factory StylingInfo({
    required String fit,
    required String length,
    required String neckline,
    @JsonKey(name: 'sleeve_length') required String sleeveLength,
    @JsonKey(name: 'style_occasions') required List<String> styleOccasions,
    required List<String> seasonality,
    required List<String> mood,
  }) = _StylingInfo;

  factory StylingInfo.fromJson(Map<String, dynamic> json) =>
      _$StylingInfoFromJson(json);
}
