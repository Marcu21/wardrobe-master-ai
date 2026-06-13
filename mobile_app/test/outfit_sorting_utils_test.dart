import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/utils/outfit_sorting_utils.dart';

Map<String, dynamic> _item(String category, String subCategory) => {
      'basic_info': {'category': category, 'sub_category': subCategory},
    };

void main() {
  group('OutfitSortingUtils.sortOutfitItems', () {
    test('UT-O01: mixed outfit sorted top-to-bottom', () {
      final items = [
        _item('Shoes', 'Sneakers'),
        _item('Tops', 'T-Shirt'),
        _item('Bottoms', 'Jeans'),
        _item('Outerwear', 'Jacket'),
      ];
      final sorted = OutfitSortingUtils.sortOutfitItems(items);
      expect(sorted[0]['basic_info']['sub_category'], 'Jacket');
      expect(sorted[1]['basic_info']['sub_category'], 'T-Shirt');
      expect(sorted[2]['basic_info']['sub_category'], 'Jeans');
      expect(sorted[3]['basic_info']['sub_category'], 'Sneakers');
    });

    test('UT-O02: full outfit with headwear and midwear sorted correctly', () {
      final items = [
        _item('Tops', 'Hoodie'),
        _item('Accessories', 'Beanie'),
        _item('Shoes', 'Boots'),
        _item('Bottoms', 'Chinos'),
        _item('Tops', 'T-Shirt'),
      ];
      final sorted = OutfitSortingUtils.sortOutfitItems(items);
      expect(sorted[0]['basic_info']['sub_category'], 'Beanie');
      expect(sorted[1]['basic_info']['sub_category'], 'Hoodie');
      expect(sorted[2]['basic_info']['sub_category'], 'T-Shirt');
      expect(sorted[3]['basic_info']['sub_category'], 'Chinos');
      expect(sorted[4]['basic_info']['sub_category'], 'Boots');
    });

    test('UT-O03: single item list is returned unchanged', () {
      final items = [_item('Outerwear', 'Blazer')];
      final sorted = OutfitSortingUtils.sortOutfitItems(items);
      expect(sorted.length, 1);
      expect(sorted.first['basic_info']['sub_category'], 'Blazer');
    });

    test('UT-O04: empty list returns empty list', () {
      expect(OutfitSortingUtils.sortOutfitItems([]), isEmpty);
    });

    test('UT-O05: item without category fields falls back to score 3 (Top)', () {
      final noCategory = <String, dynamic>{};
      final sneakers = _item('Shoes', 'Sneakers');
      final sorted = OutfitSortingUtils.sortOutfitItems([sneakers, noCategory]);
      // score 3 (fallback) < score 5 (shoes), so unknown item comes first
      expect(sorted.first, noCategory);
      expect(sorted.last, sneakers);
    });
  });
}
