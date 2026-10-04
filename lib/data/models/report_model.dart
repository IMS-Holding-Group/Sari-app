class ReportModel {
  final String reportID;
  final String organizationID;
  final String title;
  final DateTime date;
  final int riskScore; // e.g. 92
  final int eventsCount;
  final double peakCurrent;
  final int avoidedIncidents;
  final List<String> summaryHighlights;

  ReportModel({
    required this.reportID,
    required this.organizationID,
    required this.title,
    required this.date,
    required this.riskScore,
    required this.eventsCount,
    required this.peakCurrent,
    required this.avoidedIncidents,
    required this.summaryHighlights,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportID': reportID,
      'organizationID': organizationID,
      'title': title,
      'date': date.toIso8601String(),
      'riskScore': riskScore,
      'eventsCount': eventsCount,
      'peakCurrent': peakCurrent,
      'avoidedIncidents': avoidedIncidents,
      'summaryHighlights': summaryHighlights,
    };
  }
}
