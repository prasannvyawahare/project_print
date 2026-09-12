import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:project_print/core/constants/api_constants.dart';
import 'package:project_print/core/error/exceptions.dart';
import 'package:project_print/core/network/dio_client.dart';
import 'package:project_print/features/print/data/datasources/print_config_remote_data_source.dart';

class MockDioClient extends Mock implements DioClient {}

class MockLogger extends Mock implements Logger {}

Response<dynamic> _response(dynamic data) {
  return Response<dynamic>(data: data, requestOptions: RequestOptions(path: ''));
}

void main() {
  late MockDioClient dioClient;
  late MockLogger logger;
  late PrintConfigRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    dioClient = MockDioClient();
    logger = MockLogger();
    dataSource = PrintConfigRemoteDataSourceImpl(
      dioClient: dioClient,
      logger: logger,
    );
  });

  group('getPrintConfigs', () {
    const configJson = {
      '_id': 'c1',
      'name': 'Color',
      'options': {
        'paperQualities': [
          {'_id': 'q1', 'name': 'Glossy', 'gsm': '250', 'extra': 2},
        ],
        'sizes': [
          {'_id': 's1', 'name': 'A4', 'width': 210, 'height': 297, 'extra': 0},
        ],
      },
      'pricing': {'baseRate': 5},
    };

    test('returns list of PrintConfigModel on success', () async {
      when(() => dioClient.get(path: any(named: 'path'))).thenAnswer(
        (_) async => _response({
          'data': [configJson],
        }),
      );

      final result = await dataSource.getPrintConfigs();

      expect(result, hasLength(1));
      expect(result.first.id, 'c1');
      expect(result.first.name, 'Color');
      expect(result.first.paperQualities, hasLength(1));
      expect(result.first.sizes, hasLength(1));
      expect(result.first.baseRate, 5);
      verify(
        () => dioClient.get(path: ApiConstants.printConfigPath),
      ).called(1);
    });

    test('returns empty list when response.data is not a map', () async {
      when(
        () => dioClient.get(path: any(named: 'path')),
      ).thenAnswer((_) async => _response('unexpected'));

      final result = await dataSource.getPrintConfigs();
      expect(result, isEmpty);
    });

    test('returns empty list when data["data"] is not a List', () async {
      when(() => dioClient.get(path: any(named: 'path'))).thenAnswer(
        (_) async => _response({'data': 'not-a-list'}),
      );

      final result = await dataSource.getPrintConfigs();
      expect(result, isEmpty);
    });

    test('filters out non-map entries in the data list', () async {
      when(() => dioClient.get(path: any(named: 'path'))).thenAnswer(
        (_) async => _response({
          'data': ['garbage', configJson],
        }),
      );

      final result = await dataSource.getPrintConfigs();
      expect(result, hasLength(1));
      expect(result.first.id, 'c1');
    });

    test(
      'throws ServerException with DioException message on failure',
      () async {
        when(() => dioClient.get(path: any(named: 'path'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            message: 'Timed out',
            response: Response<dynamic>(
              statusCode: 500,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );

        expect(
          () => dataSource.getPrintConfigs(),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Timed out')
                .having((e) => e.statusCode, 'statusCode', 500),
          ),
        );
        verify(() => logger.e(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'))).called(1);
      },
    );

    test(
      'throws ServerException with default message when DioException.message is null',
      () async {
        when(() => dioClient.get(path: any(named: 'path'))).thenThrow(
          DioException(requestOptions: RequestOptions(path: '')),
        );

        expect(
          () => dataSource.getPrintConfigs(),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'Unable to load print configurations.',
            ),
          ),
        );
      },
    );
  });
}
