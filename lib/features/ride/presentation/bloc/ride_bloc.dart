import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/driver.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_category.dart';
import 'ride_event.dart';
import 'ride_state.dart';

/// Internal: the simulated match delay elapsed.
class _RideMatchTimerElapsed extends RideEvent {
  const _RideMatchTimerElapsed();
}

/// Internal: the simulated driver arrival delay elapsed.
class _RidePickupTimerElapsed extends RideEvent {
  const _RidePickupTimerElapsed();
}

/// Internal: the simulated trip delay elapsed.
class _RideTripTimerElapsed extends RideEvent {
  const _RideTripTimerElapsed();
}

/// Drives the ride request lifecycle for the UI-only slice.
///
/// TODO(slice 4): replace the simulated timer pipeline with the rides API:
/// `RideConfirmRequested` → POST /api/v1/rides, and timers → polling or a
/// stream datasource for pending/match/status events, keeping every event
/// name and state shape unchanged.
class RideBloc extends Bloc<RideEvent, RideState> {
  RideBloc({
    this.matchDelay = const Duration(seconds: 3),
    this.pickupDelay = const Duration(seconds: 5),
    this.tripDelay = const Duration(seconds: 8),
  }) : super(const RideIdle()) {
    on<RideDestinationSelected>(_onDestinationSelected);
    on<RideDestinationCleared>(_onDestinationCleared);
    on<RideCategorySelected>(_onCategorySelected);
    on<RideConfirmRequested>(_onConfirmRequested);
    on<RideCancelRequested>(_onCancelRequested);
    on<RideCompletionAcknowledged>(_onCompletionAcknowledged);
    on<_RideMatchTimerElapsed>(_onMatchTimerElapsed);
    on<_RidePickupTimerElapsed>(_onPickupTimerElapsed);
    on<_RideTripTimerElapsed>(_onTripTimerElapsed);
  }

  Duration matchDelay;
  Duration pickupDelay;
  Duration tripDelay;

  Timer? _timer;
  bool _closed = false;

  /// Representative per-category mock drivers until the API provides them.
  static Driver _mockDriverFor(RideCategory category) => switch (category) {
        RideCategory.standard =>
          const Driver(name: 'Somchai', vehicle: 'Toyota Vios · White', plate: 'LP 1234', rating: 4.9),
        RideCategory.xl =>
          const Driver(name: 'Kevin Phet', vehicle: 'Toyota HiAce · Silver', plate: 'LP 8899', rating: 4.8),
        RideCategory.share =>
          const Driver(name: 'Anong', vehicle: 'Honda PCX · Blue', plate: 'LP 4321', rating: 4.7),
      };

  void _schedule(Duration delay, RideEvent event) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (_closed) return;
      add(event);
    });
  }

  void _onDestinationSelected(
    RideDestinationSelected event,
    Emitter<RideState> emit,
  ) {
    _timer?.cancel();
    emit(RideSelecting(pickup: event.pickup, destination: event.destination));
  }

  void _onDestinationCleared(
    RideDestinationCleared event,
    Emitter<RideState> emit,
  ) {
    _timer?.cancel();
    emit(const RideIdle());
  }

  void _onCategorySelected(
    RideCategorySelected event,
    Emitter<RideState> emit,
  ) {
    final state = this.state;
    if (state is! RideSelecting) return;
    emit(RideSelecting(
      pickup: state.pickup,
      destination: state.destination,
      category: event.category,
    ));
  }

  void _onConfirmRequested(
    RideConfirmRequested event,
    Emitter<RideState> emit,
  ) {
    final state = this.state;
    if (state is! RideSelecting) return;
    final ride = Ride(
      pickup: state.pickup,
      destination: state.destination,
      category: state.category,
      fareKip: state.category.baseFareKip,
      status: RideStatus.matching,
    );
    emit(RideMatching(ride: ride));
    _schedule(matchDelay, const _RideMatchTimerElapsed());
  }

  void _onCancelRequested(
    RideCancelRequested event,
    Emitter<RideState> emit,
  ) {
    final ride = rideOf(state);
    if (ride == null) return;
    if (ride.status == RideStatus.inProgress ||
        ride.status == RideStatus.completed) {
      return; // The trip can no longer be cancelled from the rider side.
    }
    _timer?.cancel();
    emit(RideCancelled(ride: ride.copyWith(status: RideStatus.cancelled)));
  }

  void _onCompletionAcknowledged(
    RideCompletionAcknowledged event,
    Emitter<RideState> emit,
  ) {
    _timer?.cancel();
    emit(const RideIdle());
  }

  void _onMatchTimerElapsed(
    _RideMatchTimerElapsed event,
    Emitter<RideState> emit,
  ) {
    final state = this.state;
    if (state is! RideMatching) return;
    final miniState = state.ride;
    final ride = miniState.copyWith(
      status: RideStatus.assigned,
      driver: _mockDriverFor(miniState.category),
      etaMinutes: 3,
    );
    emit(RideAssigned(ride: ride));
    _schedule(pickupDelay, const _RidePickupTimerElapsed());
  }

  void _onPickupTimerElapsed(
    _RidePickupTimerElapsed event,
    Emitter<RideState> emit,
  ) {
    final state = this.state;
    if (state is! RideAssigned) return;
    final ride = state.ride.copyWith(
      status: RideStatus.inProgress,
      etaMinutes: 14,
    );
    emit(RideInProgress(ride: ride));
    _schedule(tripDelay, const _RideTripTimerElapsed());
  }

  void _onTripTimerElapsed(
    _RideTripTimerElapsed event,
    Emitter<RideState> emit,
  ) {
    final state = this.state;
    if (state is! RideInProgress) return;
    final ride = state.ride.copyWith(status: RideStatus.completed);
    emit(RideCompleted(ride: ride));
  }

  @override
  Future<void> close() {
    _closed = true;
    _timer?.cancel();
    return super.close();
  }
}
