import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_address.dart';
import '../../domain/usecases/get_addresses.dart';
import '../../domain/usecases/remove_address.dart';
import '../../domain/usecases/select_address.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc({
    required CreateAddress createAddress,
    required GetAddresses getAddresses,
    required RemoveAddress removeAddress,
    required SelectAddress selectAddress,
  }) : _createAddress = createAddress,
       _getAddresses = getAddresses,
       _removeAddress = removeAddress,
       _selectAddress = selectAddress,
       super(const AddressState()) {
    on<AddressFetchRequested>(_onFetchRequested);
    on<AddressCreateRequested>(_onCreateRequested);
    on<AddressRemoveRequested>(_onRemoveRequested);
    on<AddressSelectRequested>(_onSelectRequested);
  }

  final CreateAddress _createAddress;
  final GetAddresses _getAddresses;
  final RemoveAddress _removeAddress;
  final SelectAddress _selectAddress;

  Future<void> _onFetchRequested(
    AddressFetchRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.loading, error: ''));
    final result = await _getAddresses(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(status: AddressStatus.failure, error: failure.message),
      ),
      (addresses) => emit(
        state.copyWith(status: AddressStatus.success, addresses: addresses),
      ),
    );
  }

  Future<void> _onCreateRequested(
    AddressCreateRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.creating, error: ''));
    final result = await _createAddress(
      CreateAddressParams(
        addressType: event.addressType,
        address: event.address,
        flat: event.flat,
        landmark: event.landmark,
        pincode: event.pincode,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(status: AddressStatus.failure, error: failure.message),
      ),
      (_) => add(const AddressFetchRequested()),
    );
  }

  Future<void> _onRemoveRequested(
    AddressRemoveRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.removing, error: ''));
    final result = await _removeAddress(
      RemoveAddressParams(addressId: event.addressId),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(status: AddressStatus.failure, error: failure.message),
      ),
      (_) => add(const AddressFetchRequested()),
    );
  }

  Future<void> _onSelectRequested(
    AddressSelectRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.selecting, error: ''));
    final result = await _selectAddress(
      SelectAddressParams(addressId: event.addressId),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(status: AddressStatus.failure, error: failure.message),
      ),
      (_) => add(const AddressFetchRequested()),
    );
  }
}
