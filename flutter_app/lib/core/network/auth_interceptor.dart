import 'package:dio/dio.dart';

import 'session_tokens.dart';

/// Anexa o Bearer e, em caso de 401, tenta renovar o token UMA vez e refaz a requisição.
/// É um QueuedInterceptor: enquanto uma renovação ocorre, as demais requisições esperam na fila.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokens,
    required this.refreshClient,
    required this.mainClient,
    required this.onSessionExpired,
  });

  final SessionTokens tokens;
  final Dio refreshClient; // Dio "limpo", sem este interceptor
  final Dio Function() mainClient;
  final void Function() onSessionExpired;

  static const _publicPaths = ['/api/auth/login', '/api/auth/register', '/api/auth/refresh'];
  bool _isPublic(String path) => _publicPaths.any(path.endsWith);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isPublic(options.path)) {
      final token = await tokens.accessToken;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    if (!is401 || _isPublic(err.requestOptions.path) || err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }

    final refresh = await tokens.refreshToken;
    if (refresh == null) {
      onSessionExpired();
      return handler.next(err);
    }

    try {
      final res = await refreshClient.post('/api/auth/refresh', data: {'refreshToken': refresh});
      final data = res.data as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String;
      await tokens.saveSession(accessToken: newAccess, refreshToken: data['refreshToken'] as String);

      final opts = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra['retried'] = true;
      // FormData só pode ser enviado uma vez: clona antes de repetir (upload da selfie)
      if (opts.data is FormData) opts.data = (opts.data as FormData).clone();
      handler.resolve(await mainClient().fetch(opts));
    } catch (_) {
      await tokens.clearAccessToken();
      onSessionExpired();
      handler.next(err);
    }
  }
}
