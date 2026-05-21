import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  const AddressEntity({
    required this.id,
    required this.addressType,
    required this.address,
    required this.flat,
    required this.landmark,
    required this.pincode,
    required this.selected,
  });

  final String id;
  final String addressType;
  final String address;
  final String flat;
  final String landmark;
  final int pincode;
  final bool selected;

  @override
  List<Object?> get props => [
    id,
    addressType,
    address,
    flat,
    landmark,
    pincode,
    selected,
  ];
}
