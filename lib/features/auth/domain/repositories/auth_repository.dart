import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUserEntity>> signInWithGoogle();
  Future<Either<Failure, Unit>> verifyAndSaveUser({
    required String email,
    required String mobile,
    required String authToken,
  });
  Future<Either<Failure, Unit>> signInWithApple();
  Future<Either<Failure, Unit>> signOut();
}
