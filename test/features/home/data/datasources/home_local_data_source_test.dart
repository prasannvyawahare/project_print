import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_print/features/home/data/datasources/home_local_data_source.dart';
import 'package:project_print/features/home/data/models/print_category_model.dart';
import 'package:project_print/features/home/data/models/print_categories_response_model.dart';

void main() {
  late HomeLocalDataSourceImpl dataSource;

  const category = PrintCategoryModel(
    id: 'id1',
    avatar: 'a.png',
    printType: 'Color',
    rate: 5,
    version: 1,
  );
  const response = PrintCategoriesResponseModel(
    message: 'ok',
    categories: [category],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = HomeLocalDataSourceImpl(preferences: prefs);
  });

  group('getCachedPrintCategories', () {
    test('returns null when nothing is cached', () {
      expect(dataSource.getCachedPrintCategories(), isNull);
    });

    test('returns null when cached payload is an empty string', () async {
      SharedPreferences.setMockInitialValues({
        'home_print_categories_payload_v3': '',
      });
      final prefs = await SharedPreferences.getInstance();
      final ds = HomeLocalDataSourceImpl(preferences: prefs);

      expect(ds.getCachedPrintCategories(), isNull);
    });

    test('returns null when cached payload is not a JSON map', () async {
      SharedPreferences.setMockInitialValues({
        'home_print_categories_payload_v3': '[1,2,3]',
      });
      final prefs = await SharedPreferences.getInstance();
      final ds = HomeLocalDataSourceImpl(preferences: prefs);

      expect(ds.getCachedPrintCategories(), isNull);
    });

    test('returns the decoded response after caching', () async {
      await dataSource.cachePrintCategories(response);

      final cached = dataSource.getCachedPrintCategories();
      expect(cached, isNotNull);
      expect(cached!.message, 'ok');
      expect(cached.categories, hasLength(1));
      expect(cached.categories.first.id, 'id1');
    });
  });

  group('hasFetchedCategoriesToday', () {
    test('returns false when nothing has been cached', () {
      expect(dataSource.hasFetchedCategoriesToday(), isFalse);
    });

    test('returns true right after caching', () async {
      await dataSource.cachePrintCategories(response);
      expect(dataSource.hasFetchedCategoriesToday(), isTrue);
    });

    test('returns false when the stored day does not match today', () async {
      SharedPreferences.setMockInitialValues({
        'home_print_categories_day_v3': '2000-01-01',
      });
      final prefs = await SharedPreferences.getInstance();
      final ds = HomeLocalDataSourceImpl(preferences: prefs);

      expect(ds.hasFetchedCategoriesToday(), isFalse);
    });
  });
}
