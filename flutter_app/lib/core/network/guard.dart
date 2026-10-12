import 'package:dio/dio.dart';

import '../error/failures.dart';

/// Executa uma chamada de rede e converte exceções em [Result].
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on DioException catch (e) {
    return Err(failureFromDio(e));
  } on Failure catch (f) {
    return Err(f);
  } catch (_) {
    return const Err(Failure.unknown);
  }
}

Failure failureFromDio(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['code'] is String) {
    return Failure(data['code'] as String, (data['message'] as String?) ?? Failure.unknown.message);
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return Failure.network;
    default:
      break;
  }
  switch (e.response?.statusCode) {
    case 401:
      return Failure.sessionExpired;
    case 429:
      return const Failure('rate_limited', 'Muitas tentativas. Aguarde um instante e tente de novo.');
    case 413:
      return const Failure('image_too_large', 'A imagem é grande demais.');
  }
  return Failure.unknown;
}
