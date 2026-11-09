import 'package:equatable/equatable.dart';

/// Assigned driver identity shown during ride tracking.
///
/// TODO(slice 4): populate from the `/api/v1/rides` match response once the
/// API layer exists. Values for the UI-only slice are representative mocks.
class Driver extends Equatable {
  const Driver({
    required this.name,
    required this.vehicle,
    required this.plate,
    required this.rating,
  });

  final String name;
  final String vehicle;
  final String plate;
  final double rating;

  @override
  List<Object?> get props => [name, vehicle, plate, rating];
}
