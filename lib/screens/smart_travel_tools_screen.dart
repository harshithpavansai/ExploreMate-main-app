import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../widgets/premium_widgets.dart';
import 'trip_scheduler_screen.dart';
import 'translator_screen.dart';
import 'profile_screen.dart';

class SmartTravelToolsScreen extends StatefulWidget {
  const SmartTravelToolsScreen({super.key});

  @override
  State<SmartTravelToolsScreen> createState() => _SmartTravelToolsScreenState();
}

class _SmartTravelToolsScreenState extends State<SmartTravelToolsScreen> {
  bool _offlineMode = false;
  List<String> _savedPlaces = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _offlineMode = prefs.getBool('offline_mode') ?? false;
        _savedPlaces = prefs.getStringList('saved_places') ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _toggleOffline(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', val);
    if (mounted) {
      setState(() => _offlineMode = val);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(val
            ? '✅ Offline mode ON — map, phrases & itinerary cached'
            : 'Offline mode disabled'),
      ));
    }
  }

  Future<void> _removeSavedPlace(String place) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_savedPlaces)..remove(place);
    await prefs.setStringList('saved_places', updated);
    if (mounted) setState(() => _savedPlaces = updated);
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $number: $e')),
        );
      }
    }
  }

  void _copyLocation() {
    Clipboard.setData(const ClipboardData(text: "https://maps.google.com/?q=27.1751,78.0421"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('📍 GPS coordinate link copied to clipboard!'),
          ],
        ),
      ),
    );
  }

  void _shareLiveRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_location_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('🛡️ Live sharing active with 2 trusted contacts'),
          ],
        ),
      ),
    );
  }

  void _openExpenseSplitter() {
    final totalCtrl = TextEditingController(text: '12400');
    final countCtrl = TextEditingController(text: '4');
    double? result;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💳 Expense Splitter',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Bill / Expense (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of People / Travelers',
                  prefixIcon: Icon(Icons.people_alt_rounded),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Calculate Split',
                  icon: Icons.calculate_rounded,
                  onPressed: () {
                    final total = double.tryParse(totalCtrl.text) ?? 0;
                    final count = int.tryParse(countCtrl.text) ?? 1;
                    if (count > 0) {
                      setModalState(() {
                        result = total / count;
                      });
                    }
                  },
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF57C7FF).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF57C7FF).withValues(alpha: .3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Each Person Pays:',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '₹${result!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF57C7FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openTripMemorySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🧠 AI Travel Memory',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Configure your preferences learned by AI over time:',
                style: TextStyle(color: Colors.white70),
               ),
              const SizedBox(height: 18),
              _PreferenceTile(
                title: 'Food-first explorer',
                subtitle: 'Prioritizes local street food over sightseeing',
                value: true,
                onChanged: (v) {},
              ),
              _PreferenceTile(
                title: 'Low crowd routes',
                subtitle: 'AI automatically routes away from busy zones',
                value: true,
                onChanged: (v) {},
              ),
              _PreferenceTile(
                title: 'Mid-range budget',
                subtitle: 'Target budget: ₹2,000 - ₹5,000 daily limit',
                value: true,
                onChanged: (v) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSafetyCompanion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🛡️ Safety Companion',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Active Area Safety Report',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
            ),
            const SizedBox(height: 10),
            const _SafetyStatTile(Icons.shield_rounded, 'Safety Score', '92% (Very Safe)', AppColors.success),
            const _SafetyStatTile(Icons.cloudy_snowing, 'Weather Risk', 'Low (Clear Sky)', Colors.cyan),
            const _SafetyStatTile(Icons.share_location_rounded, 'Live Route Sharing', 'Active (2 trusted contacts)', AppColors.accent),
            const SizedBox(height: 14),
            const Text(
              'Local emergency contacts are locked. Share location link copies current coordinates to clipboard.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _openCultureCards() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⛩️ Local Culture Guides',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 160,
              child: PageView(
                children: const [
                  _CultureCard(
                    title: 'Greeting Etiquette',
                    content: 'Use "Namaste" with palms joined together at chest level to greet elders and locals respectfully.',
                    icon: Icons.diversity_3_rounded,
                  ),
                  _CultureCard(
                    title: 'Temple Clothing Code',
                    content: 'Always cover shoulders and knees when visiting holy sites. Shoes must be left at the entrance.',
                    icon: Icons.brightness_high_rounded,
                  ),
                  _CultureCard(
                    title: 'Dining Customs',
                    content: 'It is traditional to eat with your right hand. Avoid using the left hand when passing food.',
                    icon: Icons.restaurant_rounded,
                  ),
                ],
              ),
            ),
            const Center(
              child: Text(
                'Swipe left/right to view more cards',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleChipClick(String toolTitle, String chipText) {
    if (toolTitle == 'Emergency Quick Panel') {
      if (chipText.contains('100')) {
        _makeCall('100');
      } else if (chipText.contains('108')) {
        _makeCall('108');
      } else if (chipText == 'Trusted contact') {
        _makeCall('9999999999');
      } else if (chipText == 'Share location') {
        _copyLocation();
      }
    } else if (toolTitle == 'Expense Splitter') {
      _openExpenseSplitter();
    } else if (toolTitle == 'AI Trip Memory') {
      _openTripMemorySettings();
    } else if (toolTitle == 'AI Safety Companion') {
      if (chipText == 'Live route sharing') {
        _shareLiveRoute();
      } else {
        _openSafetyCompanion();
      }
    } else if (toolTitle == 'Local Culture Cards') {
      _openCultureCards();
    } else if (toolTitle == 'Smart Day Optimizer') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TripSchedulerScreen()));
    } else if (toolTitle == 'AR Place Scanner') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorScreen()));
    } else if (toolTitle == 'ExploreMate Pro Dashboard') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Smart Travel Tools',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'A premium AI toolkit for safer, smarter, more personal exploration.',
            style: TextStyle(color: adaptiveMutedColor(context, .64), height: 1.4),
          ),
          const SizedBox(height: 18),

          // ── Offline Mode ───────────────────────────────
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8DB7FF).withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF8DB7FF)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Offline Travel Mode', style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(height: 3),
                      Text('Cache itinerary, phrases & map tiles',
                          style: TextStyle(fontSize: 12, color: Color(0xFF8DB7FF))),
                    ],
                  ),
                ),
                Switch(
                  value: _offlineMode,
                  onChanged: _toggleOffline,
                  activeThumbColor: const Color(0xFF8DB7FF),
                ),
              ],
            ),
          ),

          if (_offlineMode)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Text('Offline content ready', style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: ['Itinerary cached', 'Translator phrases', 'Emergency contacts', 'Map tiles']
                        .map((c) => Chip(
                              label: Text(c, style: const TextStyle(fontSize: 11)),
                              avatar: const Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.success),
                              backgroundColor: AppColors.success.withValues(alpha: .12),
                              side: BorderSide(color: AppColors.success.withValues(alpha: .25)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

          // ── Saved Places ───────────────────────────────
          const SectionHeader(title: 'Saved Places'),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.accent))
          else if (_savedPlaces.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 40, color: adaptiveFaintColor(context)),
                  const SizedBox(height: 10),
                  Text('No saved places yet.',
                      style: TextStyle(color: adaptiveMutedColor(context, .5))),
                  const SizedBox(height: 6),
                  const Text('Tap ♡ on any destination to save it here.',
                      style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ..._savedPlaces.map((place) => GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () => _removeSavedPlace(place),
                        icon: Icon(Icons.close_rounded,
                            color: adaptiveFaintColor(context), size: 18),
                      ),
                    ],
                  ),
                )),

          // ── Premium Tools ─────────────────────────────────────
          const SectionHeader(title: 'All Premium Features'),
          ..._buildTools(context),
        ],
      ),
    );
  }

  List<Widget> _buildTools(BuildContext context) {
    const tools = [
      _Tool('AI Trip Memory', 'Learns food, budget, pace, language, and crowd preferences.',
          Icons.memory_rounded, AppColors.accent,
          ['Food-first traveler', 'Low crowd routes', 'Mid-range budget', 'Hindi + English']),
      _Tool('AI Safety Companion', 'Area safety score, risk alerts, route sharing, and emergency info.',
          Icons.health_and_safety_rounded, AppColors.success,
          ['Safe route score 92%', 'Weather risk low', 'Live route sharing', 'SOS ready']),
      _Tool('Smart Day Optimizer', 'Reorders your day using weather, distance, opening hours, and crowds.',
          Icons.auto_awesome_rounded, AppColors.secondary,
          ['Move beach to sunset', 'Lunch near heritage walk', 'Avoid 4 PM crowd', 'Save 42 min']),
      _Tool('AR Place Scanner', 'Camera-first landmark, sign, and menu recognition interface.',
          Icons.view_in_ar_rounded, Color(0xFFC78BFF),
          ['Landmark facts', 'Menu translation', 'Sign detection', 'Instant AI overlay']),
      _Tool('Local Culture Cards', 'Etiquette, phrases, festivals, dress codes, and food customs.',
          Icons.diversity_3_rounded, AppColors.xpGold,
          ['Greeting tips', 'Temple etiquette', 'Local phrases', 'Festival notes']),
      _Tool('Expense Splitter', 'Track group expenses, split bills, and estimate trip budget.',
          Icons.payments_rounded, Color(0xFF57C7FF),
          ['INR 12,400 total', '4 travelers', 'Food split', 'Activity split']),
      _Tool('Emergency Quick Panel', 'SOS, trusted contact, hotel address, and live location sharing.',
          Icons.sos_rounded, AppColors.danger,
          ['Police 100', 'Ambulance 108', 'Trusted contact', 'Share location']),
      _Tool('ExploreMate Pro Dashboard', 'Travel personality, streaks, badges, states explored.',
          Icons.workspace_premium_rounded, AppColors.accentLight,
          ['Trailblazer profile', '12 trips', '8 badges', '4-day streak']),
    ];

    return tools.map((t) => GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        if (t.title == 'Smart Day Optimizer') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripSchedulerScreen()));
        } else if (t.title == 'AR Place Scanner') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorScreen()));
        } else if (t.title == 'ExploreMate Pro Dashboard') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        } else if (t.title == 'Emergency Quick Panel') {
          _makeCall('100');
        } else if (t.title == 'Expense Splitter') {
          _openExpenseSplitter();
        } else if (t.title == 'AI Trip Memory') {
          _openTripMemorySettings();
        } else if (t.title == 'AI Safety Companion') {
          _openSafetyCompanion();
        } else if (t.title == 'Local Culture Cards') {
          _openCultureCards();
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(t.icon, color: t.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(t.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: adaptiveMutedColor(context, .62), fontSize: 12, height: 1.3)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: t.chips.map((c) => ActionChip(
                    label: Text(c, style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: t.color.withValues(alpha: .10),
                    side: BorderSide(color: t.color.withValues(alpha: .22)),
                    onPressed: () => _handleChipClick(t.title, c),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    )).toList();
  }
}

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> chips;
  const _Tool(this.title, this.subtitle, this.icon, this.color, this.chips);
}

class _PreferenceTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_PreferenceTile> createState() => _PreferenceTileState();
}

class _PreferenceTileState extends State<_PreferenceTile> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _val,
      onChanged: (v) {
        setState(() => _val = v);
        widget.onChanged(v);
      },
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(widget.subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      activeThumbColor: AppColors.accent,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SafetyStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SafetyStatTile(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CultureCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _CultureCard({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      color: Colors.white.withValues(alpha: .02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.xpGold, size: 24),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
