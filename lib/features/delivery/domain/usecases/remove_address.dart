import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/address_repository.dart';

class RemoveAddressParams extends Equatable {
  const RemoveAddressParams({required this.addressId});

  final String addressId;

  @override
  List<Object?> get props => [addressId];
}

class RemoveAddress extends UseCase<String, RemoveAddressParams> {
  RemoveAddress(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, String>> call(RemoveAddressParams params) {
    return _repository.removeAddress(addressId: params.addressId);
  }
}
