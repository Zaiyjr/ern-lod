import 'package:equatable/equatable.dart';

import '../../domain/entities/ride_category.dart';

/// Events driving the ride request lifecycle (UI-only slice).
///
/// Not `sealed`: the ride Bloc library defines internal timer events
/// that extend this type.
abstract class RideEvent extends Equatable {
  const RideEvent();

  @override
  List<Object?> get props => const [];
}

/// A pickup/destination pair was picked (saved place, recents, or search).
class RideDestinationSelected extends RideEvent {
  const RideDestinationSelected({required this.pickup, required this.destination});

  final String pickup;
  final String destination;

  @override
  List<Object?> get props => [pickup, destination];
}

/// Returns the Home sheet from ride selection back to the idle state.
class RideDestinationCleared extends RideEvent {
  const RideDestinationCleared();
}
class RideCategorySelected extends RideEvent {
  const RideCategorySelected(this.category);

  final RideCategory category;

  @override
  List<Object?> get props => [category];
}

/// The rider confirmed the selected category; ride enters matching.
class RideConfirmRequested extends RideEvent {
  const RideConfirmRequested();
}

/// The rider cancelled the ride while it is being matched or assigned.
class RideCancelRequested extends RideEvent {
  const RideCancelRequested();
}

/// The rider dismissed a finished (completed or cancelled) ride summary.
class RideCompletionAcknowledged extends RideEvent {
  const RideCompletionAcknowledged();
}

