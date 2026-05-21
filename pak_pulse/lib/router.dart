import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/agent_trace/agent_trace_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/crisis_detail/crisis_detail_screen.dart';
import 'features/history/history_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/splash_screen.dart';

CustomTransitionPage<T> _sharedAxisPage<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animation, secondary, c) => SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondary,
      transitionType: SharedAxisTransitionType.horizontal,
      child: c,
    ),
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      pageBuilder: (_, __) => _sharedAxisPage(const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (_, __) => _sharedAxisPage(const OnboardingScreen()),
    ),
    // The persistent app shell — owns the fixed bottom navigation and hosts
    // Home / Signals / Actions / Settings in an IndexedStack.
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (_, __) => _sharedAxisPage(const MainShell()),
    ),
    GoRoute(
      path: '/crisis/:id',
      name: 'crisis',
      pageBuilder: (_, state) => _sharedAxisPage(
        CrisisDetailScreen(crisisId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/trace/:id',
      name: 'trace',
      pageBuilder: (_, state) => _sharedAxisPage(
        AgentTraceScreen(
          traceId: state.pathParameters['id'] ?? '',
          liveSignalText: state.uri.queryParameters['signal'],
        ),
      ),
    ),
    // Signals / Actions / Settings are tabs inside the persistent shell, not
    // standalone pages. The routes are preserved for deep-link compatibility
    // and resolve into the shell so the bottom navigation is never lost.
    GoRoute(
      path: '/signals',
      name: 'signals',
      redirect: (_, __) => '/home',
    ),
    GoRoute(
      path: '/actions',
      name: 'actions',
      redirect: (_, __) => '/home',
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      redirect: (_, __) => '/home',
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      pageBuilder: (_, __) => _sharedAxisPage(const HistoryScreen()),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      pageBuilder: (_, __) => _sharedAxisPage(const ChatScreen()),
    ),
  ],
);
