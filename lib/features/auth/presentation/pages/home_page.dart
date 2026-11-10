import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../ride/presentation/bloc/ride_bloc.dart';
import '../../../ride/presentation/bloc/ride_event.dart';
import '../../../ride/presentation/bloc/ride_state.dart';
import '../../../ride/presentation/widgets/ride_selection_panel.dart';
import '../../../ride/presentation/widgets/ride_tracking_panel.dart';
import '../../../ride/presentation/widgets/osm_map_background.dart';

/// Screen 01 · Request a ride / Home Page
///
/// Map-first; the bottom sheet is driven by the ride lifecycle Bloc, so
/// the active state—not widget-local booleans—decides which panel and CTA
/// render (ARCHITECTURE.md state model).
///
/// [rideBloc] is injectable for widget tests; production leaves it null
/// and a fresh Bloc is created per Home visit.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.rideBloc});

  final RideBloc? rideBloc;

  @override
  Widget build(BuildContext context) {
    if (rideBloc != null) {
      return BlocProvider<RideBloc>.value(
        value: rideBloc!,
        child: const _HomePageView(),
      );
    }
    return BlocProvider<RideBloc>(
      create: (_) => RideBloc(),
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<_HomePageView> {
  /// Real-time pickup label resolved from the rider's GPS position via
  /// reverse geocoding; null until the first lookup settles.
  String? _pickupAddress;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = switch (authState) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

    final rawName = user?.displayName ?? user?.email ?? 'Alex';
    final initial =
        rawName.isNotEmpty ? rawName.substring(0, 1).toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppColors.base,
      body: Stack(
        children: [
          // 1. Real interactive OpenStreetMap background
          Positioned.fill(
            child: OsmMapBackground(
              // Real-time address: reverse-geocode GPS movement (throttled)
              onPickupAddressResolved: (address) =>
                  setState(() => _pickupAddress = address),
              // Tap-to-pick destination with its resolved address
              onPointSelected: (picked) => context.read<RideBloc>().add(
                    RideDestinationSelected(
                      pickup: _pickupAddress ?? 'Current location',
                      destination: picked.address,
                    ),
                  ),
            ),
          ),

          // 2. Safe Area floating UI elements
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top action bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Avatar / Profile button with menu for Sign Out
                      PopupMenuButton<String>(
                        tooltip: 'Profile options',
                        offset: const Offset(0, 52),
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        onSelected: (val) {
                          if (val == 'signout') {
                            context
                                .read<AuthBloc>()
                                .add(const AuthSignOutRequested());
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Text(
                              user?.email ?? 'Signed in',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'signout',
                            child: Row(
                              children: [
                                Icon(Icons.logout,
                                    size: 18, color: AppColors.danger),
                                SizedBox(width: 10),
                                Text(
                                  'Sign out',
                                  style: TextStyle(color: AppColors.danger),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.brand,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F0F172A),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // "Where to?" searchbar
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _selectDestination(
                            context,
                            'Maple St 24',
                          ),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(245),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.line),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D0F172A),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Where to?',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Notification bell with badge dot
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _showNotificationNotice,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(245),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D0F172A),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 3. Bottom sheet, driven by the ride lifecycle state
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F0F172A),
                        blurRadius: 36,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: BlocBuilder<RideBloc, RideState>(
                    builder: (context, state) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(state.runtimeType),
                        child: switch (state) {
                          RideSelecting() => RideSelectionPanel(state: state),
                          RideIdle() => _IdleSheetBody(
                              pickupAddress: _pickupAddress,
                            ),
                          _ => RideTrackingPanel(state: state),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectDestination(BuildContext context, String destination) {
    context.read<RideBloc>().add(
          RideDestinationSelected(
            pickup: _pickupAddress ?? 'Current location',
            destination: destination,
          ),
        );
  }

  void _showNotificationNotice() {
    // Keep prior behavior: notices are not wired in this slice.
    // (Click target responds to satisfy a visible pressed state.)
  }
}

/// Idle sheet body: greeting, saved places, and the drivers note.
class _IdleSheetBody extends StatelessWidget {
  const _IdleSheetBody({this.pickupAddress});

  /// Reverse-geocoded address of the rider's GPS position, or null while
  /// the lookup has not resolved yet.
  final String? pickupAddress;

  void _selectDestination(BuildContext context, String destination) {
    context.read<RideBloc>().add(
          RideDestinationSelected(
            pickup: pickupAddress ?? 'Current location',
            destination: destination,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = switch (authState) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final rawName = user?.displayName ?? user?.email ?? 'Alex';
    final firstName = rawName.split(' ').first.split('@').first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Eyebrow greeting
        Text(
          'GOOD EVENING, ${firstName.toUpperCase()}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),

        // Title
        const Text(
          'Where are you going?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Saved places rows (Home & Work)
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _DestinationRow(
                icon: Icons.home_rounded,
                title: 'Home',
                subtitle: 'Maple St 24 · 12 min',
                onTap: () => _selectDestination(context, 'Maple St 24'),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.line,
              ),
              _DestinationRow(
                icon: Icons.work_rounded,
                title: 'Work',
                subtitle: '3rd Ave 88 · 24 min',
                onTap: () => _selectDestination(context, '3rd Ave 88'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Real-time pickup address resolved from the rider's GPS position,
        // shown directly above the CTA so the shortest visual path reads
        // "departing from X → set pickup".
        Row(
          children: [
            const Icon(
              Icons.near_me_rounded,
              size: 16,
              color: AppColors.accent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pickupAddress != null
                    ? 'Departing from $pickupAddress'
                    : 'Locating your pickup address…',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // CTA button — one primary action per state
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _selectDestination(context, 'Riverside Park'),
            child: const Text(
              'Set pickup location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Drivers status note
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 15,
              ),
              SizedBox(width: 6),
              Text(
                '4 drivers near Riverside Park',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
