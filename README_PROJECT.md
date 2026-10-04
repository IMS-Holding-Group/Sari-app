# SARI (ساري) — الوثيقة الرئيسية للمشروع

هذه الوثيقة تصف المشروع كما هو في الكود والملفات بتاريخ 2026/9/27م. أي شيء غير موجود في الملفات مذكور صراحة أنه غير موجود أو غير موثق. لا تُستبدل هذه الوثيقة بملف `README.md` الإنجليزي الموجود أصلًا؛ ذلك الملف بقي كما هو.

---

# الجزء الأول — التعريف والفهم العام

## 1. ما هو المشروع؟

SARI تطبيق جوّال لمراقبة السلامة الكهربائية. يعرض قراءات التيار والجهد والتسرب الأرضي ودرجة الحرارة، ويقدّر خطرًا كهربائيًا، ويعرض تنبيهات وتقارير، ويستطيع طلب قطع التيار عند تأكيد خطر.

التطبيق مبني بـ Flutter. بجانبه سيرفر Python اسمه `live_model` يشغّل نموذج LSTM، وملف Arduino لجهاز ESP32 يرسل القراءات ويستقبل أمر القطع.

ما يظهر داخل التطبيق اليوم (الأجهزة، المناطق، معظم التنبيهات والتقارير) بيانات تجريبية ثابتة في الذاكرة. القراءات الحية تُولَّد داخل التطبيق كل ثانية بمحاكي، ثم تُرسل إلى سيرفر النموذج إذا كان يعمل.

## 2. لماذا يوجد هذا المشروع؟

وثيقة المتطلبات `SARI_Product_Requirement_Document.md` تصف الهدف: تحويل الحماية الكهربائية من رد فعل بعد العطل إلى مراقبة مستمرة وتنبؤ قبل وقوع قصر أو تسرب أو حمل زائد. هذا هدف الوثيقة، وليس إثباتًا أن النظام يحقق ذلك كاملًا في التشغيل الحالي.

ما هو مُنفَّذ فعليًا:

- محاكاة قراءات كهربائية داخل التطبيق (`TelemetryService`).
- تحليل محلي بحدود ثابتة إذا كان السيرفر غير متاح (`AIRiskEngine`).
- نموذج LSTM على السيرفر يقرر الإنذار والقطع بعد تأكيد 3 عينات وتجاوز حد فيزيائي (`AlarmPolicy` في `live_model/model.py`).
- رسم تقرير PDF/JSON/CSV عند أول إنذار مؤكد (`live_model/reports.py`).
- برنامج ESP32 يقطع محليًا عند قصر أو تسرب عالٍ، ويطلب القطع من السيرفر (`live_model/iot/sari_esp32/sari_esp32.ino`).

## 3. من يستخدمه؟

ثلاثة أدوار معرفة في `lib/data/models/user_model.dart` داخل `enum UserRole`:

| الدور في الكود | الاسم المعروض | ما يميّزه فعليًا |
|---|---|---|
| `residential` | Residential User | يشاهد الشاشات. زر قطع التيار وإعادته معطّلان. |
| `facilityManager` | Facility Manager | يستطيع قطع التيار وإعادته بعد تأكيد. |
| `admin` | System Admin | نفس صلاحية القطع كمدير المنشأة. لا توجد شاشة إدارة مستخدمين منفصلة. |

الدور يُختار من شاشة الدخول أو من "Switch Demo User Role" في الملف الشخصي. لا يُحفظ في قاعدة بيانات ولا يُفرض من السيرفر. السيرفر لا يعرف دور المستخدم أصلًا؛ أي طلب يحمل التوكن الصحيح يُقبل.

عند أول تشغيل يكون المستخدم غير مسجّل (`_isLoggedIn = false` في `AppStateViewModel`) وتظهر شاشة الدخول.

## 4. ماذا يستطيع النظام أن يفعل؟

الموجود ويعمل داخل التطبيق (بياناته محلية في الذاكرة ما لم يُذكر غير ذلك):

| الوحدة | ماذا تفعل | أين |
|---|---|---|
| الدخول والتسجيل | بريد وكلمة مرور ودور. Firebase Auth إن كان متاحًا، وإلا جلسة تجريبية إذا فشل الاتصال بالخلفية. | `LoginScreen` |
| الرئيسية | درجة سلامة، أربع قراءات، محاكي أعطال، تنبيهات نشطة. | `HomeDashboardScreen` |
| المراقبة | رسم تيار أو جهد أو تسرب لآخر 30 قراءة. | `LiveMonitoringScreen` |
| تحليل الخطر | نتيجة التحليل: المستوى، السبب، الاحتمال، الإجراء. | `AIRiskDetectionScreen` |
| التنبيهات | قائمة مع فلاتر، وزر تعليم التنبيه محلولًا. | `AlertsCenterScreen` |
| الخريطة الحرارية | أربع مناطق ثابتة، والضغط يعرض تفاصيل المنطقة. | `RiskHeatmapScreen` |
| التقارير | بطاقتان ثابتتان (يومي وشهري) وزر تصدير يعرض رسالة فقط. | `ReportsScreen` |
| الأجهزة | أربعة حساسات ثابتة، وإضافة حساس تبقى في الذاكرة حتى إغلاق التطبيق. | `DeviceManagementScreen` |
| الطوارئ | قطع يدوي بتأكيد، وإعادة التيار، حسب الدور. | `EmergencyControlScreen` |
| الملف الشخصي | لغة، تبديل دور تجريبي، صفوف حالة مكتوبة نصًا، خروج. | `ProfileScreen` |
| اللغة | إنجليزي وعربي مع اتجاه RTL. | `AppStrings` |

الموجود في السيرفر `live_model/server.py`:

- استقبال قراءة وتصنيفها بالنموذج.
- إنذار وقطع تلقائي وتقرير ملفات.
- قطع يدوي وأمر للجهاز وإعادة ضبط.

الموجود في العتاد: ملف `.ino` واحد. لا يوجد في هذا المستودع دليل على أنه رُفع على لوحة حقيقية.

## 5. كيف يعمل النظام؟

```text
قراءة (محاكي التطبيق أو ESP32)
        |
        v
POST /v1/reading  +  ترويسة X-Model-Token
        |
        v
نافذة 120 قراءة -> ميزات -> SariLSTM
        |
        v
AlarmPolicy: احتمال >= العتبة لثلاث عينات متتالية
             والقراءة تجاوزت الحد الفيزيائي
        |
        +-- لا: درجة سلامة LOW أو تحذير مبكر
        |
        +-- نعم: إنذار، قطع، ملفات تقرير، حالة القطع تبقى حتى reset
```

إذا تعذر الاتصال بالسيرفر خلال ثانيتين، التطبيق يستخدم `AIRiskEngine.analyze` (حدود ثابتة على التيار والتسرب والجهد) ولا يرسل أمر قطع للسيرفر.

## 6. أمثلة واقعية مبنية على الوظائف الموجودة

### مثال 1 — تسجيل الدخول

1. المستخدم يفتح التطبيق فيرى `LoginScreen` لأن `isLoggedIn` يبدأ `false`.
2. يكتب بريدًا وكلمة مرور ويختار دورًا ويضغط "Access SARI Dashboard".
3. `AppStateViewModel.login` يستدعي `FirebaseService.signInWithEmailAndPassword`.
4. إذا رفض Firebase البيانات (`FirebaseAuthException` ليست من أعطال الشبكة أو الإعداد)، الدالة ترجع `false` وتظهر رسالة `authFailed`. لا تُفتح اللوحة.
5. إذا نجح Firebase، أو كانت الخلفية غير متاحة (`network-request-failed` وما شابه في `_backendUnavailableCodes`)، تُفتح اللوحة بجلسة محلية. الاسم يُشتق من جزء البريد قبل `@`.
6. `GoRouter` في `app_router.dart` يحوّل من `/login` إلى `/app/home`.

### مثال 2 — محاكاة ارتفاع تيار وقطع تلقائي

1. من الرئيسية يضغط "Simulate Current Surge".
2. `TelemetryService` يرفع التيار إلى نحو 48.5–52.5 أمبير كل ثانية، والجهاز في القراءة هو دائمًا `SARI-SENS-01`.
3. كل قراءة تذهب إلى `ModelApiService.analyze` ثم `POST /v1/reading`.
4. بعد امتلاء نافذة 120 قراءة وتأكيد النموذج (3 عينات فوق العتبة والتيار فوق حد الحمل)، السيرفر يرجع `alarm: true` و`cutoff: true`.
5. `_raiseModelAlarm` يضيف تنبيهًا وتقرير حادثة ويستدعي `cutPower(notifyModel: false)` لأن القطع أصلًا قادم من النموذج.
6. الشريط العلوي يصبح POWER OFF والقراءات المعروضة تصير صفرًا (التيار والجهد والتسرب؛ الحرارة تبقى).
7. السيرفر يكتب مجلد تقرير عند أول صعود للإنذار.

