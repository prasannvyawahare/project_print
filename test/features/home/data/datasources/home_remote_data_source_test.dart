import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:project_print/core/constants/api_constants.dart';
import 'package:project_print/core/error/exceptions.dart';
import 'package:project_print/core/network/dio_client.dart';
import 'package:project_print/features/home/data/datasources/home_remote_data_source.dart';

class MockDioClient extends Mock implements DioClient {}

class MockLogger extends Mock implements Logger {}

void main() {
  late HomeRemoteDataSourceImpl dataSource;
  late MockDioClient dioClient;
  late MockLogger logger;

  setUp(() {
    dioClient = MockDioClient();
    logger = MockLogger();
    dataSource = HomeRemoteDataSourceImpl(dioClient: dioClient, logger: logger);
  });

  group('getWelcomeMessage', () {
    test('returns a WelcomeModel parsed from the response data', () async {
      when(() => dioClient.get(path: ApiConstants.welcomePath)).thenAnswer(
        (_) async => Response<dynamic>(
          data: {'title': 'Hello'},
          requestOptions: RequestOptions(path: ApiConstants.welcomePath),
        ),
      );

      final result = await dataSource.getWelcomeMessage();

      expect(result.message, 'Hello');
      verify(() => dioClient.get(path: ApiConstants.welcomePath)).called(1);
    });

    test('parses an empty map when response data is null', () async {
      when(() => dioClient.get(path: ApiConstants.welcomePath)).thenAnswer(
        (_) async => Response<dynamic>(
          data: null,
          requestOptions: RequestOptions(path: ApiConstants.welcomePath),
        ),
      );

      final result = await dataSource.getWelcomeMessage();

      expect(result.message, 'Welcome from clean architecture template');
    });

    test('throws ServerException on DioException', () async {
      when(() => dioClient.get(path: ApiConstants.welcomePath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.welcomePath),
          message: 'network down',
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ApiConstants.welcomePath),
            statusCode: 500,
          ),
        ),
      );

      expect(
        () => dataSource.getWelcomeMessage(),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'network down')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('uses default message when DioException.message is null', () async {
      when(() => dioClient.get(path: ApiConstants.welcomePath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.welcomePath),
        ),
      );

      expect(
        () => dataSource.getWelcomeMessage(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Unexpected network error',
          ),
        ),
      );
    });
  });

  group('getPrintCategories', () {
    test('returns a PrintCategoriesResponseModel parsed from response data', () async {
      when(() => dioClient.get(path: ApiConstants.printConfigPath)).thenAnswer(
        (_) async => Response<dynamic>(
          data: {
            'message': 'Fetched',
            'data': [
              {'_id': 'a', 'printType': 'Color', 'rate': 5, '__v': 0},
            ],
          },
          requestOptions: RequestOptions(path: ApiConstants.printConfigPath),
        ),
      );

      final result = await dataSource.getPrintCategories();

      expect(result.message, 'Fetched');
      expect(result.categories, hasLength(1));
      verify(() => dioClient.get(path: ApiConstants.printConfigPath)).called(1);
    });

    test('parses an empty map when response data is null', () async {
      when(() => dioClient.get(path: ApiConstants.printConfigPath)).thenAnswer(
        (_) async => Response<dynamic>(
          data: null,
          requestOptions: RequestOptions(path: ApiConstants.printConfigPath),
        ),
      );

      final result = await dataSource.getPrintCategories();

      expect(result.message, 'Categories fetched');
      expect(result.categories, isEmpty);
    });

    test('throws ServerException on DioException', () async {
      when(() => dioClient.get(path: ApiConstants.printConfigPath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.printConfigPath),
          message: 'boom',
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ApiConstants.printConfigPath),
            statusCode: 400,
          ),
        ),
      );

      expect(
        () => dataSource.getPrintCategories(),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'boom')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });
}
