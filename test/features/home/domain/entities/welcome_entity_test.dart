import 'package:flutter_test/flutter_test.dart';
import 'package:project_print/features/home/domain/entities/welcome_entity.dart';

void main() {
  group('WelcomeEntity', () {
    test('supports value equality', () {
      const a = WelcomeEntity(message: 'hi');
      const b = WelcomeEntity(message: 'hi');
      const c = WelcomeEntity(message: 'other');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('props contains message', () {
      const entity = WelcomeEntity(message: 'hi');
      expect(entity.props, ['hi']);
    });
  });
}