هذا المسار اُختبر على المحاكي مع السيرفر المحلي: إنذار `overcurrent` ظهر في سجل السيرفر.

### مثال 3 — قطع يدوي من شاشة الطوارئ

1. مستخدم بدور `facilityManager` أو `admin` يفتح `/emergency`.
2. يضغط "CUT POWER IMMEDIATELY" فيظهر حوار تأكيد.
3. التأكيد يستدعي `cutPower()`. هذه تستدعي `ModelApiService.cutoff` أي `POST /v1/devices/<id>/cutoff`.
4. السيرفر يضع `manual_cutoff = True`. طلب `GET /v1/devices/<id>/command` يرجع `cutoff: true` حتى يأتي `reset`.
5. "RESTORE FACILITY POWER" تستدعي `restorePower()` ثم `POST .../reset`، فيُحذف جهاز الحالة من ذاكرة السيرفر.

مستخدم `residential` يرى الزر معطّلًا والنص `cutoffNotAuthorized`.

### مثال 4 — إضافة حساس

1. من شاشة الأجهزة يضغط "Add Sensor".
2. نموذج فيه اسم وموقع ونوع دائرة (قيم افتراضية مكتوبة في الشاشة).
3. "Bind & Calibrate Sensor" ينشئ `DeviceModel` بمعرّف `SARI-SENS-` متبوعًا بجزء من الوقت، ويضيفه إلى قائمة `_devices` في الذاكرة.
4. لا يُرسل شيء إلى Firebase ولا إلى `devices.json` في السيرفر. بعد إغلاق التطبيق تختفي الإضافة.

### مثال 5 — تعليم تنبيه محلولًا

1. من التنبيهات أو من بطاقة الرئيسية يضغط Resolve / Mark Resolved.
2. `resolveAlert` يستبدل حالة ذلك التنبيه إلى `AlertStatus.resolved` داخل القائمة في الذاكرة.
3. لا يُحذف التنبيه ولا يُكتب في قاعدة.

## 7. رحلة المستخدم

```text
فتح التطبيق
  -> FirebaseService.initialize (نجاح أو تأجيل مسجّل في debugPrint)
  -> /login لأن isLoggedIn = false
  -> إدخال بريد وكلمة مرور ودور
  -> نجاح Firebase أو جلسة تجريبية عند تعذر الخلفية
  -> /app/home
  -> شريط سفلي: الرئيسية، المراقبة، الذكاء، التنبيهات، الخريطة، التقارير
  -> أزرار علوية: لغة، طوارئ، حساسات، ملف شخصي
  -> عملية (محاكاة، حل تنبيه، إضافة حساس، قطع)
  -> التغيير يبقى في ذاكرة AppStateViewModel فقط
  -> Log Out يعيد isLoggedIn إلى false ويعود إلى /login
```

لا توجد خطوة "حفظ" دائمة إلا ملفات التقرير التي يكتبها السيرفر على قرصه عند الإنذار.

## 8. الوحدات والأقسام

### الدخول — `lib/ui/views/auth/login_screen.dart`

وظيفة: بوابة قبل اللوحة. المستخدم يبدّل Sign In / Register، يختار دورًا، يكتب البريد وكلمة المرور. أزرار Facility Manager و Residential و Admin تملأ البريد والدور فقط ولا تسجّل الدخول وحدها. الخروج من هذه الشاشة يتم عبر `login()` الناجحة ثم تحويل الراوتر.

### الرئيسية — `home_dashboard_screen.dart`

وظيفة: نظرة سريعة. درجة من `aiRiskResult.safetyScore`، أربع بطاقات (حالة التيار، الجهد، التسرب، عدد الأجهزة)، محاكي، قائمة التنبيهات النشطة. الضغط على الجرس يذهب إلى `/app/alerts`. لا توجد علاقة حسابية بين المناطق في الخريطة وهذه البطاقات.

### المراقبة — `live_monitoring_screen.dart`

وظيفة: رسم `fl_chart` لآخر القراءات المخزنة (الحد 30 في `AppStateViewModel`). تبويبات تيار وجهد وتسرب. الجهاز المعروض في العنوان هو جهاز آخر قراءة، والمحاكي يثبت الجهاز على `SARI-SENS-01`. قائمة "Connected Devices" أسفل الشاشة تعرض `state.devices` ولا تغيّر مصدر الرسم.

### تحليل الخطر — `ai_risk_detection_screen.dart`

وظيفة: عرض `AIRiskAnalysisResult` القادمة من النموذج أو من المحرك المحلي. تحتها ثلاث بطاقات ("Arc Fault Pattern Engine" و"Insulation Degradation Predictor" و"Motor Thermal Overload Classifier") بنصوص ونسب ثابتة في الكود (96 و 91 و 94). هذه النسب ليست مخرجات النموذج.

### التنبيهات — `alerts_center_screen.dart`

وظيفة: فلترة `state.alerts` حسب ALL / ACTIVE / CRITICAL / WARNING / INFO / RESOLVED، وعرض الوقت بصيغة `SariDate`، وحل التنبيه. التنبيهان الأولان (`ALT-1092` و `ALT-1088`) مزروعان في `AppStateViewModel`. التنبيهات الجديدة تُضاف عند شذوذ المحرك المحلي أو عند إنذار النموذج.

### الخريطة — `risk_heatmap_screen.dart`

وظيفة: شبكة من `ZoneModel`. أربع مناطق مزروعة (لوبي، غرفة خوادم، مكاتب، خط تجميع) بمستويات safe / warning / critical. الضغط يفتح لوحة تفاصيل. لا تتغير المناطق مع القراءات الحية.

### التقارير — `reports_screen.dart`

وظيفة: عرض `state.reports`. تقريران مزروعان. التبويبان Daily و Monthly لا يغيّران القائمة (لا يوجد فلتر مربوط بهما). زر Export PDF يعرض `SnackBar` بالنص `Exported "..." to PDF & CSV` ولا ينشئ ملفًا. تقرير حادثة النموذج، إن وُجد، يُدرج في نفس القائمة ونصوصه قد تحتوي روابط HTTP لملفات السيرفر، دون زر تحميل داخل التطبيق.

### الأجهزة — `device_management_screen.dart`

وظيفة: عرض الحساسات وإضافة واحد في الذاكرة. لا حذف ولا تعديل ولا ربط فعلي بمعايرة.

### الطوارئ — `emergency_control_screen.dart`

وظيفة: قطع وإعادة حسب `canCutPower`. إرشادات الطوارئ الثلاثة نص إنجليزي ثابت غير مترجم.

### الملف الشخصي — `profile_screen.dart`

وظيفة: عرض المستخدم، تبديل اللغة، تبديل الدور، الخروج. صندوق "System Infrastructure Status" يعرض أربع جمل ثابتة: Firebase Auth Connected، Firestore Active، Messaging Online، Telemetry 1Hz. الثلاث الأولى لا تُقرأ من حالة حقيقية. سطر القياس 1Hz يطابق مؤقت `TelemetryService` (كل ثانية) لكنه ليس فحصًا حيًا.

### الحالة العامة — `lib/ui/view_models/app_state_view_model.dart`

تجمع المستخدم والقراءات والتنبيهات والأجهزة والمناطق والتقارير وقطع التيار واللغة، وتستمع لمحاكي القياس وتستدعي النموذج.

### السيرفر — `live_model/server.py`

يستقبل القراءات ويشغّل النموذج ويكتب التقارير.

### التدريب — `live_model/train.py` و `live_model/sim.py`

يبنيان بيانات تدريب من ملفات خارج المستودع، يدرّبان `SariLSTM`، ويكتبان `sari_lstm.pt` و `sari_config.json` و `metrics.json`.

### العتاد — `live_model/iot/sari_esp32/sari_esp32.ino`

يرسل قراءة كل ثانية تقريبًا ويقطع الريلاي عند أمر السيرفر أو عند حد محلي.

## 9. الشركات والكيانات

غير موجود كنظام متعدد الشركات.

`UserModel.organizationID` حقل نصي. القيمة الابتدائية في الكود `ORG-SARI-EGYPT`، وبعد `login()` تصبح `ORG-SARI-GLOBAL`. لا توجد شاشة شركات ولا عزل بيانات بين منظمات. تقارير النموذج لا تحمل معرّف منظمة.

## 10. الصلاحيات

المعنى هنا: الدور المختار في الجلسة المحلية فقط.

| القدرة | residential | facilityManager | admin |
|---|---|---|---|
| مشاهدة كل الشاشات | نعم | نعم | نعم |
| محاكي الأعطال | نعم | نعم | نعم |
| إضافة حساس في الذاكرة | نعم | نعم | نعم |
| حل تنبيه | نعم | نعم | نعم |
| قطع التيار وإعادته | لا | نعم | نعم |
| إدارة مستخدمين أو حساسات على السيرفر | لا | لا | لا |

