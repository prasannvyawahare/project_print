import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';

class OnboardingHeroCard extends StatelessWidget {
  const OnboardingHeroCard({
    super.key,
    required this.height,
    required this.scale,
    required this.image,
  });

  final double height;
  final double scale;

  /// Asset path of the illustration shown inside the front card.
  final String image;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: AppDimensions.spacing10 * scale,
            left: AppDimensions.spacing24 * scale,
            right: AppDimensions.spacing24 * scale,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.heroBackLayer,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radius54 * scale,
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.heroFrontLayer,
              borderRadius: BorderRadius.circular(
                AppDimensions.radius54 * scale,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220D1636),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimensions.radius54 * scale,
              ),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Positioned(
          //   right: -AppDimensions.spacing18 * scale,
          //   top: AppDimensions.spacing86 * scale,
          //   child: _RoundIcon(
          //     icon: Icons.cloud_upload_outlined,
          //     iconColor: AppColors.heroUploadIcon,
          //     scale: scale,
          //   ),
          // ),
          // Positioned(
          // left: -AppDimensions.spacing18 * scale,
          // bottom: AppDimensions.spacing78 * scale,
          // child: _RoundIcon(
          //   icon: Icons.photo_camera_outlined,
          //   iconColor: AppColors.heroCameraIcon,
          //   scale: scale,
          // ),
          //e),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.iconColor,
    required this.scale,
  });

  final IconData icon;
  final Color iconColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.spacing98 * scale,
      height: AppDimensions.spacing98 * scale,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFDFDFD),
        boxShadow: [
          BoxShadow(
            color: Color(0x250D1636),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: AppDimensions.icon36 * scale),
    );
  }
}
