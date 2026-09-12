import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_print/features/main/domain/entities/main_nav_item.dart';

void main() {
  group('MainNavItem', () {
    test('stores label and icon', () {
      const item = MainNavItem(label: 'Home', icon: Icons.home_rounded);

      expect(item.label, 'Home');
      expect(item.icon, Icons.home_rounded);
    });
  });
}