التحقق على السيرفر مختلف: ترويسة `X-Model-Token` تُقارن بـ `hmac.compare_digest` مع `MODEL_TOKEN`. لا أدوار هناك.

## 11. الأتمتة و Workflows

لا يوجد محرك سير عمل ولا طوابير ولا مهام مجدولة.

الأتمتة الموجودة:

1. مؤقت Flutter كل ثانية يولّد قراءة (`TelemetryService.start`).
2. عند كل قراءة، محاولة تحليل عبر النموذج (`_analyzeWithModel`). إن كان طلب سابق لم ينتهِ تُتخطى القراءة (`_modelBusy`).
3. على السيرفر: ثلاث عينات متتالية فوق العتبة مع تجاوز الحد، ثم إنذار وملفات تقرير و`cutoff` يبقى حتى `reset`.
4. تحذير مبكر إذا احتمال ما قبل العطل `prefault` بلغ `tau_pre` لخمس عينات (`WARN_CONFIRM`) ولم يُقفل إنذار. القيمة المحفوظة حاليًا `tau_pre = 1.01`، أي أعلى من أي احتمال، فالتحذير المبكر لا يشتغل بالإعداد الحالي.
5. ESP32: قطع محلي إذا التيار >= 200 أمبير أو التسرب >= 0.3 أمبير، وقطع إذا رد السيرفر `"cutoff":true`. إذا انقطع الاتصال أكثر من 15 ثانية يطبع سطرًا على Serial ويكتفي بالحدود المحلية.

## 12. التكامل بين الوحدات

| الحدث | ماذا يتغير أيضًا |
|---|---|
| قراءة جديدة من المحاكي | `_latestMeasurement`، آخر 30 نقطة في الرسم، وإما نتيجة النموذج أو نتيجة `AIRiskEngine`. |
| إنذار نموذج `alarm` | تنبيه جديد إن لم يوجد تنبيه نشط بنفس `riskType`، تقرير في القائمة إن رجع `report.id`، و`cutPower` إن كان `cutoff`. |
| `cutPower` | القراءات المعروضة تصير صفرًا، شريط أحمر، تنبيه EMERGENCY، وعلى السيرفر `manual_cutoff` إذا كان القطع من الواجهة. |
| `restorePower` | يُلغى القطع محليًا، يُرسل reset للجهاز الأخير الذي حلله النموذج، ويُصفَّر المحاكي إلى الوضع الطبيعي. لا يحل التنبيهات المفتوحة. |
| حل تنبيه | حالة ذلك التنبيه فقط. |
| إضافة جهاز | قائمة الأجهزة وعداد "Connected Devices". لا يغيّر مصدر القراءات. |
| تبديل الدور | صلاحية زر الطوارئ فورًا. |
| تبديل اللغة | نصوص `AppStrings` واتجاه الواجهة. نصوص كثيرة ما زالت إنجليزية ثابتة داخل الشاشات. |
| مناطق الخريطة والتقارير المزروعة | لا تتأثر بالقراءات ولا بالنموذج. |

## 13. المصطلحات

| المصطلح | المعنى في هذا المشروع |
|---|---|
| SARI | اسم المنتج في الواجهة والوثيقة. حزمة Flutter اسمها `sari_app`. |
| pu | نسبة إلى القيمة الاسمية. تيار 1.0 = التيار المقنن للجهاز. جهد 1.0 = الجهد الاسمي. |
| overcurrent | ارتفاع تيار / حمل زائد. مفتاح في `sim.FAULTS`. |
| voltage | جهد خارج 90%–110% من الاسمي. |
| leakage | تسرب أرضي. التطبيق يرسله بالأمبير. السيرفر يخزنه بالميلي أمبير داخل النافذة (`* 1000`). |
| overheat | حرارة موصل عند أو فوق 70 مئوية. |
| prefault | مخرج خامس للنموذج: احتمال عطل خلال الأفق الزمني. العتبة الحالية تعطّله عمليًا. |
| tau | عتبات الاحتمال الأربع في `sari_config.json`. |
| confirm | عدد العينات المتتالية قبل القطع. القيمة 3. |
| cutoff | أمر إبقاء الدائرة مفصولة. |
| manual_cutoff | قطع طلبه التطبيق، منفصل عن قفل النموذج. |
| safety score | رقم 0–100 يحسبه السيرفر من أعلى احتمال، أو رقم ثابت من المحرك المحلي. |
| LSTM | شبكة `SariLSTM`: طبقتان مخفيتان 64، مدخل 4 ميزات، مخرج 5. الملف `sari_lstm.pt`. |
| UCI | ملف استهلاك منزلي خارج المستودع يُستخدم مادة خام للتدريب، ليس قاعدة تشغيل. |
| Device | حساس في قائمة التطبيق. على السيرفر مفتاح في `devices.json` (تيار مقنن وجهد وموقع). |
| Zone | منطقة عرض في الخريطة. ليست جهازًا. |
| Organization | نص على المستخدم والتقرير. لا كيان تشغيلي. |

## 14. الأسئلة الشائعة

**هل القراءات على الشاشة من لوحة كهرباء حقيقية؟** لا، ما لم يُشغَّل ESP32 ويُوجَّه إلى نفس السيرفر. التطبيق نفسه يولّد أرقامًا عشوائية حول قيم ثابتة.

**لماذا درجة السلامة مختلفة بين التشغيل مع السيرفر وبدونه؟** مصدران مختلفان: معادلة السيرفر في `_result`، أو الأرقام الثابتة في `AIRiskEngine` (مثلًا 94 عند الوضع الطبيعي و 42 عند ارتفاع التيار).

**هل Firebase يحفظ الأجهزة والتنبيهات؟** لا. المشروع `sari-app-26` مهيأ لـ Auth على أندرويد و iOS فقط. لا يوجد كود Firestore ولا FCM ولا Storage في `lib/`.

**هل أقدر أقطع التيار من الجوال؟** نعم إذا كان الدور مدير منشأة أو مسؤول، والسماح يفتح الحوار ثم يرسل cutoff. المستخدم السكني لا يستطيع. القطع الفعلي للوحة لا يحدث إلا إذا كان ESP32 متصلًا ويقرأ `/command`.

**أين تذهب ملفات PDF؟** في مجلد `REPORTS_DIR` أو `live_model/reports/<device>_<وقت>/`. المجلد مذكور في `.gitignore` الخاص بالمجلد `live_model`.

**هل التحذير المبكر قبل العطل يعمل؟** الكود موجود (`warning` في الرد). العتبة المحفوظة `1.01` تمنع تفعيله.

**هل التبويب الشهري يعرض تقريرًا مختلفًا؟** لا. التبويبان لا يفلتران القائمة.

---

# الجزء الثاني — التوثيق التقني

## 15. Architecture

النمط في التطبيق: واجهات Stateless/Stateful، حالة واحدة `AppStateViewModel` عبر `provider`، تنقل `go_router`. لا طبقات repository ولا حقن تبعية غير تمرير `ModelApiService` اختياريًا في الاختبارات.

```text
+---------------- Flutter app (lib/) ----------------+
| LoginScreen / MainWrapperScreen / باقي الشاشات    |
| AppStateViewModel                                  |
|   TelemetryService  (مؤقت 1 ثانية، أرقام محلية)   |
|   AIRiskEngine      (حدود ثابتة، بديل)            |
|   ModelApiService   (HTTP، مهلة 2 ثانية)          |
| FirebaseService     (Auth فقط)                     |
+------------------------|---------------------------+
                         |  http://10.0.2.2:8080 على محاكي أندرويد
                         |  http://127.0.0.1:8080 على غيره
                         v
+---------------- live_model (Python) ---------------+
| Flask + waitress                                   |
| SariLSTM + AlarmPolicy                             |
| reports.py -> pdf / json / csv                     |
| devices.json  sari_config.json  sari_lstm.pt       |
+------------------------|---------------------------+
                         ^
                         | POST /v1/reading ، GET /command
+---------------- ESP32 (ملف .ino) ------------------+
| WiFi + HTTPClient + ريلاي على الطرف 26            |
+----------------------------------------------------+
```

Firestore المرسوم في `README.md` الأصلي غير موصول في الكود. اعتبر ذلك الرسم هدفًا وصفيًا لا مسار تنفيذ.

## 16. Tech Stack

