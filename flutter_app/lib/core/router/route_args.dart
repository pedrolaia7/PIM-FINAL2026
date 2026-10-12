import '../../domain/entities/match.dart';
import '../../domain/entities/payment.dart';

class FaceEnrollArgs {
  const FaceEnrollArgs({this.planPercent = 0, this.fromRegistration = false});
  final int planPercent;
  final bool fromRegistration;
}

class PlansArgs {
  const PlansArgs({this.initialPlan = 5, this.fromRegistration = false});
  final int initialPlan;
  final bool fromRegistration;
}

class CheckoutArgs {
  const CheckoutArgs({required this.match, required this.sector});
  final Match match;
  final Sector sector;
}

class ConfirmationArgs {
  const ConfirmationArgs(this.result);
  final PurchaseResult result;
}
