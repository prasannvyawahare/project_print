import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class CheckStorageExists {
  const CheckStorageExists(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, bool>> call() {
    return _repository.checkStorageExists();
  }
}
