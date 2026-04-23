import 'package:equatable/equatable.dart';

class PrintCategoryEntity extends Equatable {
  const PrintCategoryEntity({
    required this.id,
    required this.avatar,
    required this.printType,
    required this.rate,
    required this.version,
  });

  final String id;
  final String avatar;
  final String printType;
  final int rate;
  final int version;

  @override
  List<Object?> get props => [id, avatar, printType, rate, version];
}
