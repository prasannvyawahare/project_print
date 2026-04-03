import 'package:equatable/equatable.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.message = '',
    this.error = '',
  });

  final HomeStatus status;
  final String message;
  final String error;

  HomeState copyWith({
    HomeStatus? status,
    String? message,
    String? error,
  }) {
    return HomeState(
      status: status ?? this.status,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, message, error];
}
