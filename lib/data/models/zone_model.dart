enum ZoneRiskLevel {
  safe,      // 🟢 Green
  warning,   // 🟡 Yellow
  critical,  // 🔴 Red
}

class ZoneModel {
  final String zoneID;
  final String name;
  final String floor;
  final ZoneRiskLevel riskLevel;
  final double currentLoad;
  final double voltage;
  final double leakageCurrent;
  final int activeSensors;
  final String details;

  ZoneModel({
    required this.zoneID,
    required this.name,
    required this.floor,
    required this.riskLevel,
    required this.currentLoad,
    required this.voltage,
    required this.leakageCurrent,
    required this.activeSensors,
    required this.details,
  });
}
