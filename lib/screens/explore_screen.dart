import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../models/demo_data.dart';
import '../widgets/premium_widgets.dart';
import 'food_screen.dart';
import 'hidden_gems_screen.dart';
import 'audio_tour_screen.dart';
import 'destination_detail_screen.dart';
import '../services/api_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int chip = 0;
  String _searchQuery = '';
  final filters = ['All', 'Hidden gems', 'Food', 'Heritage', 'Adventure', 'Low crowd'];

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Smart Search', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'Find destinations, local food, and AI-ranked hidden gems.',
            style: TextStyle(color: adaptiveMutedColor(context, .62)),
          ),
          const SizedBox(height: 18),
          AnimatedSearchBar(
            hint: 'Search destinations, food, gems...',
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: chip == i,
                  label: Text(filters[i]),
                  onSelected: (_) => setState(() => chip = i),
                ),
              ),
            ),
          ),
          const SectionHeader(title: 'Categories'),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
            childAspectRatio: MediaQuery.of(context).size.width > 360 ? 1.25 : 1.08,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _Category('Destinations', Icons.landscape_rounded, AppColors.accent, null),
              _Category('Food places', Icons.restaurant_rounded, AppColors.secondary, FoodScreen()),
              _Category('Hidden gems', Icons.diamond_rounded, AppColors.xpGold, HiddenGemsScreen()),
              _Category('Voice AI', Icons.mic_rounded, Color(0xFF9C8CFF), AudioTourScreen()),
            ],
          ),
          const SectionHeader(title: 'Trending Places'),
          SizedBox(
            height: 310,
            child: FutureBuilder<List<dynamic>>(
              future: ApiService().getDestinations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }

                List<Map<String, dynamic>> allItems;

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  allItems = snapshot.data!.map((item) => {
                    'name': item['name'] ?? '',
                    'place': (item['city'] != null && item['country'] != null)
                        ? '${item['city']}, ${item['country']}'
                        : (item['location'] ?? item['place'] ?? 'Unknown'),
                    'image': item['image_url'] ??
                        ((item['imageUrls'] as List?)?.isNotEmpty == true ? item['imageUrls'][0] : (item['image'] ?? DemoImages.city)),
                    'rating': item['rating']?.toString() ?? '4.5',
                    'price': item['price']?.toString() ?? (item['price_level'] != null ? '\$' * (item['price_level'] as int) : 'Free'),
                    'reviews': item['reviewsCount']?.toString() ?? item['rating_count']?.toString() ?? '0',
                    'desc': item['description'] ?? item['short_summary'] ?? '',
                    'tags': List<String>.from(item['tags'] ?? item['popularAttractions'] ?? []),
                  }).toList();
                } else {
                  allItems = destinations.cast<Map<String, dynamic>>();
                }

                // Apply search filter
                final filtered = _searchQuery.isEmpty
                    ? allItems
                    : allItems.where((d) {
                        final name = (d['name'] as String).toLowerCase();
                        final place = (d['place'] as String).toLowerCase();
                        final tags = (d['tags'] as List).join(' ').toLowerCase();
                        return name.contains(_searchQuery) ||
                            place.contains(_searchQuery) ||
                            tags.contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: adaptiveFaintColor(context)),
                        const SizedBox(height: 12),
                        Text('No results for "$_searchQuery"',
                            style: TextStyle(color: adaptiveMutedColor(context, .5))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => DestinationCard(
                    item: filtered[i],
                    width: 245,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DestinationDetailScreen(
                          title: filtered[i]['name'] as String,
                          image: filtered[i]['image'] as String,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SectionHeader(title: 'Live Map Preview'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(17.6868, 83.2185), // Visakhapatnam
                        initialZoom: 13.0,
                        interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.exploremate.app',
                          // Add a dark mode filter to match the cinematic UI
                          tileBuilder: (context, widget, tile) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                -1, 0, 0, 0, 255, //
                                0, -1, 0, 0, 255, //
                                0, 0, -1, 0, 255, //
                                0, 0, 0, 1, 0,    //
                              ]),
                              child: widget,
                            );
                          },
                        ),
                        const MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(17.7018, 83.2845), // Yarada Beach
                              width: 40,
                              height: 40,
                              child: Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 34),
                            ),
                            Marker(
                              point: LatLng(17.6868, 83.2185), // City Center
                              width: 40,
                              height: 40,
                              child: Icon(Icons.location_on_rounded, color: AppColors.accent, size: 34),
                            ),
                            Marker(
                              point: LatLng(17.8911, 83.4472), // Bheemili Beach
                              width: 40,
                              height: 40,
                              child: Icon(Icons.location_on_rounded, color: AppColors.xpGold, size: 34),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: Colors.black54,
                          child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Widget? screen;
  const _Category(this.label, this.icon, this.color, this.screen);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Showing all destinations. Type in search bar to filter!')),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          Text(
            'AI ranked',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: adaptiveMutedColor(context, .56), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
