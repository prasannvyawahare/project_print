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

## Run the Project

1. Install dependencies:
	 flutter pub get
2. Run app:
	 flutter run
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
