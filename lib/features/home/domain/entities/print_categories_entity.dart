import 'package:equatable/equatable.dart';

import 'print_category_entity.dart';

class PrintCategoriesEntity extends Equatable {
  const PrintCategoriesEntity({
    required this.message,
    required this.categories,
  });

  final String message;
  final List<PrintCategoryEntity> categories;

  @override
  List<Object?> get props => [message, categories];
}
