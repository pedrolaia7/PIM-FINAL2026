import 'package:dio/dio.dart';

import '../../../domain/entities/payment.dart';
import '../../models/models.dart';
import '../../../domain/entities/match.dart';
import '../../../domain/entities/user.dart';

/// Falam com o backend C#. Lançam DioException; os repositórios convertem em Result.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthResponseModel> login(String email, String password) async {
    final r = await _dio.post('/api/auth/login', data: {'email': email, 'password': password});
    return AuthResponseModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AuthResponseModel> register(RegisterData d) async {
    final r = await _dio.post('/api/auth/register', data: {
      'name': d.name,
      'cpf': d.cpf,
      'email': d.email,
      'password': d.password,
      'team': d.team,
    });
    return AuthResponseModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AuthResponseModel> refresh(String refreshToken) async {
    final r = await _dio.post('/api/auth/refresh', data: {'refreshToken': refreshToken});
    return AuthResponseModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> logout() => _dio.post('/api/auth/logout');

  Future<User> me() async {
    final r = await _dio.get('/api/auth/me');
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  /// Envia a selfie (multipart). O backend repassa ao microsserviço Python.
  Future<User> enrollFace(String imagePath) async {
    final form = FormData.fromMap({
      'consent': 'true',
      'selfie': await MultipartFile.fromFile(imagePath, filename: 'selfie.jpg'),
    });
    final r = await _dio.post('/api/auth/face/enroll', data: form);
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteFace() => _dio.delete('/api/auth/face');
}

class MatchRemoteDataSource {
  MatchRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Match>> list({required String team, required String status, String? search}) async {
    final r = await _dio.get('/api/matches', queryParameters: {
      'team': team,
      'status': status,
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
    });
    return (r.data as List).map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SectorAvailability>> sectors(int matchId) async {
    final r = await _dio.get('/api/matches/$matchId/sectors');
    return (r.data as List).map((e) => SectorModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class PaymentRemoteDataSource {
  PaymentRemoteDataSource(this._dio);
  final Dio _dio;

  Future<PaymentIntent> createIntent({
    required int matchId,
    required Sector sector,
    required PaymentMethod method,
    String? memberCode,
  }) async {
    final r = await _dio.post('/api/payments/intents', data: {
      'matchId': matchId,
      'sector': sector.apiValue,
      'method': method.apiValue,
      'memberCode': memberCode,
    });
    return PaymentModel.intentFromJson(r.data as Map<String, dynamic>);
  }

  Future<PurchaseResult> confirm({
    required PaymentIntent intent,
    required String selfiePath,
    String? cardToken,
  }) async {
    final form = FormData.fromMap({
      'nonce': intent.nonce,
      if (cardToken != null) 'cardToken': cardToken,
      'selfie': await MultipartFile.fromFile(selfiePath, filename: 'selfie.jpg'),
    });
    final r = await _dio.post('/api/payments/intents/${intent.id}/confirm', data: form);
    final j = r.data as Map<String, dynamic>;
    return PurchaseResult(
      ticket: PaymentModel.ticketFromJson(j['ticket'] as Map<String, dynamic>),
      pixPayload: j['pixPayload'] as String?,
    );
  }

  Future<SubscriptionResult> subscribe({
    required int planPercent,
    required PaymentMethod method,
    String? cardToken,
  }) async {
    final r = await _dio.post('/api/membership/subscribe', data: {
      'plan': planPercent,
      'method': method.apiValue,
      'cardToken': cardToken,
    });
    final j = r.data as Map<String, dynamic>;
    return SubscriptionResult(memberCode: j['memberCode'] as String, pixPayload: j['pixPayload'] as String?);
  }

  Future<List<Ticket>> tickets() async {
    final r = await _dio.get('/api/tickets');
    return (r.data as List).map((e) => PaymentModel.ticketFromJson(e as Map<String, dynamic>)).toList();
  }
}
