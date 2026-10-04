import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/measurement_model.dart';
import 'ai_risk_engine.dart';

class ModelApiException implements Exception {
  final int statusCode;
  ModelApiException(this.statusCode);

  @override
  String toString() => 'ModelApiException($statusCode)';
}

class ModelDecision {
  final AIRiskAnalysisResult result;
  final bool alarm;
  final bool cutoff;
  final bool warning;
  final List<String> faults;
  final String timeDisplay;
  final String? reportId;
  final List<String> reportFiles;

  ModelDecision({
    required this.result,
    required this.alarm,
    required this.cutoff,
    required this.warning,
    required this.faults,
    required this.timeDisplay,
    required this.reportId,
    required this.reportFiles,
  });

  factory ModelDecision.fromJson(Map<String, dynamic> json) {
    final r = json['result'] as Map<String, dynamic>;
    final report = json['report'] as Map<String, dynamic>?;
    return ModelDecision(
      result: AIRiskAnalysisResult(
        safetyScore: (r['safetyScore'] as num).toInt(),
        riskLevel: r['riskLevel'] as String,
        riskType: r['riskType'] as String,
        probability: (r['probability'] as num).toDouble(),
        cause: r['cause'] as String,
        recommendedAction: r['recommendedAction'] as String,
        hasAnomaly: r['hasAnomaly'] == true,
      ),
      alarm: json['alarm'] == true,
      cutoff: json['cutoff'] == true,
      warning: json['warning'] == true,
      faults: List<String>.from(json['faults'] as List? ?? const []),
      timeDisplay: json['time_display'] as String? ?? '',
      reportId: report?['id'] as String?,
      reportFiles: List<String>.from(report?['files'] as List? ?? const []),
    );
  }
}

class ModelApiService {
  static const String _definedBaseUrl = String.fromEnvironment('SARI_MODEL_URL');
  static const String defaultToken = String.fromEnvironment('SARI_MODEL_TOKEN');

  /// Android emulators reach the host machine through 10.0.2.2, everything else uses loopback.
  static String get defaultBaseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
    return 'http://127.0.0.1:8080';
  }

  final http.Client _client;
  final String baseUrl;
  final String token;

  ModelApiService({http.Client? client, String? baseUrl, String? token})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl,
        token = token ?? defaultToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Model-Token': token,
      };

  Future<ModelDecision> analyze(MeasurementModel m) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/v1/reading'),
          headers: _headers,
          body: jsonEncode({
            'device_id': m.deviceID,
            'timestamp': m.timestamp.toIso8601String(),
            'current': m.current,
            'voltage': m.voltage,
            'leakage': m.leakage,
            'temperature': m.temperature,
          }),
        )
        .timeout(const Duration(seconds: 2));
    if (response.statusCode != 200) throw ModelApiException(response.statusCode);
    return ModelDecision.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<bool> reset(String deviceId) => _command(deviceId, 'reset');

  /// Latches a manual cutoff on the model server so the hardware relay trips on its next poll.
  Future<bool> cutoff(String deviceId) => _command(deviceId, 'cutoff');

  Future<bool> _command(String deviceId, String action) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/v1/devices/$deviceId/$action'), headers: _headers)
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ModelApiService] $action failed: $e');
      return false;
    }
  }

  Uri reportUri(String reportId, String file) => Uri.parse('$baseUrl/v1/reports/$reportId/$file');

  void dispose() => _client.close();
}
