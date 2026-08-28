import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/premium_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
class TripSchedulerScreen extends StatefulWidget {
  const TripSchedulerScreen({super.key});

  @override
  State<TripSchedulerScreen> createState() => _TripSchedulerScreenState();
}

class _TripSchedulerScreenState extends State<TripSchedulerScreen> {
  final days = ['Day 1', 'Day 2', 'Day 3', 'Day 4'];
  int selectedDay = 0;
  List<dynamic> tasks = ['Sunrise viewpoint', 'Cafe breakfast', 'Heritage walk', 'Hidden beach', 'Audio tour'];

  final _destController = TextEditingController(text: 'Jaipur');
  final _budgetController = TextEditingController(text: '12400');
  bool _isGenerating = false;

  @override
  void dispose() {
    _destController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);
    final budget = int.tryParse(_budgetController.text) ?? 10000;
    
    // Call the Gemini backend
    final newTasks = await ApiService().generateItinerary(_destController.text, 4, budget);
    
    if (mounted) {
      setState(() {
        if (newTasks.isNotEmpty) {
          tasks = newTasks;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate trip. Please check API key.')));
        }
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Scheduler', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'Day-wise AI planner with budget and export controls.',
            style: TextStyle(color: adaptiveMutedColor(context, .62)),
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 28),
                    SizedBox(width: 12),
                    Expanded(child: Text('AI Auto-Planner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _destController,
                        decoration: const InputDecoration(labelText: 'Destination (e.g. Goa)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Budget (₹)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: _isGenerating ? 'Generating...' : 'Generate New Plan',
                    icon: Icons.memory_rounded,
                    onPressed: _isGenerating ? () {} : _generatePlan,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(selected: selectedDay == i, label: Text(days[i]), onSelected: (_) => setState(() => selectedDay = i)),
              ),
            ),
          ),
          const SectionHeader(title: 'Drag & Drop Itinerary'),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) => setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = tasks.removeAt(oldIndex);
              tasks.insert(newIndex, item);
            }),
            itemBuilder: (_, i) => GlassCard(
              key: ValueKey(tasks[i]),
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accent.withValues(alpha: .18),
                    child: Text('${i + 1}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tasks[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(Icons.drag_handle_rounded, color: adaptiveFaintColor(context)),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Budget Tracker'),
          GlassCard(
            child: Column(
              children: [
                _Budget('Stay', (int.parse(_budgetController.text.isEmpty ? '10000' : _budgetController.text) * 0.4).round(), .40, AppColors.accent),
                _Budget('Food', (int.parse(_budgetController.text.isEmpty ? '10000' : _budgetController.text) * 0.3).round(), .30, AppColors.secondary),
                _Budget('Activities', (int.parse(_budgetController.text.isEmpty ? '10000' : _budgetController.text) * 0.3).round(), .30, AppColors.xpGold),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Save Plan',
                        icon: Icons.bookmark_rounded,
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving to server...')));
                          try {
                            final token = await ApiService().getToken();
                            if (token != null) {
                              final response = await http.post(
                                Uri.parse('${ApiConfig.activeBaseUrl}/trips'),
                                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                                body: jsonEncode({
                                  'customDestinationName': '${_destController.text} discovery plan',
                                  'startDate': DateTime.now().toIso8601String(),
                                  'endDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
                                  'budget': int.tryParse(_budgetController.text) ?? 10000,
                                  'itinerary': tasks,
                                }),
                              );
                              if ((response.statusCode == 200 || response.statusCode == 201) && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan saved to PostgreSQL!')));
                                Provider.of<AppState>(context, listen: false).incrementMissionProgress('trips');
                              }
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: GradientButton(label: 'Export', icon: Icons.picture_as_pdf_rounded, gradient: AppColors.cyanGradient, onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export coming soon!')));
                    })),
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

class _Budget extends StatelessWidget {
  final String label;
  final int amount;
  final double value;
  final Color color;
  const _Budget(this.label, this.amount, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'INR $amount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: color,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white12
                  : AppColors.textMuted.withValues(alpha: .18),
            ),
          ),
        ],
      ),
    );
  }
}
