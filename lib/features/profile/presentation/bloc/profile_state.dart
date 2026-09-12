import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile_entity.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.error = '',
  });

  final ProfileStatus status;
  final UserProfileEntity? profile;
  final String error;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfileEntity? profile,
    String? error,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, profile, error];
}
