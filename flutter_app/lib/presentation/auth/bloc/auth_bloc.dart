import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/session_events.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/usecases/auth/auth_usecases.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

// ---------- eventos ----------
sealed class AuthEvent {
  const AuthEvent();
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted(this.email, this.password, {this.enableBiometric = false});
  final String email;
  final String password;
  final bool enableBiometric;
}

class BiometricLoginRequested extends AuthEvent {
  const BiometricLoginRequested();
}

class RegisterSubmitted extends AuthEvent {
  const RegisterSubmitted(this.data);
  final RegisterData data;
}

class FaceEnrollSubmitted extends AuthEvent {
  const FaceEnrollSubmitted(this.imagePath);
  final String imagePath;
}

class UserUpdated extends AuthEvent {
  const UserUpdated(this.user);
  final User user;
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested({this.forgetDevice = false});
  final bool forgetDevice; // true = apaga também o acesso rápido por biometria
}

class SessionExpiredEvent extends AuthEvent {
  const SessionExpiredEvent();
}

// ---------- estado ----------
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.failure,
    this.errorSeq = 0,
    this.biometricReady = false,
    this.justRegistered = false,
    this.faceEnrolledSeq = 0,
    this.promptBiometric = false,
  });

  final AuthStatus status;
  final User? user;
  final bool busy;
  final Failure? failure;
  final int errorSeq; // incrementa a cada erro, para a UI reagir mesmo ao mesmo erro repetido
  final bool biometricReady; // há sessão guardada protegida por biometria
  final bool justRegistered;
  final int faceEnrolledSeq;
  final bool promptBiometric; // abre o prompt sozinho (só na abertura do app)

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
    int? errorSeq,
    bool? biometricReady,
    bool? justRegistered,
    int? faceEnrolledSeq,
    bool? promptBiometric,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        busy: busy ?? this.busy,
        failure: clearFailure ? null : (failure ?? this.failure),
        errorSeq: errorSeq ?? this.errorSeq,
        biometricReady: biometricReady ?? this.biometricReady,
        justRegistered: justRegistered ?? this.justRegistered,
        faceEnrolledSeq: faceEnrolledSeq ?? this.faceEnrolledSeq,
        promptBiometric: promptBiometric ?? this.promptBiometric,
      );

  @override
  List<Object?> get props => [status, user, busy, failure, errorSeq, biometricReady, justRegistered, faceEnrolledSeq, promptBiometric];
}

// ---------- bloc ----------
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required EnrollFaceUseCase enrollFace,
    required BiometricLoginUseCase biometricLogin,
    required RestoreSessionUseCase restoreSession,
    required LogoutUseCase logout,
    required AuthRepository repository,
    required SessionEvents sessionEvents,
  })  : _login = login,
        _register = register,
        _enrollFace = enrollFace,
        _biometricLogin = biometricLogin,
        _restore = restoreSession,
        _logout = logout,
        _repo = repository,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<LoginSubmitted>(_onLogin);
    on<BiometricLoginRequested>(_onBiometricLogin);
    on<RegisterSubmitted>(_onRegister);
    on<FaceEnrollSubmitted>(_onEnrollFace);
    on<UserUpdated>((e, emit) => emit(state.copyWith(user: e.user)));
    on<LogoutRequested>(_onLogout);
    on<SessionExpiredEvent>(_onExpired);
    _sub = sessionEvents.expired.listen((_) => add(const SessionExpiredEvent()));
  }

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final EnrollFaceUseCase _enrollFace;
  final BiometricLoginUseCase _biometricLogin;
  final RestoreSessionUseCase _restore;
  final LogoutUseCase _logout;
  final AuthRepository _repo;
  late final StreamSubscription<void> _sub;

  AuthState _fail(Failure f) =>
      state.copyWith(busy: false, failure: f, errorSeq: state.errorSeq + 1);

  Future<void> _onStarted(AuthStarted e, Emitter<AuthState> emit) async {
    final hasSession = await _repo.hasStoredSession;
    final biometric = await _repo.isBiometricEnabled;

    if (!hasSession) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, biometricReady: false));
      return;
    }
    if (biometric) {
      // Acesso rápido ativado: o app fica "trancado" até a biometria (a tela de login oferece o botão)
      emit(state.copyWith(status: AuthStatus.unauthenticated, biometricReady: true, promptBiometric: true));
      return;
    }
    // Sessão persistente sem biometria: retoma direto
    final r = await _restore();
    r.fold(
      (f) => emit(state.copyWith(
          status: AuthStatus.unauthenticated, biometricReady: false, clearUser: true)),
      (u) => emit(state.copyWith(status: AuthStatus.authenticated, user: u)),
    );
  }

  Future<void> _onLogin(LoginSubmitted e, Emitter<AuthState> emit) async {
    emit(state.copyWith(busy: true, clearFailure: true));
    final r = await _login(email: e.email, password: e.password, enableBiometric: e.enableBiometric);
    r.fold(
      (f) => emit(_fail(f)),
      (u) => emit(state.copyWith(
          status: AuthStatus.authenticated, user: u, busy: false, justRegistered: false,
          biometricReady: e.enableBiometric)),
    );
  }

  Future<void> _onBiometricLogin(BiometricLoginRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(busy: true, clearFailure: true, promptBiometric: false));
    final r = await _biometricLogin();
    r.fold(
      (f) {
        // cancelar o prompt não é "erro" a mostrar
        if (f.code == Failure.biometricCancelled.code) {
          emit(state.copyWith(busy: false));
        } else {
          emit(_fail(f));
        }
      },
      (u) => emit(state.copyWith(status: AuthStatus.authenticated, user: u, busy: false, justRegistered: false)),
    );
  }

  Future<void> _onRegister(RegisterSubmitted e, Emitter<AuthState> emit) async {
    emit(state.copyWith(busy: true, clearFailure: true));
    final r = await _register(e.data);
    r.fold(
      (f) => emit(_fail(f)),
      (u) => emit(state.copyWith(
          status: AuthStatus.authenticated, user: u, busy: false, justRegistered: true)),
    );
  }

  Future<void> _onEnrollFace(FaceEnrollSubmitted e, Emitter<AuthState> emit) async {
    emit(state.copyWith(busy: true, clearFailure: true));
    final r = await _enrollFace(e.imagePath);
    r.fold(
      (f) => emit(_fail(f)),
      (u) => emit(state.copyWith(user: u, busy: false, faceEnrolledSeq: state.faceEnrolledSeq + 1)),
    );
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    await _logout(keepBiometricSession: !e.forgetDevice);
    final biometric = await _repo.isBiometricEnabled && await _repo.hasStoredSession;
    emit(AuthState(status: AuthStatus.unauthenticated, biometricReady: biometric));
  }

  Future<void> _onExpired(SessionExpiredEvent e, Emitter<AuthState> emit) async {
    if (state.status != AuthStatus.authenticated) return;
    emit(AuthState(status: AuthStatus.unauthenticated, failure: Failure.sessionExpired, errorSeq: state.errorSeq + 1));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
