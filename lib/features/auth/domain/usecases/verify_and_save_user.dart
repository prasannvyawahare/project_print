import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class VerifyAndSaveUser {
  const VerifyAndSaveUser(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(VerifyAndSaveUserParams params) {
    return _repository.verifyAndSaveUser(
      email: params.email,
      mobile: params.mobile,
      authToken: params.authToken,
    );
  }
}

class VerifyAndSaveUserParams extends Equatable {
  const VerifyAndSaveUserParams({
    required this.email,
    required this.mobile,
    required this.authToken,
  });

  final String email;
  final String mobile;
  final String authToken;

  @override
  List<Object?> get props => [email, mobile, authToken];
}
