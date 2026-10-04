# Sari_app-main

تطبيق SARI لمراقبة خطر كهربائي. عنوان الواجهة `SARI - Electrical Risk Detection`. حزمة Flutter اسمها `sari_app`. مع التطبيق مجلد `live_model` فيه نموذج LSTM وخادم Flask، وملف عتاد `sari_esp32.ino`.

هذه الوثيقة تعتمد على الكود. README الإنجليزي و`README_PROJECT.md` و`SARI_Product_Requirement_Document.md` موجودة. ما صح منها أُبقي، وما خالفه الكود مذكور في موضعه.

# الجزء الأول - التعريف والفهم العام

## 1. ما هو المشروع؟

منصة تعرض قياسات تيار وجهد وتسرب وحرارة، وتحسب خطرا، وتعرض تنبيهات وخريطة مناطق وتقارير، وتتيح قطعا للطوارئ حسب الدور. المصدر الحي داخل التطبيق مؤقت يولّد قراءات. إن وُجد خادم النموذج يُستبدل جزء من القرار المحلي بنتيجة `POST /v1/reading`.

وصف `pubspec.yaml` ما زال `A new Flutter project.` بينما الشاشات نظام مراقبة.

## 2. لماذا يوجد هذا المشروع؟

نص README الإنجليزي ووثيقة المتطلبات يقولان إن الهدف نقل الحماية من رد الفعل بعد العطل إلى تنبيه مبكر. الكود يبني محاكيا وتنبيهات وقطعا وملفات تقرير PDF. وثيقة جهة مالكة خارج هذه الملفات غير مضافة كعقد.

## 3. من يستخدمه؟

الأدوار في `UserRole`:

| الرمز | الاسم في الواجهة |
|---|---|
| `RESIDENTIAL` | Residential User |
| `FACILITY_MANAGER` | Facility Manager |
| `ADMIN` | System Admin |

وثيقة المتطلبات تذكر مصانع وجهات حكومية. هذه الأدوار غير موجودة في `enum UserRole`.

`canCutPower` يسمح بالقطع لغير `residential`.

## 4. ماذا يستطيع النظام أن يفعل؟

الشاشات من `app_router.dart` وREADME السابق، وهي موجودة كملفات:

| المسار | الشاشة |
|---|---|
| `/login` | `LoginScreen` |
| `/app/home` | `HomeDashboardScreen` |
| `/app/monitoring` | `LiveMonitoringScreen` |
| `/app/ai-risk` | `AIRiskDetectionScreen` |
| `/app/alerts` | `AlertsCenterScreen` |
| `/app/heatmap` | `RiskHeatmapScreen` |
| `/app/reports` | `ReportsScreen` |
| `/devices` | `DeviceManagementScreen` |
| `/emergency` | `EmergencyControlScreen` |
| `/profile` | `ProfileScreen` |

قدرات ظاهرة في الكود:

- دخول وإنشاء حساب عبر Firebase Auth إن تهيأت الخدمة، وإلا جلسة تجريبية عند أخطاء الخلفية المحددة في `FirebaseService`.
- تبديل الدور من الملف الشخصي للاختبار.
- لغة `en` و`ar` عبر `AppStrings` و`SariDate`.
- رسوم `fl_chart` في المراقبة.
- محاكي: ارتفاع تيار، هبوط جهد، تسرب، إعادة الوضع الطبيعي. README الإنجليزي يسميها Anomaly Simulator وهذا يطابق لوحة الرئيسية.
- محرك محلي `AIRiskEngine` إذا تعذر النموذج.
- خادم يستقبل القراءة ويقرر إنذارا وقطعا ويكتب تقريرا.
- أجهزة معرفة في `live_model/devices.json`.
- سكتش ESP32 يرسل قراءة ويستجيب لحقل `cutoff`.

