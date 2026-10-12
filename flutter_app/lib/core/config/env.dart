/// Configuração por build:
///   flutter run --dart-define=API_URL=http://192.168.0.10:8080
class Env {
  Env._();

  /// 10.0.2.2 = localhost da máquina vista pelo emulador Android.
  /// No simulador iOS use http://localhost:8080; em aparelho físico use o IP da máquina (ou HTTPS).
  static const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  /// Exige biometria nativa antes de confirmar compra. Se o aparelho não tiver biometria cadastrada,
  /// a compra é bloqueada. A verificação facial no servidor acontece sempre.
  static const requireLocalBiometricForPurchase =
      bool.fromEnvironment('REQUIRE_LOCAL_BIOMETRIC', defaultValue: true);
}
