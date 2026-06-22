import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address_entity.dart';
import '../repositories/address_repository.dart';

class GetAddresses extends UseCase<List<AddressEntity>, NoParams> {
  GetAddresses(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, List<AddressEntity>>> call(NoParams params) {
    return _repository.getAddresses();
  }
}
