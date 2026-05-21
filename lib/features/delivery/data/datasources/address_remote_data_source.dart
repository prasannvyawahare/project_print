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
      final data = response.data as Map<String, dynamic>;
      final addressData = data['data'] as Map<String, dynamic>;
      return AddressModel.fromJson(addressData);
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: error.message ?? 'Unexpected network error',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _dioClient.get(path: ApiConstants.addressGet);
      final data = response.data as Map<String, dynamic>;
      final addressData = data['data'] as Map<String, dynamic>;
      final addressList = addressData['address'] as List<dynamic>;
      return addressList
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: error.message ?? 'Unexpected network error',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<String> removeAddress({required String addressId}) async {
    try {
      final response = await _dioClient.post(
        path: ApiConstants.addressRemove,
        data: {'addressId': addressId},
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
        message: error.message ?? 'Unexpected network error',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<String> selectAddress({required String addressId}) async {
    try {
      final response = await _dioClient.post(
        path: ApiConstants.addressSelect,
        data: {'addressId': addressId},
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
        message: error.message ?? 'Unexpected network error',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
