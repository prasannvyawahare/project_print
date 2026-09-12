import 'package:flutter_test/flutter_test.dart';

import 'package:project_print/core/error/exceptions.dart';

void main() {
  test('ServerException toString includes status and message', () {
    final exception = ServerException(message: 'bad request', statusCode: 400);

    expect(exception.message, 'bad request');
    expect(exception.statusCode, 400);
    expect(
      exception.toString(),
      'ServerException(status: 400, message: bad request)',
    );
  });

  test('ServerException statusCode defaults to null', () {
    final exception = ServerException(message: 'oops');
    expect(exception.statusCode, isNull);
    expect(exception.toString(), 'ServerException(status: null, message: oops)');
  });
}
