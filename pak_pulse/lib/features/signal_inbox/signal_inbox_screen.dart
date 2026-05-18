import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis_signal.dart';
import '../../providers.dart';
import '../../widgets/atoms/mono_text.dart';
import '../../widgets/atoms/severity_chip.dart';
import '../../widgets/molecules/signal_card.dart';
import '../../widgets/pp_chrome.dart';

class SignalInboxScreen extends ConsumerStatefulWidget {
  const SignalInboxScreen({super.key});

  @override
  ConsumerState<SignalInboxScreen> createState() =>
      _SignalInboxScreenState();
}

class _SignalInboxScreenState
    extends ConsumerState<SignalInboxScreen> {
  final _searchCtrl = TextEditingController();
  SignalSource? _sourceFilter;
  SignalLanguage? _langFilter;
  String _query = '';
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CrisisSignal> _filtered(List<CrisisSignal> all) {
    return all.where((s) {
      if (_sourceFilter != null && s.source != _sourceFilter)
        return false;
      if (_langFilter != null && s.language != _langFilter)
        return false;
      if (_query.isNotEmpty &&
          !s.rawText
              .toLowerCase()
              .contains(_query.toLowerCase()) &&
          !(s.sector
                  ?.toLowerCase()
                  .contains(_query.toLowerCase()) ??
              false)) {
        return false;
      }
      return true;
    }).toList();
  }

  Color _langColor(SignalLanguage lang) {
    switch (lang) {
      case SignalLanguage.english:
        return AppColors.low;
      case SignalLanguage.romanUrdu:
        return AppColors.high;
      case SignalLanguage.urdu:
        return AppColors.signalBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSignals = ref.watch(signalListProvider);
    final filtered = _filtered(allSignals);

    final now = DateTime.now();
    final lastHour = filtered
        .where(
            (s) => now.difference(s.timestamp).inHours < 1)
        .toList();
    final earlier = filtered
        .where(
            (s) => now.difference(s.timestamp).inHours >= 1)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                _InboxHeader(signalCount: allSignals.length),
                // ── Search bar ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.borderSubtle),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: AppTypography.bodyMedium
                          .copyWith(
                              color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search signals…',
                        hintStyle: AppTypography.bodyMedium,
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.textTertiary,
                            size: 18),
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ).animate(delay: 50.ms).fadeIn(
                    duration: 500.ms,
                    curve: Cubic(0.32, 0.72, 0, 1)),
                // ── Filter chips ─────────────────────────────
                SizedBox(
                  height: 48,
                  child: _FilterRow(
                    sourceFilter: _sourceFilter,
                    langFilter: _langFilter,
                    onSourceChanged: (v) =>
                        setState(() => _sourceFilter = v),
                    onLangChanged: (v) =>
                        setState(() => _langFilter = v),
                  ),
                ).animate(delay: 100.ms).fadeIn(
                    duration: 500.ms,
                    curve: Cubic(0.32, 0.72, 0, 1)),
                // ── Signal list ──────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState()
                      : ListView(
                          padding: const EdgeInsets.only(
                              bottom: 16),
                          children: [
                            if (lastHour.isNotEmpty) ...[
                              _StickyGroupHeader(
                                  label: 'LAST HOUR'),
                              ...lastHour
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) =>
                                        _CIROSignalCard(
                                      signal: e.value,
                                      langColor: _langColor(
                                          e.value.language),
                                      index: e.key,
                                    ),
                                  ),
                            ],
                            if (earlier.isNotEmpty) ...[
                              _StickyGroupHeader(
                                  label: 'EARLIER TODAY'),
                              ...earlier
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) =>
                                        _CIROSignalCard(
                                      signal: e.value,
                                      langColor: _langColor(
                                          e.value.language),
                                      index: lastHour.length +
                                          e.key,
                                    ),
                                  ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inbox Header ──────────────────────────────────────────────────────────────

class _InboxHeader extends StatelessWidget {
  final int signalCount;

  const _InboxHeader({required this.signalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
            bottom:
                BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PPEyebrow('SIGNAL · LIVE STREAM'),
                const SizedBox(height: 2),
                Text(
                  'Signal Inbox',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.signalBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.signalBlue.withOpacity(0.3)),
            ),
            child: MonoText(
              '$signalCount',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.signalBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final SignalSource? sourceFilter;
  final SignalLanguage? langFilter;
  final ValueChanged<SignalSource?> onSourceChanged;
  final ValueChanged<SignalLanguage?> onLangChanged;

  const _FilterRow({
    required this.sourceFilter,
    required this.langFilter,
    required this.onSourceChanged,
    required this.onLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.fromLTRB(16, 8, 16, 4),
      children: [
        _FilterPill(
          label: 'ALL',
          selected: sourceFilter == null && langFilter == null,
          color: AppColors.textSecondary,
          onTap: () {
            onSourceChanged(null);
            onLangChanged(null);
          },
        ),
        ...SignalSource.values.map((s) => _FilterPill(
              label: s.name.toUpperCase(),
              selected: sourceFilter == s,
              color: AppColors.signalBlue,
              onTap: () => onSourceChanged(
                  sourceFilter == s ? null : s),
            )),
        const SizedBox(width: 4),
        _FilterPill(
          label: 'EN',
          selected: langFilter == SignalLanguage.english,
          color: AppColors.low,
          onTap: () => onLangChanged(
              langFilter == SignalLanguage.english
                  ? null
                  : SignalLanguage.english),
        ),
        _FilterPill(
          label: 'UR',
          selected: langFilter == SignalLanguage.urdu,
          color: AppColors.high,
          onTap: () => onLangChanged(
              langFilter == SignalLanguage.urdu
                  ? null
                  : SignalLanguage.urdu),
        ),
        _FilterPill(
          label: 'ROMAN UR',
          selected:
              langFilter == SignalLanguage.romanUrdu,
          color: AppColors.high,
          onTap: () => onLangChanged(
              langFilter == SignalLanguage.romanUrdu
                  ? null
                  : SignalLanguage.romanUrdu),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.18)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? color : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w400,
            color: selected
                ? color
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Group Header ──────────────────────────────────────────────────────────────

class _StickyGroupHeader extends StatelessWidget {
  final String label;
  const _StickyGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: PPEyebrow(label),
    );
  }
}

// ── CIRO Signal Card ──────────────────────────────────────────────────────────

class _CIROSignalCard extends StatelessWidget {
  final CrisisSignal signal;
  final Color langColor;
  final int index;

  const _CIROSignalCard({
    required this.signal,
    required this.langColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(signal.timestamp);
    final sourceBadge = signal.source.name.toUpperCase();

    return GestureDetector(
      onTap: () => showSignalDetail(context, signal),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left language dot
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: langColor,
                  boxShadow: [
                    BoxShadow(
                      color: langColor.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Source badge + time
                  Row(
                    children: [
                      MonoText(
                        sourceBadge,
                        fontSize: 9,
                        color: AppColors.textTertiary,
                      ),
                      const Spacer(),
                      MonoText(
                        timeAgo,
                        fontSize: 9,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Signal text
                  Text(
                    signal.rawText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Footer: confidence + severity
                  Row(
                    children: [
                      if (signal.severityHint != null)
                        SeverityChip(
                            severity: signal.severityHint!),
                      const Spacer(),
                      if (signal.sector != null)
                        MonoText(
                          signal.sector!,
                          fontSize: 9,
                          color: AppColors.textTertiary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(
            delay: Duration(milliseconds: 30 * index))
        .fadeIn(
          duration: 500.ms,
          curve: Cubic(0.32, 0.72, 0, 1),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 500.ms,
          curve: Cubic(0.32, 0.72, 0, 1),
        );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.3, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.signalBlue
                    .withOpacity(_pulseAnim.value),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.signalBlue
                        .withOpacity(0.4 * _pulseAnim.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No signals match filters',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing filters or wait for new signals',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