دفع إشعارات جاهز للعمل غير موجود كتكامل FCM في الملفات التي فُحصت. README الإنجليزي يقول جاهزية إشعار. ذلك وصف، وملف خدمة الإشعار غير ظاهر في `lib`.

MQTT مذكور في رسم README الإنجليزي. عميل MQTT في الكود الذي فُحص غير موجود. النقل إلى النموذج HTTP.

## 5. كيف يعمل النظام؟

```text
مؤقت التطبيق كل ثانية
  -> Measurement
  -> ModelApiService POST /v1/reading  (مهلة ثانيتين)
       إن نجح: قرار النموذج + cutoff
       إن فشل: AIRiskEngine المحلي
  -> تنبيه / تقرير / قطع حسب النتيجة
خادم Flask
  -> نافذة LSTM (SariLSTM)
  -> AlarmPolicy
  -> PDF عبر reports.py
ESP32
  -> HTTP إلى الخادم
  -> ريلاي على الطرف 26
```

## 6. أمثلة واقعية

### دخول

1. المستخدم يفتح `/login`.
2. يختار دورا ويكتب بريدا وكلمة مرور أو يملأ نمطا تجريبيا من `_fillDemo`.
3. `AppStateViewModel.login` يستدعي Firebase.
4. إن كانت الخلفية غير متاحة حسب رموز `FirebaseService` تُفتح جلسة محلية ويصبح `organizationID` القيمة `ORG-SARI-GLOBAL`.
5. الموجه يرسل المسجل إلى `/app/home`.

القيمة الابتدائية قبل الدخول في الكود `ORG-SARI-EGYPT`.

### محاكاة ثم قطع

1. من الرئيسية يُشغّل سيناريو ارتفاع تيار.
2. القراءة تذهب إلى النموذج إن وُجد الرمز والخادم.
3. الخادم يحتاج عينات متتالية (`confirm` = 3 في الإعداد) مع تجاوز الحد قبل الإنذار.
4. إن رجع قطع وكانت صلاحية الدور تسمح، الواجهة تدخل حالة القطع.

### قطع يدوي

شاشة الطوارئ تستدعي القطع لمن دوره ليس `residential`. الخادم يميز القطع اليدوي. إعادة التشغيل ترسل reset لآخر جهاز حلله النموذج حسب وصف التكامل في `README_PROJECT.md` المطابق لدوال `cutoff` و`reset`.

### تقرير

عند إنذار يكتب `reports.py` ملفا. المسار `GET /v1/reports/<report_id>/<name>`. تنسيق التاريخ العربي في التقارير يستخدم `format_ar` في `reports.py`. التطبيق يعرض التواريخ عبر `SariDate` بالشكل `YYYY/M/Dم` ووقت 12 ساعة مع `ص` أو `م`.

## 7. رحلة المستخدم

فتح التطبيق، `FirebaseService.initialize`، ثم `/login` إن لم تكن الجلسة قائمة. بعد الدخول الغلاف `MainWrapperScreen` يعرض تبويبات المنزل والمراقبة والنموذج والتنبيهات والخريطة والتقارير. الأجهزة والطوارئ والملف خارج الغلاف بمسارات جذر. الخروج يعيد `isLoggedIn` إلى false.

## 8. الوحدات والأقسام

| الوحدة | الملف | الوظيفة |
|---|---|---|
| الدخول | `login_screen.dart` | Firebase أو تجربة، واختيار دور |
| الحالة | `app_state_view_model.dart` | جلسة، قراءات، تنبيهات، قطع، لغة |
| الرئيسية | `home_dashboard_screen.dart` | ملخص ومحاكي |
| المراقبة | `live_monitoring_screen.dart` | رسوم |
| الخطر | `ai_risk_detection_screen.dart` | نتائج ونصوص محركات |
| التنبيهات | `alerts_center_screen.dart` | قائمة حالات |
| الخريطة | `risk_heatmap_screen.dart` | مناطق `ZoneModel` |
| التقارير | `reports_screen.dart` | تقارير واجهة |
| الأجهزة | `device_management_screen.dart` | قائمة حساسات |
| الطوارئ | `emergency_control_screen.dart` | قطع وإعادة |
| الملف | `profile_screen.dart` | دور ولغة |
| النموذج | `model_api_service.dart` | HTTP |
| المحرك المحلي | `ai_risk_engine.dart` | قرار بديل |
| القياس | `telemetry_service.dart` | توليد قراءة |
| الخادم | `live_model/server.py` | REST |
| التدريب | `train.py` و`sim.py` و`model.py` | LSTM وبيانات |
| العتاد | `live_model/iot/sari_esp32/sari_esp32.ino` | قياس وريلاي |

