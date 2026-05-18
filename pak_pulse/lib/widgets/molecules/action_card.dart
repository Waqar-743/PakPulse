import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/crisis_action.dart';
import '../atoms/mono_text.dart';

class ActionCard extends StatefulWidget {
  final CrisisAction action;
  final ValueChanged<CrisisAction>? onExecuted;

  const ActionCard({super.key, required this.action, this.onExecuted});

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  late CrisisAction _action;
  String _typewriterText = '';
  Timer? _typewriter;

  @override
  void initState() {
    super.initState();
    _action = widget.action;
  }

  @override
  void dispose() {
    _typewriter?.cancel();
    super.dispose();
  }

  Future<void> _execute() async {
    await Haptics.medium();
    setState(() => _action = _action.copyWith(status: ActionStatus.executing));

    await Future.delayed(const Duration(milliseconds: 800));

    final response = _action.mockResponse ??
        '{"status":"completed","message":"Action executed successfully"}';

    int charIndex = 0;
    _typewriter = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) { t.cancel(); return; }
      if (charIndex >= response.length) {
        t.cancel();
        if (mounted) {
          setState(() {
            _action = _action.copyWith(
              status: ActionStatus.completed,
              executedAt: DateTime.now(),
              mockResponse: response,
            );
          });
          widget.onExecuted?.call(_action);
        }
        return;
      }
      setState(() => _typewriterText = response.substring(0, ++charIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _statusColor(_action.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _action.status == ActionStatus.executing
              ? typeColor.withOpacity(0.5)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusIcon(status: _action.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _action.title,
                        style: AppTypography.headingSmall.copyWith(fontSize: 14),
                      ),
                    ),
                    _TypeBadge(type: _action.type),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _action.description,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.business, size: 12,
                        color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(_action.targetAgency,
                        style: AppTypography.labelSmall),
                  ],
                ),
                if (_action.mockTicketId != null &&
                    _action.status == ActionStatus.completed) ...[
                  const SizedBox(height: 8),
                  MonoText(
                    '● ${_action.mockTicketId}',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.low,
                  ),
                ],
              ],
            ),
          ),
          if (_action.status == ActionStatus.executing ||
              (_action.status == ActionStatus.completed &&
                  _typewriterText.isNotEmpty))
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundBase,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MonoText(
                _action.status == ActionStatus.completed
                    ? (_action.mockResponse ?? _typewriterText)
                    : _typewriterText,
                fontSize: 10,
                color: AppColors.low,
              ),
            ),
          if (_action.status == ActionStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _execute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.critical,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'EXECUTE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          if (_action.status == ActionStatus.executing)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.borderSubtle,
                color: AppColors.critical,
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(ActionStatus s) {
    switch (s) {
      case ActionStatus.pending:   return AppColors.textTertiary;
      case ActionStatus.executing: return AppColors.moderate;
      case ActionStatus.completed: return AppColors.low;
      case ActionStatus.failed:    return AppColors.critical;
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final ActionStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ActionStatus.pending:
        return Icon(Icons.radio_button_unchecked,
            size: 16, color: AppColors.textTertiary);
      case ActionStatus.executing:
        return const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.moderate,
          ),
        );
      case ActionStatus.completed:
        return const Icon(Icons.check_circle,
            size: 16, color: AppColors.low);
      case ActionStatus.failed:
        return const Icon(Icons.error,
            size: 16, color: AppColors.critical);
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final ActionType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ActionType.dispatch => ('DISPATCH', AppColors.critical),
      ActionType.reroute  => ('REROUTE',  AppColors.signalBlue),
      ActionType.alert    => ('ALERT',    AppColors.moderate),
      ActionType.ticket   => ('TICKET',   AppColors.low),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MonoText(label, fontSize: 9, color: color,
          fontWeight: FontWeight.w700),
    );
  }
}
