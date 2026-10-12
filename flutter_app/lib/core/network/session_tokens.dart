/// Contrato de acesso aos tokens (implementado em data/ com secure storage).
abstract class SessionTokens {
  Future<String?> get accessToken;
  Future<String?> get refreshToken;
  Future<void> saveSession({required String accessToken, required String refreshToken});
  Future<void> clearAccessToken();
  Future<void> clearAll();
}
