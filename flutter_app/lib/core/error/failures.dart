import 'package:equatable/equatable.dart';

/// Erro de negócio/infra com [code] estável (vindo do backend ou gerado no app).
class Failure extends Equatable {
  const Failure(this.code, this.message);

  final String code;
  final String message;

  static const network = Failure('network', 'Sem conexão com o servidor. Verifique sua internet.');
  static const unknown = Failure('unknown', 'Algo deu errado. Tente novamente.');
  static const biometricCancelled = Failure('biometric_cancelled', 'Confirmação biométrica cancelada.');
  static const biometricUnavailable = Failure(
      'biometric_unavailable', 'Cadastre uma biometria ou Face ID nas configurações do aparelho para continuar.');
  static const sessionExpired = Failure('unauthorized', 'Sessão expirada. Faça login novamente.');

  bool get isFaceNotEnrolled => code == 'face_not_enrolled';

  @override
  List<Object?> get props => [code, message];
}

/// Resultado funcional simples (sem dependência externa).
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess) => switch (this) {
        Ok<T>(:final value) => onSuccess(value),
        Err<T>(:final failure) => onFailure(failure),
      };

  bool get isOk => this is Ok<T>;
  T? get valueOrNull => switch (this) { Ok<T>(:final value) => value, Err<T>() => null };
  Failure? get failureOrNull => switch (this) { Err<T>(:final failure) => failure, Ok<T>() => null };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
