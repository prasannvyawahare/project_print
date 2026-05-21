import '../../domain/entities/address_entity.dart';

class AddressModel extends AddressEntity {
  const AddressModel({
    required super.id,
    required super.addressType,
    required super.address,
    required super.flat,
    required super.landmark,
    required super.pincode,
    required super.selected,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] as String? ?? '',
      addressType: json['addressType'] as String? ?? '',
      address: json['address'] as String? ?? '',
      flat: json['flat'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      pincode: (json['pincode'] as num?)?.toInt() ?? 0,
      selected: json['selected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressType': addressType,
      'address': address,
      'flat': flat,
      'landmark': landmark,
      'pincode': pincode,
    };
  }
}
