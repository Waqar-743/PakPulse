import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'crisis_types.dart';

class AgentColors {
  AgentColors._();

  static Color forAgent(AgentName agent) {
    switch (agent) {
      case AgentName.signal:
        return AppColors.agentSignal;
      case AgentName.detection:
        return AppColors.agentDetection;
      case AgentName.severity:
        return AppColors.agentSeverity;
      case AgentName.action:
        return AppColors.agentAction;
    }
  }

  static Color forCrisis(CrisisType type) {
    switch (type) {
      case CrisisType.flood:
        return AppColors.floodColor;
      case CrisisType.heatwave:
        return AppColors.heatwaveColor;
      case CrisisType.protest:
        return AppColors.protestColor;
    }
  }

  static Color forSeverity(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return AppColors.critical;
      case SeverityLevel.high:
        return AppColors.high;
      case SeverityLevel.moderate:
        return AppColors.moderate;
      case SeverityLevel.low:
        return AppColors.low;
    }
  }
}