مفاتيح الأعطال في `sim.py`: `overcurrent` و`voltage` و`leakage` و`overheat`. مخرج النموذج خمسة أصناف (الأربعة زائد احتمال سابق للعطل).

## 9. الشركات والكيانات

حقل `organizationID` نصي. لا شاشة شركات ولا عزل بيانات. بعد الدخول تصبح القيمة `ORG-SARI-GLOBAL`. القيمة المزروعة قبل ذلك `ORG-SARI-EGYPT`.

أجهزة الخادم في `devices.json`:

| المعرف | تيار مقنن | جهد اسمي | الموقع المكتوب |
|---|---|---|---|
| default | 40 | 220 | فارغ |
| SARI-SENS-01 | 40 | 220 | Ground Floor Utility Room |
| SARI-SENS-02 | 32 | 220 | Rooftop Plant Room |
| SARI-SENS-03 | 32 | 220 | Floor 2 IT Bay |
| SARI-SENS-04 | 63 | 380 | Zone B Manufacturing |

## 10. الصلاحيات

من `README_PROJECT.md` المطابق لـ `canCutPower` ولبنية الحالة المحلية:

| القدرة | residential | facilityManager | admin |
|---|---|---|---|
| الشاشات بعد الدخول | نعم | نعم | نعم |
| المحاكي | نعم | نعم | نعم |
| قطع التيار من الواجهة | لا | نعم | نعم |
| أدوار على خادم النموذج | لا | لا | لا |

الخادم يتحقق من ترويسة `X-Model-Token` فقط.

## 11. الأتمتة وWorkflows

لا طابور مهام. الموجود:

1. مؤقت قراءات في التطبيق.
2. تحليل مع تخطي إن كان طلب النموذج مشغولا (`_modelBusy` كما في وثيقة المشروع الداخلية).
3. على الخادم: تأكيد 3 عينات فوق العتبة مع شرط الحد، ثم إنذار و`cutoff` حتى `reset`.
4. تحذير مبكر إذا بلغ احتمال ما قبل العطل `tau_pre` لخمس عينات. القيمة في `sari_config.json` هي `1.01`. احتمال النموذج لا يتجاوز 1، لذلك هذا التحذير لا يتحقق بالإعداد الحالي.
5. ESP32: قطع محلي إذا التيار عند أو فوق 200 أمبير أو التسرب عند أو فوق 0.3 أمبير. إن انقطع الاتصال أكثر من 15000 ملي ثانية يطبع أن النموذج غير متصل ويبقى على الحدود المحلية.

`RATE_PER_SECOND` في الخادم = 30.

## 12. التكامل بين الوحدات

| الحدث | الأثر |
|---|---|
| قراءة جديدة | القياس الأخير والرسم، ثم النموذج أو المحرك المحلي |
| `alarm` من النموذج | تنبيه، وربما تقرير، وقطع إن طلب الخادم والدور يسمح |
| قطع | القراءات المعروضة تتوقف عن الوضع الطبيعي وتنبيه طوارئ |
| إعادة | reset على الخادم لآخر جهاز |
| حل تنبيه | حالة ذلك التنبيه |
| تبديل دور | زر الطوارئ |
| تبديل لغة | `AppStrings` والاتجاه. نصوص إنجليزية ثابتة ما زالت داخل بعض الشاشات |
| مناطق الخريطة والتقارير المزروعة | لا تتبع كل قراءة حية |

