enum AlertSeverity {
  critical,
  warning,
  info,
}

enum AlertStatus {
  active,
  resolved,
  investigating,
}

class AlertModel {
  final String alertID;
  final String deviceID;
  final String title;
  final String location;
  final String type;
  final AlertSeverity severity;
  final DateTime timestamp;
  final AlertStatus status;
  final String recommendedAction;
  final double probability;

  AlertModel({
    required this.alertID,
    required this.deviceID,
    required this.title,
    required this.location,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.status,
    required this.recommendedAction,
    this.probability = 0.85,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertID': alertID,
      'deviceID': deviceID,
      'title': title,
      'location': location,
      'type': type,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'recommendedAction': recommendedAction,
      'probability': probability,
    };
  }

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    AlertSeverity sev = AlertSeverity.info;
    final s = map['severity'] as String?;
    if (s == 'critical') sev = AlertSeverity.critical;
    if (s == 'warning') sev = AlertSeverity.warning;

    AlertStatus stat = AlertStatus.active;
    final st = map['status'] as String?;
    if (st == 'resolved') stat = AlertStatus.resolved;
    if (st == 'investigating') stat = AlertStatus.investigating;

    return AlertModel(
      alertID: map['alertID'] ?? '',
      deviceID: map['deviceID'] ?? '',
      title: map['title'] ?? 'Electrical Warning',
      location: map['location'] ?? 'Main Panel',
      type: map['type'] ?? 'Abnormal Current',
      severity: sev,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      status: stat,
      recommendedAction: map['recommendedAction'] ?? 'Inspect electrical panel immediately',
      probability: (map['probability'] as num?)?.toDouble() ?? 0.85,
    );
  }
}
