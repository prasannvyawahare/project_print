import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:project_print/core/constants/api_constants.dart';
import 'package:project_print/core/error/exceptions.dart';
import 'package:project_print/core/network/dio_client.dart';
import 'package:project_print/features/delivery/data/datasources/address_remote_data_source.dart';

class MockDioClient extends Mock implements DioClient {}

class MockLogger extends Mock implements Logger {}

Response<dynamic> _response(dynamic data) {
  return Response<dynamic>(data: data, requestOptions: RequestOptions(path: ''));
}

void main() {
  late MockDioClient dioClient;
  late MockLogger logger;
  late AddressRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    dioClient = MockDioClient();
    logger = MockLogger();
    dataSource = AddressRemoteDataSourceImpl(dioClient: dioClient, logger: logger);
  });

  group('createAddress', () {
    const addressJson = {
      '_id': 'a1',
      'addressType': 'home',
      'address': '123 Street',
      'flat': '4B',
      'landmark': 'Near park',
      'pincode': 400097,
      'selected': true,
    };

    test('returns AddressModel on success', () async {
      when(
        () => dioClient.post(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _response({'data': addressJson}),
      );

      final result = await dataSource.createAddress(
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
      );

      expect(result.id, 'a1');
      expect(result.addressType, 'home');
      expect(result.selected, true);
      verify(
        () => dioClient.post(
          path: ApiConstants.addressCreate,
          data: {
            'addressType': 'home',
            'address': '123 Street',
            'flat': '4B',
            'landmark': 'Near park',
            'pincode': 400097,
          },
        ),
      ).called(1);
    });

    test('defaults to empty model when response.data is not a map', () async {
      when(
        () => dioClient.post(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _response('unexpected'));

      final result = await dataSource.createAddress(
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
      );

      expect(result.id, '');
      expect(result.pincode, 0);
    });

    test('defaults to empty model when data["data"] is not a map', () async {
      when(
        () => dioClient.post(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _response({'data': 'not-a-map'}));

      final result = await dataSource.createAddress(
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
      );

      expect(result.id, '');
    });

    test(
      'throws ServerException with backend "message" on DioException',
      () async {
        when(
          () => dioClient.post(
            path: any(named: 'path'),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response<dynamic>(
              data: {'message': 'Invalid pincode'},
              statusCode: 400,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );

        expect(
          () => dataSource.createAddress(
            addressType: 'home',
            address: '123 Street',
            flat: '4B',
            landmark: 'Near park',
            pincode: 400097,
          ),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Invalid pincode')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
        );
      },
    );

    test('falls back to backend "error" key when "message" is absent', () async {
      when(
        () => dioClient.post(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response<dynamic>(
            data: {'error': 'Something broke'},
            statusCode: 500,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => dataSource.createAddress(
          addressType: 'home',
          address: '123 Street',
          flat: '4B',
          landmark: 'Near park',
          pincode: 400097,
        ),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Something broke'),
        ),
      );
    });

    test(
      'falls back to DioException.message when response has no usable body',
      () async {
        when(
          () => dioClient.post(
            path: any(named: 'path'),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            message: 'Connection timed out',
          ),
        );

        expect(
          () => dataSource.createAddress(
            addressType: 'home',
            address: '123 Street',
            flat: '4B',
            landmark: 'Near park',
            pincode: 400097,
          ),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Connection timed out'),
          ),
        );
      },
    );

    test(
      'falls back to generic message when both backend body and message are empty',
      () async {
        when(
          () => dioClient.post(
            path: any(named: 'path'),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response<dynamic>(
              data: {'message': '   '},
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );

        expect(
          () => dataSource.createAddress(
            addressType: 'home',
            address: '123 Street',
            flat: '4B',
            landmark: 'Near park',
            pincode: 400097,
          ),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Unexpected network error'),
          ),
        );
      },
    );
  });

  group('getAddresses', () {
    test('returns list of AddressModel on success', () async {
      when(() => dioClient.get(path: any(named: 'path'))).thenAnswer(
        (_) async => _response({
          'data': {
            'address': [
              {
                '_id': 'a1',
                'addressType': 'home',
                'address': 'A',
                'flat': '1',
                'landmark': '',
                'pincode': 400001,
                'selected': false,
              },
              {
                '_id': 'a2',
                'addressType': 'office',
                'address': 'B',
                'flat': '2',
                'landmark': 'X',
                'pincode': 400002,
                'selected': true,
              },
            ],
          },
        }),
      );

      final result = await dataSource.getAddresses();

      expect(result, hasLength(2));
      expect(result.first.id, 'a1');
      expect(result.last.selected, true);
      verify(() => dioClient.get(path: ApiConstants.addressGet)).called(1);
    });

    test('returns empty list when response.data is not a map', () async {
      when(
        () => dioClient.get(path: any(named: 'path')),
      ).thenAnswer((_) async => _response('bad'));

      final result = await dataSource.getAddresses();
      expect(result, isEmpty);
    });

    test('returns empty list when data["data"] is not a map', () async {
      when(
        () => dioClient.get(path: any(named: 'path')),
      ).thenAnswer((_) async => _response({'data': 'oops'}));

      final result = await dataSource.getAddresses();
      expect(result, isEmpty);
    });

    test('returns empty list when address field is not a List', () async {
      when(() => dioClient.get(path: any(named: 'path'))).thenAnswer(
        (_) async => _response({
          'data': {'address': 'not-a-list'},
        }),
      );

      final result = await dataSource.getAddresses();
      expect(result, isEmpty);
    });

    test('filters out non-map entries from the address list', () async {
      when(() => dioClient.get(path: any(named: 'path'))).thenAnswer(
        (_) async => _response({
          'data': {
            'address': [
              'garbage',
              {
                '_id': 'a1',
                'addressType': 'home',
                'address': 'A',
                'flat': '1',
                'landmark': '',
                'pincode': 1,
                'selected': false,
              },
            ],
          },
        }),
      );

      final result = await dataSource.getAddresses();
      expect(result, hasLength(1));
      expect(result.first.id, 'a1');
    });

    test('throws ServerException on DioException', () async {
      when(() => dioClient.get(path: any(named: 'path'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response<dynamic>(
            data: {'message': 'Server down'},
            statusCode: 503,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => dataSource.getAddresses(),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Server down')
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('removeAddress', () {
    test('returns message and trims addressId when success is true', () async {
      when(
        () => dioClient.delete(
          path: any(named: 'path'),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => _response({'success': true, 'message': 'Removed'}),
      );

      final result = await dataSource.removeAddress(addressId: '  a1  ');

      expect(result, 'Removed');
      verify(
        () => dioClient.delete(
          path: ApiConstants.addressRemove,
          data: {'addressId': 'a1'},
          headers: {'content-type': 'application/json'},
        ),
      ).called(1);
    });

    test('throws ServerException when success is false', () async {
      when(
        () => dioClient.delete(
          path: any(named: 'path'),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            _response({'success': false, 'message': 'Address not found'}),
      );

      expect(
        () => dataSource.removeAddress(addressId: 'a1'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Address not found'),
        ),
      );
    });

    test('throws ServerException when success key is missing', () async {
      when(
        () => dioClient.delete(
          path: any(named: 'path'),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _response(<String, dynamic>{}));

      expect(
        () => dataSource.removeAddress(addressId: 'a1'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', '')),
      );
    });

    test('throws ServerException on DioException', () async {
      when(
        () => dioClient.delete(
          path: any(named: 'path'),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Network error',
        ),
      );

      expect(
        () => dataSource.removeAddress(addressId: 'a1'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Network error'),
        ),
      );
    });
  });

  group('selectAddress', () {
    test('returns message and trims addressId when success is true', () async {
      when(
        () => dioClient.patch(
          path: any(named: 'path'),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => _response({'success': true, 'message': 'Selected'}),
      );

      final result = await dataSource.selectAddress(addressId: ' a1 ');

      expect(result, 'Selected');
      verify(
        () => dioClient.patch(
          path: ApiConstants.addressSelect,
          data: {'addressId': 'a1'},
          headers: {'content-type': 'application/json'},
        ),
      ).called(1);
    });

    test('throws ServerException when success is false', () async {
      when(
        () => dioClient.patch(
          path: any(named: 'path'),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => _response({'success': false, 'message': 'Cannot select'}),
      );

      expect(
        () => dataSource.selectAddress(addressId: 'a1'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Cannot select'),
        ),
      );
    });

    test('throws ServerException on DioException', () async {
      when(
        () => dioClient.patch(
          path: any(named: 'path'),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response<dynamic>(
            data: {'error': 'Bad request'},
            statusCode: 400,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => dataSource.selectAddress(addressId: 'a1'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Bad request'),
        ),
      );
    });
  });
}
