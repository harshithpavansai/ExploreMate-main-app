import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/demo_data.dart';
import '../widgets/premium_widgets.dart';
import 'audio_tour_screen.dart';
import 'destination_detail_screen.dart';

class HiddenGemsScreen extends StatefulWidget {
  const HiddenGemsScreen({super.key});

  @override
  State<HiddenGemsScreen> createState() => _HiddenGemsScreenState();
}

class _HiddenGemsScreenState extends State<HiddenGemsScreen> {
  int selected = 0;
  final chips = ['All', 'Nature', 'Culture', 'Food', 'Adventure'];

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Hidden Gem Finder', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 14),
          const AnimatedSearchBar(hint: 'Search secret viewpoints and local trails'),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(selected: i == selected, label: Text(chips[i]), onSelected: (_) => setState(() => selected = i)),
              ),
            ),
          ),
          const SectionHeader(title: 'Near You', action: 'Map'),
          ...hiddenGems.map((g) => _GemCard(g)),
        ],
      ),
    );
  }
}

class _GemCard extends StatelessWidget {
  final Map<String, dynamic> gem;
  const _GemCard(this.gem);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(gem['image'] as String, fit: BoxFit.cover),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .66)]),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _Badge(Icons.star_rounded, gem['rating'] as String),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: Text(gem['name'] as String, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Badge(Icons.near_me_rounded, gem['distance'] as String),
                    const SizedBox(width: 8),
                    const _Badge(Icons.auto_awesome_rounded, 'AI match 96%'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  gem['desc'] as String,
                  style: TextStyle(color: adaptiveMutedColor(context, .72), height: 1.45),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  radius: 18,
                  padding: const EdgeInsets.all(12),
                  color: Colors.white.withValues(alpha: .06),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded, color: AppColors.accent),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Interactive map preview - low crowd route available', style: TextStyle(fontSize: 12))),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationDetailScreen(
                              title: gem['name'] as String,
                              image: gem['image'] as String,
                            ),
                          ),
                        ),
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Explore',
                        icon: Icons.explore_rounded,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationDetailScreen(
                              title: gem['name'] as String,
                              image: gem['image'] as String,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioTourScreen())),
                      icon: const Icon(Icons.graphic_eq_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .34), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
