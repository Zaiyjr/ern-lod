import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/ride_bloc.dart';
import '../bloc/ride_event.dart';
import '../bloc/ride_state.dart';
import '../../domain/entities/ride.dart';

/// Sheet body for every post-request ride phase: matching, assigned,
/// in progress, plus completed/cancelled summary panels.
class RideTrackingPanel extends StatelessWidget {
  const RideTrackingPanel({super.key, required this.state});

  final RideState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RideMatching() => const _MatchingBody(),
      RideAssigned(:final ride) => _DriverBody(ride: ride, tracking: true),
      RideInProgress(:final ride) => _DriverBody(ride: ride, tracking: false),
      RideCompleted(:final ride) => _SummaryBody(ride: ride),
      RideCancelled(:final ride) => _SummaryBody(ride: ride),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Shared route recap: pickup → destination with a status dot.
class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.pickup, required this.destination});

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'From ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '$pickup ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: 'to ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: destination,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Matching: explain the wait, keep a way out.
class _MatchingBody extends StatelessWidget {
  const _MatchingBody();

  @override
  Widget build(BuildContext context) {
    final ride = rideOf(context.watch<RideBloc>().state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PulseHeader(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Text(
              '4 drivers near your pickup',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (ride != null)
          _RouteRow(pickup: ride.pickup, destination: ride.destination),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.dangerTint),
              backgroundColor: AppColors.dangerTint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () =>
                context.read<RideBloc>().add(const RideCancelRequested()),
            child: const Text(
              'Cancel ride',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated pulse header used while matching.
class _PulseHeader extends StatefulWidget {
  const _PulseHeader();

  @override
  State<_PulseHeader> createState() => _PulseHeaderState();
}

class _PulseHeaderState extends State<_PulseHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        'Finding your driver',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Assigned & in progress: ETA is the peak moment, driver identity and
/// contact actions stay close underneath (design.md screen hierarchy).
class _DriverBody extends StatelessWidget {
  const _DriverBody({required this.ride, required this.tracking});

  final Ride ride;
  final bool tracking;

  @override
  Widget build(BuildContext context) {
    final driver = ride.driver!;
    final headline = tracking
        ? 'Pickup in ${ride.etaMinutes ?? 3} min'
        : 'On the way to ${ride.destination}';
    final subline = tracking
        ? '${driver.name} is heading to your pickup point'
        : 'En route to your destination';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headline,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subline,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accentTint,
                child: Text(
                  driver.name.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${driver.name} · ★ ${driver.rating}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver.vehicle} · ${driver.plate}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.lineStrong),
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Call · simulated contact action'),
                    duration: Duration(seconds: 2),
                  ),
                ),
                icon: const Icon(Icons.call_rounded, size: 20),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.lineStrong),
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message · simulated contact action'),
                    duration: Duration(seconds: 2),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                label: const Text('Message'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              backgroundColor: AppColors.dangerTint,
              side: const BorderSide(color: AppColors.dangerTint),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _confirmCancel(context),
            child: const Text(
              'Cancel ride',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  /// Destructive confirmation per design.md: action sheet with a red
  /// destructive option plus a cancel action.
  ///
  /// The Bloc is captured before the modal opens: a modal bottom sheet
  /// builds on the root navigator, outside this BlocProvider.
  Future<void> _confirmCancel(BuildContext context) async {
    final rideBloc = context.read<RideBloc>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cancel this ride?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: AppColors.dangerTint,
                    side: BorderSide(color: AppColors.dangerTint),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    rideBloc.add(const RideCancelRequested());
                  },
                  child: const Text(
                    'Cancel ride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.lineStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text(
                    'Keep ride',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Completed & cancelled summary with a single way back to Home.
class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final completed = ride.status == RideStatus.completed;
    final headline = completed ? 'Ride completed' : 'Ride cancelled';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: completed ? AppColors.success : AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              headline,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Route', value: '${ride.pickup} → ${ride.destination}'),
              _SummaryRow(label: 'Service', value: ride.category.label),
              _SummaryRow(
                label: 'Fare',
                value: '₭ ${ride.fareKip}',
                tabular: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => context
                .read<RideBloc>()
                .add(const RideCompletionAcknowledged()),
            child: const Text(
              'Start a new ride',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.tabular = false,
  });

  final String label;
  final String value;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ],
      ),
    );
  }
}
