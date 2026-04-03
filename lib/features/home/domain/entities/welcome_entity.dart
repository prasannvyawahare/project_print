import 'package:equatable/equatable.dart';

class WelcomeEntity extends Equatable {
  const WelcomeEntity({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
