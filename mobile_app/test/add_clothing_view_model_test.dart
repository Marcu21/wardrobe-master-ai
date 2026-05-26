import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/add_clothing/add_clothing_view_model.dart';

// ── Fixture ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _metadata() => {
      'basic_info': {
        'category': 'Tops',
        'sub_category': 'T-Shirt',
        'material': 'Cotton',
        'pattern': 'Solid',
        'primary_colors': ['White', 'Blue'],
      },
      'styling_info': {
        'fit': 'Regular',
        'length': 'Regular',
        'neckline': 'Crew',
        'sleeve_length': 'Short',
        'style_occasions': ['Casual', 'Sport'],
        'seasonality': ['Spring', 'Summer'],
      },
      'laundry_info': {
        'care_instructions': ['Machine wash cold', 'Tumble dry low'],
        'color_group': 'Light',
        'max_temp_celsius': 40,
      },
      'sustainability_info': {
        'brand': 'TestBrand',
        'price': '29.99',
        'currency': 'RON',
        'purchase_date': '2024-01-15',
      },
    };

void main() {
  // TextEditingController requires the Flutter binding.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('AddClothingViewModel — initial state', () {
    late AddClothingViewModel vm;

    setUp(() => vm = AddClothingViewModel());
    tearDown(() => vm.dispose());

    test('all text controllers start empty', () {
      expect(vm.categoryController.text, '');
      expect(vm.subCategoryController.text, '');
      expect(vm.materialController.text, '');
      expect(vm.primaryColorController.text, '');
      expect(vm.patternController.text, '');
      expect(vm.brandController.text, '');
      expect(vm.priceController.text, '');
      expect(vm.currencyController.text, '');
      expect(vm.purchaseDateController.text, '');
      expect(vm.fitController.text, '');
      expect(vm.careInstructionsController.text, '');
      expect(vm.colorGroupController.text, '');
      expect(vm.maxTempController.text, '');
    });

    test('starts with no images, no analysis, and no error', () {
      expect(vm.itemImage, isNull);
      expect(vm.tagImage, isNull);
      expect(vm.analysisResult, isNull);
      expect(vm.errorMessage, isNull);
      expect(vm.isAnalyzing, isFalse);
    });

    test('selectedWardrobeId reflects wardrobeId constructor argument', () {
      final vm2 = AddClothingViewModel(wardrobeId: 'wardrobe-abc');
      expect(vm2.selectedWardrobeId, 'wardrobe-abc');
      vm2.dispose();
    });
  });

  group('AddClothingViewModel — form population from metadata', () {
    late AddClothingViewModel vm;

    setUp(() {
      vm = AddClothingViewModel(
        initialAnalysisResult: {'metadata': _metadata()},
        initialImageFile: File('dummy.jpg'),
      );
    });
    tearDown(() => vm.dispose());

    test('populates basic info controllers correctly', () {
      expect(vm.categoryController.text, 'Tops');
      expect(vm.subCategoryController.text, 'T-Shirt');
      expect(vm.materialController.text, 'Cotton');
      expect(vm.patternController.text, 'Solid');
      expect(vm.primaryColorController.text, 'White, Blue');
    });

    test('populates styling info controllers correctly', () {
      expect(vm.fitController.text, 'Regular');
      expect(vm.necklineController.text, 'Crew');
      expect(vm.sleeveLengthController.text, 'Short');
      expect(vm.styleOccasionsController.text, 'Casual, Sport');
      expect(vm.seasonalityController.text, 'Spring, Summer');
    });

    test('populates laundry info controllers correctly', () {
      expect(vm.careInstructionsController.text,
          'Machine wash cold\nTumble dry low');
      expect(vm.colorGroupController.text, 'Light');
      expect(vm.maxTempController.text, '40');
    });

    test('populates sustainability info controllers correctly', () {
      expect(vm.brandController.text, 'TestBrand');
      expect(vm.priceController.text, '29.99');
      expect(vm.currencyController.text, 'RON');
      expect(vm.purchaseDateController.text, '2024-01-15');
    });

    test('analysisResult and itemImage are stored', () {
      expect(vm.analysisResult, isNotNull);
      expect(vm.itemImage, isNotNull);
    });
  });

  group('AddClothingViewModel — state mutations', () {
    late AddClothingViewModel vm;

    setUp(() {
      vm = AddClothingViewModel(
        initialAnalysisResult: {'metadata': _metadata()},
        initialImageFile: File('dummy.jpg'),
      );
    });
    tearDown(() => vm.dispose());

    test('resetAnalysis clears analysisResult and itemImage', () {
      expect(vm.analysisResult, isNotNull);
      vm.resetAnalysis();
      expect(vm.analysisResult, isNull);
      expect(vm.itemImage, isNull);
      expect(vm.tagImage, isNull);
    });

    test('clearItemImage nullifies itemImage without touching tag', () {
      vm.clearItemImage();
      expect(vm.itemImage, isNull);
      // tagImage was null initially — still null
      expect(vm.tagImage, isNull);
    });

    test('clearTagImage nullifies tagImage without touching item', () {
      vm.clearTagImage();
      expect(vm.tagImage, isNull);
      expect(vm.itemImage, isNotNull); // initial item image preserved
    });

    test('setWardrobeId updates selectedWardrobeId', () {
      expect(vm.selectedWardrobeId, isNull);
      vm.setWardrobeId('wid-42');
      expect(vm.selectedWardrobeId, 'wid-42');
    });

    test('setWardrobeId accepts null to clear the selection', () {
      vm.setWardrobeId('wid-42');
      vm.setWardrobeId(null);
      expect(vm.selectedWardrobeId, isNull);
    });

    test('clearError nullifies errorMessage', () {
      // Directly poke the internal state via the public clearError path.
      // (errorMessage is only set by analyzeItem which we don't trigger here.)
      vm.clearError(); // no-op when null — must not throw
      expect(vm.errorMessage, isNull);
    });

    test('setWardrobeId notifies listeners', () {
      int count = 0;
      vm.addListener(() => count++);
      vm.setWardrobeId('w1');
      expect(count, 1);
    });
  });
}
