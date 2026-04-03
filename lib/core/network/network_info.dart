import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl({
    required Connectivity connectivity,
    required InternetConnectionChecker connectionChecker,
  }) : _connectivity = connectivity,
       _connectionChecker = connectionChecker;

  final Connectivity _connectivity;
  final InternetConnectionChecker _connectionChecker;

  @override
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    return _connectionChecker.hasConnection;
  }
}
