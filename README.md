# Project Print

Flutter starter template with Clean Architecture, BLoC state management, Dio networking, and dependency injection.

## Tech Stack

- flutter_bloc
- dio + pretty_dio_logger
- get_it
- equatable
- dartz
- connectivity_plus + internet_connection_checker
- shared_preferences
- flutter_secure_storage
- logger
- json_annotation + freezed_annotation

## Folder Structure

lib/
- app/
	- app.dart
	- router/
- core/
	- constants/
	- di/
	- error/
	- network/
	- usecase/
- features/
	- home/
		- data/
		- domain/
		- presentation/

## Flavors

| Flavor | Package Name | Use |
|--------|-------------|-----|
| internal | `com.printhub.mobile.debug` | Local development |
| dev | `com.printhub.mobile.dev` | Dev/staging environment |
| prod | `com.printhub.mobile` | Production |

### Run

```bash
flutter run --flavor internal
flutter run --flavor dev
flutter run --flavor prod
```

### Build APK

```bash
flutter build apk --flavor internal
flutter build apk --flavor dev
flutter build apk --flavor prod
```

### Build Release

```bash
flutter build apk --flavor internal --release
flutter build apk --flavor dev --release
flutter build apk --flavor prod --release
```

### Build App Bundle (Play Store)

```bash
flutter build appbundle --flavor prod
```

## Run the Project

1. Install dependencies:
	 flutter pub get
2. Run app:
	 flutter run --flavor internal
3. Analyze code:
	 flutter analyze
4. Run tests:
	 flutter test

## Implemented Sample Feature

- Home feature with full Clean Architecture flow:
	- Presentation: HomeBloc + HomePage
	- Domain: entity, repository contract, use case
	- Data: remote data source, model, repository implementation
- Remote fetch is wired through Dio client and mapped into domain entity.

## Next Steps

- Add additional features under features/ using the same layer pattern.
- Add local cache and offline-first handling in repository implementations.
- Add generated models with build_runner where needed.
