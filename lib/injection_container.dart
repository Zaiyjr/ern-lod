import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'core/network/mock_http_client.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_auth_status.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// Service locator, wired dependency-injection-first:
/// datasource → repository → use case → bloc.
///
/// Each layer only ever sees the layer beneath its own abstraction
/// (e.g. use cases receive [AuthRepository], not the impl).
final GetIt sl = GetIt.instance;

Future<void> initInjection() async {
  // Datasources
  sl.registerLazySingleton<http.Client>(() => MockHttpClient());
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(client: sl<http.Client>()));
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl());

  // Repository (registered against its domain contract)
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => Register(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // Bloc (factory: a fresh instance per screen mount)
  sl.registerFactory(
    () => AuthBloc(
      signIn: sl(),
      register: sl(),
      checkAuthStatus: sl(),
      signOut: sl(),
    ),
  );
}