## 13. المصطلحات

| المصطلح | المعنى |
|---|---|
| SARI | اسم المنتج. الحزمة `sari_app` |
| pu | نسبة إلى المقنن أو الاسمي |
| tau | عتبات في `sari_config.json`: 0.95 و0.95 و0.95 و0.85 |
| tau_pre | 1.01 |
| confirm | 3 |
| leakage | التطبيق يرسل أمبيرا. الخادم يضرب في 1000 عند التخزين بالميلي أمبير |
| SariLSTM | LSTM طبقتان، مخفي 64، دخل 4، خرج 5. الملف `sari_lstm.pt` |
| UCI | ملف استهلاك خارج هذا المجلد يستخدمه التدريب |
| Zone | منطقة عرض وليست جهازا |

حدود `sari_config.json`: حمل 1.13، قصر 5.0، جهد 0.9 إلى 1.1، تسرب 30 ملي أمبير، حرارة 70.

## 14. الأسئلة الشائعة

**هل يعمل بلا خادم النموذج؟**  
نعم. المسار المحلي `AIRiskEngine` عند فشل الطلب أو غياب الإعداد.

**هل Firebase إلزامي؟**  
التهيئة تُحاول. إن فشلت يُستخدم الدخول التجريبي حسب رموز الخطأ.

**هل الترخيص MIT؟**  
README الإنجليزي يقول MIT ويشير إلى ملف LICENSE. ملف LICENSE غير موجود في الملفات الحالية.

**أين بيانات التدريب الكبيرة؟**  
المسار الافتراضي في `train.py` و`sim.py` يشير إلى مجلد `sari-client-data` على نفس الجهاز. ذلك المجلد ليس داخل هذا المشروع.

# الجزء الثاني - التوثيق التقني

## 15. Architecture

```text
Flutter (Provider + GoRouter)
   |  X-Model-Token
   v
Flask server.py  -> SariLSTM + AlarmPolicy -> reports/
   ^
ESP32 sari_esp32.ino  (WiFi + HTTP + relay)
Firebase Auth اختياري عبر firebase_options.dart
```

## 16. Tech Stack

من `pubspec.yaml` إصدار التطبيق `1.0.0+1` وDart `^3.8.0` و`publish_to: none`.

| الحزمة | القيد |
|---|---|
| provider | ^6.1.2 |
| go_router | ^14.8.0 |
| fl_chart | ^0.70.2 |
| intl | ^0.20.2 |
| flutter_animate | ^4.5.2 |
| firebase_core | ^3.12.0 |
| firebase_auth | ^5.5.1 |
| http | ^1.2.2 |
| flutter_lints | ^6.0.0 تطوير |

خادم النموذج من `requirements.txt`: torch وnumpy وpandas وflask وwaitress وreportlab وarabic-reshaper وpython-bidi. أرقام الإصدارات المقفلة غير مكتوبة في ذلك الملف.

خط الواجهة Outfit من `assets/fonts/Outfit-Variable.ttf`. الشعار `assets/images/sari_logo.png`. الثيم الداكن `AppTheme.darkTheme`.

README الإنجليزي يذكر Flutter 3.19 كحد أدنى. `pubspec.yaml` يقيد Dart `^3.8.0` ولا يثبت رقم Flutter 3.19.

## 17. Project Structure

```text
Sari_app-main/
├── lib/                     التطبيق
├── test/                    اختبارات
├── assets/images + fonts
├── live_model/
│   ├── server.py model.py sim.py train.py reports.py
│   ├── devices.json sari_config.json metrics.json
│   ├── sari_lstm.pt
│   ├── requirements.txt .env.example
│   └── iot/sari_esp32/sari_esp32.ino
├── android ios web windows linux macos
├── firebase.json
├── README.md السابق بالإنجليزية
├── README_PROJECT.md
└── SARI_Product_Requirement_Document.md
```

