import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:project_print/core/error/exceptions.dart';
import 'package:project_print/core/error/failures.dart';
import 'package:project_print/core/network/network_info.dart';
import 'package:project_print/features/home/data/datasources/home_local_data_source.dart';
import 'package:project_print/features/home/data/datasources/home_remote_data_source.dart';
import 'package:project_print/features/home/data/models/print_categories_response_model.dart';
import 'package:project_print/features/home/data/models/print_category_model.dart';
import 'package:project_print/features/home/data/models/welcome_model.dart';
import 'package:project_print/features/home/data/repositories/home_repository_impl.dart';

class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockLogger extends Mock implements Logger {}

void main() {
  late HomeRepositoryImpl repository;
  late MockHomeRemoteDataSource remoteDataSource;
  late MockHomeLocalDataSource localDataSource;
  late MockNetworkInfo networkInfo;
  late MockLogger logger;

  const welcome = WelcomeModel(message: 'hi');
  const category = PrintCategoryModel(
    id: 'id1',
    avatar: '',
    printType: 'Color',
    rate: 5,
    version: 1,
  );
  const remoteCategories = PrintCategoriesResponseModel(
    message: 'remote',
    categories: [category],
  );
  const cachedCategories = PrintCategoriesResponseModel(
    message: 'cached',
    categories: [category],
  );

  setUp(() {
    remoteDataSource = MockHomeRemoteDataSource();
    localDataSource = MockHomeLocalDataSource();
    networkInfo = MockNetworkInfo();
    logger = MockLogger();
    repository = HomeRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
      logger: logger,
    );
  });

  group('getWelcomeMessage', () {
    test('returns ConnectionFailure when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getWelcomeMessage();

      expect(result, const Left(ConnectionFailure('No internet connection')));
      verifyNever(() => remoteDataSource.getWelcomeMessage());
    });

    test('returns Right(WelcomeEntity) on success', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getWelcomeMessage())
          .thenAnswer((_) async => welcome);

      final result = await repository.getWelcomeMessage();

      expect(result, const Right(welcome));
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getWelcomeMessage()).thenThrow(
        ServerException(message: 'server broke', statusCode: 500),
      );

      final result = await repository.getWelcomeMessage();

      expect(result, const Left(ServerFailure('server broke')));
    });

    test('maps unknown errors to a generic ServerFailure', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getWelcomeMessage())
          .thenThrow(Exception('boom'));

      final result = await repository.getWelcomeMessage();

      expect(result, const Left(ServerFailure('Unknown error occurred')));
    });
  });

  group('getPrintCategories', () {
    test('returns cached categories without touching network when fetched today', () async {
      when(() => localDataSource.getCachedPrintCategories())
          .thenReturn(cachedCategories);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(true);

      final result = await repository.getPrintCategories();

      expect(result, const Right(cachedCategories));
      verifyNever(() => networkInfo.isConnected);
      verifyNever(() => remoteDataSource.getPrintCategories());
    });

    test('fetches remote and caches it when cache exists but not from today', () async {
      when(() => localDataSource.getCachedPrintCategories())
          .thenReturn(cachedCategories);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getPrintCategories())
          .thenAnswer((_) async => remoteCategories);
      when(() => localDataSource.cachePrintCategories(remoteCategories))
          .thenAnswer((_) async {});

      final result = await repository.getPrintCategories();

      expect(result, const Right(remoteCategories));
      verify(() => localDataSource.cachePrintCategories(remoteCategories))
          .called(1);
    });

    test('fetches remote when there is no cache at all', () async {
      when(() => localDataSource.getCachedPrintCategories()).thenReturn(null);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getPrintCategories())
          .thenAnswer((_) async => remoteCategories);
      when(() => localDataSource.cachePrintCategories(remoteCategories))
          .thenAnswer((_) async {});

      final result = await repository.getPrintCategories();

      expect(result, const Right(remoteCategories));
    });

    test('falls back to cache when offline and cache is present', () async {
      when(() => localDataSource.getCachedPrintCategories())
          .thenReturn(cachedCategories);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getPrintCategories();

      expect(result, const Right(cachedCategories));
      verifyNever(() => remoteDataSource.getPrintCategories());
    });

    test('returns ConnectionFailure when offline and no cache', () async {
      when(() => localDataSource.getCachedPrintCategories()).thenReturn(null);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getPrintCategories();

      expect(result, const Left(ConnectionFailure('No internet connection')));
    });

    test('falls back to cache when remote throws ServerException and cache exists', () async {
      when(() => localDataSource.getCachedPrintCategories())
          .thenReturn(cachedCategories);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getPrintCategories()).thenThrow(
        ServerException(message: 'server broke'),
      );

      final result = await repository.getPrintCategories();

      expect(result, const Right(cachedCategories));
    });

    test('returns ServerFailure when remote throws ServerException and no cache', () async {
      when(() => localDataSource.getCachedPrintCategories()).thenReturn(null);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getPrintCategories()).thenThrow(
        ServerException(message: 'server broke'),
      );

      final result = await repository.getPrintCategories();

      expect(result, const Left(ServerFailure('server broke')));
    });

    test('falls back to cache when remote throws an unknown error and cache exists', () async {
      when(() => localDataSource.getCachedPrintCategories())
          .thenReturn(cachedCategories);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getPrintCategories())
          .thenThrow(Exception('boom'));

      final result = await repository.getPrintCategories();

      expect(result, const Right(cachedCategories));
    });

    test('returns generic ServerFailure when remote throws unknown error and no cache', () async {
      when(() => localDataSource.getCachedPrintCategories()).thenReturn(null);
      when(() => localDataSource.hasFetchedCategoriesToday()).thenReturn(false);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getPrintCategories())
          .thenThrow(Exception('boom'));

      final result = await repository.getPrintCategories();

      expect(result, const Left(ServerFailure('Unknown error occurred')));
    });
  });
}
