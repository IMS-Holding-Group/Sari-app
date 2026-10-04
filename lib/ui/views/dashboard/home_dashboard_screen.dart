import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/alert_model.dart';
import '../../view_models/app_state_view_model.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  Color _getScoreColor(int score) {
    if (score >= 85) return AppColors.safeGreen;
    if (score >= 65) return AppColors.warningOrange;
    return AppColors.dangerRed;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();
    final user = state.currentUser;
    final score = state.aiRiskResult.safetyScore;
    final scoreColor = _getScoreColor(score);
    final measurement = state.latestMeasurement;
    final activeAlerts = state.alerts.where((a) => a.status == AlertStatus.active).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & User Role Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.tr('welcomeBack')}, ${user.name}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Org ID: ${user.organizationID}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.go('/app/alerts'),
                    icon: const Icon(Icons.notifications_none_rounded, size: 28),
                  ),
                  if (activeAlerts.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.dangerRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${activeAlerts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Safety Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardBg,
                  AppColors.darkSurface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: score / 100.0,
                        strokeWidth: 10,
                        backgroundColor: AppColors.darkSurface,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          state.aiRiskResult.riskLevel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.tr('safetyScoreTitle'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.aiRiskResult.riskType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/app/ai-risk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scoreColor.withOpacity(0.2),
                          foregroundColor: scoreColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: scoreColor.withOpacity(0.4)),
                          ),
                        ),
                        icon: const Icon(Icons.psychology_outlined, size: 16),
                        label: Text(state.tr('viewAiAnalysis'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Main Indicators Section Header
          Text(
            state.tr('realtimeTelemetry'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          // Main Indicators Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: [
              _buildMetricCard(
                title: state.tr('currentStatus'),
                value: measurement.current > 35.0 ? state.tr('overcurrent') : state.tr('normal'),
                unit: '${measurement.current.toStringAsFixed(1)} A',
                icon: Icons.electric_meter_rounded,
                color: measurement.current > 35.0 ? AppColors.dangerRed : AppColors.safeGreen,
              ),
              _buildMetricCard(
                title: state.tr('voltage'),
                value: '${measurement.voltage.toStringAsFixed(1)} V',
                unit: 'Target: 220 V',
                icon: Icons.bolt_rounded,
                color: (measurement.voltage < 195 || measurement.voltage > 245)
                    ? AppColors.warningOrange
                    : AppColors.primaryBlue,
              ),
              _buildMetricCard(
                title: state.tr('leakageCurrent'),
                value: '${(measurement.leakage * 1000).toStringAsFixed(0)} mA',
                unit: 'Max: 30 mA',
                icon: Icons.water_drop_outlined,
                color: measurement.leakage > 0.15 ? AppColors.dangerRed : AppColors.safeGreen,
              ),
              _buildMetricCard(
                title: state.tr('connectedDevices'),
                value: '${state.devices.length} Active',
                unit: 'Sensors Online',
                icon: Icons.sensors_rounded,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Interactive Simulation Control Panel (For easy testing & demoing)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bug_report_outlined, color: AppColors.warningOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.tr('anomalySimulator'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => state.resetSimulation(),
                      child: Text(state.tr('resetNormal'), style: const TextStyle(fontSize: 12, color: AppColors.safeGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => state.simulateOvercurrentSurge(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerRed,
                        side: const BorderSide(color: AppColors.dangerRed),
                      ),
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: Text(state.tr('simulateSurge'), style: const TextStyle(fontSize: 12)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => state.simulateVoltageDrop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warningOrange,
                        side: const BorderSide(color: AppColors.warningOrange),
                      ),
                      icon: const Icon(Icons.trending_down, size: 16),
                      label: Text(state.tr('simulateDip'), style: const TextStyle(fontSize: 12)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => state.simulateLeakageFault(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerRed,
                        side: const BorderSide(color: AppColors.dangerRed),
                      ),
                      icon: const Icon(Icons.water_drop, size: 16),
                      label: Text(state.tr('simulateLeakage'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Active Safety Alerts Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.tr('activeAlerts'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton(
                onPressed: () => context.go('/app/alerts'),
                child: Text(state.tr('viewAll'), style: const TextStyle(color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activeAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.safeGreen, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.tr('allSystemsNormal'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          state.tr('noActiveAlertsSub'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeAlerts.length,
              itemBuilder: (context, index) {
                final alert = activeAlerts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.cardBg,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: alert.severity == AlertSeverity.critical
                            ? AppColors.dangerRed.withOpacity(0.2)
                            : AppColors.warningOrange.withOpacity(0.2),
                        child: Icon(
                          alert.severity == AlertSeverity.critical
                              ? Icons.error_rounded
                              : Icons.warning_amber_rounded,
                          color: alert.severity == AlertSeverity.critical
                              ? AppColors.dangerRed
                              : AppColors.warningOrange,
                        ),
                      ),
                      title: Text(
                        alert.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${alert.location} • Probability: ${(alert.probability * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => state.resolveAlert(alert.alertID),
                        child: Text(state.tr('resolve'), style: const TextStyle(color: AppColors.safeGreen, fontSize: 12)),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
