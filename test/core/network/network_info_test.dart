import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:project_print/core/network/network_info.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockInternetConnectionChecker extends Mock
    implements InternetConnectionChecker {}

void main() {
  late MockConnectivity connectivity;
  late MockInternetConnectionChecker connectionChecker;
  late NetworkInfoImpl networkInfo;

  setUp(() {
    connectivity = MockConnectivity();
    connectionChecker = MockInternetConnectionChecker();
    networkInfo = NetworkInfoImpl(
      connectivity: connectivity,
      connectionChecker: connectionChecker,
    );
  });

  test('isConnected is false when connectivity reports none', () async {
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);

    final result = await networkInfo.isConnected;

    expect(result, isFalse);
    verifyNever(() => connectionChecker.hasConnection);
  });

  test('isConnected reflects connectionChecker when connectivity is not none (true case)', () async {
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => connectionChecker.hasConnection).thenAnswer((_) async => true);

    final result = await networkInfo.isConnected;

    expect(result, isTrue);
  });

  test('isConnected is false when connectionChecker reports no connection', () async {
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => connectionChecker.hasConnection).thenAnswer((_) async => false);

    final result = await networkInfo.isConnected;

    expect(result, isFalse);
  });

  test('isConnected treats a mixed result list containing none as offline', () async {
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi, ConnectivityResult.none]);

    final result = await networkInfo.isConnected;

    expect(result, isFalse);
    verifyNever(() => connectionChecker.hasConnection);
  });
}
