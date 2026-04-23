import 'package:equatable/equatable.dart';

import '../../domain/entities/print_category_entity.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.message = '',
    this.error = '',
    this.categories = const <PrintCategoryEntity>[],
  });

  final HomeStatus status;
  final String message;
  final String error;
  final List<PrintCategoryEntity> categories;

  HomeState copyWith({
    HomeStatus? status,
    String? message,
    String? error,
    List<PrintCategoryEntity>? categories,
  }) {
    return HomeState(
      status: status ?? this.status,
      message: message ?? this.message,
      error: error ?? this.error,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [status, message, error, categories];
}
