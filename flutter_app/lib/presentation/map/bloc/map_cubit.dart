import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error/failures.dart';
import '../../../data/services/device_services.dart';
import '../../../domain/entities/match.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/matches/match_usecases.dart';

class MapState extends Equatable {
  const MapState({
    this.loading = true,
    this.sectors = const [],
    this.failure,
    this.userLocation,
    this.locationLoading = false,
    this.locationAsked = false,
    this.distanceMeters,
  });

  final bool loading;
  final List<SectorAvailability> sectors;
  final Failure? failure;
  final LatLng? userLocation;
  final bool locationLoading;
  final bool locationAsked;
  final double? distanceMeters;

  MapState copyWith({
    bool? loading,
    List<SectorAvailability>? sectors,
    Failure? failure,
    LatLng? userLocation,
    bool? locationLoading,
    bool? locationAsked,
    double? distanceMeters,
  }) =>
      MapState(
        loading: loading ?? this.loading,
        sectors: sectors ?? this.sectors,
        failure: failure,
        userLocation: userLocation ?? this.userLocation,
        locationLoading: locationLoading ?? this.locationLoading,
        locationAsked: locationAsked ?? this.locationAsked,
        distanceMeters: distanceMeters ?? this.distanceMeters,
      );

  @override
  List<Object?> get props => [loading, sectors, failure, userLocation, locationLoading, locationAsked, distanceMeters];
}

class MapCubit extends Cubit<MapState> {
  MapCubit(this._getSectors, this._location, this.match) : super(const MapState());
  final GetSectorsUseCase _getSectors;
  final LocationService _location;
  final Match match;

  LatLng get stadiumPoint => LatLng(match.stadium.latitude, match.stadium.longitude);

  Future<void> loadSectors() async {
    emit(state.copyWith(loading: true));
    final r = await _getSectors(match.id);
    r.fold(
      (f) => emit(state.copyWith(loading: false, failure: f)),
      (s) => emit(state.copyWith(loading: false, sectors: s)),
    );
  }

  /// Pede permissão e localiza o usuário só quando ele abre a aba do estádio / toca no botão.
  Future<void> locateUser() async {
    emit(state.copyWith(locationLoading: true));
    final p = await _location.currentPosition();
    if (p == null) {
      emit(state.copyWith(locationLoading: false, locationAsked: true));
      return;
    }
    emit(state.copyWith(
      locationLoading: false,
      locationAsked: true,
      userLocation: p,
      distanceMeters: _location.distanceMeters(p, stadiumPoint),
    ));
  }
}
