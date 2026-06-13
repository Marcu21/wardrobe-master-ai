import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/laundry_service.dart';

Map<String, dynamic> _item({
  String colorGroup = 'Color',
  int? maxTemp,
  String material = '',
  String category = 'Tops',
  String subCategory = 'T-Shirt',
  List<String> careInstructions = const [],
}) =>
    <String, dynamic>{
      'basic_info': <String, dynamic>{
        'category': category,
        'sub_category': subCategory,
        'material': material,
      },
      'laundry_info': <String, dynamic>{
        'color_group': colorGroup,
        if (maxTemp != null) 'max_temp_celsius': maxTemp,
        'care_instructions': careInstructions,
      },
      'sustainability_info': <String, dynamic>{},
    };

void main() {
  final service = LaundryService();

  // ── analyzeBasket ──────────────────────────────────────────────────────────

  group('LaundryService.analyzeBasket', () {
    test('UT-L01: empty basket returns Safe with no alerts', () {
      final result = service.analyzeBasket([]);
      expect(result.status, LaundryStatus.Safe);
      expect(result.alerts, isEmpty);
    });

    test('UT-L02: single Dark item above 30°C returns Safe with no alerts', () {
      final result = service.analyzeBasket([
        _item(colorGroup: 'Dark', maxTemp: 60),
      ]);
      expect(result.status, LaundryStatus.Safe);
      expect(result.alerts, isEmpty);
    });

    test('UT-L03: single Dark item at 30°C emits cold wash alert', () {
      final result = service.analyzeBasket([
        _item(colorGroup: 'Dark', maxTemp: 30),
      ]);
      expect(result.status, LaundryStatus.Safe);
      expect(result.recommendedTemp, 30);
      expect(result.alerts.any((a) => a.contains('Cold wash')), isTrue);
    });

    test('UT-L04: Dark + Light triggers Critical — color bleeding risk', () {
      final result = service.analyzeBasket([
        _item(colorGroup: 'Dark', maxTemp: 40),
        _item(colorGroup: 'Light', maxTemp: 60),
      ]);
      expect(result.status, LaundryStatus.Critical);
      expect(result.recommendedTemp, 40);
      expect(result.alerts.any((a) => a.contains('Color bleeding')), isTrue);
    });

    test('UT-L05: Color + Light triggers Warning — pigment transfer', () {
      final result = service.analyzeBasket([
        _item(colorGroup: 'Color'),
        _item(colorGroup: 'Light'),
      ]);
      expect(result.status, LaundryStatus.Warning);
      expect(result.alerts.any((a) => a.contains('transfer pigment')), isTrue);
    });

    test('UT-L06: heavy material + delicate material triggers Warning', () {
      final result = service.analyzeBasket([
        _item(material: 'denim'),
        _item(material: 'silk'),
      ]);
      expect(result.status, LaundryStatus.Warning);
      expect(result.alerts.any((a) => a.contains('damage delicate')), isTrue);
    });

    test('UT-L07: shoes mixed with regular clothes triggers Critical hygiene', () {
      final result = service.analyzeBasket([
        _item(category: 'Shoes', subCategory: 'Sneakers'),
        _item(),
      ]);
      expect(result.status, LaundryStatus.Critical);
      expect(result.alerts.any((a) => a.contains('HYGIENE RISK')), isTrue);
    });

    test('UT-L08: footwear alone triggers Warning and caps temp at 30°C', () {
      final result = service.analyzeBasket([
        _item(category: 'Shoes', subCategory: 'Sneakers', maxTemp: 60),
      ]);
      expect(result.status, LaundryStatus.Warning);
      expect(result.recommendedTemp, 30);
      expect(result.alerts.any((a) => a.contains('laces')), isTrue);
    });

    test('UT-L09: composite basket accumulates all alerts; temp = min(40, 60)', () {
      final result = service.analyzeBasket([
        _item(colorGroup: 'Dark', maxTemp: 40),
        _item(colorGroup: 'Light', maxTemp: 60),
        _item(category: 'Shoes', subCategory: 'Sneakers'),
        _item(material: 'denim'),
        _item(material: 'silk'),
      ]);
      expect(result.status, LaundryStatus.Critical);
      expect(result.recommendedTemp, 40);
      expect(result.alerts.length, greaterThanOrEqualTo(3));
    });

    test('UT-L10: max_temp_celsius stored as String is parsed correctly', () {
      final item = <String, dynamic>{
        'basic_info': <String, dynamic>{'category': 'Tops', 'sub_category': 'T-Shirt', 'material': ''},
        'laundry_info': <String, dynamic>{
          'color_group': 'Dark',
          'max_temp_celsius': '40',
          'care_instructions': <String>[],
        },
        'sustainability_info': <String, dynamic>{},
      };
      final result = service.analyzeBasket([item]);
      expect(result.recommendedTemp, 40);
    });

    test('UT-L11: dry clean only item triggers Critical', () {
      final result = service.analyzeBasket([
        _item(careInstructions: ['Dry clean only']),
      ]);
      expect(result.status, LaundryStatus.Critical);
      expect(result.alerts.any((a) => a.contains('dry clean')), isTrue);
    });

    test('UT-L12: do not wash item triggers Critical', () {
      final result = service.analyzeBasket([
        _item(careInstructions: ['Do not wash']),
      ]);
      expect(result.status, LaundryStatus.Critical);
      expect(result.alerts.any((a) => a.contains('cannot be washed')), isTrue);
    });

    test('UT-L13: hand wash only item triggers Warning', () {
      final result = service.analyzeBasket([
        _item(careInstructions: ['Hand wash only']),
      ]);
      expect(result.status, LaundryStatus.Warning);
      expect(result.alerts.any((a) => a.contains('hand washing')), isTrue);
    });
  });

  // ── suggestOptimalSplits ───────────────────────────────────────────────────

  group('LaundryService.suggestOptimalSplits', () {
    test('UT-S01: empty basket returns empty list', () {
      expect(service.suggestOptimalSplits([]), isEmpty);
    });

    test('UT-S02: only sneakers → Footwear Load', () {
      final loads = service.suggestOptimalSplits([
        _item(category: 'Shoes', subCategory: 'Sneakers'),
      ]);
      expect(loads.length, 1);
      expect(loads.first.title, 'Footwear Load');
    });

    test('UT-S03: silk + lace → Delicates Load', () {
      final loads = service.suggestOptimalSplits([
        _item(material: 'silk'),
        _item(material: 'lace'),
      ]);
      expect(loads.length, 1);
      expect(loads.first.title, 'Delicates Load');
    });

    test('UT-S04: Dark + Light + Color → Whites & Lights + Darks & Colors (2 loads)', () {
      final loads = service.suggestOptimalSplits([
        _item(colorGroup: 'Dark'),
        _item(colorGroup: 'Light'),
        _item(colorGroup: 'Color'),
      ]);
      final titles = loads.map((l) => l.title).toList();
      expect(loads.length, 2);
      expect(titles, containsAll(['Whites & Lights Load', 'Darks & Colors Load']));
    });

    test('UT-S05: mixed basket → Footwear, Delicates, Whites & Lights, Darks & Colors', () {
      final loads = service.suggestOptimalSplits([
        _item(category: 'Shoes', subCategory: 'Sneakers'),
        _item(material: 'silk'),
        _item(colorGroup: 'Dark', material: 'denim'),
        _item(colorGroup: 'Light'),
        _item(colorGroup: 'Color'),
      ]);
      final titles = loads.map((l) => l.title).toList();
      expect(titles, containsAll([
        'Footwear Load',
        'Delicates Load',
        'Whites & Lights Load',
        'Darks & Colors Load',
      ]));
      expect(loads.length, 4);
    });

    test('UT-S06: undefined color_group falls back to Darks & Colors Load', () {
      final item = <String, dynamic>{
        'basic_info': <String, dynamic>{'category': 'Tops', 'sub_category': 'T-Shirt', 'material': ''},
        'laundry_info': <String, dynamic>{'care_instructions': <String>[]},
        'sustainability_info': <String, dynamic>{},
      };
      final loads = service.suggestOptimalSplits([item]);
      expect(loads.length, 1);
      expect(loads.first.title, 'Darks & Colors Load');
    });

    test('UT-S07: dry clean only item → Dry Clean Only load', () {
      final loads = service.suggestOptimalSplits([
        _item(careInstructions: ['Dry clean only']),
      ]);
      expect(loads.first.title, 'Dry Clean Only');
    });

    test('UT-S08: do not wash item → Special Care load', () {
      final loads = service.suggestOptimalSplits([
        _item(careInstructions: ['Do not wash']),
      ]);
      expect(loads.first.title, 'Special Care');
    });

    test('UT-S09: hand wash only item → Hand Wash Only load', () {
      final loads = service.suggestOptimalSplits([
        _item(careInstructions: ['Hand wash only']),
      ]);
      expect(loads.first.title, 'Hand Wash Only');
    });
  });
}
