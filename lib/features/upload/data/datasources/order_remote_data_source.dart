import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/temporary_auth_store.dart';
import '../models/order_summary_model.dart';

abstract class OrderRemoteDataSource {
  Future<OrderCreateResult> createOrder({
    required String printConfigId,
    required num deliveryCharge,
    required List<OrderCreateItem> items,
  });

  Future<OrderSummaryResponse> getOrderSummary({required String orderId});

  /// Places the order for [orderId] against [addressId] with the chosen
  /// [paymentMethod] (e.g. `COD`). Backed by `POST order/checkout`.
  Future<OrderCheckoutResult> checkout({
    required String orderId,
    required String addressId,
    required String paymentMethod,
  });

  /// Cancels (deletes) the order [orderId] on the backend via
  /// `DELETE order/cancel`.
  Future<void> cancelOrder({required String orderId});

  /// Notifies the backend that a file's Drive upload finished, so it can
  /// finalize the item. Called once per file after its `uploadUrl` PUT succeeds.
  ///
  /// Backed by `POST order/items/<itemId>/upload-complete`, where [itemId]
  /// comes from the `order/create` response and [driveFileId] is the `id`
  /// Drive returned from the resumable PUT (see [DriveUploadResult.id]).
  Future<void> completeUpload({
    required String itemId,
    required String driveFileId,
  });
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
  Future<OrderCreateResult> createOrder({
    required String printConfigId,
    required num deliveryCharge,
    required List<OrderCreateItem> items,
  }) async {
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
          'printConfigId': printConfigId,
          'deliveryCharge': deliveryCharge,
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

      final result = OrderCreateResult.fromJson(data);

      if (result.orderId.isEmpty) {
        throw const OrderCreateException(
          'Order created but the server did not return an order ID.',
        );
      }

      return result;
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

  @override
  Future<OrderSummaryResponse> getOrderSummary({
    required String orderId,
  }) async {
    if (orderId.isEmpty) {
      throw const OrderCreateException('Missing order ID for the summary.');
    }

    try {
      final response = await _dioClient.get(
        path: ApiConstants.orderSummary,
        data: {'orderId': orderId},
      );

      final responseData = response.data;
      final responseMap = responseData is Map<String, dynamic>
          ? responseData
          : const <String, dynamic>{};

      return OrderSummaryResponse.fromJson(responseMap);
    } on DioException catch (error, stackTrace) {
      _logger.e(
        'Order summary fetch failed',
        error: error,
        stackTrace: stackTrace,
      );

      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

      throw OrderCreateException(
        backendMessage ?? error.message ?? 'Failed to load order summary.',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected order summary error',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is OrderCreateException) {
        rethrow;
      }
      throw const OrderCreateException('Failed to load order summary.');
    }
  }

  @override
  Future<OrderCheckoutResult> checkout({
    required String orderId,
    required String addressId,
    required String paymentMethod,
  }) async {
    if (orderId.isEmpty) {
      throw const OrderCreateException('Missing order ID for checkout.');
    }
    if (addressId.isEmpty) {
      throw const OrderCreateException('Please select a delivery address.');
    }

    try {
      final response = await _dioClient.post(
        path: ApiConstants.orderCheckout,
        data: {
          'orderId': orderId,
          'addressId': addressId,
          'paymentMethod': paymentMethod,
        },
      );

      final responseData = response.data;
      final responseMap = responseData is Map<String, dynamic>
          ? responseData
          : const <String, dynamic>{};
      final data = responseMap['data'] is Map<String, dynamic>
          ? responseMap['data'] as Map<String, dynamic>
          : responseMap;

      return OrderCheckoutResult.fromJson(
        data,
        message: responseMap['message']?.toString(),
      );
    } on DioException catch (error, stackTrace) {
      _logger.e('Order checkout failed', error: error, stackTrace: stackTrace);

      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

      throw OrderCreateException(
        backendMessage ?? error.message ?? 'Failed to place the order.',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected order checkout error',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is OrderCreateException) {
        rethrow;
      }
      throw const OrderCreateException('Failed to place the order.');
    }
  }

  @override
  Future<void> cancelOrder({required String orderId}) async {
    if (orderId.isEmpty) {
      throw const OrderCreateException('Missing order ID to cancel.');
    }

    try {
      await _dioClient.delete(
        path: ApiConstants.orderCancel,
        data: {'orderId': orderId},
      );
    } on DioException catch (error, stackTrace) {
      _logger.e('Order cancel failed', error: error, stackTrace: stackTrace);

      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

      throw OrderCreateException(
        backendMessage ?? error.message ?? 'Failed to cancel the order.',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected order cancel error',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is OrderCreateException) {
        rethrow;
      }
      throw const OrderCreateException('Failed to cancel the order.');
    }
  }

  @override
  Future<void> completeUpload({
    required String itemId,
    required String driveFileId,
  }) async {
    if (itemId.isEmpty) {
      throw const OrderCreateException('Missing item id to finalize upload.');
    }
    if (driveFileId.isEmpty) {
      throw const OrderCreateException('Missing Drive file id to finalize.');
    }

    try {
      await _dioClient.post(
        path: ApiConstants.orderItemUploadComplete(itemId),
        data: {'driveFileId': driveFileId},
      );
    } on DioException catch (error, stackTrace) {
      _logger.e(
        'Upload complete failed',
        error: error,
        stackTrace: stackTrace,
      );

      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

      throw OrderCreateException(
        backendMessage ?? error.message ?? 'Failed to finalize upload.',
      );
    }
  }

  String _resolveMobileNumber() {
    final storedMobile = _temporaryAuthStore.mobile;
    if (storedMobile.isNotEmpty) {
      return storedMobile;
    }
    return _firebaseAuth.currentUser?.phoneNumber?.trim() ?? '';
  }

}

class OrderCreateItem {
  const OrderCreateItem({
    required this.fileName,
    required this.fileType,
    required this.mimeType,
    required this.fileSize,
    required this.paperQualityId,
    required this.sizeId,
    required this.numberOfPages,
    required this.numberOfCopy,
    required this.samePage,
  });

