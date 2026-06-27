import '../../../print/data/models/print_config_model.dart';
import '../../domain/entities/print_category_entity.dart';

class PrintCategoryModel extends PrintCategoryEntity {
  const PrintCategoryModel({
    required super.id,
    required super.avatar,
    required super.printType,
    required super.rate,
    required super.version,
    super.paperQualities,
    super.sizes,
  });

  factory PrintCategoryModel.fromJson(Map<String, dynamic> json) {
    // Tolerant of two shapes: the `print-config/get` API (name + pricing.baseRate)
    // and the locally cached payload written by [toJson] (printType + rate).
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final options = json['options'] is Map<String, dynamic>
        ? json['options'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final qualities = options['paperQualities'];
    final sizes = options['sizes'];

    return PrintCategoryModel(
      id: (json['_id'] as String?) ?? '',
      avatar: (json['avatar'] as String?) ?? '',
      printType:
          (json['printType'] as String?) ?? (json['name'] as String?) ?? 'Unknown',
      rate:
          (json['rate'] as num?)?.toInt() ??
          (pricing['baseRate'] as num?)?.toInt() ??
          0,
      version: (json['__v'] as num?)?.toInt() ?? 0,
      paperQualities: qualities is List
          ? qualities
                .whereType<Map<String, dynamic>>()
                .map(PaperQualityOption.fromJson)
                .toList(growable: false)
          : const <PaperQualityOption>[],
      sizes: sizes is List
          ? sizes
                .whereType<Map<String, dynamic>>()
                .map(PaperSizeOption.fromJson)
                .toList(growable: false)
          : const <PaperSizeOption>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'avatar': avatar,
      'printType': printType,
      'rate': rate,
      '__v': version,
      // Preserve the same nested shape [fromJson] reads so the cache round-trips
      // the paper qualities/sizes used by the Configure Print dropdowns.
      'options': {
        'paperQualities': paperQualities
            .map((q) => q.toJson())
            .toList(growable: false),
        'sizes': sizes.map((s) => s.toJson()).toList(growable: false),
      },
    };
  }
}
