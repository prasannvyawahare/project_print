import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/address_entity.dart';

abstract class AddressRepository {
  Future<Either<Failure, AddressEntity>> createAddress({
    required String addressType,
    required String address,
    required String flat,
    required String landmark,
    required int pincode,
  });

  Future<Either<Failure, List<AddressEntity>>> getAddresses();

  Future<Either<Failure, String>> removeAddress({required String addressId});

  Future<Either<Failure, String>> selectAddress({required String addressId});
}