| الطبقة | التقنية | الدليل |
|---|---|---|
| تطبيق | Flutter، Dart. القيد في `pubspec.yaml`: `sdk: ^3.8.0`. البيئة التي بُني عليها هذا الفحص: Flutter 3.32.5 و Dart 3.8.1. ملف `.metadata` يسجل إنشاء المشروع بمراجعة Flutter `c9a6c484230f8b5e408ec57be1ef71dee1e77020` على قناة stable. | `pubspec.yaml`, `.metadata` |
| حالة وتنقل | provider 6.1.5+1، go_router 14.8.1 | `pubspec.lock` |
| رسم | fl_chart 0.70.2 | `pubspec.lock` |
| حركة | flutter_animate 4.5.2 | `pubspec.lock` |
| خط | Outfit متغير مضمّن، عائلة `Outfit` | `assets/fonts/Outfit-Variable.ttf`, `AppTheme` |
| تواريخ الواجهة | `SariDate` محلي. حزمة intl 0.20.2 موجودة لأن Flutter localizations تطلبها؛ الشاشات لم تعد تستدعي `DateFormat`. | `sari_date.dart` |
| شبكة التطبيق | http 1.6.0 | `pubspec.lock` |
| هوية | firebase_core 3.15.2، firebase_auth 5.7.0 | `pubspec.lock` |
| أندرويد | Gradle 8.5، Android Gradle Plugin 8.3.2، Kotlin 2.2.20، Java 17، minSdk 23، applicationId `com.sari.app.sari_app` | `android/` |
| نموذج | Python. البيئة المفحوصة: 3.10.6، torch 2.10.0+cpu، numpy 1.26.4، pandas 2.0.3 | استيراد محلي وقت الفحص |
| HTTP السيرفر | flask 3.0.3، waitress 3.0.2 | نفس الفحص |
| PDF | reportlab 4.2.5، arabic-reshaper 3.0.0، python-bidi 0.6.3 | نفس الفحص |
| عتاد | Arduino C++ لـ ESP32، مكتبتا WiFi و HTTPClient | `sari_esp32.ino` |

`requirements.txt` لا يثبّت أرقام إصدارات؛ الأرقام أعلاه ما كان مثبتًا على جهاز الفحص لا ما يضمنه الملف.

## 17. Project Structure

```text
Sari_app-main/
  pubspec.yaml                 اسم الحزمة sari_app وإصدار التطبيق 1.0.0+1
  analysis_options.yaml        flutter_lints
  firebase.json                مشروع Firebase sari-app-26 لأندرويد و iOS
  SARI_Product_Requirement_Document.md
  README.md                    نبذة إنجليزية أصلية، لم تُستبدل
  README_PROJECT.md            هذه الوثيقة
  assets/images/sari_logo.png
  assets/fonts/Outfit-Variable.ttf
  assets/fonts/OFL.txt
  lib/main.dart
  lib/firebase_options.dart
  lib/core/localization/app_strings.dart
  lib/core/router/app_router.dart
  lib/core/services/firebase_service.dart
  lib/core/theme/app_theme.dart
  lib/core/utils/sari_date.dart
  lib/data/models/               user, device, measurement, alert, report, zone
  lib/data/services/             telemetry_service, ai_risk_engine, model_api_service
  lib/ui/view_models/app_state_view_model.dart
  lib/ui/views/                  auth, dashboard, monitoring, ai_risk, alerts,
                                 heatmap, reports, devices, emergency, profile, navigation
  test/                          unit_test, model_api_service_test, widget_test
  android/                       Gradle و manifest و network_security_config
  ios/  web/  linux/  macos/  windows/     قوالب Flutter. Firebase مهيأ لأندرويد و iOS فقط
  live_model/
    server.py  model.py  sim.py  train.py  reports.py
    sari_config.json  sari_lstm.pt  devices.json  metrics.json
    requirements.txt  .env.example  .gitignore
    iot/sari_esp32/sari_esp32.ino
    iot/sari_esp32/secrets.example.h
```

لا يوجد مجلد `database/` ولا ملفات SQL ولا PHP.

## 18. Frontend

هذا ليس موقع HTML/CSS/JS. الواجهة ودجات Flutter.

| الموضوع | الواقع |
|---|---|
| HTML | غير مستخدم لواجهة المنتج. `web/index.html` قالب Flutter Web وعنوانه ما زال `sari_app`. |
| CSS | غير موجود. الألوان في `AppColors` داخل `app_theme.dart`. |
| JavaScript | غير موجود في واجهة المنتج. |
| Components | كل شاشة ملف Dart مستقل. بطاقات القياس مبنية داخل الملف وليست مكتبة مكونات مشتركة، باستثناء `SariDate`. |
| Templates | لا قوالب. النصوص الثنائية في خريطة `AppStrings`. |
| Routing | `createRouter` في `app_router.dart`. المسارات في الجدول أدناه. |
| SPA/MPA | تطبيق جوّال بـ `MaterialApp.router`. ليس تطبيق صفحات متعددة على سيرفر. |
| تحميل البيانات | لا جلب قائمة من API عند الفتح. الحالة تُبنى في كونستركتور `AppStateViewModel`. القراءات تتولد محليًا. التحليل طلب POST لكل قراءة. |
| Responsive | الرئيسية تغيّر عدد أعمدة المؤشرات إلى 4 إذا عرض الشاشة أكبر من 600. باقي الشاشات تمرير عمودي ثابت. لا تخطيط لوحي منفصل. |
| الثيم | `ThemeData` داكن واحد `AppTheme.darkTheme`. لا ثيم فاتح. |
| الأيقونات | `Icons.*` من Material و `Image.asset` لشعار SARI. |
| اتجاه | `locale` إما `en` أو `ar`. مفوضو `GlobalMaterialLocalizations` مضافون في `main.dart`. |

المسارات الفعلية في `createRouter`:

| المسار | الشاشة | داخل الشِل |
|---|---|---|
| `/login` | `LoginScreen` | لا |
| `/app/home` | `HomeDashboardScreen` | نعم |
| `/app/monitoring` | `LiveMonitoringScreen` | نعم |
| `/app/ai-risk` | `AIRiskDetectionScreen` | نعم |
| `/app/alerts` | `AlertsCenterScreen` | نعم |
| `/app/heatmap` | `RiskHeatmapScreen` | نعم |
| `/app/reports` | `ReportsScreen` | نعم |
| `/devices` | `DeviceManagementScreen` | لا، فوق الجذر |
| `/emergency` | `EmergencyControlScreen` | لا |
| `/profile` | `ProfileScreen` | لا |

التحويل: غير المسجّل يُعاد إلى `/login`، والمسجّل الذي يفتح `/login` يُعاد إلى `/app/home`.

الشريط السفلي في `MainWrapperScreen` ستة عناصر بالترتيب: Home، Monitoring، AI Risk، Alerts (مع `Badge` لعدد النشطة)، Heatmap، Reports.

## 19. Backend

لا PHP ولا MVC كلاسيكي.

سيرفر Python واحد، تطبيق Flask اسمه `app` في `server.py`. المنطق ليس مقسومًا إلى controllers منفصلة؛ كل مسار دالة في نفس الملف. الأصناف المساعدة:

| الرمز | الملف | الدور |
|---|---|---|
| `SariLSTM` | `model.py` | الشبكة |
| `AlarmPolicy.step` | `model.py` | قرار عينة واحدة |
| `over_limit` | `model.py` | مقارنة القراءة بالحدود |
| `DeviceState` | `server.py` | ذاكرة جهاز واحد داخل العملية |
| `AIRiskEngine.analyze` | `ai_risk_engine.dart` | بديل داخل التطبيق، ليس على السيرفر |
| `write_report` / `format_ar` | `reports.py` | ملفات التقرير وتنسيق الوقت |
| `sequence` / `batch` / `labels` / `features` | `sim.py` | توليد بيانات التدريب والتقييم فقط |

الوصول للبيانات ملفات JSON وقراءة CSV للتقييم، لا طبقة قاعدة بيانات.

## 20. Request Flow

مثال حقيقي: قراءة تسرب من التطبيق حتى قطع.

```text
TelemetryService._emitCurrentReading
  -> MeasurementModel (deviceID = SARI-SENS-01)
  -> AppStateViewModel._analyzeWithModel
  -> ModelApiService.analyze
       POST http://10.0.2.2:8080/v1/reading
       Header: X-Model-Token, Content-Type: application/json
       Body: device_id, timestamp, current, voltage, leakage, temperature
  -> server.reading
       _guard: معدل ثم توكن
       _number لكل حقل
       DeviceState: تحويل التيار إلى pu والجهد إلى pu والتسرب إلى mA
       sim.features ثم MODEL
       AlarmPolicy.step
       عند rising: write_report
       JSON: alarm, cutoff, faults, probabilities, prefault, result, report?
  -> ModelDecision.fromJson
  -> _raiseModelAlarm ثم cutPower إن لزم
  -> notifyListeners فتعيد الشاشات البناء
```

لا توجد قاعدة بيانات في هذا المسار. الحالة في `states` داخل عملية بايثون، وتُمسح عند إعادة تشغيل السيرفر.

## 21. Database

لا توجد قاعدة بيانات في المستودع: لا MySQL ولا Postgres ولا SQLite ولا Firestore client.

ما يشبه التخزين:

