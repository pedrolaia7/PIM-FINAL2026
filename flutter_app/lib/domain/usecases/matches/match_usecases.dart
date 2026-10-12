import '../../../core/error/failures.dart';
import '../../entities/match.dart';
import '../../entities/payment.dart';
import '../../repositories/repositories.dart';

class GetMatchesUseCase {
  GetMatchesUseCase(this._repo);
  final MatchRepository _repo;

  Future<Result<List<Match>>> call({
    MatchScope scope = MatchScope.mine,
    MatchStatusFilter status = MatchStatusFilter.all,
    String? search,
  }) =>
      _repo.getMatches(scope: scope, status: status, search: search);
}

class GetSectorsUseCase {
  GetSectorsUseCase(this._repo);
  final MatchRepository _repo;
  Future<Result<List<SectorAvailability>>> call(int matchId) => _repo.getSectors(matchId);
}
