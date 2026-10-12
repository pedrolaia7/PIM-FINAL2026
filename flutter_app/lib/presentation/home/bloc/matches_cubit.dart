import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/match.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/matches/match_usecases.dart';

enum LoadStatus { loading, success, failure }

class MatchesState extends Equatable {
  const MatchesState({
    this.status = LoadStatus.loading,
    this.matches = const [],
    this.failure,
    this.scope = MatchScope.mine,
    this.filter = MatchStatusFilter.all,
    this.search = '',
  });

  final LoadStatus status;
  final List<Match> matches;
  final Failure? failure;
  final MatchScope scope;
  final MatchStatusFilter filter;
  final String search;

  MatchesState copyWith({
    LoadStatus? status,
    List<Match>? matches,
    Failure? failure,
    MatchScope? scope,
    MatchStatusFilter? filter,
    String? search,
  }) =>
      MatchesState(
        status: status ?? this.status,
        matches: matches ?? this.matches,
        failure: failure,
        scope: scope ?? this.scope,
        filter: filter ?? this.filter,
        search: search ?? this.search,
      );

  @override
  List<Object?> get props => [status, matches, failure, scope, filter, search];
}

class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit(this._getMatches) : super(const MatchesState());
  final GetMatchesUseCase _getMatches;

  int _req = 0; // descarta respostas antigas quando o usuário muda o filtro rápido

  Future<void> load({MatchScope? scope, MatchStatusFilter? filter, String? search}) async {
    final next = state.copyWith(
      status: LoadStatus.loading,
      scope: scope,
      filter: filter,
      search: search,
    );
    emit(next);
    final id = ++_req;
    final r = await _getMatches(scope: next.scope, status: next.filter, search: next.search);
    if (id != _req || isClosed) return;
    r.fold(
      (f) => emit(state.copyWith(status: LoadStatus.failure, failure: f)),
      (list) => emit(state.copyWith(status: LoadStatus.success, matches: list)),
    );
  }
}
