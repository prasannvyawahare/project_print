import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'PrintHub';

  static const String splashHeadline =
      'PRINT ANYTHING, DELIVERED IN 15 MINUTES';
  static const String splashStatus = 'OPTIMIZING PRINT QUEUE';
  static const String splashFooter = 'SECURE INDUSTRIAL NODE';

  static const String onboardingTitlePrecision = 'Precision Scanning';
  static const String onboardingDescriptionPrecision =
      'Upload with your camera or pick files from your cloud storage';
  static const String onboardingTitleProduction = 'Instant Production';
  static const String onboardingDescriptionProduction =
      'Calibrated print pipelines route jobs to the fastest machine';
  static const String onboardingTitleDelivery = 'Live Delivery';
  static const String onboardingDescriptionDelivery =
      'Track rider movement and receive your print at your doorstep';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';

  static const String authWelcomeLine1 = 'Welcome back';
  static const String authWelcomeLine2 = 'to ';
  static const String authSubtitle =
      'Your high-speed print station is one tap away';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithApple = 'Continue with Apple';
  static const String continueWithEmail = 'Continue with Email';
  static const String orDivider = 'OR';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String authFooter = 'PRECISION IN EVERY PIXEL';
}

class AppDurations {
  const AppDurations._();

  static const Duration onboardingPageAnimation = Duration(milliseconds: 280);
  static const Duration onboardingIndicatorAnimation = Duration(
    milliseconds: 220,
  );
}

class AppColors {
  const AppColors._();

  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

  static const Color brandBlue = Color(0xFF4A4FD3);
  static const Color splashBlue = Color(0xFF3B4EC9);
  static const Color brandTeal = Color(0xFF0B7A9A);
  static const Color deepTeal = Color(0xFF0A7A9A);
  static const Color navy = Color(0xFF272F49);

  static const Color authBackgroundTop = Color(0xFFEDEFF8);
  static const Color authBackgroundBottom = Color(0xFFDDE7F3);
  static const Color onboardingBackground = Color(0xFFEFF0F8);

  static const Color headingDark = Color(0xFF252E4A);
  static const Color headingDarkSecondary = Color(0xFF27304D);
  static const Color bodyText = Color(0xFF545E79);
  static const Color bodyTextSecondary = Color(0xFF59627D);
  static const Color mutedText = Color(0xFF656E87);
  static const Color footerText = Color(0xFF6A748D);

  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleButtonText = Color(0xFF2A334D);

  static const Color fadeShape = Color(0x24FFFFFF);
  static const Color splashWhite90 = Color(0xE6FFFFFF);
  static const Color splashWhite64 = Color(0xA3FFFFFF);
  static const Color splashWhite60 = Color(0x99FFFFFF);

  static const Color splashAccentBlue = Color(0xFF4A6FFF);
  static const Color splashAccentCyan = Color(0xFF6ED7FF);
  static const Color splashProgress = Color(0xFFA9E7FF);

  static const Color onboardingIndicatorInactive = Color(0xFFD3D8EA);
  static const Color miniIndicatorMuted = Color(0xFFD3DAF0);
  static const Color miniIndicatorAccent = Color(0xFF8BBFD0);

  static const Color heroBackLayer = Color(0xFFE3E5F2);
  static const Color heroFrontLayer = Color(0xFFF6F7FD);
  static const Color heroChip = Color(0xFFCACCF1);
  static const Color heroUploadIcon = Color(0xFF4A53DB);
  static const Color heroCameraIcon = Color(0xFF0A758E);
}

class AppGradients {
  const AppGradients._();

  static const LinearGradient splashBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.splashBlue, AppColors.brandTeal],
  );

  static const LinearGradient splashAccent = LinearGradient(
    colors: [AppColors.splashAccentBlue, AppColors.splashAccentCyan],
  );

  static const LinearGradient onboardingPrimaryButton = LinearGradient(
    colors: [Color(0xFF4753E0), AppColors.brandTeal],
  );

  static const LinearGradient onboardingIndicatorActive = LinearGradient(
    colors: [Color(0xFF4B54DC), Color(0xFF0B799A)],
  );

  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.authBackgroundTop, AppColors.authBackgroundBottom],
  );

  static const LinearGradient authCircle = LinearGradient(
    colors: [Color(0xFF4653DF), AppColors.deepTeal],
  );

  static const LinearGradient heroCenterLine = LinearGradient(
    colors: [Color(0xFF4B54DC), Color(0xFF0B799A)],
  );
}
