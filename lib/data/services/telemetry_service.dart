import 'dart:async';
import 'dart:math';
import '../models/measurement_model.dart';

class TelemetryService {
  final Random _random = Random();
  Timer? _ticker;
  final StreamController<MeasurementModel> _controller = StreamController<MeasurementModel>.broadcast();

  double _currentBias = 14.5;
  double _voltageBias = 220.0;
  double _leakageBias = 0.02;
  double _tempBias = 32.0;

  bool _isSimulatingSurge = false;
  bool _isSimulatingVoltageDrop = false;
  bool _isSimulatingLeakageFault = false;

  Stream<MeasurementModel> get telemetryStream => _controller.stream;

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _emitCurrentReading();
    });
  }

  void stop() {
    _ticker?.cancel();
  }

  void _emitCurrentReading() {
    double current = _currentBias + (_random.nextDouble() * 1.2 - 0.6);
    double voltage = _voltageBias + (_random.nextDouble() * 4.0 - 2.0);
    double leakage = _leakageBias + (_random.nextDouble() * 0.004 - 0.002);
    double temp = _tempBias + (_random.nextDouble() * 0.6 - 0.3);

    if (_isSimulatingSurge) {
      current = 48.5 + (_random.nextDouble() * 4.0);
      temp += 8.0;
    }

    if (_isSimulatingVoltageDrop) {
      voltage = 172.0 + (_random.nextDouble() * 5.0);
    }

    if (_isSimulatingLeakageFault) {
      leakage = 0.42 + (_random.nextDouble() * 0.1);
    }

    final measurement = MeasurementModel(
      deviceID: 'SARI-SENS-01',
      timestamp: DateTime.now(),
      current: double.parse(current.toStringAsFixed(2)),
      voltage: double.parse(voltage.toStringAsFixed(1)),
      leakage: double.parse(leakage.toStringAsFixed(3)),
      temperature: double.parse(temp.toStringAsFixed(1)),
    );

    _controller.add(measurement);
  }

  void triggerOvercurrentSurge() {
    _isSimulatingSurge = true;
    _emitCurrentReading();
  }

  void triggerVoltageDrop() {
    _isSimulatingVoltageDrop = true;
    _emitCurrentReading();
  }

  void triggerGroundLeakageFault() {
    _isSimulatingLeakageFault = true;
    _emitCurrentReading();
  }

  void resetToNormal() {
    _isSimulatingSurge = false;
    _isSimulatingVoltageDrop = false;
    _isSimulatingLeakageFault = false;
    _emitCurrentReading();
  }

  void dispose() {
    _ticker?.cancel();
    _controller.close();
  }
}
