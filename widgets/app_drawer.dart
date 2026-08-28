import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../screens/hidden_gems_screen.dart';
import '../screens/audio_tour_screen.dart';
import '../screens/trip_scheduler_screen.dart';
import '../screens/translator_screen.dart';
import '../screens/ai_assist_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/food_screen.dart';
import '../screens/game_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primaryDeep,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionLabel('General'),
                _buildItem(context, Icons.home_rounded, 'Home', onTap: () => _pop(context)),
                _buildItem(context, Icons.explore_rounded, 'Explore Map',
                    onTap: () => _navigate(context, const ExploreScreen())),
                _buildItem(context, Icons.restaurant_rounded, 'Food Explorer',
                    onTap: () => _navigate(context, const FoodScreen())),
                _buildItem(context, Icons.stars_rounded, 'City Game',
                    badge: 'New', onTap: () => _navigate(context, const GameScreen())),

                _buildSectionLabel('Key Features'),
                _buildItem(context, Icons.diamond_rounded, 'Hidden Gems',
                    onTap: () => _navigate(context, const HiddenGemsScreen())),
                _buildItem(context, Icons.audiotrack_rounded, 'Audio Tour Guide',
                    onTap: () => _navigate(context, const AudioTourScreen())),
                _buildItem(context, Icons.calendar_today_rounded, 'Trip Scheduler',
                    onTap: () => _navigate(context, const TripSchedulerScreen())),
                _buildItem(context, Icons.translate_rounded, 'Translator',
                    onTap: () => _navigate(context, const TranslatorScreen())),
                _buildItem(context, Icons.psychology_rounded, 'AI Assist',
                    onTap: () => _navigate(context, const AiAssistScreen())),

                _buildSectionLabel('Account'),
                _buildItem(context, Icons.person_rounded, 'Profile', onTap: () => _pop(context)),
                _buildItem(context, Icons.leaderboard_rounded, 'Leaderboard', onTap: () => _pop(context)),
                _buildItem(context, Icons.notifications_rounded, 'Notifications',
                    badge: '3', onTap: () => _pop(context)),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.explore_rounded, color: AppColors.primaryDeep, size: 24),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ExploreMate',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('v2.1.0',
                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent,
                  child: Text('AK',
                      style: TextStyle(
                          color: AppColors.primaryDeep, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arjun Kumar',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('Pro Explorer · Lv.4',
                        style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(label.toUpperCase(),
          style: const TextStyle(
              color: Colors.white30, fontSize: 9,
              fontWeight: FontWeight.w600, letterSpacing: 1.0)),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String label,
      {String? badge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: Colors.white60, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge,
                    style: const TextStyle(color: Colors.white, fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          _buildFooterItem(Icons.settings_rounded, 'Settings', onTap: () {}),
          const SizedBox(height: 4),
          _buildFooterItem(Icons.logout_rounded, 'Log out',
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 16),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) => Navigator.of(context).pop();
  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
