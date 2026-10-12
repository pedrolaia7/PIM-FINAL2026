import 'package:equatable/equatable.dart';

class Stadium extends Equatable {
  const Stadium({required this.name, required this.city, required this.latitude, required this.longitude});
  final String name;
  final String city;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [name, city, latitude, longitude];
}

class Match extends Equatable {
  const Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeName,
    required this.awayName,
    required this.kickoffAt,
    required this.isFinished,
    required this.basePrice,
    required this.price,
    required this.discountPercent,
    required this.isAway,
    required this.stadium,
  });

  final int id;
  final String homeTeam; // slug (mandante)
  final String awayTeam; // slug (visitante)
  final String homeName;
  final String awayName;
  final DateTime kickoffAt; // UTC
  final bool isFinished;
  final double basePrice;
  final double price; // já com desconto de sócio
  final int discountPercent;
  final bool isAway; // o time do usuário é o visitante?
  final Stadium stadium;

  String get title => '$homeName vs $awayName';
  bool get hasDiscount => discountPercent > 0;

  @override
  List<Object?> get props => [id, homeTeam, awayTeam, kickoffAt, isFinished, price, isAway];
}
