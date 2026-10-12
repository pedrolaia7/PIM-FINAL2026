import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.team,
    required this.planPercent,
    required this.planName,
    required this.memberCode,
    required this.hasFace,
  });

  final String id;
  final String name;
  final String email;
  final String team; // slug
  final int planPercent; // 0, 5, 10, 20
  final String planName;
  final String? memberCode;
  final bool hasFace;

  bool get isMember => planPercent > 0;

  @override
  List<Object?> get props => [id, name, email, team, planPercent, planName, memberCode, hasFace];
}