`google-services.json` داخل `android/app` و`GoogleService-Info.plist` داخل `ios/Runner`. القيم لا تُنسخ هنا.

## 18. Frontend

Flutter وليس HTML يدوي. `web/index.html` قالب تشغيل. التوجيه `GoRouter` مع تحويل إلى الدخول. الحالة `ChangeNotifier`. الرسوم `fl_chart`. الحركة `flutter_animate`. اللغتان en وar و`GlobalMaterialLocalizations`. الاتجاه يتبع اللغة.

ملفات المنصات قوالب Flutter. `web/favicon.png` لأيقونة الويب.

## 19. Backend

خادم النموذج Flask في `server.py` ويُقدَّم بـ waitress عند التشغيل الرئيسي. منطق القرار في `model.py` و`AlarmPolicy`. التدريب منفصل في `train.py`.

تطبيق الجوال لا يحتوي PHP. Firebase Auth طبقة حساب اختيارية.

## 20. Request Flow

```text
TelemetryService
  -> ModelApiService.analyze
  -> POST /v1/reading
  -> فحص الترويسة والمعدل
  -> نافذة الجهاز
  -> SariLSTM ثم السياسة
  -> JSON قرار
  -> AppStateViewModel
```

جسم القراءة: `device_id` و`timestamp` و`current` و`voltage` و`leakage` و`temperature`.

حدود الأرقام في الخادم: تيار 0 إلى 10000، جهد 0 إلى 1000، تسرب 0 إلى 100، حرارة -50 إلى 300.

## 21. Database

قاعدة SQL داخل المشروع غير موجودة. Firebase ملفات تهيئة موجودة. مخزن سحابي للقراءات غير مبني كجداول في هذا المستودع.

حالة الخادم ذاكرة عملية: قاموس أجهزة `states`. التقارير ملفات في `REPORTS_DIR`.

`metrics.json` و`devices.json` و`sari_config.json` ملفات إعداد ونتيجة تدريب وليست قاعدة مستخدمين.

## 22. API

الترويسة `X-Model-Token`. إن غاب `MODEL_TOKEN` أو كان أقصر من 16 حرفا يتوقف `server.py` عند الإقلاع.

| الطريقة | المسار | الغرض |
|---|---|---|
| POST | `/v1/reading` | قراءة وقرار |
| GET | `/v1/devices/<device_id>/command` | أمر الجهاز |
| POST | `/v1/devices/<device_id>/cutoff` | قطع |
| POST | `/v1/devices/<device_id>/reset` | إعادة |
| GET | `/v1/reports/<report_id>/<name>` | ملف تقرير |
| GET | `/health` | فحص حياة |

معرف الجهاز يمر على نمط في الخادم. الأصول المسموحة من `ALLOWED_ORIGINS`.

## 23. Authentication & Authorization

Firebase: `signInWithEmailAndPassword` و`createUserWithEmailAndPassword` و`signOut`. أخطاء الخلفية المذكورة في الخدمة: `network-request-failed` و`operation-not-allowed` و`configuration-not-found` و`app-not-authorized` و`internal-error`. غيرها يُعامل كرفض كلمة أو بريد.

الدور المختار في الواجهة لا يُرسل إلى Firebase كصلاحية خادم. القطع محلي حسب الدور.

النموذج: مقارنة `hmac.compare_digest` للترويسة مع `MODEL_TOKEN`.

## 24. Security

