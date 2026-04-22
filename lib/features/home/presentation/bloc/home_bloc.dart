import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_print_categories.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required GetPrintCategories getPrintCategories})
    : _getPrintCategories = getPrintCategories,
      super(const HomeState()) {
    on<HomeRequested>(_onHomeRequested);
  }

  final GetPrintCategories _getPrintCategories;

  Future<void> _onHomeRequested(
    HomeRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, error: ''));

    final result = await _getPrintCategories(const NoParams());
    print(
      " HomeBloc: Received result from GetPrintCategories use case - $result",
    );
    result.fold(
      (failure) {
        emit(
          state.copyWith(status: HomeStatus.failure, error: failure.message),
        );
      },
      (categoriesResult) {
        print(
          " HomeBloc: Successfully retrieved print categories - ${categoriesResult.categories.length} categories",
        );
        for (var category in categoriesResult.categories) {
          print(
            " HomeBloc: Category: ${category.printType}, Rate: ${category.rate}, Avatar: ${category.avatar}",
          );
        }

        emit(
          state.copyWith(
            status: HomeStatus.success,
            message: categoriesResult.message,
            categories: categoriesResult.categories,
          ),
        );
      },
    );
  }
}
