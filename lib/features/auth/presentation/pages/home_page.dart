import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../ride/presentation/widgets/osm_map_background.dart';

/// Screen 01 · Request a ride / Home Page
/// Matches the mockup design board: Dark Map, Profile avatar, Search bar,
/// ride-type chips, bottom sheet with quick destination rows and CTA.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedChipIndex = 0;
  final List<String> _rideTypes = ['Ride', 'XL', 'Share'];

  void _showNotificationNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No new notifications'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDestinationSelected(String place) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected destination: $place'),
        duration: const Duration(seconds: 2),
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
    final initial =
        rawName.isNotEmpty ? rawName.substring(0, 1).toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppColors.base,
      body: Stack(
        children: [
          // 1. Real interactive OpenStreetMap background
          const Positioned.fill(
            child: OsmMapBackground(),
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
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.accentSoft],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // "Where to?" Searchbar
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDestinationSelected('Search location'),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xF2192134),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: AppColors.textMuted,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Where to?',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
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
                        borderRadius: BorderRadius.circular(14),
                        onTap: _showNotificationNotice,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xF0192134),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line),
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

                // Ride type selector chips
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: List.generate(_rideTypes.length, (idx) {
                      final selected = _selectedChipIndex == idx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _selectedChipIndex = idx;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0x472563EB)
                                  : const Color(0xEB192134),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0x8C60A5FA)
                                    : AppColors.line,
                              ),
                            ),
                            child: Text(
                              _rideTypes[idx],
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFE8F1FF)
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(),

                // 3. Bottom Sheet (Screen 01 sheet)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF192134),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border(
                      top: BorderSide(color: Color(0x12FFFFFF)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x73040812),
                        blurRadius: 48,
                        offset: Offset(0, -24),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle pill
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Eyebrow greeting
                      Text(
                        'GOOD EVENING, ${firstName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      const Text(
                        'Where are you going?',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Saved places rows (Home & Work)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0x06FFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            _DestinationRow(
                              icon: Icons.home_rounded,
                              title: 'Home',
                              subtitle: 'Maple St 24 · 12 min',
                              onTap: () =>
                                  _showDestinationSelected('Maple St 24 (Home)'),
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
                              onTap: () =>
                                  _showDestinationSelected('3rd Ave 88 (Work)'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CTA Button
                      ElevatedButton(
                        onPressed: () =>
                            _showDestinationSelected('Custom Pickup Location'),
                        child: const Text('Set pickup location'),
                      ),
                      const SizedBox(height: 12),

                      // Drivers status note
                      const Center(
                        child: Text(
                          '4 drivers near Riverside Park',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.accentSoft,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
