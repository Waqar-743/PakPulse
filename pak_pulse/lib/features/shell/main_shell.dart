import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../providers.dart';
import '../../widgets/pp_chrome.dart';
import '../action_console/action_console_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../signal_inbox/signal_inbox_screen.dart';

/// The permanent app shell.
///
/// A single root [Scaffold] owns the [BottomNavigationBar] (rendered as the
/// branded [PPNavBar]) and an [IndexedStack] of the four primary screens.
/// Because the nav bar lives here — not inside any screen — it can never
/// disappear, shift, or rebuild when switching tabs, and the [IndexedStack]
/// keeps every tab's scroll position and state alive between switches.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  // Built once, kept alive by the IndexedStack for the app's lifetime.
  static const List<Widget> _tabs = [
    HomeScreen(),
    SignalInboxScreen(),
    ActionConsoleScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    return PopScope(
      // Android back from a sub-tab returns to Home rather than exiting.
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(navIndexProvider.notifier).state = 0;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundBase,
        body: IndexedStack(index: index, children: _tabs),
        bottomNavigationBar: SafeArea(
          top: false,
          child: PPNavBar(
            currentIndex: index,
            onTab: (i) {
              if (i == index) return;
              Haptics.light();
              ref.read(navIndexProvider.notifier).state = i;
            },
          ),
        ),
      ),
    );
  }
}
