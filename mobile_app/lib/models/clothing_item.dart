import 'package:freezed_annotation/freezed_annotation.dart';
import 'basic_info.dart';
import 'styling_info.dart';
import 'laundry_info.dart';
import 'sustainability_info.dart';
import 'usage_stats.dart';

part 'clothing_item.freezed.dart';
part 'clothing_item.g.dart';

@freezed
class ClothingItem with _$ClothingItem {
  const factory ClothingItem({
    @JsonKey(name: 'item_id') required String id,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'basic_info') required BasicInfo basicInfo,
    @JsonKey(name: 'styling_info') required StylingInfo stylingInfo,
    @JsonKey(name: 'laundry_info') required LaundryInfo laundryInfo,
    @JsonKey(name: 'sustainability_info') required SustainabilityInfo sustainabilityInfo,
    @JsonKey(name: 'usage_stats') required UsageStats usageStats,
  }) = _ClothingItem;

  factory ClothingItem.fromJson(Map<String, dynamic> json) =>
      _$ClothingItemFromJson(json);
}
