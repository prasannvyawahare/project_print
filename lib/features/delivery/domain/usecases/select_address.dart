import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/address_repository.dart';

class SelectAddressParams extends Equatable {
  const SelectAddressParams({required this.addressId});

  final String addressId;

  @override
  List<Object?> get props => [addressId];
}

class SelectAddress extends UseCase<String, SelectAddressParams> {
  SelectAddress(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, String>> call(SelectAddressParams params) {
    return _repository.selectAddress(addressId: params.addressId);
  }
}
