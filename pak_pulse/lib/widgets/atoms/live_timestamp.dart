import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';

class LiveTimestamp extends StatefulWidget {
  final DateTime timestamp;
  final double? fontSize;
  final Color? color;

  const LiveTimestamp({
    super.key,
    required this.timestamp,
    this.fontSize,
    this.color,
  });

  @override
  State<LiveTimestamp> createState() => _LiveTimestampState();
}

class _LiveTimestampState extends State<LiveTimestamp> {
  late Timer _timer;
  late String _display;

  @override
  void initState() {
    super.initState();
    _display = AppDateUtils.timeAgo(widget.timestamp);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _display = AppDateUtils.timeAgo(widget.timestamp));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _display,
      style: GoogleFonts.jetBrainsMono(
        fontSize: widget.fontSize ?? 11,
        color: widget.color ?? AppColors.textTertiary,
      ),
    );
  }
}
