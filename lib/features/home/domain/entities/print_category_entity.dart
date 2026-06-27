import 'package:equatable/equatable.dart';

import '../../../print/data/models/print_config_model.dart';

class PrintCategoryEntity extends Equatable {
  const PrintCategoryEntity({
    required this.id,
    required this.avatar,
    required this.printType,
    required this.rate,
    required this.version,
    this.paperQualities = const <PaperQualityOption>[],
    this.sizes = const <PaperSizeOption>[],
  });

  final String id;
  final String avatar;
  final String printType;
  final int rate;
  final int version;

  /// Paper qualities/sizes for this category, taken straight from the
  /// `print-config/get` response loaded on the home screen. Carried through so
  /// the Configure Print screen can populate its dropdowns without re-fetching.
  final List<PaperQualityOption> paperQualities;
  final List<PaperSizeOption> sizes;

  @override
  List<Object?> get props => [
    id,
    avatar,
    printType,
    rate,
    version,
    paperQualities,
    sizes,
  ];
}
