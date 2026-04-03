import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/welcome_entity.dart';
import '../repositories/home_repository.dart';

class GetWelcomeMessage extends UseCase<WelcomeEntity, NoParams> {
  GetWelcomeMessage(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, WelcomeEntity>> call(NoParams params) {
    return _repository.getWelcomeMessage();
  }
}
