import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/temporary_auth_store.dart';
import '../../domain/entities/splash_config.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SplashConfig _config = const SplashConfig();
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(
      Duration(milliseconds: _config.displayMilliseconds),
      () {
        if (!mounted) return;
        final hasActiveSession = sl<TemporaryAuthStore>().token.isNotEmpty;
        final nextRoute = hasActiveSession
            ? AppRouter.home
            : AppRouter.onboarding;
        Navigator.of(context).pushReplacementNamed(nextRoute);
      },
    );
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.splashBackground,
        ),
        child: Stack(
          children: [
            _buildBackgroundBlobs(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing28,
                  vertical: AppDimensions.spacing22,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: AppDimensions.spacing116,
                      height: AppDimensions.spacing116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.print_rounded,
                        size: AppDimensions.icon54,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing34),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: AppDimensions.spacing70,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -1.4,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing74),
                    const Text(
                      AppConstants.splashHeadline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.splashWhite90,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing24),
                    Container(
                      height: 2.4,
                      width: AppDimensions.spacing190,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.splashAccent,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      AppConstants.splashStatus,
                      style: TextStyle(
                        color: AppColors.splashWhite64,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radius100,
                      ),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: 0.66,
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.16,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.splashProgress,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing30),
                    const Text(
                      AppConstants.splashFooter,
                      style: TextStyle(
                        color: AppColors.splashWhite60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -20,
          child: _Blob(
            size: AppDimensions.spacing220,
            color: AppColors.white.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          top: 80,
          right: -40,
          child: _Blob(
            size: AppDimensions.spacing260,
            color: AppColors.white.withValues(alpha: 0.04),
          ),
        ),
        Positioned(
          bottom: 90,
          left: -40,
          child: _Blob(
            size: AppDimensions.spacing220,
            color: AppColors.white.withValues(alpha: 0.04),
          ),
        ),
        Positioned(
          bottom: -40,
          right: -30,
          child: _Blob(
            size: AppDimensions.spacing260,
            color: AppColors.white.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
