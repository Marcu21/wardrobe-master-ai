import 'package:freezed_annotation/freezed_annotation.dart';

part 'basic_info.freezed.dart';
part 'basic_info.g.dart';

@freezed
class BasicInfo with _$BasicInfo {
  const factory BasicInfo({
    required String category,
    @JsonKey(name: 'sub_category') required String subCategory,
    @JsonKey(name: 'primary_colors') required List<String> primaryColors,
    required String material,
    required String pattern,
  }) = _BasicInfo;

  factory BasicInfo.fromJson(Map<String, dynamic> json) =>
      _$BasicInfoFromJson(json);
}
