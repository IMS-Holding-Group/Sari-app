enum DeviceStatus {
  online,
  offline,
  warning,
  critical,
}

class DeviceModel {
  final String deviceID;
  final String name;
  final String userID;
  final String location;
  final DeviceStatus status;
  final DateTime installationDate;
  final double batteryLevel;
  final String circuitType;

  DeviceModel({
    required this.deviceID,
    required this.name,
    required this.userID,
    required this.location,
    required this.status,
    required this.installationDate,
    this.batteryLevel = 98.0,
    this.circuitType = 'Main Panel 220V',
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceID': deviceID,
      'name': name,
      'userID': userID,
      'location': location,
      'status': status.name,
      'installationDate': installationDate.toIso8601String(),
      'batteryLevel': batteryLevel,
      'circuitType': circuitType,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    DeviceStatus stat = DeviceStatus.online;
    final s = map['status'] as String?;
    if (s == 'warning') stat = DeviceStatus.warning;
    if (s == 'critical') stat = DeviceStatus.critical;
    if (s == 'offline') stat = DeviceStatus.offline;

    return DeviceModel(
      deviceID: map['deviceID'] ?? '',
      name: map['name'] ?? 'SARI Sensor',
      userID: map['userID'] ?? '',
      location: map['location'] ?? 'Main Panel',
      status: stat,
      installationDate: DateTime.tryParse(map['installationDate'] ?? '') ?? DateTime.now(),
      batteryLevel: (map['batteryLevel'] as num?)?.toDouble() ?? 98.0,
      circuitType: map['circuitType'] ?? 'Main Panel 220V',
    );
  }
}
