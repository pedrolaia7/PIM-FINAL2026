import '../../core/error/failures.dart';
import '../../core/network/guard.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local/token_local_ds.dart';
import '../datasources/remote/remote_datasources.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens);
  final AuthRemoteDataSource _remote;
  final TokenLocalDataSource _tokens;

  @override
  Future<bool> get hasStoredSession async => (await _tokens.refreshToken) != null;

  @override
  Future<bool> get isBiometricEnabled => _tokens.biometricEnabled;

  @override
  Future<Result<User>> restoreSession() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return const Err(Failure.sessionExpired);
    // Sempre renova: garante refresh token válido e rotaciona o antigo.
    final r = await guard(() => _remote.refresh(refresh));
    return r.fold(
      (f) async {
        // Só apaga a sessão se o servidor recusou. Sem rede, mantém para tentar depois.
        if (f.code == 'unauthorized') await _tokens.clearAll();
        return Err<User>(f);
      },
      (auth) async {
        await _tokens.saveSession(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
        return Ok(auth.user);
      },
    );
  }

  @override
  Future<Result<User>> login({required String email, required String password, required bool enableBiometric}) async {
    final r = await guard(() => _remote.login(email, password));
    return r.fold((f) async => Err<User>(f), (auth) async {
      await _tokens.saveSession(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      await _tokens.setBiometricEnabled(enableBiometric);
      return Ok(auth.user);
    });
  }

  @override
  Future<Result<User>> register(RegisterData data) async {
    final r = await guard(() => _remote.register(data));
    return r.fold((f) async => Err<User>(f), (auth) async {
      await _tokens.saveSession(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      return Ok(auth.user);
    });
  }

  @override
  Future<Result<User>> enrollFace(String imagePath) => guard(() => _remote.enrollFace(imagePath));

  @override
  Future<Result<User>> refreshUser() => guard(_remote.me);

  @override
  Future<Result<void>> deleteFace() => guard(_remote.deleteFace);

  @override
  Future<void> logout({required bool keepBiometricSession}) async {
    if (keepBiometricSession && await _tokens.biometricEnabled) {
      // Só "tranca": o refresh token continua guardado e só é usado depois da biometria.
      await _tokens.clearAccessToken();
      return;
    }
    await guard(_remote.logout); // revoga no servidor; falha de rede não impede o logout local
    await _tokens.clearAll();
  }

  @override
  Future<void> disableBiometric() => _tokens.setBiometricEnabled(false);
}

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl(this._remote);
  final MatchRemoteDataSource _remote;

  @override
  Future<Result<List<Match>>> getMatches({
    MatchScope scope = MatchScope.mine,
    MatchStatusFilter status = MatchStatusFilter.all,
    String? search,
  }) =>
      guard(() => _remote.list(
            team: scope == MatchScope.mine ? 'mine' : 'all',
            status: status.name,
            search: search,
          ));

  @override
  Future<Result<List<SectorAvailability>>> getSectors(int matchId) => guard(() => _remote.sectors(matchId));
}

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._remote);
  final PaymentRemoteDataSource _remote;

  @override
  Future<Result<PaymentIntent>> createIntent({
    required int matchId,
    required Sector sector,
    required PaymentMethod method,
    String? memberCode,
  }) =>
      guard(() => _remote.createIntent(matchId: matchId, sector: sector, method: method, memberCode: memberCode));

  @override
  Future<Result<PurchaseResult>> confirm({
    required PaymentIntent intent,
    required String selfiePath,
    String? cardToken,
  }) =>
      guard(() => _remote.confirm(intent: intent, selfiePath: selfiePath, cardToken: cardToken));

  @override
  Future<Result<SubscriptionResult>> subscribe({
    required int planPercent,
    required PaymentMethod method,
    String? cardToken,
  }) =>
      guard(() => _remote.subscribe(planPercent: planPercent, method: method, cardToken: cardToken));

  @override
  Future<Result<List<Ticket>>> tickets() => guard(_remote.tickets);
}