| المخزن | النوع | المحتوى |
|---|---|---|
| `live_model/devices.json` | JSON | مفاتيح `default` و `SARI-SENS-01` حتى `SARI-SENS-04`. لكل واحد `rated_current` و `nominal_voltage` و `location`. |
| `live_model/sari_config.json` | JSON | `window` 120، `tau` أربع قيم، `tau_pre`، `confirm`، `limits`. |
| `live_model/sari_lstm.pt` | أوزان PyTorch | يُحمَّل عند إقلاع السيرفر بـ `map_location=cpu`. |
| `live_model/metrics.json` | JSON | آخر نتيجة تقييم كتبها `train.py`. ليس مخزن تشغيل. |
| ذاكرة `AppStateViewModel` | كائنات Dart | تزول بإغلاق التطبيق. |
| مجلد التقارير | ملفات | تُنشأ عند الإنذار. |

جداول وثيقة المتطلبات (`users`، `devices`، `measurements`، `alerts`، `reports`) وصف منتج فقط. لا migrations ولا seeds.

ملفات خارج المستودع يستخدمها التدريب إذا وُجدت المسارات:

- `SARI_UCI_PATH` الافتراضي في `sim.py`: `d:\VSCode\Projects\sari-client-data\uci\household_power_consumption.txt` (أعمدة مستخدمة: Date, Time, Voltage, Global_intensity).
- `SARI_CLIENT_TRAIN` الافتراضي في `train.py`: `d:\VSCode\Projects\sari-client-data\train_.csv` ويُقرأ منه عمود `anomaly` فقط لحساب `client_dataset_all_normal_accuracy`.

هذان المساران ليسا جزءًا من تشغيل التطبيق. وجودهما على جهاز تطوير واحد لا يعني أنهما مرفقان بالمشروع.

اتصال Firebase المعرّف في `lib/firebase_options.dart` و `firebase.json`: المشروع `sari-app-26`. مفتاح API العميل موجود في الملف المولَّد من FlutterFire؛ لا يُنسخ هنا. المنصات بدون إعداد: web و windows و macos و linux ترمي `UnsupportedError` إذا استُدعيت `currentPlatform`.

## 22. API

الأساس: `HOST` و `PORT` من البيئة، الافتراضي `0.0.0.0:8080`. كل المسارات ما عدا `/health` و `OPTIONS` تمر على `_guard`.

حدود جسم الطلب: `MAX_CONTENT_LENGTH = 4096`. معرّف الجهاز: `^[A-Za-z0-9_-]{1,64}$`.

| Method | Path | الغرض | جسم / معاملات | التوثيق | الرد |
|---|---|---|---|---|---|
| GET | `/health` | فحص حياة | لا | لا | `{"ok": true}` |
| OPTIONS | أي مسار | رد المتصفح المسبق | لا | لا | رد Flask الافتراضي |
| POST | `/v1/reading` | تحليل قراءة | `device_id`، `current` 0–10000، `voltage` 0–1000، `leakage` 0–100، `temperature` -50–300، `timestamp` اختياري ISO | `X-Model-Token` | 200 قرار، 400 قراءة أو جهاز غير صالح، 401، 429 |
| GET | `/v1/devices/<device_id>/command` | هل الريلاي مفصول | المعرّف في المسار | التوكن | `{"device_id","cutoff"}`. جهاز غير معروف في الذاكرة: `cutoff false` |
| POST | `/v1/devices/<device_id>/cutoff` | تثبيت قطع يدوي | لا جسم مطلوب | التوكن | `{"cutoff": true}`. ينشئ حالة الجهاز إن لم تكن موجودة |
| POST | `/v1/devices/<device_id>/reset` | مسح حالة الجهاز من الذاكرة | لا جسم مطلوب | التوكن | `{"cutoff": false}` |
| GET | `/v1/reports/<report_id>/<name>` | تنزيل ملف | `report_id` يطابق `^[A-Za-z0-9_-]{1,64}_[0-9]{8}T[0-9]{6}$`. `name` أحد `report.pdf` أو `report.json` أو `readings.csv` | التوكن | الملف كمرفق، أو 404 |

حقول قرار `/v1/reading` المبنية في الكود: `device_id`، `timestamp`، `time_display` من `format_ar`، `alarm`، `cutoff` (إنذار أو قطع يدوي)، `warning`، `faults`، `probabilities`، `prefault`، `result` (safetyScore, riskLevel, riskType, probability, cause, recommendedAction, hasAnomaly)، و`report` عند وجود تقرير سابق بعد القطع وفيه `id` و `files`.

أخطاء: 401 `unauthorized`، 429 `too many requests` (30 طلبًا في الثانية لكل IP، `RATE_PER_SECOND`)، 500 `server error` بلا تفاصيل للمتصل. الاستثناءات تُسجّل عبر `logging`.

CORS: لا يُرسل `Access-Control-Allow-Origin` إلا إذا كان ترويسة `Origin` ضمن `ALLOWED_ORIGINS`.

## 23. Authentication & Authorization

التطبيق:

- `FirebaseService.initialize` يلتقط الفشل ولا يوقف التطبيق.
- تسجيل الدخول: `signInWithEmailAndPassword`. إنشاء حساب: `createUserWithEmailAndPassword` عندما تكون واجهة Register مختارة.
- أخطاء البيانات تُرفض (`FirebaseService.isCredentialError`). أعطال الشبكة والإعداد في `_backendUnavailableCodes` تفتح جلسة تجريبية.
- لا جلسة محفوظة على القرص في الكود (لا `SharedPreferences`). إعادة تشغيل التطبيق ترجع إلى `/login` حتى لو كان Firebase ما زال يحتفظ بمستخدم؛ الكود لا يستعيد `FirebaseAuth.instance.currentUser` عند الإقلاع.
- الخروج: `FirebaseService.signOut` ثم `_isLoggedIn = false`.
- الدور ليس claim من Firebase. هو اختيار واجهة.

السيرفر:

- سر واحد مشترك `MODEL_TOKEN` طوله 16 حرفًا على الأقل وإلا `SystemExit` عند الإقلاع.
- المقارنة `hmac.compare_digest`.
- لا مستخدمين ولا انتهاء جلسة ولا تدوير مفاتيح في الكود.

## 24. Security

الموجود فعلًا في `server.py` و manifest أندرويد:

| الوسيلة | أين |
|---|---|
| توكن ثابت للـ API | `X-Model-Token` |
| حد معدل لكل IP | `_rate_ok`، 30/ثانية |
| سقف حجم الجسم | 4096 بايت |
| التحقق من نوع الرقم ومداه | `_number` |
| رفض معرّف جهاز لا يطابق النمط | `DEVICE_ID` |
| رفض معرّف تقرير أو اسم ملف خارج القائمة | `REPORT_ID` و `FILES` ثم `send_from_directory` |
| ترويسات | `X-Content-Type-Options: nosniff`، `X-Frame-Options: DENY`، `Content-Security-Policy: default-src 'none'`، `Cache-Control: no-store`، إخفاء نسخة Werkzeug (`server_version = SARI`) |
| CORS مغلق ما لم تُذكر الأصول | `ALLOWED_ORIGINS` |
| سجل أخطاء عام للمستخدم | `_error` |
| HTTP الواضح على أندرويد | مسموح فقط لـ `10.0.2.2` و `127.0.0.1` و `localhost` في `network_security_config.xml`. باقي الوجهات cleartext ممنوعة. |
| صلاحية الإنترنت | `AndroidManifest.xml` الرئيسي |

غير الموجود في الكود:

- CSRF (واجهة الجوال لا تعتمد كوكيز جلسة للمتصفح).
- تجزئة كلمات مرور داخل المشروع (Firebase Auth يدير ذلك عندما يُستخدم).
- سجل تدقيق دائم للعمليات.
- تحقق من شهادة TLS مخصص.
- عزل صلاحيات على السيرفر.
- تشفير ملفات التقارير على القرص.

كلمات المرور لا تُطبع في السجل عمدًا. `debugPrint` قد يطبع استثناء Firebase وقد يحتوي بريدًا؛ هذا سلوك الكود الحالي.

## 25. Configuration

لا تُكتب القيم السرية هنا.

تطبيق Flutter، عبر `--dart-define` ويقرأها `String.fromEnvironment` في `ModelApiService`:

| المفتاح | إذا غاب |
|---|---|
| `SARI_MODEL_URL` | على أندرويد `http://10.0.2.2:8080`، وغير ذلك `http://127.0.0.1:8080` |
| `SARI_MODEL_TOKEN` | سلسلة فارغة، فالسيرفر يرد 401 |

سيرفر `live_model/.env` (يُحمَّل في `_load_env` دون أن يستبدل متغيرًا موجودًا في البيئة). المثال في `.env.example`:

