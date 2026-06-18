import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.success) {
            Navigator.of(context).pushReplacementNamed(AppRouter.main);
          }

          if (state.status == AuthStatus.loggedOut) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(const SnackBar(content: Text('Logged out')));
          }

          if (state.status == AuthStatus.failure &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage)));
          }
        },
        builder: (context, state) {
          final isSigningIn = state.isLoading;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppGradients.authBackground,
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final scale = (width / AppDimensions.designWidth).clamp(
                      0.8,
                      1.05,
                    );
                    final isCompact =
                        height < AppDimensions.compactHeightBreakpoint;

                    final logoSize = (AppDimensions.icon38 * scale)
                        .clamp(AppDimensions.spacing28, AppDimensions.icon38)
                        .toDouble();
                    final brandSize = (AppDimensions.spacing24 * scale)
                        .clamp(AppDimensions.spacing18, AppDimensions.spacing24)
                        .toDouble();
                    final titleSize = (AppDimensions.spacing64 * scale)
                        .clamp(AppDimensions.spacing30, AppDimensions.spacing48)
                        .toDouble();
                    final subtitleSize = (AppDimensions.spacing24 * scale)
                        .clamp(AppDimensions.spacing14, AppDimensions.spacing18)
                        .toDouble();
                    final socialButtonHeight = (AppDimensions.spacing86 * scale)
                        .clamp(AppDimensions.spacing48, AppDimensions.spacing64)
                        .toDouble();
                    final socialTextSize = (AppDimensions.spacing18 * scale)
                        .clamp(AppDimensions.spacing14, AppDimensions.spacing18)
                        .toDouble();
                    final circleSize = (AppDimensions.spacing165 * scale)
                        .clamp(
                          AppDimensions.spacing92,
                          AppDimensions.spacing124,
                        )
                        .toDouble();

                    return Stack(
                      children: [
                        _buildBackgroundShapes(scale),
                        SafeArea(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacing24 * scale,
                              vertical: AppDimensions.spacing12 * scale,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.print_rounded,
                                      color: AppColors.brandBlue,
                                      size: logoSize,
                                    ),
                                    SizedBox(
                                      width: AppDimensions.spacing8 * scale,
                                    ),
                                    Text(
                                      AppConstants.appName,
                                      style: TextStyle(
                                        color: AppColors.brandBlue,
                                        fontSize: brandSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: IconButton(
                                        tooltip: 'Temporary logout',
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: isSigningIn
                                            ? null
                                            : () =>
                                                  context.read<AuthBloc>().add(
                                                    const AuthLogoutRequested(),
                                                  ),
                                        icon: const Icon(
                                          Icons.logout,
                                          size: 16,
                                          color: AppColors.brandBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      (isCompact
                                          ? AppDimensions.spacing16
                                          : AppDimensions.spacing24) *
                                      scale,
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: circleSize,
                                    height: circleSize,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppGradients.authCircle,
                                    ),
                                    child: Icon(
                                      Icons.bolt_rounded,
                                      color: AppColors.white,
                                      size: (AppDimensions.icon80 * scale)
                                          .clamp(
                                            AppDimensions.spacing44,
                                            AppDimensions.spacing62,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      (isCompact
                                          ? AppDimensions.spacing12
                                          : AppDimensions.spacing16) *
                                      scale,
                                ),
                                Center(
                                  child: Text.rich(
                                    textAlign: TextAlign.center,
                                    TextSpan(
                                      style: TextStyle(
                                        color: AppColors.headingDark,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w800,
                                        height: 0.95,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text:
                                              '${AppConstants.authWelcomeLine1}\n',
                                        ),
                                        TextSpan(
                                          text: AppConstants.authWelcomeLine2,
                                        ),
                                        TextSpan(
                                          text: AppConstants.appName,
                                          style: TextStyle(
                                            color: AppColors.brandBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: AppDimensions.spacing30 * scale,
                                ),
                                Center(
                                  child: Text(
                                    AppConstants.authSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.bodyText,
                                      fontSize: subtitleSize,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      (isCompact
                                          ? AppDimensions.spacing30
                                          : AppDimensions.spacing40) *
                                      scale,
                                ),

                                _SocialButton(
                                  onPressed: isSigningIn
                                      ? null
                                      : () => context.read<AuthBloc>().add(
                                          const AuthGoogleSignInRequested(),
                                        ),
                                  text: AppConstants.continueWithGoogle,
                                  backgroundColor: AppColors.white,
                                  textColor: AppColors.googleButtonText,
                                  buttonHeight: socialButtonHeight,
                                  textSize: socialTextSize,
                                  iconSlotWidth:
                                      (AppDimensions.spacing44 * scale).clamp(
                                        AppDimensions.spacing34,
                                        AppDimensions.spacing44,
                                      ),
                                  icon: Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize:
                                          (AppDimensions.spacing36 * scale)
                                              .clamp(
                                                AppDimensions.spacing24,
                                                AppDimensions.spacing36,
                                              ),
                                      height: 0.8,
                                      color: AppColors.googleRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: AppDimensions.spacing10 * scale,
                                ),
                                _SocialButton(
                                  onPressed: isSigningIn
                                      ? null
                                      : () => context.read<AuthBloc>().add(
                                          const AuthAppleSignInRequested(),
                                        ),
                                  text: AppConstants.continueWithApple,
                                  backgroundColor: AppColors.navy,
                                  textColor: AppColors.white,
                                  buttonHeight: socialButtonHeight,
                                  textSize: socialTextSize,
                                  iconSlotWidth:
                                      (AppDimensions.spacing44 * scale).clamp(
                                        AppDimensions.spacing34,
                                        AppDimensions.spacing44,
                                      ),
                                  icon: Icon(
                                    Icons.apple,
                                    color: AppColors.white,
                                    size: (AppDimensions.spacing34 * scale)
                                        .clamp(
                                          AppDimensions.spacing24,
                                          AppDimensions.spacing34,
                                        ),
                                  ),
                                ),
                                SizedBox(
                                  height: AppDimensions.spacing56 * scale,
                                ),
                                const Spacer(),
                                // Row(
                                //   children: [
                                //     Expanded(
                                //       child: OutlinedButton(
                                //         onPressed: isSigningIn
                                //             ? null
                                //             : () => _continue(context),
                                //         style: OutlinedButton.styleFrom(
                                //           minimumSize: Size.fromHeight(
                                //             (AppDimensions.spacing46 * scale)
                                //                 .clamp(
                                //                   AppDimensions.spacing40,
                                //                   AppDimensions.spacing46,
                                //                 ),
                                //           ),
                                //           side: const BorderSide(
                                //             color: AppColors.brandBlue,
                                //           ),
                                //           shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.circular(
                                //               AppDimensions.radius18,
                                //             ),
                                //           ),
                                //         ),
                                //         child: Text(
                                //           AppConstants.login,
                                //           style: TextStyle(
                                //             fontSize:
                                //                 (AppDimensions.spacing16 *
                                //                         scale)
                                //                     .clamp(
                                //                       AppDimensions.spacing14,
                                //                       AppDimensions.spacing16,
                                //                     ),
                                //           ),
                                //         ),
                                //       ),
                                //     ),
                                //     SizedBox(
                                //       width: AppDimensions.spacing10 * scale,
                                //     ),
                                //     Expanded(
                                //       child: ElevatedButton(
                                //         onPressed: isSigningIn
                                //             ? null
                                //             : () => _continue(context),
                                //         style: ElevatedButton.styleFrom(
                                //           minimumSize: Size.fromHeight(
                                //             (AppDimensions.spacing46 * scale)
                                //                 .clamp(
                                //                   AppDimensions.spacing40,
                                //                   AppDimensions.spacing46,
                                //                 ),
                                //           ),
                                //           backgroundColor: AppColors.brandBlue,
                                //           foregroundColor: AppColors.white,
                                //           shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.circular(
                                //               AppDimensions.radius18,
                                //             ),
                                //           ),
                                //         ),
                                //         child: Text(
                                //           AppConstants.register,
                                //           style: TextStyle(
                                //             fontSize:
                                //                 (AppDimensions.spacing16 *
                                //                         scale)
                                //                     .clamp(
                                //                       AppDimensions.spacing14,
                                //                       AppDimensions.spacing16,
                                //                     ),
                                //           ),
                                //         ),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                Center(
                                  child: Column(
                                    children: [
                                      if (isSigningIn)
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            bottom: AppDimensions.spacing8,
                                          ),
                                          child: SizedBox(
                                            width: AppDimensions.spacing20,
                                            height: AppDimensions.spacing20,
                                            child: CircularProgressIndicator(
                                              strokeWidth:
                                                  AppDimensions.spacing2,
                                            ),
                                          ),
                                        ),
                                      _MiniIndicator(scale: scale),
                                      SizedBox(
                                        height: AppDimensions.spacing8 * scale,
                                      ),
                                      Text(
                                        AppConstants.authFooter,
                                        style: TextStyle(
                                          color: AppColors.footerText,
                                          fontSize: (13 * scale).clamp(
                                            AppDimensions.spacing10,
                                            AppDimensions.spacing14,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundShapes(double scale) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: AppDimensions.spacing110 * scale,
            left: AppDimensions.spacing40 * scale,
            child: _FadedShape(
              width: AppDimensions.spacing220 * scale,
              height: AppDimensions.spacing420 * scale,
            ),
          ),
          Positioned(
            top: AppDimensions.spacing124 * scale,
            right: AppDimensions.spacing70 * scale,
            child: _FadedShape(
              width: AppDimensions.spacing110 * scale,
              height: AppDimensions.spacing220 * scale,
            ),
          ),
          Positioned(
            bottom: AppDimensions.spacing100 * scale,
            right: AppDimensions.spacing48 * scale,
            child: _FadedShape(
              width: AppDimensions.spacing190 * scale,
              height: AppDimensions.spacing300 * scale,
            ),
          ),
          Positioned(
            bottom: AppDimensions.spacing150 * scale,
            left: AppDimensions.spacing44 * scale,
            child: _FadedShape(
              width: AppDimensions.spacing100 * scale,
              height: AppDimensions.spacing220 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.buttonHeight,
    required this.textSize,
    required this.iconSlotWidth,
  });

  final VoidCallback? onPressed;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final double buttonHeight;
  final double textSize;
  final double iconSlotWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(buttonHeight),
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius46),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSlotWidth,
              child: Center(child: icon),
            ),
            const SizedBox(width: AppDimensions.spacing8),
            Text(
              text,
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FadedShape extends StatelessWidget {
  const _FadedShape({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimensions.radius52),
      ),
    );
  }
}

class _MiniIndicator extends StatelessWidget {
  const _MiniIndicator({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _bar(
          (AppDimensions.spacing92 * scale).clamp(
            AppDimensions.spacing56,
            AppDimensions.spacing92,
          ),
          AppColors.miniIndicatorMuted,
        ),
        SizedBox(width: AppDimensions.spacing12 * scale),
        _bar(
          (AppDimensions.spacing44 * scale).clamp(
            AppDimensions.spacing28,
            AppDimensions.spacing44,
          ),
          AppColors.miniIndicatorAccent,
        ),
        SizedBox(width: AppDimensions.spacing12 * scale),
        _bar(
          (AppDimensions.spacing92 * scale).clamp(
            AppDimensions.spacing56,
            AppDimensions.spacing92,
          ),
          AppColors.miniIndicatorMuted,
        ),
      ],
    );
  }

  Widget _bar(double width, Color color) {
    return Container(
      width: width,
      height: AppDimensions.spacing8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radius100),
        color: color,
      ),
    );
  }
}
