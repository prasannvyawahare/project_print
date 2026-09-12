import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:project_print/core/error/exceptions.dart';
import 'package:project_print/core/error/failures.dart';
import 'package:project_print/core/network/network_info.dart';
import 'package:project_print/features/delivery/data/datasources/address_remote_data_source.dart';
import 'package:project_print/features/delivery/data/models/address_model.dart';
import 'package:project_print/features/delivery/data/repositories/address_repository_impl.dart';

class MockAddressRemoteDataSource extends Mock
    implements AddressRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockLogger extends Mock implements Logger {}

void main() {
  late MockAddressRemoteDataSource remoteDataSource;
  late MockNetworkInfo networkInfo;
  late MockLogger logger;
  late AddressRepositoryImpl repository;

  const addressModel = AddressModel(
    id: 'a1',
    addressType: 'home',
    address: '123 Street',
    flat: '4B',
    landmark: 'Near park',
    pincode: 400097,
    selected: false,
  );

  setUp(() {
    remoteDataSource = MockAddressRemoteDataSource();
    networkInfo = MockNetworkInfo();
    logger = MockLogger();
    repository = AddressRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
      logger: logger,
    );
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
  });

  group('createAddress', () {
    test('returns Right with the entity on success', () async {
      when(
        () => remoteDataSource.createAddress(
          addressType: any(named: 'addressType'),
          address: any(named: 'address'),
          flat: any(named: 'flat'),
          landmark: any(named: 'landmark'),
          pincode: any(named: 'pincode'),
        ),
      ).thenAnswer((_) async => addressModel);

      final result = await repository.createAddress(
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
      );

      expect(result, Right(addressModel));
    });

    test('returns Left(ConnectionFailure) when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.createAddress(
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
      );

      expect(result, const Left(ConnectionFailure('No internet connection')));
      verifyNever(
        () => remoteDataSource.createAddress(
          addressType: any(named: 'addressType'),
          address: any(named: 'address'),
          flat: any(named: 'flat'),
          landmark: any(named: 'landmark'),
          pincode: any(named: 'pincode'),
        ),
      );
    });

    test('returns Left(ServerFailure) when the datasource throws ServerException', () async {
      when(
        () => remoteDataSource.createAddress(
          addressType: any(named: 'addressType'),
          address: any(named: 'address'),
          flat: any(named: 'flat'),
          landmark: any(named: 'landmark'),
          pincode: any(named: 'pincode'),
        ),
      ).thenThrow(ServerException(message: 'Invalid pincode'));

      final result = await repository.createAddress(
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
      );

      expect(result, const Left(ServerFailure('Invalid pincode')));
    });

    test('returns Left(ServerFailure) with a generic message on unknown errors', () async {
      when(
        () => remoteDataSource.createAddress(
          addressType: any(named: 'addressType'),
          address: any(named: 'address'),
          flat: any(named: 'flat'),
          landmark: any(named: 'landmark'),
          pincode: any(named: 'pincode'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await repository.createAddress(
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
      );

      expect(result, const Left(ServerFailure('Unknown error occurred')));
    });
  });

  group('getAddresses', () {
    test('returns Right with the list on success', () async {
      when(() => remoteDataSource.getAddresses())
          .thenAnswer((_) async => [addressModel]);

      final result = await repository.getAddresses();

      expect(result, Right([addressModel]));
    });

    test('returns Left(ConnectionFailure) when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getAddresses();

      expect(result, const Left(ConnectionFailure('No internet connection')));
      verifyNever(() => remoteDataSource.getAddresses());
    });

    test('returns Left(ServerFailure) when the datasource throws ServerException', () async {
      when(() => remoteDataSource.getAddresses())
          .thenThrow(ServerException(message: 'Server down'));

      final result = await repository.getAddresses();

      expect(result, const Left(ServerFailure('Server down')));
    });

    test('returns Left(ServerFailure) with a generic message on unknown errors', () async {
      when(() => remoteDataSource.getAddresses()).thenThrow(Exception('boom'));

      final result = await repository.getAddresses();

      expect(result, const Left(ServerFailure('Unknown error occurred')));
    });
  });

  group('removeAddress', () {
    test('returns Right with the message on success', () async {
      when(() => remoteDataSource.removeAddress(addressId: any(named: 'addressId')))
          .thenAnswer((_) async => 'Removed');

      final result = await repository.removeAddress(addressId: 'a1');

      expect(result, const Right('Removed'));
    });

    test('returns Left(ConnectionFailure) when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.removeAddress(addressId: 'a1');

      expect(result, const Left(ConnectionFailure('No internet connection')));
      verifyNever(
        () => remoteDataSource.removeAddress(addressId: any(named: 'addressId')),
      );
    });

    test('returns Left(ServerFailure) when the datasource throws ServerException', () async {
      when(() => remoteDataSource.removeAddress(addressId: any(named: 'addressId')))
          .thenThrow(ServerException(message: 'Address not found'));

      final result = await repository.removeAddress(addressId: 'a1');

      expect(result, const Left(ServerFailure('Address not found')));
    });

    test('returns Left(ServerFailure) with a generic message on unknown errors', () async {
      when(() => remoteDataSource.removeAddress(addressId: any(named: 'addressId')))
          .thenThrow(Exception('boom'));

      final result = await repository.removeAddress(addressId: 'a1');

      expect(result, const Left(ServerFailure('Unknown error occurred')));
    });
  });

  group('selectAddress', () {
    test('returns Right with the message on success', () async {
      when(() => remoteDataSource.selectAddress(addressId: any(named: 'addressId')))
          .thenAnswer((_) async => 'Selected');

      final result = await repository.selectAddress(addressId: 'a1');

      expect(result, const Right('Selected'));
    });

    test('returns Left(ConnectionFailure) when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.selectAddress(addressId: 'a1');

      expect(result, const Left(ConnectionFailure('No internet connection')));
      verifyNever(
        () => remoteDataSource.selectAddress(addressId: any(named: 'addressId')),
      );
    });

    test('returns Left(ServerFailure) when the datasource throws ServerException', () async {
      when(() => remoteDataSource.selectAddress(addressId: any(named: 'addressId')))
          .thenThrow(ServerException(message: 'Cannot select'));

      final result = await repository.selectAddress(addressId: 'a1');

      expect(result, const Left(ServerFailure('Cannot select')));
    });

    test('returns Left(ServerFailure) with a generic message on unknown errors', () async {
      when(() => remoteDataSource.selectAddress(addressId: any(named: 'addressId')))
          .thenThrow(Exception('boom'));

      final result = await repository.selectAddress(addressId: 'a1');

      expect(result, const Left(ServerFailure('Unknown error occurred')));
    });
  });
}