| المفتاح | معنى |
|---|---|
| `MODEL_TOKEN` | مطلوب، 16+ حرفًا |
| `HOST` | الافتراضي في الكود `0.0.0.0` |
| `PORT` | الافتراضي `8080` |
| `ALLOWED_ORIGINS` | قائمة مفصولة بفواصل، فارغة تعني لا CORS |
| `REPORTS_DIR` | افتراضيًا مجلد `reports` بجانب السيرفر |
| `SARI_UCI_PATH` | مسار ملف UCI للتدريب فقط |
| `SARI_CLIENT_TRAIN` | مسار CSV للتقييم فقط |

عتاد: `secrets.example.h` يعرّف `WIFI_SSID` و `WIFI_PASSWORD` و `MODEL_URL` و `MODEL_TOKEN` و `DEVICE_ID`. الملف الفعلي المتوقع `secrets.h` مذكور في `live_model/.gitignore` وغير مرفق.

إعدادات أخرى مثبتة في الكود لا في بيئة: حدود الأعطال في `sim.py` (`OVERLOAD_PU = 1.13`، `SHORT_PU = 5`، `V_LOW = 0.9`، `V_HIGH = 1.1`، `LEAK_MA = 30`، `TEMP_C = 70`، `PERSIST = 3`، `WINDOW = 120`، `HORIZON = 60`)، ونسخة منها داخل `sari_config.json` للسيرفر العامل.

`android/gradle.properties` يحدد `org.gradle.java.home` لمسار JDK على جهاز التطوير (`C:/Program Files/Amazon Corretto/jdk21.0.7_6`). هذا مسار آلة محلية وقد يحتاج تعديلًا على جهاز آخر.

## 26. Integrations

| الخدمة | الحالة في الكود |
|---|---|
| Firebase Auth | مستدعى من `FirebaseService`. الإعداد لمشروع `sari-app-26` على أندرويد و iOS. |
| Cloud Firestore | غير مستدعى. صف الواجهة الذي يقول Active نص ثابت. |
| Cloud Messaging | غير مستدعى. لا `firebase_messaging` في `pubspec.yaml`. |
| Firebase Storage | مذكور في `storageBucket` داخل `firebase_options.dart` فقط. لا رفع ملفات. |
| نموذج LSTM المحلي | HTTP إلى `live_model`. |
| ESP32 | عميل HTTP للسيرفر نفسه. |
| بريد / SMS / تحليلات / Cloudflare | غير موجودة في الكود. |
| تحميل خط من الإنترنت | أُزيل. الخط ملف محلي. |

## 27. Scheduled Jobs

لا cron ولا workers ولا queues ولا مهام نظام.

المؤقتات داخل العمليات: مؤقت Flutter كل ثانية، وحلقة ESP32 التي تنتظر حتى يكتمل الثانية تقريبًا (`delay` بما تبقى من 1000 مللي ثانية).

## 28. File Storage

- شعار التطبيق: `assets/images/sari_logo.png` مضمّن في الحزمة.
- خط: `assets/fonts/Outfit-Variable.ttf` مع `OFL.txt`.
- تقارير السيرفر: `write_report` ينشئ مجلدًا لكل حادثة فيه `readings.csv` (كل الصفوف المحتفظ بها في النافذة، الحد `CONFIG["window"]` أي 120) و `report.json` و `report.pdf` إذا وُجد خط عربي. مرشحات الخط في `reports.py`: `C:\Windows\Fonts\arial.ttf` ثم مسارات DejaVu على لينكس. إن لم يوجد خط يُتخطى PDF ويُسجَّل تحذير.
- لا رفع ملفات من المستخدم. إضافة الحساس لا ترفع صورة ولا شهادة.

## 29. Logging & Monitoring

- السيرفر: `logging` باسم `sari.server` و `sari.reports`. أسطر INFO عند الإنذار والقطع اليدوي و reset. الاستثناءات عبر `log.exception`. لا تجميع مقاييس ولا تنبيه خارجي.
- التطبيق: `debugPrint` لفشل Firebase وفشل النموذج وفشل reset. لا خدمة تقارير أعطال (لا Crashlytics في `pubspec.yaml`).
- الصحة: `GET /health`.
- شاشة الملف الشخصي لا تعرض صحة السيرفر الفعلية.

## 30. Installation

المتطلبات المفحوصة لتشغيل التطبيق على أندرويد:

- Flutter SDK يطابق قيد Dart `^3.8.0` (الفحص تم بـ 3.32.5 / Dart 3.8.1).
- Android SDK ومحاكي أو جهاز.
- JDK 17. الملف الحالي يشير إلى Amazon Corretto 21 في `gradle.properties` لأن تلك الآلة تستخدمه مع هدف Java 17.

تشغيل الواجهة فقط (تحليل محلي، بدون نموذج):

```bash
cd Sari_app-main
flutter pub get
flutter run -d <device>
```

تشغيل النموذج مع الواجهة:

```bash
cd live_model
pip install -r requirements.txt
copy .env.example .env
# ضع MODEL_TOKEN بطول 16 حرفًا على الأقل داخل .env ولا ترفعه
python server.py
```

ثم من جذر التطبيق:

```bash
flutter run -d <device> --dart-define=SARI_MODEL_TOKEN=<نفس التوكن>
```

عنوان مخصص إن لزم:

```bash
flutter run --dart-define=SARI_MODEL_URL=http://<host>:8080 --dart-define=SARI_MODEL_TOKEN=<token>
```

اختبارات:

```bash
flutter test
flutter analyze
```

إعادة تدريب النموذج (اختياري، يحتاج ملفي البيانات الخارجيين، وقد يستغرق عشرات الدقائق على CPU):

```bash
cd live_model
python train.py
python train.py --eval
```

`--eval` يحمّل `sari_lstm.pt` الموجود ولا يعيد التدريب، ثم يعيد ضبط العتبات ويكتب `metrics.json` و `sari_config.json`.

ESP32: انسخ `secrets.example.h` إلى `secrets.h` واملأ القيم، ثم ابنِ `sari_esp32.ino` من Arduino IDE. طريقة الرفع غير موثقة داخل المستودع بأكثر من ذلك.

Firebase: `google-services.json` موجود تحت `android/app/` و `GoogleService-Info.plist` موجود تحت `ios/Runner/`. إعادة التوليد عبر FlutterFire CLI مذكورة في `README.md` الأصلي وليست مشروحة كخطوات محفوظة هنا لأن أوامر الحساب غير موجودة في المستودع.

لا يوجد خادم ويب PHP يلزم ضبطه.

## 31. Development Guide

هذه خريطة للإضافة وفق البنية الحالية، لا التزام بأن الإضافة ستصبح دائمة التخزين.

صفحة جديدة:

1. ملف شاشة تحت `lib/ui/views/<name>/`.
2. مسار في `createRouter` داخل `app_router.dart`.
3. إن كانت ضمن الشريط السفلي، عنصر في `MainWrapperScreen` وحالة في `_calculateSelectedIndex`.
4. مفاتيح النص في الخريطتين `en` و `ar` داخل `AppStrings`.

منطق مشترك: دالة أو حقل في `AppStateViewModel` ثم `notifyListeners`. الشاشات تقرأ عبر `context.watch<AppStateViewModel>()`.

نداء API جديد: دالة في `ModelApiService` ثم مسار في `server.py` يمر تلقائيًا على `_guard` ما لم يُستثنَ مثل `/health`.

تغيير حد كهربائي: القيمة التشغيلية التي يقرأها السيرفر من `sari_config.json` (تُنسخ إلى `CONFIG` عند الإقلاع). قيمة التدريب والتسمية في ثوابت `sim.py`. تعديل أحدهما دون الآخر يفرّق التدريب عن التشغيل.

جدول قاعدة: لا يوجد مكان لإضافته. التخزين الحالي ملفات JSON أو الذاكرة.

صلاحية جديدة: اليوم الفحص الوحيد هو `canCutPower` في `AppStateViewModel`. أي صلاحية إضافية تُضاف هناك وتُستدعى من الشاشة. السيرفر لن يعرف بها إلا إذا أُضيف حقل صريح، وهذا غير موجود.

اختبار: أضف حالة في `test/` بحقن `MockClient` كما في `model_api_service_test.dart`.

## 32. Deployment

لا يوجد في المستودع `Dockerfile` ولا `render.yaml` ولا سكربت نشر ولا CI.

ما يمكن استنتاجه من الكود فقط:

- السيرفر يربط `0.0.0.0:$PORT` ويستخدم waitress إن كانت مثبتة.
- وضع Flask `debug=False` في فرع غياب waitress.
- مجلد التقارير على نظام الملفات المحلي للعملية. على منصة قرصها مؤقت تضيع التقارير بعد إعادة التشغيل. لا بديل تخزين كائني في الكود.
- تطبيق أندرويد: `buildTypes.release` يوقّع بمفتاح debug (`signingConfig` في `android/app/build.gradle.kts`). لا يوجد إعداد توقيع إنتاج.
- `minSdk` 23 لأن Firebase Auth يتطلب ذلك في هذا الإصدار.
- عنوان النموذج داخل التطبيق يُثبَّت عند البناء بـ `--dart-define`، ليس عند التشغيل من ملف إعداد.

