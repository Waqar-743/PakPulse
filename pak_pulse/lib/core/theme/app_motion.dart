import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration xslow = Duration(milliseconds: 1000);

  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;

  /// iOS-grade decel spring — the primary easing for premium entrance motion.
  static const Curve spring = Cubic(0.32, 0.72, 0.0, 1.0);

  /// Soft settle — for ambient, looping, and large-surface transitions.
  static const Curve soft = Cubic(0.22, 0.61, 0.36, 1.0);
}
