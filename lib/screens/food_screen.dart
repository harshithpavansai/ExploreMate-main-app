import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/demo_data.dart';
import '../widgets/premium_widgets.dart';
import '../services/api_service.dart';
import 'destination_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  int mood = 0;
  List<dynamic> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    setState(() => _isLoading = true);
    // Determine search query based on mood
    String query = 'restaurant';
    if (moods[mood]['label'] == 'Street Food') query = 'street food';
    if (moods[mood]['label'] == 'Cafe & Chill') query = 'cafe';
    if (moods[mood]['label'] == 'Fine Dining') query = 'fine dining';
    
    // Defaulting to Goa/Baga Beach for demo purposes, you can make this dynamic later based on GPS
    final places = await ApiService().getFoodPlaces(query, 'Baga Beach');
    if (mounted) {
      setState(() {
        _places = places;
        _isLoading = false;
      });
    }
  }

  void _onMoodChanged(int index) {
    setState(() => mood = index);
    _fetchPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final active = moods[mood];
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood Food Explorer', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'AI blends your mood, weather, and local cravings.',
            style: TextStyle(color: adaptiveMutedColor(context, .62)),
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Row(
              children: [
                Icon(active['icon'] as IconData, color: active['color'] as Color, size: 38),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${active['label']} mode is active. Clear sky, 32 C, bright flavors recommended.',
                    style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Choose Mood'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: moods.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 640 ? 3 : 2,
              childAspectRatio: MediaQuery.of(context).size.width > 360 ? 1.45 : 1.25,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              final m = moods[i];
              final selected = i == mood;
              return GlassCard(
                onTap: () => _onMoodChanged(i),
                color: selected ? (m['color'] as Color).withValues(alpha: .24) : null,
                child: Row(
                  children: [
                    Icon(m['icon'] as IconData, color: m['color'] as Color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m['label'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SectionHeader(title: 'Recommended Restaurants'),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else if (_places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No places found for this mood nearby.', style: TextStyle(fontWeight: FontWeight.w600))),
            )
          else
            ..._places.map((place) {
              final name = place['name'] ?? 'Unknown Place';
              // Check if name is empty
              if (name.toString().trim().isEmpty) return const SizedBox.shrink();
              
              final type = place['type']?.toString().toUpperCase() ?? 'FOOD';
              final address = place['display_name']?.toString().split(',').take(2).join(',') ?? 'Local area';
              
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () {
                  Provider.of<AppState>(context, listen: false).incrementMissionProgress('food');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailScreen(
                        title: name,
                        image: DemoImages.food,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(colors: [(active['color'] as Color).withValues(alpha: .75), AppColors.primary]),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$type • $address',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: adaptiveMutedColor(context, .62), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.accent),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
