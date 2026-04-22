import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/print_categories_response_model.dart';

abstract class HomeLocalDataSource {
  Future<void> cachePrintCategories(PrintCategoriesResponseModel response);
  PrintCategoriesResponseModel? getCachedPrintCategories();
  bool hasFetchedCategoriesToday();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _categoriesPayloadKey =
      'home_print_categories_payload_v1';
  static const String _categoriesFetchDayKey = 'home_print_categories_day_v1';

  final SharedPreferences _preferences;

  @override
  Future<void> cachePrintCategories(
    PrintCategoriesResponseModel response,
  ) async {
    await _preferences.setString(
      _categoriesPayloadKey,
      jsonEncode(response.toJson()),
    );
    await _preferences.setString(_categoriesFetchDayKey, _todayCacheKey);
  }

  @override
  PrintCategoriesResponseModel? getCachedPrintCategories() {
    final payload = _preferences.getString(_categoriesPayloadKey);
    if (payload == null || payload.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return PrintCategoriesResponseModel.fromJson(decoded);
  }

  @override
  bool hasFetchedCategoriesToday() {
    return _preferences.getString(_categoriesFetchDayKey) == _todayCacheKey;
  }

  String get _todayCacheKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
