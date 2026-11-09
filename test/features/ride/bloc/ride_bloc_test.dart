import 'package:flutter_test/flutter_test.dart';
import 'package:ride_booking/features/ride/domain/entities/ride.dart';
import 'package:ride_booking/features/ride/domain/entities/ride_category.dart';
import 'package:ride_booking/features/ride/presentation/bloc/ride_bloc.dart';
import 'package:ride_booking/features/ride/presentation/bloc/ride_event.dart';
import 'package:ride_booking/features/ride/presentation/bloc/ride_state.dart';

void main() {
  const fast = Duration(milliseconds: 1);
  // Long enough for all chained 1ms timers to fire, short enough for tests.
  const fullChain = Duration(milliseconds: 60);
  const destination = RideDestinationSelected(
    pickup: 'Current location',
    destination: 'Maple St 24',
  );

  RideBloc buildBloc({
    Duration matchDelay = fast,
    Duration pickupDelay = fast,
    Duration tripDelay = fast,
  }) =>
      RideBloc(
        matchDelay: matchDelay,
        pickupDelay: pickupDelay,
        tripDelay: tripDelay,
      );

  /// Events are handled via the internal queue, so each `add` is pump-charged
  /// before assertions.
  Future<void> feed(RideBloc bloc, RideEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  group('RideBloc lifecycle (simulated, UI-only slice)', () {
    test('starts idle', () {
      final bloc = buildBloc();
      expect(bloc.state, const RideIdle());
      return bloc.close();
    });

    test('destination selection moves to RideSelecting', () async {
      final bloc = buildBloc();
      await feed(bloc, destination);
      expect(
        bloc.state,
        const RideSelecting(
          pickup: 'Current location',
          destination: 'Maple St 24',
        ),
      );
      await bloc.close();
    });

    test('category selection updates the selected category', () async {
      final bloc = buildBloc();
      await feed(bloc, destination);
      await feed(bloc, const RideCategorySelected(RideCategory.xl));
      expect(
        bloc.state,
        const RideSelecting(
          pickup: 'Current location',
          destination: 'Maple St 24',
          category: RideCategory.xl,
        ),
      );
      await bloc.close();
    });

    test('confirm runs matching → assigned → in progress → completed → idle',
        () async {
      final bloc = buildBloc();
      final received = <RideState>[];
      final sub = bloc.stream.listen(received.add);

      await feed(bloc, destination);
      await feed(bloc, const RideConfirmRequested());
      expect(bloc.state, isA<RideMatching>());

      // Let the whole simulated pipeline run: 1ms per phase.
      await Future<void>.delayed(fullChain);
      expect(bloc.state, isA<RideCompleted>());

      final matching = received.whereType<RideMatching>().single;
      expect(matching.ride.status, RideStatus.matching);
      expect(matching.ride.driver, isNull);

      final assigned = received.whereType<RideAssigned>().single;
      expect(assigned.ride.status, RideStatus.assigned);
      expect(assigned.ride.driver, isNotNull);
      expect(assigned.ride.driver!.name, 'Somchai');

      final inProgress = received.whereType<RideInProgress>().single;
      expect(inProgress.ride.status, RideStatus.inProgress);

      final completed = received.whereType<RideCompleted>().single;
      expect(completed.ride.status, RideStatus.completed);
      expect(completed.ride.fareKip, RideCategory.standard.baseFareKip);

      await feed(bloc, const RideCompletionAcknowledged());
      expect(bloc.state, const RideIdle());

      await sub.cancel();
      await bloc.close();
    });

    test('cancel during matching yields a cancelled ride, then idle on ack',
        () async {
      // Pickup delay long enough that we stay in matching.
      final bloc = buildBloc(matchDelay: fast, pickupDelay: const Duration(seconds: 10));
      await feed(bloc, destination);
      await feed(bloc, const RideConfirmRequested());
      expect(bloc.state, isA<RideMatching>());

      await feed(bloc, const RideCancelRequested());
      final cancelled = (bloc.state as RideCancelled).ride;
      expect(cancelled.status, RideStatus.cancelled);
      expect(cancelled.driver, isNull);

      await feed(bloc, const RideCompletionAcknowledged());
      expect(bloc.state, const RideIdle());
      await bloc.close();
    });

    test('cancel during assigned keeps the driver in the summary', () async {
      final bloc = buildBloc(matchDelay: fast, pickupDelay: const Duration(seconds: 10));
      await feed(bloc, destination);
      await feed(bloc, const RideConfirmRequested());
      await Future<void>.delayed(fullChain);
      expect(bloc.state, isA<RideAssigned>());

      await feed(bloc, const RideCancelRequested());
      expect(bloc.state, isA<RideCancelled>());
      expect((bloc.state as RideCancelled).ride.driver, isNotNull);
      await bloc.close();
    });

    test('cancel is ignored once the trip is in progress', () async {
      // Trip delay long enough that we stay in progress after cancelling.
      final bloc = buildBloc(
        matchDelay: fast,
        pickupDelay: fast,
        tripDelay: const Duration(seconds: 10),
      );
      await feed(bloc, destination);
      await feed(bloc, const RideConfirmRequested());
      await Future<void>.delayed(fullChain);
      expect(bloc.state, isA<RideInProgress>());

      await feed(bloc, const RideCancelRequested());
      expect(bloc.state, isA<RideInProgress>());
      await bloc.close();
    });

    test('clearing the destination returns to idle', () async {
      final bloc = buildBloc();
      await feed(bloc, destination);
      await feed(bloc, const RideDestinationCleared());
      expect(bloc.state, const RideIdle());
      await bloc.close();
    });
  });
}
