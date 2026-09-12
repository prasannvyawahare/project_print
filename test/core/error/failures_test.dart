import 'package:flutter_test/flutter_test.dart';

import 'package:project_print/core/error/failures.dart';

void main() {
  group('Failure', () {
    test('ServerFailure exposes message/statusCode and equality via props', () {
      const a = ServerFailure('boom', statusCode: 500);
      const b = ServerFailure('boom', statusCode: 500);
      const c = ServerFailure('other', statusCode: 500);

      expect(a.message, 'boom');
      expect(a.statusCode, 500);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.props, ['boom', 500]);
    });

    test('ConnectionFailure defaults statusCode to null', () {
      const f = ConnectionFailure('offline');
      expect(f.message, 'offline');
      expect(f.statusCode, isNull);
    });

    test('CacheFailure carries message/statusCode', () {
      const f = CacheFailure('cache miss', statusCode: 404);
      expect(f.message, 'cache miss');
      expect(f.statusCode, 404);
    });

    test('different Failure subtypes with same message are not equal', () {
      const server = ServerFailure('x');
      const connection = ConnectionFailure('x');
      expect(server, isNot(equals(connection)));
    });
  });
}
