class ServerException implements Exception {
  ServerException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}
