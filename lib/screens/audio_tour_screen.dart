import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../app_colors.dart';
import '../models/demo_data.dart';
import '../services/api_service.dart';
import '../widgets/premium_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AudioTourScreen extends StatefulWidget {
  final String? placeName;
  const AudioTourScreen({super.key, this.placeName});

  @override
  State<AudioTourScreen> createState() => _AudioTourScreenState();
}

class _AudioTourScreenState extends State<AudioTourScreen> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _questionCtrl = TextEditingController();

  bool _playing = false;
  bool _loadingNarration = false;
  double _progress = 0;
  String _narration = '';
  String _currentPlace = 'Gateway of India';
  double _speechRate = 0.5; // FlutterTts normal rate is typically 0.5

  final List<Map<String, String>> _nearbyTours = [
    {'name': 'Borra Caves', 'place': 'Vizag, Andhra Pradesh'},
    {'name': 'Charminar', 'place': 'Hyderabad, Telangana'},
    {'name': 'Old Harbor Walk', 'place': 'Kochi, Kerala'},
    {'name': 'Amber Fort', 'place': 'Jaipur, Rajasthan'},
  ];

  @override
  void initState() {
    super.initState();
    _currentPlace = widget.placeName ?? 'Gateway of India';
    _setupPlayer();
    _loadNarration();
  }

  Future<void> _setupPlayer() async {
    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() { _playing = false; _progress = 1.0; });
        Provider.of<AppState>(context, listen: false).incrementMissionProgress('audio');
      }
    });
    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _playing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('TTS Error: $msg')));
      }
    });
    _tts.setProgressHandler((text, start, end, word) {
      if (mounted && text.isNotEmpty) {
        setState(() => _progress = end / text.length);
      }
    });
  }

  Future<void> _loadNarration({String? question}) async {
    setState(() => _loadingNarration = true);
    final text = await ApiService().getAudioNarration(_currentPlace, question: question);
    if (mounted) {
      setState(() {
        _narration = text.isNotEmpty
            ? text
            : 'This magnificent place holds centuries of history. Stand here and feel the stories of countless travelers who passed through before you. The architecture, the light, and the sounds around you are all part of its living legacy.';
        _loadingNarration = false;
        _progress = 0;
        _playing = false;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _tts.stop();
      setState(() => _playing = false);
    } else {
      if (_narration.isEmpty) await _loadNarration();
      
      setState(() { _playing = true; _progress = 0; });
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(_speechRate);
      final result = await _tts.speak(_narration);
      if (result != 1) {
        setState(() => _playing = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to play audio')));
      }
    }
  }

  Future<void> _askQuestion() async {
    final q = _questionCtrl.text.trim();
    if (q.isEmpty) return;
    _questionCtrl.clear();
    await _tts.stop();
    await _loadNarration(question: q);
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(_narration);
  }

  Future<void> _switchTour(String name) async {
    await _tts.stop();
    setState(() {
      _currentPlace = name;
      _narration = '';
      _progress = 0;
      _playing = false;
    });
    await _loadNarration();
  }

  @override
  void dispose() {
    _tts.stop();
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Audio Tour', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'AI narration, voice answers, and contextual tour guide.',
            style: TextStyle(color: adaptiveMutedColor(context, .62)),
          ),
          const SizedBox(height: 18),

          // ── Now Playing Card ─────────────────────────────────────
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SizedBox(
                  height: 240,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Image.network(DemoImages.fort, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppColors.cardBg)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: .82)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.spatial_audio_off_rounded, color: Colors.white, size: 13),
                              SizedBox(width: 4),
                              Text('AI GUIDE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Text(
                          _currentPlace,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Waveform(active: _playing),
                      const SizedBox(height: 8),
                      Slider(
                        value: _progress,
                        onChanged: (v) => setState(() => _progress = v),
                        activeColor: AppColors.accent,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Slower',
                            onPressed: () async {
                              setState(() => _speechRate = (_speechRate - 0.1).clamp(0.1, 1.0));
                              await _tts.setSpeechRate(_speechRate);
                            },
                            icon: const Icon(Icons.slow_motion_video_rounded),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primaryDeep,
                              minimumSize: const Size(60, 60),
                            ),
                            iconSize: 36,
                            onPressed: _loadingNarration ? null : _togglePlay,
                            icon: _loadingNarration
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.primaryDeep),
                                  )
                                : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: 'Refresh narration',
                            onPressed: _loadingNarration ? null : () => _loadNarration(),
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── AI Narration Text ────────────────────────────────────
          const SectionHeader(title: 'AI Narration'),
          GlassCard(
            child: _loadingNarration
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          ),
                          SizedBox(width: 12),
                          Text('Generating narration...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                : Text(
                    _narration.isEmpty
                        ? 'Tap play to start the AI narration.'
                        : _narration,
                    style: TextStyle(height: 1.6, color: adaptiveMutedColor(context, .75)),
                  ),
          ),

          // ── Ask the Guide ────────────────────────────────────────
          const SectionHeader(title: 'Ask the Guide'),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. When was this built?',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _askQuestion(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _askQuestion,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),

          // ── Speech Settings ──────────────────────────────────────
          const SectionHeader(title: 'Voice Settings'),
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    const Text('Playback Speed', style: TextStyle(fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Slider(
                        value: _speechRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: _speechRate.toStringAsFixed(1),
                        activeColor: AppColors.accent,
                        onChanged: (v) async {
                          setState(() => _speechRate = v);
                          await _tts.setSpeechRate(v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── More Tours ───────────────────────────────────────────
          const SectionHeader(title: 'More Tours Nearby'),
          ..._nearbyTours.map(
            (t) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['name']!, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(t['place']!,
                            style: TextStyle(color: adaptiveMutedColor(context, .56), fontSize: 11)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _switchTour(t['name']!),
                    child: const Text('Start'),
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
