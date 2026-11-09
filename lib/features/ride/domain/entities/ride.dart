import 'package:equatable/equatable.dart';

import 'driver.dart';
import 'ride_category.dart';

/// Lifecycle of a requested ride, mirroring the PRD state inventory:
/// matching → assigned → in progress → completed, or cancelled.
enum RideStatus {
  matching('Finding your driver'),
  assigned('Arriving now'),
  inProgress('In progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const RideStatus(this.label);

  final String label;
}

/// A requested ride with its current lifecycle status.
class Ride extends Equatable {
  const Ride({
    required this.pickup,
    required this.destination,
    required this.category,
    required this.fareKip,
    required this.status,
    this.driver,
    this.etaMinutes,
  });

  final String pickup;
  final String destination;
  final RideCategory category;

  /// Fare in Lao kip; tabular-numeral display responsibility lives in UI.
  final int fareKip;
  final RideStatus status;

  /// Null until the ride is matched to a driver.
  final Driver? driver;

  /// Estimated minutes shown prominently while tracking.
  final int? etaMinutes;

  Ride copyWith({
    String? pickup,
    String? destination,
    RideCategory? category,
    int? fareKip,
    RideStatus? status,
    Object? driver = _unset,
    Object? etaMinutes = _unset,
  }) {
    return Ride(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      category: category ?? this.category,
      fareKip: fareKip ?? this.fareKip,
      status: status ?? this.status,
      driver: driver == _unset ? this.driver : driver as Driver?,
      etaMinutes: etaMinutes == _unset ? this.etaMinutes : etaMinutes as int?,
    );
  }

  static const _unset = Object();

  @override
  List<Object?> get props => [
        pickup,
        destination,
        category,
        fareKip,
        status,
        driver,
        etaMinutes,
      ];
}