  final String fileName;
  final String fileType;
  final String mimeType;
  final int fileSize;
  final String paperQualityId;
  final String sizeId;
  final int numberOfPages;
  final int numberOfCopy;
  final bool samePage;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'paperQualityId': paperQualityId,
      'sizeId': sizeId,
      'numberOfPages': numberOfPages,
      'numberOfCopy': numberOfCopy,
      'samePage': samePage,
    };
  }
}

/// Parsed `data` payload returned by `order/create`.
class OrderCreateResult {
  const OrderCreateResult({
    required this.orderId,
    required this.printConfigId,
    required this.baseRate,
    required this.totalAmount,
    required this.deliveryCharge,
    required this.grandTotal,
    required this.uploads,
  });

  factory OrderCreateResult.fromJson(Map<String, dynamic> json) {
    final uploads = json['uploads'];
    return OrderCreateResult(
      orderId: (json['orderId'] as String?) ?? '',
      printConfigId: (json['printConfigId'] as String?) ?? '',
      baseRate: (json['baseRate'] as num?) ?? 0,
      totalAmount: (json['totalAmount'] as num?) ?? 0,
      deliveryCharge: (json['deliveryCharge'] as num?) ?? 0,
      grandTotal: (json['grandTotal'] as num?) ?? 0,
      uploads: uploads is List
          ? uploads
                .whereType<Map<String, dynamic>>()
                .map(OrderUploadSession.fromJson)
                .toList(growable: false)
          : const <OrderUploadSession>[],
    );
  }

  final String orderId;
  final String printConfigId;
  final num baseRate;
  final num totalAmount;
  final num deliveryCharge;
  final num grandTotal;
  final List<OrderUploadSession> uploads;
}

/// A resumable upload session for a single order item.
class OrderUploadSession {
  const OrderUploadSession({
    required this.itemId,
    required this.uploadSessionId,
    required this.uploadUrl,
    required this.expiresIn,
  });

  factory OrderUploadSession.fromJson(Map<String, dynamic> json) {
    return OrderUploadSession(
      itemId: (json['itemId'] as String?) ?? '',
      uploadSessionId: (json['uploadSessionId'] as String?) ?? '',
      uploadUrl: (json['uploadUrl'] as String?) ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
    );
  }

  final String itemId;
  final String uploadSessionId;
  final String uploadUrl;
  final int expiresIn;
}

/// Parsed `data` payload returned by `order/checkout`.
class OrderCheckoutResult {
  const OrderCheckoutResult({
    required this.orderId,
    required this.status,
    required this.paymentMethod,
    required this.grandTotal,
    required this.message,
  });

  factory OrderCheckoutResult.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    return OrderCheckoutResult(
      orderId: (json['orderId'] as String?) ?? '',
      status: (json['status'] as String?) ?? (json['orderStatus'] as String?) ?? '',
      paymentMethod: (json['paymentMethod'] as String?) ?? '',
      grandTotal: (json['grandTotal'] as num?) ?? 0,
      message: message ?? json['message']?.toString() ?? '',
    );
  }

  final String orderId;
  final String status;
  final String paymentMethod;
  final num grandTotal;
  final String message;
}

class OrderCreateException implements Exception {
  const OrderCreateException(this.message);

  final String message;
}