نطاق إنتاج، شهادة TLS، ونطاقات CORS قيم يشغّلها من ينشر. الكود لا يفرض HTTPS على السيرفر نفسه؛ قيد cleartext هو على تطبيق أندرويد فقط.

## 33. Backup & Recovery

غير موجود. لا سكربت نسخ، ولا استعادة.

ما يُفقد عند إعادة التشغيل:

- ذاكرة التطبيق كاملة (تنبيهات مولَّدة، حساسات مضافة، حالة القطع).
- قاموس `states` في السيرفر، فيعود القطع التلقائي واليدوي غير قائم حتى قراءة أو طلب جديد.
- ملفات `reports/` إذا مُسح المجلد أو كان القرص مؤقتًا.

ما يبقى على القرص إذا لم يُحذف: `sari_lstm.pt`، `sari_config.json`، `devices.json`، `metrics.json`، تقارير لم تُمسح.

## 34. Troubleshooting

| العرض | ما يطابقه في الكود | اتجاه الفحص |
|---|---|---|
| شاشة الدخول ترفض البريد | Firebase ردّ بخطأ بيانات و`isCredentialError` أعاد false | حساب غير موجود أو كلمة مختلفة. زر Demo لا ينشئ حساب Firebase. |
| الدخول يفتح لوحة رغم أن Firebase مرفوض | الخطأ من `_backendUnavailableCodes` (شبكة أو إعداد) فتُفتح جلسة تجريبية | راجع log بعنوان `[FirebaseService] Auth error` |
| التحليل يبقى على أرقام المحرك المحلي (94 أو 42 أو 58 أو 71) | استثناء في `_analyzeWithModel` يضع `_modelOnline = false` | السيرفر غير شغّال، أو التوكن فارغ (401)، أو العنوان خطأ. على المحاكي العنوان الافتراضي `10.0.2.2` |
| 429 من السيرفر | أكثر من 30 طلبًا في الثانية من نفس IP | المحاكي يرسل قراءة كل ثانية وهذا تحت الحد. حلقة اختبار بلا انتظار تتجاوزه. |
| PDF غير موجود في الرد | `reports.py` لم يجد خطًا عربيًا | على ويندوز يتوقع `C:\Windows\Fonts\arial.ttf` |
| Gradle لا يجد JDK | `org.gradle.java.home` مسار جهاز آخر | عدّل المسار في `android/gradle.properties` |
| فشل بناء بسبب إصدار Dart | قيد `pubspec.yaml` لا يطابق Flutter المثبت | القيد الحالي `^3.8.0` |
| Web/desktop يرمي عند Firebase init | `DefaultFirebaseOptions.currentPlatform` غير معرّف لتلك المنصات | `FirebaseService.initialize` يلتقط الاستثناء ويكمل. Auth يبقى غير مهيأ. |
| القطع لا يفصل لوحة حقيقية | لا جهاز يقرأ `/command` | راجع Serial على ESP32 و`MODEL_URL` في `secrets.h` |
| درجة السلامة حوالي 97 والخطر LOW | سلوك السيرفر بعد تجاهل prefault تحت `tau_pre` | ليس عطلًا بحد ذاته |

## 35. Dependencies

قيود `pubspec.yaml` ثم النسخة المحلولة في `pubspec.lock`:

| الحزمة | القيد | المحلول |
|---|---|---|
| cupertino_icons | ^1.0.8 | 1.0.8 |
| provider | ^6.1.2 | 6.1.5+1 |
| go_router | ^14.8.0 | 14.8.1 |
| fl_chart | ^0.70.2 | 0.70.2 |
| flutter_animate | ^4.5.2 | 4.5.2 |
| intl | ^0.20.2 | 0.20.2 |
| firebase_core | ^3.12.0 | 3.15.2 |
| firebase_auth | ^5.5.1 | 5.7.0 |
| http | ^1.2.2 | 1.6.0 |
| flutter_lints (dev) | ^6.0.0 | 6.0.0 |

إصدار التطبيق نفسه: `1.0.0+1`. لا يوجد Git داخل مجلد المشروع (`fatal: not a git repository` وقت الفحص)، لذلك لا تاريخ إصدارات من الوسوم.

Python في `requirements.txt` بلا أرقام: torch, numpy, pandas, flask, waitress, reportlab, arabic-reshaper, python-bidi. الأرقام المثبتة على جهاز الفحص مذكورة في القسم 16.

## 36. Known Limitations

مستنتجة من الكود الحالي، لا من افتراض منتج:

- بيانات الأجهزة والمناطق والتنبيهين الأولين والتقريرين الأولين ثابتة في الكونستركتور.
- المحاكي يرسل دائمًا باسم `SARI-SENS-01` فقط.
- تبويبا التقارير لا يفلتران. زر التصدير لا يكتب ملفًا.
- بطاقات "Predictive Failure Risk Models" نسبها مكتوبة يدويًا.
- صندوق حالة النظام في الملف الشخصي نص ثابت ويخالف غياب Firestore و FCM.
- `tau_pre = 1.01` يعطّل التحذير المبكر.
- حالة السيرفر في الذاكرة فقط.
- حد 30 طلبًا/ثانية لكل IP مشترك بين كل الأجهزة خلف نفس العنوان.
- توقيع إصدار أندرويد بمفتاح debug.
- `README.md` الإنجليزي يصف Firestore و FCM و RBAC كميزات قائمة؛ الكود لا يطبق Firestore ولا FCM، والدور المحلي يغيّر زر الطوارئ فقط.
- نصوص واجهة كثيرة غير داخلة في `AppStrings` (بطاقات التقارير، إرشادات الطوارئ، فلاتر التنبيهات، أسماء نماذج الخطر).
- لا ملف `LICENSE` رغم أن `README.md` يقول MIT.
- مفتاح API الخاص بعميل Firebase موجود داخل `lib/firebase_options.dart` لأنه مخرج FlutterFire المعتاد لتطبيق جوّال، وهو ليس سر سيرفر، لكن الملف يُرفع مع المصدر.

## 37. Current System State

مكتمل ويمكن تشغيله:

- بناء تطبيق أندرويد على Flutter 3.32.5 بعد ضبط Gradle.
- عشر اختبارات Flutter ناجحة (`flutter test`) و `flutter analyze` بلا أخطاء (تنبيهات info من نوع `withOpacity` و `prefer_final_fields` ما زالت).
- شاشات التنقل العشر، ثنائية اللغة جزئيًا، محاكي الأعطال، قطع وإعادة حسب الدور.
- سيرفر النموذج: قراءة، توكن، حد معدل، قطع تلقائي، قطع يدوي، reset، تنزيل تقرير.
- أوزان نموذج محفوظة وملف عتبات.

موجود كواجهة أو كود ولا يكتمل وظيفيًا:

- Firebase Auth يعمل فقط مع حساب حقيقي؛ الحسابات المعروضة في Quick Demo ليست حسابات منشأة في المستودع.
- Firestore و FCM و Storage و Push.
- حفظ دائم للقراءات والتنبيهات والأجهزة.
- تصدير PDF من التطبيق.
- فلتر يومي/شهري.
- تحميل تقرير النموذج من داخل التطبيق.
- إدارة مستخدمين متعددة الصلاحيات كما في وثيقة المتطلبات.
- نشر إنتاج وتوقيع متجر.

غير موثق في المستودع:

- مالك منتج Firebase ومن لديه صلاحية لوحة `sari-app-26`.
- هل ESP32 رُكب على لوحة وبأي حساسات.
- مصدر ملفي `sari-client-data` وترخيص استخدام ملف UCI.
- سياسة الاحتفاظ بالتقارير.

## 38. Architecture Decisions

| القرار | الدليل | السبب كما يظهر من الكود، لا من تخمين خارجي |
|---|---|---|
| حالة واحدة `ChangeNotifier` | `main.dart` يمرر `AppStateViewModel` للراوتر وللشاشات | الشاشات تقرأ نفس القوائم بدون طبقة وسيطة |
| بديل محلي إذا سقط النموذج | `catch` في `_analyzeWithModel` ثم `AIRiskEngine` | التعليق عبر `debugPrint`: النموذج غير متصل فيُستخدم محرك القواعد |
| العتبة لا تكفي للقطع | `AlarmPolicy.step` يشترط `over_limit` أو قصرًا فوريًا على التيار | التعليق غير مكتوب؛ السلوك نفسه في `train.first_alarm` و `server` حتى تتطابق التقييم مع التشغيل |
| تحميل torch قبل pandas | أول سطر في `server.py` و `train.py` | التعليق: وإلا يفشل `c10.dll` على ويندوز |
| التوكن في `.env` ويفشل الإقلاع إن قصر | `SystemExit` في `server.py` | لا قيمة افتراضية للتوكن |
| HTTP واضح محدود على أندرويد | `network_security_config.xml` | المحاكي يتصل بـ `10.0.2.2` بلا TLS؛ باقي الوجهات ممنوعة cleartext |
| الخط مضمّن | `pubspec.yaml` خطوط Outfit، ولا اعتماد `google_fonts` | التشغيل بلا شبكة لا يطلب `fonts.gstatic.com` |
| التقارير على القرص لا في التطبيق | `write_report` | التطبيق يخزن الروابط كنص داخل `summaryHighlights` |

