import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../view_models/app_state_view_model.dart';

class AIRiskDetectionScreen extends StatelessWidget {
  const AIRiskDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();
    final result = state.aiRiskResult;

    Color riskColor = AppColors.safeGreen;
    if (result.riskLevel == 'CRITICAL') riskColor = AppColors.dangerRed;
    if (result.riskLevel == 'HIGH') riskColor = AppColors.dangerRed;
    if (result.riskLevel == 'MEDIUM') riskColor = AppColors.warningOrange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: AppColors.primaryBlue, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.tr('aiEngineTitle'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state.tr('aiEngineSub'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main AI Analysis Banner Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: riskColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: riskColor.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.tr('aiAnalysisResult'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: riskColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.tr('riskLevel')}: ${result.riskLevel}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  result.riskType,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 16),

                // Details grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.tr('cause'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(result.cause, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.tr('probability'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            '${(result.probability * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: riskColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Recommended Action container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warningOrange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.tr('recommendedAction'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warningOrange),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.recommendedAction,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Machine Learning Anomaly Risk Drivers
          Text(
            state.tr('predictiveModels'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildRiskDriverTile(
            title: 'Arc Fault Pattern Engine',
            sub: 'High frequency current waveform distortion analysis',
            confidence: 96,
            status: result.hasAnomaly ? 'Warning' : 'Normal',
            color: result.hasAnomaly ? AppColors.warningOrange : AppColors.safeGreen,
          ),
          const SizedBox(height: 10),
          _buildRiskDriverTile(
            title: 'Insulation Degradation Predictor',
            sub: 'Ground leakage trend vs ambient humidity matrix',
            confidence: 91,
            status: result.hasAnomaly && state.latestMeasurement.leakage > 0.15 ? 'Critical' : 'Normal',
            color: result.hasAnomaly && state.latestMeasurement.leakage > 0.15 ? AppColors.dangerRed : AppColors.safeGreen,
          ),
          const SizedBox(height: 10),
          _buildRiskDriverTile(
            title: 'Motor Thermal Overload Classifier',
            sub: 'Current draw harmonics & phase imbalance',
            confidence: 94,
            status: state.latestMeasurement.current > 35.0 ? 'Critical' : 'Normal',
            color: state.latestMeasurement.current > 35.0 ? AppColors.dangerRed : AppColors.safeGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDriverTile({
    required String title,
    required String sub,
    required int confidence,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_graph_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '$confidence% model accuracy',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
