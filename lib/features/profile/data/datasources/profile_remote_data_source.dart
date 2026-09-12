import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({
    required DioClient dioClient,
    required Logger logger,
  }) : _dioClient = dioClient,
       _logger = logger;

  final DioClient _dioClient;
  final Logger _logger;

  @override
  Future<UserProfileModel> getProfile() async {
    try {
      final response = await _dioClient.get(path: ApiConstants.userProfile);
      final data = response.data as Map<String, dynamic>?;
      return UserProfileModel.fromJson(data ?? <String, dynamic>{});
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final backendMessage = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ??
                responseData['error']?.toString())
          : null;
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: backendMessage ?? error.message ?? 'Unexpected network error',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
