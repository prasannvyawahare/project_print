import 'package:equatable/equatable.dart';

import '../../domain/entities/address_entity.dart';

enum AddressStatus {
  initial,
  loading,
  success,
  failure,
  creating,
  removing,
  selecting,
}

class AddressState extends Equatable {
  const AddressState({
    this.status = AddressStatus.initial,
    this.addresses = const [],
    this.error = '',
  });

  final AddressStatus status;
  final List<AddressEntity> addresses;
  final String error;

  AddressState copyWith({
    AddressStatus? status,
    List<AddressEntity>? addresses,
    String? error,
  }) {
    return AddressState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, addresses, error];
}
