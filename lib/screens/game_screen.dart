import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/premium_widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final missionDefinitions = const [
    (id: 'gems', title: 'Visit 3 hidden gems', total: 3, xp: 200, icon: Icons.diamond_rounded),
    (id: 'landmarks', title: 'Capture 5 landmarks', total: 5, xp: 350, icon: Icons.photo_camera_rounded),
    (id: 'food', title: 'Try 3 street foods', total: 3, xp: 150, icon: Icons.ramen_dining_rounded),
    (id: 'audio', title: 'Complete an audio tour', total: 1, xp: 100, icon: Icons.graphic_eq_rounded),
    (id: 'trips', title: 'Plan 2 trips', total: 2, xp: 120, icon: Icons.calendar_today_rounded),
    (id: 'translate', title: 'Translate 5 signs', total: 5, xp: 80, icon: Icons.translate_rounded),
  ];

  void _showMissionInfo(String title, String id) {
    String actionInfo = '';
    if (id == 'gems' || id == 'landmarks') {
      actionInfo = 'To progress this mission, search and save a place on the Destination Details page!';
    } else if (id == 'food') {
      actionInfo = 'To progress this mission, tap on a recommended restaurant in the Mood Food Explorer!';
    } else if (id == 'audio') {
      actionInfo = 'To progress this mission, listen to any Voice AI audio tour to completion!';
    } else if (id == 'trips') {
      actionInfo = 'To progress this mission, create and save a new itinerary in the Trip Scheduler!';
    } else if (id == 'translate') {
      actionInfo = 'To progress this mission, perform a text translation in the Live Translator!';
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
          const SizedBox(height: 4),
          Text(actionInfo),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF10233A),
      duration: const Duration(seconds: 4),
    ));
  }

  static const badges = [
    (Icons.diamond_rounded, 'Gem Hunter', true),
    (Icons.restaurant_rounded, 'Foodie', true),
    (Icons.explore_rounded, 'Navigator', true),
    (Icons.camera_alt_rounded, 'Lens Eye', true),
    (Icons.translate_rounded, 'Polyglot', false),
    (Icons.nights_stay_rounded, 'Night Owl', false),
    (Icons.hiking_rounded, 'Trekker', false),
    (Icons.auto_stories_rounded, 'Historian', false),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('City Explorer', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Complete missions, earn XP, and unlock badges.',
              style: TextStyle(color: adaptiveMutedColor(context, .62))),
          const SizedBox(height: 18),

          // ── XP Progress ───────────────────────────────────────
          XpProgressWidget(xp: state.xp, level: state.level),

          // ── Daily Challenge ───────────────────────────────────
          const SectionHeader(title: 'Daily Challenge'),
          GestureDetector(
            onTap: state.dailyChallengeCompleted ? null : () {
              state.completeDailyChallenge();
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Daily challenge completed! +75 XP earned 🎉'),
                  ],
                ),
                backgroundColor: Color(0xFF1A2940),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: GlassCard(
              color: state.dailyChallengeCompleted
                  ? AppColors.success.withValues(alpha: .08)
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: state.dailyChallengeCompleted
                          ? const LinearGradient(colors: [AppColors.success, Color(0xFF8CEFA5)])
                          : AppColors.sunriseGradient,
                    ),
                    child: Icon(
                        state.dailyChallengeCompleted
                            ? Icons.check_rounded
                            : Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Visit any 2 food stalls today',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          state.dailyChallengeCompleted ? 'Completed! 🎉' : 'Resets in 8h 24m',
                          style: TextStyle(
                              color: state.dailyChallengeCompleted
                                  ? AppColors.success
                                  : AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: state.dailyChallengeCompleted
                          ? AppColors.success.withValues(alpha: .15)
                          : AppColors.xpGold.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.dailyChallengeCompleted
                            ? AppColors.success.withValues(alpha: .4)
                            : AppColors.xpGold.withValues(alpha: .4),
                      ),
                    ),
                    child: Text(
                      state.dailyChallengeCompleted ? '✓ Claimed' : '+75 XP',
                      style: TextStyle(
                          color: state.dailyChallengeCompleted
                              ? AppColors.success
                              : AppColors.xpGold,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Active Missions ───────────────────────────────────
          const SectionHeader(title: 'Active Missions'),
          ...missionDefinitions.map((def) {
            final current = state.missionProgress[def.id] ?? 0;
            final progress = (current / def.total).clamp(0.0, 1.0);
            final done = current >= def.total;

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () => _showMissionInfo(def.title, def.id),
              child: Row(
                children: [
                  Icon(def.icon,
                      color: done ? AppColors.success : AppColors.accent, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                decoration: done ? TextDecoration.lineThrough : null)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  color: done ? AppColors.success : AppColors.accent,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$current/${def.total}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: adaptiveMutedColor(context, .56))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    done ? '✓ Done' : '+${def.xp} XP',
                    style: TextStyle(
                        color: done ? AppColors.success : AppColors.xpGold,
                        fontWeight: FontWeight.w900,
                        fontSize: 13),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: Text(
                'Tap a mission card to see instructions',
                style: TextStyle(color: adaptiveMutedColor(context, .45), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // ── Achievement Badges ────────────────────────────────
          const SectionHeader(title: 'Achievement Badges'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemBuilder: (_, i) {
              final (icon, label, _) = badges[i];
              final unlocked = state.badges.contains(label);
              return Tooltip(
                message: label,
                child: GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          color: unlocked
                              ? AppColors.xpGold
                              : adaptiveFaintColor(context),
                          size: 28),
                      const SizedBox(height: 4),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 8,
                              color: unlocked
                                  ? AppColors.xpGold
                                  : adaptiveFaintColor(context))),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Leaderboard ───────────────────────────────────────
          const SectionHeader(title: 'Leaderboard'),
          ...[
            ('#1', 'Priya S.', '4820 XP', true),
            ('#2', 'Ravi K.', '3910 XP', true),
            ('#5', 'Meera T.', '2650 XP', false),
            ('#12', 'You', '${state.xp} XP', false),
          ].map((row) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: row.$4 ? AppColors.xpGold.withValues(alpha: .2) : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(row.$1,
                        style: TextStyle(
                            color: row.$4 ? AppColors.xpGold : adaptiveMutedColor(context, .5),
                            fontWeight: FontWeight.w900,
                            fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(row.$2,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: row.$3.contains(state.xp.toString())
                              ? AppColors.accent
                              : null)),
                ),
                Text(row.$3,
                    style: TextStyle(
                        color: row.$4 ? AppColors.xpGold : adaptiveMutedColor(context, .5),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
