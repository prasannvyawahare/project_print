import 'package:flutter_test/flutter_test.dart';
import 'package:project_print/features/home/data/models/welcome_model.dart';

void main() {
  group('WelcomeModel.fromJson', () {
    test('uses title from json when present and non-empty', () {
      final model = WelcomeModel.fromJson({'title': 'Hello there'});
      expect(model.message, 'Hello there');
    });

    test('falls back to default message when title is null', () {
      final model = WelcomeModel.fromJson(const {});
      expect(model.message, 'Welcome from clean architecture template');
    });

    test('falls back to default message when title is empty', () {
      final model = WelcomeModel.fromJson({'title': ''});
      expect(model.message, 'Welcome from clean architecture template');
    });
  });

  group('WelcomeModel.toJson', () {
    test('round-trips message', () {
      const model = WelcomeModel(message: 'hi');
      expect(model.toJson(), {'message': 'hi'});
    });
  });
}
