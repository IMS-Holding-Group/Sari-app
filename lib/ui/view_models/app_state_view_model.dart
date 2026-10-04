import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/device_model.dart';
import '../../data/models/measurement_model.dart';
import '../../data/models/alert_model.dart';
import '../../data/models/report_model.dart';
import '../../data/models/zone_model.dart';
import '../../data/services/telemetry_service.dart';
import '../../data/services/ai_risk_engine.dart';
import '../../data/services/model_api_service.dart';
import '../../core/localization/app_strings.dart';

class AppStateViewModel extends ChangeNotifier {
  final TelemetryService _telemetryService = TelemetryService();
  final ModelApiService _modelApi;
  StreamSubscription<MeasurementModel>? _subscription;

  bool _modelOnline = false;
  bool get modelOnline => _modelOnline;
  bool _modelBusy = false;
  String? _modelDeviceId;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    notifyListeners();
  }

  String tr(String key) => AppStrings.getString(key, _locale);

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  UserModel _currentUser = UserModel(
    userID: 'USR-8921',
    name: 'Yousef Rabia',
    email: 'yousef@sari-safety.io',
    role: UserRole.facilityManager,
    organizationID: 'ORG-SARI-EGYPT',
  );
  UserModel get currentUser => _currentUser;

  bool _isPowerCut = false;
  bool get isPowerCut => _isPowerCut;

  // Live telemetry state
  MeasurementModel _latestMeasurement = MeasurementModel(
    deviceID: 'SARI-SENS-01',
    timestamp: DateTime.now(),
    current: 14.5,
    voltage: 220.0,
    leakage: 0.02,
    temperature: 31.5,
  );
  MeasurementModel get latestMeasurement => _latestMeasurement;

  final List<MeasurementModel> _measurementHistory = [];
  List<MeasurementModel> get measurementHistory => List.unmodifiable(_measurementHistory);

  AIRiskAnalysisResult _aiRiskResult = AIRiskAnalysisResult(
    safetyScore: 92,
    riskLevel: 'LOW',
    riskType: 'No abnormal behavior detected',
    probability: 0.05,
    cause: 'Optimal Operating Parameters',
    recommendedAction: 'System operating normally. Continue scheduled monitoring.',
    hasAnomaly: false,
  );
  AIRiskAnalysisResult get aiRiskResult => _aiRiskResult;

  // Devices state
  List<DeviceModel> _devices = [
    DeviceModel(
      deviceID: 'SARI-SENS-01',
      name: 'Main Distribution Panel',
      userID: 'USR-8921',
      location: 'Ground Floor Utility Room',
      status: DeviceStatus.online,
      installationDate: DateTime.now().subtract(const Duration(days: 120)),
      batteryLevel: 99.0,
      circuitType: '3-Phase 380V / 220V',
    ),
    DeviceModel(
      deviceID: 'SARI-SENS-02',
      name: 'HVAC Compressor Sub-Panel',
      userID: 'USR-8921',
      location: 'Rooftop Plant Room',
      status: DeviceStatus.online,
      installationDate: DateTime.now().subtract(const Duration(days: 95)),
      batteryLevel: 94.0,
      circuitType: 'Single Phase 220V',
    ),
    DeviceModel(
      deviceID: 'SARI-SENS-03',
      name: 'Server Room UPS Breaker',
      userID: 'USR-8921',
      location: 'Floor 2 IT Bay',
      status: DeviceStatus.online,
      installationDate: DateTime.now().subtract(const Duration(days: 60)),
      batteryLevel: 100.0,
      circuitType: 'Critical Backup 220V',
    ),
    DeviceModel(
      deviceID: 'SARI-SENS-04',
      name: 'Factory Assembly Line #2',
      userID: 'USR-8921',
      location: 'Zone B Manufacturing',
      status: DeviceStatus.warning,
      installationDate: DateTime.now().subtract(const Duration(days: 45)),
      batteryLevel: 88.0,
      circuitType: 'Heavy Industrial Motor 380V',
    ),
  ];
  List<DeviceModel> get devices => List.unmodifiable(_devices);

  // Alerts state
  List<AlertModel> _alerts = [
    AlertModel(
      alertID: 'ALT-1092',
      deviceID: 'SARI-SENS-04',
      title: 'High Current Peak Detected',
      location: 'Zone B Manufacturing',
      type: 'Overcurrent Peak',
      severity: AlertSeverity.warning,
      timestamp: DateTime.now().subtract(const Duration(minutes: 24)),
      status: AlertStatus.active,
      recommendedAction: 'Inspect assembly motor bearing for thermal friction overload.',
      probability: 0.84,
    ),
    AlertModel(
      alertID: 'ALT-1088',
      deviceID: 'SARI-SENS-01',
      title: 'Transient Voltage Dip',
      location: 'Ground Floor Utility Room',
      type: 'Voltage Fluctuation',
      severity: AlertSeverity.info,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      status: AlertStatus.resolved,
      recommendedAction: 'Logged grid stabilization event.',
      probability: 0.62,
    ),
  ];
  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  // Heatmap Zones state
  List<ZoneModel> _zones = [
    ZoneModel(
      zoneID: 'ZONE-F1-A',
      name: 'Main Entrance & Lobby',
      floor: 'Floor 1',
      riskLevel: ZoneRiskLevel.safe,
      currentLoad: 12.4,
      voltage: 220.5,
      leakageCurrent: 0.015,
      activeSensors: 3,
      details: 'All circuits nominal. Grounding path verified.',
    ),
    ZoneModel(
      zoneID: 'ZONE-F1-B',
      name: 'Server Room & Data Bay',
      floor: 'Floor 1',
      riskLevel: ZoneRiskLevel.warning,
      currentLoad: 28.1,
      voltage: 218.0,
      leakageCurrent: 0.048,
      activeSensors: 4,
      details: 'Elevated thermal load on UPS bypass relay.',
    ),
    ZoneModel(
      zoneID: 'ZONE-F2-A',
      name: 'Executive Offices',
      floor: 'Floor 2',
      riskLevel: ZoneRiskLevel.safe,
      currentLoad: 8.2,
      voltage: 221.0,
      leakageCurrent: 0.011,
      activeSensors: 2,
      details: 'Lighting & desktop power lines balanced.',
    ),
    ZoneModel(
      zoneID: 'ZONE-PLANT-B',
      name: 'Industrial Assembly Line B',
      floor: 'Ground Factory',
      riskLevel: ZoneRiskLevel.critical,
      currentLoad: 46.8,
      voltage: 209.2,
      leakageCurrent: 0.185,
      activeSensors: 6,
      details: 'High current surge & potential leakage detected on motor feeder.',
    ),
  ];
  List<ZoneModel> get zones => List.unmodifiable(_zones);

  // Reports state
  List<ReportModel> _reports = [
    ReportModel(
      reportID: 'REP-2026-09-20',
      organizationID: 'ORG-SARI-EGYPT',
      title: 'Daily Electrical Safety Summary',
      date: DateTime.now(),
      riskScore: 92,
      eventsCount: 3,
      peakCurrent: 34.2,
      avoidedIncidents: 2,
      summaryHighlights: [
        'Prevented 1 potential electrical fire via early arc warning.',
        'Total facility power consumption remained within 85% peak envelope.',
        '0 trip outages experienced today.',
      ],
    ),
    ReportModel(
      reportID: 'REP-2026-08-31',
      organizationID: 'ORG-SARI-EGYPT',
      title: 'August Monthly Infrastructure Audit',
      date: DateTime.now().subtract(const Duration(days: 20)),
      riskScore: 89,
      eventsCount: 14,
      peakCurrent: 44.8,
      avoidedIncidents: 6,
      summaryHighlights: [
        'Successfully isolated 2 ground fault leakage paths in Factory Line B.',
        'Scheduled preventative maintenance saved estimated \$18,500 in motor downtime.',
      ],
    ),
  ];
  List<ReportModel> get reports => List.unmodifiable(_reports);

  AppStateViewModel({ModelApiService? modelApi}) : _modelApi = modelApi ?? ModelApiService() {
    _initTelemetry();
  }

  void _initTelemetry() {
    _telemetryService.start();
    _subscription = _telemetryService.telemetryStream.listen((m) {
      if (_isPowerCut) {
        _latestMeasurement = MeasurementModel(
          deviceID: m.deviceID,
          timestamp: m.timestamp,
          current: 0.0,
          voltage: 0.0,
          leakage: 0.0,
          temperature: m.temperature,
        );
      } else {
        _latestMeasurement = m;
      }

      _measurementHistory.add(_latestMeasurement);
      if (_measurementHistory.length > 30) {
        _measurementHistory.removeAt(0);
      }

      if (!_isPowerCut) _analyzeWithModel(_latestMeasurement);
      if (_modelOnline && !_isPowerCut) {
        notifyListeners();
        return;
      }

      _aiRiskResult = AIRiskEngine.analyze(_latestMeasurement);

      // If AI detects anomaly and no active alert exists for it, add alert
      if (_aiRiskResult.hasAnomaly && !_isPowerCut) {
        final existingActive = _alerts.any(
          (a) => a.status == AlertStatus.active && a.type == _aiRiskResult.riskType,
        );
        if (!existingActive) {
          _alerts.insert(
            0,
            AlertModel(
              alertID: 'ALT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              deviceID: _latestMeasurement.deviceID,
              title: _aiRiskResult.riskType,
              location: 'Main Distribution Panel',
              type: _aiRiskResult.riskType,
              severity: _aiRiskResult.riskLevel == 'CRITICAL'
                  ? AlertSeverity.critical
                  : AlertSeverity.warning,
              timestamp: DateTime.now(),
              status: AlertStatus.active,
              recommendedAction: _aiRiskResult.recommendedAction,
              probability: _aiRiskResult.probability,
            ),
          );
        }
      }

      notifyListeners();
    });
  }

  Future<void> _analyzeWithModel(MeasurementModel m) async {
    if (_modelBusy) return;
    _modelBusy = true;
    try {
      final decision = await _modelApi.analyze(m);
      _modelOnline = true;
      _modelDeviceId = m.deviceID;
      if (_isPowerCut) return;
      _aiRiskResult = decision.result;
      if (decision.alarm) _raiseModelAlarm(decision, m);
      notifyListeners();
    } catch (e) {
      if (_modelOnline) debugPrint('[AppStateViewModel] model offline, using rule engine: $e');
      _modelOnline = false;
    } finally {
      _modelBusy = false;
    }
  }

  void _raiseModelAlarm(ModelDecision decision, MeasurementModel m) {
    final result = decision.result;
    final existingActive = _alerts.any(
      (a) => a.status == AlertStatus.active && a.type == result.riskType,
    );
    if (!existingActive) {
      _alerts.insert(
        0,
        AlertModel(
          alertID: 'ALT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          deviceID: m.deviceID,
          title: result.riskType,
          location: 'Main Distribution Panel',
          type: result.riskType,
          severity: result.riskLevel == 'CRITICAL' ? AlertSeverity.critical : AlertSeverity.warning,
          timestamp: m.timestamp,
          status: AlertStatus.active,
          recommendedAction: result.recommendedAction,
          probability: result.probability,
        ),
      );
    }
    final reportId = decision.reportId;
    if (reportId != null && !_reports.any((r) => r.reportID == reportId)) {
      _reports.insert(
        0,
        ReportModel(
          reportID: reportId,
          organizationID: _currentUser.organizationID,
          title: 'Incident Report: ${result.riskType}',
          date: m.timestamp,
          riskScore: result.safetyScore,
          eventsCount: decision.faults.length,
          peakCurrent: _measurementHistory.fold<double>(0, (p, e) => e.current > p ? e.current : p),
          avoidedIncidents: 1,
          summaryHighlights: [
            'وقت الخلل: \u2066${decision.timeDisplay}\u2069',
            result.cause,
            result.recommendedAction,
            ...decision.reportFiles.map((f) => _modelApi.reportUri(reportId, f).toString()),
          ],
        ),
      );
    }
    if (decision.cutoff && !_isPowerCut) cutPower(notifyModel: false);
  }

  // Auth & Role methods
  /// Returns false when Firebase rejects the credentials; demo mode is used only when the backend is unavailable.
  Future<bool> login(String email, String password, UserRole role, {bool isSignUp = false}) async {
    try {
      if (isSignUp) {
        await FirebaseService.createUserWithEmailAndPassword(email, password);
      } else {
        await FirebaseService.signInWithEmailAndPassword(email, password);
      }
    } catch (e) {
      if (FirebaseService.isCredentialError(e)) {
        debugPrint('[AppStateViewModel] sign in refused');
        return false;
      }
      debugPrint('[AppStateViewModel] auth backend unavailable, demo session: $e');
    }

    _isLoggedIn = true;
    _currentUser = UserModel(
      userID: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      name: email.contains('@') ? email.split('@').first.toUpperCase() : 'USER',
      email: email,
      role: role,
      organizationID: 'ORG-SARI-GLOBAL',
    );
    notifyListeners();
    return true;
  }

  void switchRole(UserRole newRole) {
    _currentUser = UserModel(
      userID: _currentUser.userID,
      name: _currentUser.name,
      email: _currentUser.email,
      role: newRole,
      organizationID: _currentUser.organizationID,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseService.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  // Emergency Cutoff methods
  bool get canCutPower => _currentUser.role != UserRole.residential;

  void cutPower({bool notifyModel = true}) {
    if (notifyModel) _modelApi.cutoff(_modelDeviceId ?? _latestMeasurement.deviceID);
    _isPowerCut = true;
    _latestMeasurement = MeasurementModel(
      deviceID: 'SARI-MAIN-DISCONNECT',
      timestamp: DateTime.now(),
      current: 0.0,
      voltage: 0.0,
      leakage: 0.0,
      temperature: _latestMeasurement.temperature,
    );
    _alerts.insert(
      0,
      AlertModel(
        alertID: 'ALT-EMERGENCY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        deviceID: 'SARI-MAIN-DISCONNECT',
        title: 'EMERGENCY POWER SHUTDOWN ACTIVATED',
        location: 'Facility Wide',
        type: 'Remote Circuit Cutoff',
        severity: AlertSeverity.critical,
        timestamp: DateTime.now(),
        status: AlertStatus.active,
        recommendedAction: 'Main breaker disengaged. Ensure safe circuit status before re-energizing.',
        probability: 1.0,
      ),
    );
    notifyListeners();
  }

  void restorePower() {
    _isPowerCut = false;
    final deviceId = _modelDeviceId;
    if (deviceId != null) _modelApi.reset(deviceId);
    _telemetryService.resetToNormal();
    notifyListeners();
  }

  // Anomaly simulation methods for interactive testing
  void simulateOvercurrentSurge() {
    _telemetryService.triggerOvercurrentSurge();
  }

  void simulateVoltageDrop() {
    _telemetryService.triggerVoltageDrop();
  }

  void simulateLeakageFault() {
    _telemetryService.triggerGroundLeakageFault();
  }

  void resetSimulation() {
    _telemetryService.resetToNormal();
  }

  // Alert management
  void resolveAlert(String alertID) {
    final index = _alerts.indexWhere((a) => a.alertID == alertID);
    if (index != -1) {
      final old = _alerts[index];
      _alerts[index] = AlertModel(
        alertID: old.alertID,
        deviceID: old.deviceID,
        title: old.title,
        location: old.location,
        type: old.type,
        severity: old.severity,
        timestamp: old.timestamp,
        status: AlertStatus.resolved,
        recommendedAction: old.recommendedAction,
        probability: old.probability,
      );
      notifyListeners();
    }
  }

  // Device management
  void addDevice(DeviceModel newDevice) {
    _devices.add(newDevice);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _telemetryService.dispose();
    _modelApi.dispose();
    super.dispose();
  }
}
