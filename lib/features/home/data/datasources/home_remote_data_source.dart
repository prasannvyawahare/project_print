import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/print_categories_response_model.dart';
import '../models/welcome_model.dart';

abstract class HomeRemoteDataSource {
  Future<WelcomeModel> getWelcomeMessage();
  Future<PrintCategoriesResponseModel> getPrintCategories();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl({
    required DioClient dioClient,
    required Logger logger,
  }) : _dioClient = dioClient,
       _logger = logger;

  final DioClient _dioClient;
  final Logger _logger;

  @override
  Future<WelcomeModel> getWelcomeMessage() async {
    try {
      final response = await _dioClient.get(path: ApiConstants.welcomePath);
      final data = response.data as Map<String, dynamic>?;
      return WelcomeModel.fromJson(data ?? <String, dynamic>{});
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: error.message ?? 'Unexpected network error',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<PrintCategoriesResponseModel> getPrintCategories() async {
    try {
      final response = await _dioClient.get(path: ApiConstants.printTypePath);
      final data = response.data as Map<String, dynamic>?;
      return PrintCategoriesResponseModel.fromJson(data ?? <String, dynamic>{});
    } on DioException catch (error) {
      _logger.e('Dio error', error: error, stackTrace: error.stackTrace);
      throw ServerException(
        message: error.message ?? 'Unexpected network error',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
