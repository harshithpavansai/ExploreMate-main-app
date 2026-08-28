import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_colors.dart';

Color adaptiveMutedColor(BuildContext context, [double opacity = .68]) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: opacity)
      : AppColors.textMid.withValues(alpha: opacity + .12 > 1 ? 1 : opacity + .12);
}

Color adaptiveFaintColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: .38)
      : AppColors.textMuted;
}

class CinematicScaffold extends StatelessWidget {
  final Widget child;
  final bool scroll;
  final EdgeInsets padding;

  const CinematicScaffold({
    super.key,
    required this.child,
    this.scroll = false,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 100),
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : AppColors.lightSurface,
      ),
      child: Stack(
        children: [
          if (Theme.of(context).brightness == Brightness.dark) ...[
            const Positioned.fill(child: _AnimatedAurora()),
            Positioned(
              top: -120,
              right: -80,
              child: _GlowBlob(color: AppColors.accent.withValues(alpha: 0.18), size: 260),
            ),
            Positioned(
              bottom: 120,
              left: -120,
              child: _GlowBlob(color: AppColors.secondary.withValues(alpha: 0.13), size: 280),
            ),
          ],
          SafeArea(
            child: scroll
                ? ListView(padding: padding, children: [child])
                : Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
    return Scaffold(body: body);
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 24,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? (dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.82)),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
            ),
            boxShadow: [
              BoxShadow(
                color: dark ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: card);
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Gradient gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppColors.sunriseGradient,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

class AnimatedSearchBar extends StatefulWidget {
  final String hint;
  final VoidCallback? onMicTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AnimatedSearchBar({
    super.key,
    this.hint = 'Ask AI where to go next',
    this.onMicTap,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.10 : 0.96),
        borderRadius: BorderRadius.circular(focused ? 22 : 18),
        border: Border.all(color: focused ? AppColors.accent : Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: focused ? 0.20 : 0.08),
            blurRadius: focused ? 26 : 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => focused = v),
        child: TextField(
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textDark,
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            icon: const Icon(Icons.search_rounded, color: AppColors.accent),
            hintText: widget.hint,
            border: InputBorder.none,
            suffixIcon: IconButton(
              tooltip: 'Voice search',
              onPressed: widget.onMicTap,
              icon: const Icon(Icons.mic_rounded, color: AppColors.secondary),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class DestinationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final double width;
  final VoidCallback? onTap;

  const DestinationCard({super.key, required this.item, this.width = 260, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 14))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: item['name'] as String,
              child: Image.network(
                item['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.cardBg),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE807111F)],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _Pill(icon: Icons.star_rounded, label: item['rating'] as String),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(item['place'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ((item['tags'] as List<String>).take(3))
                        .map((t) => _Pill(label: t, dense: true))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.sunriseGradient),
            child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('32 C, clear sky', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'AI suggests sunset viewpoints and mint coolers nearby.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: adaptiveMutedColor(context, .62), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.near_me_rounded, color: AppColors.accent),
        ],
      ),
    );
  }
}

class XpProgressWidget extends StatelessWidget {
  final int xp;
  final int level;

  const XpProgressWidget({super.key, required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    final progress = ((xp - (level - 1) * 500) / 500).clamp(0.0, 1.0);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.xpGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Level $level Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '$xp XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(AppColors.xpGold),
            ),
          ),
        ],
      ),
    );
  }
}

class Waveform extends StatefulWidget {
  final bool active;
  const Waveform({super.key, required this.active});

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
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
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(28, (i) {
          final wave = widget.active ? (math.sin(controller.value * math.pi * 2 + i * .55) + 1) / 2 : .18;
          return Container(
            width: 4,
            height: 10 + wave * 38,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: AppColors.cyanGradient,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}

class SkeletonLine extends StatefulWidget {
  final double width;
  const SkeletonLine({super.key, required this.width});

  @override
  State<SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<SkeletonLine> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
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
      builder: (_, __) => Container(
        width: widget.width,
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [Colors.white10, Colors.white.withValues(alpha: .22), Colors.white10],
            stops: const [0, .5, 1],
            begin: Alignment(-1 + controller.value * 2, 0),
            end: Alignment(controller.value * 2, 0),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool dense;

  const _Pill({required this.label, this.icon, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 5 : 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.xpGold, size: 14),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _AnimatedAurora extends StatefulWidget {
  const _AnimatedAurora();

  @override
  State<_AnimatedAurora> createState() => _AnimatedAuroraState();
}

class _AnimatedAuroraState extends State<_AnimatedAurora> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
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
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.7 + controller.value * 1.3, -0.85 + controller.value * .45),
            radius: 1.15,
            colors: [
              AppColors.primary.withValues(alpha: 0.60),
              AppColors.surface,
              AppColors.primaryDeep,
            ],
          ),
        ),
      ),
    );
  }
}
