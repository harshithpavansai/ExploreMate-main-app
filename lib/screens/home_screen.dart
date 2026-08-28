import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/demo_data.dart';
import '../providers/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/premium_widgets.dart';
import 'ai_assist_screen.dart';
import 'audio_tour_screen.dart';
import 'destination_detail_screen.dart';
import 'explore_screen.dart';
import 'food_screen.dart';
import 'game_screen.dart';
import 'hidden_gems_screen.dart';
import 'profile_screen.dart';
import 'smart_travel_tools_screen.dart';
import 'trip_scheduler_screen.dart';
import 'translator_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  Offset? chatButtonPosition;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AppState>(context, listen: false).loadUserData();
      }
    });
  }

  late final pages = <Widget>[
    _HomeTab(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
    const ExploreScreen(),
    const TripSchedulerScreen(),
    const TranslatorScreen(),
    const ProfileScreen(),
  ];

  final nav = const [
    (Icons.home_rounded, 'Home'),
    (Icons.travel_explore_rounded, 'Explore'),
    (Icons.calendar_month_rounded, 'Trips'),
    (Icons.translate_rounded, 'Translator'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final inactiveNavColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : AppColors.textMid.withValues(alpha: .68);
    return Scaffold(
      key: scaffoldKey,
      extendBody: true,
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const buttonSize = 64.0;
          final topMin = MediaQuery.of(context).padding.top + 12;
          final maxX = math.max(12.0, constraints.maxWidth - buttonSize - 12);
          final maxY = math.max(topMin, constraints.maxHeight - buttonSize - 128);
          final position = chatButtonPosition ??
              Offset(
                maxX,
                maxY,
              );

          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  child: KeyedSubtree(key: ValueKey(currentIndex), child: pages[currentIndex]),
                ),
              ),
              Positioned(
                left: position.dx.clamp(12.0, maxX).toDouble(),
                top: position.dy.clamp(topMin, maxY).toDouble(),
                child: _FloatingAiChatButton(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiAssistScreen()),
                  ),
                  onDrag: (delta) {
                    setState(() {
                      final current = chatButtonPosition ?? position;
                      chatButtonPosition = Offset(
                        (current.dx + delta.dx).clamp(12.0, maxX).toDouble(),
                        (current.dy + delta.dy).clamp(topMin, maxY).toDouble(),
                      );
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: GlassCard(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(nav.length, (i) {
              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent.withValues(alpha: .18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(nav[i].$1, color: selected ? AppColors.accent : inactiveNavColor, size: 21),
                        const SizedBox(height: 3),
                        Text(
                          nav[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? AppColors.accent : inactiveNavColor,
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FloatingAiChatButton extends StatefulWidget {
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;

  const _FloatingAiChatButton({
    required this.onTap,
    required this.onDrag,
  });

  @override
  State<_FloatingAiChatButton> createState() => _FloatingAiChatButtonState();
}

class _FloatingAiChatButtonState extends State<_FloatingAiChatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -4 * controller.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) => widget.onDrag(details.delta),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.cyanGradient,
            border: Border.all(color: Colors.white.withValues(alpha: .34), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: .38),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primaryDeep,
                size: 31,
              ),
              Positioned(
                right: 13,
                top: 13,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryDeep, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback openDrawer;
  const _HomeTab({required this.openDrawer});

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(onPressed: openDrawer, icon: const Icon(Icons.menu_rounded)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good evening, ${FirebaseAuth.instance.currentUser?.displayName?.split(' ')[0] ?? 'Explorer'}', style: TextStyle(color: adaptiveMutedColor(context, .72), fontSize: 12)),
                    const Text('Where shall AI take you?', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                icon: const Icon(Icons.notifications_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.cyanGradient),
                      child: const Icon(Icons.psychology_rounded, color: AppColors.primaryDeep),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I found 7 cinematic routes near you based on weather, crowd energy, and your food mood.',
                        style: TextStyle(height: 1.4, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSearchBar(
                  hint: 'Search destinations, food, hidden gems',
                  onMicTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const WeatherWidget(),
          const SectionHeader(title: 'Recommended For You', action: 'See all'),
          SizedBox(
            height: 330,
            child: FutureBuilder<List<dynamic>>(
              future: ApiService().getDestinations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: destinations.length,
                    itemBuilder: (_, i) => DestinationCard(
                      item: destinations[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DestinationDetailScreen(
                            title: destinations[i]['name'] as String,
                            image: destinations[i]['image'] as String,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                
                final liveDestinations = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: liveDestinations.length,
                  itemBuilder: (_, i) {
                    final item = liveDestinations[i];
                    final mappedItem = {
                      'name': item['name'] ?? '',
                      'place': (item['city'] != null && item['country'] != null)
                          ? '${item['city']}, ${item['country']}'
                          : (item['location'] ?? item['place'] ?? 'Unknown'),
                      'image': item['image_url'] ??
                          (item['imageUrls']?.isNotEmpty == true ? item['imageUrls'][0] : (item['image'] ?? DemoImages.city)),
                      'rating': item['rating']?.toString() ?? '4.5',
                      'price': item['price']?.toString() ?? (item['price_level'] != null ? '\$' * (item['price_level'] as int) : 'Free'),
                      'reviews': item['reviewsCount']?.toString() ?? item['rating_count']?.toString() ?? '100',
                      'desc': item['description'] ?? item['short_summary'] ?? '',
                      'tags': List<String>.from(item['tags'] ?? item['popularAttractions'] ?? []),
                    };
                    return DestinationCard(
                      item: mappedItem,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DestinationDetailScreen(
                            title: mappedItem['name'] as String,
                            image: mappedItem['image'] as String,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SectionHeader(title: 'AI Exploration Modes'),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
            childAspectRatio: MediaQuery.of(context).size.width > 360 ? 1.08 : .98,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _ModeCard('Hidden Gems', Icons.diamond_rounded, AppColors.accent, HiddenGemsScreen()),
              _ModeCard('Food Mood', Icons.restaurant_rounded, AppColors.secondary, FoodScreen()),
              _ModeCard('City Game', Icons.stars_rounded, AppColors.xpGold, GameScreen()),
              _ModeCard('AI Guide', Icons.graphic_eq_rounded, Color(0xFF8DB7FF), AudioTourScreen()),
            ],
          ),
          const SectionHeader(title: 'Smart Travel Tools'),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
            childAspectRatio: MediaQuery.of(context).size.width > 360 ? 1.08 : .98,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _ModeCard('AI Memory', Icons.memory_rounded, AppColors.accent, SmartTravelToolsScreen()),
              _ModeCard('Offline Mode', Icons.download_for_offline_rounded, Color(0xFF8DB7FF), SmartTravelToolsScreen()),
              _ModeCard('Safety AI', Icons.health_and_safety_rounded, AppColors.success, SmartTravelToolsScreen()),
              _ModeCard('Day Optimizer', Icons.auto_awesome_rounded, AppColors.secondary, SmartTravelToolsScreen()),
              _ModeCard('AR Scanner', Icons.view_in_ar_rounded, Color(0xFFC78BFF), SmartTravelToolsScreen()),
              _ModeCard('Culture Cards', Icons.diversity_3_rounded, AppColors.xpGold, SmartTravelToolsScreen()),
              _ModeCard('Expense Split', Icons.payments_rounded, Color(0xFF57C7FF), SmartTravelToolsScreen()),
              _ModeCard('Photo Journal', Icons.auto_stories_rounded, Color(0xFFFF8FB3), SmartTravelToolsScreen()),
              _ModeCard('Emergency SOS', Icons.sos_rounded, AppColors.danger, SmartTravelToolsScreen()),
              _ModeCard('Pro Dashboard', Icons.workspace_premium_rounded, AppColors.accentLight, SmartTravelToolsScreen()),
            ],
          ),
          const SectionHeader(title: 'Nearby Hidden Gems'),
          ...hiddenGems.map((gem) => GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.zero,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DestinationDetailScreen(
                      title: gem['name'] as String,
                      image: gem['image'] as String,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(gem['image'] as String, width: 68, height: 68, fit: BoxFit.cover),
                  ),
                  title: Text(
                    gem['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${gem['type']} - ${gem['distance']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: adaptiveMutedColor(context, .62)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded, color: AppColors.accent),
                ),
              )),
          Consumer<AppState>(
            builder: (_, state, __) => XpProgressWidget(xp: state.xp, level: state.level),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _ModeCard(this.title, this.icon, this.color, this.screen);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Open module',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: adaptiveMutedColor(context, .56), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Mission update', 'You are one hidden gem away from Gem Hunter II.', Icons.flag_rounded, AppColors.xpGold),
      ('Weather alert', 'Light rain expected at 7 PM near Beach Road.', Icons.cloud_rounded, const Color(0xFF70B7FF)),
      ('Nearby place', 'A low-crowd viewpoint opened 1.4 km from you.', Icons.place_rounded, AppColors.accent),
      ('AI suggestion', 'Try the heritage-night route before dinner.', Icons.psychology_rounded, AppColors.secondary),
    ];
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 8),
              const Text('Notifications', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
          ...items.map((n) => GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(n.$3, color: n.$4, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: adaptiveMutedColor(context, .62), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
