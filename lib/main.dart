import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'ui/view_models/app_state_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const SariApp());
}

class SariApp extends StatefulWidget {
  const SariApp({super.key});

  @override
  State<SariApp> createState() => _SariAppState();
}

class _SariAppState extends State<SariApp> {
  late final AppStateViewModel _appState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appState = AppStateViewModel();
    _router = createRouter(_appState);
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStateViewModel>.value(
      value: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'SARI - Electrical Risk Detection',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: _appState.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
