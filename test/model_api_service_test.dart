import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sari_app/data/models/measurement_model.dart';
import 'package:sari_app/data/services/model_api_service.dart';
import 'package:sari_app/ui/view_models/app_state_view_model.dart';

Map<String, dynamic> _payload({required bool alarm}) => {
      'device_id': 'SARI-SENS-01',
      'time_display': '2026/9/27م 8:05ص',
      'alarm': alarm,
      'cutoff': alarm,
      'warning': false,
      'faults': alarm ? ['leakage'] : [],
      'result': {
        'safetyScore': alarm ? 12 : 97,
        'riskLevel': alarm ? 'CRITICAL' : 'LOW',
        'riskType': alarm ? 'Current Leakage Hazard' : 'No abnormal behavior detected',
        'probability': alarm ? 0.99 : 0.01,
        'cause': alarm ? 'Leakage 450 mA above 30 mA' : 'Optimal Operating Parameters',
        'recommendedAction': 'x',
        'hasAnomaly': alarm,
      },
      if (alarm) 'report': {'id': 'SARI-SENS-01_20260927T080500', 'files': ['report.pdf', 'report.json', 'readings.csv']},
    };

void main() {
  test('analyze sends token and parses an alarm decision', () async {
    late http.Request sent;
    final api = ModelApiService(
      baseUrl: 'http://model',
      token: 'secret-token-123456',
      client: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode(_payload(alarm: true)), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    final decision = await api.analyze(MeasurementModel(
      deviceID: 'SARI-SENS-01',
      timestamp: DateTime(2026, 9, 27, 8, 5),
      current: 14.5,
      voltage: 220,
      leakage: 0.45,
      temperature: 32,
    ));
    expect(sent.headers['X-Model-Token'], 'secret-token-123456');
    expect(jsonDecode(sent.body)['leakage'], 0.45);
    expect(decision.cutoff, isTrue);
    expect(decision.faults, ['leakage']);
    expect(decision.result.riskLevel, 'CRITICAL');
    expect(decision.reportFiles.first, 'report.pdf');
  });

  test('analyze throws on rejected token', () async {
    final api = ModelApiService(baseUrl: 'http://model', token: 'bad', client: MockClient((_) async => http.Response('{}', 401)));
    expect(
      api.analyze(MeasurementModel(deviceID: 'D', timestamp: DateTime.now(), current: 1, voltage: 220, leakage: 0.02, temperature: 30)),
      throwsA(isA<ModelApiException>()),
    );
  });

  test('model alarm cuts power and files an incident report', () async {
    var resetCalls = 0;
    final api = ModelApiService(
      baseUrl: 'http://model',
      token: 't',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/reset')) {
          resetCalls++;
          return http.Response('{"cutoff": false}', 200);
        }
        return http.Response(jsonEncode(_payload(alarm: true)), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    final vm = AppStateViewModel(modelApi: api);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(vm.isPowerCut, isTrue);
    expect(vm.reports.first.reportID, 'SARI-SENS-01_20260927T080500');
    expect(vm.alerts.any((a) => a.type == 'Current Leakage Hazard'), isTrue);
    vm.restorePower();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(resetCalls, 1);
    vm.dispose();
  });

  test('normal model decision keeps power on', () async {
    final api = ModelApiService(
      baseUrl: 'http://model',
      token: 't',
      client: MockClient((_) async => http.Response(jsonEncode(_payload(alarm: false)), 200, headers: {'content-type': 'application/json; charset=utf-8'})),
    );
    final vm = AppStateViewModel(modelApi: api);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(vm.modelOnline, isTrue);
    expect(vm.isPowerCut, isFalse);
    expect(vm.aiRiskResult.riskLevel, 'LOW');
    vm.dispose();
  });
}
