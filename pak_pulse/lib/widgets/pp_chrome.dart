import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

// ── PPOrbs ────────────────────────────────────────────────────────────────────
/// Two ambient background gradient orbs. Wrap your SafeArea inside a Stack
/// and place PPOrbs as the first child.
class PPOrbs extends StatelessWidget {
  const PPOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.critical.withOpacity(0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.signalBlue.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── PPEyebrow ─────────────────────────────────────────────────────────────────
/// Mono uppercase eyebrow label — small, letter-spaced, tertiary color.
class PPEyebrow extends StatelessWidget {
  final String text;
  final Color? color;

  const PPEyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 9.5,
        letterSpacing: 1.4,
        color: color ?? AppColors.textTertiary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── PPBezel ───────────────────────────────────────────────────────────────────
/// Double-bezel hero card wrapper.
class PPBezel extends StatelessWidget {
  final Widget child;
  final Color? gradientStart;
  final EdgeInsetsGeometry? padding;

  const PPBezel({
    super.key,
    required this.child,
    this.gradientStart,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            (gradientStart ?? AppColors.textPrimary).withOpacity(0.08),
            (gradientStart ?? AppColors.textPrimary).withOpacity(0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: child,
      ),
    );
  }
}

// ── PPSectionHeader ───────────────────────────────────────────────────────────
/// Kicker + title section header.
class PPSectionHeader extends StatelessWidget {
  final String kicker;
  final String title;
  final Widget? trailing;

  const PPSectionHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PPEyebrow(kicker),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── PPScanLine ────────────────────────────────────────────────────────────────
/// Animated horizontal scan line with shimmer.
class PPScanLine extends StatelessWidget {
  final Color? color;

  const PPScanLine({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            (color ?? AppColors.critical).withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 2200.ms,
          color: (color ?? AppColors.critical).withOpacity(0.8),
        );
  }
}

// ── PPNavBar ──────────────────────────────────────────────────────────────────
/// Floating glass bottom nav bar with 4 destinations.
class PPNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTab;

  const PPNavBar({
    super.key,
    required this.currentIndex,
    required this.onTab,
  });

  static const _labels = ['HOME', 'SIGNALS', 'ACTIONS', 'SETTINGS'];
  static const _icons = [
    Icons.map_outlined,
    Icons.graphic_eq_outlined,
    Icons.bolt_outlined,
    Icons.tune_outlined,
  ];
  static const _activeIcons = [
    Icons.map,
    Icons.graphic_eq,
    Icons.bolt,
    Icons.tune,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (i) {
          final active = i == currentIndex;
          return _NavItem(
            label: _labels[i],
            icon: _icons[i],
            activeIcon: _activeIcons[i],
            isActive: active,
            onTap: () => onTab(i),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicator line on top of active tab
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 20 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.critical,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? AppColors.critical : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                letterSpacing: 0.8,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.critical : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
