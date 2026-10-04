import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/models/device_model.dart';
import '../../view_models/app_state_view_model.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedChartMetric = 0; // 0: Current, 1: Voltage, 2: Leakage

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();
    final history = state.measurementHistory;
    final latest = state.latestMeasurement;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with device selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.tr('liveMonitoringTitle'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.tr('liveMonitoringSub'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors, color: AppColors.primaryBlue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      latest.deviceID,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Metric Selection Tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) => setState(() => _selectedChartMetric = index),
              indicatorColor: AppColors.primaryBlue,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: state.tr('currentTab')),
                Tab(text: state.tr('voltageTab')),
                Tab(text: state.tr('leakageTab')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // High Performance Real-Time Chart Container
          Container(
            height: 280,
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _getMetricTitleWidget(_selectedChartMetric, latest),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.safeGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.tr('streamingHz'),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : LineChart(
                          _buildLineChartData(history, _selectedChartMetric),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Live Quick Metrics Summary Strip
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Current Peak',
                  value: '${latest.current.toStringAsFixed(1)} A',
                  color: latest.current > 35.0 ? AppColors.dangerRed : AppColors.safeGreen,
                  icon: Icons.electric_bolt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Voltage Line',
                  value: '${latest.voltage.toStringAsFixed(1)} V',
                  color: (latest.voltage < 195 || latest.voltage > 245)
                      ? AppColors.warningOrange
                      : AppColors.primaryBlue,
                  icon: Icons.speed_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Leakage Path',
                  value: '${(latest.leakage * 1000).toStringAsFixed(0)} mA',
                  color: latest.leakage > 0.15 ? AppColors.dangerRed : AppColors.safeGreen,
                  icon: Icons.water_drop_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Connected Device Sensors Status List
          Text(
            state.tr('connectedDevices'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.devices.length,
            itemBuilder: (context, index) {
              final device = state.devices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        color: _getDeviceStatusColor(device.status).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sensors,
                        color: _getDeviceStatusColor(device.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${device.location} • ${device.circuitType}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getDeviceStatusColor(device.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            device.status.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getDeviceStatusColor(device.status),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bat: ${device.batteryLevel.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getMetricTitleWidget(int metricIndex, MeasurementModel latest) {
    if (metricIndex == 0) {
      return Text(
        'Current Telemetry: ${latest.current.toStringAsFixed(1)} A',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      );
    } else if (metricIndex == 1) {
      return Text(
        'Voltage Telemetry: ${latest.voltage.toStringAsFixed(1)} V',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      );
    } else {
      return Text(
        'Leakage Current: ${(latest.leakage * 1000).toStringAsFixed(0)} mA',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      );
    }
  }

  LineChartData _buildLineChartData(List<MeasurementModel> history, int metricIndex) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      double val = 0.0;
      if (metricIndex == 0) val = history[i].current;
      if (metricIndex == 1) val = history[i].voltage;
      if (metricIndex == 2) val = history[i].leakage * 1000.0; // convert to mA
      spots.add(FlSpot(i.toDouble(), val));
    }

    Color lineColor = AppColors.safeGreen;
    if (metricIndex == 0 && history.last.current > 35.0) lineColor = AppColors.dangerRed;
    if (metricIndex == 1) lineColor = AppColors.primaryBlue;
    if (metricIndex == 2 && history.last.leakage > 0.15) lineColor = AppColors.dangerRed;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.gridLine, strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withOpacity(0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getDeviceStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return AppColors.safeGreen;
      case DeviceStatus.warning:
        return AppColors.warningOrange;
      case DeviceStatus.critical:
        return AppColors.dangerRed;
      case DeviceStatus.offline:
        return AppColors.textMuted;
    }
  }
}
