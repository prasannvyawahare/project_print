import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_welcome_message.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required GetWelcomeMessage getWelcomeMessage})
      : _getWelcomeMessage = getWelcomeMessage,
        super(const HomeState()) {
    on<HomeRequested>(_onHomeRequested);
  }

  final GetWelcomeMessage _getWelcomeMessage;

  Future<void> _onHomeRequested(
    HomeRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, error: ''));

    final result = await _getWelcomeMessage(const NoParams());

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            error: failure.message,
          ),
        );
      },
      (welcome) {
        emit(
          state.copyWith(
            status: HomeStatus.success,
            message: welcome.message,
          ),
        );
      },
    );
  }
}
