import 'package:dio/dio.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';
import 'session_tokens.dart';

class DioFactory {
  DioFactory._();

  static BaseOptions _options() => BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 40), // verificação facial pode demorar
        headers: {'Accept': 'application/json'},
      );

  static Dio create({required SessionTokens tokens, required void Function() onSessionExpired}) {
    final dio = Dio(_options());
    final refreshClient = Dio(_options());
    dio.interceptors.add(AuthInterceptor(
      tokens: tokens,
      refreshClient: refreshClient,
      mainClient: () => dio,
      onSessionExpired: onSessionExpired,
    ));
    return dio;
  }
}
