import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/premium_widgets.dart';
import '../services/api_service.dart';

class AiAssistScreen extends StatefulWidget {
  const AiAssistScreen({super.key});

  @override
  State<AiAssistScreen> createState() => _AiAssistScreenState();
}

class _AiAssistScreenState extends State<AiAssistScreen> {
  final controller = TextEditingController();

  final List<(bool, String)> messages = [
    (true, 'I am online. I can plan routes, explain places, translate signs, and match food to your mood.'),
    (false, 'Best hidden gems in Vizag?'),
    (true, 'Try Yarada Beach at sunset, Bheemili Dutch Ruins before lunch, and Borra Caves as a full-day story route.'),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      child: Column(
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
                  'ExploreMate AI',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.circle,
                color: AppColors.accent,
                size: 10,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
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
                        maxWidth: MediaQuery.of(context).size.width * .72,
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'Start audio tour',
                'Add to schedule',
                'Food nearby',
                'Weather today'
              ]
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(s),
                        onPressed: () => _send(s),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add((false, text));
      messages.add((true, 'Thinking...'));
      controller.clear();
    });

    final reply = await ApiService().chatWithGuide(text, 'User is looking for travel advice.');

    if (mounted) {
      setState(() {
        messages.removeLast(); // Remove 'Thinking...'
        messages.add((true, reply));
      });
    }
  }
}
