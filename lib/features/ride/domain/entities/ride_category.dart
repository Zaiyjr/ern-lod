/// Vehicle categories offered on the Home ride-selection sheet.
///
/// Fare and ETA values are presentation-only placeholders for the UI-only
/// slice; real prices must come from the rides API once wired (PRD §8).
enum RideCategory {
  standard('Ride',
      seatCapacity: 4, baseFareKip: 45000, etaWindow: '3–6 min'),
  xl('XL', seatCapacity: 6, baseFareKip: 78000, etaWindow: '6–10 min'),
  share('Share', seatCapacity: 2, baseFareKip: 28000, etaWindow: '5–8 min');

  const RideCategory(
    this.label, {
    required this.seatCapacity,
    required this.baseFareKip,
    required this.etaWindow,
  });

  /// English-first display label; kept short so it also fits a chip.
  final String label;

  final int seatCapacity;

  /// Presentation placeholder fare in Lao kip.
  final int baseFareKip;

  /// Presentation placeholder arrival window label.
  final String etaWindow;
}
