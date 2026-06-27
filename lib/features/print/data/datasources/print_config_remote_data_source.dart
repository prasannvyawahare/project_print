import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/print_config_model.dart';

abstract class PrintConfigRemoteDataSource {
  Future<List<PrintConfigModel>> getPrintConfigs();
}

class PrintConfigRemoteDataSourceImpl implements PrintConfigRemoteDataSource {
  PrintConfigRemoteDataSourceImpl({
    required DioClient dioClient,
    required Logger logger,
  }) : _dioClient = dioClient,
       _logger = logger;

  final DioClient _dioClient;
  final Logger _logger;

  @override
  Future<List<PrintConfigModel>> getPrintConfigs() async {
    try {
      final response = await _dioClient.get(
        path: ApiConstants.printConfigPath,
      );
      final responseMap = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : const <String, dynamic>{};
      final data = responseMap['data'];

      return data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(PrintConfigModel.fromJson)
                .toList(growable: false)
          : const <PrintConfigModel>[];
    } on DioException catch (error, stackTrace) {
      _logger.e(
        'Print config fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw ServerException(
        message: error.message ?? 'Unable to load print configurations.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
