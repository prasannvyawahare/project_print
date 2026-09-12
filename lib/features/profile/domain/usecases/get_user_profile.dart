import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfile extends UseCase<UserProfileEntity, NoParams> {
  GetUserProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserProfileEntity>> call(NoParams params) {
    return _repository.getProfile();
  }
}
