import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailPassword {
  const SignInWithEmailPassword(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AuthUserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }
}
