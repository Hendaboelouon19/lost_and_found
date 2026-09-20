import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:errasoft/core/networking/api_service.dart';
import 'package:errasoft/core/networking/dio_factory.dart';
import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/features/auth/login/data/repo/login_repository.dart';
import 'package:errasoft/features/auth/login/presentation/cubit/login_cubit.dart';
import 'package:errasoft/features/auth/register/data/repo/register_repository.dart';
import 'package:errasoft/features/auth/register/presentation/cubit/register_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  getIt.registerLazySingleton<LocalStorage>(
    () => LocalStorage.instance,
  );

  getIt.registerLazySingleton<Dio>(
    () => DioFactory.getDio(),
  );

  getIt.registerLazySingleton<ApiService>(
    () => ApiService(getIt<Dio>()),
  );

  getIt.registerLazySingleton<LoginRepository>(
    () => LoginRepository(
      getIt<ApiService>(),
      getIt<LocalStorage>(),
    ),
  );

  getIt.registerLazySingleton<RegisterRepository>(
    () => RegisterRepository(
      getIt<ApiService>(),
    ),
  );

  getIt.registerFactory<LoginCubit>(
    () => LoginCubit(
      getIt<LoginRepository>(),
    ),
  );

  getIt.registerFactory<RegisterCubit>(
    () => RegisterCubit(
      getIt<RegisterRepository>(),
    ),
  );
}