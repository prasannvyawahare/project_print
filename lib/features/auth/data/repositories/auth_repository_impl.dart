import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo,
       _logger = logger;

  final AuthRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  @override
  Future<Either<Failure, AuthUserEntity>> signInWithGoogle() async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      final user = await _remoteDataSource.signInWithGoogle();
      return Right(user);
    } on ServerException catch (error, stackTrace) {
      _logger.e('Auth server exception', error: error, stackTrace: stackTrace);
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e('Auth unknown exception', error: error, stackTrace: stackTrace);
      return const Left(ServerFailure('Authentication failed'));
    }
  }

  @override
  Future<Either<Failure, AuthUserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      final user = await _remoteDataSource.signInWithEmailPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } on ServerException catch (error, stackTrace) {
      _logger.e(
        'Email auth server exception',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e(
        'Email auth unknown exception',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure('Authentication failed'));
    }
  }

  @override
  Future<Either<Failure, String>> verifyAndSaveUser({
    required String email,
    required String mobile,
    required String authToken,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      final userId = await _remoteDataSource.verifyAndSaveUser(
        email: email,
        mobile: mobile,
        authToken: authToken,
      );
      return Right(userId);
    } on ServerException catch (error, stackTrace) {
      _logger.e(
        'Verify user server exception',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e(
        'Verify user unknown exception',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure('Unable to verify user details'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkStorageExists() async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      final exists = await _remoteDataSource.checkStorageExists();
      return Right(exists);
    } on ServerException catch (error, stackTrace) {
      _logger.e(
        'Check storage exception',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e(
        'Check storage unknown exception',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure('Unable to check storage'));
    }
  }

  @override
  Future<Either<Failure, Unit>> createStorage(String userId) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      await _remoteDataSource.createStorage(userId);
      return const Right(unit);
    } on ServerException catch (error, stackTrace) {
      _logger.e(
        'Create storage exception',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e(
        'Create storage unknown exception',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure('Unable to create storage'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signInWithApple() async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      return const Left(ConnectionFailure('No internet connection'));
    }

    try {
      await _remoteDataSource.signInWithApple();
      return const Right(unit);
    } on ServerException catch (error, stackTrace) {
      _logger.e(
        'Apple auth server exception',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e(
        'Apple auth unknown exception',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure('Apple authentication failed'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(unit);
    } on ServerException catch (error, stackTrace) {
      _logger.e(
        'Logout server exception',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(error.message, statusCode: error.statusCode));
    } catch (error, stackTrace) {
      _logger.e(
        'Logout unknown exception',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure('Logout failed'));
    }
  }
}
