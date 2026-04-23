import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/print_categories_entity.dart';
import '../entities/welcome_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, WelcomeEntity>> getWelcomeMessage();
  Future<Either<Failure, PrintCategoriesEntity>> getPrintCategories();
}
