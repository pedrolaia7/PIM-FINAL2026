import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/local/token_local_ds.dart';
import '../../data/datasources/remote/remote_datasources.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../data/services/device_services.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/auth/auth_usecases.dart';
import '../../domain/usecases/checkout/checkout_usecases.dart';
import '../../domain/usecases/matches/match_usecases.dart';
import '../network/dio_factory.dart';
import '../network/session_events.dart';
import '../network/session_tokens.dart';

final sl = GetIt.instance;

/// Registro manual (sem codegen). Ordem: infra -> data -> domain.
void configureDependencies() {
  // --- infra ---
  sl.registerLazySingleton<SessionEvents>(SessionEvents.new);
  sl.registerLazySingleton<TokenLocalDataSource>(TokenLocalDataSource.new);
  sl.registerLazySingleton<SessionTokens>(() => sl<TokenLocalDataSource>());
  sl.registerLazySingleton<Dio>(() => DioFactory.create(
        tokens: sl<SessionTokens>(),
        onSessionExpired: () => sl<SessionEvents>().notifyExpired(),
      ));

  // --- serviços do aparelho ---
  sl.registerLazySingleton<BiometricAuthenticator>(LocalAuthBiometric.new);
  sl.registerLazySingleton<CardTokenizer>(SandboxCardTokenizer.new);
  sl.registerLazySingleton<LocationService>(LocationService.new);

  // --- data ---
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton(() => MatchRemoteDataSource(sl()));
  sl.registerLazySingleton(() => PaymentRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<MatchRepository>(() => MatchRepositoryImpl(sl()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(sl()));

  // --- use cases ---
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => EnrollFaceUseCase(sl()));
  sl.registerLazySingleton(() => BiometricLoginUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RestoreSessionUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetMatchesUseCase(sl()));
  sl.registerLazySingleton(() => GetSectorsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePaymentIntentUseCase(sl()));
  sl.registerLazySingleton(() => RequireBiometricUseCase(sl()));
  sl.registerLazySingleton(() => ConfirmPaymentUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SubscribePlanUseCase(sl(), sl()));
}
