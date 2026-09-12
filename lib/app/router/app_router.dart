import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  const AppRouter._();

  /// Global navigator key so navigation can be triggered from outside the
  /// widget tree (e.g. the Dio error interceptor on an invalid token).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String main = '/main';
  static const String home = '/home';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(builder: (_) => const SplashPage());
      case onboarding:
        return MaterialPageRoute<void>(builder: (_) => const OnboardingPage());
      case auth:
        return MaterialPageRoute<void>(
          builder: (_) => BlocProvider<AuthBloc>(
            create: (_) => sl<AuthBloc>(),
            child: const AuthPage(),
          ),
        );
      case main:
        return MaterialPageRoute<void>(
          builder: (_) => BlocProvider<HomeBloc>(
            create: (_) => sl<HomeBloc>()..add(const HomeRequested()),
            child: const HomePage(),
          ),
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => BlocProvider<HomeBloc>(
            create: (_) => sl<HomeBloc>()..add(const HomeRequested()),
            child: const HomePage(),
          ),
        );
      case profile:
        return MaterialPageRoute<void>(
          // ProfileBloc is a DI singleton pre-fetched from the dashboard, so
          // reuse its instance here instead of creating (and re-fetching) a
          // new one.
          builder: (_) => BlocProvider<ProfileBloc>.value(
            value: sl<ProfileBloc>(),
            child: const ProfilePage(),
          ),
        );
      default:
        return MaterialPageRoute<void>(builder: (_) => const SplashPage());
    }
  }
}
