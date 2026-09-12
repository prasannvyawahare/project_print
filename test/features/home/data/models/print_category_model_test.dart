import 'package:flutter_test/flutter_test.dart';
import 'package:project_print/features/home/data/models/print_category_model.dart';

void main() {
  group('PrintCategoryModel.fromJson', () {
    test('parses the print-config/get API shape (name + pricing.baseRate)', () {
      final model = PrintCategoryModel.fromJson({
        '_id': 'id1',
        'avatar': 'avatar.png',
        'name': 'Color',
        'pricing': {'baseRate': 7},
        '__v': 3,
        'options': {
          'paperQualities': [
            {'_id': 'q1', 'name': 'Glossy', 'gsm': '250', 'extra': 2},
          ],
          'sizes': [
            {'_id': 's1', 'name': 'A4', 'width': 210, 'height': 297, 'extra': 0},
          ],
        },
      });

      expect(model.id, 'id1');
      expect(model.avatar, 'avatar.png');
      expect(model.printType, 'Color');
      expect(model.rate, 7);
      expect(model.version, 3);
      expect(model.paperQualities, hasLength(1));
      expect(model.paperQualities.first.name, 'Glossy');
      expect(model.sizes, hasLength(1));
      expect(model.sizes.first.name, 'A4');
    });

    test('parses the locally cached shape (printType + rate)', () {
      final model = PrintCategoryModel.fromJson({
        '_id': 'id1',
        'avatar': 'avatar.png',
        'printType': 'Binding',
        'rate': 12,
        '__v': 1,
      });

      expect(model.printType, 'Binding');
      expect(model.rate, 12);
      expect(model.paperQualities, isEmpty);
      expect(model.sizes, isEmpty);
    });

    test('prefers printType over name, and rate over pricing.baseRate', () {
      final model = PrintCategoryModel.fromJson({
        'printType': 'Preferred',
        'name': 'Ignored',
        'rate': 99,
        'pricing': {'baseRate': 1},
      });

      expect(model.printType, 'Preferred');
      expect(model.rate, 99);
    });

    test('defaults missing fields', () {
      final model = PrintCategoryModel.fromJson(const {});

      expect(model.id, '');
      expect(model.avatar, '');
      expect(model.printType, 'Unknown');
      expect(model.rate, 0);
      expect(model.version, 0);
      expect(model.paperQualities, isEmpty);
      expect(model.sizes, isEmpty);
    });

    test('ignores non-map entries and non-list options', () {
      final model = PrintCategoryModel.fromJson({
        'options': {
          'paperQualities': ['not-a-map', 5],
          'sizes': 'not-a-list',
        },
      });

      expect(model.paperQualities, isEmpty);
      expect(model.sizes, isEmpty);
    });

    test('ignores non-map pricing/options', () {
      final model = PrintCategoryModel.fromJson({
        'pricing': 'invalid',
        'options': 'invalid',
      });

      expect(model.rate, 0);
      expect(model.paperQualities, isEmpty);
      expect(model.sizes, isEmpty);
    });
  });

  group('PrintCategoryModel.toJson', () {
    test('round-trips through fromJson preserving nested options', () {
      const model = PrintCategoryModel(
        id: 'id1',
        avatar: 'a.png',
        printType: 'Color',
        rate: 5,
        version: 2,
      );

      final json = model.toJson();
      expect(json['_id'], 'id1');
      expect(json['avatar'], 'a.png');
      expect(json['printType'], 'Color');
      expect(json['rate'], 5);
      expect(json['__v'], 2);
      expect(json['options'], {'paperQualities': [], 'sizes': []});

      final decoded = PrintCategoryModel.fromJson(json);
      expect(decoded.id, model.id);
      expect(decoded.printType, model.printType);
      expect(decoded.rate, model.rate);
      expect(decoded.version, model.version);
    });
  });
}
