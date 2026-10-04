import '../models/measurement_model.dart';

class AIRiskAnalysisResult {
  final int safetyScore;
  final String riskLevel; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final String riskType;
  final double probability;
  final String cause;
  final String recommendedAction;
  final bool hasAnomaly;

  AIRiskAnalysisResult({
    required this.safetyScore,
    required this.riskLevel,
    required this.riskType,
    required this.probability,
    required this.cause,
    required this.recommendedAction,
    required this.hasAnomaly,
  });
}

class AIRiskEngine {
  static AIRiskAnalysisResult analyze(MeasurementModel measurement) {
    // Overcurrent check
    if (measurement.current > 35.0) {
      return AIRiskAnalysisResult(
        safetyScore: 42,
        riskLevel: 'CRITICAL',
        riskType: 'Overcurrent Thermal Overload',
        probability: 0.94,
        cause: 'Abnormal Current Pattern (${measurement.current.toStringAsFixed(1)} A peak)',
        recommendedAction: 'Inspect main circuit breaker and reduce heavy electrical load immediately.',
        hasAnomaly: true,
      );
    }

    // Leakage current check
    if (measurement.leakage > 0.15) {
      return AIRiskAnalysisResult(
        safetyScore: 58,
        riskLevel: 'HIGH',
        riskType: 'Current Leakage Hazard',
        probability: 0.88,
        cause: 'Insulation Breakdown / Ground Fault (${(measurement.leakage * 1000).toStringAsFixed(0)} mA)',
        recommendedAction: 'Disconnect affected branch and inspect grounding line for moisture/damage.',
        hasAnomaly: true,
      );
    }

    // Voltage drop check
    if (measurement.voltage < 195.0 || measurement.voltage > 245.0) {
      return AIRiskAnalysisResult(
        safetyScore: 71,
        riskLevel: 'MEDIUM',
        riskType: 'Voltage Fluctuation Anomaly',
        probability: 0.76,
        cause: 'Grid Voltage Instability (${measurement.voltage.toStringAsFixed(1)} V)',
        recommendedAction: 'Verify automatic voltage regulator (AVR) performance.',
        hasAnomaly: true,
      );
    }

    // Normal safe condition
    return AIRiskAnalysisResult(
      safetyScore: 94,
      riskLevel: 'LOW',
      riskType: 'No abnormal behavior detected',
      probability: 0.05,
      cause: 'Optimal Operating Parameters',
      recommendedAction: 'System operating normally. Continue scheduled monitoring.',
      hasAnomaly: false,
    );
  }
}
