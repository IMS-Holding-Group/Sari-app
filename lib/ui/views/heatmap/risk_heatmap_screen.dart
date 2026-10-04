import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/zone_model.dart';
import '../../view_models/app_state_view_model.dart';

class RiskHeatmapScreen extends StatefulWidget {
  const RiskHeatmapScreen({super.key});

  @override
  State<RiskHeatmapScreen> createState() => _RiskHeatmapScreenState();
}

class _RiskHeatmapScreenState extends State<RiskHeatmapScreen> {
  ZoneModel? _selectedZone;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateViewModel>();
    final zones = state.zones;

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
                child: const Icon(Icons.map_rounded, color: AppColors.primaryBlue, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.tr('heatmapTitle'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state.tr('heatmapSub'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Map legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Text('🟢 ', style: TextStyle(fontSize: 14)),
                    Text(state.tr('safe'), style: const TextStyle(fontSize: 12, color: AppColors.safeGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Text('🟡 ', style: TextStyle(fontSize: 14)),
                    Text(state.tr('warning'), style: const TextStyle(fontSize: 12, color: AppColors.warningOrange, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Text('🔴 ', style: TextStyle(fontSize: 14)),
                    Text(state.tr('criticalRisk'), style: const TextStyle(fontSize: 12, color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid of Spatial Rooms / Industrial Zones
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
            ),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              final color = _getZoneColor(zone.riskLevel);
              final iconStr = _getZoneIconStr(zone.riskLevel);

              return GestureDetector(
                onTap: () => setState(() => _selectedZone = zone),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              zone.floor,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(iconStr, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Load: ${zone.currentLoad} A • ${zone.voltage} V',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(zone.leakageCurrent * 1000).toStringAsFixed(0)} mA leakage',
                            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Zone Detail Inspector Panel
          if (_selectedZone != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getZoneColor(_selectedZone!.riskLevel), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inspector: ${_selectedZone!.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _selectedZone = null),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedZone!.details,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailStat('Active Sensors', '${_selectedZone!.activeSensors} Devices'),
                      _buildDetailStat('Current Draw', '${_selectedZone!.currentLoad} A'),
                      _buildDetailStat('Line Voltage', '${_selectedZone!.voltage} V'),
                    ],
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Color _getZoneColor(ZoneRiskLevel level) {
    switch (level) {
      case ZoneRiskLevel.safe:
        return AppColors.safeGreen;
      case ZoneRiskLevel.warning:
        return AppColors.warningOrange;
      case ZoneRiskLevel.critical:
        return AppColors.dangerRed;
    }
  }

  String _getZoneIconStr(ZoneRiskLevel level) {
    switch (level) {
      case ZoneRiskLevel.safe:
        return '🟢';
      case ZoneRiskLevel.warning:
        return '🟡';
      case ZoneRiskLevel.critical:
        return '🔴';
    }
  }
}