## 39. Changelog

لا يوجد ملف CHANGELOG ولا وسوم Git داخل هذا المجلد. لا تُخترع أرقام إصدار.

إصدار التطبيق المعلن في `pubspec.yaml` هو `1.0.0+1` فقط.

`metrics.json` الحالي (ناتج آخر `train.py --eval` محفوظ في المجلد) يسجل باختصار:

- عتبات `tau`: 0.95 و 0.95 و 0.95 و 0.85، و `tau_pre`: 1.01.
- على 20000 تسلسل اختبار: نسب كشف بين 0.966 و 0.9733 حسب النوع، و `false_cutoffs` = 5.
- `real_uci_held_out`: 28.7 يومًا و `false_alarm_seconds` = 0.
- محاكاة التطبيق: 0 إنذارات كاذبة في 24 ساعة طبيعية، وقطع السيناريوهات خلال 3 أو 4 ثوانٍ.
- `client_dataset_all_normal_accuracy`: 0.9787 (هذه نسبة صفوف عمود `anomaly` غير الموجبة في CSV خارجي، وليست دقة النموذج على تلك البيانات).
- `minutes`: 10.0 لمدة ذلك التشغيل.

هذه أرقام ملف التقييم، لا ضمان تشغيل حي.

### تعديلات الكود الأخيرة المرتبطة بهذه الوثيقة

موجودة في الملفات الآن مقارنة بسلوك أقدم كان يبدأ التطبيق داخل اللوحة مباشرة ويستدعي النموذج على `127.0.0.1` فقط:

- `pubspec.yaml`: قيد Dart `^3.8.0`، إزالة `google_fonts`، إضافة خط Outfit.
- أندرويد: Gradle 8.5، AGP 8.3.2، Kotlin 2.2.20، minSdk 23، صلاحية إنترنت في manifest الرئيسي، `network_security_config.xml`، اسم التطبيق `SARI`.
- `ModelApiService.defaultBaseUrl`: `10.0.2.2` على أندرويد.
- `SariDate` لتنسيق `YYYY/M/Dم H:MMص` في التنبيهات والتقارير.
- البداية من شاشة الدخول، ورفض خطأ بيانات Firebase، والسماح بجلسة تجريبية فقط عند تعذر الخلفية.
- `POST /v1/devices/<id>/cutoff` و`ModelApiService.cutoff`، و`canCutPower` للمستخدم السكني.
- درجة السيرفر تتجاهل `prefault` إذا كان تحت `tau_pre`.
- تبويب تنبيهات في الشريط السفلي.
- معالجة فيضان عرض في الرئيسية والتقارير وزر الطوارئ.

---

# الجزء الأخير — ملخص شامل

## System Overview

```text
شخص يفتح تطبيق SARI
        |
        +-- Firebase Auth (إن وُجد حساب وشبكة) أو جلسة تجريبية عند انقطاع الخلفية
        |
        v
لوحة في الذاكرة: أجهزة ثابتة، مناطق ثابتة، تقارير ثابتة، قراءات تُولَّد كل ثانية
        |
        +-- تحليل محلي AIRiskEngine  إذا السيرفر غائب
        |
        +-- POST /v1/reading -------> live_model
        |                                LSTM + حدود فيزيائية
        |                                إنذار؟ -> PDF/JSON/CSV على القرص
        |                                cutoff يبقى حتى /reset
        |
        +-- زر طوارئ (مدير أو مسؤول) -> POST /cutoff
                         ^
                         |
                    ESP32 يرسل قراءة ويقرأ /command ويحرّك الريلاي
                    (فقط إذا بُرمج اللوح بـ secrets.h)
```

## Quick Reference

| الجزء | التقنية | الموقع | الوظيفة |
|---|---|---|---|
| تشغيل الواجهة | Flutter | `lib/main.dart` | تهيئة Firebase ثم `SariApp` |
| التنقل | go_router | `lib/core/router/app_router.dart` | المسارات والتحويل حسب الدخول |
| الحالة | provider | `lib/ui/view_models/app_state_view_model.dart` | كل بيانات الشاشات |
| محاكي القياس | Dart Timer | `lib/data/services/telemetry_service.dart` | قراءة كل ثانية |
| تحليل بديل | Dart | `lib/data/services/ai_risk_engine.dart` | حدود تيار/تسرب/جهد |
| عميل النموذج | http | `lib/data/services/model_api_service.dart` | reading و cutoff و reset |
| الهوية | firebase_auth | `lib/core/services/firebase_service.dart` | دخول وإنشاء وخروج |
| النصوص | Dart map | `lib/core/localization/app_strings.dart` | en / ar |
| التاريخ | Dart | `lib/core/utils/sari_date.dart` | صيغة العرض |
| الألوان | ThemeData | `lib/core/theme/app_theme.dart` | ثيم داكن |
| API النموذج | Flask | `live_model/server.py` | القراءة والقطع والتقارير |
| الشبكة | PyTorch | `live_model/model.py` | SariLSTM و AlarmPolicy |
| بيانات التدريب | numpy/pandas | `live_model/sim.py` | توليد وتسمية |
| تدريب | Python | `live_model/train.py` | تدريب وتقييم وكتابة العتبات |
| تقرير | reportlab | `live_model/reports.py` | PDF و JSON و CSV |
| عتاد | Arduino | `live_model/iot/sari_esp32/sari_esp32.ino` | إرسال وريلاي |
| أجهزة معروفة للسيرفر | JSON | `live_model/devices.json` | تيار مقنن وجهد وموقع |
| عتبات التشغيل | JSON | `live_model/sari_config.json` | tau والحدود |

## Quick Start

```bash
cd live_model
pip install -r requirements.txt
copy .env.example .env
# MODEL_TOKEN= سلسلة 16 حرفًا على الأقل
python server.py
```

```bash
cd ..
flutter pub get
flutter run -d <device> --dart-define=SARI_MODEL_TOKEN=<نفس القيمة>
```

بدون السيرفر: `flutter pub get` ثم `flutter run` ويكفي المحرك المحلي.

## For Non-Technical Users

SARI شاشة لمراقبة كهرباء تجريبية مع إمكانية وصلها بنموذج على حاسوب.

ماذا تفعل اليوم: ترى تيارًا وجهدًا وتسربًا يتغيران كل ثانية، ودرجة سلامة، وتنبيهات، وخريطة مناطق جاهزة، وتقارير جاهزة. تقدر تحاكي عطلًا من الرئيسية. مدير المنشأة أو المسؤول يقدر يقطع التيار من شاشة الطوارئ بعد تأكيد؛ المستخدم السكني لا يقدر.

كيف تستخدمها: تفتح التطبيق، تسجّل الدخول (حساب Firebase حقيقي، أو أي بريد إذا كانت شبكة Firebase غير متاحة فيُفتح وضع تجريبي)، ثم تتنقل من الشريط الأسفل. الخريطة والتقارير الأولية ليست نتيجة قياس تلك اللحظة. القطع يصل إلى لوحة حقيقية فقط إذا كان جهاز SARI الإلكتروني متصلًا بالسيرفر.

أهم الأقسام: الرئيسية، المراقبة، تحليل الخطر، التنبيهات، الخريطة، التقارير، الأجهزة، الطوارئ، الملف الشخصي.

## For Developers

- الحزمة: `sari_app`، Flutter، حالة واحدة، `go_router`.
- لا قاعدة SQL. Firebase = Auth فقط رغم نص الواجهة.
- API الوحيدة: `live_model/server.py`. التوكن إلزامي. الحالة في الذاكرة.
- النموذج: `SariLSTM`، نافذة 120، تأكيد 3، بوابة حدود في `over_limit`.
- أهم الملفات: `app_state_view_model.dart`، `model_api_service.dart`، `server.py`، `model.py`، `sim.py`، `sari_config.json`.
- التطوير: شاشة جديدة = ملف في `lib/ui/views` + مسار في `app_router.dart` + مفاتيح `AppStrings`. نداء جديد = دالة في `ModelApiService` + مسار Flask. الاختبارات في `test/` مع `MockClient`.
- لا ترفع `.env` ولا `secrets.h`. لا تغيّر رقم `version` في `pubspec.yaml` إلا بطلب صريح.
