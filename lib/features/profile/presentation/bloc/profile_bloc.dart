import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_user_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required GetUserProfile getUserProfile})
    : _getUserProfile = getUserProfile,
      super(const ProfileState()) {
    on<ProfileRequested>(_onProfileRequested);
  }

  final GetUserProfile _getUserProfile;

  Future<void> _onProfileRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, error: ''));

    final result = await _getUserProfile(const NoParams());
    result.fold(
      (failure) {
        emit(
          state.copyWith(status: ProfileStatus.failure, error: failure.message),
        );
      },
      (profile) {
        emit(state.copyWith(status: ProfileStatus.success, profile: profile));
      },
    );
  }
}
