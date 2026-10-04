import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sari_date.dart';
import '../../../data/models/alert_model.dart';
import '../../view_models/app_state_view_model.dart';

class AlertsCenterScreen extends StatefulWidget {
  const AlertsCenterScreen({super.key});

  @override
  State<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends State<AlertsCenterScreen> {
  String _selectedFilter = 'ALL'; // ALL, CRITICAL, WARNING, INFO, ACTIVE, RESOLVED

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();
    final allAlerts = state.alerts;

    final filteredAlerts = allAlerts.where((alert) {
      if (_selectedFilter == 'CRITICAL') return alert.severity == AlertSeverity.critical;
      if (_selectedFilter == 'WARNING') return alert.severity == AlertSeverity.warning;
      if (_selectedFilter == 'INFO') return alert.severity == AlertSeverity.info;
      if (_selectedFilter == 'ACTIVE') return alert.status == AlertStatus.active;
      if (_selectedFilter == 'RESOLVED') return alert.status == AlertStatus.resolved;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter pills bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Alerts (${allAlerts.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('ACTIVE', 'Active'),
              const SizedBox(width: 8),
              _buildFilterChip('CRITICAL', 'Critical 🔴'),
              const SizedBox(width: 8),
              _buildFilterChip('WARNING', 'Warning 🟡'),
              const SizedBox(width: 8),
              _buildFilterChip('INFO', 'Info 🔵'),
              const SizedBox(width: 8),
              _buildFilterChip('RESOLVED', 'Resolved 🟢'),
            ],
          ),
        ),

        Expanded(
          child: filteredAlerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Safety Alerts Found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No records match filter: $_selectedFilter',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    final timeFormatted = SariDate.format(alert.timestamp);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _getSeverityColor(alert.severity).withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(alert.severity).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        alert.severity.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getSeverityColor(alert.severity),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: alert.status == AlertStatus.resolved
                                            ? AppColors.safeGreen.withOpacity(0.15)
                                            : AppColors.warningOrange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        alert.status.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: alert.status == AlertStatus.resolved
                                              ? AppColors.safeGreen
                                              : AppColors.warningOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  timeFormatted,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              alert.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Location: ${alert.location}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Probability: ${(alert.probability * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${state.tr('recommendedAction')}: ${alert.recommendedAction}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                            if (alert.status == AlertStatus.active) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () => state.resolveAlert(alert.alertID),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.safeGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: Text(state.tr('markResolved'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
      selectedColor: AppColors.primaryBlue,
      backgroundColor: AppColors.darkSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.dangerRed;
      case AlertSeverity.warning:
        return AppColors.warningOrange;
      case AlertSeverity.info:
        return AppColors.primaryBlue;
    }
  }
}
