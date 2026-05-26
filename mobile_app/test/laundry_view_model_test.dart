import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/laundry/laundry_view_model.dart';

// ── Fixture helpers ───────────────────────────────────────────────────────────

Map<String, dynamic> _item({
  required String id,
  String category = 'Tops',
  String subCategory = 'T-Shirt',
}) =>
    {
      'id': id,
      'basic_info': {'category': category, 'sub_category': subCategory},
    };

void main() {
  group('LaundryViewModel — basket mutations', () {
    late LaundryViewModel vm;

    setUp(() {
      vm = LaundryViewModel.forTest();
      vm.allWardrobeItems = [
        _item(id: 'a', category: 'Tops', subCategory: 'T-Shirt'),
        _item(id: 'b', category: 'Bottoms', subCategory: 'Jeans'),
        _item(id: 'c', category: 'Tops', subCategory: 'Blouse'),
      ];
    });

    tearDown(() => vm.dispose());

    test('starts with an empty basket', () {
      expect(vm.basketItems, isEmpty);
    });

    test('filteredDocs initially equals all wardrobe items', () {
      expect(vm.filteredDocs.length, 3);
    });

    test('addToBasket moves item out of filteredDocs', () {
      final item = vm.allWardrobeItems.first;
      vm.addToBasket(item);

      expect(vm.basketItems.length, 1);
      expect(vm.basketItems.first['id'], 'a');
      expect(vm.filteredDocs.any((d) => d['id'] == 'a'), isFalse);
    });

    test('addToBasket does not affect other filteredDocs entries', () {
      vm.addToBasket(vm.allWardrobeItems[0]);
      expect(vm.filteredDocs.length, 2);
      expect(vm.filteredDocs.any((d) => d['id'] == 'b'), isTrue);
      expect(vm.filteredDocs.any((d) => d['id'] == 'c'), isTrue);
    });

    test('removeFromBasket restores item to filteredDocs', () {
      final item = vm.allWardrobeItems.first;
      vm.addToBasket(item);
      expect(vm.filteredDocs.any((d) => d['id'] == 'a'), isFalse);

      vm.removeFromBasket(item);
      expect(vm.basketItems, isEmpty);
      expect(vm.filteredDocs.any((d) => d['id'] == 'a'), isTrue);
    });

    test('basket holds multiple items independently', () {
      vm.addToBasket(vm.allWardrobeItems[0]);
      vm.addToBasket(vm.allWardrobeItems[1]);

      expect(vm.basketItems.length, 2);
      expect(vm.filteredDocs.length, 1);
      expect(vm.filteredDocs.first['id'], 'c');
    });
  });

  group('LaundryViewModel — category filtering', () {
    late LaundryViewModel vm;

    setUp(() {
      vm = LaundryViewModel.forTest();
      vm.allWardrobeItems = [
        _item(id: 'a', category: 'Tops', subCategory: 'T-Shirt'),
        _item(id: 'b', category: 'Bottoms', subCategory: 'Jeans'),
        _item(id: 'c', category: 'Tops', subCategory: 'Blouse'),
      ];
    });

    tearDown(() => vm.dispose());

    test('setCategory filters to matching items only', () {
      vm.setCategory('Tops');
      expect(vm.filteredDocs.length, 2);
      expect(vm.filteredDocs.every((d) => d['basic_info']['category'] == 'Tops'),
          isTrue);
    });

    test('setCategory with All restores full list', () {
      vm.setCategory('Bottoms');
      expect(vm.filteredDocs.length, 1);

      vm.setCategory('All');
      expect(vm.filteredDocs.length, 3);
    });

    test('setCategory resets sub-category filter to All', () {
      vm.setSubCategory('T-Shirt');
      vm.setCategory('Bottoms');
      expect(vm.selectedSubCategory, 'All');
    });

    test('setSubCategory narrows within the selected category', () {
      vm.setCategory('Tops');
      vm.setSubCategory('T-Shirt');

      expect(vm.filteredDocs.length, 1);
      expect(vm.filteredDocs.first['id'], 'a');
    });

    test('category filter excludes basket items from result', () {
      vm.addToBasket(vm.allWardrobeItems.firstWhere((d) => d['id'] == 'a'));
      vm.setCategory('Tops');

      // 'a' is in basket — only 'c' (Blouse) should appear
      expect(vm.filteredDocs.length, 1);
      expect(vm.filteredDocs.first['id'], 'c');
    });
  });
}
