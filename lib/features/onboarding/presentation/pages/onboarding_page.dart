import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/onboarding_step.dart';
import '../widgets/onboarding_hero_card.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const List<OnboardingStep> _steps = [
    OnboardingStep(
      title: AppConstants.onboardingTitlePrecision,
      description: AppConstants.onboardingDescriptionPrecision,
      highlight: 'SCAN',
    ),
    OnboardingStep(
      title: AppConstants.onboardingTitleProduction,
      description: AppConstants.onboardingDescriptionProduction,
      highlight: 'PRINT',
    ),
    OnboardingStep(
      title: AppConstants.onboardingTitleDelivery,
      description: AppConstants.onboardingDescriptionDelivery,
      highlight: 'DELIVER',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: AppDurations.onboardingPageAnimation,
        curve: Curves.easeOut,
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.auth);
  }

  void _skip() {
    Navigator.of(context).pushReplacementNamed(AppRouter.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = (width / AppDimensions.designWidth).clamp(0.82, 1.08);
            final isCompact = height < AppDimensions.compactHeightBreakpoint;

            final titleSize = (AppDimensions.spacing52 * scale)
                .clamp(AppDimensions.spacing36, AppDimensions.spacing52)
                .toDouble();
            final descriptionSize = (AppDimensions.spacing22 * scale)
                .clamp(AppDimensions.spacing16, AppDimensions.spacing22)
                .toDouble();
            final buttonTextSize = (AppDimensions.spacing24 * scale)
                .clamp(AppDimensions.spacing18, AppDimensions.spacing24)
                .toDouble();
            final skipSize = (AppDimensions.spacing22 * scale)
                .clamp(AppDimensions.spacing16, AppDimensions.spacing22)
                .toDouble();
            final buttonHeight =
                (isCompact
                    ? AppDimensions.spacing64
                    : AppDimensions.spacing82) *
                scale;
            final heroHeight = (height * (isCompact ? 0.36 : 0.44)).clamp(
              AppDimensions.spacing230,
              AppDimensions.spacing420,
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.spacing24 * scale,
                AppDimensions.spacing10 * scale,
                AppDimensions.spacing24 * scale,
                AppDimensions.spacing18 * scale,
              ),
              child: Column(
                children: [
                  SizedBox(height: AppDimensions.spacing8 * scale),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return Column(
                          children: [
                            OnboardingHeroCard(
                              height: heroHeight,
                              scale: scale,
                            ),
                            SizedBox(height: AppDimensions.spacing20 * scale),
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.headingDarkSecondary,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                height: 0.95,
                              ),
                            ),
                            SizedBox(height: AppDimensions.spacing14 * scale),
                            Text(
                              step.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.bodyTextSecondary,
                                fontSize: descriptionSize,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacing12 * scale),
                  _OnboardingIndicator(
                    index: _currentIndex,
                    count: _steps.length,
                  ),
                  SizedBox(height: AppDimensions.spacing18 * scale),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radius40,
                      ),
                      gradient: AppGradients.onboardingPrimaryButton,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F4753E0),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radius40,
                            ),
                          ),
                        ),
                        child: Text(
                          _currentIndex == _steps.length - 1
                              ? AppConstants.getStarted
                              : AppConstants.next,
                          style: TextStyle(
                            fontSize: buttonTextSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacing8 * scale),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      AppConstants.skip,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: skipSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingIndicator extends StatelessWidget {
  const _OnboardingIndicator({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: AppDurations.onboardingIndicatorAnimation,
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing6,
          ),
          width: isActive ? AppDimensions.spacing62 : AppDimensions.spacing22,
          height: AppDimensions.spacing12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radius99),
            gradient: isActive ? AppGradients.onboardingIndicatorActive : null,
            color: isActive ? null : AppColors.onboardingIndicatorInactive,
          ),
        );
      }),
    );
  }
}
