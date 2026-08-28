import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../app_colors.dart';
import '../widgets/premium_widgets.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  String from = 'English';
  String to = 'Hindi';
  final TextEditingController _controller = TextEditingController();
  String _translatedText = '';
  bool _isLoading = false;
  final FlutterTts _tts = FlutterTts();

  static const languages = [
    'Arabic', 'Bengali', 'Chinese Simplified', 'Chinese Traditional',
    'Dutch', 'English', 'French', 'German', 'Greek', 'Gujarati',
    'Hebrew', 'Hindi', 'Indonesian', 'Italian', 'Japanese', 'Kannada',
    'Korean', 'Malay', 'Malayalam', 'Marathi', 'Nepali', 'Odia',
    'Persian', 'Polish', 'Portuguese', 'Punjabi', 'Russian', 'Sanskrit',
    'Spanish', 'Swahili', 'Tamil', 'Telugu', 'Thai', 'Turkish',
    'Ukrainian', 'Urdu', 'Vietnamese',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _translate() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() { _isLoading = true; _translatedText = ''; });
    
    try {
      final result = await ApiService().translateText(_controller.text.trim(), to);
      if (mounted) {
        if (result.contains('failed') || result.contains('unavailable') || result.contains('Error')) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(result)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
          setState(() { _isLoading = false; });
        } else {
          setState(() { _isLoading = false; _translatedText = result; });
          Provider.of<AppState>(context, listen: false).incrementMissionProgress('translate');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.redAccent,
        ));
        setState(() { _isLoading = false; });
      }
    }
  }



  Future<void> _speakTranslation() async {
    if (_translatedText.isEmpty) return;
    await _tts.setLanguage('en-IN');
    await _tts.speak(_translatedText);
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Translator', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Text, voice & camera translation for travelers.',
              style: TextStyle(color: adaptiveMutedColor(context, .62))),
          const SizedBox(height: 18),

          // ── Language Selector ─────────────────────────────────
          GlassCard(
            child: Row(
              children: [
                Expanded(child: _LanguageDrop(value: from, list: languages, onChanged: (v) => setState(() => from = v))),
                IconButton(
                  tooltip: 'Swap',
                  onPressed: () => setState(() { final t = from; from = to; to = t; }),
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.accent),
                ),
                Expanded(child: _LanguageDrop(value: to, list: languages, onChanged: (v) => setState(() => to = v))),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Input ─────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type or paste text to translate',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Where is the nearest metro station?',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: _isLoading ? 'Translating...' : 'Translate',
                        icon: Icons.translate_rounded,
                        onPressed: _isLoading ? () {} : _translate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Speak result',
                      onPressed: _translatedText.isNotEmpty ? _speakTranslation : null,
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Translation Output ────────────────────────────────
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(color: AppColors.accent),
            )),

          if (_translatedText.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$to translation',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(_translatedText,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.4)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Speak',
                        onPressed: _speakTranslation,
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Copy',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],





          // ── Quick Phrases ─────────────────────────────────────
          const SectionHeader(title: 'Travel Quick Phrases'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              'Where is the toilet?', 'How much does it cost?',
              'I am vegetarian', 'Call a doctor', 'I am lost', 'Thank you',
              'One ticket please', 'Do you speak English?',
            ].map((phrase) => ActionChip(
              label: Text(phrase, style: const TextStyle(fontSize: 12)),
              onPressed: () { _controller.text = phrase; _translate(); },
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LanguageDrop extends StatelessWidget {
  final String value;
  final List<String> list;
  final ValueChanged<String> onChanged;
  const _LanguageDrop({required this.value, required this.list, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: list.contains(value) ? value : list.first,
        isExpanded: true,
        dropdownColor: AppColors.cardBg,
        items: list.map((l) => DropdownMenuItem(
          value: l, child: Text(l, maxLines: 1, overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}




