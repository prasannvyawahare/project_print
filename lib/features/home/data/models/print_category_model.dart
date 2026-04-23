import '../../domain/entities/print_category_entity.dart';

class PrintCategoryModel extends PrintCategoryEntity {
  const PrintCategoryModel({
    required super.id,
    required super.avatar,
    required super.printType,
    required super.rate,
    required super.version,
  });

  factory PrintCategoryModel.fromJson(Map<String, dynamic> json) {
    return PrintCategoryModel(
      id: (json['_id'] as String?) ?? '',
      avatar: (json['avatar'] as String?) ?? '',
      printType: (json['printType'] as String?) ?? 'Unknown',
      rate: (json['rate'] as num?)?.toInt() ?? 0,
      version: (json['__v'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'avatar': avatar,
      'printType': printType,
      'rate': rate,
      '__v': version,
    };
  }
}
