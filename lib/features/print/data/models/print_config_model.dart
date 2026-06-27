/// Models for the `print-config/get` endpoint.
///
/// A print config (e.g. "Color", "Photo Print") describes the paper qualities
/// and sizes available for that service. The Configure Print screen uses these
/// to populate its Paper Quality and Paper Size fields.
class PrintConfigModel {
  const PrintConfigModel({
    required this.id,
    required this.name,
    required this.paperQualities,
    required this.sizes,
    required this.baseRate,
  });

  factory PrintConfigModel.fromJson(Map<String, dynamic> json) {
    final options = json['options'] is Map<String, dynamic>
        ? json['options'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final qualities = options['paperQualities'];
    final sizes = options['sizes'];

    return PrintConfigModel(
      id: (json['_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
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
      baseRate: (pricing['baseRate'] as num?) ?? 0,
    );
  }

  final String id;
  final String name;
  final List<PaperQualityOption> paperQualities;
  final List<PaperSizeOption> sizes;
  final num baseRate;
}

class PaperQualityOption {
  const PaperQualityOption({
    required this.id,
    required this.name,
    required this.gsm,
    required this.extra,
  });

  factory PaperQualityOption.fromJson(Map<String, dynamic> json) {
    return PaperQualityOption(
      id: (json['_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      gsm: (json['gsm'] as String?) ?? '',
      extra: (json['extra'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'gsm': gsm,
    'extra': extra,
  };

  final String id;
  final String name;
  final String gsm;
  final num extra;

  /// Display label, e.g. "Glossy (250 GSM)".
  String get label => gsm.isEmpty ? name : '$name ($gsm)';
}

class PaperSizeOption {
  const PaperSizeOption({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.extra,
  });

  factory PaperSizeOption.fromJson(Map<String, dynamic> json) {
    return PaperSizeOption(
      id: (json['_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      width: (json['width'] as num?) ?? 0,
      height: (json['height'] as num?) ?? 0,
      extra: (json['extra'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'width': width,
    'height': height,
    'extra': extra,
  };

  final String id;
  final String name;
  final num width;
  final num height;
  final num extra;

  /// Display label, e.g. "A4 (210 × 297 mm)".
  String get label => (width > 0 && height > 0)
      ? '$name ($width × $height mm)'
      : name;
}
