import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/address_model.dart';

abstract class AddressRemoteDataSource {
  Future<AddressModel> createAddress({
    required String addressType,
    required String address,
    required String flat,
    required String landmark,
    required int pincode,
  });

  Future<List<AddressModel>> getAddresses();

  Future<String> removeAddress({required String addressId});

  Future<String> selectAddress({required String addressId});
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  AddressRemoteDataSourceImpl({
    required DioClient dioClient,
    required Logger logger,
  }) : _dioClient = dioClient,
       _logger = logger;

  final DioClient _dioClient;
  final Logger _logger;

  /// Backend validation errors (400s) come back as `{message: "..."}` (or
  /// occasionally `{error: "..."}`) — surface that instead of Dio's generic
  /// "Http status error [400]" so the SnackBar tells the user what actually
  /// failed (e.g. an invalid pincode or a missing field).
  String _backendMessage(DioException error) {
    final data = error.response?.data;
    final backendMessage = data is Map<String, dynamic>
        ? (data['message']?.toString() ?? data['error']?.toString())
        : null;
    if (backendMessage != null && backendMessage.trim().isNotEmpty) {
      return backendMessage;
    }
    return error.message ?? 'Unexpected network error';
  }

  @override
  Future<AddressModel> createAddress({
    required String addressType,
    required String address,
    required String flat,
    required String landmark,
    required int pincode,
  }) async {
    try {
      final response = await _dioClient.post(
        path: ApiConstants.addressCreate,
        data: {
          'addressType': addressType,
          'address': address,
          'flat': flat,
          'landmark': landmark,
          'pincode': pincode,
        },
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : const <String, dynamic>{};
      final addressData = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : const <String, dynamic>{};
      return AddressModel.fromJson(addressData);
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: _backendMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _dioClient.get(path: ApiConstants.addressGet);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : const <String, dynamic>{};
      final addressData = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final addressList = addressData['address'] is List
          ? addressData['address'] as List<dynamic>
          : const <dynamic>[];
      return addressList
          .whereType<Map<String, dynamic>>()
          .map(AddressModel.fromJson)
          .toList();
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: _backendMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<String> removeAddress({required String addressId}) async {
    try {
      final response = await _dioClient.delete(
        path: ApiConstants.addressRemove,
        data: {'addressId': addressId.trim()},
        headers: {'content-type': 'application/json'},
      );
      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';
      if (!success) {
        throw ServerException(message: message);
      }
      return message;
    } on ServerException {
      rethrow;
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: _backendMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<String> selectAddress({required String addressId}) async {
    try {
      final response = await _dioClient.patch(
        path: ApiConstants.addressSelect,
        data: {'addressId': addressId.trim()},
        headers: {'content-type': 'application/json'},
      );
      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';
      if (!success) {
        throw ServerException(message: message);
      }
      return message;
    } on ServerException {
      rethrow;
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: _backendMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }
}