| الوسيلة | الحالة |
|---|---|
| رمز النموذج | متغير بيئة، وطول أدنى 16 |
| مقارنة ثابتة الزمن | `hmac.compare_digest` |
| حد معدل | 30 طلبا في الثانية لكل عنوان |
| مدى الأرقام | `_number` |
| Firebase Auth | عند التهيئة الناجحة |
| جلسة تجريبية | عند تعذر الخلفية |
| ملفات Firebase | موجودة وتحتوي تهيئة عميل، والقيم غير منسوخة |
| `secrets.h` للوحة | السكتش يضمه، والملف غير موجود في المستودع |
| ترخيص معلن | MIT في README بلا ملف LICENSE |

## 25. Configuration

`live_model/.env.example` المفاتيح فقط:

| المفتاح | مثال في الملف |
|---|---|
| `MODEL_TOKEN` | فارغ |
| `HOST` | `0.0.0.0` |
| `PORT` | `8080` |
| `ALLOWED_ORIGINS` | فارغ |
| `REPORTS_DIR` | فارغ |
| `SARI_UCI_PATH` | فارغ |
| `SARI_CLIENT_TRAIN` | فارغ |

المسارات الافتراضية في الكود إن غابت المتغيرات تشير إلى `d:\VSCode\Projects\sari-client-data\`.

تطبيق Flutter يقرأ `SARI_MODEL_TOKEN` و`SARI_MODEL_URL` من `--dart-define`. ملف `.env` الفعلي بجانب المثال موجود في المجلد؛ قيمه لا تُنسخ.

عناوين WiFi للوحة تُتوقع من `secrets.h` غير المرفق.

## 26. Integrations

| الخدمة | الحالة |
|---|---|
| Firebase Core وAuth | ملفات التهيئة والحزمة |
| HTTP للنموذج | `http` |
| PDF عربي | reportlab مع arabic-reshaper وpython-bidi |
| بيانات UCI وتدريب العميل | مسارات خارجية |
| MQTT | مذكور في README الإنجليزي وغير موجود في الكود المفحوص |
| بريد وSMS | غير موجود |

## 27. Scheduled Jobs

مهمة نظام مجدولة غير موجودة. المؤقت داخل التطبيق ومؤقت اللوحة (`millis`) هما التكرار. التدريب سكربت يُشغَّل يدويا: `train.py` ودفتر `train_colab.ipynb`.

## 28. File Storage

التقارير مجلد `reports` أو `REPORTS_DIR`. الوزن `sari_lstm.pt`. الصور والخط في `assets`. رفع مستخدم عام غير موجود.

## 29. Logging & Monitoring

`debugPrint` في خدمات Flutter. الخادم يعيد أخطاء JSON عبر `_error`. `/health` فحص حياة. لوحة ESP32 تطبع على Serial عند انقطاع النموذج. نظام تنبيه خارجي غير موجود.

## 30. Installation

التطبيق، كما في README السابق مع تصحيح ما لزم:

```text
flutter pub get
flutter run
```

النموذج:

```text
cd live_model
pip install -r requirements.txt
copy .env.example .env
```

ثم ضع `MODEL_TOKEN` بطول 16 حرفا على الأقل دون كتابة القيمة في الوثائق، ثم:

```text
python server.py
flutter run --dart-define=SARI_MODEL_TOKEN=... --dart-define=SARI_MODEL_URL=http://HOST:8080
```

README السابق: محاكي أندرويد يصل للمضيف عبر `10.0.2.2:8080`. الخادم يقرأ `HOST` و`PORT` والقيمة الافتراضية `0.0.0.0` و`8080`.

Firebase: الملفات الحالية فيها `google-services.json` و`GoogleService-Info.plist` و`firebase_options.dart`. إعادة التوليد بأداة FlutterFire مذكورة في README السابق.

لوحة ESP32: تحتاج `secrets.h` غير الموجود، ومعايرة الثوابت المكتوبة في السكتش.

## 31. Development Guide

- شاشة: ملف تحت `lib/ui/views` ومسار في `createRouter`.
- نص: مفتاح في `app_strings.dart` بالإنجليزية والعربية.
- قرار محلي: `AIRiskEngine`.
- قرار خادم: `server.py` و`model.py` ثم عقد `ModelApiService`.
- جهاز خادم: مفتاح في `devices.json`.
- صلاحية واجهة: فرع على `UserRole` مثل `canCutPower`.
- تاريخ: `SariDate` حتى يبقى الشكل `YYYY/M/Dم` و12 ساعة.

## 32. Deployment

نشر متاجر أو نطاق إنتاج غير موثق بملف CI. `publish_to: none`. الخادم يربط `0.0.0.0` والمنفذ من البيئة. waitress مستدعى في `server.py`. شهادة TLS وأسرار الإنتاج غير مرفقة.

رابط النسخ في README الإنجليزي: `https://github.com/YoussefMoRabie/Sari_app.git`. التحقق من أصل git المحلي غير مضمّن في هذا الفحص.

