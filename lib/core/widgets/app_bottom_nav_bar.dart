import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

double _navScreenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

/// The Home / Orders / Profile bottom bar shared across top-level screens, so
/// switching screens doesn't hide navigation behind a back arrow.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onHome,
    this.onOrders,
    this.onProfile,
  });

  final int currentIndex;
  final VoidCallback? onHome;
  final VoidCallback? onOrders;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final compact = _navScreenScale(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        12 * compact,
        8 * compact,
        12 * compact,
        10 * compact,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: currentIndex == 0,
            compact: compact,
            onTap: onHome,
          ),
          _BottomItem(
            icon: Icons.assignment_outlined,
            label: 'Orders',
            active: currentIndex == 1,
            compact: compact,
            onTap: onOrders,
          ),
          _BottomItem(
            icon: Icons.person_outline,
            label: 'Profile',
            active: currentIndex == 2,
            compact: compact,
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.compact,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final double compact;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.dashboardAccent;
    const inactiveColor = Color(0xFF99A0B5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * compact),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6 * compact),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24 * compact,
              color: active ? activeColor : inactiveColor,
            ),
            SizedBox(height: 4 * compact),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontSize: 11 * compact,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            SizedBox(height: 4 * compact),
            if (active)
              Container(
                width: 18 * compact,
                height: 3 * compact,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2 * compact),
                ),
              )
            else
              SizedBox(height: 3 * compact),
          ],
        ),
      ),
    );
  }
}
