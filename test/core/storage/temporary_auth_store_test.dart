import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_print/core/storage/temporary_auth_store.dart';

void main() {
  late TemporaryAuthStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = TemporaryAuthStore(preferences: prefs);
  });

  test('mobile/token/userId/displayName default to empty when unset', () {
    expect(store.mobile, '');
    expect(store.token, '');
    expect(store.userId, '');
    expect(store.displayName, '');
  });

  test('save trims and persists mobile/token/displayName', () async {
    await store.save(
      mobile: '  9876543210  ',
      token: '  tok123  ',
      displayName: '  Jane  ',
    );

    expect(store.mobile, '9876543210');
    expect(store.token, 'tok123');
    expect(store.displayName, 'Jane');
  });

  test('save without displayName leaves displayName unset', () async {
    await store.save(mobile: '111', token: 'tok');

    expect(store.mobile, '111');
    expect(store.token, 'tok');
    expect(store.displayName, '');
  });

  test('saveUserId trims and persists userId', () async {
    await store.saveUserId('  user-42  ');

    expect(store.userId, 'user-42');
  });

  test('clear removes mobile/token/userId/displayName', () async {
    await store.save(mobile: '111', token: 'tok', displayName: 'Jane');
    await store.saveUserId('user-42');

    await store.clear();

    expect(store.mobile, '');
    expect(store.token, '');
    expect(store.userId, '');
    expect(store.displayName, '');
  });
}
