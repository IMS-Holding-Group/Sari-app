class MeasurementModel {
  final String deviceID;
  final DateTime timestamp;
  final double current;     // Amperes (A)
  final double voltage;     // Volts (V)
  final double leakage;     // Amperes (A), e.g. 0.02 A
  final double temperature; // Celsius (°C)

  MeasurementModel({
    required this.deviceID,
    required this.timestamp,
    required this.current,
    required this.voltage,
    required this.leakage,
    required this.temperature,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceID': deviceID,
      'timestamp': timestamp.toIso8601String(),
      'current': current,
      'voltage': voltage,
      'leakage': leakage,
      'temperature': temperature,
    };
  }

  factory MeasurementModel.fromMap(Map<String, dynamic> map) {
    return MeasurementModel(
      deviceID: map['deviceID'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      current: (map['current'] as num?)?.toDouble() ?? 0.0,
      voltage: (map['voltage'] as num?)?.toDouble() ?? 0.0,
      leakage: (map['leakage'] as num?)?.toDouble() ?? 0.0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 25.0,
    );
  }
}
