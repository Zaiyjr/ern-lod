import 'package:equatable/equatable.dart';

import '../../domain/entities/driver.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_category.dart';

/// Mutually exclusive ride phases. The active state, not widget-local
/// booleans, decides which sheet panel and CTA render (ARCHITECTURE.md).
sealed class RideState extends Equatable {
  const RideState();

  @override
  List<Object?> get props => const [];
}

/// Home sheet: destination entry with saved places and recents.
class RideIdle extends RideState {
  const RideIdle();
}

/// Home sheet: destination chosen; category rows with fare quotes.
class RideSelecting extends RideState {
  const RideSelecting({
    required this.pickup,
    required this.destination,
    this.category = RideCategory.standard,
  });

  final String pickup;
  final String destination;
  final RideCategory category;

  @override
  List<Object?> get props => [pickup, destination, category];
}

/// The ride request was accepted and a driver is being matched.
class RideMatching extends RideState {
  const RideMatching({required this.ride});

  final Ride ride;

  @override
  List<Object?> get props => [ride];
}

/// A driver accepted; they are en route to the pickup point.
class RideAssigned extends RideState {
  const RideAssigned({required this.ride});

  final Ride ride;

  @override
  List<Object?> get props => [ride];
}

/// The rider is in the car; the trip to the destination is running.
class RideInProgress extends RideState {
  const RideInProgress({required this.ride});

  final Ride ride;

  @override
  List<Object?> get props => [ride];
}

/// The trip finished; a summary is shown until acknowledged.
class RideCompleted extends RideState {
  const RideCompleted({required this.ride});

  final Ride ride;

  @override
  List<Object?> get props => [ride];
}

/// The ride was cancelled; a summary is shown until acknowledged.
class RideCancelled extends RideState {
  const RideCancelled({required this.ride});

  final Ride ride;

  @override
  List<Object?> get props => [ride];
}

/// Marker for summary states so shared rendering can branch on it.
typedef RideSummaryState = RideCompleted;

/// Convenience helpers for tracking states that carry a ride.
Ride? rideOf(RideState state) => switch (state) {
      RideMatching(:final ride) ||
      RideAssigned(:final ride) ||
      RideInProgress(:final ride) ||
      RideCompleted(:final ride) ||
      RideCancelled(:final ride) =>
        ride,
      _ => null,
    };

/// Re-exported for panels that compose driver details.
typedef RideDriver = Driver;
