import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../models/trip_model.dart';
import '../providers/app_state.dart';
import '../services/trip_service.dart';
import '../widgets/premium_widgets.dart';
import 'smart_travel_tools_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _savedCount = 0;
  List<TripModel> _trips = [];
  bool _loadingTrips = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCount();
    _loadTrips();
  }

  Future<void> _loadSavedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_places') ?? [];
    if (mounted) setState(() => _savedCount = saved.length);
  }

  Future<void> _loadTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final trips = await TripService.instance.getTrips(user.uid);
      if (mounted) {
        setState(() {
          _trips = trips;
          _loadingTrips = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loadingTrips = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dark = state.themeMode == ThemeMode.dark;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final displayName = firebaseUser?.displayName ?? 'Explorer';
    final email = firebaseUser?.email ?? '';
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'EX';

    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Header ────────────────────────────────────
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, gradient: AppColors.cyanGradient),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                              color: AppColors.primaryDeep,
                              fontSize: 24,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                            email.isEmpty ? 'Level ${state.level} Explorer' : email,
                            style: TextStyle(color: adaptiveMutedColor(context, .62), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: dark, onChanged: state.toggleTheme),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Stat('Trips', state.tripCount.toString()),
                    _Stat('Places', _savedCount.toString()),
                    _Stat('Badges', state.badges.length.toString()),
                  ],
                ),
              ],
            ),
          ),

          XpProgressWidget(xp: state.xp, level: state.level),

          // ── Travel History ────────────────────────────────────
          const SectionHeader(title: 'Travel History'),
          if (_loadingTrips)
            const Center(child: CircularProgressIndicator())
          else if (_trips.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No trips in your history yet.',
                    style: TextStyle(color: Colors.white70)),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _trips.length,
                itemBuilder: (context, index) {
                  final trip = _trips[index];
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1B5E5C), Color(0xFF439F9D)],
                              ),
                            ),
                          ),
                          Container(color: Colors.black.withValues(alpha: .15)),
                          Positioned(
                            left: 14, bottom: 14, right: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(trip.destination,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  '${trip.totalDays} days',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Settings Tiles ────────────────────────────────────
          const SectionHeader(title: 'Saved Places & Settings'),
          _Tile(
            Icons.favorite_rounded,
            'Saved Places',
            _savedCount == 0 ? 'No saved places yet' : '$_savedCount places saved',
            color: AppColors.danger,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SmartTravelToolsScreen()));
              _loadSavedCount(); // Refresh count when returning
            },
          ),
          _Tile(
            Icons.workspace_premium_rounded,
            'Achievements',
            state.badges.isEmpty ? 'No achievements yet' : state.badges.join(', '),
          ),
          _Tile(
            Icons.security_rounded,
            'Privacy & Offline Maps',
            'Manage local travel data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SmartTravelToolsScreen()),
            ),
          ),
          _Tile(
            Icons.tune_rounded,
            'AI Preferences',
            'Adventure, food-first, low crowds',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚙️ AI Preferences: Adventure, food-first, and low crowd filters are active.'),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accent)),
          Text(label,
              style: TextStyle(color: adaptiveMutedColor(context, .56), fontSize: 12)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;
  const _Tile(this.icon, this.title, this.subtitle, {this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: TextStyle(color: adaptiveMutedColor(context, .56), fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: adaptiveFaintColor(context)),
        ],
      ),
    );
  }
}
