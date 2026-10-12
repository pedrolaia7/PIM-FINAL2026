import '../../../core/error/failures.dart';
import '../../entities/payment.dart';
import '../../entities/user.dart';
import '../../repositories/repositories.dart';

class LoginUseCase {
  LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<User>> call({required String email, required String password, bool enableBiometric = false}) =>
      _repo.login(email: email.trim(), password: password, enableBiometric: enableBiometric);
}

class RegisterUseCase {
  RegisterUseCase(this._repo);
  final AuthRepository _repo;
  Future<Result<User>> call(RegisterData data) => _repo.register(data);
}

class EnrollFaceUseCase {
  EnrollFaceUseCase(this._repo);
  final AuthRepository _repo;
  Future<Result<User>> call(String imagePath) => _repo.enrollFace(imagePath);
}

/// Login rápido: biometria nativa DESBLOQUEIA a sessão guardada (refresh token).
/// Não é prova de identidade para o servidor — para compras há a verificação facial no backend.
class BiometricLoginUseCase {
  BiometricLoginUseCase(this._biometric, this._repo);
  final BiometricAuthenticator _biometric;
  final AuthRepository _repo;

  Future<Result<User>> call() async {
    if (!await _biometric.isAvailable) return const Err(Failure.biometricUnavailable);
    final ok = await _biometric.authenticate('Entre no TicketFut');
    if (!ok) return const Err(Failure.biometricCancelled);
    return _repo.restoreSession();
  }
}

class RestoreSessionUseCase {
  RestoreSessionUseCase(this._repo);
  final AuthRepository _repo;
  Future<Result<User>> call() => _repo.restoreSession();
}

class LogoutUseCase {
  LogoutUseCase(this._repo);
  final AuthRepository _repo;
  Future<void> call({bool keepBiometricSession = true}) => _repo.logout(keepBiometricSession: keepBiometricSession);
}
