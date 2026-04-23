import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/print_categories_entity.dart';
import '../repositories/home_repository.dart';

class GetPrintCategories extends UseCase<PrintCategoriesEntity, NoParams> {
  GetPrintCategories(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, PrintCategoriesEntity>> call(NoParams params) {
    return _repository.getPrintCategories();
  }
}