## 33. Backup & Recovery

نسخ قاعدة غير موجود لأن SQL المحلي غير موجود. الملفات الحرجة للنموذج: `sari_lstm.pt` و`sari_config.json` و`devices.json` ومجلد التقارير.

## 34. Troubleshooting

| العرض | الاتجاه |
|---|---|
| النموذج لا يقبل التشغيل | `MODEL_TOKEN` أقصر من 16 أو غائب |
| التطبيق يبقى على المحرك المحلي | العنوان أو الرمز أو المهلة ثانيتان |
| 401 أو رفض | ترويسة `X-Model-Token` |
| كثرة الطلبات | الحد 30 في الثانية |
| التحذير المبكر لا يظهر | `tau_pre` = 1.01 |
| اللوحة لا تتصل | `secrets.h` مفقود |
| Firebase يرفض البريد | خطأ اعتماد وليس من مجموعة تعذر الخلفية |
| LICENSE مفقود | رغم شارة MIT في README الإنجليزي |

## 35. Dependencies

قيود Flutter في القسم 16. قفل الحلول في `pubspec.lock`. حزم بايثون أسماء بلا أرقام في `requirements.txt`.

## 36. Known Limitations

- القراءات الافتراضية من محاكٍ.
- الخريطة والتقارير المزروعة لا تتبع كل قراءة.
- `tau_pre` الحالي يعطل التحذير المبكر.
- أدوار الوثيقة الحكومية غير مبنية.
- MQTT غير مبني.
- `secrets.h` غير مرفق.
- ملف LICENSE غير موجود.
- وصف pubspec ما زال نص قالب.
- نصوص إنجليزية ثابتة داخل شاشات رغم وجود `AppStrings`.

## 37. Current System State

| الحالة | التفصيل |
|---|---|
| موجود | التطبيق، الخادم، الوزن، الإعداد، السكتش، الاختبارات، وثائق سابقة |
| يعمل مع Flutter | الواجهة والمحاكي |
| يعمل مع بايثون ورمز | قرارات LSTM والتقارير |
| غير مكتمل | عزل منظمات، إشعار جوال، MQTT، أسرار اللوحة داخل المستودع |
| غير موثق | عقد تشغيل إنتاج |

اختبارات موجودة: `test/widget_test.dart` و`test/unit_test.dart` و`test/model_api_service_test.dart`.

## 38. Architecture Decisions

ازدواج المحرك المحلي والنموذج البعيد ظاهر من مهلة HTTP والرجوع إلى `AIRiskEngine`. السبب في README السابق: العمل عند غياب الخادم.

التحقق على الخادم برمز واحد لا بأدوار الواجهة ظاهر من `hmac` مقابل `UserRole` المحلي. لذلك صلاحية القطع في التطبيق لا تغيّر من يملك الرمز.

`tau_pre` أعلى من 1 يبقي فرع التحذير المبكر في الكود دون تفعيله رقميا. القيمة مكتوبة في JSON.

تضمين `secrets.h` يُخرج WiFi من السكتش المرفوع، والملف نفسه غير موجود في الشجرة.

## 39. سجل التغييرات

