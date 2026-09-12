import 'package:flutter_test/flutter_test.dart';

import 'package:project_print/features/delivery/data/models/address_model.dart';
import 'package:project_print/features/delivery/domain/entities/address_entity.dart';

void main() {
  group('AddressModel.fromJson', () {
    test('parses all fields from a full json map', () {
      final model = AddressModel.fromJson(const {
        '_id': 'a1',
        'addressType': 'home',
        'address': '123 Street',
        'flat': '4B',
        'landmark': 'Near park',
        'pincode': 400097,
        'selected': true,
      });

      expect(model.id, 'a1');
      expect(model.addressType, 'home');
      expect(model.address, '123 Street');
      expect(model.flat, '4B');
      expect(model.landmark, 'Near park');
      expect(model.pincode, 400097);
      expect(model.selected, true);
    });

    test('defaults every field when the json map is empty', () {
      final model = AddressModel.fromJson(const {});

      expect(model.id, '');
      expect(model.addressType, '');
      expect(model.address, '');
      expect(model.flat, '');
      expect(model.landmark, '');
      expect(model.pincode, 0);
      expect(model.selected, false);
    });

    test('defaults fields that are explicitly null', () {
      final model = AddressModel.fromJson(const {
        '_id': null,
        'addressType': null,
        'pincode': null,
        'selected': null,
      });

      expect(model.id, '');
      expect(model.addressType, '');
      expect(model.pincode, 0);
      expect(model.selected, false);
    });

    test('throws a type error when a field has an incompatible type', () {
      // NOTE: fromJson only defaults on null/missing keys (via `??`) — a
      // present value of the wrong type (e.g. pincode as a String) is cast
      // directly and throws instead of being coerced. Documented here as
      // current behavior rather than "fixed", per test-writing instructions.
      expect(
        () => AddressModel.fromJson(const {'pincode': 'not-a-number'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('accepts a double pincode and truncates to int', () {
      final model = AddressModel.fromJson(const {'pincode': 400097.9});
      expect(model.pincode, 400097);
    });
  });

  group('toJson', () {
    test('serializes editable fields but omits id and selected', () {
      const model = AddressModel(
        id: 'a1',
        addressType: 'home',
        address: '123 Street',
        flat: '4B',
        landmark: 'Near park',
        pincode: 400097,
        selected: true,
      );

      final json = model.toJson();

      expect(json, {
        'addressType': 'home',
        'address': '123 Street',
        'flat': '4B',
        'landmark': 'Near park',
        'pincode': 400097,
      });
      expect(json.containsKey('_id'), false);
      expect(json.containsKey('selected'), false);
    });
  });

  test('AddressModel is an AddressEntity and supports value equality', () {
    const modelA = AddressModel(
      id: 'a1',
      addressType: 'home',
      address: 'X',
      flat: '1',
      landmark: '',
      pincode: 1,
      selected: false,
    );
    const modelB = AddressModel(
      id: 'a1',
      addressType: 'home',
      address: 'X',
      flat: '1',
      landmark: '',
      pincode: 1,
      selected: false,
    );

    expect(modelA, isA<AddressEntity>());
    expect(modelA, modelB);
  });
}
