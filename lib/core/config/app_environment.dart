import 'package:package_info_plus/package_info_plus.dart';

/// The build flavor the app is currently running as.
///
/// Mirrors the Android product flavors declared in `android/app/build.gradle.kts`
/// (`internal`, `dev`, `prod`) and their application id suffixes.
enum AppFlavor { internal, dev, prod }

/// Resolves the running [AppFlavor] once at startup so the rest of the app can
/// read it synchronously.
///
/// The flavor is derived from the application/bundle id set by the native
/// build, so no extra `--dart-define` is needed — `flutter run --flavor <x>`
/// is enough:
///   * `com.printhub.mobile.debug` -> [AppFlavor.internal]
///   * `com.printhub.mobile.dev`   -> [AppFlavor.dev]
///   * `com.printhub.mobile`       -> [AppFlavor.prod]
class AppEnvironment {
  AppEnvironment._();

  static AppFlavor _flavor = AppFlavor.internal;

  /// The resolved flavor. Defaults to [AppFlavor.internal] until [init] runs.
  static AppFlavor get flavor => _flavor;

  /// True only for the production flavor. Payment and other integrations use
  /// this to pick live vs. sandbox configuration.
  static bool get isProduction => _flavor == AppFlavor.prod;

  /// Reads the package id and maps it to an [AppFlavor]. Call once from `main`
  /// before `runApp`.
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    final id = info.packageName;
    if (id.endsWith('.debug')) {
      _flavor = AppFlavor.internal;
    } else if (id.endsWith('.dev')) {
      _flavor = AppFlavor.dev;
    } else {
      _flavor = AppFlavor.prod;
    }
  }
}
