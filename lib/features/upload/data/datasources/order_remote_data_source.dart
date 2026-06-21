import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/temporary_auth_store.dart';

abstract class OrderRemoteDataSource {
  Future<String> createOrder({required List<OrderCreateItem> items});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl({
    required DioClient dioClient,
    required TemporaryAuthStore temporaryAuthStore,
    required FirebaseAuth firebaseAuth,
    required Logger logger,
  }) : _dioClient = dioClient,
       _temporaryAuthStore = temporaryAuthStore,
       _firebaseAuth = firebaseAuth,
       _logger = logger;

  final DioClient _dioClient;
  final TemporaryAuthStore _temporaryAuthStore;
  final FirebaseAuth _firebaseAuth;
  final Logger _logger;

  @override
  Future<String> createOrder({required List<OrderCreateItem> items}) async {
    final mobile = _resolveMobileNumber();
    if (mobile.isEmpty) {
      throw const OrderCreateException(
        'Mobile number is missing. Please sign in again.',
      );
    }

    if (items.isEmpty) {
      throw const OrderCreateException(
        'Add at least one item to create an order.',
      );
    }

    try {
      final response = await _dioClient.post(
        path: ApiConstants.orderCreate,
        data: {
          'mobile': mobile,
          'itemCount': items.length,
          'orderStatus': 'created',
          'items': items.map((item) => item.toJson()).toList(),
        },
      );

      final responseData = response.data;
      final responseMap = responseData is Map<String, dynamic>
          ? responseData
          : const <String, dynamic>{};
      final data = responseMap['data'] is Map<String, dynamic>
          ? responseMap['data'] as Map<String, dynamic>
          : const <String, dynamic>{};

      final orderId = _firstNonEmptyString([
        data['orderId'],
        data['_id'],
        responseMap['orderId'],
        responseMap['_id'],
      ]);

      if (orderId.isEmpty) {
        throw const OrderCreateException(
          'Order created but the server did not return an order ID.',
        );
      }

      return orderId;
    } on DioException catch (error, stackTrace) {
      _logger.e('Order creation failed', error: error, stackTrace: stackTrace);

      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

      throw OrderCreateException(
        backendMessage ?? error.message ?? 'Failed to create order.',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected order creation error',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is OrderCreateException) {
        rethrow;
      }
      throw const OrderCreateException('Failed to create order.');
    }
  }

  String _resolveMobileNumber() {
    final storedMobile = _temporaryAuthStore.mobile;
    if (storedMobile.isNotEmpty) {
      return storedMobile;
    }
    return _firebaseAuth.currentUser?.phoneNumber?.trim() ?? '';
  }

  String _firstNonEmptyString(Iterable<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}

class OrderCreateItem {
  const OrderCreateItem({
    required this.fileName,
    required this.fileType,
    required this.numberOfCopy,
    required this.samePage,
    required this.printType,
  });

  final String fileName;
  final String fileType;
  final int numberOfCopy;
  final bool samePage;
  final String printType;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'numberOfCopy': numberOfCopy,
      'samePage': samePage,
      'printType': printType,
    };
  }
}

class OrderCreateException implements Exception {
  const OrderCreateException(this.message);

  final String message;
}
