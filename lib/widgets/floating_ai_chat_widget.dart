import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../screens/ai_assist_screen.dart';
import '../screens/audio_tour_screen.dart';
import '../screens/trip_scheduler_screen.dart';
import '../screens/food_screen.dart';
import '../widgets/premium_widgets.dart';

class FloatingAiChatWidget extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onOpenFull;

  const FloatingAiChatWidget({
    super.key,
    this.width = 360,
    this.height = 470,
    this.onOpenFull,
  });

  @override
  State<FloatingAiChatWidget> createState() => _FloatingAiChatWidgetState();
}

class _FloatingAiChatWidgetState extends State<FloatingAiChatWidget> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  final List<(bool isAi, String text)> messages = [
    (
      true,
      'I am online. I can plan routes, explain places, translate signs, and match food to your mood.'
    ),
    (false, 'Try a calm route with sunset spots?'),
    (
      true,
      'Try Yarada Beach at sunset, Dutch Ruins before lunch, and Borra Caves as a full-day story.'
    ),
  ];

  bool isOpen = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => isOpen = !isOpen);
    if (isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    }
  }

  void _jumpToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      messages.add((false, trimmed));
      messages.add((
        true,
        'I can turn that into a live plan. I will balance distance, weather, budget, and crowd level.'
      ));
      controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Backdrop bubble
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          bottom: 78,
          right: 0,
          left: null,
          width: widget.width,
          height: isOpen ? widget.height : 0,
          child: isOpen
              ? GestureDetector(
                  onTap: () {},
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: AppColors.primaryDeep.withValues(alpha: .72),
                        border: Border.all(color: Colors.white.withValues(alpha: .16)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .28),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _Header(onClose: _toggle),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              itemCount: messages.length,
                              itemBuilder: (_, i) {
                                final (isAi, text) = messages[i];
                                return Align(
                                  alignment: isAi
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: GlassCard(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    color: isAi
                                        ? Colors.white.withValues(alpha: .08)
                                        : AppColors.accent.withValues(alpha: .22),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            widget.width - 60,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          text,
                                          style: const TextStyle(height: 1.25),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          _QuickActions(onOpenFull: widget.onOpenFull),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        hintText: 'Ask AI about your trip',
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: _send,
                                    ),
                                  ),
                                  IconButton.filled(
                                    onPressed: () => _send(controller.text),
                                    icon: const Icon(Icons.send_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Floating toggle button
        GestureDetector(
          onTap: _toggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: SizedBox(
              key: ValueKey(isOpen),
              width: 64,
              height: 64,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.cyanGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .34),
                    width: 1.2,
                  ),
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
                    Icon(
                      isOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
                      color: AppColors.primaryDeep,
                      size: isOpen ? 28 : 31,
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
                          border: Border.all(
                            color: AppColors.primaryDeep,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'ExploreMate AI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback? onOpenFull;

  const _QuickActions({this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
        scrollDirection: Axis.horizontal,
        children: [
          _ActionChip(
            label: 'Start audio tour',
            icon: Icons.graphic_eq_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AudioTourScreen()),
            ),
          ),
          _ActionChip(
            label: 'Add to schedule',
            icon: Icons.calendar_month_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripSchedulerScreen()),
            ),
          ),
          _ActionChip(
            label: 'Food nearby',
            icon: Icons.restaurant_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoodScreen()),
            ),
          ),
          _ActionChip(
            label: 'Open full AI',
            icon: Icons.open_in_full_rounded,
            onTap: onOpenFull ??
                () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiAssistScreen()),
                    ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        avatar: Icon(icon, size: 18),
        onPressed: onTap,
      ),
    );
  }
}
