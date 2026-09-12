import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo,
       _logger = logger;

  final ProfileRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  @override
  Future<Either<Failure, UserProfileEntity>> getProfile() async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      final result = await _remoteDataSource.getProfile();
      return Right(result);
    } on ServerException catch (error, stackTrace) {
      _logger.e('Server exception', error: error, stackTrace: stackTrace);
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e('Unknown failure', error: error, stackTrace: stackTrace);
      return const Left(ServerFailure('Unknown error occurred'));
    }
  }
}
