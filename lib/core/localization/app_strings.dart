import 'package:flutter/material.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'SARI',
      'appSubtitle': 'Smart Electrical Risk Prevention Platform',
      'signIn': 'Sign In',
      'register': 'Register',
      'selectRole': 'Select Account Role',
      'email': 'Email Address',
      'password': 'Password',
      'accessDashboard': 'Access SARI Dashboard',
      'createAccount': 'Create Account',
      'quickDemo': 'Quick Demo Quick-Start:',

      // Navigation
      'navHome': 'Home',
      'navMonitoring': 'Monitoring',
      'navAiRisk': 'AI Risk',
      'navAlerts': 'Alerts',
      'navHeatmap': 'Heatmap',
      'navReports': 'Reports',
      'navDevices': 'Sensors',
      'navEmergency': 'Emergency',
      'navProfile': 'Profile',

      // Home Dashboard
      'welcomeBack': 'Welcome back',
      'safetyScoreTitle': 'Electrical Safety Score',
      'viewAiAnalysis': 'View AI Analysis',
      'realtimeTelemetry': 'Real-Time Telemetry',
      'currentStatus': 'Current Status',
      'voltage': 'Voltage',
      'leakageCurrent': 'Leakage Current',
      'connectedDevices': 'Connected Devices',
      'normal': 'NORMAL',
      'overcurrent': 'OVERCURRENT',
      'anomalySimulator': 'Live Anomaly Simulator Engine',
      'resetNormal': 'Reset Normal',
      'simulateSurge': 'Simulate Current Surge',
      'simulateDip': 'Simulate Voltage Dip',
      'simulateLeakage': 'Simulate Ground Fault',
      'activeAlerts': 'Active Safety Warnings',
      'viewAll': 'View All',
      'allSystemsNormal': 'All Electrical Systems Normal',
      'noActiveAlertsSub': 'No active safety warnings present in network.',
      'resolve': 'Resolve',
      'markResolved': 'Mark Resolved',

      // Live Monitoring
      'liveMonitoringTitle': 'Live Electrical Monitoring',
      'liveMonitoringSub': 'Real-time IoT Telemetry Engine',
      'currentTab': 'Current (A)',
      'voltageTab': 'Voltage (V)',
      'leakageTab': 'Leakage (mA)',
      'streamingHz': 'Streaming 1Hz',

      // AI Risk
      'aiEngineTitle': 'AI Predictive Risk Engine',
      'aiEngineSub': 'Neural Pattern & Failure Anomaly Detection',
      'aiAnalysisResult': 'AI ANALYSIS RESULT',
      'riskLevel': 'RISK LEVEL',
      'cause': 'Identified Cause:',
      'probability': 'Failure Probability:',
      'recommendedAction': 'Recommended Action',
      'predictiveModels': 'Predictive Failure Risk Models',

      // Heatmap
      'heatmapTitle': 'Spatial Risk Heatmap',
      'heatmapSub': 'Facility & Circuit Safety Geography',
      'safe': 'Safe',
      'warning': 'Warning',
      'criticalRisk': 'Critical Risk',

      // Reports
      'reportsTitle': 'Safety & Audit Reports',
      'reportsSub': 'Daily & Monthly Infrastructure Analytics',
      'exportPdf': 'Export PDF',
      'dailyTab': 'Daily Summary',
      'monthlyTab': 'Monthly Safety Report',

      // Devices
      'devicesTitle': 'Device & Sensor Management',
      'addSensor': 'Add Sensor',
      'registerNewSensor': 'Register New SARI Sensor',
      'deviceName': 'Device Name',
      'location': 'Location / Installation Site',
      'circuitType': 'Circuit Type / Breaker Rating',
      'bindSensor': 'Bind & Calibrate Sensor',

      // Emergency Cutoff
      'emergencyControl': 'Emergency Power Control',
      'circuitsDeenergized': 'CIRCUITS DE-ENERGIZED',
      'relaysEnergized': 'SAFETY RELAYS ENERGIZED',
      'cutPowerNow': 'CUT POWER IMMEDIATELY',
      'restorePower': 'RESTORE FACILITY POWER',
      'confirmCutoff': 'CONFIRM POWER CUTOFF',
      'cutoffWarning': 'Are you sure you want to disengage all facility circuit relays?',
      'cancel': 'Cancel',
      'yesCutPower': 'YES, CUT POWER NOW',
      'cutoffNotAuthorized': 'Remote power control is limited to Facility Managers and Admins.',
      'authFailed': 'Sign in failed. Check your email and password.',

      // Profile & Settings
      'profileSettings': 'Profile & Settings',
      'switchRole': 'Switch Demo User Role',
      'switchRoleSub': 'Test different user role permissions & capabilities live:',
      'languageSelector': 'Select Application Language',
      'systemStatus': 'System Infrastructure Status',
      'logOut': 'Log Out of SARI',
      'english': 'English',
      'arabic': 'العربية (Arabic)',
      'powerOff': 'POWER OFF',
      'live': 'LIVE',
    },
    'ar': {
      'appTitle': 'ساري',
      'appSubtitle': 'المنصة الذكية للكشف والوقاية من المخاطر الكهربائية',
      'signIn': 'تسجيل الدخول',
      'register': 'إنشاء حساب جديد',
      'selectRole': 'اختر نوع الحساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'accessDashboard': 'الدخول لمنصة ساري',
      'createAccount': 'تأكيد إنشاء الحساب',
      'quickDemo': 'بدء سريع بحساب تجريبي:',

      // Navigation
      'navHome': 'الرئيسية',
      'navMonitoring': 'المراقبة',
      'navAiRisk': 'الذكاء',
      'navAlerts': 'التنبيهات',
      'navHeatmap': 'الخريطة',
      'navReports': 'التقارير',
      'navDevices': 'الحساسات',
      'navEmergency': 'طوارئ القطع',
      'navProfile': 'الحساب',

      // Home Dashboard
      'welcomeBack': 'مرحباً بك',
      'safetyScoreTitle': 'مؤشر السلامة الكهربائية',
      'viewAiAnalysis': 'عرض تحليل الذكاء الاصطناعي',
      'realtimeTelemetry': 'قراءات الحساسات المباشرة',
      'currentStatus': 'حالة التيار',
      'voltage': 'الجهد الكهربائي',
      'leakageCurrent': 'تسرب التيار الأرضي',
      'connectedDevices': 'الأجهزة المتصلة',
      'normal': 'طبيعي',
      'overcurrent': 'ارتفاع تيار حرج',
      'anomalySimulator': 'محاكي الأعطال المباشر',
      'resetNormal': 'إعادة الحالة الطبيعية',
      'simulateSurge': 'محاكاة ارتفاع التيار',
      'simulateDip': 'محاكاة انخفاض الجهد',
      'simulateLeakage': 'محاكاة تسرب أرضي',
      'activeAlerts': 'تنبيهات السلامة النشطة',
      'viewAll': 'عرض الكل',
      'allSystemsNormal': 'جميع الأنظمة الكهربائية تعمل بشكل آمن',
      'noActiveAlertsSub': 'لا توجد تحذيرات خطيرة حالية في الشبكة.',
      'resolve': 'معالجة',
      'markResolved': 'تأكيد المعالجة',

      // Live Monitoring
      'liveMonitoringTitle': 'المراقبة الكهربائية المباشرة',
      'liveMonitoringSub': 'محيط قراءات إنترنت الأشياء المباشرة',
      'currentTab': 'التيار (أمبير)',
      'voltageTab': 'الجهد (فولت)',
      'leakageTab': 'التسرب (ملي أمبير)',
      'streamingHz': 'بث حي 1 هرتز',

      // AI Risk
      'aiEngineTitle': 'محرك التنبؤ بالمخاطر بالذكاء الاصطناعي',
      'aiEngineSub': 'تحليل النماذج العصبية والكشف عن الأعطال',
      'aiAnalysisResult': 'نتيجة تحليل الذكاء الاصطناعي',
      'riskLevel': 'مستوى الخطر',
      'cause': 'السبب المكتشف:',
      'probability': 'احتمالية العطل:',
      'recommendedAction': 'الإجراء الموصى به',
      'predictiveModels': 'نماذج التنبؤ بالأعطال المستقبلية',

      // Heatmap
      'heatmapTitle': 'الخريطة الحرارية للمخاطر',
      'heatmapSub': 'التوزيع الجغرافي لسلامة الدوائر بالمنشأة',
      'safe': 'آمن',
      'warning': 'تحذير',
      'criticalRisk': 'خطر حرج',

      // Reports
      'reportsTitle': 'تقارير السلامة والتدقيق',
      'reportsSub': 'تحليلات البنية التحتية اليومية والشهرية',
      'exportPdf': 'تصدير PDF',
      'dailyTab': 'الملخص اليومي',
      'monthlyTab': 'التقرير الشهري',

      // Devices
      'devicesTitle': 'إدارة الأجهزة والحساسات',
      'addSensor': 'إضافة حساس',
      'registerNewSensor': 'ربط حساس ساري جديد',
      'deviceName': 'اسم الجهاز',
      'location': 'الموقع / مكان التركيب',
      'circuitType': 'نوع الدائرة / سعة القاطع',
      'bindSensor': 'ربط ومعايرة الحساس',

      // Emergency Cutoff
      'emergencyControl': 'تحكم الطوارئ بالتيار',
      'circuitsDeenergized': 'التيار مقطوع عن الدوائر',
      'relaysEnergized': 'قواطع السلامة متصلة',
      'cutPowerNow': 'قطع التيار فوراً',
      'restorePower': 'إعادة التيار للمنشأة',
      'confirmCutoff': 'تأكيد قطع التيار الكلي',
      'cutoffWarning': 'هل أنت أصلًا متأكد من فصل قواطع التيار عن المنشأة بالكامل؟',
      'cancel': 'إلغاء',
      'yesCutPower': 'نعم، اقطع التيار الآن',
      'cutoffNotAuthorized': 'التحكم بقطع التيار متاح لمدير المنشأة ومسؤول النظام فقط.',
      'authFailed': 'فشل تسجيل الدخول. تحقق من البريد وكلمة المرور.',

      // Profile & Settings
      'profileSettings': 'الملف الشخصي والإعدادات',
      'switchRole': 'تغيير نوع الحساب التجريبي',
      'switchRoleSub': 'تجربة صلاحيات ومميزات كل نوع حساب مباشر:',
      'languageSelector': 'اختيار لغة التطبيق',
      'systemStatus': 'حالة البنية التحتية للنظام',
      'logOut': 'تسجيل الخروج من ساري',
      'english': 'English (الإنجليزية)',
      'arabic': 'العربية',
      'powerOff': 'مقطوع',
      'live': 'مباشر',
    }
  };

  static String getString(String key, Locale locale) {
    final langCode = locale.languageCode == 'ar' ? 'ar' : 'en';
    return _localizedValues[langCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
