import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/premium_widgets.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;

  final pages = const [
    ('AI-powered exploration', 'Turn every city into a living quest with routes, narration, food moods, and hidden gems.'),
    ('Travel like a local', 'ExploreMate blends weather, time, crowd energy, and your preferences into live recommendations.'),
    ('Play the journey', 'Earn XP, complete missions, unlock badges, and make every trip feel cinematic.'),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/mountain_bg.png', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.surface],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.explore_rounded, color: AppColors.accent, size: 32),
                      const SizedBox(width: 10),
                      const Text('ExploreMate', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      TextButton(onPressed: _finish, child: const Text('Skip')),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: pages.length,
                      onPageChanged: (v) => setState(() => index = v),
                      itemBuilder: (_, i) => Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pages[i].$1,
                            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, height: 1.05),
                          ),
                          const SizedBox(height: 14),
                          Text(pages[i].$2, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      ...List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          width: index == i ? 32 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: index == i ? AppColors.accent : Colors.white30,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const Spacer(),
                      GradientButton(
                        label: index == pages.length - 1 ? 'Start' : 'Next',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (index == pages.length - 1) {
                            _finish();
                          } else {
                            controller.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}
