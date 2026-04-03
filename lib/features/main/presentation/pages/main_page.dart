import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/main_nav_item.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const List<MainNavItem> _items = [
    MainNavItem(label: 'Home', icon: Icons.home_rounded),
    MainNavItem(label: 'Orders', icon: Icons.receipt_long_rounded),
    MainNavItem(label: 'Uploads', icon: Icons.cloud_upload_rounded),
    MainNavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(
        child: Text(
          'Main Screen: ${_items[_index].label}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: _items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