الإصدار في `pubspec.yaml` هو `1.0.0+1`. سجل إصدارات مستقل غير موجود. README الإنجليزي و`README_PROJECT.md` ووثيقة المتطلبات تبقى مراجع، وهذه الوثيقة هي ملف الجذر بعد مطابقة الكود.

# الجزء الأخير - ملخص شامل

## System Overview

```text
مستخدم (دور محلي)
  -> Flutter SARI
       دخول Firebase أو جلسة تجريبية
       محاكي كل ثانية
       |-- AIRiskEngine إن غاب النموذج
       |-- HTTP /v1/reading إن وُجد
  -> Flask + SariLSTM + سياسة إنذار
       تقارير PDF
  -> ESP32 ريلاي + حدود محلية 200A و0.3A
بيانات تدريب خارجية: sari-client-data (ليست داخل هذا المجلد)
```

## Quick Reference

| الجزء | التقنية | الموقع | الوظيفة |
|---|---|---|---|
| التطبيق | Flutter | `lib/main.dart` | الإقلاع والموجه |
| المسارات | go_router | `lib/core/router/app_router.dart` | الشاشات |
| الحالة | provider | `app_state_view_model.dart` | الجلسة والقراءات |
| الحساب | Firebase | `firebase_service.dart` | دخول أو تراجع تجريبي |
| النموذج العميل | http | `model_api_service.dart` | `/v1/reading` |
| التاريخ | Dart | `sari_date.dart` | `YYYY/M/Dم` و12 ساعة |
| الخادم | Flask | `live_model/server.py` | القرار والقطع |
| الشبكة | PyTorch | `model.py` | `SariLSTM` |
| التدريب | Python | `train.py` `sim.py` | بيانات وعتبات |
| الأجهزة | JSON | `devices.json` | مقنن وموقع |
| العتبات | JSON | `sari_config.json` | tau والحدود |
| اللوحة | C++/Arduino | `sari_esp32.ino` | قياس وريلاي |
| البيئة | env | `.env.example` | أسماء المفاتيح |

## Quick Start

```text
flutter pub get
flutter run
```

للنموذج الحي: انسخ `.env.example` إلى `.env`، اضبط `MODEL_TOKEN` بطول 16 أو أكثر، ثم `python server.py` من `live_model`، وشغّل التطبيق مع `--dart-define` لنفس الرمز والعنوان. بلا الخادم تبقى المحاكاة المحلية.

## For Non-Technical Users

- SARI شاشة لمراقبة الكهرباء والتنبيه والقطع التجريبي.
- الدخول يفتح لوحة فيها المنزل والمراقبة والتنبيهات والخريطة والتقارير.
- يمكن تجربة أعطال من زر المحاكي دون جهاز حقيقي.
- قطع الكهرباء من زر الطوارئ متاح لدور مدير المنشأة أو الأدمن، وغير متاح لدور السكن في الكود.
- اللغة تتبدل بين العربية والإنجليزية من الملف الشخصي.
- الخادم الذكي اختياري. بدونه يبقى تقدير داخل التطبيق.

## For Developers

- التقنيات: Flutter وProvider وGoRouter وFirebase Auth وFlask وPyTorch وwaitress.
- المعمارية: واجهة ذات حالة، وخادم نموذج منفصل، وسكتش لوحة.
- قاعدة بيانات SQL: غير موجودة. التقارير ملفات. Firebase تهيئة حساب.
- API: مسارات `/v1` و`/health` مع `X-Model-Token`.
- أهم الملفات: `app_state_view_model.dart` و`server.py` و`model.py` و`sari_config.json` و`devices.json`.
- التطوير: أبقِ التواريخ على `SariDate`. لا تكتب `MODEL_TOKEN` ولا مفاتيح Firebase في الوثائق. `tau_pre` الحالي 1.01. ملف `secrets.h` مطلوب للوحة وغير مرفق.
