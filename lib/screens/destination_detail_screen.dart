import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../widgets/premium_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'ai_assist_screen.dart';
import 'audio_tour_screen.dart';
import 'food_screen.dart';
import 'game_screen.dart';
import 'hidden_gems_screen.dart';
import 'trip_scheduler_screen.dart';

class DestinationDetailScreen extends StatefulWidget {
  final String title;
  final String image;

  const DestinationDetailScreen({
    super.key,
    required this.title,
    required this.image,
  });

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_places') ?? [];
    if (mounted) setState(() => _isSaved = saved.contains(widget.title));
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = List<String>.from(prefs.getStringList('saved_places') ?? []);
    if (_isSaved) {
      saved.remove(widget.title);
    } else {
      saved.add(widget.title);
    }
    await prefs.setStringList('saved_places', saved);
    if (mounted) {
      setState(() => _isSaved = !_isSaved);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSaved ? 'Saved to your places!' : 'Removed from saved places'),
      ));
      if (_isSaved) {
        Provider.of<AppState>(context, listen: false).incrementMissionProgress('gems');
        Provider.of<AppState>(context, listen: false).incrementMissionProgress('landmarks');
      }
    }
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(widget.title);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        try {
          await launchUrl(uri);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open Maps. Is Google Maps installed?')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final about =
        '${widget.title} is presented as an AI-assisted exploration zone. ExploreMate helps travelers understand the place, discover hidden gems, play city missions, plan their day, find nearby food, and start contextual audio guidance.';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: AppColors.primaryDeep,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            actions: [
              IconButton.filledTonal(
                tooltip: _isSaved ? 'Remove from saved' : 'Save place',
                onPressed: _toggleSave,
                icon: Icon(_isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isSaved ? AppColors.danger : null),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: widget.title,
                    child: Image.network(
                      widget.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.cardBg),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .08),
                          AppColors.surface.withValues(alpha: .95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SignalBadge(),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _MetaPill(Icons.location_on_rounded, 'AI mapped place'),
                            _MetaPill(Icons.star_rounded, '4.8'),
                            _MetaPill(Icons.people_alt_rounded, 'Low crowd route'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Open Maps & Save row ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.map_rounded),
                          label: const Text('Open in Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.primaryDeep,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AudioTourScreen(placeName: widget.title))),
                          icon: const Icon(Icons.headphones_rounded),
                          label: const Text('Audio Tour'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Explore Options',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
                    childAspectRatio: MediaQuery.of(context).size.width > 360 ? .98 : .90,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ActionCard(
                        title: 'Hidden Gems',
                        subtitle: 'Find secret nearby places',
                        icon: Icons.diamond_rounded,
                        color: AppColors.accent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HiddenGemsScreen()),
                        ),
                      ),
                      _ActionCard(
                        title: 'City Explorer',
                        subtitle: 'Earn XP with place missions',
                        icon: Icons.stars_rounded,
                        color: AppColors.xpGold,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GameScreen()),
                        ),
                      ),
                      _ActionCard(
                        title: 'AI Guide',
                        subtitle: 'Ask about history, routes, timing',
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFF8DB7FF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiAssistScreen()),
                        ),
                      ),
                      _ActionCard(
                        title: 'Audio Tour',
                        subtitle: 'Start contextual narration',
                        icon: Icons.graphic_eq_rounded,
                        color: AppColors.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AudioTourScreen()),
                        ),
                      ),
                      _ActionCard(
                        title: 'Food Nearby',
                        subtitle: 'Mood-based restaurants',
                        icon: Icons.restaurant_rounded,
                        color: const Color(0xFFFFB067),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FoodScreen()),
                        ),
                      ),
                      _ActionCard(
                        title: 'Add To Plan',
                        subtitle: 'Place it in your itinerary',
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFFC78BFF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TripSchedulerScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About This Place',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          about,
                          style: TextStyle(color: adaptiveMutedColor(context, .72), height: 1.55),
                        ),
                        const SizedBox(height: 18),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip('Best at sunset'),
                            _InfoChip('Photo friendly'),
                            _InfoChip('Hidden gems nearby'),
                            _InfoChip('XP missions ready'),
                            _InfoChip('Local food nearby'),
                            _InfoChip('Audio story ready'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Place Brief',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 12),
                        _BriefRow(Icons.wb_sunny_rounded, 'Weather fit', 'Clear evening window, good visibility.'),
                        _BriefRow(Icons.diamond_rounded, 'Hidden gem scan', 'AI can surface quieter nearby spots connected to this place.'),
                        _BriefRow(Icons.stars_rounded, 'City explorer missions', 'Complete photo, food, audio, and discovery quests for XP.'),
                        _BriefRow(Icons.route_rounded, 'Suggested route', 'Start with the scenic point, then food nearby.'),
                        _BriefRow(Icons.notifications_active_rounded, 'Live alert', 'AI can notify you if crowd level changes.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: adaptiveMutedColor(context, .62), fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _BriefRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _BriefRow(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: adaptiveMutedColor(context, .62), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  const _SignalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: .5)),
      ),
      child: const Text(
        'AI exploration place',
        style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: AppColors.accent.withValues(alpha: .25)),
      backgroundColor: AppColors.accent.withValues(alpha: .10),
    );
  }
}
