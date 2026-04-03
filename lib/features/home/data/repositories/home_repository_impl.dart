import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/welcome_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required HomeRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _logger = logger;

  final HomeRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  @override
  Future<Either<Failure, WelcomeEntity>> getWelcomeMessage() async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      final result = await _remoteDataSource.getWelcomeMessage();
      return Right(result);
    } on ServerException catch (error, stackTrace) {
      _logger.e('Server exception', error: error, stackTrace: stackTrace);
      return Left(ServerFailure(error.message));
    } catch (error, stackTrace) {
      _logger.e('Unknown failure', error: error, stackTrace: stackTrace);
      return const Left(ServerFailure('Unknown error occurred'));
    }
  }
}
