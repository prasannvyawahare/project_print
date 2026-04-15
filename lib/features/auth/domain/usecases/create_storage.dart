import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class CreateStorage {
  const CreateStorage(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(String userId) {
    return _repository.createStorage(userId);
  }
}
