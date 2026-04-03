import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';

class OnboardingHeroCard extends StatelessWidget {
  const OnboardingHeroCard({
    super.key,
    required this.height,
    required this.scale,
  });

  final double height;
  final double scale;

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
            child: Stack(
              children: [
                Positioned(
                  left: AppDimensions.spacing28 * scale,
                  top: AppDimensions.spacing24 * scale,
                  child: Container(
                    height: AppDimensions.spacing16 * scale,
                    width: AppDimensions.spacing94 * scale,
                    decoration: BoxDecoration(
                      color: AppColors.heroChip,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radius20 * scale,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: AppDimensions.spacing180 * scale,
                  child: Container(
                    height: AppDimensions.spacing6 * scale,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.heroCenterLine,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -AppDimensions.spacing18 * scale,
            top: AppDimensions.spacing86 * scale,
            child: _RoundIcon(
              icon: Icons.cloud_upload_outlined,
              iconColor: AppColors.heroUploadIcon,
              scale: scale,
            ),
          ),
          Positioned(
            left: -AppDimensions.spacing18 * scale,
            bottom: AppDimensions.spacing78 * scale,
            child: _RoundIcon(
              icon: Icons.photo_camera_outlined,
              iconColor: AppColors.heroCameraIcon,
              scale: scale,
            ),
          ),
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
