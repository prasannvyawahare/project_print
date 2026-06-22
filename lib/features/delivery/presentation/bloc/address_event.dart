import 'package:equatable/equatable.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

class AddressFetchRequested extends AddressEvent {
  const AddressFetchRequested();
}

class AddressCreateRequested extends AddressEvent {
  const AddressCreateRequested({
    required this.addressType,
    required this.address,
    required this.flat,
    required this.landmark,
    required this.pincode,
  });

  final String addressType;
  final String address;
  final String flat;
  final String landmark;
  final int pincode;

  @override
  List<Object?> get props => [addressType, address, flat, landmark, pincode];
}

class AddressRemoveRequested extends AddressEvent {
  const AddressRemoveRequested({required this.addressId});

  final String addressId;

  @override
  List<Object?> get props => [addressId];
}

class AddressSelectRequested extends AddressEvent {
  const AddressSelectRequested({required this.addressId});

  final String addressId;

  @override
  List<Object?> get props => [addressId];
}
