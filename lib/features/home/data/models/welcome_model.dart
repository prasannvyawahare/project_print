import '../../domain/entities/welcome_entity.dart';

class WelcomeModel extends WelcomeEntity {
  const WelcomeModel({required super.message});

  factory WelcomeModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final message = (title == null || title.isEmpty)
        ? 'Welcome from clean architecture template'
        : title;

    return WelcomeModel(message: message);
  }

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}
