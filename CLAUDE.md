# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PrintHub is a Flutter mobile app for high-speed print delivery (upload docs → print → deliver in 15 min). Supports Android, iOS, and web.

## Commands

```bash
# Install dependencies
flutter pub get

# Run with flavor
flutter run --flavor internal   # local dev
flutter run --flavor dev        # staging
flutter run --flavor prod       # production

# Build APK
flutter build apk --flavor internal
flutter build apk --flavor prod --release

# Build Android App Bundle (Play Store)
flutter build appbundle --flavor prod

# Code generation (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
dart run build_runner watch --delete-conflicting-outputs

# Analyze and test
flutter analyze
flutter test
```

## App Flavors

| Flavor | Package ID | Purpose |
|--------|-----------|---------|
| `internal` | `com.printhub.mobile.debug` | Local development |
| `dev` | `com.printhub.mobile.dev` | Staging/QA |
| `prod` | `com.printhub.mobile` | Production |

## Architecture

**Clean Architecture** with three layers per feature:

```
lib/
├── main.dart              # Entry point — initializes Firebase, DI, runs App
├── app/
│   ├── app.dart           # Root MaterialApp, global BLoC providers
│   └── router/app_router.dart  # Named route definitions and generation
├── core/
│   ├── constants/         # API URLs, colors, dimensions, text strings
│   ├── di/injection.dart  # GetIt service locator registration
│   ├── error/             # Failure types (ServerFailure, ConnectionFailure, CacheFailure)
│   ├── network/           # Dio client + interceptors, connectivity checks
│   ├── storage/           # TemporaryAuthStore (SharedPreferences token storage)
│   └── usecase/           # Base UseCase<Type, Params> abstract class
└── features/
    └── [feature]/
        ├── data/
        │   ├── datasources/     # Remote API calls (Dio) and local data sources
        │   ├── models/          # JSON-serializable DTOs (json_serializable / freezed)
        │   └── repositories/    # Repository implementations
        ├── domain/
        │   ├── entities/        # Pure Dart business objects
        │   ├── repositories/    # Abstract repository contracts
        │   └── usecases/        # Single-responsibility business operations
        └── presentation/
            ├── bloc/            # BLoC (events, states, bloc class)
            ├── pages/           # Full-screen UI widgets
            └── widgets/         # Feature-specific reusable widgets
```

## Key Patterns

### State Management (BLoC)
- All features use `flutter_bloc` v9.1.1
- States use enums (e.g., `AuthStatus.loading`, `AuthStatus.success`) with `copyWith()`
- Failures are propagated as state fields, not exceptions
- Use `dartz` `Either<Failure, T>` in use cases and repositories

### Dependency Injection (GetIt)
- All services/repos/use cases registered in `lib/core/di/injection.dart`
- Access via `sl<Type>()` shorthand
- Register in order: external → core → data sources → repositories → use cases → blocs

### Navigation
- Named routes defined as constants in `AppRouter`
- `AppRouter.generateRoute()` passed to `MaterialApp.onGenerateRoute`
- BLoC providers are created per-route inside `generateRoute`

### API Layer
- Base URL: `https://print-hub-xdgd.onrender.com/api/v1/`
- Dio client configured in `core/network/dio_client.dart` with 30s timeouts and `PrettyDioLogger`
- Auth token injected automatically via Dio interceptor from `TemporaryAuthStore`

### Authentication Flow
1. Google or Apple sign-in via Firebase Auth
2. User data POSTed to backend (`user/verify-and-save`)
3. Token stored in `TemporaryAuthStore` (SharedPreferences)
4. If no mobile number, prompt user to enter it
5. Check/create backend storage (`user/storage-exists`, `user/create-storage`)

### Code Generation
Models using `freezed` or `json_serializable` require running `build_runner`. Generated files (`*.freezed.dart`, `*.g.dart`) are committed to the repo.
