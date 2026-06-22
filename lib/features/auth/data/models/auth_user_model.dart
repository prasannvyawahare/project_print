import '../../domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUserEntity {
  const AuthUserModel({
    required super.email,
    super.displayName,
    super.mobile,
    super.authToken,
  });

  Map<String, dynamic> toVerifyPayload({required String mobileNumber}) {
    return {'mobile': mobileNumber, 'email': email};
  }
}
