import 'package:flutter_test/flutter_test.dart';
import 'package:project_print/features/home/data/models/print_categories_response_model.dart';
import 'package:project_print/features/home/data/models/print_category_model.dart';

void main() {
  group('PrintCategoriesResponseModel.fromJson', () {
    test('parses message and categories from data list', () {
      final model = PrintCategoriesResponseModel.fromJson({
        'message': 'Fetched ok',
        'data': [
          {'_id': 'a', 'printType': 'Color', 'rate': 5, '__v': 0},
          {'_id': 'b', 'printType': 'Binding', 'rate': 10, '__v': 0},
        ],
      });

      expect(model.message, 'Fetched ok');
      expect(model.categories, hasLength(2));
      expect(model.categories.first.id, 'a');
    });

    test('defaults message when missing', () {
      final model = PrintCategoriesResponseModel.fromJson(const {});
      expect(model.message, 'Categories fetched');
      expect(model.categories, isEmpty);
    });

    test('ignores non-map entries in data and non-list data', () {
      final model = PrintCategoriesResponseModel.fromJson({
        'data': ['not-a-map', 5],
      });
      expect(model.categories, isEmpty);

      final model2 = PrintCategoriesResponseModel.fromJson({'data': 'nope'});
      expect(model2.categories, isEmpty);
    });
  });

  group('PrintCategoriesResponseModel.toJson', () {
    test('serializes categories using PrintCategoryModel.toJson', () {
      const category = PrintCategoryModel(
        id: 'a',
        avatar: '',
        printType: 'Color',
        rate: 5,
        version: 0,
      );
      const model = PrintCategoriesResponseModel(
        message: 'ok',
        categories: [category],
      );

      final json = model.toJson();
      expect(json['success'], true);
      expect(json['message'], 'ok');
      expect(json['data'], [category.toJson()]);
    });

    test('round-trips through fromJson', () {
      const category = PrintCategoryModel(
        id: 'a',
        avatar: '',
        printType: 'Color',
        rate: 5,
        version: 0,
      );
      const model = PrintCategoriesResponseModel(
        message: 'ok',
        categories: [category],
      );

      final decoded = PrintCategoriesResponseModel.fromJson(model.toJson());
      expect(decoded.message, 'ok');
      expect(decoded.categories, hasLength(1));
      expect(decoded.categories.first.id, 'a');
    });
  });
}
