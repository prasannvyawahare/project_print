import 'package:flutter_test/flutter_test.dart';
import 'package:project_print/features/home/domain/entities/print_category_entity.dart';
import 'package:project_print/features/print/data/models/print_config_model.dart';

void main() {
  group('PrintCategoryEntity', () {
    test('defaults paperQualities/sizes to empty lists', () {
      const entity = PrintCategoryEntity(
        id: '1',
        avatar: 'avatar.png',
        printType: 'Color',
        rate: 5,
        version: 1,
      );

      expect(entity.paperQualities, isEmpty);
      expect(entity.sizes, isEmpty);
    });

    test('supports value equality including nested lists', () {
      const quality = PaperQualityOption(
        id: 'q1',
        name: 'Glossy',
        gsm: '250',
        extra: 2,
      );
      const size = PaperSizeOption(
        id: 's1',
        name: 'A4',
        width: 210,
        height: 297,
        extra: 0,
      );

      const a = PrintCategoryEntity(
        id: '1',
        avatar: 'a.png',
        printType: 'Color',
        rate: 5,
        version: 1,
        paperQualities: [quality],
        sizes: [size],
      );
      const b = PrintCategoryEntity(
        id: '1',
        avatar: 'a.png',
        printType: 'Color',
        rate: 5,
        version: 1,
        paperQualities: [quality],
        sizes: [size],
      );
      const c = PrintCategoryEntity(
        id: '2',
        avatar: 'a.png',
        printType: 'Color',
        rate: 5,
        version: 1,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('props exposes all fields in order', () {
      const entity = PrintCategoryEntity(
        id: '1',
        avatar: 'a.png',
        printType: 'Color',
        rate: 5,
        version: 1,
      );

      expect(entity.props, [
        '1',
        'a.png',
        'Color',
        5,
        1,
        entity.paperQualities,
        entity.sizes,
      ]);
    });
  });
}
