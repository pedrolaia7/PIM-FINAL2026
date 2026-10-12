import 'dart:math';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/entities/payment.dart';
import '../../domain/repositories/repositories.dart';

/// Biometria nativa (Face ID / Touch ID / digital) via local_auth.
class LocalAuthBiometric implements BiometricAuthenticator {
  LocalAuthBiometric([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> get isAvailable async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true, // sem cair para PIN/padrão: é uma confirmação biométrica
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false; // cancelado, bloqueado por tentativas ou indisponível
    }
  }
}

/// TOKENIZADOR DE SANDBOX — não envia dados do cartão a lugar nenhum.
/// Em produção, troque por SDK do gateway (Mercado Pago, Stripe, Pagar.me...) que devolve um token real.
/// Cartões terminados em 0000 são recusados pelo gateway sandbox do backend (teste de recusa).
class SandboxCardTokenizer implements CardTokenizer {
  @override
  Future<String> tokenize(CardInput card) async {
    final digits = card.number.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    final rnd = Random.secure().nextInt(1 << 32).toRadixString(16);
    return 'tok_sandbox_${last4}_$rnd';
  }
}

class LocationService {
  /// Retorna a posição atual, ou null se o serviço/permissão estiver negado.
  Future<LatLng?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  double distanceMeters(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
}
