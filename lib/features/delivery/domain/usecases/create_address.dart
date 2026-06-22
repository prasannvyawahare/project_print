import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address_entity.dart';
import '../repositories/address_repository.dart';

class CreateAddressParams extends Equatable {
  const CreateAddressParams({
    required this.addressType,
    required this.address,
    required this.flat,
    required this.landmark,
    required this.pincode,
  });

  final String addressType;
  final String address;
  final String flat;
  final String landmark;
  final int pincode;

  @override
  List<Object?> get props => [addressType, address, flat, landmark, pincode];
}

class CreateAddress extends UseCase<AddressEntity, CreateAddressParams> {
  CreateAddress(this._repository);

  final AddressRepository _repository;

  @override
  Future<Either<Failure, AddressEntity>> call(CreateAddressParams params) {
    return _repository.createAddress(
      addressType: params.addressType,
      address: params.address,
      flat: params.flat,
      landmark: params.landmark,
      pincode: params.pincode,
    );
  }
}
