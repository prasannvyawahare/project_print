import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_storage_exists.dart';
import '../../features/auth/domain/usecases/create_storage.dart';
import '../../features/auth/domain/usecases/sign_in_with_apple.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/verify_and_save_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/delivery/data/datasources/address_remote_data_source.dart';
import '../../features/delivery/data/repositories/address_repository_impl.dart';
import '../../features/delivery/domain/repositories/address_repository.dart';
import '../../features/delivery/domain/usecases/create_address.dart';
import '../../features/delivery/domain/usecases/get_addresses.dart';
import '../../features/delivery/domain/usecases/remove_address.dart';
import '../../features/delivery/domain/usecases/select_address.dart';
import '../../features/delivery/presentation/bloc/address_bloc.dart';
import '../../features/upload/data/datasources/order_remote_data_source.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_print_categories.dart';
import '../../features/home/domain/usecases/get_welcome_message.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../storage/active_job_store.dart';
import '../storage/temporary_auth_store.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  sl
    ..registerLazySingleton<Logger>(Logger.new)
    ..registerLazySingleton<Dio>(Dio.new)
    ..registerLazySingleton<SharedPreferences>(() => sharedPreferences)
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance)
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<InternetConnectionChecker>(
      InternetConnectionChecker.createInstance,
    );

  await sl<GoogleSignIn>().initialize(
    serverClientId:
        '952760305739-e8f0cc9e6fb3fes6uo6l7bs3tpe0g2ba.apps.googleusercontent.com',
  );

  sl.registerLazySingleton<TemporaryAuthStore>(
    () => TemporaryAuthStore(preferences: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<ActiveJobStore>(
    () => ActiveJobStore(preferences: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<DioClient>(
    () =>
        DioClient(dio: sl<Dio>(), temporaryAuthStore: sl<TemporaryAuthStore>()),
  );

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(
      connectivity: sl<Connectivity>(),
      connectionChecker: sl<InternetConnectionChecker>(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
      dioClient: sl<DioClient>(),
      temporaryAuthStore: sl<TemporaryAuthStore>(),
      logger: sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      logger: sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<SignInWithGoogle>(
    () => SignInWithGoogle(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SignInWithApple>(
    () => SignInWithApple(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<VerifyAndSaveUser>(
    () => VerifyAndSaveUser(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<CheckStorageExists>(
    () => CheckStorageExists(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<CreateStorage>(
    () => CreateStorage(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SignOut>(() => SignOut(sl<AuthRepository>()));

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      signInWithGoogle: sl<SignInWithGoogle>(),
      signInWithApple: sl<SignInWithApple>(),
      verifyAndSaveUser: sl<VerifyAndSaveUser>(),
      checkStorageExists: sl<CheckStorageExists>(),
      createStorage: sl<CreateStorage>(),
      signOut: sl<SignOut>(),
    ),
  );

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(
      dioClient: sl<DioClient>(),
      logger: sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(preferences: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl<HomeRemoteDataSource>(),
      localDataSource: sl<HomeLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      logger: sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<GetWelcomeMessage>(
    () => GetWelcomeMessage(sl<HomeRepository>()),
  );

  sl.registerLazySingleton<GetPrintCategories>(
    () => GetPrintCategories(sl<HomeRepository>()),
  );

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(getPrintCategories: sl<GetPrintCategories>()),
  );

  // Address feature
  sl.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSourceImpl(
      dioClient: sl<DioClient>(),
      logger: sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(
      remoteDataSource: sl<AddressRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      logger: sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<CreateAddress>(
    () => CreateAddress(sl<AddressRepository>()),
  );

  sl.registerLazySingleton<GetAddresses>(
    () => GetAddresses(sl<AddressRepository>()),
  );

  sl.registerLazySingleton<RemoveAddress>(
    () => RemoveAddress(sl<AddressRepository>()),
  );

  sl.registerLazySingleton<SelectAddress>(
    () => SelectAddress(sl<AddressRepository>()),
  );

  sl.registerFactory<AddressBloc>(
    () => AddressBloc(
      createAddress: sl<CreateAddress>(),
      getAddresses: sl<GetAddresses>(),
      removeAddress: sl<RemoveAddress>(),
      selectAddress: sl<SelectAddress>(),
    ),
  );

  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(
      dioClient: sl<DioClient>(),
      temporaryAuthStore: sl<TemporaryAuthStore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      logger: sl<Logger>(),
    ),
  );
}
