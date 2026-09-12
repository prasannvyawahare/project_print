import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_print/core/error/failures.dart';
import 'package:project_print/core/usecase/usecase.dart';

class _EchoUseCase implements UseCase<int, int> {
  @override
  Future<Either<Failure, int>> call(int params) async => Right(params);
}

void main() {
  test('NoParams has empty props and is equal to another NoParams', () {
    const a = NoParams();
    const b = NoParams();
    expect(a.props, isEmpty);
    expect(a, equals(b));
  });

  test('UseCase implementations can be called and return an Either', () async {
    final useCase = _EchoUseCase();
    final result = await useCase.call(42);
    expect(result, const Right<Failure, int>(42));
  });
}
