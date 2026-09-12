import 'package:flutter_test/flutter_test.dart';
import 'package:project_print/features/home/domain/entities/print_categories_entity.dart';
import 'package:project_print/features/home/domain/entities/print_category_entity.dart';

void main() {
  group('PrintCategoriesEntity', () {
    const category = PrintCategoryEntity(
      id: '1',
      avatar: 'a.png',
      printType: 'Color',
      rate: 5,
      version: 1,
    );

    test('supports value equality', () {
      const a = PrintCategoriesEntity(message: 'ok', categories: [category]);
      const b = PrintCategoriesEntity(message: 'ok', categories: [category]);
      const c = PrintCategoriesEntity(message: 'different', categories: [category]);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('props contains message and categories', () {
      const entity = PrintCategoriesEntity(message: 'ok', categories: [category]);
      expect(entity.props, ['ok', [category]]);
    });
  });
}
