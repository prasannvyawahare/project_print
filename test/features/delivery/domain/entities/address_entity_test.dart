import 'package:flutter_test/flutter_test.dart';

import 'package:project_print/features/delivery/domain/entities/address_entity.dart';

void main() {
  const base = AddressEntity(
    id: 'a1',
    addressType: 'home',
    address: '123 Street',
    flat: '4B',
    landmark: 'Near park',
    pincode: 400097,
    selected: true,
  );

  test('two entities with identical fields are equal', () {
    const other = AddressEntity(
      id: 'a1',
      addressType: 'home',
      address: '123 Street',
      flat: '4B',
      landmark: 'Near park',
      pincode: 400097,
      selected: true,
    );

    expect(base, other);
    expect(base.hashCode, other.hashCode);
  });

  test('entities differing in a single field are not equal', () {
    const other = AddressEntity(
      id: 'a1',
      addressType: 'home',
      address: '123 Street',
      flat: '4B',
      landmark: 'Near park',
      pincode: 400097,
      selected: false,
    );

    expect(base, isNot(other));
  });

  test('props exposes every field in declaration order', () {
    expect(base.props, [
      'a1',
      'home',
      '123 Street',
      '4B',
      'Near park',
      400097,
      true,
    ]);
  });
}
