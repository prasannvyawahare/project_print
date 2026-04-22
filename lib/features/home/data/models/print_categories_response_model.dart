import '../../domain/entities/print_categories_entity.dart';
import 'print_category_model.dart';

class PrintCategoriesResponseModel extends PrintCategoriesEntity {
  const PrintCategoriesResponseModel({
    required super.message,
    required super.categories,
  });

  factory PrintCategoriesResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final categories = data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .map(PrintCategoryModel.fromJson)
              .toList(growable: false)
        : const <PrintCategoryModel>[];

    return PrintCategoriesResponseModel(
      message: (json['message'] as String?) ?? 'Categories fetched',
      categories: categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': true,
      'message': message,
      'data': categories
          .map((category) => (category as PrintCategoryModel).toJson())
          .toList(growable: false),
    };
  }
}
