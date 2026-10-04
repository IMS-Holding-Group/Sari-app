import 'package:flutter_test/flutter_test.dart';
import 'package:sari_app/data/models/measurement_model.dart';
import 'package:sari_app/data/services/ai_risk_engine.dart';
import 'package:sari_app/ui/view_models/app_state_view_model.dart';

void main() {
  group('AI Risk Engine Tests', () {
    test('Normal parameters return LOW risk level and high safety score', () {
      final normal = MeasurementModel(
        deviceID: 'TEST-01',
        timestamp: DateTime.now(),
        current: 14.5,
        voltage: 220.0,
        leakage: 0.02,
        temperature: 30.0,
      );

      final result = AIRiskEngine.analyze(normal);
      expect(result.riskLevel, equals('LOW'));
      expect(result.safetyScore, greaterThanOrEqualTo(90));
      expect(result.hasAnomaly, isFalse);
    });

    test('Overcurrent surge returns CRITICAL risk level', () {
      final surge = MeasurementModel(
        deviceID: 'TEST-01',
        timestamp: DateTime.now(),
        current: 48.5,
        voltage: 220.0,
        leakage: 0.02,
        temperature: 38.0,
      );

      final result = AIRiskEngine.analyze(surge);
      expect(result.riskLevel, equals('CRITICAL'));
      expect(result.hasAnomaly, isTrue);
      expect(result.probability, greaterThan(0.9));
    });

    test('Ground leakage fault returns HIGH risk level', () {
      final leakageFault = MeasurementModel(
        deviceID: 'TEST-01',
        timestamp: DateTime.now(),
        current: 14.5,
        voltage: 220.0,
        leakage: 0.45,
        temperature: 30.0,
      );

      final result = AIRiskEngine.analyze(leakageFault);
      expect(result.riskLevel, equals('HIGH'));
      expect(result.hasAnomaly, isTrue);
    });
  });

  group('App State ViewModel Tests', () {
    test('Emergency power shutdown updates power status', () {
      final vm = AppStateViewModel();
      expect(vm.isPowerCut, isFalse);

      vm.cutPower();
      expect(vm.isPowerCut, isTrue);
      expect(vm.latestMeasurement.current, equals(0.0));

      vm.restorePower();
      expect(vm.isPowerCut, isFalse);
      vm.dispose();
    });

    test('Locale switching toggles between English and Arabic', () {
      final vm = AppStateViewModel();
      expect(vm.locale.languageCode, equals('en'));
      expect(vm.tr('appTitle'), equals('SARI'));

      vm.toggleLanguage();
      expect(vm.locale.languageCode, equals('ar'));
      expect(vm.tr('appTitle'), equals('ساري'));

      vm.toggleLanguage();
      expect(vm.locale.languageCode, equals('en'));
      vm.dispose();
    });
  });
}
