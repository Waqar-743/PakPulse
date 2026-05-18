import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis_signal.dart';
import '../atoms/live_timestamp.dart';
import '../atoms/mono_text.dart';

class SignalCard extends StatelessWidget {
  final CrisisSignal signal;
  final bool compact;
  final VoidCallback? onTap;

  const SignalCard({
    super.key,
    required this.signal,
    this.compact = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: compact ? _CompactBody(signal: signal) : _FullBody(signal: signal),
      ),
    );
  }
}

class _CompactBody extends StatelessWidget {
  final CrisisSignal signal;
  const _CompactBody({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SourceBadge(source: signal.source),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SignalText(signal: signal, maxLines: 2),
              const SizedBox(height: 4),
              Row(
                children: [
                  _LanguageTag(language: signal.language),
                  if (signal.sector != null) ...[
                    const SizedBox(width: 6),
                    _SectorChip(sector: signal.sector!),
                  ],
                  const Spacer(),
                  LiveTimestamp(timestamp: signal.timestamp),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullBody extends StatelessWidget {
  final CrisisSignal signal;
  const _FullBody({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SourceBadge(source: signal.source),
            const SizedBox(width: 8),
            _LanguageTag(language: signal.language),
            if (signal.sector != null) ...[
              const SizedBox(width: 6),
              _SectorChip(sector: signal.sector!),
            ],
            const Spacer(),
            LiveTimestamp(timestamp: signal.timestamp),
          ],
        ),
        const SizedBox(height: 10),
        _SignalText(signal: signal, maxLines: 10),
      ],
    );
  }
}

class _SignalText extends StatelessWidget {
  final CrisisSignal signal;
  final int maxLines;
  const _SignalText({required this.signal, required this.maxLines});

  @override
  Widget build(BuildContext context) {
    if (signal.language == SignalLanguage.urdu) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          signal.rawText,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoNastaliqUrdu(
            fontSize: 13,
            height: 1.8,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }
    return Text(
      signal.rawText,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final SignalSource source;
  const _SourceBadge({required this.source});

  static const _labels = {
    SignalSource.twitter: 'TWT',
    SignalSource.pmd: 'PMD',
    SignalSource.ndma: 'NDMA',
    SignalSource.traffic: 'ITP',
    SignalSource.citizen: 'CIT',
  };

  static const _colors = {
    SignalSource.twitter: Color(0xFF1DA1F2),
    SignalSource.pmd: AppColors.signalBlue,
    SignalSource.ndma: AppColors.high,
    SignalSource.traffic: AppColors.moderate,
    SignalSource.citizen: AppColors.low,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[source] ?? AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: MonoText(
        _labels[source] ?? source.name.toUpperCase(),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _LanguageTag extends StatelessWidget {
  final SignalLanguage language;
  const _LanguageTag({required this.language});

  static const _labels = {
    SignalLanguage.english: 'EN',
    SignalLanguage.urdu: 'اردو',
    SignalLanguage.romanUrdu: 'Roman UR',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.borderSubtle,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _labels[language] ?? language.name,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _SectorChip extends StatelessWidget {
  final String sector;
  const _SectorChip({required this.sector});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.signalBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.signalBlue.withOpacity(0.3)),
      ),
      child: MonoText(sector, fontSize: 9, color: AppColors.signalBlue),
    );
  }
}

// Wrapper that shows extracted entities on tap (bottom sheet)
void showSignalDetail(BuildContext context, CrisisSignal signal) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _SignalDetailSheet(signal: signal),
  );
}

class _SignalDetailSheet extends StatelessWidget {
  final CrisisSignal signal;
  const _SignalDetailSheet({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SIGNAL DETAILS', style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          _DetailRow('Location', signal.sector ?? 'Unknown'),
          _DetailRow('Type', signal.crisisHint?.label ?? 'Unclassified'),
          _DetailRow(
              'Severity', signal.severityHint?.label ?? 'Unknown'),
          _DetailRow(
              'Language',
              signal.language == SignalLanguage.urdu
                  ? 'Urdu Script'
                  : signal.language == SignalLanguage.romanUrdu
                      ? 'Roman Urdu'
                      : 'English'),
          _DetailRow('Source', signal.source.name.toUpperCase()),
          const SizedBox(height: 16),
          Text('RAW TEXT', style: AppTypography.labelSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: signal.language == SignalLanguage.urdu
                ? Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      signal.rawText,
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 14,
                        height: 1.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : Text(signal.rawText, style: AppTypography.bodyMedium),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTypography.labelSmall),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
