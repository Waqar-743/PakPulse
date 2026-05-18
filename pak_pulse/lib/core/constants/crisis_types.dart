enum CrisisType { flood, heatwave, protest }

enum SeverityLevel { critical, high, moderate, low }

enum SignalSource { twitter, pmd, ndma, traffic, citizen }

enum SignalLanguage { english, urdu, romanUrdu }

enum AgentName { signal, detection, severity, action }

enum ActionType { dispatch, reroute, alert, ticket }

enum ActionStatus { pending, executing, completed, failed }

extension CrisisTypeExt on CrisisType {
  String get label {
    switch (this) {
      case CrisisType.flood:
        return 'Urban Flooding';
      case CrisisType.heatwave:
        return 'Extreme Heatwave';
      case CrisisType.protest:
        return 'Road Blockage';
    }
  }

  String get emoji {
    switch (this) {
      case CrisisType.flood:
        return '🌊';
      case CrisisType.heatwave:
        return '🔥';
      case CrisisType.protest:
        return '🚧';
    }
  }
}

extension SeverityExt on SeverityLevel {
  String get label => name.toUpperCase();

  int get order {
    switch (this) {
      case SeverityLevel.critical:
        return 0;
      case SeverityLevel.high:
        return 1;
      case SeverityLevel.moderate:
        return 2;
      case SeverityLevel.low:
        return 3;
    }
  }
}
