import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_data_source.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl({
    required AddressRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo,
       _logger = logger;

  final AddressRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  @override
  Future<Either<Failure, AddressEntity>> createAddress({
    required String addressType,
    required String address,
    required String flat,
    required String landmark,
    required int pincode,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }
    try {
      final result = await _remoteDataSource.createAddress(
        addressType: addressType,
        address: address,
        flat: flat,
        landmark: landmark,
        pincode: pincode,
      );
      return Right(result);
    } on ServerException catch (error, stackTrace) {
      _logger.e('Server exception', error: error, stackTrace: stackTrace);
      return Left(ServerFailure(error.message));
    } catch (error, stackTrace) {
      _logger.e('Unknown failure', error: error, stackTrace: stackTrace);
      return const Left(ServerFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<AddressEntity>>> getAddresses() async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }
    try {
      final result = await _remoteDataSource.getAddresses();
      return Right(result);
    } on ServerException catch (error, stackTrace) {
      _logger.e('Server exception', error: error, stackTrace: stackTrace);
      return Left(ServerFailure(error.message));
    } catch (error, stackTrace) {
      _logger.e('Unknown failure', error: error, stackTrace: stackTrace);
      return const Left(ServerFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> removeAddress({
    required String addressId,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }
    try {
      final message = await _remoteDataSource.removeAddress(
        addressId: addressId,
      );
      return Right(message);
    } on ServerException catch (error, stackTrace) {
      _logger.e('Server exception', error: error, stackTrace: stackTrace);
      return Left(ServerFailure(error.message));
    } catch (error, stackTrace) {
      _logger.e('Unknown failure', error: error, stackTrace: stackTrace);
      return const Left(ServerFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> selectAddress({
    required String addressId,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }
    try {
      final message = await _remoteDataSource.selectAddress(
        addressId: addressId,
      );
      return Right(message);
    } on ServerException catch (error, stackTrace) {
      _logger.e('Server exception', error: error, stackTrace: stackTrace);
      return Left(ServerFailure(error.message));
    } catch (error, stackTrace) {
      _logger.e('Unknown failure', error: error, stackTrace: stackTrace);
      return const Left(ServerFailure('Unknown error occurred'));
    }
  }
}
